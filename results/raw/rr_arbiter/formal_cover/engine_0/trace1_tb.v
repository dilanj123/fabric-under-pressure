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
  rr_arbiter_formal UUT (
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
    UUT.dut._witness_.anyinit_procdff_1163 = 2'b00;
    UUT.dut._witness_.anyinit_procdff_1168 = 3'b000;
    UUT.dut._witness_.anyinit_procdff_1173 = 1'b0;
    UUT.dut._witness_.anyinit_procdff_1178 = 2'b00;

    // state 0
    PI_ACLK = 1'b0;
    UUT.ARESETn = 1'b0;
    UUT.request = 3'b000;
    UUT.downstream_ready = 1'b0;
  end
  always @(posedge clock) begin
    // state 1
    if (cycle == 0) begin
      PI_ACLK <= 1'b0;
      UUT.ARESETn <= 1'b1;
      UUT.request <= 3'b000;
      UUT.downstream_ready <= 1'b0;
    end

    genclock <= cycle < 1;
    cycle <= cycle + 1;
  end
endmodule
