---
name: grill-me
description: A relentless interview to sharpen a loose idea or plan before committing to it — pure interview, no spec or docs written. Invoke explicitly with /grill-me; it does not trigger itself.
disable-model-invocation: true
---

Call the Skill tool with "grilling".

This is the plain, stateless front door to that interview: no repo required, nothing written to disk, nothing decided for you. Use it whenever you have an idea worth taking seriously but haven't worked out what it involves yet — a feature, a technical direction, even something non-technical. If you can already specify the thing precisely, you don't need this; go straight to \`/spec\` (or just start building) instead.

You own the scope, not the skill. The failure mode here is passivity — agreeing your way through forty questions and coming out with a plan you nodded at rather than one you actually own. Push back when a question is pitched at the wrong level of detail, say "I don't know" when that's the honest answer, and say when you think the scope is drifting.

Some questions can't be settled by talking — "does this interaction feel right" needs something to react to, not more discussion. When you hit one of those, stop grilling, build or sketch the smallest throwaway version, look at it, then come back and answer in one line.

If what came out of this session turns out to be a software feature worth a durable record, don't start a fresh conversation — hand this same conversation straight to \`/spec\`. The value of the session is the context you just built together; a fresh session would just have to re-derive it.
