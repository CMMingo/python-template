---
name: security-audit
description: Whole-project or whole-area security analysis (not just the pending changes). Dispatches the security-auditor agent to map the entry points and look for weak points an attacker could use -- injection, leaks, broken access control, unsafe dependencies, secrets left in git history, CI and infrastructure misconfiguration -- and returns ranked findings with a fix for each. For a quick check of only the pending changes, use the built-in /security-review instead. Invoke explicitly with /security-audit; it does not trigger itself.
argument-hint: "[path, feature or area to audit -- optional, defaults to the whole repo]"
disable-model-invocation: true
---

Dispatch the `security-auditor` subagent. Give it the scope: the path, feature or area the user named, or the whole repository if they named none (if they only want the pending changes checked, point them to the built-in `/security-review` instead, unless they also want the deeper treatment, in which case scope it to `git diff` against the base branch). Also tell it where the project's own context lives -- `AGENTS.md`, `CONTEXT.md`, the ADRs under `docs/ADRs/` that touch the area -- so it understands what the system is meant to do and what is deliberately out of scope.

This is broader and more adversarial than the two lighter checks. `code-reviewer` includes a security pass on one diff, and the built-in `/security-review` checks only the pending changes on the current branch; use those for a quick look at what you are about to commit. This skill is the dedicated pass over a whole area or the whole repository -- including dependencies, secrets in git history, CI workflows and infrastructure. `code-reviewer` checks one diff for many things before a commit; this is a dedicated, attacker-minded pass over a whole area, with its own map of entry points. It is worth running before a release, and whenever the project gains an endpoint, authentication, file or data handling, a new integration, or new infrastructure.

Relay the report back as it is: the attack-surface map, the findings ranked by severity, and the list of what was not checked. Do not fix anything yourself and do not commit. If the user wants findings acted on, they decide which to take: a confirmed vulnerability is a task for `/spec` (a feature-sized fix) or `diagnosing-bugs` (a concrete, reproducible failure).
