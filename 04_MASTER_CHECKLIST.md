# Fabric Under Pressure — Master Checklist

Use this as the execution/gate checklist. A checked item means the required evidence exists, not merely that someone intends to do it.

**Evidence rule:** when an item depends on simulation/formal/synthesis/P&R/benchmark execution, link the evidence in `docs/EVIDENCE_INDEX.md` before checking it.

---

# A. Planning package

- [x] Master project purpose is interconnect/QoS, not CPU design.
- [x] Engineering method is frozen.
- [x] Evidence classifications are defined.
- [x] Architecture A is round robin.
- [x] Architecture B is QOS + aging/starvation escape.
- [x] Architecture C is conditional on measured A/B bottleneck.
- [x] Originality boundary is defined.
- [x] Required repository documentation set is defined.
- [x] Hostile first-draft audit has been performed.
- [x] All planning-level BLOCKER/MAJOR audit items have a repair.
- [x] Readiness is classified as READY WITH PHASE-0 CONDITIONS.

---

# B. Protocol authority

- [x] Normative AXI4 source selected as Arm IHI 0022H.c / ID012621 / 26 Jan 2021.
- [x] Current-family Issue L recorded as context only.
- [x] Issue J removal of AXI4 content understood.
- [ ] `docs/references/AXI_SPEC.md` exists in repository.
- [ ] H.c source link is recorded.
- [ ] H.c handshake section is referenced in requirements.
- [ ] H.c AW/W independence/order section is referenced.
- [ ] H.c burst/4-KiB section is referenced.
- [ ] H.c ID/order model section is referenced.
- [ ] H.c WID/write-data order section is referenced.
- [ ] H.c interconnect ID extension section is referenced.
- [ ] H.c QoS section is referenced.
- [ ] H.c response-code/default-decode behavior source is referenced.
- [ ] Arm PDF redistribution/licence handling is documented; PDF is not casually committed.

---

# C. Frozen topology and interface contract

- [x] 3 managers frozen.
- [x] M0 = control-like traffic.
- [x] M1 = DMA/bulk traffic.
- [x] M2 = latency-critical accelerator traffic.
- [x] 4 logical subordinate targets frozen.
- [x] S0 SRAM A region frozen.
- [x] S1 SRAM B region frozen.
- [x] S2 config/peripheral region frozen.
- [x] S3 default/error target frozen.
- [x] DATA_WIDTH = 64.
- [x] ADDR_WIDTH = 32.
- [x] manager-side ID_WIDTH = 4.
- [x] manager-index width = 2.
- [x] downstream internal ID width = 6.
- [x] read outstanding limit = 4/manager.
- [x] write outstanding limit = 4/manager.
- [x] one outstanding per manager ID per direction.
- [x] address map is non-overlapping and 4-KiB aligned.
- [ ] exact signal list is frozen in `docs/REQUIREMENTS.md`.
- [ ] attribute pass-through/fixed semantics are frozen in `docs/REQUIREMENTS.md`.

---

# D. AXI4 subset

- [x] project language is “documented AXI4 subset”.
- [x] AW/W/B supported.
- [x] AR/R supported.
- [x] INCR supported.
- [x] 1–16 beats supported.
- [x] aligned 8-byte transfer size only.
- [x] arbitrary legal WSTRB supported within aligned full-width transfer.
- [x] IDs supported.
- [x] multiple outstanding across distinct IDs supported by plan.
- [x] RESP supported.
- [x] LAST supported.
- [x] AxQOS supported.
- [x] backpressure required on all channels.
- [x] unmapped supported accesses route to S3/DECERR.
- [x] FIXED excluded.
- [x] WRAP excluded.
- [x] >16 beat bursts excluded.
- [x] narrow transfers excluded.
- [x] unaligned transfers excluded.
- [x] exclusives/locked accesses excluded.
- [x] ATOP excluded.
- [x] ACE/CHI/coherency excluded.
- [x] WID/write-data interleaving excluded.
- [x] USER semantics excluded.
- [x] unsupported manager requests are outside the documented subset and must be assertion-detected.
- [ ] all subset requirements have stable `REQ-*` IDs.
- [ ] every subset requirement maps to at least one test/assertion/property.

