#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Gate-3 Stage-B qualification: same frozen seeds and v2 functional endpoint,
# with a predeclared 2,048-operation body.  This is functional stress evidence,
# not performance measurement.  v2's manager lifecycle remains historical
# context; Gate-2 directed tests are the authoritative four-outstanding DUT
# evidence until a stronger concurrent random driver is justified.
export GATE3_OUT_DIR="${GATE3_OUT_DIR:-$ROOT/results/raw/gate3_random_long}"
export GATE3_OPERATIONS=2048
export GATE3_EXPECTED_OPERATIONS=2048
exec "$ROOT/scripts/run_gate3_random_v2.sh" "$@"
