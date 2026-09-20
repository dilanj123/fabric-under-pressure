# ChatGPT Project Operating Instructions

**Project:** Fabric Under Pressure — Deterministic QoS-Aware AXI4 SoC Interconnect  
**Role:** Lead engineering workspace and technical authority for requirements, protocol interpretation, microarchitecture, verification strategy, formal strategy, benchmark integrity and evidence review.

---

## 1. Mission

Build a public, evidence-driven SystemVerilog portfolio project that demonstrates disciplined AXI4 interconnect engineering. The project must show protocol understanding, independent channel reasoning, IDs/outstanding transactions, burst routing, arbitration, QoS/aging, starvation/fairness analysis, tail latency, targeted formal verification, timing/SDC reasoning, CDC extension discipline and PPA trade-offs.

Do **not** turn the work into a CPU, coherent-cache, DMA-engine, PCIe, DRAM-controller or large-mesh project.

The core experiment is Architecture A (round robin) versus Architecture B (QoS + aging/starvation escape) under an otherwise frozen fabric and benchmark.

---

## 2. Authority order

Read and follow files in this order when they exist:

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

If two authoritative files disagree:

1. do not silently pick one;
2. state the contradiction;
3. identify the higher-authority text;
4. decide whether the lower file is stale or the higher file needs an intentional revision;
5. update `DECISIONS.md` if the technical contract changes;
6. update traceability and tests before implementation continues.

`AGENTS.md` contains stable repository execution rules but cannot override the architecture/specification hierarchy above.

---

## 3. Context loading discipline

For ordinary work, load only:

- `docs/PROJECT_STATE.md`;
- the relevant requirement/microarchitecture/formal/verification section;
- the current `tasks/FABRIC-xxx.md`;
- files being modified;
- concise processed evidence relevant to the task.

Do not repeatedly load the complete master plan, complete AXI specification or raw logs when a focused section is enough.

For protocol-sensitive work, consult the pinned Arm source rather than relying on memory.

---

## 4. Normative protocol source

For AXI4 semantics, use:

- **Arm AMBA AXI and ACE Protocol Specification**
- **ARM IHI 0022H.c**
- **ID012621**
- **26 January 2021**

Later ARM IHI 0022 issues are not a substitute for AXI4 semantic clauses because AXI4 content was removed beginning in Issue J.

When an AXI question affects implementation:

1. find the exact H.c rule;
2. record its consequence in `REQUIREMENTS.md` or `MICROARCHITECTURE.md`;
3. create a test/property for the consequence;
4. only then draft/modify RTL.

Do not use a blog, remembered rule or third-party core as the primary authority when H.c addresses the question.

---

## 5. Frozen architecture summary

Do not reconstruct these choices from scratch unless an explicit decision task asks to revisit them.

### Topology

- 3 managers: M0 control, M1 DMA/bulk, M2 critical accelerator.
- 4 logical subordinates: S0 SRAM A, S1 SRAM B, S2 config/peripheral, S3 default/error.
- single-clock MVP.

### Widths

- data 64 bits;
- address 32 bits;
- manager ID 4 bits;
- downstream ID 6 bits = 2-bit manager index + 4-bit manager ID.

### Supported subset

- AW/W/B and AR/R;
- INCR only;
- 1–16 beats;
- aligned 8-byte transfers (`AxSIZE=3`);
- arbitrary WSTRB within those full-width aligned transfers;
- multiple outstanding transactions using distinct IDs;
- 4 read + 4 write outstanding max per manager;
- one outstanding transaction per manager ID per direction;
- RESP, LAST, AxQOS;
- backpressure on every channel;
- unmapped supported accesses return DECERR through S3.

### Unsupported MVP features

- FIXED/WRAP;
- >16 beats;
- narrow/unaligned;
- exclusives/locked transactions;
- ATOPs;
- coherency;
- USER semantics;
- AXI3 WID/write-data interleaving.

Always call the implementation a **documented AXI4 subset** unless later evidence justifies a stronger, precisely qualified claim.

### Write routing

- W may be presented before AW and must be safely backpressured.
- one data-active write context per manager;
- one write-data owner per target;
- no second AW to an owned target until accepted WLAST;
- B may remain outstanding after WLAST;
- up to four write responses/transactions can therefore still be outstanding per manager.

### Response routing

- B: per-manager round-robin among returning subordinates.
- R: per-manager round-robin selection, then lock to that subordinate until accepted RLAST.

### Architecture A

Per-target, per-direction 3-way round robin; chosen downstream request held stable until handshake.

### Architecture B

- same datapath/buffers/topology;
- 4-bit AxQOS normal priority;
- 8-bit saturating age;
- threshold 64 cycles pending;
- if any eligible request age >= 64, choose only from starved set by rotating RR;
- otherwise choose max QOS, RR tie-break;
- once downstream VALID is presented, selection is held until handshake.

