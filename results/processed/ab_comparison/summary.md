# Architecture A/B canonical comparison

**Decision: REJECT Architecture B under frozen D045.** The comparison is complete and controlled; the outcome is negative against two of the five predeclared criteria. No scheduler, workload, metric or sample-policy changes were made after observing results.

## Frozen setup and run completeness

- W00–W13 × five seeds (`0xFABC0001`–`0xFABC0005`): **70/70 valid A runs and 70/70 valid B runs**. W00 is the idle sanity case. Each active manager completed 500 warm-up and 5,000 retained transactions. Each JUnit file has one passing testcase with no failures, errors or skips; metadata records the selected top and bounded drain.
- A top: `axi_fabric_a`; B top: `axi_fabric_b`. The B runner compiles the B source list and asserts the selected top in test metadata.
- Workload SHA-256: `31c599caa7344c938b588a0f22404cfcfe5fe53b3ef5fae40a568130cfadfca4`. Benchmark engine SHA-256: `6d243fe801557d0d97ee273a9dd5f52d42acfd24c7ecc794d34e4e1d080d0e7f`. Generator SHA-256: `d017c80afe6fcaff0b5032e2e5a4da02a12b6ef6990f357ec26e7c32cb653453`. Runner SHA-256: `634573f401b4dba12765f87e6a442738611553d60f8d821e12997d8db0d0ada5`.
- The matched-run checker confirms identical workload, generator, engine, endpoint configuration and per-run intent-plan hashes across A/B. Simulation source manifests differ as expected for the selected RTL. The wrapper hash in the A cocotb manifest differs from B only because a comment changed between those runs; that wrapper is not compiled by the cocotb simulation. Both PPA runs use the same final wrapper SHA-256 `8c4a44d4db1947399b8722a5cb6b1cefc643ce17470955ff46b4fc6900fd9cd5`.
- Percentiles are NumPy 2.3.5 `method="nearest"`; comparison reports per-seed pairs and the median of the five per-seed values. The complete matrix, source manifest comparison and exact values are in the adjacent CSV/JSON artifacts.

## D045 decision table

| Frozen criterion | A baseline | B measured | Result |
|---|---:|---:|---|
| W08 M2 read admission P99 ≤16 cycles | 21 cycles | 16 cycles | **PASS** |
| W08 M1 read+write payload ≥10.07665 B/cycle | 10.606859 B/cycle | 6.340714 B/cycle (59.78% of A) | **FAIL** |
| W08 M0 read admission P99 ≤23 cycles | 21 cycles | 17 cycles | **PASS** |
| W08 M0 write admission P99 ≤29 cycles | 27 cycles | 69 cycles | **FAIL** |
| W12 Jain grant-rate index ≥0.98 | 0.9999999733 | 0.9999999733 | **PASS** |

Two required criteria fail. D045 is unchanged and B is rejected under its frozen limits.

## W08 latency and throughput

Values below are median-of-five per-seed statistics, in cycles. Each seed contributes 5,000 completed samples per active manager/direction; W08 directions are shown separately.

| Manager / direction | Admission P50 A→B | P95 A→B | P99 A→B | Max A→B | Response P99 A→B | End-to-end P99 A→B |
|---|---:|---:|---:|---:|---:|---:|
| M0 read | 20→3 | 21→17 | 21→17 | 21→35 | 65→57 | 86→66 |
| M0 write | 27→67 | 27→69 | 27→69 | 27→69 | 6→6 | 33→75 |
| M1 read | 20→27 | 21→56 | 21→57 | 21→71 | 78→66 | 86→98 |
| M1 write | 27→67 | 27→69 | 27→69 | 27→69 | 21→21 | 48→90 |
| M2 read | 20→2 | 21→16 | 21→16 | 21→17 | 65→58 | 86→67 |
| M2 write | 27→4 | 27→27 | 27→27 | 27→27 | 7→7 | 34→34 |

W08 payload throughput (read + write, bytes/cycle) is M0 **0.663→0.670** (+1.1%), M1 **10.607→6.341** (−40.2%), and M2 **0.995→2.595** (+160.9%). These are per-manager common-window rates, aggregated by direction for throughput only. The per-direction samples remain separate in `matched_median_of_five.csv`.

## Scheduler waiting, fairness and endpoint effects

- W08 median maximum eligible service losses by manager/direction are recorded in `matched_median_of_five.csv`. M0 write: 2→12; M1 read: 2→8; M1 write: 2→12; M2 read: 2→1 opportunities. These are arbitration/service-opportunity observations, not arbitrary elapsed cycles. Target backpressure is separately instrumented.
- A representative W08 seed-1 M0 write waited 69 cycles for address admission with 12 eligible service losses and zero target AW/AR/W stall cycles. M1's representative write also waited 69 cycles with 12 such losses and no target stalls. This points to scheduler contention/priority as the admission delay in these examples, distinct from endpoint queue backpressure.
- The fixed endpoint response path still contributes substantial read tails. For example, A's W08 M2 read response P99 is 65 cycles versus admission P99 21; B lowers response P99 to 58 while admission falls to 16. The deterministic endpoint does not represent a production memory.
- W12 equal-demand Jain grant-rate index is 0.9999999733 for A and B (median of five; each seed is also in `run_summary.json`). Do not generalize this equal-demand result to heterogeneous W08 traffic.
- W13 parallel-target address-progress cycles for seeds 1–5: A `[2823, 2720, 2775, 2848, 2868]`; B `[2812, 2727, 2783, 2865, 2884]`. Independent target progress is retained in both designs.

