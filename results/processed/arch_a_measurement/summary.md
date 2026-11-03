# Architecture-A canonical measurement

**Status:** Architecture-A measurement complete. Architecture B is not implemented; the Gate-4 A/B comparison remains open.

## Frozen setup and completion

- `bench/workloads.yaml` was unchanged; SHA-256 `31c599caa7344c938b588a0f22404cfcfe5fe53b3ef5fae40a568130cfadfca4`.
- Seeds: `0xFABC0001`–`0xFABC0005`; generator: `arch-bench-xorshift32-v1-round-robin-manager-draws`.
- Command: see [`run_command.txt`](../../raw/arch_a_full_final/run_command.txt). The PPA command and route policy are in [`PPA run_command.txt`](../../raw/arch_a_ppa_complete/run_command.txt).
- Each active manager reached 500 warm-up and 5,000 measured completions. Sampling stopped only after all active managers reached quota; all traffic in that common window contributes to throughput. W00 is idle and has no latency quota.
- NumPy 2.3.5 `method="nearest"`. Percentiles are measured in ACLK cycles. `t_wlast` is manager-facing accepted WLAST; target WLAST is tracked separately for ownership release.
- The 50,000 transaction intents per manager were generated before simulation. `run_summary.json` retains workload/configuration, intent, trace, driver and generator hashes for all 70 runs.

## W00–W13 × five-seed completion matrix

| Workload | FABC0001 | FABC0002 | FABC0003 | FABC0004 | FABC0005 |
|---|---|---|---|---|---|
| W00 idle | PASS | PASS | PASS | PASS | PASS |
| W01 M0 control | PASS | PASS | PASS | PASS | PASS |
| W02 M1 DMA | PASS | PASS | PASS | PASS | PASS |
| W03 M2 critical | PASS | PASS | PASS | PASS | PASS |
| W04 balanced mixed | PASS | PASS | PASS | PASS | PASS |
| W05 DMA + control | PASS | PASS | PASS | PASS | PASS |
| W06 DMA + critical | PASS | PASS | PASS | PASS | PASS |
| W07 all saturated | PASS | PASS | PASS | PASS | PASS |
| W08 adversarial QoS | PASS | PASS | PASS | PASS | PASS |
| W09 read-heavy | PASS | PASS | PASS | PASS | PASS |
| W10 write-heavy | PASS | PASS | PASS | PASS | PASS |
| W11 mixed 50/50 | PASS | PASS | PASS | PASS | PASS |
| W12 equal-demand fairness | PASS | PASS | PASS | PASS | PASS |
| W13 parallel targets | PASS | PASS | PASS | PASS | PASS |

All 70 runs have one passing cocotb testcase and no failures, errors or skips in JUnit XML. The runner validated the quota from each run's metadata. Exact per-seed/per-manager/per-direction records are in [`latency_throughput.csv`](latency_throughput.csv); run counters and replay hashes are in [`run_summary.json`](run_summary.json). Raw event traces remain under `results/raw/arch_a_full_final/` (about 1 GB).

## W08 latency and throughput

Each row shows the median across five seeds of the per-seed P50/P95/P99, plus the worst per-seed observed maximum. Samples are the median per-seed direction split; each manager contributes 5,000 measured completions total. Throughput is median payload bytes/cycle for that manager/direction.

| Manager / direction | Samples/seed | Admission P50/P95/P99 / max | Accepted-response P50/P95/P99 / max | End-to-end P50/P95/P99 / max | Bytes/cycle |
|---|---:|---:|---:|---:|---:|
| M0 read | 2,806 | 20 / 21 / 21 / 22 | 63 / 65 / 65 / 66 | 84 / 86 / 86 / 87 | 0.372 |
| M0 write | 2,194 | 27 / 27 / 27 / 27 | 6 / 6 / 6 / 6 | 33 / 33 / 33 / 33 | 0.291 |
| M1 read | 2,806 | 20 / 21 / 21 / 21 | 64 / 65 / 78 / 80 | 84 / 86 / 86 / 86 | 5.954 |
| M1 write | 2,194 | 27 / 27 / 27 / 27 | 21 / 21 / 21 / 21 | 48 / 48 / 48 / 48 | 4.653 |
| M2 read | 2,806 | 20 / 21 / 21 / 35 | 64 / 65 / 65 / 81 | 84 / 86 / 86 / 99 | 0.557 |
| M2 write | 2,194 | 27 / 27 / 27 / 27 | 7 / 7 / 7 / 7 | 33 / 34 / 34 / 34 | 0.438 |

W08 M1 total payload throughput was 10.607 bytes/cycle (read plus write, median of per-seed sums). M2 read admission P99 was 21 cycles in every seed, with a worst individual measured admission of 35 cycles. M2 read end-to-end P99 was 86 cycles and its worst individual measured completion latency was 99 cycles. M0 control P99 admission was 21 cycles for reads and 27 for writes.

## Contention, endpoint limits and parallelism

