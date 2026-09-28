module axi_s3_error_target_tb;
  logic ACLK=0, ARESETn=0; always #5 ACLK=~ACLK;
  integer checks=0;
  logic [5:0] awid, bid, arid, rid;
  logic [31:0] awaddr, araddr;
  logic [7:0] awlen, arlen;
  logic [2:0] awsize, arsize; logic [1:0] awburst, arburst;
  logic awlock, arlock; logic [3:0] awcache, awqos, awregion, arcache, arqos, arregion;
  logic [2:0] awprot, arprot;
  logic awvalid, awready, wvalid, wready, wlast;
  logic [63:0] wdata; logic [7:0] wstrb;
  logic bvalid, bready; logic [1:0] bresp;
  logic arvalid, arready, rvalid, rready, rlast; logic [63:0] rdata; logic [1:0] rresp;
  logic early_wlast_violation, missing_wlast_violation, w_without_aw_violation;
  logic write_active, read_active; logic [5:0] write_id, read_id;
  logic [4:0] write_beats_remaining, read_beats_remaining;

  axi_s3_error_target dut(.*);

  task automatic ck(input logic c, input string s);
    begin checks++; if (!c) begin $display("FAIL %0s", s); $fatal(1); end end
  endtask
  task automatic tick; begin @(posedge ACLK); #1; end endtask
  task automatic clear_inputs;
    begin awvalid=0; wvalid=0; wlast=0; bready=0; arvalid=0; rready=0; end
  endtask
  task automatic reset_dut;
    begin clear_inputs(); ARESETn=0; #1; ck(!bvalid && !rvalid && !write_active && !read_active,"reset clears state"); tick(); ARESETn=1; tick(); end
  endtask

  task automatic write_burst(input integer beats, input logic [5:0] id);
    integer i;
    begin
      awid=id; awlen=8'(beats-1); awvalid=1; #1; ck(awready,"AW ready"); tick(); awvalid=0;
      for (i=0;i<beats;i=i+1) begin
        wdata={id, 8'(i), 50'h0}; wstrb=8'hA5; wlast=(i==beats-1); wvalid=1;
        #1; ck(wready,"W ready after AW"); tick();
      end
      wvalid=0; wlast=0; #1; ck(bvalid && bid==id && bresp==2'b11,"DECERR B generated");
      bready=0; repeat(2) begin tick(); ck(bvalid && bid==id && bresp==2'b11,"B stable under stall"); end
      bready=1; #1; ck(bvalid,"B handshake visible"); tick(); bready=0;
      ck(!bvalid && !write_active,"B clears write context");
    end
  endtask

  task automatic read_burst(input integer beats, input logic [5:0] id);
    integer i;
    begin
      arid=id; arlen=8'(beats-1); arvalid=1; #1; ck(arready,"AR ready"); tick(); arvalid=0;
      for (i=0;i<beats;i=i+1) begin
        rready=0; #1; ck(rvalid && rid==id && rdata==64'h0 && rresp==2'b11 && rlast==(i==beats-1),"DECERR R payload");
        tick(); ck(rvalid,"R stable under stall"); rready=1; #1; ck(rvalid,"R handshake visible"); tick();
      end
      rready=0; ck(!rvalid && !read_active,"R clears read context");
    end
  endtask

  initial begin
    awaddr=0; awsize=3; awburst=2'b01; awlock=0; awcache=0; awqos=0; awregion=0; awprot=0;
    araddr=0; arsize=3; arburst=2'b01; arlock=0; arcache=0; arqos=0; arregion=0; arprot=0;
    wdata=0; wstrb=8'hFF; reset_dut();

    // WVALID may precede local AW acceptance. S3 holds WREADY low without
    // diagnosing the legal independent-channel ordering.
    wvalid=1; wlast=1;
    repeat(3) begin #1; ck(!wready && !w_without_aw_violation && !write_active && !bvalid,"W before local AW is backpressured legally"); tick(); end
    awid=6'h00; awlen=0; awvalid=1; #1; ck(awready,"AW accepts after early WVALID"); tick(); awvalid=0;
    #1; ck(wready && !w_without_aw_violation,"held W becomes admissible after AW"); tick(); wvalid=0;
    #1; ck(bvalid && bid==6'h00 && bresp==2'b11,"early-held W completes DECERR"); bready=1; tick(); bready=0;
    write_burst(1,6'h01);
    write_burst(2,6'h02);
    write_burst(4,6'h03);
    write_burst(16,6'h04);

    // Early WLAST and missing final WLAST never create B prematurely.
    reset_dut(); awid=6'h08; awlen=8'd3; awvalid=1; tick(); awvalid=0;
    wvalid=1; wlast=1; #1; ck(early_wlast_violation && !bvalid,"early WLAST diagnostic"); tick();
    wlast=0; repeat(2) begin #1; ck(wready && !bvalid,"early WLAST retains context"); tick(); end
    wlast=0; #1; ck(missing_wlast_violation && !bvalid,"missing WLAST diagnostic"); tick();
    wlast=1; #1; ck(wready && !bvalid,"correct final remains target-side event"); tick(); wvalid=0;
    #1; ck(bvalid && bid==6'h08,"late correct WLAST creates B"); bready=1; tick(); bready=0;

    // B backpressure prevents AW reuse; reads remain independent.
    reset_dut(); awid=6'h0A; awlen=0; awvalid=1; tick(); awvalid=0; wvalid=1; wlast=1; tick(); wvalid=0;
    #1; ck(bvalid && !awready,"pending B blocks AW reuse"); bready=0; repeat(2) tick(); ck(bvalid,"B remains pending");
    bready=1; tick(); bready=0; ck(!bvalid,"B released");

    // Independent simultaneous read/write contexts.
    reset_dut(); awid=6'h0B; awlen=3; awvalid=1; arid=6'h2B; arlen=3; arvalid=1; #1;
    ck(awready && arready,"read/write independent ready"); tick(); awvalid=0; arvalid=0; ck(write_active && read_active,"read/write active together");
    wvalid=1; rready=1;
    repeat(4) begin wlast=(write_beats_remaining==1); #1; ck(wready && rvalid,"read/write progress together"); tick(); end
    wvalid=0; rready=0; #1; ck(bvalid,"simultaneous write B"); bready=1; tick(); bready=0;
    ck(!read_active,"read completes independently");

    // Reset while B and R are stalled.
    reset_dut(); awid=6'h0C; awlen=1; awvalid=1; tick(); awvalid=0; wvalid=1; wlast=0; tick(); wlast=1; tick(); wvalid=0;
    arid=6'h2C; arlen=3; arvalid=1; tick(); arvalid=0; rready=0; bready=0; #1; ck(bvalid && rvalid,"responses stalled before reset");
    ARESETn=0; #1; ck(!bvalid && !rvalid && !write_active && !read_active,"reset clears pending responses"); ARESETn=1; tick();

    $display("PASS axi_s3_error_target_tb checks=%0d",checks); $finish;
  end
endmodule
