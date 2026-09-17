# python-template

A [Copier](https://copier.readthedocs.io/) template for Python projects, designed for ML and data-heavy workloads with AI-native development baked in: a full Claude Code workflow (skills, subagents, and safety hooks) ships with every generated project.

## What's included

**Project structure**
- Named package folder (`{{project_name}}/`) with a `constants.py` module and a `utils/` subpackage holding a shared logger
- `tests/`, `notebooks/`, `scripts/`, `configs/`, `data/`, `logs/`, `runs/`, `results/`, `docs/`, `frontend/`, `infra/`

**Dependency management & tooling**
- `pyproject.toml` configured for **uv**, **Ruff**, **ty** (type checking), and **pytest** with coverage
- `Makefile` with shortcuts for setup, testing, linting, type-checking, docs, DVC, and Docker
- `scripts/setup.sh` — one-command bootstrap for a fresh clone (uv, deps, pre-commit, DVC, `.env`), plus a best-effort install of two optional agent-support tools:
  - [**graphify**](https://github.com/Graphify-Labs/graphify) — builds a queryable knowledge graph of the codebase for AI assistants
  - [**rtk**](https://github.com/rtk-ai/rtk) — filters and compresses command output before it reaches an agent's context window
- `.pre-commit-config.yaml` with Ruff, common safety hooks, and a local `make test` gate

**Logging**
- `configs/logging.yaml` — rotating file handler, configurable per-module levels
- `{{project_name}}/utils/logger.py` — `get_logger(__name__)` loads YAML config automatically, falls back to sensible defaults

**Data & ML**
- `dvc.yaml` with placeholder `prepare → train → evaluate` pipeline stages
- `data/`, `runs/mlruns/`, `runs/artifacts/`, `results/` (gitignored contents, tracked structure)

**Docker**
- `Dockerfile` using uv for fast, reproducible image builds
- `docker-compose.yml` with volume mounts for data, logs, configs, and a commented-out database service

**CI/CD**
- GitHub Actions CI — lint, format check, type-check, and tests on every push and PR
- GitHub Actions CD — builds and pushes Docker image to GHCR (manual trigger by default, easy to enable on tags)

**AI-native development (Claude Code)**
- `CLAUDE.md` — project brief plus a *Development workflow* section mapping how the skills, subagents, and hooks compose end to end
- `.claude/settings.json` — points Claude Code to `CLAUDE.md` and registers the two `PreToolUse` hooks
- `.claude/hooks/` — `test_gate.py` (no `git commit` until `make test` passes, no override) and `destructive_guard.py` (blocks `rm -rf` on dangerous paths, `git reset --hard`, force-pushes to `main`, etc.)
- `.claude/agents/` — 7 subagents: `context-scout`, `code-reviewer`, `logic-checker`, `changelog-writer`, `readme-updater`, `commit-push`, `debugger`
- `.claude/skills/` — 13 engineering skills (`spec`, `implement`, `tdd`, `diagnosing-bugs`, `grill-with-docs`, `grilling`, `domain-modeling`, `commit-push`, `claude-handoff`, `walkthrough`, `doubt`, `handcraft`, `frontend-design`) plus 9 general-purpose `productivity_skills/`
- `docs/specs/` and `docs/adr/` conventions, and a project glossary (`CONTEXT.md`) maintained by the skills
- `.github/PULL_REQUEST_TEMPLATE.md` — structured PR template with an AI-specific notes section
- `.github/ISSUE_TEMPLATE/` — bug report, feature request, and task templates with acceptance criteria

**Other**
- `.gitignore` (ignores `.DS_Store`/`Thumbs.db` among the usual suspects), `.dockerignore`, `.dvcignore`
- `CHANGELOG.md` in Keep a Changelog format
- `.env.example`

See [python-template-guide.md](python-template-guide.md) for a file-by-file explanation of everything in the template, including the full AI workflow.

---

## The AI-native workflow in one paragraph

For anything bigger than a one-line fix: `/grill-with-docs` to clarify a loose idea (writing terms to `CONTEXT.md` and hard decisions to `docs/adr/`) → `/spec` to write `docs/specs/<type>-<yyyy_mm>-<name>/SPEC.md` + a seam-organized `plan/PLAN.md` and cut a branch → `implement` runs automatically after, doing `tdd` at each seam with `logic-checker` and a final `code-reviewer` pass, writing reports to the spec's `reports/` → `/commit-push` dispatches `changelog-writer` and `readme-updater`, then commits (split logically if large) and pushes → you open the PR. Bugs take a separate track through `diagnosing-bugs` → the `debugger` subagent (Opus, skeptical mindset). Two hooks run underneath all of it: no commit without green tests, and no destructive shell commands. Full rosters live in the generated project's `.claude/skills/README.md` and `.claude/agents/README.md`.

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
| `python_version` | Minimum Python version (default `3.12`) |
| `open_source_license` | MIT, Apache-2.0, GPL-3.0, or None |

Then bootstrap the generated project:

```bash
cd my-new-project
bash scripts/setup.sh
source .venv/bin/activate
```

The hooks in `.claude/settings.json` are invoked as `python3 $CLAUDE_PROJECT_DIR/.claude/hooks/<hook>.py`, so `python3` must be on the PATH of whatever shell Claude Code runs in.

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
├── .gitignore                          ← template repo's own (.DS_Store, Thumbs.db)
├── README.md                           ← this file (not copied)
├── python-template-guide.md            ← file-by-file reference (not copied)
└── template/                           ← copied into generated projects
    ├── {{project_name}}/
    │   ├── __init__.py.jinja
    │   ├── constants.py
    │   └── utils/
    │       ├── __init__.py.jinja
    │       └── logger.py.jinja
    ├── tests/
    │   ├── __init__.py
    │   └── test_sample.py.jinja
    ├── notebooks/
    ├── data/
    ├── docs/                           ← specs/, adr/, build/ created on demand
    ├── scripts/
    │   └── setup.sh
    ├── frontend/
    │   └── src/
    ├── infra/
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
    ├── .claude/
    │   ├── settings.json               ← context file + PreToolUse hooks
    │   ├── hooks/
    │   │   ├── destructive_guard.py
    │   │   └── test_gate.py
    │   ├── agents/                     ← README.md + 7 subagent definitions
    │   │   ├── changelog-writer.md
    │   │   ├── code-reviewer.md
    │   │   ├── commit-push.md
    │   │   ├── context-scout.md
    │   │   ├── debugger.md
    │   │   ├── logic-checker.md
    │   │   └── readme-updater.md
    │   └── skills/                     ← README.md + one folder per skill
    │       ├── claude-handoff/
    │       ├── commit-push/
    │       ├── diagnosing-bugs/
    │       ├── domain-modeling/
    │       ├── doubt/
    │       ├── frontend-design/
    │       ├── grill-with-docs/
    │       ├── grilling/
    │       ├── handcraft/
    │       ├── implement/
    │       ├── spec/
    │       ├── tdd/
    │       ├── walkthrough/
    │       └── productivity_skills/    ← grill-me, handoff, lbt, mvk, rp, teach,
    │                                      to-questionnaire, wait-what, writing-for-agents
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
