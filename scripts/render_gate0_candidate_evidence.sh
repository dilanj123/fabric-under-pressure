#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_LOG="$ROOT/results/raw/gate0/env/check_env.log"
OUT_DIR="$ROOT/results/processed/gate0"
mkdir -p "$OUT_DIR"

# This script is intentionally strict: it is run only after every smoke command
# has returned success.  It creates reviewable candidate evidence; it does not
# create a Git tag or silently publish a PASS commit.
grep -q 'uname=Darwin' "$ENV_LOG"
grep -q 'machine=arm64' "$ENV_LOG"

test -s "$ROOT/results/raw/gate0/sim/results.xml"
test -s "$ROOT/results/raw/gate0/bfm/results.xml"
test -s "$ROOT/results/raw/gate0/formal/run.log"
test -s "$ROOT/results/raw/gate0/synth/ecp5_smoke.json"
test -s "$ROOT/results/raw/gate0/pnr/ecp5_smoke.config"
test -s "$ROOT/results/raw/gate0/wrapper/preserve_harness.json"

{
  echo '# Gate-0 candidate evidence — macOS arm64'
  echo
  echo '**Candidate result: PASS, pending repository review/commit.**'
  echo
  echo 'This file was generated only after the complete Gate-0 driver returned success on a Darwin/arm64 host.'
  echo
  echo '## Host and tool record'
  echo '```text'
  cat "$ENV_LOG"
  echo '```'
  echo
  echo '## Smoke evidence'
  echo '| Check | Evidence | Candidate status |'
  echo '|---|---|---|'
  echo '| Host/platform | `results/raw/gate0/env/check_env.log` | PASS |'
  echo '| SV frontends | `results/raw/gate0/env/sv_frontends.log` | PASS |'
  echo '| Verilator+cocotb | `results/raw/gate0/sim/results.xml` | PASS |'
  echo '| cocotbext-axi BFM | `results/raw/gate0/bfm/results.xml` | PASS |'
  echo '| Formal prove/cover/expected-fail | `results/raw/gate0/formal/run.log` | PASS |'
  echo '| ECP5 synthesis | `results/raw/gate0/synth/ecp5_smoke.json` | PASS |'
  echo '| ECP5 P&R | `results/raw/gate0/pnr/ecp5_smoke.config` | PASS |'
  echo '| Wrapper preservation | `results/raw/gate0/wrapper/preserve_harness.json` | PASS |'
  echo
  echo 'Do not create `kg-g0-env` until these artifacts have been reviewed and committed into the evidence record.'
} > "$OUT_DIR/ci_candidate_pass.md"
