# Gate-0 Evidence Summary

**Gate result: PASS locally; CI qualification remains separate evidence.** The complete smoke suite returned exit code 0 on this Darwin/arm64 host at commit `11501c9037b14ed60ae71c8782ff732cec7c97cb`.

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

This evidence qualifies the toolchain and generic methodology only. No Fabric AXI RTL, reference model, AXI functional correctness, performance, PPA or project timing evidence exists.
