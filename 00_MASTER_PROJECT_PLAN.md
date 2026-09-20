# Fabric Under Pressure — Deterministic QoS-Aware AXI4 SoC Interconnect

**Document:** `00_MASTER_PROJECT_PLAN.md`  
**Planning snapshot:** 2026-09-20  
**Status:** Authoritative planning contract; RTL implementation has not started.  
**Readiness:** READY WITH PHASE-0 CONDITIONS  
**Protocol claim:** **documented AXI4 subset**, not unrestricted/full AXI4 compliance.

---

## 0. Purpose and authority

This project is an evidence-driven SystemVerilog/SoC portfolio project about AXI4 interconnect architecture, arbitration, QoS, outstanding transactions, ordering, formal verification, tail latency, CDC and implementation/PPA trade-offs. It is deliberately **not** a CPU project, DMA-engine project, ACE/CHI project or large NoC project.

The engineering question is:

> How should an AXI4 fabric arbitrate between latency-critical control/accelerator traffic and bandwidth-heavy DMA traffic while preserving protocol correctness, bounding starvation under stated assumptions, and balancing tail latency, throughput, routed timing and area?

The architecture experiment is intentionally controlled:

- **Architecture A:** per-target round-robin request arbitration.
- **Architecture B:** the same datapath, buffering, topology and protocol behavior, but request arbitration becomes AxQOS-aware with deterministic aging/starvation escape.
- **Architecture C:** prohibited unless measured A/B evidence identifies a bottleneck that class separation could plausibly address. C requires a new decision record and a newly frozen experiment.

### 0.1 Repository authority order

Once the repository exists, engineering decisions are authoritative in this order:

1. `00_MASTER_PROJECT_PLAN.md`
2. `01_CHATGPT_PROJECT_OPERATING_INSTRUCTIONS.md`
3. `docs/REQUIREMENTS.md`
4. `docs/MICROARCHITECTURE.md`
5. `docs/VERIFICATION_PLAN.md`
6. `docs/FORMAL.md`
7. `docs/DECISIONS.md`
8. `docs/PROJECT_STATE.md`
9. `docs/EVIDENCE_INDEX.md`
10. implementation/test/build files

Contradictions must be recorded, not silently resolved.

### 0.2 Engineering method

Use the sequence:

`specify -> simplest complete baseline -> verify -> synthesize/implement -> measure -> identify bottleneck -> hypothesis -> one controlled architectural change -> re-verify -> re-measure -> retain/modify/reject -> compare -> conclude`

No performance feature may be justified before a measured bottleneck exists. No architectural comparison is valid if functionality, buffering, workload, target, tool settings or measurement method changes between variants without being the named experiment.

---

## 1. Evidence discipline

### 1.1 Evidence classifications

Every nontrivial claim in public documentation must carry one of these conceptual evidence classes:

| Class | Meaning | Examples |
|---|---|---|
| `SPEC` | Normative external specification evidence | Arm AMBA AXI4 rule, protocol ordering rule |
| `UPSTREAM` | Verified current upstream documentation/repository/tool metadata | repository licence, tool platform support |
| `PLAN` | Frozen engineering decision, not yet implemented | outstanding depth = 4 |
| `HYPOTHESIS` | Reasoned expectation requiring measurement | QoS+aging may reduce critical P99 |
| `SIM` | Simulation evidence produced by this repository | regression pass, scoreboard result |
| `FORMAL` | Formal tool evidence produced by this repository | property proved to stated depth/assumptions |
| `SYNTH` | Synthesis evidence | cell/LUT/FF counts |
| `PNR` | Routed implementation evidence | WNS, achieved target frequency |
| `BENCH` | Performance measurement evidence | P50/P95/P99, throughput, starvation interval |
| `REPRO` | Clean-clone/reproduction evidence | fresh checkout reruns documented command |

A `PLAN` or `HYPOTHESIS` is never upgraded to `SIM`, `FORMAL`, `PNR` or `BENCH` by prose. Tool outputs are required.

### 1.2 Claims forbidden without evidence

Do not claim any of the following until the matching artifact exists:

- functional correctness;
- AXI4 compliance beyond the documented subset and tested properties;
- formal proof of the whole fabric;
- bounded wall-clock starvation under arbitrary backpressure;
- timing closure;
- a specific Fmax;
- resource counts;
- throughput;
- P50/P95/P99 or maximum latency;
- a QoS improvement;
- a PPA trade-off.

### 1.3 Known-good commits

A commit becomes `KNOWN_GOOD` only when its required gate regression is complete and the evidence index points to the exact tool outputs. A tag/name without evidence is not a known-good state.

Recommended naming:

- `kg-g0-env`
- `kg-g1-spec`
- `kg-g2-arch-a-functional`
- `kg-g3-arch-a-deep`
- `kg-g4-ab-measured`
- `kg-g5-public`

---

## 2. Research findings and protocol authority

### 2.1 Arm specification decision

The current Arm document family is `ARM IHI 0022`. However, Issue J restructured the document and removed AXI3, AXI4 and AXI4-Lite content; later Issues K and L continue the newer AXI5-focused branch. Therefore **the newest issue number is not the correct semantic authority for an AXI4 implementation**.

Freeze the normative AXI4 source as:

- **Title:** AMBA AXI and ACE Protocol Specification
- **Document:** ARM IHI 0022H.c
- **ID:** ID012621
- **Date:** 26 January 2021
- **Status for this project:** normative protocol authority for AXI4 semantics
- **Canonical Arm documentation selector:** `https://developer.arm.com/documentation/ihi0022/hc`

Record Issue L only as current-family/version-history context:

- **ARM IHI 0022 Issue L**
- **Date:** 27 August 2025
- AXI4 content had already been removed beginning in Issue J.

Do not commit or redistribute the Arm PDF unless its licence terms are explicitly reviewed. Keep a source record containing document number, issue, date and canonical Arm link instead.

### 2.2 AXI4 rules that directly drive this architecture

The implementation and verification documents must cite the exact H.c sections/pages for at least these rules:

1. AXI has five independent channels: AW, W, B, AR, R.
2. `VALID` must remain asserted and payload stable until a `VALID && READY` handshake.
3. Write data can be presented before, with, or after its write address; the fabric must not assume AW and W arrive together.
4. AXI4 has no WID. A manager issues write data in the same order as write addresses, and an interconnect combining managers must preserve the address-associated write-data order.
5. A burst cannot cross a 4-KiB boundary.
6. AXI4 INCR bursts can be longer than this project supports, but the project may legally backpressure/restrict its documented subset.
7. Same-ID ordering requirements apply; different IDs permit greater reordering freedom.
8. An interconnect may append manager-port information to IDs to make IDs globally unique downstream and remove the added bits on return.
9. `AWQOS` and `ARQOS` are 4-bit fields. AXI4 recommends higher values as higher priority, but does **not** define the exact QoS algorithm. AXI ordering constraints take precedence over QoS.
10. Write response generation is dependent on completion of the accepted write address and all write data including WLAST; BVALID cannot be made dependent on BREADY.

These are architectural requirements, not coding details.

---

## 3. Current prior-art, licence and reuse review

Research snapshot: 2026-09-20. Exact dependency commits used by the repository must be pinned during Phase 0 and recorded in `THIRD_PARTY_MANIFEST.md`.

