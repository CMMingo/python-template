---
name: tdd
description: Test-driven development — write the failing test first, then just enough code to pass it, one seam at a time. Use when implementing new behavior or fixing a bug that has a clear input/output, when the user mentions TDD, "red-green", or "test-first", or before writing implementation code for anything with a testable seam.
---

# Test-Driven Development

TDD here means red → green, nothing more: write one failing test, then just enough code to pass it, then the next one. This skill is the reference that makes that loop produce tests worth keeping — what a good test is, where tests go, the anti-patterns that quietly ruin a suite, and the ML-specific rules generic TDD guidance misses.

There's a narrow exception and a hard line here. The exception: **tidy** the code you just wrote, immediately after it goes green, if the tidy is confined to that same code — a rename, collapsing an obvious duplication within the function you just touched, deleting dead code the last change made unreachable. That's small enough to stay safe under the test you just wrote, and cheap enough that deferring it just means forgetting it.

The hard line: no broader **refactoring** mid-loop — restructuring across seams, extracting a new shared abstraction, changing an interface, anything that touches code beyond what the current test exercises. That's a separate pass with a separate mindset, and folding it into this cycle is how "just enough code to pass" quietly becomes "let me also clean this up while I'm here," ballooning a one-seam diff into something unrelated and harder to review. Note those larger opportunities as you notice them — `implement` runs a dedicated refactor pass for them once every seam is covered, rather than leaving them as notes nobody acts on.

Read `CONTEXT.md` first if it exists, so test names and interface vocabulary match the project's own domain language, and respect any ADRs in the area you're touching.

## Seams: agree them before writing a single test

A **seam** is the public boundary you observe behavior at — the interface you call, without reaching inside to check how it worked. No test gets written against an unconfirmed seam.

If a `/spec` already exists for this work, its Testing Decisions section already named the seam — use that one, don't re-ask. Otherwise, before writing anything, name the candidate seam(s) yourself and confirm with the user: "the public interface here is `X`; I'll test through it, not against `Y` internals — sound right?" This is the cheapest point to fix a wrong test boundary; catching it after a full suite is built around it is expensive.

Prefer the highest-level seam that still exercises real behavior, and prefer one that already exists over inventing a new one. If picking the seam turns into its own hard design question — how deep an interface should be, where a module boundary belongs — that's a different problem than TDD is solving; say so rather than picking arbitrarily.

**Default to a functional/integration seam, not a unit seam.** Most behavior worth locking down is observable through a real entry point — a function's public API, an endpoint, a CLI command, a pipeline stage — exercising its actual collaborators, not through an isolated unit wired up with mocks. A pile of narrow unit tests that each exercise one internal function in isolation adds maintenance surface (more fixtures, more mocks, more brittle coupling to internals that are free to change) without buying much confidence that the pieces actually work together. That surface is a cost, not a neutral extra — don't pay it by default.

Write a unit test only when a case genuinely can't be covered well at the integration seam: a pure function with many input/output combinations that would be combinatorially expensive to drive through the full stack, an edge case only reachable by forcing an unusual internal state, or logic complex enough to deserve its own focused proof independent of what's around it. When in doubt, write the integration-level test first; add a narrower unit test only if something real is still uncovered after that.

## What a good test is

A test verifies behavior through the agreed seam, not through internal structure. The code behind the seam can be rewritten completely and the test shouldn't notice. A good test name reads like a capability: "batch predict returns results in input order," not "predict_batch calls predict in a loop."

**Good** — tests the interface, expected value from an independent source:

```python
def test_batch_predict_preserves_order():
    result = predict_batch(["short", "a much longer piece of text"])
    assert [p.label for p in result] == ["negative", "positive"]  # known from the fixture's construction, not recomputed
```

**Bad — implementation-coupled**: breaks on a refactor even though behavior didn't change.

```python
def test_batch_predict_calls_predict_for_each_item(mocker):
    spy = mocker.spy(inference, "predict")
    predict_batch(["a", "b"])
    assert spy.call_count == 2  # tests HOW, not WHAT
```

**Bad — tautological**: the expected value is computed the same way the code computes it, so it can't fail.

