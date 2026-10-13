---
name: Bug report
about: Something is broken, wrong or slow
labels: bug
---

<!--
How to fill this in (people and agents alike):
- Write for someone who hasn't seen the conversation. Plain words, short bullets.
- Delete a section that doesn't apply instead of writing "N/A". Keep the order.
- Facts first: what you saw and what you ran. Put guesses about the cause under "Suspected cause".
- Title: what is broken and where, as a sentence (`Upload fails for HEIC photos over 10 MB`).
- Checkboxes: [x] means it was actually done, and it says what it showed.
  [ ] means someone still has to do it. Never tick what didn't happen.
-->

Related: <!-- links: the PR that introduced it, a chat thread, a monitoring alert, a duplicate. -->

## What happens

<!--
The problem as a user or operator sees it, and what it costs (lost data, blocked work, wrong numbers).
Paste the exact error message or a screenshot. Don't paraphrase an error.
-->

## Expected

<!-- What should happen instead, in one or two sentences. -->

## How to reproduce

<!--
Exact steps, so someone else can see it in a few minutes. Prefer commands over prose:
```bash
<command to set up or run>
<command to check>   # what you get now
```
If it only happens sometimes, say how often and what changes it.
-->

## Where

<!-- Keep only the lines that matter. -->

- **Area:** <!-- Backend, UI, Infra, CI, Docs -->
- **Version:** <!-- commit, release, or the environment it was seen in -->
- **Environment:** <!-- OS, Python or Node version, browser: only what could change the result -->
- **First seen:** <!-- date, or the last version known to work -->

## Impact

<!-- Who is affected, how many, how badly. Is there a workaround? Say what it is. -->

## Suspected cause

<!--
Optional. A file, commit or theory, and how sure you are.
Label it as a guess if it is one: a wrong cause stated as fact sends the fix the wrong way.
-->

## Done when

- [ ] <!-- Observable condition: "the command above prints X". -->
- [ ] <!-- A test that fails today and passes after the fix. -->
