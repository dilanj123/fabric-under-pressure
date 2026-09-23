# Address Decoder Primitive Evidence

**Result: PASS for the decoder primitive only.** The implementation is a pure combinational 32-bit raw-address decoder with a one-hot four-bit target select: bit 0=S0, bit 1=S1, bit 2=S2 and bit 3=S3/default. Request legality, burst-boundary checks and unsupported-request policy remain external as required by the frozen architecture.

| Check | Command | Exit | Evidence | Classification |
|---|---|---:|---|---|
| Verilator lint | `verilator --lint-only --timing -Wall rtl/fabric_addr_map_pkg.sv rtl/axi_address_decoder.sv` | 0 | `results/raw/decoder/verilator_lint.log` | RTL SIMULATION INFRASTRUCTURE |
| Directed simulation | `verilator --binary ...; results/raw/decoder/sim_work/address_decoder_tb` through `scripts/run_decoder_checks.sh` | 0 | `results/raw/decoder/simulation.log` | RTL SIMULATION VERIFIED |
| Yosys ECP5 synthesis | `yosys -Q -p "read_verilog -sv rtl/fabric_addr_map_pkg.sv rtl/axi_address_decoder.sv; synth_ecp5 -top axi_address_decoder -json results/raw/decoder/axi_address_decoder_ecp5.json; stat"` | 0 | `results/raw/decoder/yosys_synth.log` | SYNTHESISED |
| Formal prove | `sby -f -d results/raw/decoder/formal_prove address_decoder.sby prove` | 0 | `results/raw/decoder/formal_prove/logfile.txt` and `PASS` | FORMALLY CHECKED UNDER DOCUMENTED ASSUMPTIONS |
| Formal cover | `sby -f -d results/raw/decoder/formal_cover address_decoder.sby cover` | 0 | `results/raw/decoder/formal_cover/logfile.txt` and `PASS` | FORMALLY CHECKED UNDER DOCUMENTED ASSUMPTIONS |

The directed test ran 19 cases covering all mapped boundaries, adjacent regions, representative interiors and unmapped addresses. Formal uses unconstrained `(* anyconst *)` address input, Yices through SBY 0.69, prove depth 1 and cover depth 1. The proof covers exact one-hot selection and mapped/default routing; it does not prove any wider fabric behavior.

Warning review: Verilator lint reported no warnings. Target-aware Yosys ECP5 synthesis completed with one reported experimental-feature warning from the qualified Yosys flow; it reported no design problems. The final mapped summary was 15 LUT4 and 2 PFUMX cells, retained only as primitive synthesis evidence and not as Fabric PPA. The initial Yosys import incompatibility was repaired by using fully qualified package constants, consistent with the Gate-0-qualified conservative SV subset. The earlier `proc; check; stat` run is retained only as frontend evidence; the final synthesis classification is based on `synth_ecp5`.
