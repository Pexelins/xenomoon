#!/usr/bin/env bash
# sync-upstream.sh — pull upstream into our fork the disciplined way.
# See docs/whitelabel/SYNC.md for the full rationale.
#
#   main  = pristine mirror of upstream/main (never hand-edited)
#   forge = our integration trunk; upstream is MERGED in (NOT rebased), and the
#           xenomoon rebrand is COMMITTED on forge — so a sync = merge + re-run the codemod.
#
# Flags:
#   --push     also push the fast-forwarded main to origin
#   --no-test  skip `npm run test:onboarding` (faster, less safe)
set -euo pipefail
cd "$(dirname "$0")/.."

PUSH=0
RUN_TEST=1
for arg in "$@"; do
  case "$arg" in
    --push) PUSH=1 ;;
    --no-test) RUN_TEST=0 ;;
    *) echo "unknown flag: $arg" >&2; exit 2 ;;
  esac
done

echo "==> fetching upstream"
git fetch upstream

echo "==> fast-forwarding main to upstream/main"
git checkout main
git merge --ff-only upstream/main
[ "$PUSH" = 1 ] && { echo "==> pushing main to origin"; git push origin main; }

echo "==> merging main into forge (rebrand is committed on forge; expect conflicts on rebranded lines)"
git checkout forge
if ! git merge --no-ff main; then
  echo
  echo "Merge conflicts — resolve them, then finish the sync by hand:"
  echo "  - keep README ours; keep the DOMAIN seam in ui/server/core/config.js"
  echo "  - re-drop the intentional divergences (godot-docs, FEATURES.md) per docs/whitelabel/SEAMS.md"
  echo "  - git add -u && git commit            # complete the merge"
  echo "  - node scripts/rebrand.mjs && git commit -am 'rebrand: re-flip merged upstream'"
  echo "  - node scripts/rebrand.mjs --check && npm run validate && npm run test:onboarding"
  exit 1
fi

if [ "$RUN_TEST" = 1 ]; then
  echo "==> onboarding gate"
  npm install --silent
  npm run test:onboarding
fi

echo
echo "Done. main merged into forge cleanly. Re-brand the merged-in upstream strings:"
echo "    node scripts/rebrand.mjs && git commit -am 'rebrand: re-flip merged upstream'"
echo "    node scripts/rebrand.mjs --check   # only arthur0n + docs/whitelabel + scripts keep 'xenodot'"
