---
name: update-docs
description: Update one documentation file so it matches the project as it is now. Invoke explicitly with /update-docs <file> -- it does not trigger itself. A README goes to the docs-updater agent (what the project is and does today, no history); CHANGELOG.md goes to the changelog-writer agent (the technical changes and why).
argument-hint: "<path of the doc to update, e.g. README.md or CHANGELOG.md>"
disable-model-invocation: true
---

This skill needs the path of the file to update. If none was given, ask which one (offer `README.md` and `CHANGELOG.md`, plus any file under `docs/` that looks relevant) rather than guessing. Then route by what the file is:

- **`CHANGELOG.md`** -- dispatch the `changelog-writer` subagent with the path. It records the technical differences and the reason for each, following the file's own Keep a Changelog template.
- **A README** (the root `README.md` or any other) -- dispatch the `docs-updater` subagent with the path. Tell it whether this is the root README: for that one it keeps a simple, organized structure that works as the repository's starting point.
- **Any other doc** (a guide, a reference page) -- dispatch `docs-updater` with the path and tell it the file is not a README, so it applies the same current-state rules and keeps the file's own purpose and structure.

The two kinds of document are deliberately different. A README describes what exists **now**, functionally, and never how we got here. A changelog is the **history**: what changed and why, in technical terms. Don't mix them, and don't ask one agent to touch the other's file.

Relay the agent's report back (what it changed, and anything it was unsure about) rather than re-summarizing it. Don't commit; that is a separate step (`/commit`).
