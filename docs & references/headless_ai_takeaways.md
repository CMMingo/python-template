# Designing for Headless AI: Takeaways for ML / Software Engineers

Source: *Headless AI will make every product a platform* (Patrick Neeman, UX Collective, Sep 2026)
https://uxdesign.cc/headless-ai-will-make-every-product-a-platform-heres-what-to-consider-when-designing-for-this-f219c33245c7

## The main takeaway

Anything you build may be called by a program, often an LLM agent, with no human watching. So the **interface contract** (inputs, outputs, errors, names, permissions) is the product, and the UI is just one client of it.

## What to apply

### 1. Enforce rules in the lowest layer, never only in the client or UI
If a rule matters (permissions, confirmations, limits, validation), it must live in the backend or domain logic. Anything enforced only upstream disappears when a caller bypasses it.

### 2. Know every entry point, and allow no back doors
Keep an inventory of every way in: APIs, tools exposed to agents, webhooks, exports, internal scripts. Avoid direct reads of another component's data store. Go through a defined interface so there is one place to enforce rules and observe usage.

### 3. Write error messages for a caller that can't ask follow-up questions
An agent retries or gives up based on the error text alone. Say which field failed, what was expected, and what was received.

```python
# Unhelpful: the caller can only guess
raise ValueError("invalid request")

# Actionable: the caller can fix it and retry
raise ValueError("field 'date': expected YYYY-MM-DD, got '07/10/26'")
```

### 4. Make failure safe: idempotency, partial success, confirmation
- **Idempotent writes:** a retry with the same key must not duplicate the effect.
- **Partial success on batches:** report which items succeeded and which failed.
- **Irreversible actions:** require an explicit confirmation step.

```python
def create_invoice(key: str, data: InvoiceIn):
    if (saved := store.get(key)):
        return saved            # same key -> same response, no duplicate
    result = _create(data)
    store.set(key, result)
    return result
```

> Edge case: in a real system the "check, then create, then save" sequence must be atomic (a DB unique constraint or a lock). Otherwise two concurrent retries can both pass the check.

### 5. Be tolerant in what you accept, explicit in what you return
Agents produce messy input (dates in several formats, strings instead of numbers). Accept reasonable variations, always return one consistent shape, and **report what you coerced** (e.g. "read as order date"). Silent guessing hides errors from the caller.

### 6. Names and descriptions are part of the interface
Field names, enum values, docstrings, and tool descriptions are what a model reads to decide how to call you. Treat them like UI copy. Define business concepts ("active customer", "booked vs. recognized revenue") once, in one place, so every consumer gets the same meaning.

### 7. Make usage observable per caller and per session
- Give every call a trace or session ID so you can reconstruct *sequences* of calls, not just counts.
- Retry loops mean confusion; a call that precedes abandonment means a dead end.
- Measure task completion (finished without human rescue, correct data, no duplicate writes) rather than page views.

### 8. Test your interface with a model
Give an LLM your schema and a realistic task, then see where it goes wrong. It works like a usability study, and it can be automated as an eval suite that runs on every contract change.

### 9. Decide access policy deliberately
Define scopes (least privilege), rate limits, and which agents are allowed at all, before vendors or platform defaults decide for you.

## ML-specific angle

*(Extrapolation, not from the article, but it follows directly.)*

- **Model endpoints are doors too.** Keep input and output schemas stable and versioned, and return structured outputs.
- **Expose uncertainty and failure modes explicitly** (confidence, "abstained", "input out of distribution") instead of returning a plausible-looking answer. An agent downstream can't judge a bad prediction the way a human glancing at a dashboard might.
- **Treat tools you give to agents as products.** A vague tool description, or an overloaded tool with ten optional parameters, is a design bug that shows up as agent errors.

## Background: the Bezos mandate

The article's "Map Every Door" section references Steve Yegge's retelling of Amazon's early-2000s API mandate:

- Every team exposes data and functionality only through service interfaces (APIs).
- Teams communicate *only* through those interfaces: no direct database reads, no shared memory, no back doors.
- Every interface must be designed so it *could* be exposed to outside developers.

"Interface" here means **API**. The article's point is that headless AI imposes the same discipline on you whether or not anyone sends the memo: agents will use whatever doors exist.

A separate use of the word: "rules enforced by the interface" refers to the **UI** (disabled buttons, confirmation dialogs, hidden fields). Those rules vanish when a caller hits the API directly, which is why rule enforcement belongs in the backend (point 1).

## One-line checklist

For each capability you ship, ask:

1. What can a program do here that a person couldn't through the UI?
2. What does it see when it fails?
3. Could it safely retry?
4. Who owns this contract?
