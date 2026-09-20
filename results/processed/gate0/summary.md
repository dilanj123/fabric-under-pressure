# Gate-0 Evidence Summary

**Gate result: OPEN.** Repository/bootstrap work is complete, but the intended Apple-Silicon EDA flow has not yet been executed.

| Check | Command | Result | Evidence | Decision/impact |
|---|---|---|---|---|
| host/platform | `./scripts/check_env.sh` | PARTIAL | `results/raw/gate0/env/check_env.log` | current container is Linux/x86_64; rerun on intended Mac required |
| protocol/source register | n/a | PASS (documentation) | `docs/references/AXI_SPEC.md` | H.c source/sections pinned |
| upstream snapshots/licences | n/a | PASS (public-source snapshot) | `docs/THIRD_PARTY_MANIFEST.md` | core references remain reference-only |
| SV lint/elaboration | `./scripts/run_smoke_sv.sh` | OPEN | `results/raw/gate0/env/` | EDA binaries unavailable here |
| Verilator+cocotb | `./scripts/run_smoke_sim.sh` | OPEN | `results/raw/gate0/sim/` | package/tool install unavailable here |
| cocotbext-axi | `./scripts/run_smoke_bfm.sh` | OPEN | `results/raw/gate0/bfm/` | full transaction smoke is authored; dependency remains unqualified until executed |
| formal | `./scripts/run_smoke_formal.sh` | OPEN | `results/raw/gate0/formal/` | PASS/cover/fail harness must run locally |
| Yosys ECP5 synth | `./scripts/run_smoke_synth.sh` | OPEN | `results/raw/gate0/synth/` | intended flow unqualified |
| nextpnr ECP5 | `./scripts/run_smoke_pnr.sh` | OPEN | `results/raw/gate0/pnr/` | LFE5U-45F/CABGA381/-6 command must run locally |
| compact wrapper method | `./scripts/run_smoke_wrapper.sh` | OPEN | `results/raw/gate0/wrapper/` | Gate-0 blocker until payload cone survival shown |

## Current conclusion
Do **not** implement fabric RTL yet. Run the smoke suite on the intended Mac and close every OPEN row first.

Static validation performed here: all generated shell scripts pass `bash -n`; both cocotb Python test modules pass `python -m py_compile`. This is syntax evidence only.

## Automated intended-host route
A GitHub Actions workflow now exists at `.github/workflows/gate0-macos-arm64.yml`. It targets the standard `macos-14` Apple-Silicon runner, asserts Darwin/arm64, verifies the pinned OSS CAD Suite checksum, executes the existing Gate-0 suite, and uploads evidence. The workflow itself is static harness evidence only; Gate 0 remains OPEN until a real run succeeds and its artifact is reviewed.
