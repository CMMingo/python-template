# Decide the frontend

Nothing is installed in this folder on purpose. The right frontend depends on what the product
needs, and that is easier to decide with the project in front of you than when the repo is created.
This guide is for the person starting the frontend, human or agent: answer the questions in order,
write the answers into the **Decision** section at the bottom, then scaffold.

If you are an agent: do not pick for the user. Ask the questions in step 1 and 2, propose an
answer with the reason, and wait for a yes.

## 1. What kind of interface is it?

| It is... | Use | Why |
| --- | --- | --- |
| An app people log into: dashboard, admin, internal tool, editor. The API lives in `backend/` | **A single-page app built with Vite** | Static files that call the backend's API. Simple to build and host, and search engines don't matter behind a login |
| A public site that must rank in search or show previews when shared: marketing, shop, blog | **A server-rendering framework**: Next.js (React), Nuxt (Vue) or SvelteKit (Svelte) | The server sends finished HTML, which search engines and link previews need. It adds a Node server to run and deploy |
| Mostly text and pages that rarely change: docs, a content site | **Astro** (or a static site generator) | Ships almost no JavaScript, and is cheap to host |
| A demo, prototype or internal showcase of data or ML work, where the UI is secondary | **A Python UI: Streamlit or Gradio** | No JavaScript at all. It can live in `backend/`; if you choose it, delete `frontend/` and its CI job disappears on its own |
| One small page with a few interactions | **Vite with vanilla TypeScript** | No framework to maintain |
| A mobile or desktop app | Out of scope here | Look at React Native, or Tauri for desktop |

When unsure between the first two rows: ask whether a stranger needs to find the pages through a
search engine. If not, the single-page app is almost always the right start.

## 2. Which framework?

Only if step 1 left a choice. Default to **React** unless you have a reason not to.

- **React**: the largest ecosystem, the most libraries, tutorials and answers, and the one AI
  agents know best. The safe default.
- **Vue**: gentler to learn, with routing and state management that come as official packages.
  A good pick if the team already knows it.
- **Svelte**: the least code to write, and fast. The ecosystem is smaller.

Always use **TypeScript**. It is how the frontend learns what the API returns, and it catches
mistakes before the browser does.

## 3. Defaults for everything else

Take these unless the project gives a reason to change one.

| Need | Default | Notes |
| --- | --- | --- |
| Package manager | npm | Already on any machine with Node |
| Styling | Tailwind CSS | Plain CSS or CSS modules also work. Avoid mixing several approaches |
| Components | shadcn/ui (React) or the framework's most used kit | Only when you need ready-made buttons, dialogs and tables |
| Talking to the backend | `fetch`, plus TanStack Query for caching and loading states | Keep every request in one `api/` module |
| API types | Generate them from the backend's OpenAPI schema (`openapi-typescript`) | FastAPI publishes it at `/openapi.json`. This keeps both sides in step |
| Unit tests | Vitest, plus Testing Library for components | Tests live next to the code, as `*.test.ts` |
| Linting | ESLint (or oxlint) | Whatever the scaffold ships is fine |
| Dev server | The Vite dev server, proxying `/api` to the backend | Avoids CORS during development |

## 4. Scaffold it

1. Fill in the **Decision** section below, then copy it into an ADR under `docs/ADRs/` if it
   should outlive this file.
2. Delete this file. Scaffolding tools refuse a folder that isn't empty.
3. Scaffold with the framework's own command, never by hand. For a Vite single-page app:

   ```bash
   npm create vite@latest frontend -- --template react-ts
   ```

   Use `vue-ts`, `svelte-ts` or `vanilla-ts` for the other frameworks. For a server-rendering
   framework use its own command instead, for example `npx create-next-app@latest frontend`.
4. Add Vitest: `cd frontend && npm install --save-dev vitest`.
5. Pin exact versions, so nothing moves between machines (the backend does the same):
   - create `frontend/.npmrc` containing `save-exact=true`, so later installs are exact;
   - replace every `^` or `~` in `package.json` with the installed version, then run
     `npm install` once more to refresh `package-lock.json`.
6. Commit `package.json` and `package-lock.json`.

## 5. What the rest of the project expects

The Makefile, CI and pre-commit already know about `frontend/`. They start working as soon as
`frontend/package.json` exists, if it has these scripts:

| Script | Used by | Notes |
| --- | --- | --- |
| `lint` | `make lint-frontend`, CI, the pre-commit hook | Vite's React template has one. Add `oxlint` for the others |
| `test` | `make test-frontend`, CI | `vitest run`; add `--passWithNoTests` until the first test exists |
| `build` | CI | Catches type errors the linter doesn't |
| `dev` | You | Starts the dev server |

Also, once the frontend exists:

- Uncomment the `npm` block in `.github/dependabot.yaml` (it needs a `package.json` to point at).
- Fill in `BACKEND_CMD` and `FRONTEND_CMD` in `scripts/dev.sh`, so `make dev` starts both servers.
- Add the stack to the *Stack & tools* section of `AGENTS.md`.
- If the frontend is Python-only (Streamlit, Gradio), skip all of the above and delete `frontend/`.

## Decision

Fill this in, then follow step 4.

- **Kind of interface:**
- **Framework and language:**
- **Styling:**
- **Why:** <!-- the one or two facts that decided it -->
- **Decided on:** <!-- date -->
