# Python Project Template — Complete File Reference

This document explains every file in the template: what it is, what it does, what the code inside means, and when it becomes relevant in a real project.

---

## How the template works

Before diving into individual files, it helps to understand Copier's mechanics.

The repo has two levels:

```
python-template/
├── copier.yml          ← Copier's control file (questions, settings)
└── template/           ← everything here gets copied into your new project
```

When you run `copier copy gh:you/python-template ./my-project`, Copier reads `copier.yml`, asks you the questions defined there, and then copies everything inside `template/` into `my-project/`, substituting `{{ variable }}` placeholders along the way.

Files ending in `.jinja` are treated as Jinja2 templates — the `.jinja` extension is stripped after rendering, so `pyproject.toml.jinja` becomes `pyproject.toml` in your project. Files without `.jinja` are copied verbatim.

---

## `copier.yml`

The master config for the template itself. It is never copied into generated projects.

```yaml
project_name:
  type: str
  help: Project name (used for the package folder and pyproject.toml)

description:
  type: str
  help: Short description of the project
  default: ""

python_version:
  type: str
  help: Minimum Python version
  default: "3.12"

open_source_license:
  type: str
  help: License
  default: MIT
  choices: [MIT, Apache-2.0, GPL-3.0, None]

_subdirectory: template
_exclude:
  - copier.yml
  - README.md
```

Each top-level key becomes a variable available as `{{ variable_name }}` in every `.jinja` file. The `_subdirectory: template` line tells Copier that the actual files to copy live inside the `template/` folder, not at the root. `_exclude` lists files that exist in the repo but should never be copied to generated projects — in this case, the template's own `README.md` and `copier.yml` itself.

When you improve the template and push changes, anyone who generated a project from it can run `copier update` in their project directory to pull in the changes. Copier diffs the old and new template versions and merges the changes, similar to a Git rebase.

---

## Root files

### `pyproject.toml`

The single most important file in a modern Python project. It is the standardised replacement for the old `setup.py`, `setup.cfg`, `requirements.txt`, and scattered tool config files — everything lives here now.

```toml
[project]
name = "my_project"
version = "0.1.0"
description = "..."
# authors = [{ name = "Your Name", email = "you@example.com" }]
requires-python = ">=3.12"
readme = "README.md"
license = { text = "MIT" }
dependencies = [
  "pyyaml",        # used by the logger to load configs/logging.yaml
]

[project.optional-dependencies]
dev = [
  "ruff",          # linting and formatting
  "ty",            # type checking (Astral's fast type checker)
  "pre-commit",    # git hook runner
  "pytest",        # test framework
  "pytest-cov",    # coverage reporting for pytest
  "dvc",           # data version control
]
```

The `[project.optional-dependencies]` block defines a group called `dev`. When you run `uv sync --all-extras`, uv installs both the main dependencies and everything in `dev`. In production (e.g. inside Docker), you run `uv sync --no-dev` to install only the main dependencies — leaner image.

```toml
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.hatch.build.targets.wheel]
packages = ["my_project"]
```

This tells Python's build tooling how to package your project if you ever want to publish it to PyPI or install it as a proper package. `hatchling` is a modern, fast build backend. The `packages` line tells it which folder is the actual package to include.

```toml
[tool.ruff]
line-length = 100
target-version = "py312"

[tool.ruff.lint]
select = [
  "E",   # pycodestyle errors
  "W",   # pycodestyle warnings
  "F",   # pyflakes (unused imports, undefined names, etc.)
  "I",   # isort (import ordering)
  "UP",  # pyupgrade (modernise Python syntax)
  "B",   # flake8-bugbear (common bugs and design issues)
]
ignore = []
```

