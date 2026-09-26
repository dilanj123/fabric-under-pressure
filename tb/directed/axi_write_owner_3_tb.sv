module axi_write_owner_3_tb;
  logic ACLK = 0; logic ARESETn = 0; always #5 ACLK = ~ACLK;
  logic [2:0] allocate_fire, w_fire, wlast;
  logic [2:0] allocate_allowed, active;
  logic [2:0][3:0] allocate_target, allocate_id, owner_target, owner_id;
  logic [2:0][5:0] allocate_internal_id, owner_internal_id;
  logic [2:0][7:0] allocate_len;
  logic [2:0][4:0] beats_remaining;
  logic [2:0] expected_wlast, allocate_violation, w_without_owner_violation, wlast_mismatch_violation;
  genvar m;
  generate for (m=0; m<3; m=m+1) begin : managers
    axi_write_owner dut (
      .ACLK(ACLK), .ARESETn(ARESETn), .allocate_fire(allocate_fire[m]),
      .allocate_target(allocate_target[m]), .allocate_id(allocate_id[m]),
      .allocate_internal_id(allocate_internal_id[m]), .allocate_len(allocate_len[m]),
      .w_fire(w_fire[m]), .wlast(wlast[m]), .allocate_allowed(allocate_allowed[m]),
      .active(active[m]), .owner_target(owner_target[m]), .owner_id(owner_id[m]),
      .owner_internal_id(owner_internal_id[m]), .beats_remaining(beats_remaining[m]),
      .expected_wlast(expected_wlast[m]), .allocate_violation(allocate_violation[m]),
      .w_without_owner_violation(w_without_owner_violation[m]),
      .wlast_mismatch_violation(wlast_mismatch_violation[m])
    );
  end endgenerate
  integer checks=0;
  task automatic check(input bit condition, input string message);
    checks=checks+1; if(!condition) begin $display("FAIL %s",message); $fatal(1); end
  endtask
  initial begin
    ARESETn=1'b1; #1; ARESETn=1'b0; #1;
    allocate_fire=0; w_fire=0; wlast=0; allocate_len='0; allocate_target='0; allocate_id='0; allocate_internal_id='0;
    #1; ARESETn=1;
    check(&allocate_allowed, "allocation permitted after reset");
    for (int i=0;i<3;i=i+1) begin
      allocate_len[i]=8'd2; allocate_target[i]=i[3:0]; allocate_id[i]=i[3:0]; allocate_internal_id[i]=6'd16 + i[5:0]; allocate_fire[i]=1;
    end
    @(posedge ACLK); #1; allocate_fire=0;
    check(&active && beats_remaining[0]==3 && beats_remaining[1]==3 && beats_remaining[2]==3, "three independent owners");
    w_fire[1]=1; wlast[1]=0; @(posedge ACLK); #1; w_fire[1]=0;
    check(active[0] && active[2] && beats_remaining[0]==3 && beats_remaining[2]==3, "other owners unaffected");
    w_fire[0]=1; wlast[0]=0; w_fire[2]=1; wlast[2]=0; @(posedge ACLK); #1; w_fire=0;
    check(beats_remaining[0]==2 && beats_remaining[2]==2, "parallel beat accounting");
    w_fire[1]=1; wlast[1]=0; @(posedge ACLK); #1; w_fire[1]=0;
    w_fire[1]=1; wlast[1]=1; @(posedge ACLK); #1; w_fire[1]=0;
    check(!active[1] && active[0] && active[2], "one completion does not modify others");
    w_fire[0]=1; wlast[0]=0; w_fire[2]=1; wlast[2]=0; @(posedge ACLK); #1; w_fire=0;
    w_fire[0]=1; wlast[0]=1; w_fire[2]=1; wlast[2]=1; @(posedge ACLK); #1; w_fire=0;
    check(!(active[0] || active[1] || active[2]), "all independent owners complete");
    $display("PASS axi_write_owner_3_tb checks=%0d",checks); $finish;
  end
endmodule
