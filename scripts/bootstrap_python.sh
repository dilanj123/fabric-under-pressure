#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 -m venv "$ROOT/.venv"
"$ROOT/.venv/bin/python" -m pip install --upgrade pip
"$ROOT/.venv/bin/pip" install -r "$ROOT/requirements/phase0.txt"
"$ROOT/.venv/bin/pip" freeze | tee "$ROOT/results/raw/gate0/env/pip-freeze.txt"
