# FABRIC Phase 0 Bootstrap Task

**Task type:** environment/reference/reproducibility bootstrap  
**RTL feature implementation:** prohibited  
**Gate closed by this task:** Gate 0 — environment/reference baseline

---

## 1. Objective

Create a clean repository skeleton and produce **real local evidence** that the planned open-source workflow can compile, simulate, run cocotb, run a small formal proof, synthesize and route a harmless smoke design on the intended Apple-Silicon/ECP5 path.

This task exists to remove environment uncertainty **before** AXI RTL is written.

Do not implement the AXI fabric, decoder, arbiter, scoreboard or performance generator in Phase 0.

---

## 2. Read first

Read:

1. `00_MASTER_PROJECT_PLAN.md`
2. `01_CHATGPT_PROJECT_OPERATING_INSTRUCTIONS.md`
3. this file

Protocol reference metadata to record:

- Arm AMBA AXI and ACE Protocol Specification
- ARM IHI 0022H.c
- ID012621
- 26 January 2021
- canonical Arm documentation selector for H.c

Also record that later Issue J removed AXI3/AXI4/AXI4-Lite content and that current Issue L is not the normative AXI4 semantic source for this project.

---

## 3. Deliverables

By completion, create at least:

```text
AGENTS.md
README.md                       # minimal bootstrap README only
docs/REQUIREMENTS.md            # skeleton + frozen high-level contract
docs/MICROARCHITECTURE.md       # skeleton
docs/VERIFICATION_PLAN.md       # skeleton
docs/FORMAL.md                  # skeleton
docs/TIMING_PERFORMANCE.md      # skeleton
docs/TRADEOFFS.md               # skeleton
docs/DECISIONS.md               # seed decisions D001-D013
docs/PROJECT_STATE.md           # short current-state file
docs/EVIDENCE_INDEX.md          # Gate-0 evidence entries
docs/KNOWN_LIMITATIONS.md       # initial planning limitations
docs/THIRD_PARTY_MANIFEST.md
docs/THIRD_PARTY_NOTICES.md
docs/references/AXI_SPEC.md
scripts/check_env.sh
scripts/run_smoke_sim.sh
scripts/run_smoke_formal.sh
scripts/run_smoke_synth.sh
scripts/run_smoke_pnr.sh
results/raw/gate0/...
results/processed/gate0/summary.md
requirements/ or pyproject/lockfile as chosen
```

Smoke HDL may live under `smoke/` or `test/phase0/`. It must be generic tool-validation code, not project fabric RTL.

---

## 4. Step 0 — initialize repository and directories

Create the target repository tree from the master plan.

Minimum directories:

```text
docs/
docs/references/
rtl/
tb/cocotb/
tb/model/
tb/directed/
formal/
bench/analysis/
scripts/
constraints/
tasks/
results/raw/gate0/
results/processed/gate0/
third_party/
smoke/
```

Add `.gitignore` entries for:

- Python virtual environments;
- simulator build directories;
- wave dumps unless deliberately preserved;
- formal work directories;
- synthesis/P&R transient directories;
- macOS `.DS_Store`;
- large raw artifacts that are regenerated rather than versioned.

Do not ignore concise processed evidence or lockfiles.

---

## 5. Step 1 — protocol/source register

Create `docs/references/AXI_SPEC.md` containing:

- exact normative document metadata: H.c / ID012621 / 26 Jan 2021;
- canonical Arm source link;
- note that Issue J removed AXI4 content;
- note that Issue L is current-family context, not AXI4 semantic authority;
- the H.c chapter/section locations that will govern:
  - channel independence/handshake;
  - AW/W relationship;
  - burst length/4-KiB rule;
  - ID/order model;
  - WID/write-data ordering;
  - interconnect ID extension;
  - QoS signaling;
  - response codes;
  - reset/interface rules used later.

Do **not** commit the Arm PDF unless redistribution rights are explicitly checked and documented.

### Acceptance

A fresh engineer can identify the exact official AXI4 source without searching chat history.

---

## 6. Step 2 — toolchain pin

### Preferred path

Use a specific OSS CAD Suite `darwin-arm64` archive for EDA binaries and a repository-managed Python virtual environment for cocotb/analysis.

Record:

- archive/release identifier;
- download source;
- SHA-256 if available or computed;
- macOS version;
- CPU architecture;
- shell;
- exact version outputs for:
  - `verilator --version`
  - `yosys -V`
  - `sby --version` or equivalent
  - `nextpnr-ecp5 --version`
  - Trellis/ecppack version if exposed
  - Slang/yosys-slang version if exposed
  - `python3 --version`
  - `pip --version` / package-manager version

### Python candidate pins

Start with:

- cocotb `2.1.0`;
- cocotbext-axi `0.1.28`;
- pytest;
- numpy;
- pandas;
- matplotlib.

Use a lockfile or fully pinned requirements after smoke passes.

### Homebrew fallback

