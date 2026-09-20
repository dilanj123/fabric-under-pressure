#!/usr/bin/env bash
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
rc=0
for s in check_env.sh run_smoke_sv.sh run_smoke_sim.sh run_smoke_bfm.sh run_smoke_formal.sh run_smoke_synth.sh run_smoke_pnr.sh run_smoke_wrapper.sh; do
  echo "===== $s ====="
  "$ROOT/scripts/$s" || rc=1
done
exit "$rc"