| Project | Current finding | Licence finding | Useful patterns | Allowed project use | Prohibited/avoid |
|---|---|---|---|---|---|
| `pulp-platform/axi` | Active; current release observed as v0.39.10. Provides AXI4/AXI4-Lite building blocks, crossbars, ID utilities, test infrastructure and Verilator/Yosys-Slang CI work. | Hardware is SHL-0.51. | Professional treatment of AXI channel decomposition, IDs, demux/mux, CDC, test structure. | **Reference-only for core fabric.** A separately approved generic verification/type utility may be reused only with provenance and licence handling. | Do not fork its crossbar, demux, arbitration or routing and present changes as original. |
| `pulp-platform/common_cells` | Active; repository explicitly labels cells active/deprecated and includes CDC/formal/test infrastructure. | Predominantly SHL-0.51, but individual files can carry different SPDX identifiers; inspect every reused file. | FIFO/CDC/reset primitives, coding/documentation patterns. | Candidate generic primitive source for later CDC only after file-level licence review and explicit decision. | Do not import a large utility dependency merely to avoid writing core project logic. |
| `pulp-platform/iDMA` | Active modular DMA architecture; supports AXI4+ATOPs, AXI4-Lite, AXI4-Stream and other protocols. | SHL-0.51. | Realistic DMA burst/page-boundary behavior and workload inspiration. | Reference for traffic-generation realism and DMA pressure patterns. | Do not integrate the DMA engine into MVP; that would shift portfolio scope. |
| `pulp-platform/FlooNoC` | Active; v0.8.4 observed 2026-06-30. End-to-end AXI4 multistream NoC, physical-link and virtual-channel ideas. | Hardware SHL-0.51; software/FlooGen Apache-2.0 per repository. | Later inspiration for class separation, physical QoS/VC ideas and PPA-aware NoC thinking. | Reference only; may inform Architecture C *if measured A/B evidence justifies C*. | No mesh/NoC implementation before the core fabric is public-ready. |
| `ZipCPU/wb2axip` | Public active reference containing bus bridges and formal material. Its README explicitly says the full-AXI formal property set in master is partial/incomplete. | Apache-2.0. | Formal property style, assumptions vs assertions, protocol bug examples. | Reference for formal methodology; small copied properties only if provenance/licence notices are explicit and originality remains clear. | Do not treat its master full-AXI property file as a complete compliance checker. |
| `alexforencich/cocotbext-axi` | Active cocotb AXI/AXI-Lite/APB models; current release observed as v0.1.28. Supports multiple in-flight transactions, IDs, response reordering/interleaving and RAM/slave models. | MIT. | Endpoint BFM, backpressure/pause generation, traffic stimulus. | Preferred candidate BFM for simulation **only** after Phase-0 compatibility smoke with cocotb 2.1.0. | It is not the project oracle. Expected routing/data/order remains checked by the original Python reference model. |

### 3.1 Originality boundary

The following remain original unless a later `DECISIONS.md` entry explicitly changes the policy:

- address decoder;
- manager-to-subordinate request arbitration;
- round-robin arbiter;
- QoS/aging scheduler;
- write ownership/routing state;
- B and R response routing/arbitration;
- outstanding transaction tracking;
- manager-index ID mapping;
- default/error target;
- performance counters;
- synthesizable contention traffic generators if later added;
- CDC bridge architecture if the extension is built;
- formal properties for project-specific mechanisms;
- Python transaction/reference model;
- benchmark analysis.

### 3.2 Third-party controls

`THIRD_PARTY_MANIFEST.md` must record for every external code dependency:

- repository URL;
- exact commit/tag;
- files/directories used;
- SPDX/licence;
- purpose;
- whether source is modified;
- required attribution/notice;
- whether it is build-only, verification-only or synthesizable.

`THIRD_PARTY_NOTICES.md` must contain required notices. A licence badge at repository level is not enough when reused files have independent headers.

---

## 4. Toolchain feasibility

### 4.1 Preferred reproducible path

Use a **pinned OSS CAD Suite `darwin-arm64` archive** for EDA binaries and a repository-controlled Python virtual environment for Python packages.

Current research supports Apple Silicon feasibility:

- OSS CAD Suite publishes `darwin-arm64` builds for macOS 13+ and includes Yosys, Slang, SBY, formal solvers, Verilator, nextpnr and Project Trellis.
- Homebrew separately provides Apple-Silicon bottles for Verilator and Yosys; current observed stable versions are Verilator 5.052 and Yosys 0.69.
- Homebrew provides SBY 0.68. The Homebrew SBY/Yosys dependency versions can move independently, so a Phase-0 smoke is mandatory if Homebrew is used as the primary path.
- cocotb 2.1.0 was released 2026-08-30/2026-09-01 and supports modern macOS/ARM64 combinations in its support policy.
- cocotbext-axi v0.1.28 is the current observed candidate BFM release.
- nextpnr supports ECP5 through Project Trellis.

### 4.2 Candidate pins before Phase-0 verification

These are **candidate**, not yet locally evidenced:

| Component | Candidate | Role |
|---|---:|---|
| Python | 3.12 or 3.13 | test/analysis environment |
| cocotb | 2.1.0 | verification framework |
| cocotbext-axi | 0.1.28 | external AXI BFM only |
| Verilator | 5.052-class/current suite pin | primary simulation + lint |
| Yosys | 0.69-class/current suite pin | synthesis/formal frontend |
| SBY | 0.68-class/current suite pin | formal orchestration |
| Slang / yosys-slang | version bundled with chosen OSS CAD Suite | SV elaboration/lint smoke |
| nextpnr-ecp5 | version bundled with chosen OSS CAD Suite | FPGA P&R |
| Project Trellis | suite-bundled pin | ECP5 database/bitstream support |
| Python analysis | numpy/pandas/matplotlib pinned in lockfile | benchmark analysis |

Phase 0 must record exact local versions and archive/hash. Do not write a README claiming these work until smoke evidence exists.

### 4.3 Lint policy

Minimum lint/elaboration path:

1. `verilator --lint-only` with warnings treated intentionally;
2. Slang or yosys-slang elaboration for the synthesizable subset;
3. Yosys synthesis parse/elaboration smoke.

Verible is optional; it is not an MVP blocker.

---

## 5. Frozen project definition

### 5.1 Topology

**Managers (3):**

- `M0`: CPU/control-like traffic generator — sparse, latency-sensitive.
- `M1`: DMA/bulk traffic generator — sustained bandwidth pressure.
- `M2`: latency-critical accelerator traffic generator — short high-QoS bursts.

**Logical subordinates (4):**

- `S0`: SRAM bank A model.
- `S1`: SRAM bank B model.
- `S2`: configuration/peripheral address region.
- `S3`: internal default/error target.

No CPU is integrated in the MVP.

### 5.2 Widths and constants

| Parameter | Frozen value |
|---|---:|
| Managers | 3 |
| Subordinates | 4 logical targets |
| `DATA_WIDTH` | 64 bits |
| `ADDR_WIDTH` | 32 bits |
| manager-side `ID_WIDTH` | 4 bits |
| manager-index width | 2 bits |
| subordinate-side internal ID width | 6 bits = `{manager_index[1:0], manager_id[3:0]}` |
| maximum supported burst | 16 beats |
| transfer size | 8 bytes/beat (`AxSIZE=3`) |
| read outstanding limit | 4 per manager |
| write outstanding limit | 4 per manager |
| simultaneous outstanding per ID | 1 per manager per direction |
| QoS width | 4 bits |
| Architecture-B age width | 8 bits |
| Architecture-B starvation threshold | 64 pending cycles |