Homebrew is acceptable if a coherent set works. Current research observed Apple-Silicon packages for Verilator/Yosys/SBY, but do not assume independent formula versions remain mutually compatible. Capture real local output.

### Acceptance

`results/processed/gate0/tool_versions.md` lists every version and installation source used by the smoke suite.

---

## 7. Step 3 — SystemVerilog language/elaboration smoke

The project intends to use modern but conservative SystemVerilog. Before AXI coding, validate a tiny non-project smoke containing the language constructs being considered, for example:

- packages;
- parameters/localparams;
- packed structs;
- packed/unpacked arrays at module boundaries;
- generate loops;
- `always_ff` / `always_comb`;
- immediate/concurrent assertions where the chosen tool supports them;
- synthesizable functions.

Do not use AXI implementation logic in this smoke.

Run it through:

1. Verilator lint/elaboration;
2. Slang or yosys-slang elaboration;
3. Yosys synthesis parse/elaboration.

If SystemVerilog interfaces or modports are desired for readability, include them as a separate **optional compatibility experiment**. If they create inconsistent frontend support, prefer project-owned packed channel structs/flat wrappers rather than making interface support an MVP dependency.

### Decision criterion

Choose the narrowest coding style that works across simulation, synthesis and formal without large tool-specific source forks.

Record the result in `docs/DECISIONS.md`.

---

## 8. Step 4 — Verilator + cocotb smoke

Create a tiny handshake/counter-like smoke DUT unrelated to AXI.

Prove locally that:

- Verilator compiles it;
- cocotb starts;
- clock/reset work;
- a cocotb test drives input and observes output;
- JUnit/XML or another machine-readable result is generated;
- a deterministic seed can be passed and printed.

### Acceptance

- exit code 0;
- test result file exists;
- raw compile/run log saved under `results/raw/gate0/sim/`;
- concise summary saved under `results/processed/gate0/`.

---

## 9. Step 5 — cocotbext-axi compatibility smoke

This is the only Phase-0 smoke that may instantiate a **third-party AXI BFM**, but it still must not implement the project fabric.

Use a tiny known-simple AXI RAM/slave endpoint or a minimal test fixture to validate the chosen version combination.

Demonstrate at least:

- one aligned 64-bit write;
- one aligned 64-bit read;
- a multi-beat INCR transfer;
- explicit transaction ID handling if the BFM API exposes it in the selected fixture;
- a finite pause/backpressure generator;
- compatibility with cocotb 2.1.0 and chosen Verilator.

This smoke is **tool qualification**, not project protocol evidence.

### Decision criterion

- **PASS:** pin cocotbext-axi exact tag/SHA and mark `verification-only` in `THIRD_PARTY_MANIFEST.md`.
- **FAIL, easy fix:** pin a compatible release/commit and document why.
- **FAIL, structural:** replace with another open BFM or create a small project-specific driver later; do not let the BFM block core architecture.

---

## 10. Step 6 — formal smoke

Create a tiny generic state machine/counter property with:

- at least one assertion that proves;
- at least one cover that reaches;
- one intentionally failing variant run once to confirm the harness reports failure correctly, then remove/disable it from normal PASS regression.

Run through SBY/Yosys and a selected solver.

Record:

- SBY version;
- Yosys version;
- solver/version;
- mode/depth;
- PASS log;
- cover evidence;
- expected-failure harness evidence.

### Acceptance

The team knows both what a real PASS and real FAIL look like before AXI formal properties are written.

---

## 11. Step 7 — synthesis smoke

Synthesize a tiny generic design with Yosys for ECP5.

Capture:

- command/script;
- resource report;
- warnings;
- generated netlist/JSON location;
- exact tool version.

The purpose is tool plumbing, not PPA evidence for the fabric.

---

## 12. Step 8 — ECP5 P&R smoke

Target the frozen planned device tuple:

- `LFE5U-45F`;
- package `CABGA381`;
- speed grade `6`;
- nextpnr ECP5/Trellis flow.

Validate the actual command syntax supported by the pinned tools. Current upstream nextpnr exposes the 45k device option, CABGA381 package support and speed-grade selection, but the local command is the evidence.

Use a tiny smoke design with a modest clock target (for example 100 MHz) only to confirm P&R runs.

Capture:

- command;
- device/package/speed;
- seed;
- timing summary;
- output artifact;
- warnings.

Do not describe a smoke WNS/Fmax as project timing evidence.

---

## 13. Step 9 — compact fabric P&R harness methodology experiment

The future AXI fabric cannot realistically expose every manager/subordinate signal as FPGA package pins. Also, tying interfaces to constants may let synthesis optimize the fabric away.

Before Gate 0 closes, prototype a **generic preservation methodology**, still without AXI fabric RTL, that demonstrates how the future wrapper will:

- keep a large internal DUT cone alive;
- drive many internal DUT inputs from a small number of registered top-level stimulus pins/state generators;
- reduce/consume many DUT outputs into a small registered signature;
- use the same wrapper structure for architecture variants;
- avoid excessive package I/O;
- survive Yosys optimization;
- yield stable stats over repeated runs.

