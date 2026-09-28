# S3 error-target evidence summary

Scope: standalone protocol-correct S3 default/error target plus focused one-target Architecture-A write and read lifecycle compositions. The endpoint accepts only already-legal supported requests, consumes write data without memory side effects, returns DECERR, and is not a complete four-target Fabric.

RTL: `rtl/axi_s3_error_target.sv`. The write side stores one widened AW ID and a 1–16 beat count, consumes W through correct final WLAST, and then raises stable DECERR B. The read side stores one widened AR ID and emits exactly ARLEN+1 zero-data DECERR beats with RLAST on the final beat. Read and write contexts are independent.

Simulation: qualified OSS CAD Suite/Verilator binaries for the standalone endpoint and focused AW/state/W/B and AR/state/R compositions. Results: 72 standalone checks, 5 focused write-lifecycle checks and 6 focused read-lifecycle checks.

Formal: `sby -f formal/axi_s3_error_target_write.sby` and `sby -f formal/axi_s3_error_target_read.sby`; engine `smtbmc`, solver Yices, bounded prove/cover depth 24. Assumptions constrain accepted AWLEN/ARLEN to <=15 and apply coordinated reset. Proofs cover state capacity, DECERR payloads, beat counters, response stability under backpressure and no premature response generation. Covers reach one-beat, 16-beat, stalled-response and final-response states.

Synthesis: `yosys -Q -p "read_verilog -sv rtl/axi_s3_error_target.sv; synth_ecp5 -top axi_s3_error_target -json results/raw/s3_error_target/axi_s3_error_target_ecp5.json; stat"`; exit 0, Yosys check reported 0 problems. Primitive result: 52 LUT4, 29 TRELLIS_FF, 12 CCU2C, 13 PFUMX and 7 L6MUX21. One experimental-feature warning was reported; no synthesis error. This is primitive synthesis evidence, not Fabric PPA.

Limitations: recorded-target versus returned-target response-source matching remains unproven; full four-target production composition, whole-Fabric regression, independent Python oracle, Architecture B, timing/performance/PPA and Gate 2 remain open.
