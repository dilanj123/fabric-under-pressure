#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export GATE3_ARCH=B
export GATE3_OUT_DIR="${GATE3_OUT_DIR:-$ROOT/results/raw/gate3_random_b_512}"
export GATE3_OPERATIONS=512
export GATE3_EXPECTED_OPERATIONS=512
exec "$ROOT/scripts/run_gate3_random_v2.sh" "$@"
