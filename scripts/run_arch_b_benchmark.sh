#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export ARCH_BENCH_ARCH=B
export ARCH_BENCH_OUT_ROOT="${ARCH_BENCH_OUT_ROOT:-$ROOT/results/raw/arch_b_full_v1}"
exec "$ROOT/scripts/run_arch_a_benchmark.sh" "$@"
