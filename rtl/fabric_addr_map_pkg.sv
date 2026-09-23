package fabric_addr_map_pkg;
  // The package is shared by independent primitives. A focused lint of one
  // primitive will not consume every map/target constant.
  /* verilator lint_off UNUSEDPARAM */
  localparam logic [31:0] S0_BASE = 32'h0000_0000;
  localparam logic [31:0] S0_LAST = 32'h0000_FFFF;
  localparam logic [31:0] S1_BASE = 32'h1000_0000;
  localparam logic [31:0] S1_LAST = 32'h1000_FFFF;
  localparam logic [31:0] S2_BASE = 32'h2000_0000;
  localparam logic [31:0] S2_LAST = 32'h2000_0FFF;

  // One-hot logical target select: bit 0=S0, bit 1=S1, bit 2=S2, bit 3=S3.
  localparam logic [3:0] TARGET_S0 = 4'b0001;
  localparam logic [3:0] TARGET_S1 = 4'b0010;
  localparam logic [3:0] TARGET_S2 = 4'b0100;
  localparam logic [3:0] TARGET_S3 = 4'b1000;

  localparam logic [1:0] AXI_BURST_INCR = 2'b01;
  localparam logic       AXI_LOCK_NORMAL = 1'b0;
  localparam logic [7:0] AXI_MAX_LEN = 8'd15;
  localparam logic [2:0] AXI_FULL_WIDTH_SIZE = 3'd3;
  /* verilator lint_on UNUSEDPARAM */
endpackage