Ruff's configuration. Rather than running separate tools (flake8, isort, black, pyupgrade), Ruff does all of it in one pass, much faster. The `select` list controls which rule categories are active. You can add more (e.g. `"N"` for naming conventions) or suppress specific rules by adding their code to `ignore`.

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "--cov=my_project --cov-report=term-missing"
```

Pytest configuration. `testpaths` tells pytest where to look for tests. `addopts` are flags automatically passed on every run — here, they enable coverage measurement for your package and print a terminal report showing which lines are not covered.

`ty` needs no configuration block — `uv run ty check .` (wrapped as `make typecheck`) picks up `requires-python` and the package layout from `[project]` directly.

---

### `README.md`

The project's front page, shown on GitHub and in documentation. Already written as a template — it documents the requirements (including the optional `graphify` and `rtk` agent-support tools), the project structure, all `make` commands in tables, configuration, logging, and CI/CD.

It also has a **Docs** section that spells out the three kinds of documentation a generated project keeps, because the AI workflow writes to all of them and they're easy to confuse:

| Location | What it holds | Written by |
|---|---|---|
| `CONTEXT.md` | Project glossary — resolved terminology only | `domain-modeling` / `grill-with-docs` |
| `docs/adr/` | Architecture decision records — hard-to-reverse decisions with a real trade-off | `domain-modeling` |
| `docs/specs/<type>-<yyyy_mm>-<name>/` | One folder per piece of work: `SPEC.md`, `plan/PLAN.md`, `reports/` | `/spec`, `implement`, `debugger` |
| `docs/build/` | Generated API docs (gitignored) | `pdoc` via `make docs` |

Fill in the description and update it as the project grows — or let the `readme-updater` subagent do it as part of `/commit-push` (see [`.claude/`](#claude)).

---

### `CHANGELOG.md`

A human-readable log of notable changes across versions. Follows the [Keep a Changelog](https://keepachangelog.com) format:

```markdown
## [Unreleased]
### Added
### Changed
### Fixed
```

The `[Unreleased]` section collects changes that haven't been released yet. When you cut a release, you rename it to `[1.0.0] - <date>` and open a new `[Unreleased]` section above it. In this template the `changelog-writer` subagent owns this file: `/commit-push` dispatches it before every commit so the entry lands in the same commit as the code it describes, and it can cut a release section when asked. It is append-only history — it never touches `README.md` (that's `readme-updater`'s job).

---

### `CLAUDE.md`

A file specifically for AI coding assistants. When Claude Code opens your project, it reads this file first to understand the context it's operating in. Think of it as a brief for a new team member who reads extremely fast.

```markdown
## Project overview          ← fill in
## Architecture              ← fill in
## Stack & tools             ← pre-filled: Python, uv, Ruff, ty, pytest, dvc, docker
## Common commands           ← pre-filled: make install / test / lint / typecheck / format
## Development workflow      ← pre-filled: how the skills, subagents and hooks compose
## General guidelines        ← pre-filled: dev philosophy, tooling rules, constraints
## Behavioral guidelines     ← pre-filled: think before coding, simplicity, surgical changes, goal-driven
## Out of scope              ← fill in
```

The first two and the last section are yours to fill in as the project evolves. The rest ships ready:

- **Development workflow** is the map of the whole AI-native process — clarify (`/grill-with-docs`) → spec (`/spec`) → implement (`implement`, `tdd`, `logic-checker`, `code-reviewer`) → docs + commit (`/commit-push`) → PR by hand — plus the separate debugging track (`diagnosing-bugs` → `debugger`) and the two hooks that run under everything. It is deliberately a map, not a recipe: each piece triggers on its own (user-invoked, model-invoked, or hook-enforced). Read it once and you know how everything under `.claude/` fits together.
- **General guidelines** encode the coding philosophy the agent should follow: small functions, flat over nested, explicit over implicit, no premature abstraction, comments only for non-obvious *why*, always use scaffolding/package-manager commands instead of hand-writing config, imports at the top, hard timeouts on external processes, never commit secrets, and "type checker and linter are gates, not suggestions".
- **Behavioral guidelines** are the four rules of engagement — *Think Before Coding* (surface assumptions, ask when unclear), *Simplicity First* (no speculative features or abstractions), *Surgical Changes* (touch only what the request needs), *Goal-Driven Execution* (turn tasks into verifiable criteria and loop until they pass) — with an anti-patterns table.

The more accurate the fill-in sections are, the better an agent performs — it won't suggest patterns that don't fit, won't touch things marked out of scope, and will use the right commands.

---

### `Makefile`

A task runner: a file of named shell command shortcuts. You run them with `make <target>`. The pattern `## comment` after each target is used by the `help` target to auto-generate a command list.

```makefile
PROJECT_NAME := my_project    # injected by Copier, used by make docs
```

Key targets:

