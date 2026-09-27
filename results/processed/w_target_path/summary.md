# Registered W target path evidence

## Scope

One parameterized logical-target W path, driven only by registered shared write-owner state. The path accepts manager W beats into a one-entry registered target slot, permits non-final drain/refill, forbids final-WLAST refill, and emits target-delivery owner events. The focused composition includes one Architecture-A AW path and the shared per-manager write-state bank. B routing and four-target integration are outside scope.

## Commands and results

- `./scripts/run_w_target_path_checks.sh` — exit 0.
- Verilator 5.053 devel (`v5.052-119-g014c9820d`) lint/build — exit 0.
- `axi_w_target_path_tb` — PASS, 15 checks.
- `axi_aw_w_state_composition_tb` — PASS, 14 checks.
- `yosys -Q -p "read_verilog -sv rtl/axi_w_target_path.sv; synth_ecp5 -top axi_w_target_path -json results/raw/w_target_path/axi_w_target_path_ecp5.json; stat"` — exit 0; Yosys found 0 structural problems.
- `sby -f -d results/raw/w_target_path/formal_prove axi_w_target_path.sby prove` — PASS, smtbmc/Yices, bounded BMC depth 20.
- `sby -f -d results/raw/w_target_path/formal_cover axi_w_target_path.sby cover` — PASS, smtbmc/Yices, bounded cover depth 24.
- `sby -f -d results/raw/aw_w_composition/formal_prove axi_aw_w_state_composition.sby prove` — PASS, smtbmc/Yices, bounded BMC depth 24.
- `sby -f -d results/raw/aw_w_composition/formal_cover axi_aw_w_state_composition.sby cover` — PASS, smtbmc/Yices, bounded cover depth 32.

## Simulation scope

The standalone suite checks W-before-AW blocking, owner-only WREADY, target routing, final-beat stall stability, target-side owner progress, non-final drain/refill, final no-refill, wrong-target blocking and conflicting-owner suppression. The composition suite checks AW admission into shared owner/outstanding state, W-before-AW, same-cycle AW/W behavior, target-stalled final W, target-side owner release while outstanding remains until B, and manager-indexed state behavior.

## Formal scope

Safety properties cover one-hot manager READY/fire, no WREADY without a matching registered owner, conflict suppression, target-delivery-only owner events, stalled payload stability, final-beat no-refill and reset clearing. Covers reach no-owner pending W, accepted W, stalled target W, non-final drain/refill, final delivery and owner conflict. The standalone and AW/state/W composition proofs are bounded; they are not unbounded or whole-Fabric AXI proofs. The composition harness assumes legal source stability and does not include B routing.

## Synthesis

The target-aware ECP5 synthesis contains 646 LUT4, 77 TRELLIS_FF, 313 PFUMX and 159 L6MUX21 cells. These are primitive/path synthesis figures, not Fabric PPA. Yosys reported one experimental-feature warning and no synthesis error.

## Limitations

The production state bank is not connected to a full four-target top. WREADY/VALID are verified at one-target and focused AW/state/W composition scope. B routing, AR/R, S3 response generation, complete Architecture A behavior, Architecture B and performance/PPA remain unproven.