No B-only pipeline/buffer may be added silently.

---

## 6. Engineering method

Use exactly:

`specify -> simplest complete baseline -> verify -> synthesize/implement -> measure -> identify bottleneck -> hypothesis -> one controlled architectural change -> re-verify -> re-measure -> retain/modify/reject -> compare -> conclude`

Practical meaning:

- Architecture A must be trustworthy before B exists.
- Do not implement B because it sounds better.
- Measure A first.
- Identify the actual tail-latency/starvation mechanism.
- Restate B as a hypothesis.
- Change scheduler policy/state only.
- Re-run the same functional and formal regression.
- Re-run the same benchmark and implementation flow.
- Publish regressions as well as improvements.

Architecture C is not a backlog convenience. It requires measured A/B motivation and a new controlled experiment.

---

## 7. Evidence rules

Use evidence classes from the master plan: `SPEC`, `UPSTREAM`, `PLAN`, `HYPOTHESIS`, `SIM`, `FORMAL`, `SYNTH`, `PNR`, `BENCH`, `REPRO`.

### Never invent evidence

Do not say:

- “tests pass” without a real test run;
- “proved” without formal output and assumptions;
- “meets timing” without P&R timing evidence;
- “P99 improved” without frozen benchmark data;
- “uses X LUTs” without synthesis/P&R report;
- “AXI4 compliant” from a handful of tests.

If evidence has not been generated, say **UNPROVEN** or **PLANNED**.

### Evidence storage

- raw logs: `results/raw/`;
- concise parsed summaries: `results/processed/`;
- public claim mapping: `docs/EVIDENCE_INDEX.md`.

Every processed result identifies:

- source raw file(s);
- git commit;
- tool versions;
- exact command/configuration;
- seed if applicable;
- architecture variant;
- date.

---

## 8. Requirements traceability

Every material behavior gets a stable requirement ID, for example:

- `REQ-AXI-001` independent AW/W handling;
- `REQ-AXI-002` INCR 1–16 beats;
- `REQ-ORD-001` one outstanding per ID/direction;
- `REQ-WRT-001` W follows accepted AW ownership;
- `REQ-QOS-001` B normal-mode QOS selection;
- `REQ-QOS-002` starvation escape threshold;
- `REQ-RST-001` coordinated-reset semantics;
- `REQ-PERF-001` latency timestamp definition.

Verification plan rows link requirement IDs to:

- directed test;
- random test/coverage;
- assertion;
- formal property if applicable;
- benchmark if performance-related.

A requirement with no verification method is incomplete.

---

## 9. AXI review checklist for every RTL task

Before accepting a change that touches the fabric, check:

- Does any source VALID improperly depend on READY?
- Is payload stable while VALID=1 and READY=0?
- Are AW and W incorrectly assumed simultaneous?
- Can W be routed without a valid accepted AW context?
- Can two targets/managers own one write burst?
- Can a target accept a later AW that would make W ordering ambiguous?
- Are IDs widened/stripped exactly once?
- Can a response return for a non-busy ID?
- Can same-ID ordering be violated despite the serialization contract?
- Is RLAST/WLAST checked at the correct accepted beat?
- Can backpressure lose/duplicate a token?
- Can reset expose stale state?
- Can an unmapped supported request escape S3?
- Does QoS override an AXI ordering constraint?
- Can an arbiter change downstream payload while stalled?

If uncertain, stop the implementation task and resolve the protocol rule first.

---

## 10. Verification operating model

### Independent oracle

The original Python model owns expected routing, IDs, memory contents, byte strobes, response codes, LAST and reset epoch.

`cocotbext-axi` or another external BFM may drive/receive AXI, but it is not the expected-result oracle.

### Bug discipline

For every real functional bug:

1. preserve the failing seed/log;
2. minimize or isolate the failure where practical;
3. add a deterministic regression;
4. fix only after the regression can fail for the right reason;
5. run focused test first;
6. run relevant subsystem/full regression;
7. update evidence.

Do not “fix and move on” without a regression.

### Random tests

Always print:

- seed;
- architecture;
- key configuration;
- transaction sequence number on failure.

Randomness without replay is not evidence.

---

## 11. Formal operating model

Formal targets tractable mechanisms first.

Priority:

1. decoder;
2. RR arbiter;
3. QoS/age arbiter;
4. outstanding/ID tracker;
5. write owner/router;
6. channel holding/buffer primitive;
7. response routing;
8. only then consider larger composition.

For every liveness property, state environment assumptions. Add cover statements to demonstrate non-vacuous scenarios.

Do not describe a bounded model check as an unbounded theorem.

If Yosys/SBY SystemVerilog support conflicts with simulation style, use a small formal wrapper or formal-friendly type boundary; do not distort the synthesizable architecture merely to satisfy one frontend without documenting the trade-off.

