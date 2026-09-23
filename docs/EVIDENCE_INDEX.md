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

| G0-E013 | REPRO | Apple-Silicon CI qualification workflow | `.github/workflows/gate0-macos-arm64.yml`; run 35801448593 artifact under `results/raw/gate0/github-actions/35801448593/`, reviewed report in `results/processed/gate0/ci-run-35801448593.md` | PASS; all workflow steps succeeded |

No AXI functional correctness or performance evidence exists yet.

## Gate-1 specification evidence

| ID | Class | Claim | Evidence | Status |
|---|---|---|---|---|
| G1-E001 | SPEC | documented AXI4 subset, exact signal bundle, attributes and exclusions | `docs/REQUIREMENTS.md` | COMPLETE |
| G1-E002 | SPEC | topology, address map, ID widening, ownership, buffering and reset contract | `docs/MICROARCHITECTURE.md` | COMPLETE |
| G1-E003 | SPEC | workload generator, percentages, endpoint model, seeds and sample policy frozen | `bench/workloads.yaml`, SHA-256 `31c599caa7344c938b588a0f22404cfcfe5fe53b3ef5fae40a568130cfadfca4` | COMPLETE |
| G1-E004 | SPEC | metric definitions and fixed P&R/wrapper method | `docs/TIMING_PERFORMANCE.md` | COMPLETE |
| G1-E005 | SPEC | requirement-to-test and formal assumption traceability | `docs/VERIFICATION_PLAN.md`, `docs/FORMAL.md` | COMPLETE |
| G1-E006 | REVIEW | hostile Gate-1 consistency review | authority-file review recorded in Gate-1 commit | PASS; no open BLOCKER/MAJOR issue |

## Decoder primitive evidence

| ID | Class | Claim | Evidence | Status |
|---|---|---|---|---|
| D-E001 | SIM | address decoder directed boundary and default tests pass | `results/raw/decoder/simulation.log` | PASS; 19 self-checking cases |
| D-E002 | FORMAL | decoder one-hot/mapped/default properties prove | `results/raw/decoder/formal_prove/logfile.txt` | PASS; Yices via SBY, depth 1 |
| D-E003 | FORMAL | all four target covers reach | `results/raw/decoder/formal_cover/logfile.txt` | PASS; S0, S1, S2 and S3 covers reached at step 0 |
| D-E004 | REPRO | decoder Verilator frontend/lint compatibility passes | `results/raw/decoder/verilator_lint.log` | PASS; reviewed with no warnings |
| D-E005 | SYNTH | decoder completes target-aware Yosys ECP5 synthesis | `results/raw/decoder/yosys_synth.log`, `axi_address_decoder_ecp5.json` | PASS; no P&R or Fabric PPA claim |
