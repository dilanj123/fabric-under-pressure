# Project State

**Date:** 2026-09-23
**Gate:** Gate 0 PASS; reviewed local and GitHub macOS arm64 qualification
**Architecture:** planning frozen; project AXI RTL not started.

## What changed
Prepared history was restored at `11501c9037b14ed60ae71c8782ff732cec7c97cb` and pushed to `dilanj123/fabric-under-pressure`. The pinned OSS CAD Suite and Python environment were qualified on the physical Darwin/arm64 host. Gate-0 smoke sources/scripts were minimally repaired for the actual tool versions and the complete local driver passed. Public process-reference review remains against `dilanj123/from-rtl-to-pixels` commit `f32eb297fbe95530753673debd4739617529a84d`.

## Evidence now exists
- authoritative planning documents are present;
- protocol metadata/section register is present;
- public upstream repository SHAs/licence observations are recorded;
- exact candidate OSS CAD Suite darwin-arm64 asset/digest is recorded;
- exact Darwin/arm64 host and tool versions;
- exact Python freeze for cocotb 2.1.0 and cocotbext-axi 0.1.28;
- SV frontend, cocotb, BFM, formal, synthesis, P&R and wrapper raw evidence.

## Still unproven
- GitHub-hosted macOS arm64 workflow result and artifact review;
- all Fabric AXI behavior, formal properties, performance, PPA and timing.

## Risks
Do not interpret generated scripts or public upstream metadata as local tool qualification. Gate 0 remains OPEN until the intended Mac executes the smoke suite successfully.

## Specification changes
No AXI behaviour changed. Process authority was strengthened by resolving the RTL-to-Pixels reference, and repository ownership metadata was corrected to `dilanj123`; see D016-D017.

## Phase-0 execution status

- The physical Apple-Silicon host passed the complete Gate-0 driver at exit code 0.
- The BFM smoke passed aligned 64-bit read/write, a 4-beat INCR transfer, explicit IDs/QoS and deterministic backpressure.
- Generic formal prove/cover/intentional-fail, ECP5 synthesis/P&R and wrapper preservation passed.
- No project AXI RTL or reference model exists.

## Next smallest task
Gate 0 is closed at the reviewed local/CI evidence commit. The next task is the Gate-1 specification freeze; do not start fabric RTL until that freeze is complete.
