# Timing and Performance Methodology

**Status:** Gate-1 benchmark and metric contract remains frozen. The matched Architecture-A/B canonical simulation and common-wrapper ECP5 comparison is complete; see `results/processed/ab_comparison/summary.md`. D045 remains frozen and D047 rejects B under its criteria.

## Frozen implementation target
LFE5U-45F / CABGA381 / speed grade 6 using a pinned nextpnr-ECP5/Trellis flow.

For A/B comparison, use the qualified OSS CAD Suite release and Python pins recorded in `results/processed/gate0/tool_versions.md`, the frozen common wrapper `bench/arch_fabric_wrapper.sv`, identical synthesis scripts and parameters, nextpnr seeds `1,2,3,4,5`, and the fixed frequency sweep 50/75/100/125/150/175/200 MHz with 5-MHz refinement around a transition. Report routed path delay/derived target-period slack, utilization, seed, tool versions and exact command for every attempt. The Gate-0 100-MHz smoke is a qualification point, not Fabric timing evidence.

## Latency labels
Gate 1 will retain distinct timestamps for request presentation, request acceptance, arbitration wait and response completion. Queueing/arbitration/end-to-end response latency must never be merged without labels.

For request `q`, record `t_present`, `t_addr_accept`, `t_wlast`, `t_first_resp` and `t_complete`. Report admission latency as `t_addr_accept-t_present`; scheduler-contention cycles only when an eligible target service opportunity is lost; backpressure-blocked cycles separately; read response latency as `t_complete-t_addr_accept`; write data-phase latency as `t_wlast-t_addr_accept`; write response latency as `t_complete-t_wlast`; write accepted end-to-end latency as `t_complete-t_addr_accept`; and presentation-to-completion latency as `t_complete-t_present`. Read and write distributions remain separate.

Use the frozen `bench/workloads.yaml` policy: 500 warm-up completions, the first 5,000 measured samples per active manager, a common window until all active managers reach that count, per-seed summaries, and NumPy 2.3.5 `method=nearest` percentiles for P50/P95/P99.

## A/B fairness
Freeze topology, widths, IDs, outstanding depth, address map, endpoints, buffers, workloads, tool versions, wrapper, synthesis/P&R settings, constraints, seeds and measurement scripts.

## Compact P&R wrapper method — validated for generic preservation
Use a common registered stimulus-expansion + signature-reduction wrapper:
- an internally seeded registered LFSR generates legal one-beat requests and deterministic ready/response behavior;
- registered stimulus feeds the internal DUT cone;
- DUT outputs are consumed by a registered signature reducer;
- the wrapper exposes only `clk` and an 8-bit signature output;
- the complete wrapper is identical between A and B;
- register boundaries keep the Fabric observable while avoiding a large external AXI pin interface.

### Generic Phase-0 validation
`scripts/run_smoke_wrapper.sh` passed on the qualified host. Yosys retained a non-empty top module with 777 mapped cells, 375 TRELLIS_FF cells and 392 LUT4 cells behind a 17-bit top-level interface. This is generic wrapper methodology evidence, not Fabric PPA evidence.

### Fabric Architecture-A measurement

The full W00–W13 × five-seed matrix completed with 500 warm-up and 5,000 measured completions per active manager, using NumPy 2.3.5 `method="nearest"`. Per-run transaction records, hashes and summaries are indexed in `results/processed/arch_a_measurement/summary.md`. W08 shows M2 read admission P99 of 21 cycles (median of five seed P99s), with response/end-to-end P99 of 65/86 cycles and heavy S0 AR queue backpressure. W12 Jain grant-rate index is 0.9999999733 for each seed. W13 records same-cycle address progress at multiple targets.

Direct Fabric synthesis reports 5,046 LUT4 and 1,219 FF. Common-wrapper synthesis reports 5,226 LUT4 and 1,649 FF; routed wrapper use is 6,020 combinational cells and 1,649 FF. Five-seed nextpnr runs are timing-clean through the 60-MHz target; only one of five seeds passes at 65 MHz. The critical path varies by seed and includes AW decode/owner and R response logic. This is an Architecture-A wrapper result, not a general device timing signoff.

The measurable bottleneck and falsifiable QoS/aging hypothesis were frozen in D045 before B RTL. D045 was evaluated without tuning in Mission 4; the result and trade-offs follow.

### Matched Architecture-A/B comparison (Mission 4)

Both architectures completed 70/70 W00–W13 × five-seed runs with 500 warm-up and 5,000 retained completions per active manager. Workload SHA is `31c599caa7344c938b588a0f22404cfcfe5fe53b3ef5fae40a568130cfadfca4`; the same transaction intent hashes, generator, endpoint, benchmark engine and sample policy were checked. A and B also completed 55 ECP5 routes each using the same final wrapper, device, tools and route seeds.

Under W08, B's median-of-five M2 read-admission P99 is 16 cycles versus A's 21, and M0 read-admission P99 is 17 versus 21. However, M1 combined payload throughput is 6.341 versus 10.607 bytes/cycle (−40.2%), and M0 write-admission P99 is 69 versus 27 cycles. W12 Jain grant-rate index is 0.9999999733 for both. B's highest tested all-five-seed timing-clean target is 55 MHz versus A's 60 MHz. D045 therefore fails overall; decision D047 is **REJECT B under frozen criteria**. The scheduler was not tuned after results.

Direct Fabric LUT4/FF counts are A 5,046/1,219 and B 5,730/1,426. Common-wrapper LUT4/FF counts are A 5,226/1,649 and B 5,826/1,856. The tested B representative critical path includes QoS/age selection from manager AW address inputs to manager AWREADY. This is evidence from the fixed wrapper and tool flow, not timing signoff. Full per-manager read/write metrics, route tables, event traces and four plots are in the processed comparison directory.

### Interpretation limitation
The wrapper contributes overhead, so direct Fabric and wrapped resource numbers are reported separately. The Mission-4 A/B PPA uses identical final wrapper logic and parameters. A/B simulation manifests contain a comment-only wrapper-hash difference because the wrapper comment changed between runs; the wrapper is not compiled in those cocotb runs, and the PPA builds use the same wrapper hash.

## CDC timing later
When CDC is added: define clocks, asynchronous clock groups, justified false paths only, and cross-domain latency accounting. No blanket false-path masking.