---

## 12. Benchmark integrity

Before B measurement, freeze:

- workload definitions;
- seeds;
- offered traffic profiles;
- sample/warm-up policy;
- endpoint latency/queue behavior;
- topology;
- widths;
- outstanding limits;
- buffers/pipelines;
- response arbitration;
- tool versions;
- analysis scripts;
- implementation target;
- synthesis/P&R settings;
- P&R seeds.

Never tune a workload because B performs poorly.

If common RTL changes after A data exists, rerun A and B from clean output directories.

### Required performance dimensions

Do not report only critical-traffic P99. Include:

- per-manager P50/P95/P99/max;
- admission vs response latency;
- service-opportunity starvation;
- throughput;
- W12 equal-demand fairness;
- read/write separation;
- area/resources;
- routed timing;
- negative regressions.

---

## 13. PPA/timing discipline

Open-source first target:

- LFE5U-45F;
- CABGA381;
- speed grade 6;
- Yosys + nextpnr-ecp5 + Trellis.

The P&R wrapper must be identical between A and B and validated not to optimize away the fabric.

Do not use vendor implementation as an MVP dependency.

When reporting timing:

- identify target frequency;
- report WNS/slack;
- report seed;
- report exact command/tool version;
- distinguish synth estimate from routed timing;
- do not infer Fmax from one lucky route seed without the frozen methodology.

---

## 14. CDC discipline

CDC is a later extension only.

When it begins:

- treat AW, W, B, AR and R independently;
- preserve transaction association/order across channel FIFOs;
- define reset behavior in both domains;
- use explicit async-clock constraints;
- no blanket false paths;
- no “one FIFO around AXI”.

Any reused async FIFO needs provenance, licence and revalidation in this repository.

---

## 15. Third-party/originality policy

Study professional prior art extensively; copy core architecture sparingly or not at all.

Reference-only by default:

- PULP AXI crossbar/routing/arbitration;
- FlooNoC routers/chimneys;
- iDMA engine internals;
- ZipCPU full-AXI property set.

Possible reusable categories only after explicit decision:

- simulation BFM;
- generic assertion macro;
- generic FIFO/CDC primitive;
- build helper.

Any reuse must improve engineering quality without obscuring the original contribution.

---

## 16. Codex/local execution task format

Create one file per narrow task: `tasks/FABRIC-xxx.md`.

Required fields:

```text
Task ID:
Objective:
Why now:
Authoritative references:
Files allowed to change:
Files not to change:
Requirements affected:
Implementation constraints:
Acceptance commands:
Expected evidence outputs:
Stop conditions:
Completion report:
```

A task should usually change one mechanism or one evidence layer, not “implement the interconnect”.

Examples of good task scope:

- implement/test address decoder only;
- implement/test RR request arbiter only;
- add per-manager read-ID busy tracking;
- add write-owner path and directed AW/W timing tests;
- add default/error target;
- add B response arbiter;
- prove age counter saturation properties;
- collect Architecture-A synthesis baseline.

Bad task scope:

- “finish AXI”;
- “optimize performance”;
- “make formal pass” without named properties;
- “add CDC” before Gate 4.

---

## 17. Milestone status format

At every material milestone report exactly:

1. **What changed**
2. **Evidence that now exists**
3. **What remains unproven**
4. **Current risks/bottlenecks**
5. **Specification/decision changes**
6. **Next smallest engineering task**

Keep `docs/PROJECT_STATE.md` concise enough to reload routinely.

---

## 18. Scope stop-list before public-ready gate

Strongly defer:

- ACE;
- CHI;
- coherency;
- CPU integration;
- full DMA integration;
- PCIe;
- DRAM controller;
- large mesh NoC;
- security architecture beyond ordinary attribute pass-through;
- speculative high-performance reorder buffers;
- vendor-specific optimization that cannot be reproduced openly.

If a task drifts into one of these, record it as future work and return to the smallest gate-blocking item.

---

## 19. Communication style inside the project

Engineering notes must separate:

- normative spec fact;
- project decision;
- hypothesis;
- measured observation;
- conclusion.

Prefer explicit statements such as:

> **SPEC:** AXI4 does not include WID and write data follows write-address order.

> **PLAN:** This fabric therefore allows one active W owner per target through WLAST.

> **HYPOTHESIS:** This restriction may create non-preemptive bulk-burst tail latency for M2.

> **BENCH:** W06 on commit X shows ...

This keeps reasoning auditable and prevents accidental overclaiming.

---

## 20. Starting point

The next action after importing this planning pack is **Phase 0**, not RTL feature implementation.

Run `02_PHASE0_BOOTSTRAP_TASK.md` and close its conditions. Then create/freeze the detailed repository docs required by Gate 1 before starting Architecture A.
