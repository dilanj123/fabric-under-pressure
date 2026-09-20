# Timing and Performance Methodology

**Status:** methodology skeleton; no fabric timing/performance evidence exists.

## Frozen implementation target
LFE5U-45F / CABGA381 / speed grade 6 using a pinned nextpnr-ECP5/Trellis flow.

## Latency labels
Gate 1 will retain distinct timestamps for request presentation, request acceptance, arbitration wait and response completion. Queueing/arbitration/end-to-end response latency must never be merged without labels.

## A/B fairness
Freeze topology, widths, IDs, outstanding depth, address map, endpoints, buffers, workloads, tool versions, wrapper, synthesis/P&R settings, constraints, seeds and measurement scripts.

## Compact P&R wrapper method — provisional until Phase-0 smoke validates it
Use a common registered stimulus-expansion + signature-reduction wrapper:
- a small registered external seed/command interface drives a registered PRNG/state expander;
- expanded registered signals feed the internal DUT cone;
- DUT outputs are consumed by a registered XOR/CRC-like signature reducer;
- signature/status are the only small external outputs;
- wrapper is identical between A and B;
- register boundaries prevent simple constant propagation from deleting the DUT and reduce top-level I/O pressure.

### Required Phase-0 validation
Run `scripts/run_smoke_wrapper.sh` and inspect Yosys statistics/netlist to demonstrate the generic payload cone survives optimization. Until that passes, the wrapper method is **PLAN**, not evidence.

### Interpretation limitation
The wrapper contributes overhead, so absolute resource numbers must be reported separately/with caveats. Relative A/B comparison is valid only if wrapper structure and parameters are identical.

## CDC timing later
When CDC is added: define clocks, asynchronous clock groups, justified false paths only, and cross-domain latency accounting. No blanket false-path masking.
