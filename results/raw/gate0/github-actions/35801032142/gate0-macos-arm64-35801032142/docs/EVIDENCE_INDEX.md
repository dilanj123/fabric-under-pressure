# Evidence Index

| ID | Class | Claim | Evidence | Status |
|---|---|---|---|---|
| G0-E001 | PLAN | repository skeleton and scripts exist | repository tree | COMPLETE |
| G0-E002 | SPEC | AXI4 authority pinned to IHI 0022H.c | `docs/references/AXI_SPEC.md` | COMPLETE |
| G0-E003 | UPSTREAM | required public repository snapshots/licences recorded | `docs/THIRD_PARTY_MANIFEST.md` | COMPLETE as public-source snapshot; local dependency checkout not performed |
| G0-E004 | UPSTREAM | candidate OSS CAD Suite darwin-arm64 asset/digest pinned | `results/processed/gate0/tool_versions.md` | COMPLETE as upstream metadata only |
| G0-E005 | REPRO | qualified host/tool probe | `results/raw/gate0/env/check_env.log` | PASS locally |
| G0-E006 | SIM | Verilator+cocotb smoke | `results/raw/gate0/sim/results.xml`, `run.log` | PASS locally |
| G0-E007 | SIM | cocotbext-axi compatibility | `results/raw/gate0/bfm/results.xml`, `run.log` | PASS locally; verification-only |
| G0-E008 | FORMAL | formal PASS/cover/expected-FAIL harness | `results/raw/gate0/formal/run.log` | PASS locally |
| G0-E009 | SYNTH | ECP5 synthesis smoke | `results/raw/gate0/synth/run.log`, `ecp5_smoke.json` | PASS locally |
| G0-E010 | PNR | ECP5 P&R smoke | `results/raw/gate0/pnr/run.log`, `.config`, `.bit` | PASS locally |
| G0-E011 | SYNTH/PNR | compact wrapper preserves payload cone | `results/raw/gate0/wrapper/run.log`, `check.log`, JSON | PASS locally; generic methodology |

| G0-E012 | REPRO | generated shell/Python smoke harnesses pass static syntax checks | local `bash -n` and `python -m py_compile` run, 2026-09-20 | COMPLETE for syntax only |

| G0-E013 | REPRO | Apple-Silicon CI qualification workflow | `.github/workflows/gate0-macos-arm64.yml`, pending workflow artifact | OPEN until CI run reviewed |

No AXI functional correctness or performance evidence exists yet.
