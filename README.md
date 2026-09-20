# Fabric Under Pressure

Deterministic QoS-aware AXI4 SoC interconnect portfolio project.

**Current state:** Phase 0 bootstrap. No project AXI fabric RTL has been implemented.

The repository is governed by `00_MASTER_PROJECT_PLAN.md` and `01_CHATGPT_PROJECT_OPERATING_INSTRUCTIONS.md`.
The project targets a **documented AXI4 subset**, not an unrestricted AXI4-compliance claim.

## Gate 0

Run on the intended Apple-Silicon host after installing the pinned OSS CAD Suite and Python environment:

```bash
./scripts/check_env.sh
./scripts/run_smoke_sv.sh
./scripts/run_smoke_sim.sh
./scripts/run_smoke_bfm.sh
./scripts/run_smoke_formal.sh
./scripts/run_smoke_synth.sh
./scripts/run_smoke_pnr.sh
./scripts/run_smoke_wrapper.sh
```

Evidence is written under `results/raw/gate0/`; concise conclusions belong under `results/processed/gate0/`.

See `docs/GATE0_MAC_RUNBOOK.md` for the exact intended-host qualification procedure.

## Publish and launch Gate 0

For the dedicated GitHub repository creation/push and Apple-Silicon qualification flow, see `docs/GITHUB_BOOTSTRAP.md` or run `./scripts/publish_github_and_start_gate0.sh` from an authenticated machine with GitHub CLI.
