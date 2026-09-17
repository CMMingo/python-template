# Productivity

General workflow tools, not code-specific.

## User-invoked

Reachable only when you type them (Claude Code: `disable-model-invocation: true`).

- **[grill-me](./grill-me/SKILL.md)**: Get relentlessly interviewed about a plan or design until every branch of the design tree is resolved. No repo needed, writes nothing to disk.
- **[handoff](./handoff/SKILL.md)**: Compact the current conversation into a handoff document so another agent can continue the work.
- **[teach](./teach/SKILL.md)**: Teach the user a new skill or concept over multiple sessions, using the current directory as a stateful teaching workspace.
- **[to-questionnaire](./to-questionnaire/SKILL.md)**: Turn a decision you can't answer alone into a Markdown questionnaire for the one person who can (filled in async, or together over a meeting).
- **[wait-what](./wait-what/SKILL.md)**: Fire this the moment a message doesn't land. The agent re-pitches it with the context you're missing, in plain English, using your `CONTEXT.md` vocabulary.
- **[lbt](./lbt/SKILL.md)**: Learning-by-teaching loop -- explain something in your own words, get told what's correct, wrong, conflated, or missing, then teach it again until it's right.
- **[mvk](./mvk/SKILL.md)**: Minimal Viable Knowledge -- research any hobby or field to "level-1 enthusiast lurker" depth and deliver it as a self-contained interactive HTML mini-site (history, people, lingo, drama, and how to read a spec sheet if it has gear).
- **[rp](./rp/SKILL.md)**: Roleplay QA -- dispatch a context-free subagent to play a blind end user against the real product (UI/CLI/API only, no reading source), to surface where real users get confused or stuck.

## Model-invoked

Model- or user-reachable (rich trigger phrasing so the model can reach for them).

- **[writing-for-agents](./writing-for-agents/SKILL.md)**: Writing documents for agents: skills, AGENTS.md/CLAUDE.md, and any doc an agent reaches by a pointer.