- **`make setup`** — calls `scripts/setup.sh`. Use this on a fresh clone.
- **`make install`** — just `uv sync + pre-commit install`. Use this when uv is already set up and you just pulled changes.
- **`make fix`** — the most useful day-to-day command: runs `ruff check --fix` (auto-fixes lint issues) then `ruff format` (formats code). Run before committing.
- **`make test`** — runs pytest with coverage. This is also what the `test_gate.py` hook and the local pre-commit hook run before allowing a commit (see [`.pre-commit-config.yaml`](#pre-commit-configyaml) and [`.claude/hooks/`](#claudehooks)).
- **`make typecheck`** — runs `ty check .`. CI runs the same thing, and `CLAUDE.md` tells the agent to treat it as a gate, not a suggestion.
- **`make docs` / `make docs-serve`** — generates HTML documentation from your docstrings using `pdoc`. `uv run --with pdoc` fetches pdoc on-demand without adding it as a permanent dependency.
- **`make dvc-repro`** — re-runs any DVC pipeline stages whose dependencies have changed.
- **`make clean`** — deletes compiled Python files, test caches, build artifacts. Useful when things behave strangely.

---

### `Dockerfile`

Defines how to build a Docker image for your project.

```dockerfile
FROM python:3.12-slim
```

Starts from a minimal official Python image. The `-slim` variant excludes compilers and other tools not needed at runtime, making the image much smaller.

```dockerfile
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
```

Copies the `uv` binary directly from its official Docker image. This is a Docker multi-stage copy trick — you don't need to install uv via curl inside the image, you just grab the binary from the uv image.

```dockerfile
COPY pyproject.toml uv.lock* ./
RUN uv sync --no-dev --frozen
```

Copies dependency files first, then installs. This is a critical Docker pattern — because Docker caches each layer, if your code changes but `pyproject.toml` hasn't, Docker reuses the cached dependency install layer. `--frozen` means it must use the exact versions in `uv.lock`, refusing to resolve differently. `--no-dev` skips dev dependencies (ruff, pytest, etc.) — you don't need those in production.

```dockerfile
COPY my_project/ ./my_project/
ENV PATH="/app/.venv/bin:$PATH"
CMD ["python", "-m", "my_project"]
```

Copies your source code after dependencies (so code changes don't invalidate the dependency cache). Sets the PATH so the virtualenv's Python is used. `CMD` is the default command — running your package as a module. You'll likely change this to a specific entrypoint.

---

### `docker-compose.yml`

Defines and wires together one or more Docker services for local development and deployment.

```yaml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    image: my_project:latest
    env_file:
      - .env                # loads all variables from .env into the container
    volumes:
      - ./data:/app/data    # mounts your local data/ into the container
      - ./logs:/app/logs
      - ./runs:/app/runs
      - ./results:/app/results
      - ./configs:/app/configs
    restart: unless-stopped
```

The volume mounts are important: rather than baking data into the image (which would require a rebuild every time), the container reads data directly from your local filesystem. This means you can update configs or data without touching the image. `restart: unless-stopped` means Docker will restart the container automatically if it crashes or if the machine reboots, unless you explicitly stopped it.

The `db` service (PostgreSQL) is commented out as a ready-to-use example for when you need a database. The `volumes` section at the bottom (also commented) would create a named Docker volume to persist database data between container restarts.

---

### `.env.example`

A committed template showing which environment variables the project needs, without containing any real values.

```bash
# DATABASE_URL=postgresql://user:password@localhost:5432/mydb
# SECRET_KEY=your-secret-key
```

The workflow is: `.env.example` is committed and shared. Each developer (or deployment environment) copies it to `.env` and fills in real values. `.env` is gitignored so secrets never enter version control. Docker Compose loads `.env` automatically via `env_file: .env`.

---

### `.gitignore`

Tells Git which files and folders to never track. Key sections:

- **Python artifacts** — `__pycache__/`, `.pyc` files, `dist/`, `build/`, `.egg-info/` — these are generated files that change constantly and should never be committed.
- **Virtual environments** — `.venv/` — the installed packages live here; anyone can recreate this by running `uv sync`.
- **Runtime outputs** — `logs/*`, `data/*`, `runs/mlruns/*`, `runs/artifacts/*`, `results/*` — contents are gitignored but the folders themselves are tracked via `.gitkeep` files, so the folder structure is preserved in the repo without committing the actual data.
- **`.env`** — never commit secrets.
- **`configs/config.local.yaml`** — local config overrides with environment-specific paths or secrets.
- **`docs/build/`** — generated API documentation. Note that only `build/` is ignored: `docs/specs/` and `docs/adr/` are committed on purpose, since they're the written record the AI workflow produces.
- **Frontend build artifacts** — `frontend/node_modules/`, `frontend/.next/`, `frontend/dist/`, `frontend/.env.local`.

The pattern `folder/*` + `!folder/.gitkeep` is how you track an empty folder in Git (which normally ignores empty directories). The `.gitkeep` file has no content — it's just a placeholder.

---

### `.pre-commit-config.yaml`

Configures pre-commit hooks — scripts that run automatically every time you do `git commit`. If any hook fails, the commit is aborted.

```yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.4.4
    hooks:
      - id: ruff
        args: [--fix]     # auto-fix lint issues before committing
      - id: ruff-format   # auto-format before committing

  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: trailing-whitespace    # removes trailing spaces
      - id: end-of-file-fixer      # ensures files end with a newline
      - id: check-yaml             # validates YAML syntax
      - id: check-toml             # validates TOML syntax
      - id: check-merge-conflict   # catches unresolved merge conflict markers
      - id: debug-statements       # catches forgotten breakpoint() or pdb calls

  - repo: local
    hooks:
      - id: make-test
        name: Run test suite (make test)
        entry: make test
        language: system
        pass_filenames: false     # run the whole suite, not per-file
        always_run: true          # even if no Python files are staged
```

Each remote hook is pinned to a specific version (`rev`) for reproducibility, and runs against only the files you've staged for commit (not the whole repo), so they're fast. After running `make install`, these hooks are registered in `.git/hooks/pre-commit` and run automatically — you don't have to remember to run `make fix` manually.

The `local` `make-test` hook is different: it runs the full test suite on every commit. This is the **human** copy of the test gate. There are deliberately two:

| Gate | Who it guards | Bypassable? |
|---|---|---|
| `.pre-commit-config.yaml` → `make-test` | You, committing by hand | Yes — `git commit --no-verify` or `SKIP=make-test git commit` when you have a real reason |
| `.claude/hooks/test_gate.py` | The agent, committing through Claude Code | No — fires before Bash even runs, so `--no-verify` never comes into play |

Having the same rule in two places means a green test suite is a precondition for a commit no matter who is typing, while still leaving you an escape hatch the agent doesn't get.

---

### `dvc.yaml`

Defines your ML pipeline as a directed acyclic graph (DAG) of stages. DVC tracks which files each stage depends on and produces, so it can determine what needs to be re-run when something changes.

```yaml
stages:
  prepare:
    cmd: python -m my_project.pipeline.prepare
    deps:
      - data/raw                          # if raw data changes, re-run prepare
      - my_project/pipeline/prepare.py    # if the script changes, re-run prepare
    outs:
      - data/processed                    # DVC caches and tracks this output

  train:
    cmd: python -m my_project.pipeline.train
    deps:
      - data/processed
      - my_project/pipeline/train.py
      - configs/config.yaml               # config changes trigger a re-train
    outs:
      - runs/artifacts/model
    metrics:
      - runs/artifacts/metrics.json:
          cache: false                    # metrics are tracked but not cached

  evaluate:
    cmd: python -m my_project.pipeline.evaluate
    deps:
      - data/processed
      - runs/artifacts/model
      - my_project/pipeline/evaluate.py
    metrics:
      - runs/artifacts/evaluation.json:
          cache: false
    plots:
      - runs/artifacts/plots.csv:
          cache: false                    # plots are tracked for dvc plots
```

When you run `dvc repro`, DVC checks which stages are stale (their deps have changed since last run) and re-runs only those. It's like `make` but for ML pipelines, with built-in caching and remote storage. The stages here are placeholders — you'll rename and add stages to match your actual pipeline.

`metrics` files are small JSON files DVC tracks specially so you can compare metrics across Git commits with `dvc metrics diff`. `plots` files (CSV or JSON) can be rendered as charts with `dvc plots show`.

---

### `.dvcignore`

Same syntax as `.gitignore`, but for DVC. Files listed here are excluded from DVC's dependency tracking. You don't want DVC to watch your virtualenv or cache folders — it would cause false positives and slow down status checks.

---

## `configs/`

### `configs/config.yaml`

The main project configuration file. Written in YAML, which is human-readable and supports comments. The template includes a few common sections as starting points:

```yaml
app:
  name: "my_project"
  debug: false
```

The convention in this template is: `config.yaml` holds defaults that are safe to commit. `config.local.yaml` (gitignored) holds environment-specific overrides — local paths, credentials, debug flags. Your code loads `config.yaml` and optionally merges `config.local.yaml` on top.

---

### `configs/logging.yaml`

Configures Python's built-in `logging` module using the standard `dictConfig` format. The logger utility loads this file automatically.

```yaml
formatters:
  standard:
    format: "%(asctime)s | %(levelname)-8s | %(name)s:%(lineno)d - %(message)s"
    datefmt: "%Y-%m-%d %H:%M:%S"
```

The format string defines how each log line looks. `%(name)s` is the logger name (the module that called `get_logger(__name__)`), `%(lineno)d` is the line number — together they tell you exactly where a log message came from.

```yaml
handlers:
  file:
    class: logging.handlers.RotatingFileHandler
    filename: logs/my_project.log
    maxBytes: 10485760  # 10 MB
    backupCount: 5
```

`RotatingFileHandler` automatically creates a new log file when the current one reaches 10 MB, keeping up to 5 old files (`my_project.log.1` through `my_project.log.5`). This prevents logs from filling up a disk.

```yaml
loggers:
  httpx:
    level: WARNING
  httpcore:
    level: WARNING
```

Third-party libraries that use `logging` will produce output at INFO level by default. Setting them to WARNING silences their routine chatter while still showing errors. Add any other noisy libraries here.

---

## `{{project_name}}/` — the package

This folder becomes your importable Python package. Its name is set by the `project_name` variable at generation time.

### `{{project_name}}/__init__.py`

The file that makes a directory a Python package. Rendered from `__init__.py.jinja`: the module docstring is your `description` answer, and it sets `__version__ = "0.1.0"` (which `tests/test_sample.py` asserts against). You can also use it to expose the package's public API by importing from submodules here.

### `{{project_name}}/constants.py`

An empty module (docstring only) reserved for project-wide constants — paths, magic numbers, enum-like values. Keeping them in one place stops them from being redefined across modules, and gives agents an obvious spot to look before inventing a new one.

### `{{project_name}}/utils/__init__.py`

Makes `utils` a subpackage and re-exports `get_logger` so callers can write `from my_project.utils import get_logger` instead of the longer path.

### `{{project_name}}/utils/logger.py`

The shared logging utility. The key design decisions:

```python
_configured = False

def _configure_from_yaml() -> bool:
    """Load logging config from configs/logging.yaml. Returns True on success."""
    ...

def get_logger(name: str, level: int = logging.INFO) -> logging.Logger:
    global _configured
    if not _configured:
        _configured = _configure_from_yaml()
    ...
```

The `_configured` module-level flag ensures `configs/logging.yaml` is loaded exactly once, on the first call to `get_logger`, regardless of how many modules call it. Subsequent calls skip the YAML loading entirely.

If the YAML file doesn't exist (e.g. in a test environment or a project that doesn't use it), it falls back to a manual setup: a console handler and a date-stamped file handler in `logs/`. The filename pattern `module_name_2024-01-15.log` means each day gets its own file, making it easy to find logs for a specific date.

The line `logger.propagate = False` is important in the fallback path — without it, log messages would bubble up to Python's root logger and potentially be printed twice.

Usage in any module:

```python
from my_project.utils.logger import get_logger
logger = get_logger(__name__)   # __name__ is e.g. "my_project.pipeline.train"
```

---

## `tests/`

### `tests/__init__.py`

Empty file that makes `tests/` a package. Required for some import patterns in pytest.

### `tests/test_sample.py`

A minimal starting test that verifies the package version. More importantly, it serves as a template showing the expected structure of test files. Replace with real tests as the project grows.

Running `make test` invokes pytest with coverage enabled. The output shows a table of which lines in your package are not covered by tests, helping you identify gaps.

---

## `scripts/`

### `scripts/setup.sh`

A bootstrap script for setting up a fresh clone from scratch. Key details:

```bash
set -euo pipefail
```

This line makes the script strict: `-e` exits immediately if any command fails, `-u` treats unset variables as errors, `-o pipefail` catches failures in piped commands. This prevents the script from silently continuing after an error.

```bash
if ! command -v uv &> /dev/null; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
fi
```

Checks if `uv` is installed before trying to install it. The `export PATH` line is needed because the installer modifies `.bashrc` but the current shell session doesn't reload it automatically.

```bash
if [ ! -d ".dvc" ]; then
  uv run dvc init
fi
```

`dvc init` creates the `.dvc/` directory and adds some files to `.gitignore`. It only needs to run once per project, so this check prevents re-running it on `make setup`.

```bash
# ── 6. Optional tooling (graphify, rtk) ──
(uv tool install graphify && graphify install) || warn "graphify install failed -- ..."
curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/.../install.sh | sh || warn "rtk install failed -- ..."
```

The last step installs two optional tools that make AI agents work better in the repo, and is deliberately **best-effort** — each install is wrapped in `|| warn ...` so a failure prints a warning and the script keeps going instead of aborting under `set -e`:

- [**graphify**](https://github.com/Graphify-Labs/graphify) builds a knowledge graph of the codebase that assistants can query for structure instead of grepping.
- [**rtk**](https://github.com/rtk-ai/rtk) filters and compresses command output before it reaches an agent's context window, so long `pytest` or `git log` output doesn't burn tokens. The install path is OS-dependent: `brew` on macOS (falling back to the install script), the install script on Linux, `winget` on Windows (Git Bash / MSYS), and a skip-with-warning anywhere else.

Neither is a dependency of the project — they're conveniences for the person (or agent) driving it.

The coloured output (`GREEN`, `YELLOW`, `RED`) is purely cosmetic but makes it much easier to follow what the script is doing.

---

## `.github/`

### `.github/workflows/ci.yml`

The Continuous Integration workflow. Runs automatically on every push to `main` and every pull request targeting `main`.

```yaml
steps:
  - uses: actions/checkout@v4         # checks out your code

  - name: Install uv
    uses: astral-sh/setup-uv@v4       # installs uv on the runner

  - name: Set up Python
    run: uv python install             # installs the Python version from pyproject.toml

  - name: Install dependencies
    run: uv sync --all-extras          # installs everything including dev deps

  - name: Lint with Ruff
    run: uv run ruff check .           # fails the build if there are lint errors

  - name: Check formatting
    run: uv run ruff format --check .  # fails if code isn't formatted (doesn't modify)

  - name: Type-check with ty
    run: uv run ty check .             # fails on type errors

  - name: Run tests
    run: uv run pytest                 # runs the test suite with coverage
```

If any step fails, GitHub marks the commit/PR as failed and (optionally) blocks merging. This is the safety net that catches issues before they land on `main`. The four checks are exactly `make lint`, `make format` (in check mode), `make typecheck`, and `make test` — the same commands the agent runs throughout `implement`, so a PR that was built through the workflow should arrive green.

---

### `.github/workflows/cd.yml`

The Continuous Deployment workflow. Builds a Docker image and pushes it to GHCR (GitHub Container Registry). Disabled by default — only triggered manually via `workflow_dispatch`.

```yaml
- name: Extract metadata (tags & labels)
  uses: docker/metadata-action@v5
  with:
    tags: |
      type=semver,pattern={{version}}        # v1.2.3
      type=semver,pattern={{major}}.{{minor}} # v1.2
      type=sha,prefix=sha-                    # sha-abc1234
      type=raw,value=latest,enable={{is_default_branch}}
```

This automatically generates multiple image tags from a single push. If you push tag `v1.2.3`, your image gets tagged as `v1.2.3`, `v1.2`, `sha-abc1234`, and `latest` — all at once. This is standard practice so downstream services can pin to a specific version or always pull the latest.

```yaml
- name: Build and push
  with:
    cache-from: type=gha    # use GitHub Actions cache to speed up builds
    cache-to: type=gha,mode=max
```

Docker layer caching is stored in GitHub Actions' cache, so subsequent builds that haven't changed their dependencies skip the slow `uv sync` layer entirely.

To enable auto-trigger on version tags, uncomment the `push` block and push a tag: `git tag v1.0.0 && git push origin v1.0.0`.

---

### `.github/PULL_REQUEST_TEMPLATE.md`

Automatically pre-fills the description box when someone opens a pull request on GitHub. The sections are designed to be useful for both human reviewers and AI agents:

- **Summary** — forces the author to articulate what and why in prose.
- **Type of change** — checkboxes that categorise the PR, useful for automated changelog generation.
- **Changes made** — bullet list of specific changes, precise enough for an agent to use when generating a summary or changelog entry.
- **Breaking changes** — explicit field so reviewers never have to guess.
- **How to test** — step-by-step so any reviewer (or agent) can verify the change without prior knowledge.
- **AI-specific notes** — documents AI involvement, which helps future reviewers understand which parts were human-verified and which weren't.

---

### `.github/ISSUE_TEMPLATE/bug_report.md`

Pre-fills new issues tagged as bugs. The structured sections — environment, steps to reproduce, expected vs actual behaviour, minimal reproducible example — give agents enough information to diagnose and fix a bug without requiring back-and-forth.

### `.github/ISSUE_TEMPLATE/feature_request.md`

For proposing new functionality. The **acceptance criteria** section is key for AI-assisted development — it defines "done" in verifiable terms, which an agent can check off as it implements the feature.

### `.github/ISSUE_TEMPLATE/task.md`

The most agent-oriented template. Designed for concrete, bounded units of work:

- **Scope / Out of scope** — explicitly bounds what the agent should and shouldn't touch.
- **Implementation notes** — optional hints that prevent the agent from choosing a wrong approach.
- **Acceptance criteria** — verifiable conditions the agent can self-check against.
- **Definition of done** — standard checklist that applies to every task (lint passes, tests added, changelog updated, PR opened).

---

## `.claude/`

Everything under `.claude/` is what makes a generated project *AI-native* rather than merely AI-friendly. `CLAUDE.md` tells the agent what the project is; this folder gives it a process to follow, specialists to delegate to, and guardrails it can't switch off.

```
.claude/
├── settings.json        ← context file + PreToolUse hooks
├── hooks/               ← two Python scripts Claude Code runs before every Bash call
├── agents/              ← 7 subagent definitions (+ README roster)
└── skills/              ← 13 engineering skills + 9 productivity skills (+ README rosters)
```

The pieces compose as described in `CLAUDE.md`'s **Development workflow** section. In one line: `/grill-with-docs` → `/spec` → `implement` (`tdd` + `logic-checker` + `code-reviewer`) → `/commit-push` (`changelog-writer` + `readme-updater` + `commit-push`) → PR by hand, with `diagnosing-bugs` → `debugger` as the separate track for things that are already broken, and the two hooks underneath all of it.

### `.claude/settings.json`

```json
{
  "context": {
    "files": ["CLAUDE.md"]
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "python3 $CLAUDE_PROJECT_DIR/.claude/hooks/destructive_guard.py" },
          { "type": "command", "command": "python3 $CLAUDE_PROJECT_DIR/.claude/hooks/test_gate.py" }
        ]
      }
    ]
  }
}
```

`context.files` tells Claude Code to read `CLAUDE.md` first when it starts a session. The `hooks` block registers two `PreToolUse` hooks that fire on every `Bash` tool call: Claude Code pipes the pending call as JSON to each script's stdin, and a script that exits with code 2 blocks the call (its stderr is shown to the agent as the reason). Both are invoked with `python3`, so it needs to be on the PATH of the shell Claude Code runs in.

### `.claude/hooks/`

Both hooks share a philosophy: **they guard the agent, not you**, so neither has an override. If you need to do one of these things yourself, do it outside Claude Code.

**`test_gate.py`** — blocks any Bash call containing `git commit` unless `make test` passes first. It matches the command string with a regex (`git ... commit`, including `git -C path commit` and chained `&& git commit`) and deliberately ignores whatever flags follow, so `--no-verify` doesn't help — the hook runs before Bash ever sees the command. Tests run with a 10-minute timeout. Infrastructure problems (no `Makefile`, no `make` or `uv` on PATH, malformed hook input) **fail open** with a warning rather than blocking on something the agent can't fix by writing code.

**`destructive_guard.py`** — blocks a short list of obviously destructive commands:

- `rm -rf` (any equivalent flag combination) targeting `/`, `~`, `.`, `..`, `*`, `$HOME`, `.git`, the project root, or an ancestor of it
- `git reset --hard`
- `git clean` with a force flag
- `git checkout .` / `git restore .` (discards every uncommitted change)
- `git branch -D main|master`
- `git push --force` / `-f` to `main` or `master` (branch resolved from the explicit refspec, else the current branch)

It splits on `&&`, `||`, `;`, `|` to inspect each command in a chain and tokenizes with `shlex`. It's a heuristic safety net for the common careless case, not a shell parser — unusual quoting can slip past it.

### `.claude/agents/`

Subagents are independent Claude contexts the main agent dispatches for a specific job. Each is a Markdown file whose frontmatter sets the model, reasoning effort, and allowed tools; the body is the brief. Using a separate context keeps the main conversation lean and — for the read-only ones — makes them safe to run without touching the working tree. `agents/README.md` is the roster; the summary:

| Agent | Model / effort | Tools | Job |
|---|---|---|---|
| `context-scout` | haiku / medium | read-only | Fact-finding in the repo (code, docs, ADRs, git history). Dispatched by `grilling` and anything that delegates to it whenever a question needs a fact instead of a decision. |
| `code-reviewer` | sonnet / high | read-only | Fresh-eyes review of a diff for correctness, security, seam discipline, and fit with `CLAUDE.md`/`CONTEXT.md`/ADRs. Reports, doesn't fix. Runs at the end of `implement` and `debugger`. |
| `logic-checker` | sonnet / high | read-only | Per-seam check that the implementation matches the spec's *Implementation Decisions* and nothing is missing that the seam's own test wouldn't catch. Runs before that seam's test confirms green. Narrower and earlier than `code-reviewer`. |
| `changelog-writer` | sonnet / low | edit | Updates `CHANGELOG.md`'s `[Unreleased]` from recent commits; cuts a release section when asked. History only. |
| `readme-updater` | sonnet / low | edit | Keeps `README.md` and other top-level docs (skills READMEs, etc.) accurate and lean — deletes stale content as readily as it adds. Current-state only. |
| `commit-push` | haiku / low | Bash | Stages, drafts commit message(s) from the diff, commits (split into logical commits when large), pushes once. Only ever triggered by the `/commit-push` skill. Never opens a PR. |
| `debugger` | opus / high | edit + run | Structured diagnosis loop — repro, minimise, rank hypotheses, instrument, fix with a regression test — up to two rounds before writing up what was tried. Dispatched by `diagnosing-bugs`, one confirmed symptom at a time. Stops short of committing. |

The model-tier choices are deliberate: cheap models for mechanical work (`context-scout`, `commit-push`), stronger ones with high effort for judgement (`code-reviewer`, `logic-checker`), and the strongest with a skeptical brief for debugging, where anchoring on the first plausible cause is the failure mode.

The two hooks apply to subagents exactly as they apply to the main agent — `commit-push` can't commit past a red test suite either.

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
| `commit-push` | you (`/commit-push`) | Dispatches `changelog-writer` and `readme-updater`, then the `commit-push` subagent. The only way a commit happens in the workflow. |
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
- `CHANGELOG.md` and `README.md` — kept current by `changelog-writer` and `readme-updater` on every `/commit-push`.

None of these exist in a fresh project; `docs/` ships as an empty `.gitkeep` folder and the skills create the subfolders on first use.

---

## `.dockerignore`

Like `.gitignore` but for Docker builds. When Docker copies files into the build context, it excludes everything listed here. This matters for two reasons: build speed (less data to send to the Docker daemon) and image cleanliness (dev files don't end up in production images).

Key exclusions:
- `.git/` — the entire git history has no place in an image
- `data/`, `logs/`, `runs/`, `results/` — mount these as volumes instead
- `notebooks/`, `frontend/` — built and served separately
- `.github/`, `.pre-commit-config.yaml`, `.vscode/`, `.idea/` — dev tooling irrelevant in production
- `docs/`, `*.md` files — documentation (specs, ADRs, generated API docs, `CLAUDE.md`) doesn't belong in a runtime image
- `.dvc/`, `dvc.yaml` — pipeline definition is a dev-time concern

`.claude/` is not excluded explicitly but every file in it is either `.md` (caught by `*.md`), `.json`, or `.py` under a folder the runtime never imports — harmless, but add `.claude/` here if you want a strictly minimal context.

---

## Folder-only entries (`.gitkeep` files)

These folders contain only a `.gitkeep` file — an empty placeholder that allows Git to track the folder without any real content. Git doesn't track empty directories, so `.gitkeep` is the convention for "this folder should exist in the repo but its contents are gitignored (or created later)."

| Folder | Purpose |
|---|---|
| `data/` | Source and processed data. Contents gitignored, DVC-tracked. Conventionally split into `raw/` (immutable) and `processed/` (regenerated by the `prepare` DVC stage) — create the subfolders when you set up your pipeline; `dvc.yaml` already references them. |
| `docs/` | Written record of the project. `specs/` and `adr/` are created by the AI workflow and committed; `build/` is generated by `make docs` and gitignored. |
| `notebooks/` | Jupyter notebooks for exploration and analysis. Not used in the pipeline. |
| `frontend/src/` | Frontend source code (components, pages, styles). Occasional — the `frontend-design` skill covers the aesthetic side when you get there. |
| `infra/` | Infrastructure as code — Terraform, Pulumi, Kubernetes manifests, and the like. Occasional. |
| `logs/` | Runtime log files written by the logger. Rotated automatically. |
| `runs/mlruns/` | MLflow experiment tracking data — metrics, parameters, run metadata. |
| `runs/artifacts/` | Trained model files, checkpoints, outputs produced by pipeline stages. |
| `results/` | Final evaluation outputs, plots, tables — things you'd share or reference in a report. |
| `scripts/` | One-off utility scripts. `setup.sh` lives here; add migration scripts, data download scripts, etc. |

---

## Summary: which files you'll touch regularly

| File | How often | When |
|---|---|---|
| `CLAUDE.md` | Frequently | Every time the project architecture or conventions change — keep it current so the agent stays effective |
| `CONTEXT.md` | Frequently, via the skills | Whenever terminology gets settled (`/grill-with-docs`, `domain-modeling`) |
| `docs/specs/` | Per feature / fix | Created by `/spec`, updated by `implement` and `debugger` — you read the reports, you rarely edit them |
| `docs/adr/` | Per hard decision | Written by `domain-modeling` when a non-obvious, hard-to-reverse choice is made |
| `CHANGELOG.md` | Per commit, via `changelog-writer` | Whenever something user-facing changes — automated through `/commit-push` |
| `README.md` | Per commit, via `readme-updater` | Whenever the change makes something in it stale — automated through `/commit-push` |
| `configs/config.yaml` | Per project | When adding new configuration |
| `dvc.yaml` | Per pipeline change | When adding or renaming pipeline stages |
| `pyproject.toml` | Occasionally | When adding dependencies (through `uv add`, never by hand) |
| `.claude/skills/` | Occasionally | When you add a project-specific skill — `writing-for-agents` is the guide |
| `.claude/agents/` | Rarely | When you need a new specialist or want to change a model tier |
| `Makefile` | Rarely | When adding new workflow shortcuts |
| `Dockerfile` | Rarely | When changing runtime requirements |
| `docker-compose.yml` | Rarely | When adding services |
| `.github/workflows/` | Rarely | When changing CI/CD behaviour |
| `.pre-commit-config.yaml` | Rarely | When adding new hooks or updating versions |
| `.claude/hooks/`, `.claude/settings.json` | Almost never | Only if you want to extend the guardrails — they're meant to stay fixed |
