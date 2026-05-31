# python-template

A [Copier](https://copier.readthedocs.io/) template for Python projects, designed for ML and data-heavy workloads with AI-assisted development in mind.

## What's included

**Project structure**
- Named package folder (`{{project_name}}/`) with a `utils/` subpackage and a shared logger
- `tests/`, `notebooks/`, `scripts/`, `front/`, `configs/`, `data/`, `logs/`, `runs/`, `results/`

**Dependency management & tooling**
- `pyproject.toml` configured for **uv**, **Ruff**, and **pytest** with coverage
- `Makefile` with shortcuts for setup, testing, linting, docs, DVC, and Docker
- `scripts/setup.sh` — one-command bootstrap for a fresh clone
- `.pre-commit-config.yaml` with Ruff + common safety hooks

**Logging**
- `configs/logging.yaml` — rotating file handler, configurable per-module levels
- `{{project_name}}/utils/logger.py` — `get_logger(__name__)` loads YAML config automatically, falls back to sensible defaults

**Data & ML**
- `dvc.yaml` with placeholder `prepare → train → evaluate` pipeline stages
- `data/raw/`, `data/processed/`, `runs/mlruns/`, `runs/artifacts/`, `results/`

**Docker**
- `Dockerfile` using uv for fast, reproducible image builds
- `docker-compose.yml` with volume mounts for data, logs, configs, and a commented-out database service

**CI/CD**
- GitHub Actions CI — lint, format check, and tests on every push and PR
- GitHub Actions CD — builds and pushes Docker image to GHCR (manual trigger by default, easy to enable on tags)

**AI-assisted development**
- `CLAUDE.md` — project brief for AI coding assistants
- `.claude/settings.json` — points Claude Code to `CLAUDE.md`
- `.github/PULL_REQUEST_TEMPLATE.md` — structured PR template with an AI-specific notes section
- `.github/ISSUE_TEMPLATE/` — bug report, feature request, and task templates with acceptance criteria

**Other**
- `.gitignore`, `.dockerignore`, `.dvcignore`
- `.vscode/launch.json` — debugger configurations for current file and named modules
- `CHANGELOG.md` in Keep a Changelog format
- `.env.example`

---

## Usage

### Generate a new project

```bash
# Install copier once
pip install copier

# Generate a project from this template
copier copy gh:your-username/python-template ./my-new-project
```

Copier will ask:

| Question | Description |
|---|---|
| `project_name` | Package name — becomes the importable folder and pyproject.toml name |
| `description` | Short one-line description |
| `author_name` | Your full name |
| `author_email` | Your email |
| `python_version` | Minimum Python version (3.11, 3.12, 3.13) |
| `open_source_license` | MIT, Apache-2.0, GPL-3.0, or None |

Then bootstrap the generated project:

```bash
cd my-new-project
bash scripts/setup.sh
source .venv/bin/activate
```

### Update an existing project

If you improve this template, pull the changes into any project generated from it:

```bash
cd my-existing-project
copier update
```

Copier diffs the old and new template versions and merges the changes. Projects can be pinned to a specific template version using a Git tag.

---

## Template structure

```
python-template/
├── copier.yml                          ← questions & Copier config
└── template/                           ← copied into generated projects
    ├── {{project_name}}/
    │   ├── __init__.py.jinja
    │   └── utils/
    │       ├── __init__.py.jinja
    │       └── logger.py.jinja
    ├── tests/
    │   ├── __init__.py.jinja
    │   └── test_sample.py.jinja
    ├── notebooks/
    ├── data/
    │   ├── raw/
    │   └── processed/
    ├── scripts/
    │   └── setup.sh
    ├── front/
    │   ├── src/
    │   └── public/
    ├── configs/
    │   ├── config.yaml.jinja
    │   └── logging.yaml.jinja
    ├── logs/
    ├── runs/
    │   ├── mlruns/
    │   └── artifacts/
    ├── results/
    ├── .github/
    │   ├── workflows/
    │   │   ├── ci.yml
    │   │   └── cd.yml
    │   ├── ISSUE_TEMPLATE/
    │   │   ├── bug_report.md
    │   │   ├── feature_request.md
    │   │   └── task.md
    │   └── PULL_REQUEST_TEMPLATE.md
    ├── .vscode/
    │   └── launch.json.jinja
    ├── .claude/
    │   ├── skills/
    │   ├── guidelines_verbose.md
    │   ├── guidelines.md
    │   └── settings.json
    ├── pyproject.toml.jinja
    ├── Makefile.jinja
    ├── Dockerfile.jinja
    ├── docker-compose.yml.jinja
    ├── dvc.yaml.jinja
    ├── CLAUDE.md.jinja
    ├── README.md.jinja
    ├── CHANGELOG.md
    ├── .gitignore
    ├── .dockerignore
    ├── .dvcignore
    ├── .pre-commit-config.yaml
    └── .env.example
```
