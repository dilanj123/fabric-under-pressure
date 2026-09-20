# FABRIC-001 — Intended-Host Gate-0 Qualification

**Type:** environment evidence only  
**May implement project AXI RTL:** NO  
**Prerequisite:** repository bootstrap from FABRIC-000

## Objective
Run the prepared Gate-0 smoke suite on the intended macOS/Apple-Silicon host and close Gate 0 with real evidence, or keep it open with a precise blocker.

## Frozen upstream bundle for this task
- OSS CAD Suite release: `2026-09-20`
- asset: `oss-cad-suite-darwin-arm64-20260920.tgz`
- SHA-256: `3af61f750c8040bcdfe317ba6134f93e391d65dc27e6bf39ef56455e48c723ae`

Follow `docs/GATE0_MAC_RUNBOOK.md`.

A GitHub-hosted Apple-Silicon execution path is also provided at `.github/workflows/gate0-macos-arm64.yml`. It targets `macos-14`, asserts `Darwin/arm64`, uses the same pinned OSS CAD Suite asset/digest, and uploads Gate-0 evidence for review.

## Required commands
```bash
./scripts/check_env.sh
./scripts/bootstrap_python.sh
source .venv/bin/activate
./scripts/run_smoke_sv.sh
./scripts/run_smoke_sim.sh
./scripts/run_smoke_bfm.sh
./scripts/run_smoke_formal.sh
./scripts/run_smoke_synth.sh
./scripts/run_smoke_pnr.sh
./scripts/run_smoke_wrapper.sh
```

## Acceptance criteria
1. Host evidence says Darwin/arm64.
2. Exact versions for Verilator, Yosys, SBY, solver, nextpnr-ecp5, Trellis/ecppack, Python and pip are captured.
3. SV smoke passes intended frontends; any interfaces/modports experiment remains optional.
4. Verilator+cocotb counter smoke passes and emits XML.
5. cocotbext-axi smoke passes: aligned 64-bit read/write, four-beat INCR transfer, explicit IDs and deterministic backpressure.
6. Formal prove+cover pass and intentional-fail task is detected as failure.
7. ECP5 synthesis succeeds.
8. nextpnr routes LFE5U-45F/CABGA381/speed-6 at the smoke target and emits config.
9. Wrapper preservation smoke shows the payload cone survives synthesis and does not collapse to trivial logic.
10. `results/processed/gate0/summary.md`, `tool_versions.md`, `docs/EVIDENCE_INDEX.md`, `docs/PROJECT_STATE.md` are updated from the actual logs.
11. Only then may a `kg-g0-env` known-good tag be created.

## Stop conditions
Stop without starting AXI RTL if any core frontend, simulator, formal, synth/P&R or wrapper-preservation check fails. Record the exact command/log and make the smallest tool/coding-style decision needed.
