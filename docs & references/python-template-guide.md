# Python Project Template — Complete File Reference

This document explains every file in the template: what it is, what it does, what the code inside means, and when it becomes relevant in a real project. It covers the three project layouts the template can generate; sections say which layout a file belongs to.

---

## How the template works

Before diving into individual files, it helps to understand Copier's mechanics.

The repo has two levels:

```text
python-template/
├── copier.yml          ← Copier's control file (questions, derived variables, setup tasks)
└── template/           ← everything here gets copied into your new project
```

When you run `copier copy --trust gh:you/python-template ./my-project`, Copier reads `copier.yml`, asks the questions defined there, copies everything inside `template/` into `my-project/` (substituting `{{ variable }}` placeholders along the way), and finally runs the setup tasks.

Files ending in `.jinja` are treated as Jinja2 templates — the `.jinja` extension is stripped after rendering, so `pyproject.toml.jinja` becomes `pyproject.toml` in your project. Files without `.jinja` are copied verbatim. File and folder **names** are rendered too, which is how one template produces different trees:

- **A name that renders to an empty string is skipped**, together with everything inside it. A folder called `{% if use_ml %}notebooks{% endif %}` exists only when `use_ml` is on.
- **A name can render to a path.** A folder called `{{ py_root }}tests` becomes `backend/tests` when `py_root` is `backend/`, and plain `tests` when it is empty.

### One template, three kinds of project

The template answers two questions (`project_layout` and `use_ml`) and covers three kinds of project:

| Kind | Answers | Shape |
|---|---|---|
| Simple Python project | `simple`, `use_ml: no` | Package named after the project and a single `tests/` folder, both at the repo root. No frontend, no infra |
| ML / data project | `simple`, `use_ml: yes` | The simple shape plus `notebooks/`, `data/`, `runs/`, `results/`, `dvc.yaml` and a runnable placeholder pipeline |
| Product | `product` (+ `use_ml` if it has ML) | `backend/` (package `app`, own `pyproject.toml`, `uv.lock` and `tests/`), `frontend/` (empty: a guide helps you choose the stack later) and `infra/` (with `tests/`) |

The three shapes share about 80% of their files — the whole `.claude/` folder, the GitHub templates, `AGENTS.md`, pre-commit, the workflows — so they are one template with conditions, not three copies that would drift apart. Everything that is shared by every part of a project (`config/`, `logs/`, `docs/`, `scripts/`, and the ML folders when present) lives at the repo root in all layouts.

```text
simple                      simple + use_ml             product (+ use_ml adds the ML folders at the root)
├── demo_proj/              ├── demo_proj/              ├── backend/
│   └── utils/              │   ├── pipeline/           │   ├── app/
├── tests/                  │   └── utils/              │   │   └── utils/
├── config/                 ├── tests/                  │   ├── tests/
├── logs/                   ├── config/                 │   ├── pyproject.toml
├── docs/                   ├── notebooks/              │   └── uv.lock
├── scripts/                ├── data/raw/               ├── frontend/        (decide-frontend-style.md)
├── pyproject.toml          ├── runs/                   ├── infra/tests/
├── uv.lock                 ├── results/                ├── config/ logs/ docs/ scripts/
└── Makefile …              ├── dvc.yaml                └── Makefile …
                            └── logs/ docs/ scripts/ …
```

---

## `copier.yml`

The master config for the template itself. It is never copied into generated projects.

```yaml
project_name:
  type: str
  validator: ...              # lowercase letters, digits, underscores

description:        {type: str, default: ""}
python_version:     {type: str, default: "3.12"}
open_source_license: {choices: [MIT, Apache-2.0, GPL-3.0, None], default: MIT}

project_layout:
  type: str
  default: simple
  choices:
    "Simple: package and tests at the repo root": simple
    "Product: backend/, frontend/ and infra/, each with its own tests": product

use_ml:
  type: bool
  default: false

# derived, never asked (`when: false`)
py_root:      "{{ 'backend/' if project_layout == 'product' else '' }}"
package_name: "{{ 'app' if project_layout == 'product' else project_name }}"

_subdirectory: template
_tasks:
  - command: bash scripts/resolve-latest.sh
```

Each top-level key becomes a variable available as `{{ variable_name }}` in every `.jinja` file and in file names. The `_subdirectory: template` line tells Copier that the actual files to copy live inside the `template/` folder, not at the root. The template's own `README.md`, guides and `copier.yml` sit outside `template/`, so they are never copied — no `_exclude` is needed (an earlier version excluded `README.md`, which accidentally dropped the *generated* project's README too).

**The questions.**

- `project_name` is validated (lowercase letters, digits and underscores, starting with a letter) because in `simple` projects it is also the importable package name.
- `project_layout` and `use_ml` decide the shape as described above.
- There is deliberately **no frontend question**. Picking a framework needs knowledge of the product, which you won't have when the repo is created, so `product` projects get `frontend/decide-frontend-style.md` instead (see [`frontend/`](#frontend-product-only)).

**The derived variables.** `py_root` and `package_name` are computed from the answers, never asked (`when: false`). Putting the decision in one variable keeps every other file simple: `{{ py_root }}pyproject.toml.jinja` is the one file that lands at the root or in `backend/`.

