# Engineering source semantic review

**Reviewed revision:** `05440c322bbd49beba59f07f3f5d51a0af6faef6`
**Baseline:** `kg-g5-public-ready` at `d2ef2bb2ec41a2b99f6532618a4a2d41bca736b5`
**Review branch:** `portfolio/semantic-source-review`
**Scope:** current tracked engineering sources, read in dependency order. This is source-level review evidence, not a fresh execution of the full simulation, formal or benchmark suite.

## Coverage

The current checkout contains 1,179 tracked paths, including 877 under `results/raw/` (159,823,565 bytes). The semantic register has 186 non-placeholder engineering-source entries:

| Category | Files | REVIEWED | PARTIALLY_REVIEWED | NOT_REVIEWED |
|---|---:|---:|---:|---:|
| RTL | 25 | 25 | 0 | 0 |
| Formal harnesses/configurations | 47 | 47 | 0 | 0 |
| Directed, cocotb, model and random support | 49 | 49 | 0 | 0 |
| Benchmark source/config/tests | 9 | 9 | 0 | 0 |
| Runner/environment scripts | 45 | 45 | 0 | 0 |
| Toolchain smoke RTL | 6 | 6 | 0 | 0 |
| CI workflow | 1 | 1 | 0 | 0 |
| Audit Python tools | 3 | 3 | 0 | 0 |
| Pinned Python requirements | 1 | 1 | 0 | 0 |
| **Total** | **186** | **186** | **0** | **0** |

The TB review note initially misstated its total as 47; the path comparison found 51 tracked `tb/` paths, including two empty `.keep` placeholders, and all 49 `.sv`/`.py` sources appear by name in the per-file review report. Empty placeholders and non-source evidence/document files are excluded from the semantic source count. The historical baseline raw scan found 64 duplicate groups repository-wide; 53 groups contain only raw paths and 11 include at least one non-raw path. These duplicates remain preserved. `semantic_source_review.csv` records each reviewed path, Git blob at the pinned review commit, line count, contract inspected, concrete observation and disposition. `generated/current_head_delta_from_gate5.csv` records the complete path-level delta from the Gate-5 commit without collapsing renames: 72 additions, 30 modifications and 3 removals (105 changed paths; net repository growth 69 paths). It includes cleanup documentation moves and PR2 qualification evidence additions. The historical 1,110-file baseline register is retained unchanged.

## Significant findings

| ID | Priority/status | Finding |
|---|---|---|
| SR-P1-01 | P1, resolved here | Several focused verification paragraphs in `docs/VERIFICATION_PLAN.md` still described integrated W/B/S3 behavior as future work. The wording is corrected to preserve component-test scope while pointing to current Gate-3 whole-top evidence. |
| SR-P3-05 | P3, open | Two B-specific RTL path file headers say Architecture-A. Comment-only; RTL behavior is unchanged. |
| SR-P3-01 | P3, disclosed scope limitation | B/R routers check manager prefix and live ID but do not match response source target to stored per-ID target. D037 and `KNOWN_LIMITATIONS.md` disclose this interface limitation; no production defect was reproduced. |
| SR-P2-03 | P2, open assurance concern | Some oracle cocotb helpers poll READY/VALID and update the oracle outside an atomic edge snapshot. This weakens exact event correlation, but this review found no failing trace or result invalidation. |
| SR-P2-04 | P2, open guard-strength concern | `compare_ab.py` checks 70 records and selected manifest equality but does not itself enforce the exact frozen workload/seed Cartesian set or every manifest field. Gate-5 evidence separately verifies the complete matrix. |
| SR-P2-05 | P2, open parser-robustness concern | PPA resource parsing can emit `{}` if the expected report block is absent instead of failing. Current committed summaries have resource counts. |
| SR-P3-02 | P3, open | Formal smoke accepts any nonzero result from its intentional-fail phase, without matching the expected assertion signature. Targeted formal jobs are separate. |
| SR-P3-03 | P3, open | Optional `ecppack` failure is ignored in the smoke PNR script; the route/config check is separate. |
| SR-P3-04 | P3, open | PPA wrapper header calls B a future instance despite current B selection and measured use. Comment-only. |

An initial reviewer suggestion that benchmark latency/throughput samples leak beyond the measurement window was checked and rejected: the driver marks a transaction sampled only when completion falls in the measurement window, while throughput uses accepted beat cycles inside the common interval. See `SR-NOTE-01` in the finding register.

