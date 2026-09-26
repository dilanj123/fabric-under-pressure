# Project State

**Date:** 2026-09-26
**Gate:** Gate 1 PASS; `kg-g1-spec` exists remotely at `aecfb8c`
**Architecture:** planning frozen; raw-address decode, request-shape legality, manager/internal ID mapping, per-manager/per-direction outstanding tracking, Architecture-A 3-way RR arbiter and per-manager write-owner context primitives exist, project AXI fabric is not integrated.

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
- any integrated Architecture-A Fabric behavior or Architecture-B RTL result.

## Risks
Do not interpret generic smoke evidence as Fabric behavior or performance evidence. Gate 0 qualifies the toolchain; Gate 1 freezes the contract; neither gate qualifies project AXI RTL.

## Specification changes
No frozen AXI behavior changed. This task added the standalone decoder, request-legality, RR fairness-case and per-manager write-owner evidence; Gate-1 documentation continues to freeze the interface bundle, buffering, endpoint model, workload generator, metrics, traceability and formal assumptions; see D023-D024.

## Phase-0 execution status

- The physical Apple-Silicon host passed the complete Gate-0 driver at exit code 0.
- The BFM smoke passed aligned 64-bit read/write, a 4-beat INCR transfer, explicit IDs/QoS and deterministic backpressure.
- Generic formal prove/cover/intentional-fail, ECP5 synthesis/P&R and wrapper preservation passed.
- The standalone raw-address decoder primitive has directed simulation, frontend/synthesis and focused formal evidence; no integrated fabric or reference model exists.
- The standalone request-legality primitive has directed simulation, full Yosys synthesis and focused formal evidence, including same-target composition with the raw-address decoder.
- The standalone manager/internal ID mapping primitive has exhaustive directed simulation, full Yosys synthesis and focused formal evidence; no outstanding state or response routing exists.
- The standalone per-manager/per-direction outstanding tracker has clocked directed simulation, full Yosys synthesis and bounded stateful formal evidence; no request arbitration or response routing exists, and its write lifetime remains distinct from the separate write-owner primitive.
- The standalone Architecture-A 3-way RR arbiter has directed scheduling/backpressure simulation, bounded safety/hold/pointer/selection formal evidence, bounded fairness evidence for M0, M1 and M2 under explicit continuous-request/READY assumptions, and full Yosys synthesis; no target-specific arbiter instantiation or AXI channel integration exists.
- The standalone per-manager write-owner context has directed state-transition and three-manager composition simulation, bounded formal proof/cover for context stability, beat accounting, WLAST release and malformed-event diagnostics, and full Yosys synthesis; no target-specific ownership composition or AXI channel integration exists.

## Next smallest task
Create the next narrow Architecture A task from the frozen dependency structure: implement the target-specific request eligibility/arbiter boundary while keeping AXI channel integration, write ownership and response routing separate. Do not implement Architecture B, CPU integration or CDC in that task.