**The task.** After copying, Copier runs `scripts/resolve-latest.sh` (see [`scripts/`](#scripts)). That is why generation needs network access and `copier copy --trust`. The script skips itself once `uv.lock` exists, so `copier update` doesn't redo it, and with a warning if `uv` is missing.

**The message.** `_message_after_copy` is printed when generation finishes: where the project is, the next steps for the layout chosen (`bash scripts/setup.sh`, filling in `AGENTS.md`, and for `product` deciding the frontend and filling in `scripts/dev.sh`), how to turn Dependabot on, and how to pull later template changes.

**Updating.** When you improve the template and push changes, anyone who generated a project from it can run `copier update` in their project directory to pull in the changes. Copier diffs the old and new template versions and merges the changes, similar to a Git rebase. This depends on `.copier-answers.yml` (see below), which records the answers and the template version a project was generated from, and on a clean git tree. The `resolve-latest.sh` task runs only on the first `copy` (`when: "{{ _copier_operation == 'copy' }}"`): during an update Copier regenerates the project in temporary folders to compute a diff, and running the task there produced different dependency pins, which the merge then used to remove the project's own. Tag the template repo when you release a set of changes (`git tag v0.2.0`): Copier updates to the latest tag and a project can be pinned to a specific one; without tags it follows the latest commit.

---

## Testing the template

A template is easy to break in ways only a generated project reveals: a file that renders in one layout and fails in another, a hook that rewrites generated files on the first commit. `check-template.sh`, at the root of the template repo (outside `template/`, so never copied), renders all four combinations — `simple` and `product`, each with and without `use_ml` — into temporary folders and checks them in parallel:

```bash
bash check-template.sh                 # all four
bash check-template.sh product:true    # one combination (<layout>:<use_ml>)
```

Per generated project it checks that:

- the expected files exist (`AGENTS.md`, `CLAUDE.md`, `.copier-answers.yml`, `.gitattributes`, the lockfile and `.python-version`) and the git branch is `main`;
- Dependabot's config is gitignored;
- lint, format check, type check and tests pass, and the frontend targets skip cleanly when there is no frontend;
- a **fresh checkout** — what CI sees, without `.venv` or caches — passes markdownlint and the relative-link check;
- `pre-commit run --all-files` passes and leaves the working tree clean, so the first commit in a new project doesn't rewrite anything;
- `copier update` works: the script renders from a committed, tagged copy of the template, adds a change to it, updates the generated project, and checks that the change merged while the pins, lockfile and hooks stayed untouched;
- `product`: `make dev` refuses to start while `scripts/dev.sh` is unconfigured, and `dev.sh` stops its servers on Ctrl+C;
- `use_ml`: `dvc repro` runs the placeholder pipeline.

It prints a per-project report and the log tail of anything that failed. `.github/workflows/test-template.yml` runs it on every push and pull request to the template repo; run it locally after any change under `template/` or to `copier.yml`. It was written after a manual render-and-check routine kept catching real bugs, and its first run caught an invalid `copier.yml`.

---

---

## Root files

### `pyproject.toml`

The single most important file in a modern Python project. It is the standardised replacement for the old `setup.py`, `setup.cfg`, `requirements.txt`, and scattered tool config files — everything lives here now. It lives in the repo root for `simple` projects and in `backend/` for `product` projects.

```toml
[project]
name = "my_project"
version = "0.1.0"
description = "..."
requires-python = ">=3.12"
dependencies = []          # runtime dependencies: add with `uv add`

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.uv]
add-bounds = "exact"

[tool.hatch.build.targets.wheel]
packages = ["my_project"]  # "app" in product projects

[tool.ty.src]
include = ["my_project", "tests"]

[tool.ruff]
line-length = 100
target-version = "py312"

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "--cov=my_project --cov-report=term-missing"
```

**No hand-written dependency list.** The template deliberately ships `dependencies = []`. When the project is generated, `scripts/resolve-latest.sh` runs `uv add --dev ruff ty pre-commit pytest pytest-cov` (plus `dvc` and `ipykernel` with `use_ml`), so the project starts on the latest versions of everything instead of whatever the template's author wrote down a year ago. uv records the tooling in `[dependency-groups] dev`, which a plain `uv sync` installs. The runtime list starts empty on purpose: add what the project needs with `uv add`.

**Exact pins.** `add-bounds = "exact"` makes uv write `ruff==0.17.0` instead of `ruff>=0.17.0`, for the generated set and for every later `uv add`. Together with the committed `uv.lock`, nothing changes under the code between machines or rebuilds, and updates happen as reviewed pull requests (see Dependabot below).

**Other details.**

- `hatchling` is the build backend; `packages` tells it which folder is the importable package.
- `[tool.ty.src] include` limits type checking to the package and its tests, so scripts and agent tooling under `.claude/` are not checked.
- In `simple` projects `.claude/` is excluded from Ruff for the same reason. `product` projects don't need it: Ruff runs from `backend/`.
- `product` projects omit `readme = "README.md"`, because the README sits one folder above `backend/` and hatchling can't package a file outside the project.
- The pytest coverage flag points at the package, relative to where pytest runs (the project folder, not the repo root).
- The license is written as an SPDX expression (`MIT`, `Apache-2.0`, `GPL-3.0-only`), not the older `{ text = ... }` table. The template does not generate a `LICENSE` file: the question only fills this field and the README, which suits personal projects.

### `uv.lock`

The exact resolved version of every dependency, including transitive ones. It is **committed**: for an application, a lockfile is what makes `uv sync` reproducible. (An earlier version of the template gitignored it, which also broke any `--frozen` install.) `product` projects have it in `backend/` next to `pyproject.toml`.

### `README.md`

The project's front page, shown on GitHub and in documentation. Already written as a template that adapts to the layout — it documents the requirements (including the optional `graphify` and `rtk` agent-support tools), the project structure for the chosen layout, all `make` commands in tables, configuration, logging, and CI. DVC sections and the frontend appear only when they apply.

It also has a **Docs** section that spells out the three kinds of documentation a generated project keeps, because the AI workflow writes to all of them and they're easy to confuse:

| Location | What it holds | Written by |
|---|---|---|
| `CONTEXT.md` | Project glossary — resolved terminology only | `domain-modeling` / `grill-with-docs` |
| `docs/adr/` | Architecture decision records — hard-to-reverse decisions with a real trade-off | `domain-modeling` |
| `docs/specs/<type>-<yyyy_mm>-<name>/` | One folder per piece of work: `SPEC.md`, `plan/PLAN.md`, `reports/` | `/spec`, `implement`, `debugger` |
| `docs/build/` | Generated API docs (gitignored) | `pdoc` via `make docs` |

Fill in the description and update it as the project grows — or let the `docs-updater` subagent do it as part of `/commit-push` (see [`.claude/`](#claude)).

### `CHANGELOG.md`

A history of what changed, in [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format. It ships with an empty `[Unreleased]` section and the standard subsections (Added, Changed, Deprecated, Removed, Fixed, Security). The `changelog-writer` subagent appends to it on every `/commit-push`. It passes markdownlint as shipped, and the markdown workflow keeps it that way.

### `AGENTS.md` and `CLAUDE.md`

`AGENTS.md` is the project brief for AI assistants, and the file to maintain. `AGENTS.md` is the convention most agent tools read, so the brief isn't tied to one of them. It is a template with sections to fill in and sections that are pre-filled:

```text
## Project overview          ← fill in
## Architecture              ← fill in
## Stack & tools             ← pre-filled for the chosen layout (DVC, frontend only when present)
## Project layout            ← pre-filled: where Python, the UI and the shared folders live
## Common commands           ← pre-filled: make install / test / lint / typecheck / format
## Development workflow      ← pre-filled: how the skills, subagents and hooks compose
## General guidelines        ← pre-filled: dev philosophy, tooling rules, constraints
## Behavioral guidelines     ← pre-filled: think before coding, simplicity, surgical changes, goal-driven
## Out of scope              ← fill in
```

The *Project layout* section matters in `product` projects: it tells the agent that Python lives in `backend/` and that tooling runs from there (or through `make`, which does it for you).

`CLAUDE.md` starts with `@AGENTS.md`, which imports the brief. Claude Code reads `CLAUDE.md` and not `AGENTS.md`, so without that line it would never see the brief. Below the import it has an empty **Claude Code specifics** section for instructions that only make sense for Claude Code (everything else belongs in `AGENTS.md`, so there is one place to keep the content). It is deliberately not a jinja template.

### `Makefile`

Short commands for everything you do repeatedly. `make help` lists all targets with descriptions (it parses the `## comment` after each target). The Makefile knows where Python lives through one variable, `PY_DIR` (`.` in simple projects, `backend` in product ones), and every Python recipe starts with `cd $(PY_DIR)`, so `make test` works from any folder in the repo.

| Target | What it does | Layout |
|---|---|---|
| `setup` | `scripts/setup.sh`: project bootstrap of a fresh clone | all |
| `dev` | Start the backend and frontend dev servers through `scripts/dev.sh` | product |
| `sync` / `install` | Install from the lockfile / that plus the pre-commit hook (and `npm install` in product, once a frontend exists) | all |
| `test` | All tests: Python, plus the frontend in product | all |
| `test-py`, `test-fast` | Python tests with coverage / without | all |
| `test-frontend` | The frontend's `npm run test`; prints a hint and skips until `frontend/package.json` exists | product |
| `lint` | Ruff, ty, and the frontend linter in product | all |
| `lint-py`, `typecheck`, `format`, `format-check`, `fix` | The individual checks. `format-check` changes nothing; CI uses it | all |
| `lint-frontend` | The frontend's `npm run lint`; skips the same way | product |
| `pre-commit` | Run all pre-commit hooks on every file | all |
| `docs`, `docs-serve` | API docs with pdoc into `docs/build/` | all |
| `dvc-pull`, `dvc-push`, `dvc-repro` | DVC, run through `uv run --project` | `use_ml` |
| `clean` | Remove caches and build artefacts, skipping `node_modules/` and `.venv/` | all |

CI calls these same targets (`lint-py`, `format-check`, `typecheck`, `test-py`), so the pipeline and your terminal can't drift apart. The tooling targets exist as separate names so CI can run them as separate steps and see which one failed.

### `.env.example`

A template for environment variables. Copy it to `.env` (the setup script does this for you) and fill in real values. `.env` is gitignored so secrets never reach the repo; `.env.example` is committed so teammates know which variables exist.

### `.gitignore`

Rendered from `.gitignore.jinja`, so ML and frontend entries appear only where they apply. The notable decisions:

- **`uv.lock` is not ignored** — lockfiles are committed.
- **`.github/dependabot.yaml` is ignored** (first lines). Dependabot is opt-in: delete that line to start committing it.
- **Data, logs, runs, results** keep their folder structure through `.gitkeep` files but ignore the contents. With `use_ml`, `data/raw/.gitkeep` is also kept, because the DVC pipeline's first stage depends on that folder existing.
- `node_modules/` is ignored anywhere in the tree, `frontend/dist/` and `frontend/.env.local` in product projects.
- `.env` and `.env.*` are ignored, except `.env.example`.
- `.DS_Store` and `Thumbs.db` are ignored.

### `.python-version`

The interpreter every machine and CI use, so the project doesn't run on 3.12 on one laptop and 3.14 on another. uv does **not** create it by itself: `uv add` and `uv sync` only read it, and it is written by `uv init` or `uv python pin`. So `resolve-latest.sh` runs `uv python pin <python_version>` at generation time. The `python_version` question is the *minimum* version; the pin starts at the same value, and raising it later (`uv python pin 3.14`) is a one-line change. It lives next to `pyproject.toml` (`backend/` in product projects), where uv and CI's `uv sync` look for it.

### `.gitattributes`

Keeps `*.sh` files and the `Makefile` on LF line endings. Without it, a Windows checkout can convert them to CRLF, and Bash then fails with `$'\r': command not found`.

### `.copier-answers.yml`

Generated from `{{ _copier_conf.answers_file }}.jinja` and committed with the project. It records every answer and the template version the project came from, and `copier update` can't work without it (Copier refuses with "cannot obtain old template references"). Don't edit it by hand.

### `.pre-commit-config.yaml`

Git hooks that run automatically on `git commit`. `pre-commit` itself is a dev dependency, installed by `make install`. They are **fast checks only**, so commits stay quick:

- **Ruff** (`ruff-check` with `--fix`, and `ruff-format`) — lint and format the changed files. Both exclude `.claude/`: it is agent tooling, and in `product` projects the Ruff config lives in `backend/`, so at the repo root Ruff would reformat those scripts (and the code blocks in the skills' Markdown) with its defaults on the first commit.
- **pre-commit-hooks** — trailing whitespace, end-of-file newline, YAML and TOML validity, merge-conflict markers, leftover `breakpoint()`/`pdb` calls, and `check-added-large-files` (1000 KB), which stops a dataset or model from being committed by accident.
- **detect-secrets** — scans the commit for secrets (API keys, tokens, private keys). `AGENTS.md` says never to commit secrets; this enforces it. A false positive can be allowed with a `# pragma: allowlist secret` comment on the line, and lockfiles are excluded because they are full of hashes. It is a pure-Python hook: `gitleaks` was tried first, but as a Go hook pre-commit has to download a Go toolchain, which failed on a machine whose Python had no certificate store.
- **nbstripout** (`use_ml` only) — strips outputs and execution counts from notebooks, which bloat diffs and can leak data.
- **`typecheck`** — runs `make typecheck`, but only when Python files changed (`^backend/` in product, the package and `tests/` in simple).
- **`frontend-lint`** (product only) — runs `make lint-frontend` when a commit touches `frontend/`.

**There is deliberately no test hook.** `make test` is for you to run when you want it, CI runs it on every push and pull request, and a full test run on every commit made commits slow. (The agent has its own guard, `test_gate.py`, which blocks its commits on a red suite; see [`.claude/hooks/`](#claudehooks).)

The hook revisions are bumped to the latest by `pre-commit autoupdate` during generation. They are not covered by Dependabot, so when Dependabot bumps `ruff` in `pyproject.toml`, bump the `ruff-pre-commit` revision to match by hand.

### `dvc.yaml` and `.dvcignore` *(use_ml only)*

[DVC](https://dvc.org/) versions data and ML pipelines the way Git versions code. `dvc.yaml` describes the pipeline as three stages, each with a command, the files it depends on and the files it produces:

```yaml
stages:
  prepare:
    cmd: uv run python -m my_project.pipeline.prepare     # uv run --project backend python -m app.pipeline.prepare
    deps: [data/raw, my_project/pipeline/prepare.py]
    outs: [data/processed]
  train:
    cmd: uv run python -m my_project.pipeline.train
    deps: [data/processed, my_project/pipeline/train.py, config/config.yaml]
    outs: [runs/artifacts/model]
    metrics: [runs/artifacts/metrics.json: {cache: false}]
  evaluate:
    cmd: uv run python -m my_project.pipeline.evaluate
    deps: [data/processed, runs/artifacts/model, my_project/pipeline/evaluate.py]
    metrics: [runs/artifacts/evaluation.json: {cache: false}]
    plots: [runs/artifacts/plots.csv: {cache: false}]
```

DVC re-runs only the stages whose dependencies changed, which is what `make dvc-repro` does. The `.dvc/` folder and `dvc.yaml` live at the repo root — DVC tracks `data/` and `runs/`, which are shared by the whole project — while the `dvc` program itself is a dev dependency of the Python project (so in `backend/` for product projects), which is why the commands run through `uv run --project`. The stage modules exist (see [the `pipeline/` package](#pipeline-use_ml-only)) as working placeholders, so `dvc init` followed by `make dvc-repro` runs green on a fresh project. In product projects `uv run --project backend` points uv at the backend environment while the command still runs from the repo root, where `data/` and `runs/` live.

`.dvcignore` is the DVC equivalent of `.gitignore`: files DVC should not track or hash (virtual environments, Python caches, `logs/`).

---

## `config/`

Project-wide configuration, at the repo root in every layout so the backend, the frontend and the pipeline can all read it.

### `config/config.yaml`

The main configuration file. Starts minimal — the app name and a debug flag — with a commented-out example of what goes in it (an MLflow block with `use_ml`). Use it as the base and override per environment with `config/config.local.yaml`, which is gitignored for local secrets and paths. Nothing in the template reads it yet; `dvc.yaml`'s `train` stage lists it as a dependency, so changing it re-runs training.

There is no logging config file here. Logging is Python-only, so it is configured in the Python code that uses it (see `utils/logger.py`) instead of a root-level YAML that the frontend would never read.

---

## The package — `<project_name>/` or `backend/app/`

The importable code. In `simple` projects the folder is named after the project; in `product` projects it is `backend/app/`. The name is `{{ package_name }}` everywhere in the template.

Why `app` inside `backend/` and not the project name: the project name is already the repo name and the `pyproject.toml` name, so repeating it as a folder adds nothing. A fixed name also means the Makefile, CI, scripts and skills never need to know it. (`src` is not an alternative: that is a *layout* convention, `src/<package>/`, not a package name.)

### `__init__.py`

Marks the folder as a package and holds `__version__`, which the sample test checks.

### `constants.py`

Constants shared across the code. It starts with the project's paths, all derived from one anchor:

```python
ROOT = Path(__file__).resolve().parents[1]      # parents[2] in product projects
CONFIG_DIR = ROOT / "config"
LOG_DIR = ROOT / "logs"
# with use_ml: DATA_DIR, RAW_DIR, PROCESSED_DIR, ARTIFACTS_DIR
```

`ROOT` is the repo root, worked out from the file's own location rather than the current directory, so code behaves the same whether you run it from the repo root, from `backend/`, or from a test. `parents[1]` becomes `parents[2]` in product projects because the package sits one folder deeper. A sample test asserts that `ROOT` really is the repo root (it contains the `Makefile`), so a wrong depth is caught immediately.

### `utils/logger.py`

The shared logging utility, configured in code:

```python
def _configure() -> None:
    # console handler + RotatingFileHandler(logs/<project>.log, 10 MB, 5 backups)
    # root level from the LOG_LEVEL environment variable (default INFO)
    # httpx and httpcore turned down to WARNING

def get_logger(name: str) -> logging.Logger:
    global _configured
    if not _configured:
        _configure()
        _configured = True
    return logging.getLogger(name)
```

The module-level `_configured` flag makes the setup run exactly once, on the first call to `get_logger`, however many modules call it. All loggers propagate to the root logger, so one pair of handlers serves the whole process and nothing is printed twice.

Why code and not a YAML file: a `dictConfig` file is worth it when someone has to change handlers or per-module levels without touching code, which is rare for these projects. Meanwhile it is a second source of truth next to a code fallback, a file that needs its relative paths fixed up, and a runtime dependency (`pyyaml`) that nothing else needs. Setting the level from the environment covers the one change people actually make. If a project outgrows it, replace `_configure` with a `dictConfig` call and a file next to the code.

The log folder comes from `constants.py`, so logs always land in the root `logs/` — even for `product` projects whose code runs from `backend/`.

Usage in any module:

```python
from my_project.utils.logger import get_logger      # from app.utils.logger in product projects
logger = get_logger(__name__)
```

### `pipeline/` *(use_ml only)*

The three DVC stages as modules — `prepare.py`, `train.py` and `evaluate.py` — each with a `main()` and an `if __name__ == "__main__"` entry point, which is what `dvc.yaml` invokes with `python -m`. They are **placeholders that run**: `prepare` lists `data/raw` and writes an empty `data/processed/dataset.csv`, `train` writes a tiny `model.json` and `metrics.json`, `evaluate` writes `evaluation.json` and `plots.csv`. Each docstring states which inputs it reads and which outputs `dvc.yaml` expects, so replacing the body of `main` with real work keeps the pipeline wired. All paths come from `constants.py`.

---

## Tests

### `tests/` (simple) and `backend/tests/` (product)

`__init__.py` makes the folder a package; `test_sample.py` checks `__version__` and that `ROOT` is the repo root, and `test_logger.py` that `get_logger` returns a named logger. With `use_ml`, `test_pipeline.py` checks that each stage module imports and exposes `main()` — the contract `dvc.yaml` depends on. Pytest runs with coverage by default, configured in `pyproject.toml`.

In `product` projects each part of the system owns its tests instead of one root folder: Python tests in `backend/tests/`, frontend tests next to the frontend code (whatever runner the chosen stack uses, run by `npm run test`), and `infra/tests/` for infrastructure checks. `make test` runs all of them.

## `frontend/` *(product only)*

Holds a single file, `decide-frontend-style.md`, and nothing else on purpose. Choosing a frontend (a single-page app, a server-rendered site, a Python UI such as Streamlit?) and a framework depends on the product, so the template doesn't pre-pin tools you may never use.

The guide is written for a person who isn't a frontend specialist, and for an agent helping them. It walks through:

1. **What kind of interface it is** — a table mapping the situation (an app behind a login, a public site that needs search ranking, a content site, a data/ML demo, one small page) to a recommended approach and why.
2. **Which framework**, with React as the default and the reasons to pick Vue or Svelte instead. TypeScript always.
3. **Defaults for everything else** — package manager, styling, components, API access, generated API types, tests, linting, dev proxy.
4. **How to scaffold** — record the decision, delete the guide (scaffolders refuse a non-empty folder), run the framework's own scaffold command, add Vitest, pin exact versions (`.npmrc` with `save-exact=true`, and replacing the scaffold's `^` ranges), commit the lockfile.
5. **What the rest of the project expects** — the `lint`, `test`, `build` and `dev` npm scripts, uncommenting the npm block in Dependabot, updating `AGENTS.md`.

It ends with a *Decision* section to fill in, which can be copied into an ADR. Until `frontend/package.json` exists, the Makefile targets print a hint and skip, the CI frontend job passes without running anything, and the pre-commit hook does nothing.

## `infra/` *(product only)*

Infrastructure as code — Terraform, Pulumi, Kubernetes manifests and the like. It ships with only `infra/tests/.gitkeep`: the folder and its test location exist from day one, and the contents are yours.

---

## `scripts/`

### `scripts/setup.sh`

The project bootstrap for a fresh clone. It installs only what belongs to **this project** — dependencies, the git hook, `.env` — and never anything system-wide. Tools like `uv`, Node, `rtk` and `graphify` are machine-level: they serve every project, so they are installed once per machine (see [`bootstrap-machine.sh`](#bootstrap-machinesh-template-repo-only)), and a project script that installs them would copy that logic into every project, where it drifts and surprises people with side effects outside the repo.

```bash
set -euo pipefail
```

This line makes the script strict: `-e` exits immediately if any command fails, `-u` treats unset variables as errors, `-o pipefail` catches failures in piped commands. The script also changes into the repo root first, so it works from any directory.

The steps, in order:

1. **Check the required tools** — `git`, `make` and `uv` (and `npm` if `frontend/package.json` exists). A missing one stops the script with the install link, instead of installing it.
2. Run `resolve-latest.sh` (does nothing when `uv.lock` exists), then `uv sync` from the lockfile, and `npm ci` once a frontend exists.
3. Install the pre-commit hook.
4. With `use_ml`: `dvc init`, only if `.dvc/` doesn't exist yet (it creates `.dvc/` and edits `.gitignore`, and only needs to happen once).
5. Copy `.env.example` to `.env` if there is none.

It finishes by printing how to activate the environment (`backend/.venv` in product projects). The coloured output is purely cosmetic but makes the script easier to follow.

### `scripts/resolve-latest.sh`

The script Copier runs after copying. Its job is to make a new project start on **current, exactly pinned** dependencies without the template carrying a stale list:

1. Makes sure the folder is a git repository (`git init -b main` if needed) — `pre-commit autoupdate` and `pre-commit install` both need one, and CI watches `main`, which `git init` alone would not create on a machine without `init.defaultBranch`.
2. If there is no `uv.lock`: pins the Python version (`uv python pin`, see [`.python-version`](#python-version)), then `uv add --dev ruff ty pre-commit pytest pytest-cov` (plus `dvc ipykernel` with `use_ml`), run from the Python project folder. With `add-bounds = "exact"` in `pyproject.toml`, uv writes `==` pins, and it writes `uv.lock`.
3. Runs `pre-commit autoupdate` to bring the hook revisions in `.pre-commit-config.yaml` to the latest.

It skips itself once `uv.lock` exists, so it is safe to re-run and `copier update` doesn't redo it. **It can be removed**: once `uv.lock` is committed the script does nothing, so delete it together with the `resolve-latest.sh` line in `setup.sh` whenever you like; the only thing lost is the fallback for a clone that somehow has no lockfile. If `uv` isn't installed it warns and skips, and `setup.sh` (which stops until `uv` exists) picks it up later. The script stays in the project because `setup.sh` calls it. The frontend is not part of it: see [`frontend/`](#frontend-product-only).

### `scripts/dev.sh` *(product only)*

What `make dev` runs: it starts the backend and the frontend dev servers together and stops both on Ctrl+C (each server runs in its own process group through job control, so stopping one also stops what it started, such as `npm` and the `node` process under it). It ships as a **skeleton**: the two commands, `BACKEND_CMD` (run from `backend/`) and `FRONTEND_CMD` (run from `frontend/`), are empty, with an example next to each (`uv run uvicorn app.main:app --reload`, `npm run dev`), because neither the backend entry point nor the frontend exists yet. An empty command is skipped, and with both empty the script exits with an explanation instead of starting nothing. Fill them in when the stack is chosen; `frontend/decide-frontend-style.md` reminds you.

### `bootstrap-machine.sh` *(template repo only)*

Lives at the root of the template repo, **outside `template/`**, so it is never copied into generated projects. You run it once per machine:

- **Required:** `uv` (installer script) and `copier` (`uv tool install copier`).
- **Optional, best-effort:** [**graphify**](https://github.com/Graphify-Labs/graphify) builds a knowledge graph of the codebase that assistants can query for structure instead of grepping, and [**rtk**](https://github.com/rtk-ai/rtk) filters and compresses command output before it reaches an agent's context window, so long `pytest` or `git log` output doesn't burn tokens. The `rtk` install path is OS-dependent: `brew` on macOS (falling back to the install script), the install script on Linux, `winget` on Windows (Git Bash / MSYS), and a skip-with-warning anywhere else. Each optional install is wrapped in `|| warn ...`, so a failure prints a warning and the script continues.
- **Checked, not installed:** `git`, `make` and Node.js. Those belong to your system's package manager.

It is idempotent: anything already installed is skipped. Neither graphify nor rtk is a dependency of any project — they are conveniences for the person (or agent) driving it.

---

## `.github/`

### `.github/workflows/ci.yml`

The Continuous Integration workflow. It runs on every push to `main`, every pull request targeting `main`, and on demand (`workflow_dispatch`). It is the same file in every layout.

```yaml
permissions:
  contents: read

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  backend:    # install uv (pinned), make sync, make lint-py, make format-check, make typecheck, make test-py
  frontend:   # detect frontend/package.json; then npm ci, lint, test, build (each step guarded)
```

- **Two jobs run in parallel**, so either can fail without hiding the other.
- **Steps call `make` targets** instead of repeating commands, so CI and local runs are the same thing. The Makefile knows where Python lives, which is why the Python job is identical for simple and product projects.
- **The frontend job guards its steps** on the presence of `frontend/package.json`. `hashFiles` isn't available in a job-level `if`, so a first step detects the file and the rest check its output. In a `simple` project every step is skipped and the job passes in seconds, so it is harmless there; a comment in the file says it can be removed from a project that will never have a frontend. in a `product` project it starts running lint, vitest and a production build (which catches type errors the linter doesn't) as soon as `frontend/package.json` exists.
- **`concurrency` cancels superseded runs** of the same branch or PR, **`permissions: contents: read`** gives the workflow the minimum it needs, and each job has a **`timeout-minutes`**.
- **Versions are pinned exactly** (actions, `uv`, Node). Dependabot proposes updates for the actions; the `uv` install URL carries a version and needs bumping by hand.

### `.github/workflows/markdown.yml` and `markdownlint-config.json`

Checks every Markdown file on pushes and PRs that touch one: **style** with markdownlint (rules in `markdownlint-config.json`) and **links** with `markdown-checker`, run through `uvx` with the version pinned (`uvx --from markdown-checker==1.2.2`; the template never uses `pip`) (relative links must point at files that exist; external links only produce a warning, never a failure, because a site being down for a minute shouldn't block a push). `data/`, `node_modules/` and `.claude/` are left out of the style check, and `.claude/` is left out of the link check too (the tracked Markdown files are passed to the checker explicitly, minus `.claude/`): it holds agent prompts, which are written for a model, not styled for markdownlint, and whose internal links are not part of the project's documentation.

The shipped documents (README, CHANGELOG, AGENTS.md, CLAUDE.md, the issue and PR templates, the frontend guide) already pass the rules in every layout, so a fresh project starts green. The config disables line-length and the first-line-heading rule (issue templates start at `##` by design).

### `.github/dependabot.yaml`

Monthly dependency-update pull requests. **It is gitignored by default** (the first lines of `.gitignore`): delete that line to start committing it, which turns Dependabot on. Because versions are pinned exactly, every update is one reviewed bump.

It has one entry per ecosystem, and dependencies are grouped so a month's updates don't arrive as dozens of PRs:

| Ecosystem | Groups | Layout |
|---|---|---|
| `github-actions` | one group with everything | all |
| `uv` (`/` or `/backend`) | `python-dev-tools` (ruff, ty, pre-commit, pytest, pytest-cov, and dvc, ipykernel with `use_ml`), then `python-runtime` (everything else) | all |
| `npm` (`/frontend`) | `npm-dev-tools` (devDependencies) and `npm-runtime` (dependencies). Present but **commented out** until `frontend/package.json` exists, because Dependabot errors on a missing manifest | product |

Two rules make this work. A dependency belongs to the **first group it matches**, so the named tooling group comes before the catch-all runtime group — the packages `resolve-latest.sh` generates land in `python-dev-tools`, and anything you `uv add` later lands in `python-runtime` (the template starts with no runtime dependencies). And each group only batches **minor and patch** updates; a major update opens its own PR, because it needs a look. For npm the split uses `dependency-type`, so it follows `package.json` without listing names.

### `.github/PULL_REQUEST_TEMPLATE.md`

The pre-filled description for every PR, written to be useful to a human reviewer and to an agent alike. It opens with an instruction comment — write for a reviewer who hasn't read the ticket, delete a section that doesn't apply instead of writing "N/A", keep the order, put a conventional commit in the title for a single change, and tick `[x]` only for what was actually run — followed by a `Ticket:` line (and a note for stacked PRs) and the sections:

| Section | What goes in it |
|---|---|
| *Why* | The problem as a user or operator saw it, what it cost, and for a bug the cause with the file or commit that introduced it |
| *What changes* | One bullet per behaviour, led by the area (**Backend:**, **UI:**, **Infra:**, **CI:**), naming endpoints, statuses, config keys and migrations exactly; ends with **Not touched:** |
| *For review* | Decisions to agree with or challenge: trade-offs, deviations from the ticket, deliberately removed behaviour |
| *Deploy impact* | Only the lines that apply: what deploys on merge, migrations, the expected infrastructure diff, config or secrets, anything applied by hand, what breaks, cost or performance |
| *Verification* | Checkboxes: `[x]` what ran and what it showed, `[ ]` what still has to be checked and how, with exact commands when reproducing takes more than a sentence |
| *Known gaps* | What this deliberately leaves unfixed, and what fixing it would take |
| *After merging* | Checks after deploy, data to clean up, follow-up tickets |

### `.github/ISSUE_TEMPLATE/`

Three templates for the "New issue" menu, in the **same style as the PR template** so an issue and the PR that closes it read the same way: an instruction comment at the top (plain words for someone who hasn't seen the conversation, delete what doesn't apply, `[x]` only for what actually happened), a `Related:` line, the PR's section vocabulary, and a *Done when* checklist that becomes the PR's *Verification*.

| Template | Sections | Notes |
|---|---|---|
| `bug_report.md` | *What happens*, *Expected*, *How to reproduce*, *Where*, *Impact*, *Suspected cause*, *Done when* | Facts first (the exact error, commands to reproduce); a guessed cause goes in its own optional section, labelled as a guess, so it doesn't steer the fix |
| `feature_request.md` | *Why*, *What changes*, *For discussion*, *Deploy impact*, *Done when*, *Out of scope* | Describes the problem and the behaviour wanted, not the code; options and trade-offs go in *For discussion* |
| `task.md` | *Why*, *What to do*, *Where to look*, *For discussion*, *Deploy impact*, *Done when*, *Out of scope* | A unit of work someone can start without asking. *Where to look* (entry points, similar code, constraints) is what lets an agent begin without exploring the whole repo |

### What is deliberately not included

There is **no CD workflow** and no Dockerfile: container images and deployment are specific to each project, so a generic one would be wrong more often than useful. Add them when a project needs them.

---

## `.claude/`

Everything under `.claude/` is what makes a generated project *AI-native* rather than merely AI-friendly. `AGENTS.md` tells the agent what the project is; this folder gives it a process to follow, specialists to delegate to, and guardrails it can't switch off.

```
.claude/
├── settings.json        ← registers the hooks
├── hooks/               ← three Python scripts: two run before every Bash call, one after every Write/Edit
├── agents/              ← 7 subagent definitions (+ README roster)
└── skills/              ← 13 engineering skills + 9 productivity skills (+ README rosters)
```

The pieces compose as described in `AGENTS.md`'s **Development workflow** section. In one line: `/grill-with-docs` → `/spec` → `implement` (`tdd` + `logic-checker` + `code-reviewer`) → `/commit-push` (`changelog-writer` + `docs-updater` + `commit-push`) → PR by hand, with `diagnosing-bugs` → `debugger` as the separate track for things that are already broken, and the two hooks underneath all of it.

### `.claude/settings.json`

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "python3 $CLAUDE_PROJECT_DIR/.claude/hooks/destructive_guard.py" },
          { "type": "command", "command": "python3 $CLAUDE_PROJECT_DIR/.claude/hooks/test_gate.py" }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          { "type": "command", "command": "python3 $CLAUDE_PROJECT_DIR/.claude/hooks/format_python.py" }
        ]
      }
    ]
  }
}
```

The `hooks` block registers three hooks. Claude Code pipes a JSON description of the tool call to each script's stdin. The two `PreToolUse` hooks fire before every `Bash` call, and a script that exits with code 2 blocks the call (its stderr is shown to the agent as the reason). The `PostToolUse` hook fires after every `Write` or `Edit`, when the file is already written; there, exit code 2 can't undo anything, so its stderr is fed back to the agent as feedback on what it just did. All three are invoked with `python3`, so it needs to be on the PATH of the shell Claude Code runs in. There is no `jq` or other tool to install: the hooks read the JSON themselves.

There is no `context` block: Claude Code loads `CLAUDE.md` on its own, and that file imports `AGENTS.md`.

### `.claude/hooks/`

The first two hooks share a philosophy: **they guard the agent, not you**, so neither has an override. If you need to do one of these things yourself, do it outside Claude Code. The third, `format_python.py`, is not a guard: it never blocks anything.

**`test_gate.py`** — blocks any Bash call containing `git commit` unless `make test` passes first. It matches the command string with a regex (`git ... commit`, including `git -C path commit` and chained `&& git commit`) and deliberately ignores whatever flags follow, so `--no-verify` doesn't help — the hook runs before Bash ever sees the command. Tests run with a 10-minute timeout. Infrastructure problems (no `Makefile`, no `make` or `uv` on PATH, malformed hook input) **fail open** with a warning rather than blocking on something the agent can't fix by writing code.

**`destructive_guard.py`** — blocks a short list of obviously destructive commands:

- `rm -rf` (any equivalent flag combination) targeting `/`, `~`, `.`, `..`, `*`, `$HOME`, `.git`, the project root, or an ancestor of it
- `git reset --hard`
- `git clean` with a force flag
- `git checkout .` / `git restore .` (discards every uncommitted change)
- `git branch -D main|master`
- `git push --force` / `-f` to `main` or `master` (branch resolved from the explicit refspec, else the current branch)

It splits on `&&`, `||`, `;`, `|` to inspect each command in a chain and tokenizes with `shlex`. It's a heuristic safety net for the common careless case, not a shell parser — unusual quoting can slip past it.

**`format_python.py`** — a `PostToolUse` hook that runs `ruff format` on every `.py` file the agent just wrote or edited, so its code arrives formatted without waiting for pre-commit or `make fix`.

- It reads the file path from the hook's JSON with Python, so it needs no `jq`. (An earlier version was a shell one-liner that piped the JSON through `jq` and called `ruff` directly. That needed `jq` installed and Ruff on the global PATH, and `2>/dev/null || true` hid the failure when either was missing, so in a fresh project it quietly did nothing.)
- It finds the Python project by walking up from the file to the nearest `pyproject.toml` — the repo root in simple projects, `backend/` in product projects — and runs `uv run --project <that folder> ruff format --force-exclude <file>`. So it uses the project's own pinned Ruff and its own config, exactly like `make format`.
- `--force-exclude` makes it honour the project's Ruff excludes (simple projects exclude `.claude/`). Files outside the project folder, and files with no `pyproject.toml` above them (for example Python scripts under `.claude/` in a product project), are skipped silently.
- It never blocks. Exit code 2 means Ruff rejected the file, usually a syntax error: Ruff's message goes to the agent so it can fix its edit. Exit code 1 means the hook couldn't run (`uv` missing, a 60-second timeout) and the reason is shown to you, instead of being swallowed.

### `.claude/agents/`

Subagents are independent Claude contexts the main agent dispatches for a specific job. Each is a Markdown file whose frontmatter sets the model, reasoning effort, and allowed tools; the body is the brief. Using a separate context keeps the main conversation lean and — for the read-only ones — makes them safe to run without touching the working tree. `agents/README.md` is the roster; the summary:

| Agent | Model / effort | Tools | Job |
|---|---|---|---|
| `context-scout` | haiku / medium | read-only | Fact-finding in the repo (code, docs, ADRs, git history). Dispatched by `grilling` and anything that delegates to it whenever a question needs a fact instead of a decision. |
| `code-reviewer` | sonnet / high | read-only | Fresh-eyes review of a diff for correctness, security, seam discipline, and fit with `AGENTS.md`/`CONTEXT.md`/ADRs. Reports, doesn't fix. Runs at the end of `implement` and `debugger`. |
| `logic-checker` | sonnet / high | read-only | Per-seam check that the implementation matches the spec's *Implementation Decisions* and nothing is missing that the seam's own test wouldn't catch. Runs before that seam's test confirms green. Narrower and earlier than `code-reviewer`. |
| `changelog-writer` | sonnet / low | edit | Updates `CHANGELOG.md`'s `[Unreleased]` from recent commits; cuts a release section when asked. History only. |
| `docs-updater` | sonnet / low | edit | Keeps `README.md` and other top-level docs (skills READMEs, etc.) accurate and lean — deletes stale content as readily as it adds. Current-state only. |
| `commit-push` | haiku / low | Bash | Stages, drafts commit message(s) from the diff, commits (split into logical commits when large), pushes once. Only ever triggered by the `/commit-push` skill. Never opens a PR. |
| `debugger` | opus / high | edit + run | Structured diagnosis loop — repro, minimise, rank hypotheses, instrument, fix with a regression test — up to two rounds before writing up what was tried. Dispatched by `diagnosing-bugs`, one confirmed symptom at a time. Stops short of committing. |

The model-tier choices are deliberate: cheap models for mechanical work (`context-scout`, `commit-push`), stronger ones with high effort for judgement (`code-reviewer`, `logic-checker`), and the strongest with a skeptical brief for debugging, where anchoring on the first plausible cause is the failure mode.

The hooks apply to subagents exactly as they apply to the main agent — `commit-push` can't commit past a red test suite either.

### `.claude/skills/`

A skill is a folder with a `SKILL.md` (frontmatter + instructions) and optional `references/` or `scripts/`. Skills come in two flavours, decided by `disable-model-invocation` in the frontmatter:

- **User-invoked** (`disable-model-invocation: true`) — only run when you type `/<name>`. These are the deliberate, side-effectful steps.
- **Model-invoked** — the agent reaches for them itself when the situation matches their description. These are techniques and reference material.

`skills/README.md` is the roster. The engineering skills:

| Skill | Invoked by | What it does |
|---|---|---|
| `spec` | you (`/spec`) | Turns a feature request into `docs/specs/<type>-<yyyy_mm>-<name>/SPEC.md` plus a seam-organized `plan/PLAN.md`, after a bounded round of clarifying questions and a seam check. Creates the matching `feat/`, `fix/`, or `refactor/` branch. Continues straight into `implement` by default. |
| `implement` | you (`/implement`, or via `/spec`) | Works through the plan seam by seam: `tdd` at each seam, `logic-checker` before each seam's test confirms green, `make test`/`lint`/`typecheck` throughout, `plan/PLAN.md` checked off, a report per seam into the spec's `reports/`. Ends with an optional refactor pass and an independent `code-reviewer` pass. Never pauses for confirmation; never commits. |
| `tdd` | model | Red-green test-driven development, one seam at a time — what a good test looks like, mocking at boundaries only, plus ML-specific rules (tolerance-based float assertions, checked-in fixtures, seeding, flaky-test handling). |
| `diagnosing-bugs` | model | Triages a bug report or a half-built feature into confirmed bugs (→ `debugger`, one at a time) vs. pieces that were never built (→ `/spec` + `implement`), then dispatches. Includes a `scripts/hitl-loop.template.sh` for human-in-the-loop repro loops. |
| `grilling` | model | The interview engine: questions the user relentlessly about a plan until nothing is silently assumed. Backs `grill-me` and `grill-with-docs`; dispatches `context-scout` when a question needs a fact. |
| `grill-with-docs` | you (`/grill-with-docs`) | `grilling`, grounded in this repo — writes resolved vocabulary to `CONTEXT.md` and hard decisions to `docs/adr/` as it goes (via `domain-modeling`). |
| `domain-modeling` | model | Builds and sharpens the project glossary (`CONTEXT.md`, or one per bounded context with a `CONTEXT-MAP.md`) and records ADRs. Ships `references/CONTEXT-FORMAT.md` and `references/ADR-FORMAT.md` as the canonical formats. Also fires on its own when terminology gets sloppy. |
| `commit-push` | you (`/commit-push`) | Dispatches `changelog-writer` and `docs-updater`, then the `commit-push` subagent. The only way a commit happens in the workflow. |
| `claude-handoff` | you (`/claude-handoff`) | Hands the conversation to a detached background Claude Code agent that keeps working unattended — use instead of same-session `implement` when you want to walk away. Hooks still apply. |
| `walkthrough` | you (`/walkthrough`) | Debugger-style tour of one concrete code path — a screen per step, one real value carried forward as it transforms. For understanding existing code. `references/example.md` shows the format. |
| `doubt` | you (`/doubt`, `/x`) | Re-examines something the agent just did or claimed with structured skepticism. Ends in one of three verdicts — wrong, right, or genuine tradeoffs — never "it depends". |
| `handcraft` | you (`/handcraft`) | Builds a feature one function at a time with you approving each step — the opposite end of the spectrum from `implement`. `scripts/executable_preflight.py` checks a target is runnable before starting. |
| `frontend-design` | model | Aesthetic and UX guidance for the occasional UI work in `frontend/` — deliberate choices on palette, typography, layout. Self-contained: dispatches its own `code-reviewer` (and `logic-checker` if implementing a spec'd seam). |

### `.claude/skills/productivity_skills/`

General workflow tools that aren't code-specific, with their own `README.md` roster. All are user-invoked except `writing-for-agents`.

| Skill | What it does |
|---|---|
| `grill-me` | `grilling` with no repo and nothing written to disk — pure interview to sharpen a loose idea. |
| `handoff` | Compacts the current conversation into a handoff document another agent can pick up (a document, unlike `claude-handoff`, which spawns a process). |
| `teach` | Multi-session teaching of a skill or concept, using the current directory as a stateful workspace. `references/` define the mission, learning-record, glossary, and resources formats. |
| `lbt` | Learning-by-teaching loop — you explain something, get told what's correct/wrong/conflated/missing, and explain again. |
| `mvk` | Minimal Viable Knowledge — researches any field to "level-1 enthusiast lurker" depth and delivers an interactive HTML mini-site. |
| `rp` | Roleplay QA — a context-free subagent plays a blind end user against the real product (UI/CLI/API only, no source) to find where users get stuck. `references/actor-brief.md` is the brief it's given. |
| `to-questionnaire` | Turns a decision you can't answer alone into a Markdown questionnaire for the one person who can. |
| `wait-what` | Fire when a message doesn't land — the agent re-pitches it in plain English using your `CONTEXT.md` vocabulary. |
| `writing-for-agents` | (model-invoked) How to write documents for agents: skills, `AGENTS.md`/`CLAUDE.md`, and anything an agent reaches by a pointer. `references/SKILL-MECHANICS.md` covers how skills load and trigger. Use it when adding your own skills to the project. |

### Where the workflow writes

The skills produce durable artefacts outside `.claude/`, all committed:

- `CONTEXT.md` (project root) — the glossary. Resolved terminology only, no implementation details.
- `docs/adr/` — one file per architecture decision record.
- `docs/specs/<type>-<yyyy_mm>-<name>/` — `SPEC.md`, `plan/PLAN.md`, and `reports/NNNN-<implement|debugger>.md`, one folder per piece of work.
- `CHANGELOG.md` and `README.md` — kept current by `changelog-writer` and `docs-updater` on every `/commit-push`.

None of these exist in a fresh project; `docs/` ships as an empty `.gitkeep` folder and the skills create the subfolders on first use.

---


---

## Folder-only entries (`.gitkeep` files)

These folders contain only a `.gitkeep` file — an empty placeholder that allows Git to track the folder without any real content. Git doesn't track empty directories, so `.gitkeep` is the convention for "this folder should exist in the repo but its contents are gitignored (or created later)."

| Folder | Layout | Purpose |
|---|---|---|
| `config/` | all | Configuration files (not `.gitkeep`; it holds `config.yaml`) |
| `docs/` | all | Written record of the project. `specs/` and `adr/` are created by the AI workflow and committed; `build/` is generated by `make docs` and gitignored |
| `logs/` | all | Runtime log files written by the logger. Rotated automatically |
| `data/raw/` | `use_ml` | Immutable source data. Contents gitignored and DVC-tracked; the `.gitkeep` makes sure the `prepare` stage's dependency exists |
| `notebooks/` | `use_ml` | Jupyter notebooks for exploration and analysis. Not used in the pipeline |
| `runs/mlruns/` | `use_ml` | MLflow experiment tracking data — metrics, parameters, run metadata |
| `runs/artifacts/` | `use_ml` | Trained model files, checkpoints, outputs produced by pipeline stages |
| `results/` | `use_ml` | Final evaluation outputs, plots, tables — things you'd share or reference in a report |
| `infra/tests/` | product | Where infrastructure checks go; the rest of `infra/` is yours |
| `frontend/` | product | Not a `.gitkeep`: holds `decide-frontend-style.md` until you scaffold a frontend |

`data/processed/` is not in this table because the `prepare` stage creates it.

---

## Summary: which files you'll touch regularly

| File | How often | When |
|---|---|---|
| `AGENTS.md` | Frequently | Every time the project architecture or conventions change — keep it current so the agent stays effective |
| `CONTEXT.md` | Frequently, via the skills | Whenever terminology gets settled (`/grill-with-docs`, `domain-modeling`) |
| `docs/specs/` | Per feature / fix | Created by `/spec`, updated by `implement` and `debugger` — you read the reports, you rarely edit them |
| `docs/adr/` | Per hard decision | Written by `domain-modeling` when a non-obvious, hard-to-reverse choice is made |
| `CHANGELOG.md` | Per commit, via `changelog-writer` | Whenever something user-facing changes — automated through `/commit-push` |
| `README.md` | Per commit, via `docs-updater` | Whenever the change makes something in it stale — automated through `/commit-push` |
| `config/config.yaml` | Per project | When adding new configuration |
| `pipeline/*.py`, `dvc.yaml` | Per pipeline change | Replace the placeholder stage bodies first; edit `dvc.yaml` when adding or renaming stages (`use_ml`) |
| `pyproject.toml` | Occasionally | When adding dependencies (through `uv add`, which pins exactly; never by hand) |
| `frontend/decide-frontend-style.md` | Once | When you start the frontend — decide, scaffold, then delete it |
| `frontend/package.json` | Occasionally | When adding frontend dependencies (through `npm install`, which pins exactly once `.npmrc` is set) |
| `.claude/skills/` | Occasionally | When you add a project-specific skill — `writing-for-agents` is the guide |
| `.claude/agents/` | Rarely | When you need a new specialist or want to change a model tier |
| `scripts/dev.sh` | Once | When the stack is chosen: fill in `BACKEND_CMD` and `FRONTEND_CMD` (product) |
| `Makefile` | Rarely | When adding new workflow shortcuts |
| `.github/workflows/` | Rarely | When changing CI behaviour |
| `.github/dependabot.yaml` | Once | To turn Dependabot on (remove its line from `.gitignore`), then rarely |
| `.pre-commit-config.yaml` | Rarely | When adding hooks, or bumping the Ruff revision to match `pyproject.toml` |
| `.python-version` | Rarely | When you raise the Python version the project runs on (`uv python pin`) |
| `.claude/hooks/`, `.claude/settings.json` | Almost never | Only if you want to extend the guardrails or the formatter — they're meant to stay fixed |
