#!/usr/bin/env bash
# sync-framework.sh — pull FRAMEWORK updates DOWN into a consumer repo. One-way:
# a consumer (a domain test like xm-probius, or any real project's spine) only
# ever FETCHES the agnostic framework and re-bases its local domain test on top.
# This is the mirror of scripts/sync-upstream.sh: that pulls the godot *source*
# UP into the framework; this pulls the *framework* DOWN into a consumer.
# See docs/whitelabel/DOWNSTREAM.md for the topology + the why.
#
#   The framework (`arthur0n/xenomoon`) is updated all the time. Consumers re-run
#   this to ride those updates while keeping their own domain config + project
#   pointer. The framework spine stays AGNOSTIC — godot never lands, and no
#   consumer's project specifics get baked back into it.
#
# Conflict policy (the framework is the source of truth for the spine):
#   - identity / UI / spine / domain-pack hunks  -> take THEIRS (the framework).
#     A consumer must not fork the agnostic pack; project facts live in the
#     project's OWN CLAUDE.md, not in domains/<name>/.
#   - genuine local FRAMEWORK bug-fixes you intend to upstream -> keep, then file
#     them back to the framework so the next sync is conflict-free.
#   - NEVER reintroduce game/godot identity (game-designer, blockout, the engine
#     payload) — the leakage gate below fails the sync if any slips in.
#
# Flags:
#   --from <remote>     framework remote to fetch (default: upstream)
#   --branch <branch>   framework branch (default: main)
#   --project <name>    also fail the gate if this project name is hardcoded into
#                       the framework spine (e.g. --project lexflow)
#   --no-validate       skip `npm run validate` (faster, less safe)
set -euo pipefail
cd "$(dirname "$0")/.."

REMOTE=upstream
BRANCH=main
PROJECT=""
RUN_VALIDATE=1
while [ $# -gt 0 ]; do
  case "$1" in
    --from) REMOTE="$2"; shift 2 ;;
    --branch) BRANCH="$2"; shift 2 ;;
    --project) PROJECT="$2"; shift 2 ;;
    --no-validate) RUN_VALIDATE=0; shift ;;
    *) echo "unknown flag: $1" >&2; exit 2 ;;
  esac
done

REF="$REMOTE/$BRANCH"

if ! git remote get-url "$REMOTE" >/dev/null 2>&1; then
  echo "no remote '$REMOTE'. Add the framework remote, e.g.:" >&2
  echo "  git remote add $REMOTE https://github.com/arthur0n/xenomoon.git" >&2
  exit 2
fi
if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
  echo "working tree has uncommitted changes — commit or stash first." >&2
  exit 2
fi

echo "==> fetching framework ($REF; read-only, we never push to it)"
git fetch "$REMOTE" "$BRANCH"

BEHIND=$(git rev-list --count "HEAD..$REF")
if [ "$BEHIND" = 0 ]; then
  echo "already up to date with $REF — nothing to sync."
  exit 0
fi
echo "==> $BEHIND framework commit(s) to pull:"
git log --oneline --reverse "HEAD..$REF"

SYNC_BRANCH="sync-framework-$BRANCH"
echo "==> syncing on branch '$SYNC_BRANCH' (your trunk is left untouched until you merge it)"
git switch -C "$SYNC_BRANCH"

echo "==> merging $REF (take THEIRS on spine/identity/domain-pack conflicts)"
if ! git merge --no-ff "$REF"; then
  echo
  echo "Conflicts — resolve to the framework's version, then finish:"
  echo "  - spine (ui/server, ui/client, ui/lib), identity (ui/index.html,"
  echo "    ui/agent-ui.css, assets), and domains/<name>/ -> keep THEIRS:"
  echo "       git checkout --theirs -- <file> && git add <file>"
  echo "  - keep ONLY a genuine local framework bug-fix (then upstream it)."
  echo "  - git commit          # complete the merge, then re-run this script's gate:"
  echo "       bash scripts/sync-framework.sh --from $REMOTE --branch $BRANCH ${PROJECT:+--project $PROJECT} --no-validate"
  exit 1
fi

echo "==> leakage gate (the framework spine must stay agnostic)"
SPINE="ui domains plugin"
# Unambiguous regressions only: the engine payload, and the actual game role-MAP
# keys (`"game-designer":`). Cosmetic example strings (a doc-comment arrow, a
# "blockout levels" placeholder) ship in the framework itself and are the
# maintainer's to scrub — they must not block a consumer sync.
# (`res://` is NOT gated: the framework's own asset-mount plumbing still uses it,
# so it ships in baseline and is not a consumer regression.)
GAME='\.tscn|\.gd\b|\.import\b|[Gg]odot engine|"(game|level)-designer"[[:space:]]*:'
LEAK=0
if git grep -nIE "$GAME" -- $SPINE >/dev/null 2>&1; then
  echo "  FAIL: game/godot identity leaked into the spine:" >&2
  git grep -nIE "$GAME" -- $SPINE >&2 || true
  LEAK=1
fi
if [ -n "$PROJECT" ] && git grep -nIE "$PROJECT" -- domains plugin ui/server >/dev/null 2>&1; then
  echo "  FAIL: project '$PROJECT' is hardcoded into the framework — it belongs in the project's own CLAUDE.md:" >&2
  git grep -nIE "$PROJECT" -- domains plugin ui/server >&2 || true
  LEAK=1
fi
[ "$LEAK" = 0 ] && echo "  ok — spine is agnostic, no game/godot, no project hardcoding."

if [ "$RUN_VALIDATE" = 1 ]; then
  echo "==> validate"
  npm install --silent
  npm run validate
fi

echo
if [ "$LEAK" != 0 ]; then
  echo "Merged, but the leakage gate FAILED above — scrub the spine before merging '$SYNC_BRANCH'."
  exit 1
fi
echo "Done. Framework $REF merged onto '$SYNC_BRANCH', spine agnostic, validate green."
echo "Review, then fold into your trunk:"
echo "    git switch main && git merge --ff-only $SYNC_BRANCH   # or open a PR"
echo "(No push happens here — publish on your own.)"
