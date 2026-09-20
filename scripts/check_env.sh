#!/usr/bin/env bash
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/results/raw/gate0/env/check_env.log"
mkdir -p "$(dirname "$OUT")"
{
  echo "timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "uname=$(uname -a)"
  echo "machine=$(uname -m)"
  if command -v sw_vers >/dev/null 2>&1; then sw_vers; fi
  echo "shell=${SHELL:-unknown}"
  for cmd in python3 pip3 git verilator yosys sby nextpnr-ecp5 ecppack slang; do
    echo "--- $cmd ---"
    if command -v "$cmd" >/dev/null 2>&1; then
      command -v "$cmd"
      case "$cmd" in
        python3) python3 --version ;;
        pip3) pip3 --version ;;
        git) git --version ;;
        verilator) verilator --version ;;
        yosys) yosys -V ;;
        sby) sby --version || sby -V || true ;;
        nextpnr-ecp5) nextpnr-ecp5 --version ;;
        ecppack) ecppack --version || true ;;
        slang) slang --version || true ;;
      esac
    else
      echo "MISSING"
    fi
  done
} | tee "$OUT"
