# Project State

**Date:** 2026-09-23
**Gate:** Gate 1 PASS; Gate 0 environment qualification reviewed and tagged
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
- all Fabric AXI behavior, formal properties, performance, PPA and timing;
- any Architecture A or B RTL result.

## Risks
Do not interpret generic smoke evidence as Fabric behavior or performance evidence. Gate 0 qualifies the toolchain; Gate 1 freezes the contract; neither gate qualifies project AXI RTL.

## Specification changes
No AXI behavior or RTL changed. Gate-1 documentation freezes the interface bundle, buffering, endpoint model, workload generator, metrics, traceability and formal assumptions; see D023-D024.

## Phase-0 execution status

- The physical Apple-Silicon host passed the complete Gate-0 driver at exit code 0.
- The BFM smoke passed aligned 64-bit read/write, a 4-beat INCR transfer, explicit IDs/QoS and deterministic backpressure.
- Generic formal prove/cover/intentional-fail, ECP5 synthesis/P&R and wrapper preservation passed.
- No project AXI RTL or reference model exists.

## Next smallest task
Create the first narrow Architecture A RTL task: implement and verify the decoder/target-select primitive against the frozen interface and traceability contract. Do not implement Architecture B, CPU integration or CDC in that task.
