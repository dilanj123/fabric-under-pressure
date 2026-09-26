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
  axi_write_owner_formal UUT (
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
    UUT._witness_.anyinit_procdff_305 = 1'b0;
    UUT._witness_.anyinit_procdff_325 = 5'b00000;
    UUT.dut._witness_.anyinit_procdff_280 = 1'b0;
    UUT.dut._witness_.anyinit_procdff_285 = 4'b0000;
    UUT.dut._witness_.anyinit_procdff_290 = 4'b0000;
    UUT.dut._witness_.anyinit_procdff_295 = 6'b000000;
    UUT.dut._witness_.anyinit_procdff_300 = 5'b00000;

    // state 0
    PI_ACLK = 1'b0;
    UUT.allocate_fire = 1'b0;
    UUT.allocate_id = 4'b0000;
    UUT.allocate_internal_id = 6'b000000;
    UUT.allocate_len = 8'b10000000;
    UUT.allocate_target = 4'b0000;
    UUT.w_fire = 1'b0;
    UUT.wlast = 1'b0;
    UUT.ARESETn = 1'b0;
  end
  always @(posedge clock) begin
    // state 1
    if (cycle == 0) begin
      PI_ACLK <= 1'b0;
      UUT.allocate_fire <= 1'b1;
      UUT.allocate_id <= 4'b0000;
      UUT.allocate_internal_id <= 6'b000000;
      UUT.allocate_len <= 8'b00000000;
      UUT.allocate_target <= 4'b0000;
      UUT.w_fire <= 1'b0;
      UUT.wlast <= 1'b0;
      UUT.ARESETn <= 1'b1;
    end

    genclock <= cycle < 1;
    cycle <= cycle + 1;
  end
endmodule
