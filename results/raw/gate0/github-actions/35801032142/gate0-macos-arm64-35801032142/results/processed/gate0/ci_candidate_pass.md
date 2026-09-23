# Gate-0 candidate evidence — macOS arm64

**Candidate result: PASS, pending repository review/commit.**

This file was generated only after the complete Gate-0 driver returned success on a Darwin/arm64 host.

## Host and tool record
```text
timestamp=2026-09-23T00:08:35Z
uname=Darwin MacBook-Pro.local 25.4.0 Darwin Kernel Version 25.4.0: Thu Mar 19 19:31:17 PDT 2026; root:xnu-12377.101.15~1/RELEASE_ARM64_T6020 arm64
machine=arm64
ProductName:		macOS
ProductVersion:		26.4.1
BuildVersion:		25E253
shell=/bin/zsh
--- python3 ---
/Users/Dilan/Projects/fabric-under-pressure/.venv/bin/python3
Python 3.11.6
--- pip3 ---
/Users/Dilan/Projects/fabric-under-pressure/.venv/bin/pip3
pip 26.2.1 from /Users/Dilan/Projects/fabric-under-pressure/.venv/lib/python3.11/site-packages/pip (python 3.11)
--- git ---
/opt/homebrew/bin/git
git version 2.44.0
--- verilator ---
/Users/Dilan/eda/fabric-under-pressure/oss-cad-suite/bin/verilator
Verilator 5.053 devel rev v5.052-119-g014c9820d (mod)
--- yosys ---
/Users/Dilan/eda/fabric-under-pressure/oss-cad-suite/bin/yosys
Yosys 0.69+75 (git sha1 f0b945f63-dirty, Release, Clang /usr/local/osxcross/target/bin/aarch64-apple-darwin25.5-clang++ 21.1.8)
--- sby ---
/Users/Dilan/eda/fabric-under-pressure/oss-cad-suite/bin/sby
SBY v0.69
--- nextpnr-ecp5 ---
/Users/Dilan/eda/fabric-under-pressure/oss-cad-suite/bin/nextpnr-ecp5
--- ecppack ---
/Users/Dilan/eda/fabric-under-pressure/oss-cad-suite/bin/ecppack
Version 1.4-82-g3afe7b5
--- slang ---
/Users/Dilan/eda/fabric-under-pressure/oss-cad-suite/bin/slang
slang version 11.0.448+e222e7dc0
```

## Smoke evidence
| Check | Evidence | Candidate status |
|---|---|---|
| Host/platform | `results/raw/gate0/env/check_env.log` | PASS |
| SV frontends | `results/raw/gate0/env/sv_frontends.log` | PASS |
| Verilator+cocotb | `results/raw/gate0/sim/results.xml` | PASS |
| cocotbext-axi BFM | `results/raw/gate0/bfm/results.xml` | PASS |
| Formal prove/cover/expected-fail | `results/raw/gate0/formal/run.log` | PASS |
| ECP5 synthesis | `results/raw/gate0/synth/ecp5_smoke.json` | PASS |
| ECP5 P&R | `results/raw/gate0/pnr/ecp5_smoke.config` | PASS |
| Wrapper preservation | `results/raw/gate0/wrapper/preserve_harness.json` | PASS |

Do not create `kg-g0-env` until these artifacts have been reviewed and committed into the evidence record.
