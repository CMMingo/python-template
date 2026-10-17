# python-template

A [Copier](https://copier.readthedocs.io/) template for Python projects, designed for ML and data-heavy workloads with AI-native development baked in: a full Claude Code workflow (skills, subagents, and safety hooks) ships with every generated project.

## Layouts

One template, two questions (`project_layout`, `use_ml`) cover three kinds of project:

| Kind | Answers | You get |
|---|---|---|
| Simple Python project | `simple`, `use_ml: no` | Package named after the project plus a single `tests/` folder at the repo root |
| ML / data project | `simple`, `use_ml: yes` | The above plus `dvc.yaml` with a runnable placeholder pipeline (`<package>/pipeline/`), `notebooks/`, `data/`, `runs/`, `results/`, DVC and ipykernel |
| Product | `product` (+ optional `use_ml`) | `backend/` (package `app`, own `pyproject.toml`, `uv.lock` and `tests/`), `frontend/` (empty on purpose: a `decide-frontend-style.md` guide helps you choose the stack later), `infra/` with its own `tests/` |

`config/`, `logs/`, `docs/`, `scripts/` and the ML folders always live at the repo root, shared by every part of the project. Everything else (CI, pre-commit, justfile, setup script, Dependabot, README, `AGENTS.md`) adapts to the layout.

---

## Usage

### Generate a new project

```bash
# Install copier once (bootstrap-machine.sh does this too)
uv tool install copier

# Generate a project from this template (--trust lets Copier run the setup tasks)
copier copy --trust gh:your-username/python-template ./my-new-project
```

Copier will ask:

| Question | Description |
|---|---|
| `project_name` | Lowercase letters, digits, underscores. Names `pyproject.toml` and, in `simple` projects, the package folder |
| `description` | Short one-line description |
| `python_version` | Minimum Python version (default `3.12`) |
| `open_source_license` | MIT, Apache-2.0, GPL-3.0, or None |
| `project_layout` | `simple` (package + tests at the root) or `product` (`backend/`, `frontend/`, `infra/`) |
| `use_ml` | Add DVC, notebooks, data, runs and results folders |

Machine-wide tools are installed once per machine, not per project. `bootstrap-machine.sh` (in this repo, never copied into projects) installs `uv`, `copier` and `just` (with `uv tool install`), plus the optional `graphify` and `rtk`, and skips whatever is already there:

```bash
bash bootstrap-machine.sh
```

Then bootstrap each generated project (needed on a fresh clone, or if the setup tasks were skipped). It only checks for the machine tools, and says how to get any that are missing:

```bash
cd my-new-project
bash scripts/setup.sh
```

The hooks in `.claude/settings.json` are invoked as `python3 $CLAUDE_PROJECT_DIR/.claude/hooks/<hook>.py`, so `python3` must be on the PATH of whatever shell Claude Code runs in.

### Update an existing project

If you improve this template, pull the changes into any project generated from it:

```bash
cd my-existing-project
copier update
```

Copier diffs the old and new template versions and merges the changes. It needs the project's `.copier-answers.yml` (the template generates it; keep it committed) and a clean git tree.

Tag the template repo when you release a set of changes (`git tag v0.2.0`): Copier updates to the latest tag, and a project can be pinned to a specific one. Without tags it follows the latest commit.

When generation finishes, Copier prints the next steps for the layout you chose (`_message_after_copy` in `copier.yml`).

---

## What's included

**Project structure**
- `backend/app/` (product) or a package named after the project (simple), with a `constants.py` module and a `utils/` subpackage holding a shared logger that finds `logs/` from the repo root, whatever the working directory
- `config/`, `logs/`, `docs/`, `scripts/` in every layout; `frontend/` and `infra/` only in `product`; `data/`, `notebooks/`, `runs/`, `results/` only with `use_ml`

**Latest dependencies, pinned exactly**
- `pyproject.toml` ships with no dependency list. When the project is generated, `scripts/resolve-latest.sh` (run by a Copier task) does the work:
  - `uv add` resolves the latest dev dependencies (the template has no runtime dependencies); `add-bounds = "exact"` writes `==` pins, and the committed `uv.lock` locks everything underneath
  - `pre-commit autoupdate` bumps the hook revisions
- Needs network access and `copier copy --trust`. The script skips itself once `uv.lock` exists, and with a warning when `uv` is missing; `scripts/setup.sh` finishes the job later
- The frontend is **not** scaffolded, so no tool versions are pinned before you know what you need: `frontend/decide-frontend-style.md` walks you through the choice (kind of interface, framework, defaults), the scaffold command, how to pin exact versions, and the scripts (`lint`, `test`, `build`) the justfile and CI expect. `just` and CI skip the frontend until `frontend/package.json` exists

**Dependency management & tooling**
- `pyproject.toml` configured for **uv**, **Ruff**, **ty** (type checking), and **pytest** with coverage
- `justfile` with shortcuts for setup, testing, linting, type-checking and docs (plus DVC with `use_ml`, frontend recipes in `product`)
- `scripts/setup.sh` — project bootstrap for a fresh clone: checks the required tools, installs dependencies and the pre-commit hook, initialises DVC (`use_ml`), creates `.env`. It never installs anything system-wide
- `.pre-commit-config.yaml` — fast checks only, so commits stay quick: Ruff (not applied to `.claude/`), whitespace and merge-marker hooks, a large-file guard, a secret scan (detect-secrets), `nbstripout` with `use_ml`, and a type-check hook. There is no test hook: run `just test` when you want it (CI runs it on every push)
- `.vscode/` — shared editor config, rendered per layout: `settings.json` (the right interpreter, `backend/.venv` in product projects; Ruff as formatter with format and fix on save; pytest wired to the project folder), `extensions.json` (Python, Ruff, ty) and `tasks.json` (wrappers over the `just` recipes, plus `just dev` in product). Anything else in `.vscode/` stays local
- `.python-version`, written with `uv python pin` at generation time, so every machine and CI use the same interpreter; `.gitattributes` keeps shell scripts and the justfile on LF endings
- `just dev` (product only) — `scripts/dev.sh` starts the backend and frontend together and stops both on Ctrl+C. It ships with the two commands left empty, to fill in once the stack is chosen

**Logging**
- `{{package_name}}/utils/logger.py` — `get_logger(__name__)` configures logging in code on first use: console plus a rotating file in the root `logs/`, level from `LOG_LEVEL`. No YAML to keep in sync, and it works from any working directory

**Data & ML** (`use_ml`)
- `dvc.yaml` with a `prepare → train → evaluate` pipeline whose stage modules exist as runnable placeholders (`dvc init && just dvc-repro` works on a fresh project), DVC `just` recipes
- `data/`, `runs/mlruns/`, `runs/artifacts/`, `results/`, `notebooks/` (gitignored contents, tracked structure)

**CI**
- `ci.yml` — Python job (lint, format check, type-check, tests) and a frontend job that only runs when `frontend/package.json` exists; both call `just` recipes, so CI and local runs can't drift apart
- `markdown.yml` — markdownlint plus a relative-link check (`.claude/` excluded)
- `.github/dependabot.yaml` — monthly updates for Actions and uv (npm once the frontend exists), grouped into dev-tooling and runtime (minor/patch batched, majors one PR each); **gitignored by default**, remove its line from `.gitignore` to enable it
- No Docker files: images are specific to each project, so they aren't templated

**AI-native development (Claude Code)**
- `AGENTS.md` — how to work in the project: a short *Where to look* section (`CONTEXT.md`, `docs/ADRs/`, the README, `pyproject.toml`), the few commands that matter (`just --list` has the rest), the guidelines, and a short *Development workflow* section mapping how the skills, subagents, and hooks compose end to end. Any agent tool can read it
- `CLAUDE.md` — imports `AGENTS.md` (`@AGENTS.md`) so Claude Code loads the same brief, since it reads `CLAUDE.md` and not `AGENTS.md`, plus an empty *Claude Code specifics* section for instructions that only apply to Claude Code
- `.claude/settings.json` — registers the two `PreToolUse` guard hooks and the `PostToolUse` formatter, plus the marketplace and a per-project on/off list (`enabledPlugins`: the `dev`, `learning` and `presenting` groups on, the rest off) for the general-purpose skills
- `.claude/hooks/` — `test_gate.py` (no `git commit` until `just test` passes, no override), `destructive_guard.py` (blocks `rm -rf` on dangerous paths, `git reset --hard`, force-pushes to `main`, etc.) and `format_python.py` (runs the project's own `ruff format` on every Python file the agent writes; plain Python, no `jq` needed)
- `.claude/agents/` — 5 subagents: `code-reviewer`, `changelog-writer`, `docs-updater`, `debugger`, `security-auditor`
- `.claude/skills/` — 17 skills, A to Z (`claude-handoff`, `commit`, `diagnosing-bugs`, `domain-modeling`, `doubt`, `frontend-design`, `grill-with-docs`, `grilling`, `handcraft`, `handoff`, `implement`, `security-audit`, `spec`, `tdd`, `update-docs`, `wait-what`, `walkthrough`). General-purpose skills are not copied: they come from the `my-marketplaced-skills` marketplace as groups (`dev`, `learning`, `niche`, `presenting`, `utilities`, `Z-JustInCase`) enabled per project
- `docs/specs/` and `docs/ADRs/` conventions, and a project glossary (`CONTEXT.md`, shipped as a skeleton) maintained by the skills
- `.github/PULL_REQUEST_TEMPLATE.md` — one structure (Why, What changes, For review, Deploy impact, Verification, Known gaps, After merging) written for people and agents alike
- `.github/ISSUE_TEMPLATE/` — bug report, feature request and task templates in the same style: an instruction header, "delete what doesn't apply", `[x]` only for what actually ran, and a *Done when* checklist

**Other**
- `.gitignore` (lockfiles are committed; ignores `.DS_Store`/`Thumbs.db` among the usual suspects)
- `CHANGELOG.md` in Keep a Changelog format
- `.env.example`

See [python-template-guide.md](docs%20%26%20references/python-template-guide.md) for a file-by-file explanation of everything in the template, including the full AI workflow.

---

## The AI-native workflow in one paragraph

For anything bigger than a one-line fix: `/grill-with-docs` to clarify a loose idea (writing terms to `CONTEXT.md` and hard decisions to `docs/ADRs/`) → `/spec` to write `docs/specs/<type>_<name>/SPEC.md` + a seam-organized `PLAN.md` and cut a branch → `implement` runs automatically after, doing `tdd` at each seam and a final `code-reviewer` pass against the spec, writing `REPORT.md` in the spec folder → `/update-docs <file>` brings the README or CHANGELOG up to date (`docs-updater` or `changelog-writer`) → `/commit` makes atomic commits and never pushes → you push and open the PR. `/security-audit` is an extra pass before a release. Bugs take a separate track through `diagnosing-bugs` → the `debugger` subagent (Opus, skeptical mindset). Two hooks run underneath all of it: no commit without green tests, and no destructive shell commands. Full rosters live in the generated project's `.claude/skills/README.md` and `.claude/agents/README.md`.

---

## Testing the template

Changing a template is easy to get subtly wrong: a file that renders in one layout and breaks another, a hook that rewrites the generated files on the first commit. `check-template.sh` renders every combination (`simple` and `product`, each with and without `use_ml`) into a temporary folder and checks the result, in parallel:

```bash
bash check-template.sh                 # all four combinations
bash check-template.sh product:true    # just one (<layout>:<use_ml>)
```

For each generated project it checks that the expected files exist and the branch is `main`; that Dependabot's config is gitignored; that the shared `.vscode/` files are valid, tracked, and point at a real interpreter; that lint, format, type-check and tests pass; that a fresh checkout (what CI sees) passes markdownlint and the relative-link check; that `pre-commit run --all-files` passes and leaves the tree clean; that `copier update` merges a later template change and leaves the project's pins, lockfile and hooks alone; that `just dev` refuses to start until configured and stops its servers on Ctrl+C (`product`); and that `dvc repro` runs (`use_ml`). It needs `uv`, `git`, Node.js and network access, and prints a per-project report with the log tail of anything that failed.

`.github/workflows/test-template.yml` runs the same script on every push and pull request to this repo. Run it locally after any change under `template/` or to `copier.yml`.

---

## Template structure

Paths with `{{ }}` or `{% if %}` in their names are rendered by Copier: an empty result skips the file or folder, and `py_root` (`backend/` or empty) places the Python project.

```text
python-template/
├── copier.yml                          ← questions, derived variables, setup tasks
├── bootstrap-machine.sh                ← once per machine: uv, copier, just, graphify, rtk (not copied)
├── check-template.sh                   ← self-test: renders every layout and checks it (not copied)
├── .gitignore                          ← template repo's own (.DS_Store, Thumbs.db)
├── README.md                           ← this file (not copied)
├── docs & references/                  ← guides about the template (not copied)
├── .github/workflows/test-template.yml ← runs check-template.sh in CI (not copied)
└── template/                           ← copied into generated projects
    ├── {{ py_root }}{{ package_name }}/            ← backend/app/ or <project_name>/
    │   ├── __init__.py.jinja
    │   ├── constants.py.jinja
    │   ├── {% if use_ml %}pipeline{% endif %}/   ← prepare, train, evaluate stubs
    │   └── utils/
    │       ├── __init__.py.jinja
    │       └── logger.py.jinja
    ├── {{ py_root }}tests/                         ← backend/tests/ or tests/
    ├── {{ py_root }}pyproject.toml.jinja           ← backend/pyproject.toml or root
    ├── {% if project_layout == 'product' %}infra{% endif %}/tests/
    ├── {% if use_ml %}data|notebooks|results|runs{% endif %}/   ← data/raw/.gitkeep, runs/mlruns, runs/artifacts
    ├── {% if use_ml %}dvc.yaml{% endif %}.jinja
    ├── {% if use_ml %}.dvcignore{% endif %}
    ├── config/
    │   └── config.yaml.jinja
    ├── {% if project_layout == 'product' %}frontend{% endif %}/
    │   └── decide-frontend-style.md
    ├── logs/
    ├── docs/                           ← specs/, adr/, build/ created on demand
    ├── scripts/
    │   ├── setup.sh.jinja             ← project bootstrap (checks tools, installs deps and hooks)
    │   ├── resolve-latest.sh.jinja    ← Python version pin and latest, exactly pinned dependencies (run by Copier)
    │   └── {% if project_layout == 'product' %}dev.sh{% endif %}   ← `just dev` skeleton
    ├── .github/
    │   ├── workflows/
    │   │   ├── ci.yml
    │   │   ├── markdown.yml
    │   │   └── markdownlint-config.json
    │   ├── dependabot.yaml.jinja       ← gitignored in generated projects by default
    │   ├── ISSUE_TEMPLATE/
    │   └── PULL_REQUEST_TEMPLATE.md
    ├── .claude/                        ← settings, hooks, agents, skills
    ├── justfile.jinja
    ├── AGENTS.md.jinja                 ← how to work in the project, for any agent
    ├── CLAUDE.md                       ← imports AGENTS.md; Claude Code specifics
    ├── CONTEXT.md.jinja                ← domain glossary skeleton, filled in by the skills
    ├── README.md.jinja
    ├── CHANGELOG.md
    ├── .gitattributes
    ├── .vscode/
    │   ├── settings.json.jinja         ← interpreter path, Ruff on save, pytest
    │   ├── extensions.json
    │   └── tasks.json.jinja            ← just recipes as VS Code tasks
    ├── {{ _copier_conf.answers_file }}.jinja ← .copier-answers.yml, what makes `copier update` work
    ├── .gitignore.jinja
    ├── .pre-commit-config.yaml.jinja
    └── .env.example
```

`frontend/` holds only the decision guide: nothing is scaffolded until you choose a stack.
