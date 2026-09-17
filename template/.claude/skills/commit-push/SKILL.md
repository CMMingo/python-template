---
name: commit-push
description: Stage, commit, and push the current changes. Invoke explicitly with /commit-push -- it does not trigger itself.
disable-model-invocation: true
---

First dispatch `changelog-writer`, then `readme-updater`, against the current diff -- so any doc updates they make land in the same commit(s) as the code they describe, instead of needing a follow-up commit. Then dispatch the `commit-push` subagent to stage the current changes (including whatever those two just touched), draft a commit message from the diff, commit -- splitting into several logical commits if the diff is large (see the subagent for how) -- and push once at the end. Relay its report back (every commit hash and what was pushed, or the reason it stopped) rather than re-summarizing it -- if it was blocked by `test-gate` or flagged something to check, the user needs to see that verbatim.

This is deliberately a thin trigger: the actual staging/drafting/committing logic lives in the subagent (`.claude/agents/commit-push.md`) so it runs in its own context, on a cheaper model. Don't duplicate that logic here -- if the behavior needs to change, change the subagent, not this skill.
