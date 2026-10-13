#!/usr/bin/env bash
# check-template.sh — render every layout and check that the generated project works
#
# Run it after changing anything under template/ or copier.yml, and in CI (see
# .github/workflows/test-template.yml). Like bootstrap-machine.sh it lives outside template/,
# so it is never copied into generated projects.
#
# Usage:
#   bash check-template.sh                    # all four combinations
#   bash check-template.sh product:true       # one or more <layout>:<use_ml> combinations
#
# Needs: uv, git, Node.js (for markdownlint) and network access. The combinations run in parallel.
#
# For each generated project it checks that:
#   - the expected files exist and the branch is `main`
#   - Dependabot's config is gitignored
#   - lint, format, type-check and tests pass (and the frontend targets skip cleanly)
#   - a fresh checkout passes markdownlint and the relative-link check, as CI will see it
#   - `pre-commit run --all-files` passes and leaves the tree clean
#   - `copier update` merges a later template change and leaves the project's own files alone
#   - product: `make dev` refuses to start until configured, and stops everything on Ctrl+C
#   - use_ml: `dvc repro` runs the placeholder pipeline

set -uo pipefail

TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

command -v uv  >/dev/null || { echo "uv not found" >&2; exit 1; }
command -v git >/dev/null || { echo "git not found" >&2; exit 1; }
command -v npx >/dev/null || { echo "Node.js (npx) not found" >&2; exit 1; }

export GIT_AUTHOR_NAME=check GIT_AUTHOR_EMAIL=check@example.com
export GIT_COMMITTER_NAME=check GIT_COMMITTER_EMAIL=check@example.com

check_combo() {
  local layout=$1 ml=$2
  local name="${layout}_ml-${ml}"
  local dir="$WORK/$name" log="$WORK/$name.log" res="$WORK/$name.result"
  local py="." failed=0
  [ "$layout" = product ] && py="backend"
  : > "$log"; : > "$res"

  step() {
    local label=$1; shift
    if "$@" >>"$log" 2>&1; then echo "  ok    $label" >>"$res"; else echo "  FAIL  $label" >>"$res"; failed=1; fi
  }
  in_project() { (cd "$dir" && "$@"); }
  expect_files() { (cd "$dir" && for f in "$@"; do [ -e "$f" ] || { echo "missing: $f"; exit 1; }; done); }
  dev_stops_servers() {
    # The pattern is built at runtime so pgrep can't match this function's own command line, and the
    # duration is unique per combination so parallel runs don't see each other's servers.
    local word=sleep pid seconds
    seconds=$((1000 + $(printf %s "$name" | cksum | cut -d' ' -f1) % 9000))
    (cd "$dir" && sed "s|^BACKEND_CMD=\"\"|BACKEND_CMD=\"$word $seconds\"|" scripts/dev.sh > scripts/dev-test.sh)
    bash "$dir/scripts/dev-test.sh" & pid=$!
    sleep 2; kill -TERM "$pid"; sleep 2
    rm -f "$dir/scripts/dev-test.sh"
    ! pgrep -f "$word $seconds" >/dev/null
  }
  update_merges_a_change() {
    printf '\n## Added later\n\nA section added in a later template version.\n' >> "$tpl/template/README.md.jinja"
    git -C "$tpl" commit -qam later && git -C "$tpl" tag v0.2.0
    (cd "$dir" && uvx copier update --defaults --trust) || return 1
    grep -q "Added later" "$dir/README.md" || { echo "the template change was not merged"; return 1; }
    # Only the README and the answers file may change: the pins, lockfile and hooks must survive.
    local others
    others=$(git -C "$dir" status --porcelain | grep -vE ' (README\.md|\.copier-answers\.yml)$' || true)
    [ -z "$others" ] || { echo "update touched other files:"; echo "$others"; return 1; }
  }
  clean_tree() { [ -z "$(git -C "$dir" status --porcelain)" ] || { git -C "$dir" status --short; return 1; }; }

  # Render from a committed, tagged copy of the template, so the update check at the end does not depend
  # on the state of your working tree (Copier records the template's commit).
  local tpl="$WORK/$name-template"
  mkdir -p "$tpl" && cp -R "$TEMPLATE_DIR/." "$tpl/" && rm -rf "$tpl/.git"
  git -C "$tpl" init -q -b main && git -C "$tpl" add -A && git -C "$tpl" commit -qm template && git -C "$tpl" tag v0.1.0

  step "render" uvx copier copy --defaults --trust --data project_name=demo_proj \
    --data project_layout="$layout" --data use_ml="$ml" "$tpl" "$dir"
  [ -d "$dir" ] || { echo "  (stopped: nothing was rendered)" >>"$res"; return 1; }

  step "files exist" expect_files AGENTS.md CLAUDE.md .copier-answers.yml .gitattributes \
    "$py/pyproject.toml" "$py/uv.lock" "$py/.python-version"
  step "branch is main" test "$(git -C "$dir" branch --show-current)" = main
  step "dependabot config is gitignored" git -C "$dir" check-ignore -q .github/dependabot.yaml

  step "lint, format, types, tests" in_project make lint-py format-check typecheck test-py

  if [ "$layout" = product ]; then
    step "frontend targets skip cleanly" in_project make lint-frontend test-frontend
    step "scripts/dev.sh exists" expect_files scripts/dev.sh
    step "make dev refuses to start unconfigured" bash -c "! (cd '$dir' && make dev)"
    step "dev.sh stops its servers when interrupted" dev_stops_servers
  fi

  if [ "$ml" = true ]; then
    step "dvc repro runs the pipeline" in_project bash -c "uv run --project $py dvc init -q && make dvc-repro"
  fi

  git -C "$dir" add -A >>"$log" 2>&1
  git -C "$dir" commit -qm "generated" >>"$log" 2>&1

  # What CI sees: a fresh checkout, without .venv or caches.
  local fresh="$WORK/$name-fresh"
  mkdir -p "$fresh"; git -C "$dir" archive HEAD | tar -x -C "$fresh"
  step "markdownlint on a fresh checkout" bash -c "cd '$fresh' && npx --yes markdownlint-cli2 \
    --config .github/workflows/markdownlint-config.json '**/*.md' '#.claude' '#node_modules'"
  step "relative links on a fresh checkout" bash -c "cd '$fresh' && git init -q && git add -A \
    && git ls-files -z '*.md' ':!:.claude' | xargs -0 uvx --from markdown-checker==1.2.2 markdown-checker \
    --isolated --func check_broken_paths --report-format console"

  step "pre-commit passes on every file" in_project uv run --project "$py" pre-commit run --all-files
  step "pre-commit leaves the tree clean" clean_tree
  step "copier update merges a template change and keeps the project's files" update_merges_a_change

  return $failed
}

combos=("$@")
[ ${#combos[@]} -gt 0 ] || combos=(simple:false simple:true product:false product:true)

pids=()
for c in "${combos[@]}"; do
  ( check_combo "${c%%:*}" "${c##*:}" ) &
  pids+=($!)
done

overall=0
for i in "${!pids[@]}"; do
  wait "${pids[$i]}" || overall=1
done

for c in "${combos[@]}"; do
  name="${c%%:*}_ml-${c##*:}"
  echo "== ${c%%:*} (use_ml: ${c##*:})"
  cat "$WORK/$name.result"
  if grep -q FAIL "$WORK/$name.result"; then
    echo "  --- log tail ---"; tail -25 "$WORK/$name.log" | sed 's/^/  | /'
  fi
done

[ $overall -eq 0 ] && echo "All checks passed." || echo "Some checks failed."
exit $overall