## Synthesis and routed implementation

Fixed LFE5U-45F/CABGA381/speed-grade-6 target, same common wrapper, tools and route seeds 1–5. Each architecture completed 55 attempts: the seven frozen coarse targets 50/75/100/125/150/175/200 MHz and the 5-MHz refinement points 55/60/65/70 MHz.

| Resource/timing | A | B | B−A |
|---|---:|---:|---:|
| Direct Fabric LUT4 | 5,046 | 5,730 | +684 (+13.6%) |
| Direct Fabric FF | 1,219 | 1,426 | +207 (+17.0%) |
| Wrapped LUT4 | 5,226 | 5,826 | +600 (+11.5%) |
| Wrapped FF | 1,649 | 1,856 | +207 (+12.6%) |
| Wrapped routed combinational cells at 50 MHz | 6,020 | 6,982 | +962 (+16.0%) |
| Highest all-five-seed timing-clean target | 60 MHz | 55 MHz | −5 MHz |

At the common 50-MHz request, per-seed achieved frequency / critical path delay (MHz / ns) was: A seed 1 `63.91/15.646`, 2 `64.38/15.532`, 3 `63.44/15.763`, 4 `66.12/15.123`, 5 `62.47/16.007`; B seed 1 `58.15/17.196`, 2 `59.51/16.805`, 3 `59.47/16.816`, 4 `58.78/17.014`, 5 `55.29/18.085`. Exact rows for every frequency/seed, including critical path endpoints, WNS, utilization and route status, are in `ppa_route_comparison.csv`.

Neither design mapped DP16KD or TRELLIS_RAMW in these wrapped routes. A's 65-MHz target passed for one seed only; B's 60-MHz target failed for all seeds. At the 50-MHz target, the slowest routed path delay was 16.007 ns for A and 18.085 ns for B. A representative A path runs from manager AW address input logic to the registered target AW length path. B's representative critical path runs from manager AW address input logic through QoS/age selection to manager AWREADY. This supports an added arbitration-path cost in the tested build, but is not a general timing-signoff conclusion.

## Qualification, commands and evidence

Six B qualification cases (W01, W02, W07, W08, W12, W13) and their matched A cases passed before the full sweep. Each used a reduced qualification quota and is not mixed into canonical results.

Canonical commands:

```bash
ARCH_BENCH_OUT_ROOT=results/raw/arch_a_matched_v2 scripts/run_arch_a_benchmark.sh
ARCH_BENCH_OUT_ROOT=results/raw/arch_b_full_v1 scripts/run_arch_b_benchmark.sh
ARCH_A_PPA_OUT=results/raw/arch_a_ppa_matched_v1 scripts/run_arch_a_ppa.sh
ARCH_PPA_ARCH=B ARCH_A_PPA_OUT=results/raw/arch_b_ppa_matched_v1 scripts/run_arch_a_ppa.sh
```

Reprocess and regenerate:

```bash
.venv/bin/python bench/summarize_benchmark.py results/raw/arch_a_matched_v2
.venv/bin/python bench/summarize_benchmark.py results/raw/arch_b_full_v1
.venv/bin/python bench/compare_ab.py results/raw/arch_a_matched_v2 results/raw/arch_b_full_v1 results/processed/ab_comparison
.venv/bin/python bench/summarize_ppa.py results/raw/arch_a_ppa_matched_v1
.venv/bin/python bench/summarize_ppa.py results/raw/arch_b_ppa_matched_v1
.venv/bin/python bench/plot_ab_comparison.py
```

Raw transaction/event data, JUnit results, route logs and reports remain locally under `results/raw/arch_a_matched_v2`, `arch_b_full_v1`, `arch_a_ppa_matched_v1` and `arch_b_ppa_matched_v1`. Qualification data is under the corresponding qualification directories. Compact committed outputs are the CSV/JSON files in this directory, including `ppa_route_comparison.csv` and `ppa_resource_comparison.json`, and the four figures in `figures/`.

## Engineering conclusion and limitations

The frozen QoS/aging policy does deliver the M2 W08 admission target and preserves equal-demand W12 grant fairness, while increasing M2's W08 throughput. It fails the DMA throughput floor and M0 write-tail limit, and costs additional logic and 5 MHz of all-seed timing-clean target in this fixed-wrapper sweep. **Decision: REJECT B under D045.** No post-result tuning was performed.

Results apply only to the documented AXI subset, five frozen seeds, fixed synthetic endpoint, workload/sample policy, specific source manifests, and common wrapper/EDA flow. The bounded component formal proofs are not exhaustive whole-Fabric proofs. Routed results are not device timing signoff or universal Fmax. Architecture B remains a verified functional experimental variant; no new scheduler version was created.
