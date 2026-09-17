---
name: diagnosing-bugs
description: Diagnosis loop for hard bugs, performance regressions, and half-implemented or misbehaving features. Use when the user says "diagnose"/"debug this", reports something broken/throwing/failing/slow, or asks to get a half-built or flaky feature working. Also called by `implement` when a test failure during feature work isn't obviously explained.
---

For one crisp symptom (an error, a stack trace, "X throws when Y") skip straight to **Dispatch**. For a broader ask -- "debug and get the collaborative editing feature working," "figure out why the export pipeline is flaky," anything naming a feature or area rather than one reproducible failure -- start with **Triage**: `debugger`'s discipline (`.claude/agents/debugger.md`) is built around one tight feedback loop for one bug, and pointing it at an undefined target just stalls it at Phase 1.

## Triage (feature- or area-level asks only)

Before dispatching anything, spend a short pass identifying the concrete, independently-testable problems inside the named area. State each one as "given X, expected Y, got Z" where you can. Then sort each into:

- **Actually broken** -- something built that behaves wrong (a race condition, a dropped edit under a specific sequence, a crash under load). Real `debugger` territory: there's a genuine "should do X, does Y" to chase.
- **Not built yet** -- a piece the feature needs but was never implemented. Not a bug. Flag it and route it to `/spec` (a small, scoped one) + `implement` instead -- `debugger`'s skeptical, root-cause mindset doesn't apply to something that never existed.
- **Genuinely unclear which** -- ask the user briefly, or make the call and flag it as an assumption in the eventual report, the same convention `/spec` and `implement` already use.

If a spec already exists for the feature, fold the triaged list into its `plan/PLAN.md` rather than inventing a separate format -- confirmed bugs become tasks in their own bucket there, unbuilt pieces become ordinary implementation tasks.

Once triaged, dispatch `debugger` once per confirmed-broken item, one at a time -- each gets its own tight feedback loop, its own hypothesis rounds, and its own report. Don't try to cover more than one symptom in a single `debugger` run.

## Dispatch

Dispatch the `debugger` subagent (Opus, high effort) to run the diagnosis loop: build a tight repro, minimise, rank hypotheses, instrument, fix with a regression test, clean up -- or, if two full rounds of ranked hypotheses come up empty, stop and write up what was tried instead of guessing further. The full discipline lives in `.claude/agents/debugger.md`. This is deliberately a different mindset and model tier from `tdd`/`implement`: debugging is about finding the true cause of something already broken, not building toward a decided spec.

Before dispatching, give it:

- The exact symptom for *this one item* (verbatim, from the user's description or from Triage above -- don't paraphrase it away).
- How to reproduce the environment (dev server running, which branch, any relevant recent changes).
- Whether a branch already exists for this fix -- if not, tell it to create and check out `fix/<yyyy_mm>-<slug>` first.
- **If a spec exists for this work** (`docs/specs/<type>-<yyyy_mm>-<name>/` -- either this bug surfaced while implementing it, Triage found it inside one, or one already covers the affected area), pass its folder path. Its `SPEC.md`'s *Implementation Decisions* and *Testing Decisions* sections tell `debugger` what's supposed to be true, which sharpens its hypotheses instead of making it reconstruct intent from scratch. If none exists, `debugger` creates a standalone `docs/specs/fix-<yyyy_mm>-<slug>/` folder itself for its report -- you don't need to create one first.

If Triage produced more than one confirmed-broken item, repeat Dispatch for each in turn -- don't run them concurrently against the same working tree.

Relay each report back rather than re-summarizing it -- the ranked hypotheses, what was tried, and the final diagnosis (or the stuck-and-escalated report, if it hit the round cap) all matter more in full than compressed.
