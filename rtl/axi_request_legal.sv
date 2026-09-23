module axi_request_legal (
  // Only the page offset participates in the 4-KiB legality rule; upper
  // address bits remain intentionally unconstrained for mapped and S3 space.
  /* verilator lint_off UNUSEDSIGNAL */
  input  logic [31:0] addr,
  /* verilator lint_on UNUSEDSIGNAL */
  input  logic [7:0]  len,
  input  logic [2:0]  size,
  input  logic [1:0]  burst,
  input  logic        lock,
  output logic        request_legal
);
  logic [8:0]  beats;
  logic [11:0] burst_bytes;
  logic [12:0] end_offset;

  // The widened arithmetic is intentional: unconstrained LEN can be 8'hFF,
  // so neither LEN+1 nor offset+burst_bytes may wrap.
  always_comb begin
    beats = {1'b0, len} + 9'd1;
    burst_bytes = beats * 12'd8;
    end_offset = {1'b0, addr[11:0]} + {1'b0, burst_bytes};

    request_legal =
      (burst == fabric_addr_map_pkg::AXI_BURST_INCR) &&
      (len <= fabric_addr_map_pkg::AXI_MAX_LEN) &&
      (size == fabric_addr_map_pkg::AXI_FULL_WIDTH_SIZE) &&
      (addr[2:0] == 3'b000) &&
      (lock == fabric_addr_map_pkg::AXI_LOCK_NORMAL) &&
      (end_offset <= 13'd4096);
  end
endmodule
