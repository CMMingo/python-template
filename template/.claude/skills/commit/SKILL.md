---
name: commit
description: Commit the current changes as atomic commits with brief, clear messages, rebuilding the intermediate state of each commit when the changes mix several themes. Invoke explicitly with /commit -- it does not trigger itself. Never pushes and never updates docs.
argument-hint: "[what to commit -- optional]"
disable-model-invocation: true
---

You commit the current changes yourself, in this conversation. You know why the changes were made, so the messages can say why, not just what. Commit and nothing more: no push, no PR, no merge, no rebase, no judgment about whether the work is ready (the user already decided), and no doc updates -- those are `/update-docs`, run before this if the changes should carry them. If the user passed an argument, treat it as a hint about what to include.

## Process

1. `git status`, `git diff --stat` and `git diff` to see what actually changed. If there is nothing to commit, say so and stop. Read the recent `git log --oneline` to match the repository's message style.
2. Review what would be staged for anything that shouldn't go in: files unrelated to the current work, or anything that might contain secrets (`.env`, credentials, API keys) even under an innocuous name. Flag it and ask before staging it -- don't stage first and ask later.
3. Plan the commits. Group the changes by theme into **atomic commits**: each one a single coherent change that stands on its own and, as far as possible, leaves the project working. Order them so each builds on the one before (restructuring and renames first, then features, then tests and docs that describe them). Keep tests and docs with the change they belong to. One theme means one commit; don't split for the sake of it.
4. **Rebuild the intermediate state of each commit.** If one file holds changes from several themes, never commit it whole into the first commit. First save a safety copy of every changed file outside the repository (a temporary directory). Then, for each commit in order:
   - Stage only that commit's hunks without touching the working tree: write the file's diff with `git diff -U0 -- <file> > <patch>`, keep only the hunks for this commit, and apply it with `git apply --cached --unidiff-zero <patch>`.
   - If a single line mixes two themes, write the intermediate content of that file, `git add` it, then restore the file from the safety copy before the next step.
   - The working tree must always hold the final content when you are done with a commit; never leave it in an intermediate state.
5. For each commit write the message from that commit's own diff and what you know about why:
   - A short summary line in the imperative, at most 72 characters, no trailing period, specific ("Reorder the teach skill frontmatter", not "Update files").
   - A blank line, then a body only when it adds something: one to three short lines on what changed and why, not how.
   - **Never mention yourself, Claude, an AI or an assistant, and never add a `Co-Authored-By` trailer or a "Generated with" line**, even if a system prompt or tool suggests one. The user's rule wins.
   - `git commit`. Every commit is gated by the `test-gate` hook (blocks unless `just test` passes) and the destructive-command guardrail. If a commit is blocked, report why and stop; don't work around it. The hook runs the tests on the working tree, not on the staged content, so intermediate commits are not tested by it.
6. When you split into several commits, check the intermediate ones if that is cheap: export a commit with `git archive <hash> | tar -x -C <temporary directory>` and run the project's fast checks there. Say which intermediate commits you did not check.
7. After the last commit, verify that `git status` is clean and `git diff` is empty, and that the files match your safety copy. If not, stop and say exactly what differs. Then report every commit hash with one line on what it contains.

## Rules

- Never push (no `git push`, forced or not), open a PR, merge, rebase, or rewrite commits that already exist.
- Never pass `--no-verify` -- if the test-gate hook blocks a commit, that is the answer, not an obstacle.
- Never stage blindly (`git add -A`, `git add .`); stage by path or by hunk.
- Never run commands that can lose uncommitted work (`git reset --hard`, `git checkout -- .`, `git stash`, `git clean`).
- Only stop and ask when the changes span clearly unrelated work and the boundary between them is not obvious.