- W08 had 239,478 S0 target-AR `VALID && !READY` cycles and 23,210 stall episodes across five seeds; per-seed stalls were 47,817–47,949 cycles. The read queue reached depth 8. This is measured endpoint/buffer backpressure, distinct from arbitration.
- W08 recorded 72,477 AW and 92,449 AR eligible same-target grant losses across five seeds. The largest per-transaction count was two competing grants; the largest wall-cycle pending interval for M2 read was 35 cycles. The loss counter counts a successful competing address grant while another presented request is eligible, not arbitrary wait cycles.
- Target AW/W stalls and manager B/R stalls were zero under the canonical always-ready write-data/manager-response policy. They were instrumented and reported as zero; they were not added artificially.
- W08 all-three-manager live/presented activity totaled 332,435 cycles across seeds.
- W12 Jain index from actual manager address-grant rates was `0.9999999733` in each seed. W12 remains the equal-demand fairness case; this index is not used as a fairness verdict for heterogeneous workloads.
- W13 recorded 14,034 cycles across seeds with accepted address handshakes at two or more targets in the same cycle. Its per-seed M1 read and write throughput medians were 7.111 and 6.737 bytes/cycle, respectively, demonstrating independent target progress under the frozen split.
- The endpoint provides FIFO response ordering and a two-cycle response start; read responses then consume one beat per cycle. Thus response latency includes modeled target queue/service time and is not a pure arbitration metric.

## ECP5 synthesis and routed timing

Target: LFE5U-45F, CABGA381, speed grade 6; Yosys `synth_ecp5`, nextpnr-ecp5 and Trellis versions/commands are in the raw PPA directory. Direct Fabric synthesis and wrapped implementation are reported separately.

Qualified environment: OSS CAD Suite `2026-09-20` darwin-arm64; Verilator `5.053 devel`; Yosys `0.69+75` (git `f0b945f63-dirty`); nextpnr-ecp5 `0.11.1-30-g3e53a0bf`; Trellis/ecppack `1.4-82-g3afe7b5`; Python `3.11.6`; cocotb `2.1.0`; NumPy `2.3.5`. The Gate-0 version record and installed asset digest are `results/processed/gate0/tool_versions.md` and `results/raw/gate0/env/`.

| Synthesis scope | LUT4 | TRELLIS_FF | CCU2C | PFUMX | L6MUX21 |
|---|---:|---:|---:|---:|---:|
| Direct `axi_fabric_a` | 5,046 | 1,219 | 288 | 807 | 270 |
| Common wrapper + Fabric | 5,226 | 1,649 | 291 | 816 | 273 |

The routed wrapper used 6,020 combinational cells, 1,649 FFs, 9 I/Os, and no DP16KD/TRELLIS_RAMW. These are wrapper totals and are not reduced by subtracting estimated wrapper logic.

| nextpnr target | Seeds 1–5 all timing-clean? | Minimum reported achieved frequency |
|---:|---|---:|
| 50 MHz | Yes | 62.473 MHz |
| 55 MHz (refinement) | Yes | 62.473 MHz |
| 60 MHz (refinement) | Yes | 62.473 MHz |
| 65 MHz (refinement) | No (1/5) | 62.473 MHz |
| 70 MHz (refinement) | No | 62.473 MHz |
| 75, 100, 125, 150, 175, 200 MHz | No | 62.473 MHz |

The highest tested all-seed timing-clean target is **60 MHz**. At that target the five routed path delays were 15.646, 15.532, 15.763, 15.123 and 16.007 ns, giving derived target-period slack of 1.021, 1.135, 0.904, 1.544 and 0.660 ns. These slack values are calculated from the routed critical-path delay in the nextpnr JSON; the tool JSON reports achieved frequency rather than a standalone WNS field. At 65 MHz, only seed 4 passes. This is not a general timing-closure claim or an A/B result.

Critical register-to-register paths vary by placement seed. Seed 1, the slowest seed, runs from a manager AW address register to a target AWLEN register through address decode/AW selection and write-owner logic. Other seeds' critical paths include the target RID to manager RDATA/RLAST paths. The timing evidence therefore points to both address-control and response datapaths rather than a single universal path.

Full 55-attempt timing/utilization/path data are in [`route_summary.csv`](route_summary.csv); the all-seed summary is [`ppa_summary.json`](ppa_summary.json). Raw per-attempt nextpnr logs, JSON reports and textcfg files are under `results/raw/arch_a_ppa_complete/wrapped/routes/`.

## Measured bottleneck and Architecture-B hypothesis

Architecture A's W08 limitation has two parts. Three-manager RR contention contributes repeated competing address grants (two per continuously competing request in the observed three-way case), while the depth-8 S0 read queue accumulates up to 47.9k AR-stall cycles per seed and dominates the gap between M2 read admission P99 (21 cycles) and response/end-to-end P99 (65/86 cycles). QoS arbitration can plausibly improve address admission, but cannot reorder the frozen FIFO endpoint responses or bypass active target service. Long M1 writes also hold the target W owner for their burst; this is an ownership constraint, not an arbitration loss.

**Frozen falsifiable hypothesis (D045):** With the planned B policy (4-bit AxQOS preference; per-manager/target/direction 8-bit saturating age; threshold 64; starved RR escape; RR ties; held-selection stability), W08 M2 read admission P99 should improve by at least 20% versus Architecture A's five-seed median of 21 cycles (B median-of-seed P99 at most 16 cycles). W08 M1 total payload throughput must not regress by more than 5%, and neither W08 M0 direction's admission P99 may regress by more than 10%. W12 Jain must remain at least 0.98, starvation evidence must remain bounded under the documented recurring-service assumptions, and area plus the same all-seed routed timing method must be reported. M2 response/end-to-end P99 is a secondary observation: the FIFO endpoint may limit its improvement even if admission improves. The hypothesis may be rejected if these criteria fail.

## Scope and limitations

This is a reproducible Architecture-A baseline under the frozen synthetic endpoint, not a production-memory performance claim. Manager B/R backpressure is zero in the canonical policy. Only the requested Architecture-A workload matrix and common-wrapper PPA baseline are complete; no B RTL or A/B comparison exists. No unrestricted AXI4 compliance, whole-Fabric exhaustive proof, P99 outside these workloads, or general ECP5 device timing signoff is claimed.
