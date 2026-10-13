#!/usr/bin/env bash
# bootstrap-machine.sh — install the tools every project made from this template relies on
#
# Run it once per machine, not once per project. It lives in the template repo (outside
# template/), so it is never copied into generated projects: generated projects only check
# that these tools exist.
#
# Usage:
#   bash bootstrap-machine.sh
#
# Safe to re-run: anything already installed is skipped, and optional tools only warn on failure.
#
#   Required:  uv, copier
#   Optional:  graphify (codebase knowledge graph for AI assistants), rtk (compresses command
#              output before it reaches an agent's context window)
#   Checked, not installed: git, make, Node.js (install them with your system's package manager)

set -euo pipefail

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
RESET="\033[0m"

info()  { echo -e "${GREEN}[machine]${RESET} $*"; }
warn()  { echo -e "${YELLOW}[machine]${RESET} $*"; }
error() { echo -e "${RED}[machine]${RESET} $*" >&2; exit 1; }

# ── Checked, not installed ─────────────────────────────────────────────────────
command -v git  &> /dev/null || error "git not found. Install it: https://git-scm.com/downloads"
command -v make &> /dev/null || warn "make not found -- install your system's build tools (Xcode CLT on macOS, build-essential on Linux)."
command -v node &> /dev/null || warn "Node.js not found -- only needed for projects with a frontend: https://nodejs.org/"

# ── Required ───────────────────────────────────────────────────────────────────
if ! command -v uv &> /dev/null; then
  info "Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
fi
info "uv $(uv --version)"

if ! command -v copier &> /dev/null; then
  info "Installing copier..."
  uv tool install copier
else
  info "copier already installed -- skipping."
fi

# ── Optional ───────────────────────────────────────────────────────────────────
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

info "Machine ready. Generate a project with:"
echo ""
echo "    copier copy --trust <path-or-url-of-this-template> ./my-new-project"
echo ""
