#!/usr/bin/env python3
"""
Claude Code PreToolUse hook: destructive-command guardrail.

Hard-blocks a small set of obviously destructive Bash invocations before
they run, with no override (same philosophy as test_gate.py: this guards
the agent, not you -- if you need to run one of these yourself, do it
outside Claude Code). Currently covers:

  - `rm -rf` (or any equivalent flag combo) targeting a dangerous path:
    /, ~, ., .., *, $HOME, .git, the project root, or an ancestor of it.
  - `git reset --hard`
  - `git clean` with a force flag (-f, -fd, -fdx, --force, ...)
  - `git checkout .` / `git restore .` (discards uncommitted changes to
    every tracked file)
  - `git branch -D` on `main` or `master`
  - `git push --force` / `-f` to main or master (branch resolved from the
    explicit refspec if given, otherwise the current branch)

This is a heuristic safety net, not a full shell parser: it splits on
&&, ||, ;, | to look at each command in a chain, and tokenizes each
segment with shlex. Quoting edge cases or unusual shell constructs can
slip past it -- it catches the common, careless case, not every possible
way to write these commands.

Reads the PreToolUse hook JSON payload from stdin. Exit code 2 blocks the
tool call (stderr is surfaced to the agent as the reason); exit code 0
allows it.
"""
import json
import os
import re
import shlex
import subprocess
import sys

DANGEROUS_RM_TARGETS = {"/", "~", ".", "..", "*", "$HOME"}


def split_top_level(command: str) -> list[str]:
    """Naive split on shell control operators. Doesn't account for these
    operators appearing inside quotes -- good enough for a safety net,
    not a substitute for a real shell parser."""
    return re.split(r"&&|\|\||;|\|", command)


def tokenize(segment: str) -> list[str]:
    try:
        return shlex.split(segment)
    except ValueError:
        return segment.split()


def current_branch(project_dir: str) -> str | None:
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--abbrev-ref", "HEAD"],
            cwd=project_dir,
            capture_output=True,
            text=True,
            timeout=10,
        )
    except Exception:
        return None
    if result.returncode != 0:
        return None
    return result.stdout.strip()


def rm_flags_and_targets(tokens: list[str]) -> tuple[set[str], list[str]]:
    flags: set[str] = set()
    targets: list[str] = []
    for tok in tokens:
        if tok == "-":
            targets.append(tok)
        elif tok.startswith("--"):
            flags.add(tok)
        elif tok.startswith("-") and len(tok) > 1:
            flags.update(f"-{c}" for c in tok[1:])
        else:
            targets.append(tok)
    return flags, targets


def is_dangerous_rm_target(target: str, project_dir: str) -> bool:
    stripped = target.rstrip("/") or "/"
    if stripped in DANGEROUS_RM_TARGETS:
        return True
    if os.path.basename(stripped.rstrip("/")) == ".git":
        return True
    expanded = os.path.expanduser(os.path.expandvars(target))
    try:
        real = os.path.realpath(expanded)
    except Exception:
        return False
    home = os.path.realpath(os.path.expanduser("~"))
    proj = os.path.realpath(project_dir)
    if real == "/" or real == home or real == proj:
        return True
    # An ancestor of the project root (removing it would take the project with it).
    if proj == real or proj.startswith(real + os.sep):
        return True
    return False


def check_rm(tokens: list[str], project_dir: str) -> str | None:
    idx = 0
    if tokens[:1] == ["sudo"]:
        idx = 1
    if len(tokens) <= idx or tokens[idx] != "rm":
        return None
    flags, targets = rm_flags_and_targets(tokens[idx + 1 :])
    has_recursive = "-r" in flags or "-R" in flags or "--recursive" in flags
    has_force = "-f" in flags or "--force" in flags
    no_preserve_root = "--no-preserve-root" in flags
    if no_preserve_root:
        return "`rm` with --no-preserve-root"
    if not (has_recursive and has_force):
        return None
    for target in targets:
        if is_dangerous_rm_target(target, project_dir):
            return f"`rm -rf` targeting `{target}`"
    return None


def check_git_reset_hard(tokens: list[str]) -> str | None:
    if "git" in tokens and "reset" in tokens and "--hard" in tokens:
        return "`git reset --hard` (discards uncommitted work irreversibly)"
    return None


def check_git_clean_force(tokens: list[str]) -> str | None:
    if "git" not in tokens or "clean" not in tokens:
        return None
    for tok in tokens:
        if tok == "--force":
            return "`git clean` with a force flag (deletes untracked files irreversibly)"
        if tok.startswith("-") and not tok.startswith("--") and "f" in tok[1:]:
            return "`git clean` with a force flag (deletes untracked files irreversibly)"
    return None


def check_git_discard_all(tokens: list[str]) -> str | None:
    if "git" not in tokens:
        return None
    if "checkout" in tokens:
        idx = tokens.index("checkout")
    elif "restore" in tokens:
        idx = tokens.index("restore")
    else:
        return None
    args = tokens[idx + 1 :]
    positionals = [a for a in args if not a.startswith("-") and a != "--"]
    if positionals == ["."]:
        return "`git checkout .` / `git restore .` (discards uncommitted changes to every tracked file)"
    return None


def check_git_branch_delete_protected(tokens: list[str]) -> str | None:
    if "git" not in tokens or "branch" not in tokens:
        return None
    branch_idx = tokens.index("branch", tokens.index("git"))
    args = tokens[branch_idx + 1 :]
    if "-D" not in args:
        return None
    targets = [a for a in args if not a.startswith("-")]
    if any(t in ("main", "master") for t in targets):
        return "`git branch -D` on a protected branch (main/master)"
    return None


def check_git_push_force_protected(tokens: list[str], project_dir: str) -> str | None:
    if "git" not in tokens or "push" not in tokens:
        return None
    push_idx = tokens.index("push", tokens.index("git"))
    args = tokens[push_idx + 1 :]
    has_force = any(a in ("--force", "-f") for a in args)
    if not has_force:
        return None
    positionals = [a for a in args if not a.startswith("-")]
    if len(positionals) >= 2:
        branch = positionals[1].split(":")[-1]
    else:
        branch = current_branch(project_dir)
    if branch in ("main", "master"):
        return f"`git push --force` to `{branch}`"
    return None


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0

    if payload.get("tool_name") != "Bash":
        return 0

    command = (payload.get("tool_input") or {}).get("command", "")
    if not command:
        return 0

    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())

    for segment in split_top_level(command):
        segment = segment.strip()
        if not segment:
            continue
        tokens = tokenize(segment)
        if not tokens:
            continue

        for check in (
            lambda t: check_rm(t, project_dir),
            check_git_reset_hard,
            check_git_clean_force,
            check_git_discard_all,
            check_git_branch_delete_protected,
            lambda t: check_git_push_force_protected(t, project_dir),
        ):
            reason = check(tokens)
            if reason:
                sys.stderr.write(
                    f"destructive-guard: blocked -- {reason}.\n"
                    "No override for this gate. If you need to run this "
                    "yourself, do it outside Claude Code.\n"
                )
                return 2

    return 0


if __name__ == "__main__":
    sys.exit(main())
