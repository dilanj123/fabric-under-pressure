#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
source /Users/Dilan/eda/fabric-under-pressure/oss-cad-suite/environment
OUT="$ROOT/results/raw/architecture_b_scheduler"
mkdir -p "$OUT"
(
  cd formal
  sby -f -d "$OUT/formal_prove" axi_qos_aging_arbiter_3.sby prove
  sby -f -d "$OUT/formal_cover" axi_qos_aging_arbiter_3.sby cover
) >"$OUT/formal.log" 2>&1
grep -q '^PASS 0 1$' "$OUT/formal_prove/status"
grep -q '^PASS 0 5$' "$OUT/formal_cover/status"
echo "PASS Architecture-B scheduler formal prove + cover"
