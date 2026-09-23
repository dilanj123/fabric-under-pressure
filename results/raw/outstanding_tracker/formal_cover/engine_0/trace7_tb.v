`ifndef VERILATOR
module testbench;
  reg [4095:0] vcdfile;
  reg clock;
`else
module testbench(input clock, output reg genclock);
  initial genclock = 1;
`endif
  reg genclock = 1;
  reg [31:0] cycle = 0;
  reg [0:0] PI_ACLK;
  outstanding_tracker_formal UUT (
    .ACLK(PI_ACLK)
  );
`ifndef VERILATOR
  initial begin
    if ($value$plusargs("vcd=%s", vcdfile)) begin
      $dumpfile(vcdfile);
      $dumpvars(0, testbench);
    end
    #5 clock = 0;
    while (genclock) begin
      #5 clock = 0;
      #5 clock = 1;
    end
  end
`endif
  initial begin
`ifndef VERILATOR
    #1;
`endif
    UUT._witness_.anyinit_procdff_2357 = 16'b0000000000000000;
    UUT._witness_.anyinit_procdff_2362 = 3'b000;
    UUT.dut._witness_.anyinit_procdff_2120 = 16'b0000000000000000;
    UUT.dut._witness_.anyinit_procdff_2125 = 3'b000;
    UUT.dut._witness_.anyinit_procdff_2140 = 4'b0000;
    UUT.dut._witness_.anyinit_procdff_2145 = 4'b0000;
    UUT.dut._witness_.anyinit_procdff_2150 = 4'b0000;
    UUT.dut._witness_.anyinit_procdff_2155 = 4'b0000;
    UUT.dut._witness_.anyinit_procdff_2160 = 4'b0000;
    UUT.dut._witness_.anyinit_procdff_2165 = 4'b0000;
    UUT.dut._witness_.anyinit_procdff_2170 = 4'b0000;
    UUT.dut._witness_.anyinit_procdff_2175 = 4'b0000;
    UUT.dut._witness_.anyinit_procdff_2180 = 4'b0000;
    UUT.dut._witness_.anyinit_procdff_2185 = 4'b0000;
    UUT.dut._witness_.anyinit_procdff_2190 = 4'b0000;
    UUT.dut._witness_.anyinit_procdff_2195 = 4'b0000;
    UUT.dut._witness_.anyinit_procdff_2200 = 4'b0000;
    UUT.dut._witness_.anyinit_procdff_2205 = 4'b0000;
    UUT.dut._witness_.anyinit_procdff_2210 = 4'b0000;
    UUT.dut._witness_.anyinit_procdff_2215 = 4'b0000;
    UUT.dut._witness_.anyinit_procdff_2220 = 8'b00000000;
    UUT.dut._witness_.anyinit_procdff_2225 = 8'b00000000;
    UUT.dut._witness_.anyinit_procdff_2230 = 8'b00000000;
    UUT.dut._witness_.anyinit_procdff_2235 = 8'b00000000;
    UUT.dut._witness_.anyinit_procdff_2240 = 8'b00000000;
    UUT.dut._witness_.anyinit_procdff_2245 = 8'b00000000;
    UUT.dut._witness_.anyinit_procdff_2250 = 8'b00000000;
    UUT.dut._witness_.anyinit_procdff_2255 = 8'b00000000;
    UUT.dut._witness_.anyinit_procdff_2260 = 8'b00000000;
    UUT.dut._witness_.anyinit_procdff_2265 = 8'b00000000;
    UUT.dut._witness_.anyinit_procdff_2270 = 8'b00000000;
    UUT.dut._witness_.anyinit_procdff_2275 = 8'b00000000;
    UUT.dut._witness_.anyinit_procdff_2280 = 8'b00000000;
    UUT.dut._witness_.anyinit_procdff_2285 = 8'b00000000;
    UUT.dut._witness_.anyinit_procdff_2290 = 8'b00000000;
    UUT.dut._witness_.anyinit_procdff_2295 = 8'b00000000;
    UUT.saw_full = 1'b0;

    // state 0
    PI_ACLK = 1'b0;
    UUT.ARESETn = 1'b0;
    UUT.allocate_fire = 1'b0;
    UUT.allocate_len = 8'b00000000;
    UUT.allocate_target = 4'b0000;
    UUT.complete_fire = 1'b0;
    UUT.complete_id = 4'b0000;
    UUT.lookup_id = 4'b0000;
    UUT.allocate_id = 4'b0000;
  end
  always @(posedge clock) begin
    // state 1
    if (cycle == 0) begin
      PI_ACLK <= 1'b0;
      UUT.ARESETn <= 1'b1;
      UUT.allocate_fire <= 1'b1;
      UUT.allocate_len <= 8'b00000000;
      UUT.allocate_target <= 4'b0000;
      UUT.complete_fire <= 1'b1;
      UUT.complete_id <= 4'b0000;
      UUT.lookup_id <= 4'b0000;
      UUT.allocate_id <= 4'b0101;
    end

    // state 2
    if (cycle == 1) begin
      PI_ACLK <= 1'b0;
      UUT.ARESETn <= 1'b1;
      UUT.allocate_fire <= 1'b1;
      UUT.allocate_len <= 8'b00000000;
      UUT.allocate_target <= 4'b0000;
      UUT.complete_fire <= 1'b0;
      UUT.complete_id <= 4'b0101;
      UUT.lookup_id <= 4'b0000;
      UUT.allocate_id <= 4'b1011;
    end

    // state 3
    if (cycle == 2) begin
      PI_ACLK <= 1'b0;
      UUT.ARESETn <= 1'b1;
      UUT.allocate_fire <= 1'b1;
      UUT.allocate_len <= 8'b00000000;
      UUT.allocate_target <= 4'b0000;
      UUT.complete_fire <= 1'b0;
      UUT.complete_id <= 4'b0101;
      UUT.lookup_id <= 4'b0000;
      UUT.allocate_id <= 4'b0000;
    end

    // state 4
    if (cycle == 3) begin
      PI_ACLK <= 1'b0;
      UUT.ARESETn <= 1'b1;
      UUT.allocate_fire <= 1'b1;
      UUT.allocate_len <= 8'b00000000;
      UUT.allocate_target <= 4'b0000;
      UUT.complete_fire <= 1'b0;
      UUT.complete_id <= 4'b0000;
      UUT.lookup_id <= 4'b0000;
      UUT.allocate_id <= 4'b0000;
    end

    genclock <= cycle < 4;
    cycle <= cycle + 1;
  end
endmodule
