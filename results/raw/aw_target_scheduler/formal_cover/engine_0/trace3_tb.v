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
  aw_target_scheduler_formal UUT (
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
    UUT.dut.u_rr._witness_.anyinit_procdff_587 = 2'b00;
    UUT.dut.u_rr._witness_.anyinit_procdff_592 = 3'b000;
    UUT.dut.u_rr._witness_.anyinit_procdff_597 = 1'b0;
    UUT.dut.u_rr._witness_.anyinit_procdff_602 = 2'b00;

    // state 0
    PI_ACLK = 1'b0;
    UUT.ARESETn = 1'b0;
    UUT.owner_active = 3'b000;
    UUT.owner_target_m0 = 4'b0000;
    UUT.owner_target_m1 = 4'b0000;
    UUT.owner_target_m2 = 4'b0000;
    UUT.request_legal = 3'b000;
    UUT.request_present = 3'b000;
    UUT.target_match = 3'b000;
    UUT.target_ready = 1'b0;
    UUT.outstanding_allowed = 3'b000;
  end
  always @(posedge clock) begin
    // state 1
    if (cycle == 0) begin
      PI_ACLK <= 1'b0;
      UUT.ARESETn <= 1'b1;
      UUT.owner_active <= 3'b000;
      UUT.owner_target_m0 <= 4'b0000;
      UUT.owner_target_m1 <= 4'b0000;
      UUT.owner_target_m2 <= 4'b0000;
      UUT.request_legal <= 3'b111;
      UUT.request_present <= 3'b111;
      UUT.target_match <= 3'b111;
      UUT.target_ready <= 1'b0;
      UUT.outstanding_allowed <= 3'b100;
    end

    genclock <= cycle < 1;
    cycle <= cycle + 1;
  end
endmodule
