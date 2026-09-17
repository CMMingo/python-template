# Working With Your AI-Native SDLC

You've built the machine: skills, subagents, hooks, a debugging track, guardrails. Nobody has run a real feature through it yet. This document is about the other half — the part that doesn't live in `.claude/`: how *you* need to work differently to actually get the output your boss got in three days, instead of the same output you got before, just with more steps.

The short version: the system removes typing as your bottleneck. It does not remove thinking as your bottleneck. Everything below is about moving your attention to where it's now the scarce resource — decisions, specs, and judgment — and getting it off where it no longer needs to be — typing code, re-reading every line, running commands by hand.

---

## 1. The mental model shift

Before: you think, then you type, then you test, then you fix, then you commit. One person doing four jobs serially.

Now: you think and decide (spec, seams, scope). An agent types, tests, and self-corrects across three separate checks (`logic-checker`, `tdd`'s own loop, `code-reviewer`) before you look at anything. You review a *report*, not a typing process. You commit deliberately, once, when you mean to.

The failure mode to watch for in yourself: hovering. Watching `implement` seam-by-seam like you're pair programming defeats the point — if you're going to supervise every step at that resolution, you haven't actually delegated anything, you've just added narration. The system is built with three independent checks specifically so you don't have to be the fourth. Read the final report. Spot-check if something feels off. Don't re-derive the whole diff yourself line by line — that's what `code-reviewer` is for, and it doesn't get tired or skim.

The other failure mode: the opposite. Treating a spec as a formality to rush through so you can "get to the real work." The spec *is* the real work now. Everything downstream — how cleanly `implement` runs, whether it needs to stop and ask you something, whether the seams are testable at all — is downstream of how good the spec is. Fifteen extra minutes in `/grill-with-docs` buys you an unattended hour of `implement` looping through the whole spec later. Skipping it buys you a `/spec` that invents decisions nobody made, and an implementation built on a guess.

---

## 2. The core loop, in practice

For anything beyond a one-line fix:

1. **`/grill-with-docs`** if the idea isn't already concrete — this is your default now, not `/grill-me` (you already made that call: `grill-me` doesn't ground itself in the repo or leave anything behind for the next step, so unless you're exploring something genuinely repo-agnostic, use the one that does).
2. **`/spec`** — writes `docs/specs/<slug>.md`, agrees the seam(s), creates the branch. Push back if it's inventing scope you didn't ask for; that's exactly the failure mode it's built to avoid, but it's not infallible.
3. **`implement`** (or `claude-handoff` — see §3) — builds it, seam by seam, looping on its own until the whole spec is done, with `logic-checker` catching "passes the test but isn't what you asked for" and `code-reviewer` catching "works but has a real problem" at the end.
4. **`/commit-push`** — deliberately, when you decide the work's done. Never automatic.
5. **`changelog-writer` / `readme-updater`** — keep docs honest, low-stakes, cheap to run often.
6. **PR** — still yours, by design.

Something's actually broken instead of not-yet-built: that's `diagnosing-bugs` → `debugger`, a different track entirely, not a variant of the above. Don't debug ad hoc inside an `implement` run — if a failure isn't obviously explained, let it hand off.

---

## 3. Pick your mode by how much attention you're spending on this specific thing

This is probably the single highest-leverage habit change, and it's also how you parallelize the way your boss did.

| You're... | Use | Why |
|---|---|---|
| At your desk, watching or catching up on reports as they land | `implement` | Loops through every seam on its own, reporting as it goes — it never pauses to wait for you, so it's your call whether to read each report live or catch up once at the end. |
| Stepping away, or want two things happening at once | `claude-handoff` | Detached background agent, keeps going without you. The hooks (`test-gate`, destructive-command guard) apply exactly the same — that's what makes this safe rather than reckless. |
| Want deliberate, function-by-function control | `handcraft` | The opposite end from `implement`'s autonomous loop — for when you specifically want to be the one making every call, not for routine feature work. |

**This is how you get three days of output out of what used to take three days of typing:** don't run one thing at a time. Write two or three specs in a row (each on its own branch — `/spec` handles that), send the ones you don't need to babysit off via `claude-handoff`, let `implement` keep looping unattended on the ones still in this session, and spend your actual attention on the one that needs it, or on writing the *next* spec while the others run. Your bottleneck stops being "how fast can I type this feature" and becomes "how many well-specified units of work can I keep in flight." That's the actual shape of the productivity jump — not a faster you, a parallel you.

The precondition for this working is §1's second failure mode: specs good enough that an unattended agent doesn't wander. If you're not there to catch a wrong turn, the spec has to have already closed it off.

---

## 4. Habits worth deliberately changing

**Write smaller specs than feels natural.** One seam is the stated ideal, two or three is the ceiling before `/spec` itself should tell you to split it. A smaller spec is safer to run unattended, easier to review the report of, and easier to revert if it's wrong. Three small specs in parallel beats one big one run serially, both for wall-clock time and for risk.

**Stop reviewing at the character level; start reviewing at the decision level.** When `implement` reports back, the questions that matter are: did it flag any assumptions (check those specifically — that's where a silent wrong turn would surface), did `code-reviewer` find anything real, does the *Implementation Decisions* section still match what you actually wanted. You're auditing decisions, not diffs.

**Use `/doubt` instead of silently re-checking things yourself.** If something an agent did or claimed doesn't sit right, `/doubt` is a structured way to get a real verdict (right, wrong, or genuine tradeoff) with sources, instead of you quietly re-deriving the answer in your head and either dropping it or awkwardly re-litigating it in prose.

**Use `/walkthrough` on anything an agent built that you didn't watch get built.** This is how you avoid the real risk of this workflow: losing your own mental model of your codebase because you stopped writing the code by hand. If `implement` or `claude-handoff` produced something while you were elsewhere, walk through the actual path once before you consider it yours. Five minutes of guided tour is cheap insurance against "I don't actually know how my own service works anymore."

**Trust the integration-first testing bias you already set.** You told `tdd` to default to functional/integration seams over unit tests. That means the test suite is your regression safety net for *behavior*, not a line-by-line proof of every internal function. Don't reach for unit tests out of old habit when a test fails and you're unsure why — that's what `diagnosing-bugs` is for, not a reason to add narrower tests defensively.

**Let `debugger` be genuinely different from you fixing it yourself.** Its whole value is the skepticism discipline (rank hypotheses, don't anchor on the first plausible story, look outside the obvious code path). If you jump in and patch the symptom yourself the moment something breaks, you've spent the effort of building this track for nothing. Hand it off, actually wait for the ranked hypotheses, and use your own judgment on *those* — not on the raw stack trace.

**Treat `/commit-push` as your checkpoint, not a formality.** It's the one step in the whole pipeline that only fires when you say so. That's deliberate — use the moment before you run it to actually ask "am I ready to have this be true," not just run it because the report said "ready."

**Invest in `CONTEXT.md` and ADRs like they're compounding interest.** Every `grill-with-docs` session that resolves a term or records a decision makes every *future* `/spec`, `implement`, and `debugger` run faster and less likely to guess wrong — including ones in a `claude-handoff` session with zero shared history with you. This is the actual mechanism behind "an agent that doesn't need everything re-explained": it's not memory, it's that the domain model is written down somewhere every fresh context reads first.

---

## 5. What this doesn't remove

You're still the one who decides what's worth building, still the one who owns product judgment, still the one opening the PR, still the one who has to actually understand the system well enough to be accountable for it. The pipeline removes the mechanical cost of turning a decision into working, tested code. It doesn't remove the cost of making good decisions. If anything, since that's now the whole job, it's worth protecting that time more deliberately than before — that's where "three days of high-quality output" actually comes from: not faster hands, faster *decisions*, made possible because everything downstream of a decision now runs largely on its own.

---

## 6. Before you trust it on something that matters

Nothing here has run against a real feature yet. Before you lean on an unattended `implement` run or `claude-handoff` for something you care about:

1. Run one small, low-stakes, real feature through the full loop with plain `implement`, watching each seam.
2. Deliberately introduce one ambiguity into a spec and see whether `implement` flags it as an assumption the way it's supposed to, rather than guessing silently.
3. Let one bug go through `diagnosing-bugs` → `debugger` and read the ranked hypotheses before the fix, to calibrate how much you trust its reasoning.
4. Only then graduate to running something unattended.

Calibration first, autonomy second — in that order, not the reverse.
