#!/usr/bin/env bash
# Build the static site into docs/: the folder GitHub Pages serves, and the folder a
# Cloudflare Pages project would deploy (build output directory: docs).
#
#   ./build.sh
#
# Reads artifacts/ (written and validated by compute/). Does not recompute anything.
set -euo pipefail
cd "$(dirname "$0")"

# Framework's build log is long; keep it in site/build.log and show it only on failure
if ! ( cd site && npm run build --silent > build.log 2>&1 ); then tail -40 site/build.log; exit 1; fi
grep -E "^[┌├└]" site/build.log || true
rm -rf docs
cp -R site/dist docs
touch docs/.nojekyll   # GitHub Pages: serve the underscore-prefixed asset folders as-is
echo "Built docs/: $(du -sh docs | cut -f1), $(find docs -type f | wc -l | tr -d ' ') files"