---

# E. Ordering and ID contract

- [x] transaction-outstanding start/end is defined.
- [x] read and write ordering domains are independent for tracking.
- [x] same-ID ordering protected by one-outstanding-per-ID serialization.
- [x] different IDs may complete out of order.
- [x] manager index is appended to downstream ID.
- [x] manager index is stripped on return.
- [x] internal manager code 3 is illegal.
- [x] busy-ID tracking required.
- [x] per-manager read count cannot exceed 4.
- [x] per-manager write count cannot exceed 4.
- [x] response for non-busy ID is an error/assertion condition.
- [ ] formal property checks busy-ID double allocation.
- [ ] formal property checks count underflow/overflow.
- [ ] directed test uses same original ID from different managers concurrently.
- [ ] directed test demonstrates legal different-ID out-of-order completion.
- [ ] directed test demonstrates same ID cannot be reaccepted before final response.

---

# F. AW/W/write routing

- [x] no assumption that AW and W arrive together.
- [x] W may assert before AW and be backpressured.
- [x] WREADY is not asserted without accepted write context.
- [x] one data-active write context per manager.
- [x] one write-data owner per target.
- [x] target cannot accept new AW until owner's WLAST handshakes.
- [x] every W beat routes using captured AW target.
- [x] ownership clears on accepted WLAST, not B.
- [x] B may remain outstanding after WLAST.
- [x] manager can proceed to next AW after WLAST subject to count/ID limits.
- [ ] AW-before-W directed test passes.
- [ ] W-before-AW directed test passes.
- [ ] same-cycle AW/W directed test passes.
- [ ] W stall at first beat passes.
- [ ] W stall mid-burst passes.
- [ ] W stall on WLAST passes.
- [ ] wrong/missing WLAST is detected.
- [ ] formal write-owner properties pass under documented assumptions.

---

# G. Read/B response routing

- [x] B responses use per-manager response arbitration.
- [x] B response arbitration remains common between A/B.
- [x] R responses use per-manager arbitration.
- [x] selected R subordinate locks through accepted RLAST.
- [x] R response arbitration remains common between A/B.
- [ ] simultaneous B from multiple subordinates test passes.
- [ ] simultaneous R availability from multiple subordinates test passes.
- [ ] R backpressure maintains lock/payload.
- [ ] RLAST frees burst lock exactly once.
- [ ] response route assertions reject invalid manager-index code.
- [ ] response route assertions reject non-busy ID.

---

# H. Reset contract

- [x] single-clock coordinated reset semantics are defined.
- [x] pre-reset accepted transactions are abandoned on reset.
- [x] ownership/outstanding/scheduler state clears.
- [x] endpoint models clear pre-reset pending responses.
- [x] rogue independent stale-response collision is declared out of MVP scope.
- [ ] exact reset implementation style is frozen after Phase-0 frontend/tool smoke.
- [ ] idle reset directed test passes.
- [ ] reset after AW before W passes.
- [ ] reset mid-W burst passes.
- [ ] reset with B pending passes.
- [ ] reset with R burst pending passes.
- [ ] scoreboard resets its epoch correctly.
- [ ] no pre-reset transaction is observed after coordinated reset.
- [ ] reset limitation appears in `KNOWN_LIMITATIONS.md`.

---

# I. Architecture A scheduler

- [x] one AW arbiter per target.
- [x] one AR arbiter per target.
- [x] 3-way cyclic RR policy defined.
- [x] pointer updates only on handshake.
- [x] selected downstream request is held while stalled.
- [x] no mid-burst write preemption.
- [x] fairness language is service-opportunity conditional.
- [ ] RR arbiter directed test covers every initial pointer position.
- [ ] simultaneous 2-request ties tested.
- [ ] simultaneous 3-request ties tested.
- [ ] target READY stall while grant held tested.
- [ ] persistent-request fairness directed test passes.
- [ ] RR one-hot/no-grant-without-request formal properties pass.
- [ ] RR hold-stability formal property passes.
- [ ] RR fairness property passes under explicit readiness assumption.

---

# J. Architecture B scheduler

