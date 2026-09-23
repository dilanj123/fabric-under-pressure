module request_legality_formal;
  (* anyconst *) logic [31:0] addr;
  (* anyconst *) logic [7:0]  len;
  (* anyconst *) logic [2:0]  size;
  (* anyconst *) logic [1:0]  burst;
  (* anyconst *) logic        lock;
  logic request_legal;
  logic [3:0] start_target;
  logic [3:0] end_target;
  logic [8:0] beats;
  logic [11:0] burst_bytes;
  logic [12:0] end_offset;
  logic [32:0] last_byte_ext;
  logic [31:0] last_addr;
  logic shape_legal;

  axi_request_legal legal_dut (
    .addr(addr), .len(len), .size(size), .burst(burst), .lock(lock),
    .request_legal(request_legal)
  );
  axi_address_decoder start_decoder (.addr(addr), .target_select(start_target));
  axi_address_decoder end_decoder (.addr(last_addr), .target_select(end_target));

  always @* begin
    beats = {1'b0, len} + 9'd1;
    burst_bytes = beats * 12'd8;
    end_offset = {1'b0, addr[11:0]} + {1'b0, burst_bytes};
    last_byte_ext = {1'b0, addr} + {21'b0, burst_bytes} - 33'd1;
    last_addr = last_byte_ext[31:0];
    shape_legal =
      (burst == fabric_addr_map_pkg::AXI_BURST_INCR) &&
      (len <= fabric_addr_map_pkg::AXI_MAX_LEN) &&
      (size == fabric_addr_map_pkg::AXI_FULL_WIDTH_SIZE) &&
      (addr[2:0] == 3'b000) &&
      (lock == fabric_addr_map_pkg::AXI_LOCK_NORMAL) &&
      (end_offset <= 13'd4096);

    assert (request_legal == shape_legal);
    if (request_legal) begin
      assert (len <= fabric_addr_map_pkg::AXI_MAX_LEN);
      assert (size == fabric_addr_map_pkg::AXI_FULL_WIDTH_SIZE);
      assert (burst == fabric_addr_map_pkg::AXI_BURST_INCR);
      assert (lock == fabric_addr_map_pkg::AXI_LOCK_NORMAL);
      assert (addr[2:0] == 3'b000);
      assert (end_offset <= 13'd4096);
      assert (last_byte_ext[32] == 1'b0);
      assert (start_target == end_target);
    end

    cover (request_legal && len == 8'd0);
    cover (request_legal && len == 8'd15);
    cover (request_legal && end_offset == 13'd4096);
    cover (!request_legal && end_offset > 13'd4096);
    cover (request_legal && start_target == fabric_addr_map_pkg::TARGET_S0);
    cover (request_legal && start_target == fabric_addr_map_pkg::TARGET_S1);
    cover (request_legal && start_target == fabric_addr_map_pkg::TARGET_S2);
    cover (request_legal && start_target == fabric_addr_map_pkg::TARGET_S3);
  end
endmodule
