---
name: spec
description: "Turn a feature idea into a written SPEC.md before implementation starts: asks a short, bounded round of clarifying questions if genuinely needed, sketches the testing seams, then writes the spec to the repo. Invoke explicitly with /spec — it does not trigger itself."
disable-model-invocation: true
---

This skill turns a feature request — yours or a stakeholder's — into a spec file the codebase keeps. Reach for it whenever a change is big enough that you'd hate to lose the reasoning behind it if the session ended right now: a new endpoint, a pipeline change, a new model integration, anything spanning more than one sitting. For something you can finish in the next few minutes, skip straight to implementing — writing a spec for a one-line fix is ceremony, not planning.

## Why this shape

Two things kill specs in practice: interviews that never end, and specs that invent decisions nobody actually made. This skill is built to avoid both. Ask only what you don't already know, stop asking once you have enough to write something concrete, and write down only what was actually decided — flagging the rest as an assumption rather than smuggling it in as fact.

## Where things live

Each spec gets its own folder: `docs/specs/<type>-<yyyy_mm>-<name>/`, where `<type>` is `feat`, `fix`, or `refactor` (a bug report and a bug fix are both `fix` — there's no separate `bug` type), `<yyyy_mm>` is the year and month the spec was created, and `<name>` is a short kebab-case name (e.g. `docs/specs/feat-2026_09-multi-edit/`). Inside:

- `SPEC.md` — the spec itself (step 4 below).
- `plan/PLAN.md` — the task breakdown `implement` works through (step 5 below).
- `reports/` — created lazily, the first time `implement` or `debugger` finishes a run against this spec. Each run adds one file, named `NNNN-<skill>.md` (zero-padded, e.g. `0001-implement.md`, `0002-debugger.md`), numbered in the order they're written. Not created by this skill.

This is deliberately separate from `CONTEXT.md` and `docs/adr/`, which stay project-wide (see `domain-modeling`). Those record what's permanently true about the domain, shared and reused across every spec; a spec's own `plan/` and `reports/` record that one piece of work's task breakdown and execution history, and aren't relevant to any other spec.

## Process

### 1. Check what you already know

Before asking anything, look at what's already on the table: the request itself, the current conversation, the codebase, `CLAUDE.md`, and any ADRs in the area you're about to touch. For a targeted lookup you don't already have the answer to ("does this endpoint already exist," "what does the current schema look like"), dispatch the `context-scout` subagent rather than searching broadly yourself. If a `/grill-me` or `/grill-with-docs` session already happened earlier in this conversation, treat everything it settled as decided — do not re-ask questions it already resolved, even if this skill would otherwise have asked them itself. If the request already answers most of what you'd ask — scope, the shape of the solution, the constraints — don't manufacture questions to fill out a checklist. Go straight to step 3.

### 2. Ask, in one bounded round

If real gaps remain, ask about them in a single batch of questions, not one at a time. Cover only what's actually blocking a decision: the boundary of what's in vs. out of scope, the constraint that would change the technical approach, the thing you'd otherwise have to guess at. A good rule of thumb is three questions or fewer per round.

You get up to **three rounds** total. In practice almost everything resolves in one or two — a request is usually clear after a couple of focused exchanges, and a fourth round is more often stalling than learning something new. If something is still genuinely unresolved after round three, don't keep asking: write your best-supported assumption into the spec and flag it plainly (see the `Further Notes` section below) so correcting it costs the reader five seconds, not another round trip.

### 3. Sketch the seams, and check them

Before writing a word of the spec, work out where this feature will be tested — the seam(s) at which behavior can be verified from the outside. Prefer a seam that already exists in the codebase over inventing a new one, and prefer the highest-level seam that still exercises the real behavior. The ideal number of seams for a single spec is one; more than two or three is usually a sign the work should be split.

State the seam(s) to the user and get a quick confirmation before writing the spec. This is the cheapest point in the whole process to catch a wrong test boundary — much cheaper than discovering it during `tdd` or `code-review` later, both of which will hold the implementation to whatever seam gets agreed here.

### 4. Write the spec

Save it as `docs/specs/<type>-<yyyy_mm>-<name>/SPEC.md` — see "Where things live" above for the folder convention. Using a folder per spec, rather than a single shared file, means old specs stay around as a record instead of getting overwritten by the next feature — worth it the first time you want to remember why something was built a particular way.

Use this template. Every section should reflect something actually said or found — if a section would otherwise be empty or invented, say so explicitly rather than padding it out.

<spec-template>

## Problem Statement

The problem, from the perspective of whoever is asking for this — not restated as a solution.

## Solution

The solution, in plain terms, from the same perspective.

## User Stories

A list of user stories, each in the form:

`As a <actor>, I want <feature>, so that <benefit>`

Cover the real variations of the feature, not padding. For refactors, module boundaries, or other work that isn't really user-facing, this section will be thin or absent — say so and lean on Implementation Decisions instead rather than inventing stories nobody would recognize.

## Implementation Decisions

What was actually decided: modules touched, interfaces changed, architectural choices, schema or API changes, specific integration points. Describe decisions, not code — a file path or snippet goes stale the moment the branch moves; a decision doesn't.

Exception: if a prototype produced a snippet that pins down a decision more precisely than prose can (a state machine, a schema, a reducer shape), inline the decision-bearing fragment and say plainly that it's from a prototype, not a working implementation.

## Testing Decisions

The seam(s) agreed in step 3, what a good test at that seam looks like (behavior in, behavior out — not implementation detail), which modules get covered, and any prior art already in the codebase worth following.

## Out of Scope

What this spec deliberately does not cover. Take this section seriously — the things you explicitly ruled out are usually the most useful lines in the document, because they're what stops a future reader (agent or human) from quietly expanding the work.

## Further Notes

Anything else worth recording — including, explicitly, any assumption made in step 2 because a question went unanswered after three rounds. Label these as assumptions, not decisions.

</spec-template>

### 5. Write the plan

Before implementation starts, break the spec into a task list at `docs/specs/<type>-<yyyy_mm>-<name>/plan/PLAN.md` — the first concrete thing built off the spec, and what `implement` actually works through.

Organize it by seam, not as a flat list: for each seam named in *Testing Decisions*, nest under it the tasks that prove it, in the order they need to happen. A seam is *where* the feature gets verified from the outside (an interface boundary that survives a rewrite); a task is a *unit of work* toward proving one — a red test, the implementation that turns it green, maybe supporting plumbing. Most seams expand into a handful of tasks, not one. Some tasks won't serve any single seam (shared setup, a migration, config) — put those in their own bucket rather than forcing them under a seam they don't belong to.

Keep tasks small and concrete enough that "done" is unambiguous, and use checkboxes so progress is visible at a glance:

<plan-template>
## <Seam name>

- [ ] Task
- [ ] Task

## <Seam name>

- [ ] Task

## Supporting work

- [ ] Task (not tied to a single seam)
</plan-template>

`implement` checks off tasks as it goes, so `PLAN.md` stays a live record of where the work actually is, not just a snapshot of the original intent.

### 6. Create a branch

Create and check out a new branch mirroring the spec folder's identifier: `feat/<yyyy_mm>-<name>`, `fix/<yyyy_mm>-<name>`, or `refactor/<yyyy_mm>-<name>`, matching the spec folder's `<type>`. If a branch already exists for this exact piece of work (e.g. you're resuming), check it out instead of creating a duplicate.

### 7. Hand off

Tell the user where the spec and plan were saved, which branch was created, and a one-line summary of what's in the spec. Don't restate the whole document back to them — they just watched it get written, and if it's already surprising to them, the gaps are in the seams or scope, not in how it's summarized.

Then continue directly into implementing it: call the Skill tool with `implement`, in this same conversation, right now — same-session continuation is the default. Skip this only if the user's request made clear they wanted the spec for later ("write a spec for X, I'll get to it"), or if they've asked for this to run as a background handoff instead (call the Skill tool with `claude-handoff` in that case, seeded with the spec's path and branch).

## When the ask is bigger than one spec

If the work is clearly too large for one context window to implement end to end, say so before writing a single monolithic spec, and suggest breaking it into smaller specs or a lighter tracking doc per slice instead. A spec that nobody can implement in one sitting isn't more useful for being longer.
