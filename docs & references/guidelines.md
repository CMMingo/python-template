# Guidelines

(Duplicated guidelines from Claude.md)

## General guidelines

### Dev philosophy

- Small functions. Declarative top levels. Parse at edge, fail fast.
- Flat over nested — early returns, guard clauses, max 3 indentation levels.
- Explicit over implicit. No hidden side effects. Dependencies flow inward.
- Types as documentation. Prefer failing on uncertain cases over handling everything.
- Tests mock only system boundaries (network, time, randomness, heavy models), never your own modules. Production code carries no test-only code (no flags, hooks or exposed internals); passing a dependency in as an argument is ordinary design, not that.
- Three similar lines is better than a premature abstraction. Don't design for hypothetical future requirements.
- Default to no comments. Only add one when the WHY is non-obvious (hidden constraint, subtle invariant, workaround). Never explain WHAT — names do that.
- No belt and suspenders pattern. Fail fast and surface errors (see Errors and Interfaces below).

### Tooling rules

- Always use scaffolding/init commands to set up projects and packages (`uv init`, `dvc init`, `npm create vite@latest`, etc.).
- Always use the package manager to add dependencies. Never hand-write dependency entries.
- Never hand-write auto-generatable config files (lockfiles, tsconfig defaults, etc.) — run the tool and edit the output if needed.
- All imports at the top of the file. Never import inside functions.

### Important constraints

- Everything async where it matters — never block the UI or event loop.
- Every external process gets a hard timeout. No unbounded waits.
- Never commit secrets. Strip credentials from any environment a tool or agent inherits.
- Type checker and linter are gates, not suggestions. Fix the root cause, don't suppress.

### Errors

- Raise specific exceptions, never a bare `Exception`. Keep a small hierarchy under one project base error (for example `AppError`, with `ValidationError`, `NotFoundError`, `ConflictError` below it) so callers handle errors by type, not by parsing text. Catch a broad `Exception` only at the outermost boundary, where you log it and return a safe, structured error.
- Write every message for a caller that cannot ask follow-up questions, whether an agent or a person reading a log: say what failed, what was expected and what was received (the field, the value, never a secret), and the fix when there is one. Say whether the caller can fix it (bad input, not found, conflict) or not (internal failure, a dependency is down), so it knows whether to retry.

```python
# Unhelpful: the caller can only guess
raise ValueError("invalid request")

# Actionable: the caller can fix it and retry
raise ValidationError("field 'date': expected YYYY-MM-DD, got '07/10/26'")
```

- Handle an exception only where you can do something useful with it: retry, fall back, translate it, or add context. Otherwise let it propagate. When you re-raise, keep the cause (`raise NewError(...) from err`) and add context instead of replacing it.
- Errors a caller can see are part of the interface: stable types and codes, and no stack traces, paths, SQL or secrets in them (those go to the logs).

### Interfaces: anything a program or agent can call

Applies to APIs, CLI commands, agent tools, webhooks, exports and public library functions. Assume a program, often an LLM agent, calls them with no human watching, so the contract (inputs, outputs, errors, names, permissions) is the product and any UI is just one client of it.

- Enforce every rule (permissions, limits, validation, confirmations) in the lowest layer, the backend or domain logic, never only in a UI or client. Anything enforced upstream disappears when a caller bypasses it.
- Know every entry point and allow no back doors. Keep the list of ways in (APIs, agent tools, webhooks, exports, scripts) current in the README. One component never reads another's data store directly: it goes through a defined interface, so there is one place to enforce rules and observe use. Design each interface as if it could be exposed to outside callers.
- Make failure safe. Writes a retry can repeat are idempotent (same key, same effect, no duplicate; make check-then-create atomic with a unique constraint or a lock). Batch operations report which items succeeded and which failed. Irreversible actions require an explicit confirmation step.
- Be tolerant in what you accept, explicit in what you return. Accept reasonable variations at the edge (dates in several formats, numbers as strings), always return one consistent shape, and report what you coerced. If an input is ambiguous, fail with a clear error instead of guessing: silent guessing hides errors from the caller.
- Names are part of the interface. Field names, enum values, docstrings and tool descriptions are what models and people read to decide how to call you, so make them precise and unambiguous, and define each business concept once, in `CONTEXT.md`. A public function, endpoint or tool gets a docstring that states its contract (inputs, outputs, the errors it raises); the default of no comments is about code, not contracts. Keep tools small: one job each, not one with ten optional parameters; a vague or overloaded tool is a design bug that shows up as agent errors.
- Make use observable per caller and per session. Every call carries a trace or session ID, logged together with failures, so sequences of calls can be reconstructed. Retry loops signal confusion, and a call before abandonment signals a dead end. Measure task completion (finished without human rescue, correct data, no duplicate writes), not page views.
- Test the interface with a model: give an LLM the schema and a realistic task and see where it goes wrong, then automate it as an eval that runs on every contract change.
- Decide access deliberately: least-privilege scopes, rate limits, and which callers are allowed at all, before platform defaults decide for you.
- Model endpoints are doors too. Keep input and output schemas stable and versioned and return structured outputs. Expose uncertainty and failure modes explicitly (confidence, "abstained", "input out of distribution") instead of a plausible-looking answer that an agent downstream cannot judge.

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
- The exception is an `implement` run, where nobody may be there to answer: make the best-supported call, flag it as an assumption in the report, and stop only if the guess would be hard to undo.
- No half-finished implementations. If you can't complete it, say so explicitly rather than leaving stubs. The exception is a step-by-step mode such as `handcraft`, where labelled stubs are part of the method; resolve every one before any commit.

### 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features or introduce abstractions beyond what was asked. A bug fix doesn't need surrounding cleanup.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested. No backwards-compatibility shims when you can just change the code. No feature flags for hypothetical rollbacks.
- No error handling for impossible scenarios. Trust internal code and framework guarantees. Validate at every boundary a caller can reach (user input, external APIs, agent tools) and enforce the rules in the lowest layer, not only in a client.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken. The cleanup `tdd` and `implement` do applies only to code this change added or modified; mention anything you notice in older code instead of touching it.
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
