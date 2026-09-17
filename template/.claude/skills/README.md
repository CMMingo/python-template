# Skills

## User-invoked

Reachable only when you type them (Claude Code: `disable-model-invocation: true`).

- **[spec](./spec/SKILL.md)**: Turn a feature request into a written spec (`docs/specs/<type>-<yyyy_mm>-<name>/SPEC.md`, plus a seam-organized `plan/PLAN.md` task breakdown) before implementation starts — bounded clarifying questions, then a seam check, then the write-up.
- **[grill-with-docs](./grill-with-docs/SKILL.md)**: The same interview, grounded in this repo — writes resolved vocabulary to `CONTEXT.md` and hard decisions to `docs/adr/` as it goes.
- **[commit-push](./commit-push/SKILL.md)**: Run `changelog-writer`/`readme-updater` to bring the docs up to date, then stage, commit (splitting into several logical commits if the diff is large), and push. Thin trigger for the `commit-push` subagent -- invoke-only, never fires on its own.
- **[implement](./implement/SKILL.md)**: Implement a written spec end to end -- loops through `tdd` at each agreed seam, checks running throughout, `plan/PLAN.md` and `reports/` kept current as it goes, until every seam's covered and an independent `code-reviewer` pass is clean. Never pauses between seams for a go-ahead. Continues automatically right after `/spec`, in the same conversation, by default; use `claude-handoff` instead when you want to close the session and have it keep going unattended. Stops short of committing -- that's `/commit-push`.
- **[claude-handoff](./claude-handoff/SKILL.md)**: Hand the conversation to a detached background Claude Code agent that keeps working unattended. Use instead of same-session continuation when you want to walk away.
- **[walkthrough](./walkthrough/SKILL.md)**: Guided, debugger-style tour of one concrete code path -- a screen per step, one real value carried forward as it transforms. For understanding existing code, not writing new code.
- **[doubt](./doubt/SKILL.md)**: Re-examine something you just did or claimed with structured skepticism, when the user pushes back or says `/doubt`. Ends in one of three verdicts (you were wrong, you were right, or genuine tradeoffs) -- never "it depends" as a dodge.
- **[handcraft](./handcraft/SKILL.md)**: Build a feature one function at a time, the user approving every step. For when you want deliberate, incremental control over a build -- the opposite end of the spectrum from `implement`'s autonomous loop.
- **[frontend-design](./frontend-design/SKILL.md)**: Aesthetic and UX guidance for building or reshaping UI -- deliberate, non-templated choices on palette, typography, and layout. Self-contained: for occasional UI work, it dispatches its own `code-reviewer` (and `logic-checker`, if it's implementing a spec'd seam) rather than needing `implement` to know it exists.

## Model-invoked

Model- or user-reachable (rich trigger phrasing so the model can reach for them).

- **[grilling](./grilling/SKILL.md)**: Interview the user relentlessly about a plan, decision, or idea until every branch of the design tree is resolved. The mechanism behind `grill-me` and `grill-with-docs`, and callable from any other skill that needs a structured interview.
- **[domain-modeling](./domain-modeling/SKILL.md)**: Build and sharpen the project's glossary (`CONTEXT.md`) and record hard-to-reverse decisions as ADRs. The writing half of `grill-with-docs`; also fires on its own when terminology gets sloppy mid-conversation.
- **[tdd](./tdd/SKILL.md)**: Red-green test-driven development, one seam at a time — what a good test looks like, mocking at boundaries only, plus ML-specific rules (tolerance-based float assertions, checked-in fixtures, seeding, flaky-test handling). Paired with the test-gate hook, which enforces `make test` passing before `git commit`.
- **[diagnosing-bugs](./diagnosing-bugs/SKILL.md)**: Thin trigger for the `debugger` subagent (opus, high effort) -- structured repro -> minimise -> hypothesise -> instrument -> fix-with-regression-test loop for hard bugs and performance regressions, stopping to write up what was tried instead of guessing further if two rounds of hypotheses come up empty. Triages a feature- or area-level ask into individual confirmed bugs (`debugger`, one at a time) vs. unbuilt pieces (`/spec` + `implement`) before dispatching. The bug-fixing counterpart to `/spec` + `implement` for features, deliberately a different model tier and mindset, not a shared one.

## Productivity

General workflow tools, not code-specific — see [productivity_skills/README.md](./productivity_skills/README.md).
