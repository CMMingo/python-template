---
name: Task
about: A concrete piece of work for a developer or an AI agent
labels: task
---

<!--
How to fill this in (people and agents alike):
- Write so someone can start without asking you anything. Plain words, short bullets.
- Delete a section that doesn't apply instead of writing "N/A". Keep the order.
- Point at files and commands, not at what "should be obvious".
- Title: the work as a verb phrase (`Move logging config into the backend`).
- Checkboxes: [x] means it was actually done, and it says what it showed.
  [ ] means someone still has to do it. Never tick what didn't happen.
-->

Related: <!-- links: the spec or ADR this comes from, a parent issue, blocking issues or PRs. -->

## Why

<!--
The reason this work exists and what it unblocks, in a few lines.
Link the spec (docs/specs/...) or the decision record (docs/ADRs/...) if there is one.
-->

## What to do

<!--
One bullet per change, led by the area it touches (e.g. **Backend:**, **UI:**, **Infra:**, **CI:**).
Name files, functions, endpoints and config keys exactly.
End with **Not touched:** for anything someone might assume changes.
-->

## Where to look

<!--
The entry points: files to read first, the code that does something similar, constraints you know of.
This is what lets an agent start without exploring the whole repository.
-->

## For discussion

<!-- Open questions and decisions you want challenged before work starts. Say what you'd choose. -->

## Deploy impact

<!-- Keep only the lines that apply. -->

- **Breaks:** <!-- anything that stops working without action, and what has to be done -->
- **Config or secrets:** <!-- keys or secrets added or changed, and where they must be set -->
- **Already applied by hand:** <!-- what, in which environment, and what a deploy would undo -->

## Done when

- [ ] <!-- Observable result: "make test passes and X now does Y". -->
- [ ] <!-- The checks that must be green: tests, linters, type checker. Name them. -->
- [ ] <!-- Docs touched, if any: README, CHANGELOG, an ADR. -->

## Out of scope

<!-- What must not change in this task, and what to open a separate issue for instead. -->
