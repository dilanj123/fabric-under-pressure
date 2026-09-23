module request_legality_tb;
  logic [31:0] addr;
  logic [7:0]  len;
  logic [2:0]  size;
  logic [1:0]  burst;
  logic        lock;
  logic        request_legal;
  integer test_count;

  axi_request_legal dut (
    .addr(addr),
    .len(len),
    .size(size),
    .burst(burst),
    .lock(lock),
    .request_legal(request_legal)
  );

  task automatic check(
    input logic [31:0] value_addr,
    input logic [7:0]  value_len,
    input logic [2:0]  value_size,
    input logic [1:0]  value_burst,
    input logic        value_lock,
    input logic        expected,
    input string       name
  );
    begin
      addr = value_addr;
      len = value_len;
      size = value_size;
      burst = value_burst;
      lock = value_lock;
      #1;
      if (request_legal !== expected) begin
        $fatal(1, "FAIL %s addr=%h len=%0d size=%0d burst=%b lock=%b expected=%b actual=%b",
               name, value_addr, value_len, value_size, value_burst, value_lock, expected, request_legal);
      end
      test_count = test_count + 1;
    end
  endtask

  initial begin
    test_count = 0;

    // Legal supported shape, including legal but unmapped S3 addresses.
    check(32'h0000_0000, 8'd0, 3'd3, 2'b01, 1'b0, 1'b1, "legal S0");
    check(32'h1000_0008, 8'd1, 3'd3, 2'b01, 1'b0, 1'b1, "legal S1");
    check(32'h2000_0000, 8'd15, 3'd3, 2'b01, 1'b0, 1'b1, "legal S2");
    check(32'h3000_0000, 8'd0, 3'd3, 2'b01, 1'b0, 1'b1, "legal unmapped S3");

    // Supported burst lengths and the first unsupported length.
    check(32'h0000_0000, 8'd0, 3'd3, 2'b01, 1'b0, 1'b1, "LEN0");
    check(32'h0000_0000, 8'd1, 3'd3, 2'b01, 1'b0, 1'b1, "LEN1");
    check(32'h0000_0000, 8'd14, 3'd3, 2'b01, 1'b0, 1'b1, "LEN14");
    check(32'h0000_0F80, 8'd15, 3'd3, 2'b01, 1'b0, 1'b1, "LEN15");
    check(32'h0000_0000, 8'd16, 3'd3, 2'b01, 1'b0, 1'b0, "LEN16 unsupported");
    check(32'h0000_0000, 8'hFF, 3'd3, 2'b01, 1'b0, 1'b0, "LEN255 unsupported");

    // Transfer size and burst encoding.
    check(32'h0000_0000, 8'd0, 3'd2, 2'b01, 1'b0, 1'b0, "SIZE2");
    check(32'h0000_0000, 8'd0, 3'd3, 2'b01, 1'b0, 1'b1, "SIZE3");
    check(32'h0000_0000, 8'd0, 3'd4, 2'b01, 1'b0, 1'b0, "SIZE4");
    check(32'h0000_0000, 8'd0, 3'd3, 2'b00, 1'b0, 1'b0, "FIXED");
    check(32'h0000_0000, 8'd0, 3'd3, 2'b01, 1'b0, 1'b1, "INCR");
    check(32'h0000_0000, 8'd0, 3'd3, 2'b10, 1'b0, 1'b0, "WRAP");
    check(32'h0000_0000, 8'd0, 3'd3, 2'b11, 1'b0, 1'b0, "reserved burst");

    // Alignment and lock.
    check(32'h0000_0100, 8'd0, 3'd3, 2'b01, 1'b0, 1'b1, "aligned");
    check(32'h0000_0101, 8'd0, 3'd3, 2'b01, 1'b0, 1'b0, "alignment 1");
    check(32'h0000_0102, 8'd0, 3'd3, 2'b01, 1'b0, 1'b0, "alignment 2");
    check(32'h0000_0103, 8'd0, 3'd3, 2'b01, 1'b0, 1'b0, "alignment 3");
    check(32'h0000_0104, 8'd0, 3'd3, 2'b01, 1'b0, 1'b0, "alignment 4");
    check(32'h0000_0105, 8'd0, 3'd3, 2'b01, 1'b0, 1'b0, "alignment 5");
    check(32'h0000_0106, 8'd0, 3'd3, 2'b01, 1'b0, 1'b0, "alignment 6");
    check(32'h0000_0107, 8'd0, 3'd3, 2'b01, 1'b0, 1'b0, "alignment 7");
    check(32'h0000_0100, 8'd0, 3'd3, 2'b01, 1'b1, 1'b0, "locked unsupported");

    // 4-KiB boundaries in mapped and S3 pages.
    check(32'h0000_0FF8, 8'd0, 3'd3, 2'b01, 1'b0, 1'b1, "S0 FF8 LEN0");
    check(32'h0000_0FF8, 8'd1, 3'd3, 2'b01, 1'b0, 1'b0, "S0 FF8 LEN1 crossing");
    check(32'h0000_0F80, 8'd15, 3'd3, 2'b01, 1'b0, 1'b1, "S0 F80 LEN15");
    check(32'h0000_0F88, 8'd15, 3'd3, 2'b01, 1'b0, 1'b0, "S0 F88 LEN15 crossing");
    check(32'h2000_0FF8, 8'd0, 3'd3, 2'b01, 1'b0, 1'b1, "S2 FF8 LEN0");
    check(32'h2000_0FF8, 8'd1, 3'd3, 2'b01, 1'b0, 1'b0, "S2 FF8 LEN1 crossing");
    check(32'h3000_0F80, 8'd15, 3'd3, 2'b01, 1'b0, 1'b1, "S3 F80 LEN15");
    check(32'h3000_0F88, 8'd15, 3'd3, 2'b01, 1'b0, 1'b0, "S3 F88 LEN15 crossing");

    // Upper 32-bit address edge: no wraparound is accepted.
    check(32'hFFFF_FFF8, 8'd0, 3'd3, 2'b01, 1'b0, 1'b1, "upper S3 LEN0");
    check(32'hFFFF_FFF8, 8'd1, 3'd3, 2'b01, 1'b0, 1'b0, "upper S3 LEN1 crossing");

    $display("PASS request_legality_tb tests=%0d", test_count);
    $finish;
  end
endmodule
