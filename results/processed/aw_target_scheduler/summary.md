# Architecture-A target-specific AW scheduler

## Scope

`rtl/axi_aw_target_scheduler_a.sv` is one parameterized logical-target boundary. It consumes manager request facts and registered per-manager write-owner status, computes the frozen AW eligibility equation, and instantiates `axi_rr_arbiter_3`. It exposes the selected manager and `aw_accept_fire`; it does not mux AW payloads, generate AXI VALID/READY, allocate outstanding/write-owner state, or route W/B/R.

Target identity is parameterized by `TARGET_INDEX` 0..3. The owner status uses the one-hot target encoding from `rtl/fabric_addr_map_pkg.sv`.

## D031

On an accepted AW, the boundary gates the RR request vector to zero for that scheduling edge. The RR pointer still advances from the accepted winner; the next AW grant is selected only after registered owner-free state is visible. This prevents stale successor lookahead through the W-owned interval.

## Directed simulation

Command:

```sh
source /Users/Dilan/eda/fabric-under-pressure/oss-cad-suite/environment
scripts/run_aw_target_scheduler_checks.sh
```

`results/raw/aw_target_scheduler/simulation.log` reports `PASS axi_aw_target_scheduler_tb checks=39`. The checks cover every eligibility blocker, a legal S3/unmapped request, manager-owner gating, target-owner gating for all three possible owners, owner activity on another target, outstanding blocking, RR contention, READY stall/held grant, accepted-AW D031 suppression, owner-busy blocking, resume from the advanced pointer and a two-target non-global-serialization case.

## Formal

The standalone boundary proof uses Yices through SBY `smtbmc`, bounded BMC depth 16, with only the initial reset assumption. It checks the exact eligibility equation, target-owner exclusion, accepted-AW safety, grant wiring and the D031 gated request vector. The standalone cover uses bounded cover depth 16.

The verification-only composition instantiates one S0 boundary and three `axi_write_owner` contexts. It proves that at most one owner can be active for the target and that an accepted AW is followed by target ownership and no second AW until ownership clears. It uses Yices through SBY, bounded BMC depth 24 and cover depth 32. Accepted owner lengths use the legal 0..15 domain; no READY, busy or contention assumption removes the ownership safety cases. These are bounded composition results, not an unbounded proof and not full AW-channel evidence.

Evidence: `results/raw/aw_target_scheduler/formal_prove/logfile.txt`, `formal_cover/logfile.txt`, `formal_composition_prove/logfile.txt`, and `formal_composition_cover/logfile.txt`.

## Synthesis

The production boundary completes:

```sh
yosys -Q -p "read_verilog -sv rtl/axi_rr_arbiter_3.sv rtl/axi_aw_target_scheduler_a.sv; synth_ecp5 -top axi_aw_target_scheduler_a -json results/raw/aw_target_scheduler/axi_aw_target_scheduler_a_ecp5.json; stat"
```

Exit status is 0 with Yosys check reporting 0 problems. The primitive/composed-boundary result is 43 LUT4, 6 TRELLIS_FF, 16 PFUMX and 7 L6MUX21; no EBR/DSP cells are present. Yosys reports one experimental-feature warning. These are synthesis figures for this boundary only, not Fabric PPA.

## Limits

AW payload muxing, manager AWREADY/target AWVALID generation, production tracker/owner allocation fanout, W routing, AR/B/R paths, S3 completion, full Architecture-A integration, Architecture B and Fabric performance remain unimplemented and unverified.
