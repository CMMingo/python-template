---
name: grilling
description: Interview the user relentlessly about a plan, decision, or idea until nothing is left silently assumed. Use when the user wants to stress-test their thinking, mentions "grill" or "grilling", or when another skill needs a structured interview before it can proceed.
---

Interview the user relentlessly until you reach a shared understanding. Map this as a **design tree**: every decision branches into the decisions that hang off it.

Work the tree in **rounds**. The **frontier** is every decision whose prerequisites are already settled: the questions you can ask _now_ without guessing at answers you haven't heard yet. Ask the whole frontier in one round: number each question and give your recommended answer. Then wait for the user's answers before the next round.

Format a round like so:

\`\`\`
❓ **Q1** - **<question title>**: <question body, might be multiple paragraphs, including multiple choices>

➡️ <your recommended answer>

---

❓ **Q2** - **<question title>**: <question body, might be multiple paragraphs, including multiple choices>

➡️ <your recommended answer>
\`\`\`

Each round the user answers reshapes the tree: settled decisions push the frontier outward and unblock questions that depended on them. Recompute the frontier and ask the next round. A question whose answer depends on another question still open in this round belongs to a _later_ round, not this one.

Finding _facts_ is your job, never the user's. When a frontier question needs a fact from the environment (filesystem, tools, etc.), dispatch the `context-scout` subagent to find it; don't ask the user for anything you could look up yourself. Don't block on it: a running exploration is an unsettled prerequisite, so only the questions downstream of it wait for the sub-agent to report; ask the rest of the frontier now. The _decisions_ are the user's: put each to them and wait.

There is deliberately no cap on the number of questions here — some plans need three, some need fifty, and a fixed ceiling either truncates the hard case or feels arbitrary on the easy one. If a session runs long, that's usually a sign the scope is too big for one sitting, not a reason to force it to a close; say so and suggest breaking the work up instead.

The session is done when the frontier is empty: every branch of the design tree visited, nothing left silently assumed. Do not act on it until the user confirms you have reached a shared understanding.

## If you want one question at a time instead

The round-based format is the default because it moves faster, but it isn't for everyone — if you read slowly, work in a second language, or just prefer a sequential rhythm, add a line to your own \`CLAUDE.md\`: "When grilling, ask one question at a time." Respect it if it's there.