No P0 issue, confirmed production RTL defect, frozen workload/decision change, or evidence-integrity defect was established. The only P1 finding was documentation drift and is corrected in this branch; remaining P2 items are assurance/tool-guard observations without demonstrated invalid benchmark or functional results; P3 items are disclosed limitations, stale comments or optional smoke-quality notes. The documented recorded-target response limitation is not treated as a newly discovered failure or silently waived requirement. No RTL, formal property, workload, benchmark engine, metric, processed result or raw evidence was modified.

## Cross-module lifecycle review

The RTL pass traced manager AW admission through the registered target AW slot, target AW acceptance, registered owner-directed W path, target-accepted final WLAST owner release, target B routing and manager B retirement. Read review traced AR admission and read allocation through the registered AR slot, target-side R response, per-manager source/RID lock, accepted manager RLAST and outstanding retirement. D028 pre-state credit, D030 owner reuse, D031/D036 successor suppression and D032 slot no-drain/refill were checked against the path/state modules and focused test/formal composition evidence. This review does not claim an exhaustive proof of every cycle combination.

Architecture B's QoS scheduler was reviewed against D045/D046 and its bounded formal harness. Formal PASS claims remain property-scoped BMC/cover under each harness's assumptions; no whole-Fabric proof or unconditional starvation guarantee is claimed. The test review also retained the distinction between random depth two and deterministic directed depth four.

## Baseline and evidence integrity

The current Git delta from Gate-5 contains no changes to RTL, formal sources/configuration, `bench/workloads.yaml`, D045/D047, benchmark engine/endpoint/metric implementation, processed A/B measurements, or Gate-5 raw results. Workload SHA-256 remains `31c599caa7344c938b588a0f22404cfcfe5fe53b3ef5fae40a568130cfadfca4`. Protected tags remain at their original commits. The 1,110-file baseline audit is historical; the new delta register is specific to review commit `05440c3` and includes cleanup/qualification additions. `generated/current_review_scope.json` records the exact tracked/raw counts, bytes, category counts, duplicate counts and workload hash from Git objects.

No full regression was rerun for this source review. The only implementation change is documentation wording; validation is limited to current-path/blob/count checks, Markdown link checks and `git diff --check`.

## Follow-up: P2 assurance hardening

After the source-review baseline, SR-P2-04 and SR-P2-05 were hardened on branch `assurance/p2-tooling-guards`. The A/B comparator now fails closed on the frozen 70-run matrix, pair identities, shared source identities, selected DUT, sample fields and duplicate/missing rows. Thirteen focused synthetic tests exercise acceptance and rejection cases, including exact workload identity and malformed active-manager/sample rows. The PPA parser now requires a recognized expected DUT report and required resource counts, distinguishes optional zero resources, malformed/missing data and synthesis failures; eight parser tests cover these cases. Reprocessing the frozen A/B datasets in a separate validation directory preserved all comparison values, D045 outcomes, resource totals and the 60/55 MHz all-seed route thresholds. These are assurance checks; no benchmark metric or implementation result changed.

The active-edge oracle diagnostic escalated SR-P2-03 rather than resolving it: for the M0/S1/ID 11 LEN=3 response, the sampled public buses showed six target and six manager R handshakes while the oracle advanced four beats. Beats 1 and 2 were each accepted on two adjacent edges. This is evidence of a testbench response-driver/event-correlation issue in that scenario, not a production RTL defect. The checked-in oracle test was not changed. A separate corrective plan and compact trace are recorded at `oracle_edge_correlation_followup.md` and `results/raw/portfolio_audit_p2/oracle_edge_correlation_{summary.json,window.jsonl}`. Gate-2 R-path confidence for this helper scenario remains open pending that separate correction and its regressions.

Current P2 disposition: **two resolved by tested fail-closed guards; one escalated to separate oracle repair**. The source review's historical findings remain visible above; this follow-up does not retroactively alter its review baseline.

## Independent review

Fresh Codex CLI read-only contexts produced the category review records under `portfolio_audit/semantic_review/`; a separate patch reviewer challenged the generated register and documentation. The patch review correctly rejected the initial generic evidence-column and overbroad integration wording. The register now points to each category report, severity was reduced for disclosed/cosmetic notes, the raw/tracked counts are captured in `generated/current_review_scope.json`, and the Gate-3 wording distinguishes Architecture-A integration from B whole-top functional evidence. The patch reviewer also initially flagged possible post-window metric leakage; direct tracing of the benchmark driver and summarizer rejected that concern. A third fresh read-only review approved the corrected artifacts and verified exact scope-path coverage, finding-ID/severity consistency, frozen-source boundaries and A/B attribution. These are independent model contexts, not human or independent hardware review. No reviewer reran the full simulation, formal or benchmark suite.
