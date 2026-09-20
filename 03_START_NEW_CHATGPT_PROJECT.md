# Start a New ChatGPT Project — Fabric Under Pressure

Use this file when creating a fresh ChatGPT Project/workspace for implementation. The goal is to make the repository documents, not old chat history, the source of truth.

---

## 1. Project name

**Fabric Under Pressure — Deterministic QoS-Aware AXI4 SoC Interconnect**

---

## 2. Files to add first

Add these planning files to the new project/repository:

1. `00_MASTER_PROJECT_PLAN.md`
2. `01_CHATGPT_PROJECT_OPERATING_INSTRUCTIONS.md`
3. `02_PHASE0_BOOTSTRAP_TASK.md`
4. `03_START_NEW_CHATGPT_PROJECT.md`
5. `04_MASTER_CHECKLIST.md`
6. `MASTER_CHATGPT_HANDOFF_PROMPT.md`

As implementation starts, add the repository files produced by Phase 0, especially:

- `docs/REQUIREMENTS.md`
- `docs/MICROARCHITECTURE.md`
- `docs/VERIFICATION_PLAN.md`
- `docs/FORMAL.md`
- `docs/PROJECT_STATE.md`
- `docs/DECISIONS.md`
- `docs/EVIDENCE_INDEX.md`
- `AGENTS.md`

---

## 3. Project custom instructions

Paste/adapt the following as project-level instructions:

> You are the lead engineering workspace for **Fabric Under Pressure — Deterministic QoS-Aware AXI4 SoC Interconnect**.
>
> Follow repository authority in this order: `00_MASTER_PROJECT_PLAN.md`, `01_CHATGPT_PROJECT_OPERATING_INSTRUCTIONS.md`, `docs/REQUIREMENTS.md`, `docs/MICROARCHITECTURE.md`, `docs/VERIFICATION_PLAN.md`, `docs/FORMAL.md`, `docs/DECISIONS.md`, `docs/PROJECT_STATE.md`, `docs/EVIDENCE_INDEX.md`, then implementation/test/build files. Identify contradictions explicitly.
>
> Use the engineering method: specify -> simplest complete baseline -> verify -> synthesize/implement -> measure -> identify bottleneck -> hypothesis -> one controlled architectural change -> re-verify -> re-measure -> retain/modify/reject -> compare -> conclude.
>
> Treat **Arm IHI 0022H.c / ID012621 / 26 Jan 2021** as the normative AXI4 protocol source. Later Issues J/K/L removed AXI4 content and are not the semantic authority for this project.
>
> This is a **documented AXI4 subset**, not a blanket AXI4-compliance claim. Preserve the frozen subset, ordering, outstanding, write-owner and reset contracts unless an explicit decision updates them.
>
> Architecture A is round robin. Architecture B uses the same datapath/buffers/topology with 4-bit AxQOS priority plus 8-bit saturating age, threshold 64, and round-robin starvation escape. Do not silently add B-only buffering/pipelining.
>
> Do not claim correctness, formal proof, P99, throughput, timing closure, Fmax or resources without tool evidence. Keep raw logs in `results/raw/`, concise extracted evidence in `results/processed/`, and public claim traceability in `docs/EVIDENCE_INDEX.md`.
>
> Keep core fabric architecture original. PULP AXI/FlooNoC/iDMA/ZipCPU are prior art unless an explicit reuse decision with licence/provenance is recorded. `cocotbext-axi` may be used as a verification BFM only after Phase-0 qualification; the project-owned Python model remains the oracle.
>
> Do not turn the project into a CPU, coherent-cache, DMA, PCIe, DRAM-controller or mesh-NoC project before the CV/public-ready gate. CDC is a later extension after the single-clock fabric is trusted.
>
> For normal work, load `docs/PROJECT_STATE.md`, the relevant spec/microarchitecture section, the current task and changed files rather than repeatedly loading the whole master plan.
>
> At each material milestone report: (1) what changed; (2) evidence now exists; (3) what remains unproven; (4) risks/bottlenecks; (5) specification changes; (6) next smallest engineering task.

---

## 4. First message to the new project

Send:

> Read `00_MASTER_PROJECT_PLAN.md`, `01_CHATGPT_PROJECT_OPERATING_INSTRUCTIONS.md`, and `02_PHASE0_BOOTSTRAP_TASK.md`. Do not implement AXI RTL yet. Summarize only: (1) the frozen AXI subset; (2) outstanding/ID/write-ordering contract; (3) Architecture A/B scheduler definitions; (4) Gate-0 blockers; (5) the exact first Phase-0 execution task. Flag any contradiction among the files. Then prepare a narrow Codex/local task for Gate-0 bootstrap with explicit files, commands and evidence outputs.

