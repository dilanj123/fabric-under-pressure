#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/results/raw/gate0/formal"
mkdir -p "$OUT"
command -v sby >/dev/null || { echo "ERROR: sby missing" | tee "$OUT/run.log"; exit 2; }
(
  cd "$ROOT/formal"
  rm -rf smoke_prove smoke_cover smoke_fail
  sby -f -d smoke_prove smoke.sby prove
  sby -f -d smoke_cover smoke.sby cover
  set +e
  sby -f -d smoke_fail smoke.sby fail
  rc=$?
  set -e
  if [ "$rc" -eq 0 ]; then
    echo "ERROR: intentional fail unexpectedly passed"
    exit 4
  fi
  echo "Expected-failure harness detected failure (rc=$rc)"
) 2>&1 | tee "$OUT/run.log"
