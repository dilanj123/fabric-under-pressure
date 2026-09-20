# Project State

**Date:** 2026-09-20
**Gate:** Gate 0 OPEN
**Architecture:** planning frozen; project AXI RTL not started.

## What changed
Repository/bootstrap skeleton, Gate-0 smoke sources/scripts, protocol source register, upstream snapshot, third-party manifest and Gate-1 document skeletons created.

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
None. No frozen AXI architecture decision was changed by bootstrap work.

## Next smallest task
Run the Gate-0 smoke suite on the intended Apple-Silicon host with the pinned candidate OSS CAD Suite and Python environment; repair only environment/coding-style issues discovered. Do not start fabric RTL while Gate 0 is open.
