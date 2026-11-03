# Project State

**Date:** 2026-11-03
**Gate:** Gate 3 Architecture-A verification PASS; Gate-2 `kg-g2-a-functional` remains immutable at commit `cbb801aaf87870cb6f7aaa938f3d364e5b16d472` (annotated tag object `15190879d68fb7f94f425556d60a20609f818c79`). Gate-3 remains recorded by `kg-g3-a-verified`.
**Gate 3:** Five frozen seeds pass at both 512 and 2,048 random operations. Integrated whole-DUT AW and AR fairness each pass with manager order `0 1 2 0 1 2 0 1 2`. Random live depth is two reads/two writes; D042 allocates four-outstanding proof to Gate-2 directed tests, which demonstrate four, fifth-request blocking and next-cycle recovery. The final coverage review distinguishes random observations from directed same-target, ordering and live-reset evidence. See `results/processed/gate3/summary.md`.
**Architecture:** Production `rtl/axi_fabric_a.sv` is unchanged. Gate-2 closure passes and the expanded whole-top directed suite passes 384 checks (348 Gate-2 checks plus integrated fairness checks). Architecture-A Mission 2 measurement is complete: all 70 W00–W13/seed runs passed quota and XML checks; the common-wrapper ECP5 sweep completed 55 routes and is all-seed timing-clean through 60 MHz. D045 freezes one falsifiable B hypothesis. Architecture B and the A/B comparison remain open.

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
- exhaustive whole-Fabric formal proof and unrestricted AXI4 compliance;
- recorded-target versus returned-target response-source matching because the shared state interface does not expose the required metadata;
- Architecture-B behavior and the controlled A/B comparison; the measured synthetic endpoint does not represent a particular production memory/peripheral;
- general ECP5 timing signoff beyond the documented common-wrapper, fixed-seed method.

## Risks
Gate-0 generic smoke remains tool/methodology evidence only. Architecture-A performance claims are limited to the frozen synthetic endpoint, workloads, five seeds, sample policy and common wrapper recorded in `results/processed/arch_a_measurement/summary.md`.

## Specification changes
No frozen AXI behavior changed. This task added the standalone decoder, request-legality, RR fairness-case and per-manager write-owner evidence; Gate-1 documentation continues to freeze the interface bundle, buffering, endpoint model, workload generator, metrics, traceability and formal assumptions; see D023-D024.

## Historical milestone details

The following phase-status bullets are retained as historical milestone descriptions; they do not describe the current production-top state.

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
- The Architecture-A AR target path composes read legality/target eligibility with the verified 3-way RR primitive, applies D036 same-edge successor suppression, widens manager IDs, and transports the full AR bundle through a one-entry registered target slot with D032 no drain/refill. The shared read-state bank instantiates one outstanding tracker per manager, allocates on manager-facing AR admission, enforces four reads and one busy ID per manager, and completes through its abstract read-completion input; the common R router now drives that completion in focused AR/R composition.
- The common R response router decodes widened RID, validates manager prefix and busy manager ID, arbitrates four targets independently per manager for first-beat selection, locks the selected source and RID through manager-facing accepted RLAST, supports non-final locked-source drain/refill and registered manager-facing slots, and clears read state only on accepted manager RLAST in focused AR/R composition. Recorded-target matching, full four-target production integration remains absent.

- The S3 error target has independent one-context write/read sides. It consumes legal unmapped write bursts through WLAST before generating stable DECERR B, and emits exact zero-data DECERR read bursts with ARLEN+1 beats and final RLAST. Focused manager-to-S3-to-manager write and read lifecycle simulations and bounded endpoint formal checks pass. A repair also confirms legal WVALID-before-local-AW is backpressured without a false diagnostic; full four-target routing remains absent.

## Next smallest task
Begin the separately reviewed Architecture-B implementation mission only after preserving D045's evaluation criteria and reusing the frozen benchmark driver, endpoint, wrapper, constraints, seeds and tools unchanged. Do not claim an A/B result until the full matched B measurements are complete.
