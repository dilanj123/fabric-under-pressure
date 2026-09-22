# Project State

**Date:** 2026-09-22
**Gate:** Gate 0 OPEN
**Architecture:** planning frozen; project AXI RTL not started.

## What changed
Repository/bootstrap skeleton, Gate-0 smoke sources/scripts, protocol source register, upstream snapshot, third-party manifest and Gate-1 document skeletons created. Public process-reference review is now complete against `dilanj123/from-rtl-to-pixels` commit `f32eb297fbe95530753673debd4739617529a84d`. GitHub publication target corrected to `dilanj123/fabric-under-pressure`.

## Evidence now exists
- authoritative planning documents are present;
- protocol metadata/section register is present;
- public upstream repository SHAs/licence observations are recorded;
- exact candidate OSS CAD Suite darwin-arm64 asset/digest is recorded;
- current execution-host probe proves this ChatGPT container is Linux/x86_64 and lacks Verilator/Yosys/SBY/nextpnr/Trellis;
- Python package installation attempt failed because this container has no external package-index network access.

## Still unproven / Gate-0 blockers
- intended macOS/Apple-Silicon tool versions;
- SV frontend compatibility;
- Verilator+cocotb smoke;
- cocotbext-axi compatibility;
- formal PASS/cover/intentional-FAIL harness;
- ECP5 synthesis/P&R;
- compact wrapper preservation experiment.

## Risks
Do not interpret generated scripts or public upstream metadata as local tool qualification. Gate 0 remains OPEN until the intended Mac executes the smoke suite successfully.

## Specification changes
No AXI behaviour changed. Process authority was strengthened by resolving the RTL-to-Pixels reference, and repository ownership metadata was corrected to `dilanj123`; see D016-D017.

## Phase-0 execution status

- Repository/bootstrap structure is authored.
- Current ChatGPT execution host is Linux/x86_64, not the intended macOS/Apple-Silicon qualification host.
- Static syntax/completeness checks pass for authored bootstrap scripts and Python tests.
- A real cocotbext-axi BFM qualification smoke is authored (aligned read/write, 4-beat INCR burst, explicit IDs/QoS, deterministic backpressure).
- Simulation/formal/synthesis/P&R evidence remains OPEN because Verilator/Yosys/SBY/nextpnr/Trellis and cocotb packages are unavailable on this host and network package installation is blocked.
- Gate 0 therefore remains OPEN. No KNOWN_GOOD tag is permitted yet.

## Next smallest task
Push the repository to a GitHub remote and run `.github/workflows/gate0-macos-arm64.yml` (or run the same suite directly on the developer Mac). Review the resulting Darwin/arm64 evidence; only then close Gate 0 and create `kg-g0-env`. Do not start fabric RTL while Gate 0 is open.
