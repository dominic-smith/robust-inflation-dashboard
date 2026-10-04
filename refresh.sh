#!/usr/bin/env bash
# Monthly refresh: download the latest BEA vintage, recompute the measures, validate,
# rebuild the site and test it. Then review the printed numbers and push.
#
#   ./refresh.sh
#
# Fully self-contained: reads nothing from the paper/R&R repo.
set -euo pipefail
cd "$(dirname "$0")"

echo "== 1/6  download latest BEA underlying PCE detail =="
( cd compute/code && Rscript download_bea.R )

echo "== 2/6  compute measures and the best-trims band =="
( cd compute/code && Rscript run_compute.R )

echo "== 3/6  export artifacts (CSV) =="
( cd compute/code && Rscript export_artifacts.R )

echo "== 4/6  validate (FRED match, BEA line alignment, Dallas gap) =="
( cd compute/code && Rscript validate_refresh.R )

echo "== 5/6  build the site =="
./build.sh

echo "== 6/6  test the built site in a browser =="
( cd site && npm test )

echo
echo "Done. Review the numbers above, then publish:"
echo "  git add -A && git commit -m \"Update: \$(date +%Y-%m)\" && git push"
