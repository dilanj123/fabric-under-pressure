# Address Decoder Primitive Evidence

**Result: PASS for the decoder primitive only.** The implementation is a pure combinational 32-bit raw-address decoder with a one-hot four-bit target select: bit 0=S0, bit 1=S1, bit 2=S2 and bit 3=S3/default. Request legality, burst-boundary checks and unsupported-request policy remain external as required by the frozen architecture.

| Check | Command | Exit | Evidence | Classification |
|---|---|---:|---|---|
| Verilator lint | `verilator --lint-only --timing -Wall rtl/fabric_addr_map_pkg.sv rtl/axi_address_decoder.sv` | 0 | `results/raw/decoder/verilator_lint.log` | RTL SIMULATION INFRASTRUCTURE |
| Directed simulation | `verilator --binary ...; results/raw/decoder/sim_work/address_decoder_tb` through `scripts/run_decoder_checks.sh` | 0 | `results/raw/decoder/simulation.log` | RTL SIMULATION VERIFIED |
| Yosys elaboration/synthesis | `yosys -Q -p "read_verilog -sv ...; hierarchy -top axi_address_decoder; proc; check; stat"` | 0 | `results/raw/decoder/yosys_synth.log` | SYNTHESISED |
| Formal prove | `sby -f -d results/raw/decoder/formal_prove address_decoder.sby prove` | 0 | `results/raw/decoder/formal_prove/logfile.txt` and `PASS` | FORMALLY CHECKED UNDER DOCUMENTED ASSUMPTIONS |
| Formal cover | `sby -f -d results/raw/decoder/formal_cover address_decoder.sby cover` | 0 | `results/raw/decoder/formal_cover/logfile.txt` and `PASS` | FORMALLY CHECKED UNDER DOCUMENTED ASSUMPTIONS |

The directed test ran 19 cases covering all mapped boundaries, adjacent regions, representative interiors and unmapped addresses. Formal uses unconstrained `(* anyconst *)` address input, Yices through SBY 0.69, prove depth 1 and cover depth 1. The proof covers exact one-hot selection and mapped/default routing; it does not prove any wider fabric behavior.

Warning review: Verilator lint and Yosys reported no warnings or synthesis problems. The initial Yosys import incompatibility was repaired by using fully qualified package constants, consistent with the Gate-0-qualified conservative SV subset.