Manager index encoding `2'b11` is unused and illegal on returned internal responses.

### 5.3 Address map

| Target | Range | Size | Purpose |
|---|---|---:|---|
| S0 | `0x0000_0000`–`0x0000_FFFF` | 64 KiB | SRAM A / primary contention target |
| S1 | `0x1000_0000`–`0x1000_FFFF` | 64 KiB | SRAM B / parallelism target |
| S2 | `0x2000_0000`–`0x2000_0FFF` | 4 KiB | config/peripheral region |
| S3 | all other addresses | catch-all | DECERR/default target |

Mapped region boundaries are 4-KiB aligned. Legal supported bursts cannot cross a 4-KiB boundary.

### 5.4 Documented AXI4 subset

#### Supported

- five AXI channels: AW, W, B, AR, R;
- `INCR` bursts only;
- 1–16 beats (`AxLEN=0..15`);
- 64-bit full-width aligned transfer size (`AxSIZE=3`);
- addresses aligned to 8 bytes;
- arbitrary legal `WSTRB[7:0]` byte enables on an otherwise full-width aligned transfer;
- manager-side 4-bit IDs;
- up to four outstanding reads and four outstanding writes per manager using distinct IDs;
- `OKAY`, `SLVERR`, `DECERR` response propagation/production as applicable;
- `WLAST` and `RLAST`;
- `AWQOS` and `ARQOS`;
- backpressure on every channel;
- pass-through/capture of normal transaction attributes needed by the selected interface bundle, while only QoS is interpreted by the scheduler;
- unmapped accesses via S3 default/error handling.

#### Explicitly unsupported in MVP

- `FIXED` bursts;
- `WRAP` bursts;
- bursts longer than 16 beats;
- narrow transfers (`AxSIZE != 3`);
- unaligned transfers;
- exclusives/locked accesses (`AxLOCK` must indicate normal access);
- AXI5 ATOPs;
- ACE/CHI/coherency;
- cache coherency;
- WID / AXI3-style write-data interleaving;
- user-defined `AxUSER/WUSER/BUSER/RUSER` semantics;
- splitting one burst across multiple subordinates;
- protocol conversion (AXI-Lite/APB/etc.) in MVP.

A conforming project traffic source must only issue supported transactions. Unsupported manager inputs are **outside the interface contract** and are caught by simulation/formal assertions; MVP RTL is not required to convert every unsupported request into an error response. Unmapped **supported** accesses are inside the contract and must produce DECERR through S3.

### 5.5 Attribute policy

The exact signal list is frozen in `docs/REQUIREMENTS.md` before RTL. The intent is:

- `AxID`, `AxADDR`, `AxLEN`, `AxSIZE`, `AxBURST`, `AxQOS` are carried;
- `AxLOCK` is accepted only in the normal/non-exclusive value;
- `AxCACHE`, `AxPROT` and `AxREGION` may be carried transparently but are not used for routing or scheduling;
- USER fields are omitted from the MVP interface;
- QoS affects request scheduling only after all AXI ordering/admission constraints are satisfied.

If tool support motivates a different packing/port representation, the signal semantics cannot change without a requirements decision.

---

## 6. Ordering, outstanding-state and routing contract

### 6.1 Transaction lifetime

For project bookkeeping, a transaction becomes outstanding when its AW or AR handshake occurs at the manager-facing fabric interface and remains outstanding until:

- write: the corresponding B handshake completes back to that manager;
- read: the corresponding R beat with `RLAST=1` handshakes back to that manager.

Read and write outstanding state are independent.

### 6.2 Per-ID serialization — deliberate simplification

The fabric accepts at most **one outstanding transaction for a given manager ID in a given direction**.

Consequences:

- same-ID response ordering is preserved by construction;
- no same-ID reorder buffer is required;
- different IDs can be outstanding simultaneously and may complete in a different order;
- read ID `x` and write ID `x` are independent because read/write ordering domains are independent for this project;
- this is a legal backpressure restriction of the documented subset, not a claim that AXI4 itself limits one transaction per ID.

Each manager therefore has:

- a 16-bit read-ID busy bitmap plus a read outstanding count limited to 4;
- a 16-bit write-ID busy bitmap plus a write outstanding count limited to 4.

An ID bit is cleared only on the final response handshake for that direction.

### 6.3 Internal ID mapping

On downstream AW/AR:

`internal_id = {manager_index[1:0], manager_id[3:0]}`

On B/R return:

- upper two bits select the manager;
- lower four bits are restored as BID/RID;
- returned IDs must correspond to a busy outstanding transaction;
- invalid manager code `3` or non-busy IDs are protocol/environment errors and must be asserted in verification.

This mapping prevents collisions between managers that use the same original ID.

### 6.4 Write-address/write-data discipline

AXI4 has no WID, so write routing is frozen as follows:

1. Each manager may have up to four completed-address write transactions waiting for B overall, but may have only **one write transaction whose W burst is not yet complete**.
2. A manager's AW is eligible only if:
   - no active data-phase context already exists for that manager;
   - write outstanding count < 4;
   - that manager ID is not busy;
   - request fields satisfy the documented subset;
   - its decoded target can accept a new write owner.
3. When AW handshakes to the selected subordinate, the fabric records the manager/target as the write-data ownership context.
4. `WREADY` for that manager is not asserted until a valid AW context has been accepted and registered. Therefore W may legally arrive before AW and simply waits; the fabric never assumes simultaneous AW/W.
5. The selected subordinate accepts no second AW from any manager until the current owner's `WLAST` beat handshakes.
6. Every W beat is routed only to the subordinate recorded by the current write ownership context.
7. Ownership clears on successful WLAST handshake, not on B.
8. After WLAST, the same manager may issue the next AW even if earlier B responses remain outstanding, subject to ID/count limits.

This intentionally trades some write-address concurrency for a much simpler and auditable W-ordering mechanism while still demonstrating multiple outstanding write responses.

### 6.5 Read requests

AR arbitration is independent per subordinate. A manager can issue another AR after a prior AR handshake as long as read count/ID constraints allow. No global read serialization is imposed across different IDs.

### 6.6 Response routing

#### B responses

Multiple subordinates can produce B responses for the same manager in the same cycle. A per-manager B-response round-robin arbiter selects one response beat. BID routes via the internal manager-index bits. B response arbitration is identical in Architectures A and B.

#### R responses

Multiple subordinates can produce R data for one manager. A per-manager R-response round-robin arbiter selects a subordinate and **locks to that subordinate for the complete burst until an accepted RLAST**. This avoids response-beat interleaving inside the project and makes response stability/backpressure simple. AXI permits more aggressive behavior across different IDs, but the project intentionally chooses the stricter burst-contiguous behavior.

R-response arbitration is identical in Architectures A and B.

### 6.7 Backpressure and liveness limits

Every channel supports backpressure.

If a subordinate deasserts READY forever or a manager refuses a response forever, the fabric must preserve protocol safety but cannot promise completion. Therefore:

- no absolute wall-clock starvation/completion bound is claimed under arbitrary environment backpressure;
- scheduler fairness is defined in terms of **service opportunities** and under explicit assumptions;
- verification includes long stalls and finite randomized stalls;
- formal liveness assumptions must be stated next to the property.

### 6.8 Reset contract

MVP uses one fabric clock and a fabric-wide active-low reset. The exact synchronizer style is frozen in microarchitecture after Phase-0 tool smoke, but system semantics are frozen now:

