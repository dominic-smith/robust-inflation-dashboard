#!/usr/bin/env bash
# Monthly refresh: download the latest BEA vintage, recompute all four measures,
# export the app artifacts, and rebuild the static site. Then commit + push.
#
#   ./refresh.sh
#
# Fully self-contained: reads nothing from the paper/R&R repo.
set -euo pipefail
cd "$(dirname "$0")"

echo "== 1/4  download latest BEA underlying PCE detail =="
( cd compute/code && Rscript download_bea.R )

echo "== 2/4  compute measures (01m -> 22m) =="
( cd compute/code && Rscript run_compute.R )

echo "== 3/4  export app artifacts =="
( cd compute/code && Rscript export_artifacts.R )

echo "== 4/4  rebuild shinylive static site =="
Rscript build.R

echo
echo "Done. Review, then publish:"
echo "  git add -A && git commit -m \"Update: \$(date +%Y-%m)\" && git push"
