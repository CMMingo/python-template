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
authors = ...
requires-python = ">=3.12"
readme = "README.md"
license = { text = "MIT" }
dependencies = [
  "pyyaml",        # used by the logger to load configs/logging.yaml
]

[project.optional-dependencies]
dev = [
  "ruff",          # linting and formatting
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

---

### `README.md`

The project's front page, shown on GitHub and in documentation. Already written as a template — it documents the project structure, all `make` commands in tables, configuration, logging, and CI/CD. Fill in the description and update it as the project grows.

---

### `CHANGELOG.md`

A human-readable log of notable changes across versions. Follows the [Keep a Changelog](https://keepachangelog.com) format:

```markdown
## [Unreleased]
### Added
### Changed
### Fixed
```

The `[Unreleased]` section collects changes that haven't been released yet. When you cut a release, you rename it to `[1.0.0] - <date>` and open a new `[Unreleased]` section above it. This is particularly useful when working with AI agents: they can update this file as part of a PR, giving you a running record of what changed and why.

---

### `CLAUDE.md`

A file specifically for AI coding assistants. When Claude (or another AI tool) opens your project, it reads this file first to understand the context it's operating in. Think of it as a brief for a new team member who reads extremely fast.

```markdown
## Project overview
## Architecture
## Stack & tools
## Common commands
## Key conventions
## Out of scope
```

Fill this in as the project evolves. The more accurate and detailed it is, the better an AI agent will perform on tasks in this codebase — it won't suggest patterns that don't fit, won't touch things marked out of scope, and will use the right commands.

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
- **Runtime outputs** — `logs/*`, `data/*`, `runs/*`, `results/*` — contents are gitignored but the folders themselves are tracked via `.gitkeep` files, so the folder structure is preserved in the repo without committing the actual data.
- **`.env`** — never commit secrets.
- **`configs/config.local.yaml`** — local config overrides with environment-specific paths or secrets.
- **`docs/build/`** — generated documentation.
- **Frontend build artifacts** — `node_modules/`, `.next/`, `dist/`.

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
```

Each hook is pinned to a specific version (`rev`) for reproducibility. The hooks run against only the files you've staged for commit (not the whole repo), so they're fast. After running `make install`, these hooks are registered in `.git/hooks/pre-commit` and run automatically — you don't have to remember to run `make fix` manually.

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

The file that makes a directory a Python package. Currently just sets `__version__`. You can also use it to expose the package's public API by importing from submodules here.

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

  - name: Run tests
    run: uv run pytest                 # runs the test suite with coverage
```

If any step fails, GitHub marks the commit/PR as failed and (optionally) blocks merging. This is the safety net that catches issues before they land on `main`.

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

## `.vscode/`

### `.vscode/launch.json`

Configures the VS Code debugger. Each entry in `configurations` appears as a named option in the Run & Debug panel.

```json
{
  "name": "Python Debugger: Current File",
  "type": "debugpy",
  "request": "launch",
  "program": "${file}",         // runs whatever file is currently open
  "justMyCode": false           // steps into library code, not just yours
}
```

The other entries are for debugging specific modules:

```json
{
  "name": "Debug x module",
  "type": "debugpy",
  "request": "launch",
  "module": "<x> file",  // python -m equivalent
  "cwd": "${workspaceFolder}",  // runs from the project root
  "justMyCode": false
}
```

Using `"module"` instead of `"program"` is equivalent to running `python -m my_project.pipeline.run_pipeline` from the terminal — it respects Python's package system properly. These are placeholders; update them to match your actual module structure.

---

## `.claude/`

### `.claude/settings.json`

Tells Claude Code (the CLI tool) which files to prioritise for project context.

```json
{
  "context": {
    "files": ["CLAUDE.md"]
  }
}
```

When Claude Code starts a session in your project, it reads `CLAUDE.md` first. This is the bridge between the `.claude/` folder and the `CLAUDE.md` file — the settings tell Claude Code where to find the project brief.

---

## `.dockerignore`

Like `.gitignore` but for Docker builds. When Docker copies files into the build context, it excludes everything listed here. This matters for two reasons: build speed (less data to send to the Docker daemon) and image cleanliness (dev files don't end up in production images).

Key exclusions:
- `.git/` — the entire git history has no place in an image
- `data/`, `logs/`, `runs/`, `results/` — mount these as volumes instead
- `notebooks/`, `front/` — built and served separately
- `.github/`, `.pre-commit-config.yaml`, `.vscode/` — dev tooling irrelevant in production
- `*.md` files — documentation doesn't belong in a runtime image

---

## Folder-only entries (`.gitkeep` files)

These folders contain only a `.gitkeep` file — an empty placeholder that allows Git to track the folder without any real content. Git doesn't track empty directories, so `.gitkeep` is the convention for "this folder should exist in the repo but its contents are gitignored."

| Folder | Purpose |
|---|---|
| `data/raw/` | Original source data. Treat as immutable — never modify raw data. |
| `data/processed/` | Cleaned, transformed data ready for training. Regenerated by the `prepare` DVC stage. |
| `notebooks/` | Jupyter notebooks for exploration and analysis. Not used in the pipeline. |
| `front/src/` | Frontend source code (components, pages, styles). |
| `front/public/` | Static assets served directly (images, fonts, icons). |
| `logs/` | Runtime log files written by the logger. Rotated automatically. |
| `runs/mlruns/` | MLflow experiment tracking data — metrics, parameters, run metadata. |
| `runs/artifacts/` | Trained model files, checkpoints, outputs produced by pipeline stages. |
| `results/` | Final evaluation outputs, plots, tables — things you'd share or reference in a report. |
| `scripts/` | One-off utility scripts. `setup.sh` lives here; add migration scripts, data download scripts, etc. |

---

## Summary: which files you'll touch regularly

| File | How often | When |
|---|---|---|
| `CLAUDE.md` | Frequently | Every time the project architecture changes |
| `CHANGELOG.md` | Per PR | Whenever something user-facing changes |
| `configs/config.yaml` | Per project | When adding new configuration |
| `dvc.yaml` | Per pipeline change | When adding or renaming pipeline stages |
| `pyproject.toml` | Occasionally | When adding dependencies |
| `Makefile` | Rarely | When adding new workflow shortcuts |
| `Dockerfile` | Rarely | When changing runtime requirements |
| `docker-compose.yml` | Rarely | When adding services |
| `.github/workflows/` | Rarely | When changing CI/CD behaviour |
| `.pre-commit-config.yaml` | Rarely | When adding new hooks or updating versions |
| `CLAUDE.md` | Per sprint | Keep it current so AI tools stay effective |