- reset is applied to fabric and verification endpoint models as a coordinated system reset;
- while reset is asserted, fabric-generated VALIDs are deasserted and internal ownership/outstanding/scheduler state clears;
- transactions accepted before reset are **abandoned** and receive no completion guarantee;
- after reset, all IDs are free and schedulers return to defined pointer/age state;
- subordinate models must discard pre-reset pending responses as part of the coordinated reset contract;
- verification checks that no pre-reset transaction is emitted by the fabric after reset;
- the MVP does **not** claim protection against a physically independent subordinate that violates the reset contract and later emits a stale response with an ID that collides with a post-reset transaction. Solving that requires an isolation/epoch protocol and is outside MVP.

This limitation must be public in `KNOWN_LIMITATIONS.md`.

---

## 7. Arbitration experiment

### 7.1 Common arbiter behavior required by A and B

Each S0/S1/S2 request direction has an independent request arbiter:

- one AW arbiter per target;
- one AR arbiter per target;
- S3 is an internal error target with equivalent admission discipline.

A selected request becomes a **held grant** when presented downstream. If downstream READY is low, the selected manager and its payload remain unchanged until handshake. No new request, even higher QoS or older, may pre-empt an already-presented downstream VALID.

Pointers advance only on successful address handshakes.

Read and write scheduling remain independent. A target occupied by an active W burst blocks new AW for that target but does not automatically block AR.

### 7.2 Architecture A — round robin

For each target and request direction:

- maintain a 2-bit pointer identifying the first manager to inspect;
- among eligible VALID requests, select the first in cyclic order starting at the pointer;
- if no eligible request exists, issue no grant;
- latch/hold the chosen request until handshake if target READY is low;
- after handshake, set pointer to the manager after the winner;
- there is no mid-burst pre-emption because arbitration is at transaction/address admission and writes hold target data ownership through WLAST.

**Fairness statement:** with a recurring address service opportunity and a requester that keeps a legal request asserted, round robin gives that requester a service opportunity within at most three successful competing grants. It does not override target backpressure or an active write-data ownership interval.

### 7.3 Architecture B — QoS + aging/starvation escape

Architecture B changes only the request scheduler policy/state. Topology, widths, route logic, ID logic, response arbiters, buffering, outstanding limits and endpoint models are unchanged.

#### Frozen fields

- `AxQOS`: 4-bit unsigned priority; larger value means higher normal-mode priority.
- age counter width: 8 bits.
- age counter saturation: 255.
- starvation threshold: 64 cycles pending.
- one age counter per manager input per target request arbiter/direction.
- counter reset: reset to 0 when no legal pending request is present or when the request handshakes.
- counter increment: +1 each cycle a legal request remains pending without handshake, saturating at 255.
- a held downstream request cannot be pre-empted.

#### Selection rule

For the eligible request set:

1. If one or more requests have `age >= 64`, enter **starvation-escape mode** and choose among only that starved set using rotating round-robin order.
2. Otherwise find the maximum AxQOS among eligible requests and choose among requests at that maximum using rotating round-robin order.
3. Latch/hold the selected request until handshake.
4. Advance the shared round-robin pointer after every successful address handshake.

This means:

- QoS is advisory priority, not an override of AXI ordering;
- aging does not mathematically add to QoS and cannot overflow into an accidental priority encoding;
- a newly arriving QOS=15 request cannot bypass a request that has entered starvation-escape mode if the starved request is next under the escape RR policy;
- age saturation does not lose all fairness information because the starved set is served round-robin rather than by saturated age magnitude.

#### Bound language

The project may prove a bounded wait for the **standalone arbiter under explicit readiness assumptions**. Integrated fabric documentation must phrase the guarantee as:

> A continuously pending legal requester that reaches starvation-escape state cannot be bypassed indefinitely by non-starved QoS traffic; with recurring service opportunities, the starved set is served round-robin. No finite wall-clock bound exists if the target or an active write-data phase can block service indefinitely.

A stronger cycle bound may only be published if formal assumptions and/or measured endpoint bounds make it valid.

### 7.4 No silent pipelining change

If Architecture B fails timing and requires an extra scheduler pipeline stage, it is no longer the frozen A/B experiment. Create a named variant (for example `B_PIPE1`) and re-freeze its latency/buffering contract. Do not silently add a register only to B and compare it as if scheduler policy were the sole variable.

---

## 8. Canonical workload contract

Workloads are frozen **before Architecture B performance data is inspected**. Their source configuration must be version controlled, preferably as `bench/workloads.yaml` plus deterministic generator code.

### 8.1 Traffic classes

| Class | Manager | Typical burst | QoS | Intent |
|---|---|---:|---:|---|
| Control | M0 | 1 beat | 8 | sparse latency-sensitive control |
| DMA | M1 | 16 beats | 0 | sustained bulk bandwidth |
| Critical accelerator | M2 | 1–2 beats | 15 | bursty high-priority latency-sensitive |

All benchmark accesses are supported, 8-byte aligned INCR transactions. Unless a workload says otherwise, contention workloads target S0.

### 8.2 Fixed pseudo-random seeds

For every stochastic workload use exactly:

- `0xFABC0001`
- `0xFABC0002`
- `0xFABC0003`
- `0xFABC0004`
- `0xFABC0005`

The generator algorithm and Python package versions are pinned. A seed cannot be removed because it makes one architecture look bad.

### 8.3 Canonical scenarios

| ID | Scenario | Frozen intent |
|---|---|---|
| W00 | idle | no traffic; sanity/powerless baseline, no performance conclusion |
| W01 | M0 control only | sparse 1-beat 50/50 read/write control traffic |
| W02 | M1 DMA only | continuous 16-beat 50/50 read/write traffic |
| W03 | M2 critical only | groups of short high-QoS requests separated by deterministic idle gaps |
| W04 | balanced mixed | all three managers active with their native class profiles, common S0 contention plus a fixed fraction to S1 |
| W05 | saturated DMA + control | M1 continuously backlogged; M0 sparse control to S0 |
| W06 | saturated DMA + bursty critical | M1 continuously backlogged; M2 emits repeated high-QoS bursts to S0 |
| W07 | all saturated heterogeneous | all managers continuously backlogged with native burst/QoS profiles |
| W08 | adversarial starvation | M1 continuously requests at QOS=0 while M0/M2 continuously produce higher-QoS traffic; demonstrates whether B escape works |
| W09 | read-heavy | all managers active, 80% read / 20% write transaction selection |
| W10 | write-heavy | all managers active, 20% read / 80% write transaction selection |
| W11 | mixed 50/50 | all managers active, 50% read / 50% write |
| W12 | equal-demand fairness | all three saturated, common S0, 1-beat requests, equal QoS and identical read/write pattern; used for Jain grant fairness |
| W13 | parallel-target | traffic deliberately spread across S0/S1 to measure non-contending concurrency and detect accidental global serialization |

The exact gap distributions, target percentages and read/write PRNG mapping are frozen in `workloads.yaml` at Gate 1. Phase 0 may tune **simulation length only before any B implementation exists**, and that decision must be logged.

### 8.4 Benchmark sample policy

Default Gate-1 target:

- 500 warm-up completions per active manager per seed;
- then retain the first 5,000 latency samples per active manager per seed;
- continue the common measurement window until every active manager has at least 5,000 measured completions;
- throughput uses all handshakes in that common window;
- percentile plots pool only identically defined samples and also retain per-seed summaries.

