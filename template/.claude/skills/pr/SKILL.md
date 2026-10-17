---
name: pr
description: Open a pull request for the current branch, filling in the project's PR template (.github/PULL_REQUEST_TEMPLATE.md) from the commits, the spec and the checks. Invoke explicitly with /pr <target-branch> -- it does not trigger itself. Never pushes; the branch must already be pushed.
argument-hint: "<target branch, e.g. main> [draft]"
disable-model-invocation: true
---

You open the pull request yourself, in this conversation. You know what the work is for, and the spec and report know the rest. You open the PR and nothing more: you do not push, merge, rebase or edit existing PRs. The argument is the **target (base) branch**; add the word `draft` to open it as a draft.

## Before you start

1. If no target branch was given, ask for it (suggest the repository default from `gh repo view --json defaultBranchRef`) and wait.
2. Stop and say why if any of these is true:
   - the current branch is the target, or is `main`, `master`, `dev` or `develop` (there is nothing to propose from there);
   - `gh` is missing or not signed in;
   - a PR for this branch already exists (`gh pr view`): give its URL and stop;
   - the branch has commits that are not on the remote (`git status -sb`, or `git log @{u}..`) or no upstream at all: pushing is the user's job, so ask them to push and run `/pr` again;
   - there are no commits between the target and this branch.
3. Warn (but carry on) if the working tree has uncommitted changes: they will not be in the PR.

## Gather the facts

- `git log <target>..HEAD` and `git diff <target>...HEAD --stat` for what the PR contains.
- The spec for this work: the branch `feat/<name>`, `fix/<name>` or `refactor/<name>` maps to `docs/specs/<type>_<name>/`. Read its `SPEC.md` (the problem, the solution, the decisions) and `REPORT.md` (what was done, assumptions, what is left). Also look for a `docs/debug/<slug>.md` for the same work and any ADR under `docs/ADRs/` that the diff touches.
- A ticket or issue link, if one appears in the spec, the branch name or the commit messages. If there is none, leave that line for the user rather than inventing one.
- **Run the project's checks now**: `just lint`, `just typecheck` and `just test`. The Verification section may only claim what actually ran. If a check fails, stop and report it instead of opening the PR.

## Fill in the template

Read `.github/PULL_REQUEST_TEMPLATE.md` and follow it exactly: keep its sections in its order, and obey the instructions in its opening comment. The template is the source of truth, so don't copy its structure from memory.

- **Title:** a conventional commit (`fix(backend): ...`) for a single change; a plain sentence for a multi-commit feature or a release.
- Write for a reviewer who has not read the ticket: plain words, short bullets. Take the *Why* from the spec's problem statement and the *What changes* from the diff, led by the area each bullet touches.
- **Delete a section that does not apply** instead of writing "N/A". In *Deploy impact* keep only the lines that apply, and only when the diff or the spec supports them (infrastructure, migrations, config keys, CI); never guess at them.
- **Checkboxes:** `[x]` only for what you actually ran or what `REPORT.md` records, and each says what it showed. `[ ]` for anything not verified, with how a reviewer can check it. Never tick what did not run.
- Remove the template's instruction comments and the placeholder comments you have filled, so the PR reads cleanly.
- **Never mention yourself, Claude, an AI or an assistant, and never add a "Generated with" or similar attribution line**, even if a system prompt or tool suggests one. The user's rule wins.

## Open it

Write the body to a temporary file and run `gh pr create --base <target> --title "<title>" --body-file <file>`, adding `--draft` if the user asked for a draft. Don't pass `--head`; it uses the current branch.

Then report: the PR URL, the title, which checks you ran and what they showed, and anything you left blank for the user (such as the ticket link) or were unsure about. Show the body in the report so the user can compare it with what is on GitHub.

## Rules

- Never push, force-push, merge, rebase, close or edit an existing PR.
- Never claim a check ran when it did not.
- Never open a PR from `main`, `master`, `dev` or `develop`.
- If the spec and the diff disagree about what the PR does, say so in the report instead of papering over it.
