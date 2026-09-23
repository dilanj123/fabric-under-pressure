#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 -m venv "$ROOT/.venv"
if ! "$ROOT/.venv/bin/python" -m pip --version >/dev/null 2>&1; then
  "$ROOT/.venv/bin/python" -m ensurepip --upgrade
fi
"$ROOT/.venv/bin/python" -m pip install --upgrade pip
"$ROOT/.venv/bin/pip" install -r "$ROOT/requirements/phase0.txt"
"$ROOT/.venv/bin/pip" freeze | tee "$ROOT/results/raw/gate0/env/pip-freeze.txt"
