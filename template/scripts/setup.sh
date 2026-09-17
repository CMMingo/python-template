#!/usr/bin/env bash
# setup.sh — bootstrap a fresh clone of {{ project_name }}
#
# Usage:
#   bash scripts/setup.sh
#
# What it does:
#   1. Checks for / installs uv
#   2. Creates the virtual environment and installs all dependencies
#   3. Installs pre-commit hooks
#   4. Initialises DVC (if not already initialised)
#   5. Copies .env.example → .env (if .env doesn't exist)
#   6. Best-effort installs graphify and rtk (warns and continues on failure -- optional tools)

set -euo pipefail

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
RESET="\033[0m"

info()    { echo -e "${GREEN}[setup]${RESET} $*"; }
warn()    { echo -e "${YELLOW}[setup]${RESET} $*"; }
error()   { echo -e "${RED}[setup]${RESET} $*" >&2; exit 1; }

# ── 1. uv ──────────────────────────────────────────────────────────────────────
if ! command -v uv &> /dev/null; then
  warn "uv not found — installing..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
fi
info "uv $(uv --version)"

# ── 2. Dependencies ────────────────────────────────────────────────────────────
info "Installing dependencies..."
uv sync --all-extras

# ── 3. Pre-commit ──────────────────────────────────────────────────────────────
info "Installing pre-commit hooks..."
uv run pre-commit install

# ── 4. DVC ─────────────────────────────────────────────────────────────────────
if [ ! -d ".dvc" ]; then
  info "Initialising DVC..."
  uv run dvc init
else
  info "DVC already initialised — skipping."
fi

# ── 5. .env ────────────────────────────────────────────────────────────────────
if [ ! -f ".env" ]; then
  cp .env.example .env
  warn ".env created from .env.example — fill in your values."
else
  info ".env already exists — skipping."
fi

# ── 6. Optional tooling (graphify, rtk) ────────────────────────────────────────
# Best-effort: these are convenience tools, not real dependencies. Warn and
# continue on failure rather than blocking the rest of setup.

if ! command -v graphify &> /dev/null; then
  info "Installing graphify..."
  (uv tool install graphifyy && graphify install) || warn "graphify install failed -- install manually later: https://github.com/Graphify-Labs/graphify"
else
  info "graphify already installed -- skipping."
fi

if ! command -v rtk &> /dev/null; then
  info "Installing rtk..."
  case "$(uname -s)" in
    Darwin*)
      if command -v brew &> /dev/null; then
        brew install rtk || warn "rtk install via brew failed -- install manually: https://github.com/rtk-ai/rtk"
      else
        curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh || warn "rtk install failed -- install manually: https://github.com/rtk-ai/rtk"
      fi
      ;;
    Linux*)
      curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh || warn "rtk install failed -- install manually: https://github.com/rtk-ai/rtk"
      ;;
    MINGW*|MSYS*|CYGWIN*)
      if command -v winget &> /dev/null; then
        winget install rtk-ai.rtk || warn "rtk install via winget failed -- install manually: https://github.com/rtk-ai/rtk"
      else
        warn "winget not found -- install rtk manually: https://github.com/rtk-ai/rtk"
      fi
      ;;
    *)
      warn "Unrecognized OS ($(uname -s)) -- skipping rtk auto-install. See https://github.com/rtk-ai/rtk"
      ;;
  esac
else
  info "rtk already installed -- skipping."
fi

info "Setup complete. Activate your environment with:"
echo ""
echo "    source .venv/bin/activate"
echo ""
