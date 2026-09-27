# Project State

**Date:** 2026-09-26
**Gate:** Gate 1 PASS; `kg-g1-spec` exists remotely at `aecfb8c`
**Architecture:** planning frozen; raw-address decode, request-shape legality, manager/internal ID mapping, per-manager/per-direction outstanding tracking, Architecture-A 3-way RR arbiter, per-manager write-owner context, one target-specific Architecture-A AW eligibility/RR boundary, one registered one-target AW channel path, a shared three-manager write-state bank, one registered owner-directed W target path, a four-source RR response arbiter, one registered per-manager B response router, one target-specific Architecture-A AR path and a shared three-manager read-state bank exist, project AXI fabric is not integrated.

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
- integrated multi-target Fabric AXI behavior, end-to-end formal properties, performance, PPA and timing;
- four-target production write composition, R integration, S3 response generation, or Architecture-B RTL. One-target AW/AR admission and registered transport, shared read/write state, focused owner-directed W transport and focused B response/write-completion transport are evidenced; returned-target versus recorded-target matching is not implemented because the current shared bank interface does not expose it.

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
- The standalone per-manager write-owner context has directed state-transition and three-manager composition simulation, bounded formal proof/cover for context stability, beat accounting, WLAST release and malformed-event diagnostics, and full Yosys synthesis; the focused AW boundary/owner composition now checks target exclusion and limited target-owner uniqueness, while AXI channel integration remains absent.
- The target-specific Architecture-A AW boundary composes the frozen eligibility equation with the verified RR primitive, blocks a write-owned target, preserves held grants under READY stall and suppresses D031 same-edge successor lookahead. The one-target AW channel path now adds manager-facing admission, complete payload selection, internal ID widening, a one-entry registered target AW slot, target handshake and D032 no drain/refill behavior. Production outstanding/write-owner allocation, W routing, response paths and four-target integration remain absent.
- The shared write-state bank instantiates one outstanding tracker and one unfinished-W owner per manager. The one-target AW path plus bank composition allocates both from manager-facing AW admission, keeps state allocated through target AW stall/consumption, releases owner at final W and outstanding state at B, and preserves shared four-write/one-owner limits. Four-target production state fanout remains absent.
- The registered W target path accepts W only from the registered owner of its target, supports W-before-AW waiting, AW-before-W and same-cycle AW/W behavior, holds stalled target payload, permits non-final drain/refill and forbids final-WLAST refill. Target W delivery, rather than manager W admission, drives owner progression. The focused AW/state/W composition leaves outstanding state active after owner release until B; four-target W fanout remains absent.
- The registered B response router decodes widened BID, validates manager prefix and busy manager ID, arbitrates S0-S3 independently per manager into registered manager-facing slots, holds B payload under backpressure and clears write outstanding state only on manager B handshake. A live audit found and repaired an initial occupied-slot overwrite hazard: the repaired path disables arbitration while a manager slot is occupied and derives slot admission from the actual target B handshake. Fresh repair evidence is authoritative; source-target metadata matching, four-target production write composition and S3 response generation remain absent.
- The Architecture-A AR target path composes read legality/target eligibility with the verified 3-way RR primitive, applies D036 same-edge successor suppression, widens manager IDs, and transports the full AR bundle through a one-entry registered target slot with D032 no drain/refill. The shared read-state bank instantiates one outstanding tracker per manager, allocates on manager-facing AR admission, enforces four reads and one busy ID per manager, and completes only through its abstract read-completion input. R routing and accepted-RLAST integration remain absent.

## Next smallest task
Implement the Architecture-A R response-routing path with widened RID validation, per-manager S0-S3 arbitration, burst-source locking through accepted RLAST and read outstanding completion only on manager-facing accepted RLAST.