```python
def test_calculate_total():
    items = [10, 5]
    expected = sum(items)          # recomputes the implementation
    assert calculate_total(items) == expected
```

```python
def test_calculate_total():
    assert calculate_total([10, 5]) == 15   # independent, known literal — good
```

**Bad — horizontal slicing**: a batch of tests written before any implementation exists. They test the *shape* you imagine, not behavior you've observed, and you commit to a test structure before you understand the real one. Work in vertical slices instead: one test → the minimal code to pass it → repeat. Each cycle is a tracer bullet that tells you something the last one didn't.

## Mocking

Mock only at system boundaries: external APIs, the network, time, randomness, and — for ML code specifically — a real model checkpoint that's slow or heavy to load. Never mock your own modules or internal collaborators; if you find yourself mocking something you wrote to make a test pass, the seam is probably wrong, not the mock.

Design for it with dependency injection rather than reaching for a patch:

```python
# Easy to test: the model is passed in, not constructed inside
def predict(text: str, model: LoadedModel) -> Prediction: ...

# Hard to test: the function owns its own dependency
def predict(text: str) -> Prediction:
    model = load_model()  # every test now pays the load cost, or needs to patch this
    ...
```

## ML-specific rules

Generic TDD guidance assumes exact, deterministic outputs. Model and pipeline code usually isn't, so a few extra rules apply on top of everything above:

**Never assert exact equality on a float that came from a model.** Use a tolerance (`pytest.approx(expected, abs=1e-3)` or an explicit epsilon check) for scores, probabilities, embeddings, or anything else that's a floating-point model output. An exact-equality assertion on a model score is a test that will break the next time anyone touches the model, for reasons that have nothing to do with correctness.

**Keep fixtures small, explicit, and checked in.** A test that depends on live model weights, a network call, or a randomly-sampled row from a large dataset isn't a unit test — it's an integration test wearing a unit test's clothes, and it will be slow and occasionally flaky for reasons that have nothing to do with the code under test. Put small, representative fixture data in `tests/fixtures/`; if the data is genuinely large, reference a fixed, versioned slice via DVC rather than "whatever's in `data/` right now."

**Seed anything with irreducible randomness, and test properties, not exact output.** If a piece of code samples, shuffles, or otherwise depends on randomness that can't be removed, seed it explicitly in the test. Where even a fixed seed doesn't give a stable exact output (e.g. across library versions or hardware), test a property that should hold (a score is within a range, a distribution sums to 1) rather than a single expected value.

**A flaky test gets marked and logged, never silently retried or deleted.** If a test fails intermittently for reasons you can't immediately fix, mark it explicitly (`@pytest.mark.flaky(reason="...")` or equivalent) with a one-line reason, rather than adding a retry loop or quietly removing the assertion that's causing trouble. A test suite where flakiness is invisible is one nobody trusts, and one where it's silently paved over is one that's stopped telling you anything.

## Rules of the loop

- **Red before green.** Write the failing test first, run it, confirm it fails for the reason you expect — then write just enough code to pass it. Don't anticipate the next test or add anything speculative.
- **This assumes new behavior.** For a pure refactor — restructuring that's meant to change nothing observable — invert it: confirm the seam's tests already pass against current behavior first (write characterization tests if the seam isn't already covered), then restructure while keeping them green the entire time. Seeing red during a refactor means the restructuring changed behavior, which is itself the finding — stop and reconcile it, don't treat it as an ordinary red step to code your way through.
- **One slice at a time.** One seam, one test, one minimal implementation, then repeat. Never a batch of either.
- **The loop ends when the agreed seam's behavior is covered**, not when you run out of ideas for edge cases. If new edge cases keep surfacing, that's a sign the seam or the scope needs revisiting, not a sign to keep looping indefinitely.

## Handoff

Once the agreed seam's behavior is covered, this loop is done -- don't keep it open waiting for a review. If the change is heading to commit or a PR, dispatch the `code-reviewer` subagent for an independent, fresh-eyes pass first; it's read-only and won't touch what you just built. The test-gate hook still enforces `make test` passing before `git commit` either way -- the review is for things a passing suite can't catch (a wrong seam, a security gap, a contradicted ADR).
