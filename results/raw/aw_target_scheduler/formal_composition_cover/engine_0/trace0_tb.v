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
  aw_target_scheduler_composition_formal UUT (
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
    UUT.boundary.u_rr._witness_.anyinit_procdff_589 = 2'b00;
    UUT.boundary.u_rr._witness_.anyinit_procdff_594 = 3'b000;
    UUT.boundary.u_rr._witness_.anyinit_procdff_599 = 1'b0;
    UUT.boundary.u_rr._witness_.anyinit_procdff_604 = 2'b00;
    UUT.owner0._witness_.anyinit_procdff_609 = 1'b0;
    UUT.owner0._witness_.anyinit_procdff_614 = 4'b0000;
    UUT.owner0._witness_.anyinit_procdff_619 = 4'b0000;
    UUT.owner0._witness_.anyinit_procdff_624 = 6'b000000;
    UUT.owner0._witness_.anyinit_procdff_629 = 5'b00000;
    UUT.owner1._witness_.anyinit_procdff_609 = 1'b0;
    UUT.owner1._witness_.anyinit_procdff_614 = 4'b0000;
    UUT.owner1._witness_.anyinit_procdff_619 = 4'b0000;
    UUT.owner1._witness_.anyinit_procdff_624 = 6'b000000;
    UUT.owner1._witness_.anyinit_procdff_629 = 5'b00000;
    UUT.owner2._witness_.anyinit_procdff_609 = 1'b0;
    UUT.owner2._witness_.anyinit_procdff_614 = 4'b0000;
    UUT.owner2._witness_.anyinit_procdff_619 = 4'b0000;
    UUT.owner2._witness_.anyinit_procdff_624 = 6'b000000;
    UUT.owner2._witness_.anyinit_procdff_629 = 5'b00000;

    // state 0
    PI_ACLK = 1'b0;
    UUT.ARESETn = 1'b0;
    UUT.allocate_len = 4'b0000;
    UUT.outstanding_allowed = 3'b000;
    UUT.request_legal = 3'b000;
    UUT.request_present = 3'b000;
    UUT.target_match = 3'b000;
    UUT.target_ready = 1'b0;
    UUT.w_fire = 3'b000;
    UUT.wlast = 3'b000;
  end
  always @(posedge clock) begin
    // state 1
    if (cycle == 0) begin
      PI_ACLK <= 1'b0;
      UUT.ARESETn <= 1'b1;
      UUT.allocate_len <= 4'b0000;
      UUT.outstanding_allowed <= 3'b100;
      UUT.request_legal <= 3'b100;
      UUT.request_present <= 3'b100;
      UUT.target_match <= 3'b100;
      UUT.target_ready <= 1'b0;
      UUT.w_fire <= 3'b000;
      UUT.wlast <= 3'b000;
    end

    // state 2
    if (cycle == 1) begin
      PI_ACLK <= 1'b0;
      UUT.ARESETn <= 1'b1;
      UUT.allocate_len <= 4'b0000;
      UUT.outstanding_allowed <= 3'b000;
      UUT.request_legal <= 3'b000;
      UUT.request_present <= 3'b000;
      UUT.target_match <= 3'b000;
      UUT.target_ready <= 1'b1;
      UUT.w_fire <= 3'b000;
      UUT.wlast <= 3'b000;
    end

    genclock <= cycle < 2;
    cycle <= cycle + 1;
  end
endmodule
