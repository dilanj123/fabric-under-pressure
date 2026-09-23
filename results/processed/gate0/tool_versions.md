# Gate-0 tool/version record

## Qualified local host
- Host: `Darwin MacBook-Pro.local 25.4.0 Darwin Kernel Version 25.4.0: Thu Mar 19 19:31:17 PDT 2026 arm64`
- macOS: `26.4.1`, build `25E253`
- shell: `/bin/zsh`
- Git: `/opt/homebrew/bin/git`, `2.44.0`
- Python: repository `.venv`, `3.11.6`
- pip: `26.2.1`

## Qualified OSS CAD Suite
- Release: `2026-09-20`, darwin-arm64
- Asset: `oss-cad-suite-darwin-arm64-20260920.tgz`
- SHA-256: `3af61f750c8040bcdfe317ba6134f93e391d65dc27e6bf39ef56455e48c723ae`
- Installation: `/Users/Dilan/eda/fabric-under-pressure/oss-cad-suite`
- Verilator: `5.053 devel rev v5.052-119-g014c9820d (mod)`
- Yosys: `0.69+75`, git SHA `f0b945f63-dirty`
- SBY: `0.69`
- Slang: `11.0.448+e222e7dc0`
- nextpnr-ecp5: `0.11.1-30-g3e53a0bf`
- ecppack/Trellis: `1.4-82-g3afe7b5`
- formal solver used: Yices `2.7.0`

## Python pins used
`cocotb==2.1.0`, `cocotbext-axi==0.1.28`, `pytest==9.0.2`, `numpy==2.3.5`, `pandas==2.2.3`, `matplotlib==3.10.8`. Full resolved freeze is `results/raw/gate0/env/pip-freeze.txt`.

Raw command/version evidence is in `results/raw/gate0/env/check_env.log` and `results/raw/gate0/env/oss-cad-suite-install.log`.
