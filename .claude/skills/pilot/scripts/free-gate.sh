#!/usr/bin/env bash
# free-gate: mechanical checks that must pass before any model-token review is spent.
# Adapt the STACK section per project during Phase 2. Exit non-zero on first failure
# with the failing output on stdout/stderr so it can be fed back to Codex verbatim.
set -uo pipefail

fail() { echo "FREE-GATE FAIL [$1]"; exit 1; }

# --- 1. Diff boundary check ------------------------------------------------
# Usage: free-gate.sh <base-branch> <spec-file>
# The spec's "File boundary" section lists allowed globs, one per line, as "- glob".
BASE="${1:-main}"
SPEC="${2:-}"

if [[ -n "$SPEC" && -f "$SPEC" ]]; then
  boundary=$(awk '/^## File boundary/{flag=1;next}/^## /{flag=0}flag && /^- /{sub(/^- /,"");print}' "$SPEC")
  if [[ -n "$boundary" ]]; then
    changed=$(git diff --name-only "$BASE"...HEAD)
    while IFS= read -r f; do
      [[ -z "$f" ]] && continue
      ok=false
      while IFS= read -r g; do
        [[ -z "$g" ]] && continue
        # shellcheck disable=SC2053
        [[ "$f" == $g ]] && ok=true && break
      done <<< "$boundary"
      # Docs, specs, reviews, and lessons are always allowed.
      [[ "$f" == docs/* ]] && ok=true
      $ok || { echo "out-of-boundary change: $f"; fail "boundary"; }
    done <<< "$changed"
  fi
fi

# --- 2. Token lint -----------------------------------------------------------
if [[ -f design-tokens.json ]]; then
  mapfile -t changed_src < <(git diff --name-only "$BASE"...HEAD)
  node scripts/token-lint.mjs "${changed_src[@]}" || fail "token-lint"
fi

# --- 3. STACK: build / test / lint  (ADAPT IN PHASE 2) ----------------------
# Examples — uncomment/replace for the project's stack:
#   npm run build || fail "build"
#   npm test -- --watch=false || fail "test"
#   npx eslint . || fail "lint"
#   xcodebuild -scheme App -destination 'platform=iOS Simulator,name=iPhone 16' build || fail "build"
#   swift test || fail "test"
if [[ -f package.json ]]; then
  if node -e "const s=require('./package.json').scripts||{};process.exit(s.build?0:1)"; then
    npm run build || fail "build"
  fi
  if node -e "const s=require('./package.json').scripts||{};process.exit(s.test?0:1)"; then
    npm test || fail "test"
  fi
fi

echo "FREE-GATE OK"