If Phase 0 shows this is operationally unreasonable, the sample count may be changed **once before Architecture B RTL exists**, recorded in `DECISIONS.md`, then frozen for both architectures.

### 8.5 Canonical performance subordinate model

To avoid making random endpoint behavior part of the policy experiment, canonical performance runs use fixed endpoint behavior:

- supported AW/AR accepted whenever the model queue has capacity;
- WREADY asserted whenever a legal owned write burst is active;
- fixed, documented read-start and B-response latency;
- read data served one beat/cycle once a burst starts;
- response queue/order policy fixed and identical for A/B;
- queue depths frozen before A/B measurement.

Randomized READY/response delay belongs in functional verification, not the canonical A/B performance result.

---

## 9. Metric definitions

All metrics are captured from handshake events, never inferred from nominal request creation timestamps without labels.

### 9.1 Timestamp vocabulary

For request `q`:

- `t_present`: first cycle the manager asserts legal AWVALID/ARVALID for q.
- `t_addr_accept`: cycle of manager-facing AW/AR handshake; because address forwarding is not hidden behind an ingress request queue, this is the admitted address event for the fabric.
- `t_wlast`: cycle of WLAST handshake for a write.
- `t_first_resp`: first R or B handshake associated with q.
- `t_complete`: B handshake for write or RLAST handshake for read.

### 9.2 Latency metrics

Report separately:

- **admission latency** = `t_addr_accept - t_present`;
- **scheduler-contention cycles** = cycles while request is eligible, a target address service opportunity exists, and another manager wins;
- **backpressure-blocked cycles** = pending cycles in which the target cannot offer service;
- **read response latency** = `t_complete - t_addr_accept` for reads;
- **write data-phase latency** = `t_wlast - t_addr_accept`;
- **write response latency** = `t_complete - t_wlast`;
- **write end-to-end accepted latency** = `t_complete - t_addr_accept`;
- **presentation-to-completion latency** = `t_complete - t_present`, labelled as including admission wait.

Do not combine read and write latency distributions unless the figure explicitly says it is a heterogeneous aggregate.

### 9.3 Tail metrics

For each manager, direction and workload where sample count is adequate:

- P50;
- P95;
- P99;
- maximum;
- empirical CDF;
- sample count;
- per-seed P99 and maximum.

Use one documented percentile convention (nearest-rank or an explicitly pinned numpy method) throughout the repository.

### 9.4 Starvation metrics

Report both:

1. **wall-cycle pending interval:** maximum consecutive cycles a legal request is pending without address handshake;
2. **service-opportunity starvation:** maximum number of eligible arbitration opportunities a continuously pending requester loses before handshake.

Only the second isolates scheduler fairness from target backpressure.

### 9.5 Throughput

- write payload throughput = successful W data bytes / measurement cycles;
- read payload throughput = successful R data bytes / measurement cycles;
- aggregate throughput = read + write payload bytes / cycles;
- per-manager throughput reported separately;
- protocol/control beats are not counted as payload bytes.

### 9.6 Fairness

For W12 equal-demand fairness, compute Jain's index over per-manager successful address grant rates:

`J = (sum(g_i))^2 / (N * sum(g_i^2))`

For heterogeneous workloads, do not use one Jain number as a moral/quality verdict because the offered workloads intentionally differ. Report per-manager grant share, throughput, admission latency and starvation instead.

### 9.7 PPA/timing metrics

Record:

- LUT-equivalent resources/cells as reported by the chosen flow;
- FFs;
- inferred memory if any;
- top critical path and endpoints;
- target frequency;
- routed WNS/slack;
- seed;
- routing utilization where available;
- tool versions and command line.

No result is “better” from one metric alone. Trade-off discussion must include latency, starvation/fairness, throughput, timing and area.

---

## 10. Independent Python reference model

The project-owned Python model is the correctness oracle. External BFMs generate/consume legal AXI traffic; they do not define expected behavior.

For every accepted transaction record at least:

- unique software sequence number;
- manager;
- target;
- original ID;
- internal widened ID;
- address;
- length;
- size;
- burst type;
- QoS;
- write data and strobes where applicable;
- presentation cycle;
- address acceptance cycle;
- expected response;
- expected memory effect;
- reset epoch.

### 10.1 Model responsibilities

The model knows:

- frozen address map;
- byte-addressed contents of S0/S1 test memories;
- S2 model semantics used by tests;
- default/error routing;
- one-outstanding-per-ID restriction;
- legal different-ID reordering;
- byte-strobe update semantics;
- expected response code;
- burst beat count and LAST location;
- reset epoch.

It must not mirror private RTL implementation queues or arbiter registers unnecessarily.

### 10.2 Scoreboard must detect

- loss;
- duplication;
- misrouting;
- wrong ID;
- response to a non-outstanding ID;
- incorrect data;
- incorrect byte-strobe memory update;
- incorrect RESP;
- early/late/missing LAST;
- same-ID/order violation relative to the project contract;
- unsupported internal manager-index encoding;
- pre-reset transaction observed after reset;
- write beat routed to the wrong AW context.

---

## 11. Verification strategy

### 11.1 Layering

1. primitive unit tests;
2. decoder/ID/outstanding/write-owner tests;
3. channel/request arbiter tests;
4. target path tests;
5. end-to-end fabric directed tests;
6. randomized backpressure/delay tests;
7. long contention tests;
8. frozen A/B equivalence-of-function regression;
9. benchmark runs only after functional gates pass.

### 11.2 Required directed tests

At minimum:

- reset idle;
- single manager/single target reads and writes;
- every mapped target;
- unmapped read DECERR with correct beat count/RLAST;
- unmapped write drains legal W burst then returns DECERR;
- 1-beat and 16-beat INCR bursts;
- every legal ID;
- four distinct outstanding IDs per manager;
- same ID blocked until prior final response;
- same original ID used simultaneously by different managers and correctly distinguished downstream;
- different IDs completing out of order;
- AWVALID before WVALID;
- WVALID asserted before AW handshake and safely backpressured until route exists;
- AW and W same cycle;
- W channel stall on every beat position including final beat;
- B backpressure;
- AR backpressure;
- R backpressure on first/middle/final beat;
- simultaneous AW/AR contention;
- simultaneous all-manager contention;
- simultaneous responses from multiple subordinates to one manager;
- R response burst lock;
- valid/payload stability while stalled;
- 4-KiB legal boundary edge case;
- unsupported burst/size/alignment caught by assertions/test harness;
- reset with address accepted but data incomplete;
- reset with W partially complete;
- reset with responses pending;
- no stale pre-reset completion after coordinated reset;
- target blocked for long finite duration;
- adversarial scheduler contention;
- A and B execute identical functional vectors and produce the same architecturally legal data/result set.

### 11.3 Random verification

Random tests vary independently:

- manager request timing;
- AW vs W relative timing;
- channel backpressure;
- subordinate response delay;
- legal IDs;
- legal burst length 1–16;
- target address;
- QOS;
- WSTRB;
- read/write mix;
- reset injection points.

Seeds are printed and replayable. Every discovered bug gets a minimized or deterministic regression.

### 11.4 Protocol checkers

Project assertions cover the documented subset and internal invariants. An external AXI checker may be used as a second opinion if its licence/tool compatibility is acceptable, but public claims must identify its coverage and limitations.

---

## 12. Formal strategy

