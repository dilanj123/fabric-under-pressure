# Gate-0 Evidence Summary

**Gate result: PASS.** The complete smoke suite returned exit code 0 on this Darwin/arm64 host with the repair recorded in `fed87e1`, and the reviewed GitHub macOS arm64 qualification passed at run `35801448593`.

| Check | Command | Result | Evidence | Classification |
|---|---|---|---|---|
| host/platform | `./scripts/check_env.sh` | PASS | `results/raw/gate0/env/check_env.log` | REPRO |
| protocol/source register | n/a | PASS | `docs/references/AXI_SPEC.md` | SPEC |
| upstream snapshots/licences | n/a | PASS | `docs/THIRD_PARTY_MANIFEST.md` | UPSTREAM |
| SV lint/elaboration | `./scripts/run_smoke_sv.sh` | PASS | `results/raw/gate0/env/sv_frontends.log` | REPRO |
| Verilator+cocotb | `./scripts/run_smoke_sim.sh` | PASS | `results/raw/gate0/sim/results.xml` and `run.log` | SIM |
| cocotbext-axi | `./scripts/run_smoke_bfm.sh` | PASS | `results/raw/gate0/bfm/results.xml` and `run.log` | SIM / verification-only BFM |
| formal prove/cover/expected-fail | `./scripts/run_smoke_formal.sh` | PASS | `results/raw/gate0/formal/run.log` | FORMAL |
| Yosys ECP5 synth | `./scripts/run_smoke_synth.sh` | PASS | `results/raw/gate0/synth/run.log` and `ecp5_smoke.json` | SYNTH |
| nextpnr ECP5 | `./scripts/run_smoke_pnr.sh` | PASS | `results/raw/gate0/pnr/run.log`, `.config`, `.bit` | PNR |
| compact wrapper method | `./scripts/run_smoke_wrapper.sh` | PASS | `results/raw/gate0/wrapper/run.log`, `check.log`, JSON | SYNTH / methodology |

The combined driver was run with `bash ./scripts/run_gate0.sh` and returned exit code 0. The wrapper retained 777 mapped cells with a 17-bit external interface. The P&R smoke used LFE5U-45F/CABGA381/speed 6, seed 1 and a 100 MHz target.

GitHub run 35801032142 failed in the Verilator C++ compilation before the explicit `-std=c++17` portability repair. The focused local reruns and full local driver passed after the repair. Reviewed run 35801448593 passed all workflow steps; its artifact is available locally under `results/raw/gate0/github-actions/35801448593/` and is indexed in `results/processed/gate0/ci-run-35801448593.md`.

This evidence qualifies the toolchain and generic methodology only. No Fabric AXI RTL, reference model, AXI functional correctness, performance, PPA or project timing evidence exists.