- [x] AxQOS interpreted as unsigned 4-bit normal priority.
- [x] higher AxQOS wins in normal mode.
- [x] age width = 8 bits.
- [x] age saturates at 255.
- [x] starvation threshold = 64 pending cycles.
- [x] age increments while legal request remains pending without handshake.
- [x] age resets after handshake/no pending request.
- [x] starved set overrides non-starved QOS traffic.
- [x] starved set is served with RR.
- [x] normal-mode equal-QOS ties use RR.
- [x] held downstream request cannot be preempted.
- [x] QOS cannot override AXI ordering/admission constraints.
- [x] no absolute starvation bound claimed under infinite backpressure.
- [ ] age counter saturation test passes.
- [ ] threshold transition at 63/64 tested.
- [ ] higher-QOS normal selection tested.
- [ ] equal-QOS RR tie tested.
- [ ] starved low-QOS beats newly arriving high-QOS under frozen rule.
- [ ] multiple starved requesters rotate fairly.
- [ ] B formal priority monotonicity passes.
- [ ] B formal no-wrap/saturation passes.
- [ ] B formal starvation-escape property passes under assumptions.
- [ ] cover demonstrates starvation-escape mode is reachable.

---

# K. Benchmark freeze

- [x] manager traffic classes defined.
- [x] M0 default QoS = 8.
- [x] M1 default QoS = 0.
- [x] M2 default QoS = 15.
- [x] fixed seed set defined: FABC0001–FABC0005.
- [x] W00 idle defined.
- [x] W01 M0 only defined.
- [x] W02 M1 DMA only defined.
- [x] W03 M2 only defined.
- [x] W04 balanced mixed defined.
- [x] W05 saturated DMA + control defined.
- [x] W06 saturated DMA + critical defined.
- [x] W07 all saturated heterogeneous defined.
- [x] W08 adversarial starvation defined.
- [x] W09 read-heavy defined.
- [x] W10 write-heavy defined.
- [x] W11 50/50 mixed defined.
- [x] W12 equal-demand fairness defined.
- [x] W13 parallel-target defined.
- [x] exact workload target percentages/gap distributions are committed before B exists.
- [x] PRNG algorithm/version is pinned.
- [x] canonical subordinate model latency/queue depth is pinned.
- [x] proposed 500 warm-up / 5,000 samples policy is accepted or changed once before B RTL.
- [x] workload file checksum/commit is recorded before A/B comparison.
- [ ] no workload is altered after B results without invalidating/re-running both architectures.

---

# L. Metrics and analysis

- [x] `t_present` defined.
- [x] `t_addr_accept` defined.
- [x] `t_wlast` defined.
- [x] `t_first_resp` defined.
- [x] `t_complete` defined.
- [x] admission latency defined.
- [x] scheduler-contention cycles defined.
- [x] backpressure-blocked cycles defined.
- [x] read response latency defined.
- [x] write data-phase latency defined.
- [x] write response latency defined.
- [x] presentation-to-completion latency defined.
- [x] P50/P95/P99/max required.
- [x] wall-cycle starvation metric required.
- [x] service-opportunity starvation metric required.
- [x] read/write throughput definitions exist.
- [x] per-manager throughput required.
- [x] W12 Jain grant fairness formula defined.
- [x] heterogeneous fairness reporting caveat defined.
- [ ] percentile calculation method/version is pinned.
- [ ] analysis scripts record sample count.
- [ ] per-seed summaries retained.
- [ ] figures generated from processed data, not manually edited numbers.
- [ ] raw-to-processed transformation is reproducible.

---

# M. Independent reference model / scoreboard

- [x] project-owned Python oracle is required.
- [x] external BFM is not the oracle.
- [x] model tracks manager.
- [x] model tracks target.
- [x] model tracks ID/internal ID.
- [x] model tracks address/length/size/burst/QOS.
- [x] model tracks write data/WSTRB.
- [x] model tracks acceptance cycle.
- [x] model tracks expected RESP/LAST.
- [x] model tracks memory contents.
- [x] model tracks reset epoch.
- [ ] loss detection implemented/tested.
- [ ] duplication detection implemented/tested.
- [ ] misrouting detection implemented/tested.
- [ ] bad ID detection implemented/tested.
- [ ] bad data detection implemented/tested.
- [ ] bad WSTRB memory update detection implemented/tested.
- [ ] bad RESP detection implemented/tested.
- [ ] bad LAST detection implemented/tested.
- [ ] ordering violation detection implemented/tested.
- [ ] stale-after-reset detection implemented/tested.

