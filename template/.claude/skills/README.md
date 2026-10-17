# Skills

## User-invoked

Reachable only when you type them (Claude Code: `disable-model-invocation: true`). Alphabetical.

- **[claude-handoff](./claude-handoff/SKILL.md)**: Hand the conversation to a detached background Claude Code agent that keeps working unattended. Use instead of same-session continuation when you want to walk away.
- **[commit](./commit/SKILL.md)**: Commit the current changes as atomic commits with brief, clear messages, rebuilding the intermediate state of each commit when the changes mix themes. Never pushes and never touches the docs. The main agent does it directly, so the messages can say why; invoke-only, never fires on its own.
- **[diagnosing-bugs](./diagnosing-bugs/SKILL.md)**: Manual only: you start it when you want it. A thin trigger for the `debugger` subagent (opus, high effort) -- structured repro -> minimise -> hypothesise -> instrument -> fix-with-regression-test loop for hard bugs and performance regressions, stopping to write up what was tried instead of guessing further if two rounds of hypotheses come up empty. Triages a feature- or area-level ask into individual confirmed bugs (`debugger`, one at a time) vs. unbuilt pieces (`/spec` + `implement`) before dispatching. The bug-fixing counterpart to `/spec` + `implement` for features, deliberately a different model tier and mindset, not a shared one.
- **[doubt](./doubt/SKILL.md)**: Re-examine something you just did or claimed with structured skepticism, when the user pushes back or says `/doubt`. Ends in one of three verdicts (you were wrong, you were right, or genuine tradeoffs) -- never "it depends" as a dodge.
- **[grill-with-docs](./grill-with-docs/SKILL.md)**: The same interview, grounded in this repo — writes resolved vocabulary to `CONTEXT.md` and hard decisions to `docs/ADRs/` as it goes.
- **[handcraft](./handcraft/SKILL.md)**: Build a feature one function at a time, the user approving every step. For when you want deliberate, incremental control over a build -- the opposite end of the spectrum from `implement`'s autonomous loop.
- **[handoff](./handoff/SKILL.md)**: Compact the current conversation into a handoff *document* another agent can pick up later. Unlike `claude-handoff`, which spawns a background process, this just writes the summary, to `docs/handoffs/<yyyy-mm>_<slug>.md`.
- **[implement](./implement/SKILL.md)**: Implement a written spec end to end -- loops through `tdd` at each agreed seam, checks running throughout, `PLAN.md` and `REPORT.md` kept current as it goes, until every seam's covered and an independent `code-reviewer` pass is clean. If a test fails in a way it can't explain and the code belongs to the spec, it can dispatch `debugger` itself; failures outside the spec's scope stop the run for you. Never pauses between seams for a go-ahead. Continues automatically right after `/spec`, in the same conversation, by default; use `claude-handoff` instead when you want to close the session and have it keep going unattended. Asks for a dedicated branch if it finds itself on `main` or `dev`. Stops short of committing -- that's `/commit`.
- **[security-audit](./security-audit/SKILL.md)**: General security analysis of the project or a named area: the `security-auditor` agent maps entry points and looks for injection, leaks, broken access control, unsafe dependencies and CI or infrastructure misconfiguration, and returns ranked findings with fixes.
- **[spec](./spec/SKILL.md)**: Turn a feature request into a written spec (`docs/specs/<type>_<name>/SPEC.md`, plus a seam-organized `PLAN.md` task breakdown) before implementation starts — bounded clarifying questions, then a seam check, then the write-up.
- **[update-docs](./update-docs/SKILL.md)**: Update one documentation file, given its path. A README goes to the `docs-updater` agent (what the project is and does now, no history, simple and jargon-light for the root README); `CHANGELOG.md` goes to the `changelog-writer` agent (the technical changes and why).
- **[wait-what](./wait-what/SKILL.md)**: Fire it the moment a message doesn't land. The agent re-pitches it with the context you're missing, in plain English, using your `CONTEXT.md` vocabulary.
- **[walkthrough](./walkthrough/SKILL.md)**: Guided, debugger-style tour of one concrete code path -- a screen per step, one real value carried forward as it transforms. For understanding existing code, not writing new code.

## Model-invoked

Model- or user-reachable (rich trigger phrasing so the model can reach for them). Alphabetical.

- **[domain-modeling](./domain-modeling/SKILL.md)**: Build and sharpen the project's glossary (`CONTEXT.md`) and record hard-to-reverse decisions as ADRs. The writing half of `grill-with-docs`; also fires on its own when terminology gets sloppy mid-conversation.
- **[frontend-design](./frontend-design/SKILL.md)**: Aesthetic and UX guidance for building or reshaping UI -- deliberate, non-templated choices on palette, typography, and layout. First asks clarifying questions to pick the simplest suitable stack. Self-contained: for occasional UI work, it dispatches its own `code-reviewer` rather than needing `implement` to know it exists.
- **[grilling](./grilling/SKILL.md)**: Interview the user relentlessly about a plan, decision, or idea until every branch of the design tree is resolved. The mechanism behind `grill-me` and `grill-with-docs`, and callable from any other skill that needs a structured interview.
- **[tdd](./tdd/SKILL.md)**: Red-green test-driven development, one seam at a time — what a good test looks like, mocking at boundaries only, plus ML-specific rules (tolerance-based float assertions, checked-in fixtures, seeding, flaky-test handling). Paired with the test-gate hook, which enforces `just test` passing before `git commit`.

## Skills that live in the marketplace

The general-purpose skills are not copied into the project. They are plugins in my `my-marketplaced-skills` marketplace, enabled per project. See its README for what each one does:

- `dev` (bundle: `diagram-design`, `make-pages-interactive`): tools for development work.
- `learning` (`lbt`, `mvk`, `teach`): learning new things.
- `niche` (bundle: `anatomy`, `reverse-engineer-anything`): occasional, specialised work.
- `presenting` (`visium-html-deck`, plus `ppt-master`): making presentations.
- `utilities` (`grill-me`, `rp`, `to-questionnaire`, `writing-for-agents`, plus `find-skills`): general workflow tools. `grill-me` needs the `grilling` skill from this folder.
- `Z-JustInCase` (bundle: `session-memory`): interesting skills kept off by default, for particular uses.

Installing a bundle installs all its members; turning it off takes an uninstall plus `claude plugin prune -y` (the marketplace README explains why). `graphify` and `rtk` are not plugins: `bootstrap-machine.sh` in the template repo installs them once per machine.

Their commands carry the plugin name: `/learning:teach`, `/utilities:grill-me`. `writing-for-agents` (how to write skills and agent documents) is in `utilities`, which is off by default: turn it on when you are about to write or edit skills.
