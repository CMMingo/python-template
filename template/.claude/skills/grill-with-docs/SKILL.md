---
name: grill-with-docs
description: A relentless interview to sharpen a plan or design in the context of this repo, which also writes CONTEXT.md and ADRs as it goes. Invoke explicitly with /grill-with-docs; it does not trigger itself.
disable-model-invocation: true
---

Call the Skill tool with "grilling", then call the Skill tool with "domain-modeling". Run the interview grounded in this repo (read the code, `CLAUDE.md`, and any existing `CONTEXT.md`/`docs/adr/` before asking anything) rather than treating the subject as portable.

Use this instead of `/grill-me` whenever you're in a working repo and the change is worth settling before you build it — `grill-me` is for ideas with no codebase behind them yet; this is for a change to one you're standing in.

When the session ends, don't start a fresh conversation for `/spec` — hand this same conversation straight to it. The value here is the shared understanding and settled vocabulary you just built; a fresh session would have to re-derive both.
