# Guidelines

(Duplicated guidelines from Claude.md)

## General guidelines

### Dev philosophy

- Small functions. Declarative top levels. Parse at edge, fail fast.
- Flat over nested — early returns, guard clauses, max 3 indentation levels.
- Explicit over implicit. No hidden side effects. Dependencies flow inward.
- Types as documentation. Prefer failing on uncertain cases over handling everything.
- Tests mock collaborators; production never bends to make tests possible.
- Three similar lines is better than a premature abstraction. Don't design for hypothetical future requirements.
- Default to no comments. Only add one when the WHY is non-obvious (hidden constraint, subtle invariant, workaround). Never explain WHAT — names do that.
- No belt and suspenders pattern. Fail fast and surface errors.

### Tooling rules

- Always use scaffolding/init commands to set up projects and packages (`uv init`, `dvc --init`, etc.).
- Always use the package manager to add dependencies. Never hand-write dependency entries.
- Never hand-write auto-generatable config files (lockfiles, tsconfig defaults, etc.) — run the tool and edit the output if needed.
- All imports at the top of the file. Never import inside functions.

### Important constraints

- Everything async where it matters — never block the UI or event loop.
- Every external process gets a hard timeout. No unbounded waits.
- Never commit secrets. Strip credentials from any environment a tool or agent inherits.
- Type checker and linter are gates, not suggestions. Fix the root cause, don't suppress.

### Writing style

- Be brief and direct. Explain what's needed effectively.

## Behavioral guidelines

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

### 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.
- No half-finished implementations. If you can't complete it, say so explicitly rather than leaving stubs.

### 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features or introduce abstractions beyond what was asked. A bug fix doesn't need surrounding cleanup.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested. No backwards-compatibility shims when you can just change the code. No feature flags for hypothetical rollbacks.
- No error handling for impossible scenarios. Trust internal code and framework guarantees. Validate only at system boundaries (user input, external APIs).
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

### 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"
- Root-cause obstacles instead of bypassing them (no `--no-verify`, no silencing type errors, no deleting failing tests).

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

### Anti-Patterns Summary

| Principle | Anti-Pattern | Fix |
|-----------|-------------|-----|
| Think Before Coding | Silently assumes file format, fields, scope | List assumptions explicitly, ask for clarification |
| Simplicity First | Strategy pattern for single discount calculation | One function until complexity is actually needed |
| Surgical Changes | Reformats quotes, adds type hints while fixing bug | Only change lines that fix the reported issue |
| Goal-Driven | "I'll review and improve the code" | "Write test for bug X → make it pass → verify no regressions" |