---

# N. Functional verification

- [ ] address decoder tests pass.
- [ ] RR arbiter unit tests pass.
- [ ] QOS/age arbiter unit tests pass when B begins.
- [ ] ID mapping tests pass.
- [ ] outstanding counter/bitmap tests pass.
- [ ] AW/W decoupling tests pass.
- [ ] B path tests pass.
- [ ] AR/R tests pass.
- [ ] 1-beat burst tests pass.
- [ ] 16-beat burst tests pass.
- [ ] all intermediate legal burst lengths covered/randomized.
- [ ] multiple-ID tests pass.
- [ ] simultaneous manager tests pass.
- [ ] random subordinate response latency tests pass.
- [ ] AW backpressure tested.
- [ ] W backpressure tested.
- [ ] B backpressure tested.
- [ ] AR backpressure tested.
- [ ] R backpressure tested.
- [ ] default/error read tests pass.
- [ ] default/error write tests pass.
- [ ] reset idle passes.
- [ ] reset partially accepted traffic passes.
- [ ] long randomized contention passes.
- [ ] adversarial fairness/starvation tests pass.
- [ ] every discovered bug has a regression.
- [ ] A and B run identical functional vector suites.

---

# O. Formal

- [ ] SBY environment smoke passes.
- [ ] proof harness detects intentional failing smoke.
- [ ] decoder exclusivity/default proof passes.
- [ ] RR one-hot proof passes.
- [ ] RR no-grant-without-request proof passes.
- [ ] RR hold stability proof passes.
- [ ] RR fairness proof has explicit assumptions.
- [ ] QOS one-hot proof passes.
- [ ] QOS hold stability proof passes.
- [ ] age saturation/no-wrap proof passes.
- [ ] normal-mode priority property passes.
- [ ] starvation-escape property passes under explicit assumptions.
- [ ] write-owner uniqueness proof passes.
- [ ] W route follows accepted AW proof passes.
- [ ] outstanding counters cannot underflow.
- [ ] outstanding counters cannot exceed 4.
- [ ] busy ID cannot be double-accepted.
- [ ] R route only targets valid outstanding manager/ID under assumptions.
- [ ] cover statements show meaningful states are reachable.
- [ ] every proof summary records mode/depth/engine/assumptions.
- [ ] no bounded check is described as unbounded proof.
- [ ] whole-fabric exhaustive proof is not attempted prematurely.

---

# P. Gate 0 — environment/reference baseline

- [ ] repository initialized.
- [ ] directory structure created.
- [ ] H.c reference file created.
- [ ] OSS CAD Suite exact archive pinned or alternative decided.
- [ ] macOS/Apple-Silicon environment recorded.
- [ ] Verilator version recorded.
- [ ] Yosys version recorded.
- [ ] SBY version recorded.
- [ ] solver/version recorded.
- [ ] nextpnr/Trellis versions recorded.
- [ ] Python version recorded.
- [ ] cocotb 2.1.0 environment smoke passes.
- [ ] cocotbext-axi candidate smoke passes or replacement decided.
- [ ] SV language subset smoke passes Verilator.
- [ ] SV language subset smoke passes Slang/yosys-slang.
- [ ] SV language subset smoke passes Yosys.
- [ ] generic formal smoke passes.
- [ ] generic synthesis smoke passes.
- [ ] ECP5 LFE5U-45F/CABGA381/speed-6 P&R smoke passes.
- [ ] compact anti-optimization P&R wrapper methodology validated.
- [ ] upstream repositories/tags/SHAs/licences recorded.
- [ ] THIRD_PARTY_MANIFEST exists.
- [ ] THIRD_PARTY_NOTICES exists.
- [ ] Gate-0 processed summary exists.
- [ ] Evidence index links Gate-0 artifacts.
- [ ] known-good Gate-0 commit tagged only after evidence exists.

