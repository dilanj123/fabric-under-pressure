# S3 W-before-AW diagnostic repair

Root cause: the original S3 endpoint classified `WVALID && !write_active` as a protocol violation. In this architecture AW and W are independent, and the Fabric can admit AW and create shared owner state before the target-facing AW slot has completed its handshake with S3. WVALID may therefore be held at S3 before local AW acceptance.

Repair: `rtl/axi_s3_error_target.sv` retains `WREADY = ARESETn && write_active` and redefines the retained diagnostic as the impossible defensive condition `w_fire && !write_active`. Since `w_fire = WVALID && WREADY`, the diagnostic is unreachable by construction. WVALID-before-AW is legal and is only backpressured.

Directed evidence: the standalone test holds WVALID/WLAST before AW for three cycles, checks no WREADY, no handshake, no state change, no BVALID and no diagnostic, then accepts AW, accepts the held W beat and generates DECERR B. The focused AW/state/W/S3 composition holds the target-side AW acceptance low after manager AW admission, presents W through the registered owner-directed path, verifies S3 backpressure and no diagnostic, then releases AW and completes normally.

Results: standalone S3 simulation PASS with 77 checks; focused write lifecycle PASS with 7 checks; focused read lifecycle PASS with 6 checks. Existing 1/2/4/16-beat write/read, WLAST, B/R backpressure, simultaneous read/write and reset coverage remains present in the standalone test.

Formal: Yices through SBY `smtbmc`, bounded prove and cover depth 24. The repaired write harness proves `!write_active -> !wready`, retains response/counter safety, and covers WVALID-before-AW followed by later AW availability. Read prove/cover remains PASS.

Synthesis: ECP5-targeted Yosys synthesis exits 0 with 0 reported problems. Resource counts remain 52 LUT4, 29 TRELLIS_FF, 12 CCU2C, 13 PFUMX and 7 L6MUX21. One experimental-feature warning remains; no synthesis error. These are primitive figures, not Fabric PPA.
