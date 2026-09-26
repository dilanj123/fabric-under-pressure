# Per-manager write-owner primitive

## Scope

`rtl/axi_write_owner.sv` models the registered routing context created by an already-accepted AW for one manager. It stores `active`, target, original ID, internal ID and a 5-bit `beats_remaining` counter. The context is held through accepted W beats and is released only by the accepted final beat with the expected `WLAST`. No B input is present: write-owner lifetime is distinct from outstanding-write lifetime, which remains the responsibility of the later outstanding tracker/fabric integration.

The frozen D030 policy is used: allocation is evaluated from registered pre-state, so a final W completion cannot recycle the owner in the same cycle. The owner is available on the following cycle.

## Directed simulation

Command:

```sh
source /Users/Dilan/eda/fabric-under-pressure/oss-cad-suite/environment
scripts/run_write_owner_checks.sh
```

`results/raw/write_owner/simulation.log` reports `PASS axi_write_owner_tb checks=22`. The suite covers reset, allocation and metadata capture, allocation while active, W without owner, same-cycle allocate/W pre-state behavior, single-, four- and 16-beat writes, stalls before/midway/before final beat, early and missing `WLAST`, correct release, same-cycle final-W/reallocation blocking, following-cycle reallocation and reset while active.

`results/raw/write_owner/composition_simulation.log` reports `PASS axi_write_owner_3_tb checks=6`. Three independent contexts (M0→S0, M1→S1, M2→S2) can be active and complete independently. This does not prove per-target uniqueness.

## Formal

`formal/axi_write_owner_formal.sv` is checked by Yices through SBY. The prove task is bounded BMC to depth 12; the cover task is bounded to depth 16. Legal allocation traces assume `allocate_len <= 15`. Malformed W events are not assumed away for diagnostic properties. The checked properties cover state bounds, exact allocation capture, context stability, no overwrite during active ownership, beat accounting, no underflow, correct WLAST release, no premature release, malformed-event diagnostics and next-cycle reallocation. Covers reach single- and 16-beat contexts, stalls, malformed events, completion and reallocation.

Evidence: `results/raw/write_owner/formal_prove/logfile.txt` and `results/raw/write_owner/formal_cover/logfile.txt`. These are bounded primitive properties, not an unbounded liveness proof or whole-Fabric proof.

## Synthesis

The target-aware Yosys `synth_ecp5` smoke completes with `Found and reported 0 problems`. Primitive-only mapped resources are 54 LUT4, 20 TRELLIS_FF, 7 CCU2C and 3 PFUMX (plus one L6MUX21); no EBR or DSP cells are present. This is synthesis evidence for the primitive, not Fabric PPA.

## Limits

Target-specific request eligibility, target ownership uniqueness, AW/W channel integration, W routing, WREADY behavior, B/R response paths, S3 endpoint behavior and the complete Architecture-A/Architecture-B Fabrics remain unimplemented and unverified.