---

# Q. Gate 1 — architecture/protocol freeze

- [x] REQUIREMENTS implementation-complete.
- [x] MICROARCHITECTURE implementation-complete.
- [x] VERIFICATION_PLAN maps every requirement.
- [x] FORMAL maps tractable invariants.
- [x] TIMING_PERFORMANCE freezes benchmark/PPA method.
- [x] DECISIONS includes D001-D013.
- [x] KNOWN_LIMITATIONS is accurate.
- [x] exact interface signal list frozen.
- [x] exact reset style frozen.
- [x] exact performance endpoint queue/latency model frozen.
- [x] exact workload generator algorithm/percentages frozen.
- [x] exact benchmark sample count frozen.
- [x] exact P&R wrapper frozen.
- [x] exact tool versions/settings frozen for later A/B comparison.
- [x] hostile Gate-1 protocol review has no open BLOCKER/MAJOR issue.
- [x] requirement-to-test traceability has no gaps.
- [x] known-good Gate-1 commit recorded as `0d856ff` before tagging `kg-g1-spec`.

---

# R. Gate 2 — Architecture A functional baseline

- [ ] A core RTL exists.
- [ ] lint/elaboration passes.
- [ ] decoder integrated.
- [ ] RR request arbiters integrated.
- [ ] ID widen/strip integrated.
- [ ] outstanding tracking integrated.
- [ ] AR path works.
- [ ] R response route/lock works.
- [ ] AW/write-owner path works.
- [ ] W route through WLAST works.
- [ ] B route works.
- [ ] S3 default/error target works.
- [ ] independent Python model checks end-to-end behavior.
- [ ] directed regression passes.
- [ ] no deep-verification/PPA claim made prematurely.
- [ ] known-good Gate-2 commit recorded.

---

# S. Gate 3 — deep Architecture A verification

- [ ] all-channel random backpressure passes.
- [ ] random legal IDs/bursts/QOS/targets pass.
- [ ] randomized response latency passes.
- [ ] simultaneous channel stress passes.
- [ ] long seeded contention passes.
- [ ] reset-with-traffic regression passes.
- [ ] adversarial A fairness tests pass as specified.
- [ ] targeted formal properties for trusted primitives pass.
- [ ] bug regression set is current.
- [ ] coverage/reachability review completed.
- [ ] known-good Gate-3 commit recorded.

---

# T. Gate 4 — Architecture A measurement

- [ ] common P&R wrapper frozen.
- [ ] A synthesis evidence collected.
- [ ] A P&R seed/frequency evidence collected.
- [ ] A canonical benchmark all workloads/seeds complete.
- [ ] A latency distributions processed.
- [ ] A throughput processed.
- [ ] A starvation metrics processed.
- [ ] A fairness W12 processed.
- [ ] A timing/resources processed.
- [ ] measured bottleneck identified.
- [ ] bottleneck mechanism linked to traces/counters, not guesswork.
- [ ] B hypothesis written before B results.

---

# U. Architecture B controlled change

- [ ] B implementation changes scheduler policy/state only or deviations are explicitly reclassified.
- [ ] no B-only hidden buffer.
- [ ] no B-only hidden pipeline.
- [ ] no workload change.
- [ ] no outstanding-depth change.
- [ ] no target-model change.
- [ ] same functional regression passes.
- [ ] B-specific scheduler directed tests pass.
- [ ] B formal properties pass with assumptions.
- [ ] B canonical benchmark uses identical seeds/config.
- [ ] B synthesis/P&R uses identical target/settings/seeds.
- [ ] processed A/B comparison contains regressions and improvements.
- [ ] B retain/modify/reject decision written.
- [ ] if common bug fix occurred, A was rerun too.
- [ ] known-good Gate-4 commit recorded after comparison evidence.

---

# V. A/B comparison completeness