Formal is targeted, compositional and assumption-aware. Do not attempt whole-fabric exhaustive proof first.

### 12.1 Candidate proof blocks

#### Round-robin arbiter

- at most one grant;
- grant implies request;
- selected request remains stable while downstream is stalled;
- pointer advances only on handshake;
- under READY/service assumptions, a persistent requester is not bypassed indefinitely.

#### QoS/age arbiter

- one-hot grant;
- held grant stability;
- age saturates and never wraps;
- no starved requester is bypassed by a non-starved request;
- normal mode never grants a lower-QOS request when a higher-QOS eligible request exists;
- equal-QOS ties obey RR order;
- under explicit always/recurringly-ready assumptions, a persistent request receives service within a stated bounded number of grant opportunities.

#### Address decoder

- exactly one logical target for every 32-bit address including default;
- mapped regions are mutually exclusive;
- unmapped address selects S3.

#### Outstanding/ID tracker

- counts never underflow or exceed 4;
- busy ID cannot be accepted twice in same direction;
- final response frees exactly one busy ID;
- response cannot be accepted as valid project traffic for a non-busy ID.

#### Write owner/router

- every accepted W beat routes only to the target captured by its accepted AW;
- no target has more than one W owner;
- ownership persists until accepted WLAST;
- new AW to an owned target is blocked;
- WREADY is not asserted without a valid write context.

#### Channel buffer/register, if present

- payload stable while stalled;
- no overwrite;
- token conservation.

#### Response routing

- returned manager index is valid;
- response only goes to the indexed manager;
- R lock persists until accepted RLAST.

### 12.2 Liveness discipline

Every liveness/bounded-starvation property must state assumptions such as:

- requester keeps VALID/payload stable;
- target creates service opportunities;
- active write burst eventually progresses;
- reset does not intervene during the proof window.

A property proved only because its antecedent can never occur is a formal failure of methodology. Add cover statements for meaningful antecedent reachability.

### 12.3 Proof evidence

For every proof record:

- tool/version;
- top module;
- exact `.sby`/script;
- engine;
- depth/mode;
- assumptions;
- assertions/covers;
- PASS/FAIL/UNKNOWN;
- runtime;
- log path;
- known abstraction limitations.

Never summarize a bounded check as unbounded proof.

---

## 13. Implementation and timing/PPA plan

### 13.1 Open FPGA target

Freeze the intended first implementation target as:

- family/device class: **Lattice ECP5 `LFE5U-45F`**;
- package: **CABGA381**;
- speed grade: **6**;
- flow: Yosys -> nextpnr-ecp5 -> Project Trellis;
- physical hardware board: **not required**.

Current nextpnr source exposes `--45k`, CABGA381 support and speed grades 6/7/8. Phase 0 must smoke this exact tuple before Gate 1 is signed off.

### 13.2 P&R wrapper problem and required Phase-0 experiment

A 3x4 AXI fabric exposed entirely as top-level FPGA pins would create an unrealistic I/O problem and may be optimized away if tied to constants. Therefore the routed comparison needs a **common compact P&R harness** that:

- instantiates the same fabric interface in A and B;
- drives fabric inputs from registered internal stimulus state rather than hundreds of package pins;
- consumes outputs in registered observable signature/state so logic cannot be optimized away;
- adds identical wrapper logic to A and B;
- has a small fixed set of real top-level pins/clocks;
- produces stable synthesis/P&R deltas across repeated builds.

Phase 0 must prototype this methodology before any PPA claims. If absolute fabric resource extraction cannot be made trustworthy, report:

1. direct Yosys hierarchical synthesis statistics for the fabric; and
2. routed timing/resources of the identical common wrapper for **relative** A/B comparison.

Do not subtract wrapper resources arithmetically unless synthesis evidence shows subtraction is meaningful.

### 13.3 Freeze before A/B implementation comparison

Record and lock:

- exact FPGA device/package/speed;
- exact OSS CAD/tool versions;
- top wrapper commit;
- RTL parameters;
- topology;
- widths;
- outstanding limits;
- address map;
- pipeline/buffer configuration;
- constraints;
- synthesis flags;
- nextpnr flags;
- fixed P&R seed set;
- frequency sweep method.

Recommended fixed P&R seeds: `1,2,3,4,5` unless Phase 0 shows the backend uses a different documented seed mechanism. Freeze before Architecture-B results.

### 13.4 Timing methodology

Start with a 100-MHz constraint as a tool smoke, not a performance claim. At Gate 4 use a predeclared frequency sweep and fixed seeds. One acceptable frozen method is:

- coarse targets: 50, 75, 100, 125, 150, 175, 200 MHz;
- if a transition is observed, refine with 5-MHz steps around the boundary;
- report WNS for every seed and target attempted;
- define “all-seed timing-clean target” as the highest tested target with non-negative reported slack for all fixed seeds.

If the flow's timing model makes that definition inappropriate, change it once in `DECISIONS.md` before comparing B.

### 13.5 CDC extension

CDC is prohibited before single-clock core fabric reaches deep verification and baseline implementation evidence.

Later extension may introduce:

- manager-side clock;
- fabric clock;
- optional subordinate-side clock;
- independent CDC treatment for AW, W, B, AR and R;
- channel-specific buffering and reset coordination.

Never place one FIFO around the conceptual “whole AXI bus.” Each independent channel requires its own CDC reasoning, and AW/W relationship must remain correct across domains.

If a previously verified async FIFO from another portfolio project exists, it may be reused only after source/provenance/licence/tool assumptions are revalidated here. Otherwise study `common_cells` CDC primitives as prior art and make an explicit reuse/originality decision.

### 13.6 SDC policy for CDC phase

- define each real clock;
- use generated clocks only when a real generated-clock relationship exists;
- explicitly group truly asynchronous clocks;
- constrain synchronizer/CDC structures by architecture, not blanket false paths;
- no broad false-path command that hides ordinary synchronous timing;
- document how latency is measured across clock domains.

---

## 14. Benchmark integrity contract

Architecture A and B comparisons freeze all of the following:

- topology;
- DATA/ADDR/ID widths;
- internal ID mapping;
- outstanding limits;
- address map;
- supported AXI subset;
- response-arbitration policy;
- buffer/pipeline depths;
- endpoint models and queue depths;
- workload definitions;
- workload seeds;
- measurement scripts;
- implementation target;
- tool versions;
- constraints;
- synthesis/P&R flags;
- P&R seed policy.

Only the named scheduler state/selection policy changes.

If a bug fix changes common functionality after one architecture was measured, rerun **both** architectures from clean evidence directories.

Architecture B is not accepted merely because critical P99 falls. The conclusion must include at least:

- M0/M1/M2 latency distributions;
- max/service-opportunity starvation;
- aggregate/per-manager throughput;
- equal-demand fairness result;
- resource delta;
- routed timing delta;
- complexity/verification cost;
- any workload where B regresses A.

---

## 15. Hostile first-draft audit and repairs

The following audit was performed before this plan was marked ready.

