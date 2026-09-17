#!/usr/bin/env python3
"""
Claude Code PreToolUse hook: test-gate.

Hard-blocks any Bash tool call that runs `git commit` unless `make test`
passes first. This is a no-override gate for the agent: it fires regardless
of flags on the git commit invocation itself (including --no-verify), and
there is no environment variable or flag that skips it. If a human wants to
commit without running the suite, that's what the *separate*
.pre-commit-config.yaml gate is for -- that one is a normal pre-commit hook
and can be bypassed by hand in the usual ways (`git commit --no-verify`,
`SKIP=make-test git commit`). The two gates are intentionally different:
this one guards the agent, that one guards you.

Reads the PreToolUse hook JSON payload from stdin, matches on
tool_name == "Bash" and a `git commit` invocation in the command string,
then runs `make test` in the project root. Exit code 2 blocks the tool call
(stderr is surfaced to the agent as the reason to fix); exit code 0 allows
it. Infra problems (no Makefile, no make/uv on PATH) fail open with a
warning rather than blocking on something the agent can't fix by writing
code.
"""
import json
import os
import shutil
import subprocess
import sys
import re

# Matches `git commit`, `git -C some/path commit`, `... && git commit ...`,
# etc. Deliberately does not special-case --no-verify or any other flag:
# this hook blocks the tool call before Bash even runs, so git's own flag
# handling never comes into play.
GIT_COMMIT_RE = re.compile(r"\bgit\b[^|&;\n]*\bcommit\b")

TEST_TIMEOUT_SECONDS = 600


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        # Malformed hook input -- fail open rather than block unrelated
        # tool calls on something that isn't a test failure.
        return 0

    if payload.get("tool_name") != "Bash":
        return 0

    command = (payload.get("tool_input") or {}).get("command", "")
    if not command or not GIT_COMMIT_RE.search(command):
        return 0

    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())

    for tool in ("make", "uv"):
        if shutil.which(tool) is None:
            print(
                f"test-gate: `{tool}` not found on PATH, skipping test gate.",
                file=sys.stderr,
            )
            return 0

    if not os.path.isfile(os.path.join(project_dir, "Makefile")):
        print(
            f"test-gate: no Makefile found in {project_dir}, skipping test gate.",
            file=sys.stderr,
        )
        return 0

    try:
        result = subprocess.run(
            ["make", "test"],
            cwd=project_dir,
            capture_output=True,
            text=True,
            timeout=TEST_TIMEOUT_SECONDS,
        )
    except subprocess.TimeoutExpired:
        sys.stderr.write(
            f"test-gate: blocked `git commit` -- `make test` did not finish "
            f"within {TEST_TIMEOUT_SECONDS}s. No override for this gate; "
            "investigate the hang (or run the suite yourself) before "
            "committing.\n"
        )
        return 2

    if result.returncode == 0:
        return 0

    sys.stderr.write(
        "test-gate: blocked `git commit` -- `make test` failed.\n"
        "Fix the failing tests before committing. No override for this gate.\n\n"
        "--- make test output (tail) ---\n"
    )
    tail = "\n".join((result.stdout + result.stderr).splitlines()[-60:])
    sys.stderr.write(tail + "\n")
    return 2


if __name__ == "__main__":
    sys.exit(main())