- [ ] M0 P50/P95/P99/max compared.
- [ ] M1 P50/P95/P99/max compared.
- [ ] M2 P50/P95/P99/max compared.
- [ ] reads compared separately.
- [ ] writes compared separately.
- [ ] admission latency compared.
- [ ] service-opportunity starvation compared.
- [ ] wall-cycle max wait compared.
- [ ] aggregate throughput compared.
- [ ] per-manager throughput compared.
- [ ] W12 fairness compared.
- [ ] LUT/cell resources compared.
- [ ] FFs compared.
- [ ] memory use compared if any.
- [ ] routed WNS/frequency compared.
- [ ] critical paths inspected.
- [ ] complexity/verification cost discussed.
- [ ] workloads where B regresses are explicitly shown.
- [ ] no overall “B is better” conclusion without trade-off context.

---

# W. CDC extension gate

Do not begin until core A/B results are trustworthy.

- [ ] CDC extension has a measured/portfolio reason.
- [ ] clock domains are explicitly named.
- [ ] AW crossing architecture specified.
- [ ] W crossing architecture specified.
- [ ] B crossing architecture specified.
- [ ] AR crossing architecture specified.
- [ ] R crossing architecture specified.
- [ ] AW/W association across domains specified.
- [ ] reset behavior across domains specified.
- [ ] async FIFO/protocol primitive provenance/licence resolved.
- [ ] synchronizer assumptions documented.
- [ ] SDC creates each real clock.
- [ ] asynchronous clocks grouped explicitly.
- [ ] no blanket false paths.
- [ ] CDC functional tests exist.
- [ ] CDC formal properties scoped tractably.
- [ ] cross-domain latency metric definition exists.

---

# X. Architecture C gate

- [ ] A/B functional evidence complete.
- [ ] A/B benchmark evidence complete.
- [ ] A/B PPA evidence complete.
- [ ] a remaining measured bottleneck exists.
- [ ] scheduler-only B cannot plausibly solve it.
- [ ] C hypothesis is one controlled change.
- [ ] C does not become a mesh-NoC project by default.
- [ ] C workload/target/settings are re-frozen before implementation.
- [ ] decision record authorizes C.

If any item above is unchecked, defer C.

---

# Y. Third-party/reuse

- [ ] every imported external file appears in manifest.
- [ ] every imported file's actual SPDX/header checked.
- [ ] required notice text included.
- [ ] external verification dependency clearly separated from oracle.
- [ ] PULP core fabric logic not copied.
- [ ] FlooNoC core router logic not copied.
- [ ] iDMA not integrated into MVP.
- [ ] ZipCPU partial AXI formal set not marketed as complete checker.
- [ ] reused generic primitive has explicit rationale.
- [ ] public README states original contribution boundary.

---

# Z. Public/CV-ready gate

- [ ] README answers the engineering question.
- [ ] README calls interface a documented AXI4 subset.
- [ ] README links exact supported/unsupported feature table.
- [ ] architecture block diagram published.
- [ ] AW/W ownership diagram published.
- [ ] ID widening/response routing diagram published.
- [ ] A/B scheduler diagram published.
- [ ] benchmark methodology published before/with results.
- [ ] P50/P95/P99 plots have definitions/sample counts.
- [ ] starvation plot/table published.
- [ ] throughput/fairness data published.
- [ ] PPA/timing table published.
- [ ] formal summary lists assumptions/limitations.
- [ ] negative results/trade-offs included.
- [ ] exact commands documented.
- [ ] tool versions documented.
- [ ] limitations documented.
- [ ] third-party notices complete.
- [ ] evidence index maps every major public claim.
- [ ] fresh clean-clone reproduction completed.
- [ ] known-good public commit/tag recorded.
- [ ] no raw claim exceeds evidence.

---

# AA. Milestone report template

At each material milestone verify the status report contains:

- [ ] 1. What changed.
- [ ] 2. What evidence now exists.
- [ ] 3. What remains unproven.
- [ ] 4. Current risks/bottlenecks.
- [ ] 5. Specification changes.
- [ ] 6. Next smallest engineering task.

---

# AB. Final scope sanity check

Before any new major feature ask:

- [ ] Does it directly strengthen the AXI/interconnect/QoS/tail-latency/formal/CDC/PPA story?
- [ ] Is there a measured reason now?
- [ ] Can it be one controlled change?
- [ ] Will it preserve benchmark comparability?
- [ ] Is it more valuable than closing the current gate?

If not, defer it.