Possible methods may include registered PRNG/stimulus expansion and registered signature reduction. The final technique is chosen from evidence, not assumed.

### Acceptance

Document in `docs/TIMING_PERFORMANCE.md`:

- chosen wrapper method;
- why DUT logic remains observable;
- limitations of absolute resource interpretation;
- how A/B relative comparison will remain fair.

This is a Gate-0 blocker because meaningless PPA would undermine the project experiment.

---

## 14. Step 10 — upstream snapshot and licensing

For each required reference project record:

- repository;
- exact observed tag/SHA;
- retrieval date;
- licence file/SPDX;
- role in this project;
- whether any code is copied.

Required:

- `pulp-platform/axi`
- `pulp-platform/common_cells`
- `pulp-platform/iDMA`
- `pulp-platform/FlooNoC`
- `ZipCPU/wb2axip`
- `alexforencich/cocotbext-axi`

Initial policy:

- core PULP/FlooNoC/iDMA/wb2axip logic: reference-only;
- cocotbext-axi: candidate verification dependency;
- common_cells: reference-only until a later explicit generic-primitive reuse decision.

If a file is actually imported, review that file's header/SPDX. Do not rely only on repository-level licence summaries.

---

## 15. Step 11 — create Gate-1 document skeletons

Populate skeletons with headings and frozen decisions from the master plan.

Do not leave the following as “TBD” after Phase 0 because they are already decided:

- documented AXI4 subset label;
- 3x4 topology;
- widths;
- address map;
- max burst 16;
- aligned 64-bit INCR only;
- 4 read + 4 write outstanding per manager;
- one outstanding per ID/direction;
- manager-index ID widening;
- write ownership policy;
- Architecture A RR policy;
- Architecture B age width/threshold/escape rule;
- workload seed set;
- ECP5 target;
- single-clock-first scope.

Open items must be genuine implementation-detail decisions, not forgotten architecture.

---

## 16. Step 12 — processed Gate-0 evidence summary

Create `results/processed/gate0/summary.md` with a table:

| Check | Command | Result | Evidence | Decision/impact |
|---|---|---|---|---|
| host/platform | ... | PASS/FAIL | raw path | ... |
| SV lint/elaboration | ... | ... | ... | coding subset |
| Verilator+cocotb | ... | ... | ... | simulator qualified |
| cocotbext-axi | ... | ... | ... | pin/replace |
| formal | ... | ... | ... | solver path |
| Yosys ECP5 synth | ... | ... | ... | synthesis path |
| nextpnr ECP5 | ... | ... | ... | target command |
| compact wrapper method | ... | ... | ... | PPA validity |
| licences | n/a | ... | manifest | reuse policy |

Update `docs/EVIDENCE_INDEX.md` to point to this summary and raw evidence.

---

## 17. Gate-0 acceptance criteria

Gate 0 is **PASS** only if all are true:

- [ ] repository skeleton exists;
- [ ] H.c protocol source metadata is pinned;
- [ ] exact tool versions are captured;
- [ ] selected SV coding subset passes all intended frontends;
- [ ] Verilator+cocotb smoke passes;
- [ ] cocotbext-axi is either qualified and pinned or explicitly rejected/replaced;
- [ ] formal PASS/cover smoke works;
- [ ] formal harness can detect an intentional FAIL;
- [ ] Yosys synthesis smoke passes;
- [ ] nextpnr/Trellis smoke passes for LFE5U-45F/CABGA381/speed-6;
- [ ] compact P&R harness method is validated;
- [ ] upstream tags/SHAs/licences are recorded;
- [ ] third-party manifest/notices exist;
- [ ] no project AXI RTL has been implemented;
- [ ] `PROJECT_STATE.md` says Gate 0 PASS with evidence links.

If one of the key EDA steps fails, Gate 0 remains open. Resolve the environment/tool method before implementing the fabric.

---

## 18. Stop conditions

Stop and escalate to an engineering decision if:

- the chosen SV style requires divergent source files for sim/synth/formal;
- cocotb/Verilator combination is unstable;
- SBY cannot execute a basic property;
- the exact ECP5 target cannot route a trivial design;
- the compact wrapper cannot prevent optimization without dominating the design;
- a proposed third-party dependency has ambiguous or incompatible licensing.

Do not “temporarily” start AXI RTL while one of these blockers remains.

---

## 19. Completion report format

When Phase 0 is complete, report:

1. **What changed** — repository/docs/scripts created.
2. **Evidence now exists** — exact smoke results and paths.
3. **Unproven** — all AXI functionality/performance remains unimplemented/unproven.
4. **Risks** — any tool/frontend/P&R caveats.
5. **Specification changes** — only if the smoke forced a documented choice.
6. **Next smallest task** — complete Gate-1 requirements/microarchitecture freeze, not “implement everything”.

Do not report AXI functional correctness from Phase-0 smoke tests.