| Severity | First-draft hole | Why dangerous | Repair now frozen |
|---|---|---|---|
| BLOCKER | “Use latest AXI spec” could point to Issue L | AXI4 content was removed from Issue J onward | Pin H.c/ID012621 for AXI4 semantics; record L only as current-family history |
| BLOCKER | vague “IDs + outstanding” | same-ID transactions to different targets could return out of order | at most one outstanding transaction per manager ID per direction; 4 distinct IDs max concurrently |
| BLOCKER | AW/W treated as if paired simultaneously | legal W can precede AW and AXI4 has no WID | W is backpressured until accepted AW context; explicit write owner held through WLAST |
| BLOCKER | multiple AWs could reach a target before data | merged-manager W ordering could become ambiguous | only one active AW/W data owner per subordinate until accepted WLAST |
| BLOCKER | arbiter could change winner while target stalled | violates downstream VALID/payload stability | held grant is latched until handshake in A and B |
| BLOCKER | “bounded starvation” stated without environment assumptions | impossible if target backpressures forever | define service-opportunity bound; any cycle bound must state READY/progress assumptions |
| BLOCKER | B could accidentally gain extra buffering/pipeline | invalid controlled A/B comparison | identical datapath/buffers; any B-only pipeline is a new named variant |
| BLOCKER | external BFM could become de-facto oracle | correlated bug risk; weak originality | project-owned independent Python transaction model is authoritative checker |
| BLOCKER | reset outstanding semantics vague | stale responses/ID reuse ambiguity | coordinated full-system reset abandons pre-reset traffic; explicit public limitation for non-coordinated stale responders |
| BLOCKER | routed FPGA top could be optimized away or exceed I/O | meaningless PPA | common compact internal P&R harness must be validated in Phase 0 |
| MAJOR | aging undefined | cannot reason about starvation or reproduce | 8-bit saturating counters, threshold 64, exact update and escape rules |
| MAJOR | response collisions unspecified | two slaves can answer one manager simultaneously | per-manager B RR and burst-locked R RR paths |
| MAJOR | latency start/end ambiguous | P99 comparisons can be manipulated | fixed timestamp vocabulary and separate admission/response/end-to-end metrics |
| MAJOR | fairness metric on heterogeneous burst sizes misleading | DMA bytes dominate by construction | Jain grant fairness reserved for equal-demand W12; heterogeneous results decomposed |
| MAJOR | unsupported AXI behavior undefined | false “compliance” claims | documented-subset input contract; assertions catch unsupported requests; only unmapped supported accesses DECERR |
| MAJOR | licence assumed at repository level | mixed per-file licences can exist | file-level SPDX/provenance check for every reused file |
| MAJOR | formal liveness can be vacuous | apparent proof without reachable antecedent | explicit assumptions + cover properties + proof metadata |
| MAJOR | response ordering across same ID/different targets | direct mux could violate same-ID order | per-ID serialization removes case from accepted state space |
| MAJOR | benchmark tuned after B | invalid experiment | workload/seeds/sample policy frozen before B implementation/results |
| MINOR | Issue H vs H.c source links can be confusing | wrong revision may be downloaded | metadata records exact `H.c`, date and `ID012621`; Phase 0 stores canonical Arm selector |
| ACCEPTABLE RISK | response burst lock is stricter than AXI requires | can add HOL latency | intentional baseline simplification, same in A/B and measured |
| ACCEPTABLE RISK | one data-active write per manager limits address concurrency | may reduce peak write throughput | intentional simplest-complete baseline; still supports multiple outstanding B transactions |
| ACCEPTABLE RISK | reset does not protect against rogue post-reset stale response collision | would need epoch/isolation protocol | explicit limitation; coordinated-reset assumption |

All BLOCKER and MAJOR items above are repaired in the planning contract. Any implementation deviation reopens the corresponding audit item.

---

## 16. Unresolved decisions — Phase-0 conditions, not hidden ambiguity

The project is intentionally not classified “unconditionally ready” because these items require local evidence:

1. **Exact OSS CAD Suite release/archive pin and checksum.** Candidate path is viable on Apple Silicon, but the repository must record a concrete archive and actual versions.
2. **cocotb 2.1.0 + cocotbext-axi v0.1.28 + chosen Verilator compatibility.** Run real read/write/ID/backpressure smoke.
3. **SystemVerilog coding subset.** Verify the intended packed-struct/array/interface style elaborates in Verilator, Slang/Yosys and formal tooling. Prefer simple packed types/flat wrappers if interfaces create tool friction.
4. **SBY solver path.** Prove a small smoke property using the chosen suite and record solver/version.
5. **ECP5 exact target command.** Smoke `LFE5U-45F`, CABGA381, speed 6 through Yosys/nextpnr/Trellis.
6. **P&R anti-optimization wrapper.** Demonstrate that common wrapper retains fabric logic and yields stable repeatable stats without impossible package I/O.
7. **Performance-run size.** The proposed 500 warm-up/5,000 samples per manager per seed is frozen unless Phase 0 changes it *before* Architecture B RTL exists.
8. **Third-party exact commits.** Record v/tag/SHA/licence before any code is imported.
9. **Process-reference gap.** The separate “From RTL to Pixels” files were not available in the accessible file set during this planning pass. The engineering method/evidence/gate requirements explicitly reproduced in the Fabric brief have been followed; if those reference files are later added, compare workflow-only differences and log any imported process refinement. Their image/CPU architecture must not become technical authority here.

Failure of items 1–6 to produce a workable open-source path blocks Gate 0 and triggers a tool/method decision, not an RTL workaround.

---

## 17. Repository structure

Target structure after bootstrap:

```text
.
├── 00_MASTER_PROJECT_PLAN.md
├── 01_CHATGPT_PROJECT_OPERATING_INSTRUCTIONS.md
├── 02_PHASE0_BOOTSTRAP_TASK.md
├── 03_START_NEW_CHATGPT_PROJECT.md
├── 04_MASTER_CHECKLIST.md
├── MASTER_CHATGPT_HANDOFF_PROMPT.md
├── AGENTS.md
├── README.md
├── docs/
│   ├── REQUIREMENTS.md
│   ├── MICROARCHITECTURE.md
│   ├── VERIFICATION_PLAN.md
│   ├── FORMAL.md
│   ├── TIMING_PERFORMANCE.md
│   ├── TRADEOFFS.md
│   ├── DECISIONS.md
│   ├── PROJECT_STATE.md
│   ├── EVIDENCE_INDEX.md
│   ├── KNOWN_LIMITATIONS.md
│   ├── THIRD_PARTY_MANIFEST.md
│   ├── THIRD_PARTY_NOTICES.md
│   └── references/
│       └── AXI_SPEC.md
├── rtl/
├── tb/
│   ├── cocotb/
│   ├── model/
│   └── directed/
├── formal/
├── bench/
│   ├── workloads.yaml
│   └── analysis/
├── scripts/
├── constraints/
├── tasks/
│   └── FABRIC-xxx.md
├── results/
│   ├── raw/
│   └── processed/
└── third_party/
```

Raw logs, wave dumps and tool chatter go in `results/raw/`. Concise, reviewable extracted evidence goes in `results/processed/`. Large generated artifacts need not be committed if a deterministic regeneration path is recorded.

---

## 18. Gate structure and acceptance criteria

### Gate 0 — environment/reference baseline

Required:

- official AXI4 authority pinned to H.c with source metadata;
- Issue-L/J removal rationale documented;
- chosen toolchain locally smoke-tested on Apple Silicon;
- simulator + cocotb smoke passes;
- cocotbext-axi compatibility smoke passes or a replacement is decided;
- SBY proof smoke passes;
- Yosys synthesis smoke passes;
- nextpnr ECP5 P&R smoke passes;
- compact P&R harness method validated;
- upstream repo/tag/licence snapshot recorded;
- `THIRD_PARTY_MANIFEST.md` exists;
- no core third-party RTL imported.

