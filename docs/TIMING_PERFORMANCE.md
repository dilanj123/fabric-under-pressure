# Timing and Performance Methodology

**Status:** Gate-1 benchmark and metric contract frozen; Gate-0 wrapper methodology validated; no fabric timing/performance evidence exists.

## Frozen implementation target
LFE5U-45F / CABGA381 / speed grade 6 using a pinned nextpnr-ECP5/Trellis flow.

For later A/B comparison, use the qualified OSS CAD Suite release and Python pins recorded in `results/processed/gate0/tool_versions.md`, the common wrapper from `smoke/wrapper_preserve.sv`, identical synthesis scripts and parameters, nextpnr seeds `1,2,3,4,5`, and the fixed frequency sweep 50/75/100/125/150/175/200 MHz with 5-MHz refinement around a transition. Report WNS, routed utilization, seed, tool versions and exact command for every attempt. The Gate-0 100-MHz smoke is a qualification point, not Fabric timing evidence.

## Latency labels
Gate 1 will retain distinct timestamps for request presentation, request acceptance, arbitration wait and response completion. Queueing/arbitration/end-to-end response latency must never be merged without labels.

For request `q`, record `t_present`, `t_addr_accept`, `t_wlast`, `t_first_resp` and `t_complete`. Report admission latency as `t_addr_accept-t_present`; scheduler-contention cycles only when an eligible target service opportunity is lost; backpressure-blocked cycles separately; read response latency as `t_complete-t_addr_accept`; write data-phase latency as `t_wlast-t_addr_accept`; write response latency as `t_complete-t_wlast`; write accepted end-to-end latency as `t_complete-t_addr_accept`; and presentation-to-completion latency as `t_complete-t_present`. Read and write distributions remain separate.

Use the frozen `bench/workloads.yaml` policy: 500 warm-up completions, the first 5,000 measured samples per active manager, a common window until all active managers reach that count, per-seed summaries, and NumPy 2.3.5 `method=nearest` percentiles for P50/P95/P99.

## A/B fairness
Freeze topology, widths, IDs, outstanding depth, address map, endpoints, buffers, workloads, tool versions, wrapper, synthesis/P&R settings, constraints, seeds and measurement scripts.

## Compact P&R wrapper method — validated for generic preservation
Use a common registered stimulus-expansion + signature-reduction wrapper:
- a small registered external seed/command interface drives a registered PRNG/state expander;
- expanded registered signals feed the internal DUT cone;
- DUT outputs are consumed by a registered XOR/CRC-like signature reducer;
- signature/status are the only small external outputs;
- wrapper is identical between A and B;
- register boundaries prevent simple constant propagation from deleting the DUT and reduce top-level I/O pressure.

### Phase-0 validation
`scripts/run_smoke_wrapper.sh` passed on the qualified host. Yosys retained a non-empty top module with 777 mapped cells, 375 TRELLIS_FF cells and 392 LUT4 cells behind a 17-bit top-level interface. This is generic wrapper methodology evidence, not Fabric PPA evidence.

### Interpretation limitation
The wrapper contributes overhead, so absolute resource numbers must be reported separately/with caveats. Relative A/B comparison is valid only if wrapper structure and parameters are identical.

## CDC timing later
When CDC is added: define clocks, asynchronous clock groups, justified false paths only, and cross-domain latency accounting. No blanket false-path masking.
