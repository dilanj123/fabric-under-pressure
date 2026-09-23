package fabric_addr_map_pkg;
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
endpackage