**Gate evidence:** exact commands, versions, logs and checksums.

### Gate 1 — architecture/protocol frozen

Required docs are internally consistent and reviewed:

- exact documented AXI4 subset;
- exact signal list and attribute policy;
- topology/address map;
- 4R/4W per-manager outstanding limits;
- one outstanding per ID per direction;
- 6-bit downstream ID map;
- AW/W ownership behavior;
- B/R response routing;
- reset contract;
- A scheduler definition;
- B QoS/age definition;
- workloads/seeds/sample policy;
- metric definitions;
- verification plan;
- formal plan;
- implementation target and wrapper method.

No RTL feature work begins until Gate 1 is signed.

### Gate 2 — baseline functional fabric (Architecture A)

Required evidence:

- simplest complete A fabric compiles/lints;
- directed routing/burst/ID/error tests pass;
- Python model/scoreboard checks memory, IDs, LAST and responses;
- AW/W timing permutations pass;
- four outstanding distinct IDs pass;
- unmapped/default target passes;
- reset-idle passes;
- exact logs indexed.

No claim of deep correctness yet.

### Gate 3 — deep verified baseline

Required evidence:

- randomized independent channel backpressure;
- random legal IDs/bursts/QOS/targets;
- random subordinate response delay;
- simultaneous all-manager contention;
- reset with partial traffic;
- long randomized runs with replayable seeds;
- adversarial fairness tests for A;
- all discovered bugs have regression tests;
- targeted formal primitives begin passing with assumptions documented.

A must be stable before B exists.

### Gate 4 — engineering depth and controlled A/B experiment

Sequence:

1. synthesize/P&R Architecture A under frozen target;
2. run frozen workloads on A;
3. identify measured bottleneck;
4. restate B as hypothesis, not foregone improvement;
5. implement only the frozen scheduler change;
6. run the exact functional/formal regression on B;
7. run exact workloads/seeds/sample method on B;
8. synthesize/P&R B with exact same implementation settings;
9. compare all positive and negative effects;
10. retain/modify/reject B based on evidence.

Optional CDC starts only after A/B core results are trustworthy.

### Gate 5 — CV/public ready

Required:

- README explains engineering question, subset and limitations accurately;
- architecture diagrams show independent AXI paths and write ownership;
- A/B delta is explicit;
- latency CDF/percentile figures include sample counts and definitions;
- throughput/fairness/starvation data published;
- formal summary names proved blocks and assumptions;
- PPA/timing tables link to raw/processed evidence;
- exact reproduction commands exist;
- third-party notices complete;
- clean-clone reproduction is performed;
- no claim exceeds evidence;
- `EVIDENCE_INDEX.md` maps public claims to artifacts.

---

## 19. Decision log seeds

Create initial entries in `docs/DECISIONS.md` for:

- D001 — use H.c as AXI4 normative authority;
- D002 — call design a documented AXI4 subset;
- D003 — 3 manager / 4 logical subordinate topology;
- D004 — 64/32/4 widths and 6-bit widened internal ID;
- D005 — 4 read + 4 write outstanding per manager, one outstanding per ID/direction;
- D006 — 1–16 beat aligned full-width INCR subset;
- D007 — one active write-data context per manager and one W owner per target;
- D008 — Architecture A round-robin;
- D009 — Architecture B QOS + 8-bit age, threshold 64, starved-set RR;
- D010 — independent original Python oracle; cocotbext-axi is BFM only;
- D011 — ECP5-45F/CABGA381/speed-6 open implementation target;
- D012 — no CDC before single-clock A/B core is trusted;
- D013 — no Architecture C without A/B measured motivation.

Each decision records context, alternatives, rationale, consequences and evidence class.

---

## 20. Task/Codex discipline

Every `tasks/FABRIC-xxx.md` must contain:

- one narrow objective;
- authoritative docs to read;
- exact files allowed to change;
- files explicitly not to change;
- acceptance tests/commands;
- expected evidence paths;
- prohibited scope expansion;
- requirement IDs affected;
- completion summary format.

Do not paste the whole AXI spec or master plan into every task. Give the relevant requirement/microarchitecture section and current `PROJECT_STATE.md`.

For implementation work, local execution owns compile/sim/formal/synth/P&R evidence. ChatGPT owns requirements, interpretation, architecture, test methodology, analysis and review.

---

## 21. Architecture C gate

Architecture C is allowed only if all are true:

1. A and B have passed the same functional regression.
2. A and B have complete canonical benchmark and PPA evidence.
3. A measured bottleneck remains that scheduler priority/aging alone cannot address.
4. The suspected mechanism is documented (for example non-preemptive bulk burst occupation or class HOL blocking).
5. A single controlled C hypothesis is written.
6. C does not silently change topology, width, outstanding depth and buffer capacity simultaneously.

Possible inspirations can include separated latency/bulk traffic classes or virtual-channel-like ideas, but no design is pre-approved.

---

## 22. Public narrative

A strong final portfolio narrative should be factual:

1. define a constrained but meaningful AXI4 subset;
2. build the simplest correct multi-manager/multi-subordinate baseline;
3. prove/check protocol-critical primitives and stress independent channels;
4. measure contention and tail latency;
5. identify starvation/tail behavior under bulk traffic;
6. introduce one exact QoS+aging scheduler change;
7. re-run identical correctness and implementation evidence;
8. discuss where QoS helps, where non-preemptive bursts still dominate, and the area/timing cost;
9. optionally extend CDC only after the core experiment is complete.

Do not market the project as a production AXI fabric. Market it as a carefully specified, original, measured interconnect experiment with transparent limitations.

---

## 23. Readiness classification

# READY WITH PHASE-0 CONDITIONS

The protocol contract, baseline architecture, QoS/aging policy, ordering simplifications, benchmark method, verification strategy, formal scope and first implementation target are specific enough for a fresh engineer/ChatGPT Project to proceed without reconstructing major decisions from chat history.

It is not yet “unconditional” because local Apple-Silicon tool compatibility, exact version pins, cocotbext-axi compatibility, formal solver smoke and the compact ECP5 P&R harness must be demonstrated with real commands before Gate 0 closes.

No RTL, simulation, formal, timing, throughput, P99, Fmax or resource result is claimed by this planning document.

---

## 24. Research source register

Record these sources in `docs/references/` during bootstrap and pin exact commits/tags where applicable:

- Arm, **AMBA AXI and ACE Protocol Specification, ARM IHI 0022H.c, ID012621, 26 Jan 2021** — normative AXI4 source.
- Arm, **AMBA AXI Protocol Specification Issue L, 27 Aug 2025** — current-family/version-history context; AXI4 had been removed beginning with Issue J.
- `https://github.com/pulp-platform/axi`
- `https://github.com/pulp-platform/common_cells`
- `https://github.com/pulp-platform/iDMA`
- `https://github.com/pulp-platform/FlooNoC`
- `https://github.com/ZipCPU/wb2axip`
- `https://github.com/alexforencich/cocotbext-axi`
- `https://github.com/YosysHQ/oss-cad-suite-build`
- `https://github.com/YosysHQ/nextpnr`
- `https://github.com/YosysHQ/prjtrellis`
- cocotb 2.1 documentation/release notes;
- Homebrew formula metadata for Verilator, Yosys and SBY as a secondary Apple-Silicon feasibility source.

The source register is research evidence, not permission to copy third-party core logic.
