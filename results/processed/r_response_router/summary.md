# R response router evidence summary

## Scope

This evidence covers the common `axi_r_response_router` and a focused composition with the existing one-target AR path and shared read-state bank. It does not cover S3 response generation, recorded-target response-source matching, or full four-target production integration.

## Commands

The reproducible flow is:

```text
source /Users/Dilan/eda/fabric-under-pressure/oss-cad-suite/environment
scripts/run_r_response_router_checks.sh
```

The production synthesis command is:

```text
yosys -Q -p "read_verilog -sv rtl/axi_rr_arbiter_4.sv rtl/axi_r_response_router.sv; synth_ecp5 -top axi_r_response_router -json results/raw/r_response_router/axi_r_response_router_ecp5.json; stat"
```

## Simulation

Verilator directed simulations pass:

* `axi_r_response_router_tb`: 34 checks;
* `axi_r_burst_lengths_tb`: 50 checks for 2-, 4- and 16-beat bursts;
* `axi_ar_r_read_lifecycle_tb`: 9 checks for AR admission through accepted RLAST completion.

The suites cover target contention, per-manager burst lock, target gaps, manager backpressure, non-final drain/refill, final no-refill, invalid prefix, non-busy RID, locked-RID changes, same visible IDs across managers, different-ID out-of-order completion, S3 transport and reset.

## Formal

`formal/axi_r_response_router.sby` uses Yices through SBY `smtbmc`. The prove task is bounded BMC depth 24; the cover task is bounded cover depth 32. Assumptions are reset initialization/release and independent per-target source stability while that target is stalled. Manager `RREADY` and other target channels remain unconstrained. Properties cover target-handshake admission, validation, occupied-slot blocking, lock establishment/persistence, no interleaving, final no-refill, completion separation and meaningful focused covers. No unbounded claim is made.

## Synthesis

The ECP5-targeted Yosys synthesis exits 0 and reports zero design-check problems. Primitive/path statistics are 1,786 LUT4, 284 TRELLIS_FF, 353 PFUMX and 102 L6MUX21. One Yosys experimental-feature warning is recorded; there are no synthesis errors. These are primitive/path figures and are not Fabric PPA.

## Limitations

The shared read-state bank does not expose a complete per-ID recorded-target table, so returned-target matching is not claimed. S3 DECERR generation, full four-target production composition, complete Architecture A, Architecture B, independent Python end-to-end oracle results, timing, performance and PPA remain outside this evidence.