The correct first engineering action is environment/reference bootstrap, not fabric RTL.

---

## 5. Phase-0 handoff to local/Codex execution

The initial execution task should:

- inspect the fresh repository;
- create the documented skeleton;
- pin and report tools;
- run language/simulation/formal/synthesis/P&R smoke tests;
- qualify or reject cocotbext-axi;
- validate the ECP5 compact-wrapper methodology;
- create Gate-0 evidence;
- avoid AXI RTL implementation.

The task must have named acceptance commands and exact evidence output locations.

---

## 6. After Gate 0

Do **not** immediately ask Codex to “build the interconnect.”

The next stage is Gate 1 document completion. In the fresh project, ask ChatGPT to make the following repository documents implementation-complete and mutually consistent:

1. `docs/REQUIREMENTS.md`
2. `docs/MICROARCHITECTURE.md`
3. `docs/VERIFICATION_PLAN.md`
4. `docs/FORMAL.md`
5. `docs/TIMING_PERFORMANCE.md`
6. `docs/DECISIONS.md`
7. `docs/KNOWN_LIMITATIONS.md`

Then run a hostile protocol review specifically covering:

- AW/W independence;
- no WID;
- W order across merged managers;
- same-ID ordering;
- different-ID reordering;
- downstream VALID stability while stalled;
- response collisions;
- reset with outstanding traffic;
- 4-KiB and burst limits;
- every channel's backpressure;
- QoS not overriding AXI ordering;
- starvation guarantee assumptions.

Gate 1 must close before Architecture-A RTL feature work starts.

---

## 7. Suggested first implementation task sequence after Gate 1

The sequence below is a planning recommendation, not permission to skip tests between items:

1. `FABRIC-001` — shared package/types/constants + compile/lint only.
2. `FABRIC-002` — address decoder + directed/formal tests.
3. `FABRIC-003` — round-robin request arbiter + directed/formal tests.
4. `FABRIC-004` — ID widen/strip + outstanding busy/count tracker.
5. `FABRIC-005` — read request path AR routing.
6. `FABRIC-006` — read response arbitration/routing + burst lock.
7. `FABRIC-007` — write AW admission + write-owner state.
8. `FABRIC-008` — W routing through WLAST + AW/W timing tests.
9. `FABRIC-009` — B response routing/arbitration.
10. `FABRIC-010` — default/error target.
11. `FABRIC-011` — integrated Architecture-A directed regression.
12. `FABRIC-012` — independent Python transaction model/scoreboard completion.
13. `FABRIC-013` — randomized backpressure/latency regression.
14. `FABRIC-014` — reset-with-traffic regression.
15. `FABRIC-015` — targeted formal integration properties.
16. `FABRIC-016` — Architecture-A frozen benchmark baseline.
17. `FABRIC-017` — Architecture-A ECP5 synthesis/P&R baseline.
18. **Only now:** identify measured bottleneck and authorize Architecture B.

Task IDs can change; the narrowness and dependency order should not.

---

## 8. Files to keep short

`docs/PROJECT_STATE.md` should remain small and operational. Recommended shape:

```text
Current gate:
Known-good commit:
Current task:
Last evidence:
Open blockers:
Frozen architecture changes since last state:
Next smallest task:
```

Do not use it as another master plan.

---

## 9. What not to upload repeatedly

Do not repeatedly paste:

- the full Arm AXI specification;
- the entire master plan;
- huge simulator logs;
- all raw benchmark CSVs.

Instead upload/reference:

- relevant spec section citation;
- focused repository docs;
- current task;
- failing log excerpt plus raw-log path;
- concise processed evidence.

---

## 10. Success condition for project setup

A fresh ChatGPT Project is correctly initialized when it can answer, from files alone:

- exactly what AXI4 subset is supported;
- why H.c is the normative source;
- how IDs are widened and same-ID order is protected;
- what happens when W precedes AW;
- why a target has one W owner through WLAST;
- exact A and B scheduling rules;
- what “bounded starvation” does and does not mean;
- which benchmark variables are frozen;
- which claims require which evidence classes;
- what must happen before CDC/Architecture C.

If those answers require old chat history, project setup is incomplete.
