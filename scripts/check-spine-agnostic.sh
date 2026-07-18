#!/usr/bin/env bash
# check-spine-agnostic.sh — the ONE deterministic check behind /sync-framework.
# It answers a yes/no question with no judgment: did game/godot identity or a
# named project's specifics leak into the framework spine? Everything that needs
# *analysis* (which conflict takes theirs, is this agnostic or project-specific,
# is a finding worth keeping) lives in the /sync-framework command, not here.
#
# Detection is by-construction precise so it never trips on docs that merely
# *discuss* these patterns (this script, the command, the whitelabel runbooks):
#   - godot engine payload  -> file PRESENCE by extension (not a content grep)
#   - game identity         -> the role-MAP keys, in *.js only (where the map lives)
#   - project hardcoding     -> the project's name in the spine, minus this command's own doc
#
# Exit 0 = clean. Exit 1 = leak (printed). Exit 2 = usage error.
#
#   --project <name>   also fail if this project's name is hardcoded into the spine
set -euo pipefail
cd "$(dirname "$0")/.."

PROJECT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --project) PROJECT="${2:-}"; shift 2 ;;
    *) echo "usage: check-spine-agnostic.sh [--project <name>]" >&2; exit 2 ;;
  esac
done

leak=0

# 1. Godot engine payload — any engine file in the tree is a hard leak.
engine=$(git ls-files -- '*.tscn' '*.gd' '*.import' '*.godot' || true)
if [ -n "$engine" ]; then
  echo "FAIL: godot engine files present —" >&2
  echo "$engine" >&2
  leak=1
fi

# 2. Game identity — the role-MAP keys live in JS (e.g. ui/client/.../agents.js).
KEYS='"(game|level)-designer"[[:space:]]*:'
if git grep -nIE "$KEYS" -- '*.js' >/dev/null 2>&1; then
  echo "FAIL: game role-map keys in the spine —" >&2
  git grep -nIE "$KEYS" -- '*.js' >&2 || true
  leak=1
fi

# 3. Project hardcoding — the bound project's name baked into the framework. Skip this
#    command's own doc, which legitimately names a project as an example.
if [ -n "$PROJECT" ] &&
   git grep -nIE "$PROJECT" -- domains plugin ui/server ':!plugin/commands/sync-framework.md' >/dev/null 2>&1; then
  echo "FAIL: project '$PROJECT' hardcoded into the framework (it belongs in the project's own CLAUDE.md) —" >&2
  git grep -nIE "$PROJECT" -- domains plugin ui/server ':!plugin/commands/sync-framework.md' >&2 || true
  leak=1
fi

if [ "$leak" = 0 ]; then
  echo "ok — spine agnostic: no godot engine files, no game role-map keys, no project hardcoding${PROJECT:+ (checked '$PROJECT')}."
fi
exit "$leak"
