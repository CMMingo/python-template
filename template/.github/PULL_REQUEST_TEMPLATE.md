<!--
How to fill this in (people and agents alike):
- Write for a reviewer who hasn't read the ticket. Plain words, short bullets.
- Delete a section that doesn't apply instead of writing "N/A". Keep the order.
- Title: a conventional commit for a single change (`fix(backend): ...`),
  a plain sentence for a multi-commit feature or a release.
- Checkboxes: [x] means it was actually run, and it says what it showed.
  [ ] means someone still has to do it. Never tick what didn't run.
-->

Ticket: <!-- link to the issue or ticket -->
<!-- Also link other context here: related PRs, a chat thread, a design doc. -->

<!-- Stacked on another PR? Put this first:
> **Stacked on #NNN. Merge that first.** Until it merges, only the last N commits belong here.
-->

## Why

<!--
The problem as a user or operator saw it, and what it cost.
For a bug: the cause, with the file or commit that introduced it.
Link the plan, spec or design doc if there is one.
-->

## What changes

<!--
One bullet per behaviour change, led by the area it touches (e.g. **Backend:**, **UI:**, **Infra:**, **CI:**).
Name new endpoints, statuses, config keys and migrations exactly.
End with **Not touched:** for anything a reviewer might assume changed.
-->

## For review

<!--
Decisions to agree with or challenge: trade-offs, deviations from the ticket,
behaviour that is deliberately removed.
-->

## Deploy impact

<!-- Keep only the lines that apply. -->

- **Merging deploys:** <!-- which environment, if any, deploys automatically when this merges -->
- **Database migration:** <!-- file name, whether it is reversible, and whether it is safe to run before the new code is live -->
- **Expected infrastructure diff:** <!-- what the plan/preview should show, and what must not change -->
- **Config or secrets:** <!-- keys or secrets added or changed, and where they must be set -->
- **Already applied by hand:** <!-- what, in which environment, when; and what a deploy would undo until this merges -->
- **Breaks:** <!-- anything that stops working without action: a required config key, a changed API contract, existing data the new code can't read. Say what has to be done. -->
- **Cost or performance:** <!-- cloud cost, latency, memory, startup time, API or token usage. Before/after numbers if you have them. -->

## Verification

- [x] <!-- What you ran and what it showed: new tests, before/after numbers, a local repro. Screenshots for UI changes. -->
- [x] <!-- Test suites, linters and type checkers that ran, with results. -->
- [ ] <!-- What wasn't verified, and how a reviewer can check it. -->

<!-- If reproducing it takes more than one sentence, give the exact steps:
```bash
<command to set up or run>
<command to check>   # expected result
```
-->

## Known gaps

<!-- What this deliberately leaves unfixed, and what fixing it would take. -->

## After merging

- [ ] <!-- Checks after deploy, data to clean up, follow-up tickets. -->
