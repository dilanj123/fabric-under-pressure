# Architecture-A 3-way round-robin arbiter evidence

## Scope

`rtl/axi_rr_arbiter_3.sv` is a standalone scheduler for one target and one request direction. Its three request bits are assumed to have already passed upstream eligibility checks. It does not decode addresses, inspect AXI payloads, arbitrate channels, implement write ownership, or integrate with the Fabric.

The arbiter uses a registered 2-bit pointer and one registered held grant. The pointer resets to M0 (`2'b00`) and advances only after `grant_valid && downstream_ready`. A stalled grant remains registered until handshake, independent of request changes.

## Commands and results

The complete local flow was run with the qualified OSS CAD Suite environment sourced from `/Users/Dilan/eda/fabric-under-pressure/oss-cad-suite/environment`:

```text
scripts/run_rr_arbiter_checks.sh
```

The script runs Verilator lint/build and directed simulation, target-aware ECP5 Yosys synthesis, safety/selection formal prove and cover, and a separate fairness formal harness.

| Check | Exit | Evidence | Classification |
|---|---:|---|---|
| Verilator lint and directed build/simulation | 0 | `results/raw/rr_arbiter/verilator_lint.log`, `verilator_build.log`, `simulation.log` | SIM/REPRO |
| Directed simulation | 0 | `results/raw/rr_arbiter/simulation.log` | SIM; `PASS rr_arbiter_tb checks=70` |
| Yosys `synth_ecp5` | 0 | `results/raw/rr_arbiter/yosys_synth.log`, `axi_rr_arbiter_3_ecp5.json` | SYNTH |
| Safety/selection BMC prove | 0 | `results/raw/rr_arbiter/formal_prove/logfile.txt` | FORMAL; bounded depth 12 |
| Sequential covers | 0 | `results/raw/rr_arbiter/formal_cover/logfile.txt` | FORMAL; bounded cover depth 12 |
| Fairness BMC | 0 | `results/raw/rr_arbiter/formal_fairness/logfile.txt` | FORMAL; bounded depth 12 |

## Directed coverage

The 70 checks include all 24 pointer/request combinations, all 2-request and 3-request ties, all single-request cases, continuous all-manager rotation, persistent two-request pairs, dynamic request arrival, 1/2/5/10-cycle stalls, held-grant stability, reset during a held grant, reset priority restoration and persistent-request fairness sequences.

## Formal scope

The safety harness proves one-hot-or-zero grants, valid/grant equivalence, legal pointer states, cyclic first-match selection, no phantom selection, hold stability across request changes, pointer stability without handshake and pointer rotation on handshake. Covers reach each pointer, each manager winner, multi-cycle holds, changed requests during a hold, pointer wrap, two-request skips and reset while held.

The fairness harness assumes only for the fairness property that `request[0]` remains asserted and `downstream_ready` remains high. Under those assumptions it checks that no more than two competing successful grants occur before M0 service. Safety properties use unconstrained requests and READY. All formal results are bounded BMC results, not unbounded inductive proofs.

Formal engine is `smtbmc` with Yices. Verification-only state ports are enabled with the `FORMAL` define; the normal production interface remains the seven-port arbiter interface.

## Synthesis and warnings

Exact synthesis command:

```text
yosys -Q -p "read_verilog -sv /Users/Dilan/Projects/fabric-under-pressure/rtl/axi_rr_arbiter_3.sv; synth_ecp5 -top axi_rr_arbiter_3 -json /Users/Dilan/Projects/fabric-under-pressure/results/raw/rr_arbiter/axi_rr_arbiter_3_ecp5.json; stat"
```

Primitive-only result:

```text
38 LUT4
15 PFUMX
9 L6MUX21
6 TRELLIS_FF
```

Yosys reported zero problems. The one warning is the qualified target flow's experimental `write_xaiger2` notice; it is unrelated to the RTL and does not affect the synthesis exit status. These figures are not Fabric PPA.

## Limitations

The primitive has no AXI channel integration, target-specific instantiation, payload mux, request eligibility logic, write ownership, response routing, S3 endpoint or integrated Fabric fairness evidence. The formal results are finite-depth and apply only to the named properties and fairness assumptions.
