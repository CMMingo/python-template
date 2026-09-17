---
name: claude-handoff
description: Hand the current conversation off to a detached background Claude Code agent that keeps working unattended. Use when the user says to run this in the background, hand it off, or let it keep going without them -- e.g. right after /spec, instead of continuing implementation in this same session.
argument-hint: "What should the next session focus on?"
disable-model-invocation: true
---

Write a handoff summary of the current conversation -- enough for a fresh agent with no other context to pick up immediately -- then launch a detached background agent seeded with that summary, instead of continuing here.

## What goes in the summary

- The spec being implemented (path, not a copy of its content) and the branch already checked out for it.
- What's already done vs. what's left (e.g. "spec written and branch created, implementation not started" or "implementation done through seam 2 of 3").
- Which skills the next agent should reach for -- name `implement` explicitly; it loops through `tdd`, `logic-checker`, and `code-reviewer` on its own, seam by seam, until the spec is done, then stops and reports ready for `/commit-push` -- a separate, explicit step the next agent still has to trigger.
- Any decision made in this conversation that isn't already captured in the spec, `CONTEXT.md`, or an ADR -- reference those files by path rather than repeating their content.
- Redact anything sensitive (API keys, credentials, PII) before it goes in -- this summary becomes the next session's prompt verbatim.

## Launching it

Use the background-agent flag your installed Claude Code CLI exposes for this (recent versions: `claude --bg --name "<descriptive name>" "<summary>"`) -- check `claude --help` first, since flags here have changed across versions and shouldn't be assumed. Always give it a descriptive `--name` (e.g. "Implement batch endpoint") so it's identifiable later in `claude agents`.

For it to actually run unattended -- not stop and wait at the first tool call -- it needs an auto-approval permission mode. Check `claude --help` for the current flag rather than assuming the one you last used still applies, and confirm with the user which mode they want before launching: this trades the normal per-action approval for autonomy, and that's their call, not a default to reach for silently.

The `test-gate` and destructive-command guardrail hooks still apply inside a background or headless run exactly as they do in an interactive one -- that's what makes handing off full autonomy survivable rather than reckless.

## When to use this vs. staying in-session

Default to continuing in the same conversation -- the `implement` skill does this automatically right after `/spec`. Reach for this instead only when the user explicitly wants to close the session and have the work continue without them: "run this in the background," "let it keep going," "I'm heading out, keep working on this."
