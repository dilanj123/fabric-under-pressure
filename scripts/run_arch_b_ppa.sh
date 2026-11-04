#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export ARCH_PPA_ARCH=B
export ARCH_A_PPA_OUT="${ARCH_A_PPA_OUT:-$ROOT/results/raw/arch_b_ppa_v1}"
exec "$ROOT/scripts/run_arch_a_ppa.sh" "$@"
