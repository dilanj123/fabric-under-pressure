module axi_w_target_route_tb;
  logic ACLK = 0;
  always #5 ACLK = ~ACLK;
  logic ARESETn;
  logic [2:0] wvalid = 3'b001, wlast = 3'b001, owner_active = 3'b001;
  logic [2:0][63:0] wdata;
  logic [2:0][7:0] wstrb;
  logic [2:0][3:0] owner_target;
  logic [3:0] target_ready;
  logic [3:0][2:0] wready, wfire, owner_fire;
  logic [3:0] target_valid, target_last, target_fire;
  logic [3:0][63:0] target_data;
  logic [3:0][7:0] target_strb;
  logic [3:0][1:0] selected_manager;
  logic [3:0] selected_valid, conflict;
  logic [3:0][2:0] owner_last;
  integer checks = 0;
  genvar g;
  generate for (g=0; g<4; g=g+1) begin : paths
    axi_w_target_path #(.TARGET_INDEX(g)) dut (
      .ACLK, .ARESETn, .manager_wvalid(wvalid), .manager_wdata(wdata),
      .manager_wstrb(wstrb), .manager_wlast(wlast), .owner_active,
      .owner_target, .target_wready(target_ready[g]),
      .manager_wready(wready[g]), .manager_w_fire(wfire[g]),
      .target_wvalid(target_valid[g]), .target_wdata(target_data[g]),
      .target_wstrb(target_strb[g]), .target_wlast(target_last[g]),
      .target_w_fire(target_fire[g]), .selected_manager(selected_manager[g]),
      .selected_owner_valid(selected_valid[g]),
      .owner_conflict_violation(conflict[g]), .owner_w_fire(owner_fire[g]),
      .owner_wlast(owner_last[g])
    );
  end endgenerate
  task automatic check(input logic condition, input string message);
    begin checks=checks+1; if (!condition) begin $display("FAIL: %s",message); $fatal(1); end end
  endtask
  task automatic tick; begin @(posedge ACLK); #1; end endtask
  integer t, u;
  initial begin
    wdata='0; wdata[0]=64'hface_cafe_face_cafe; wstrb='0; wstrb[0]=8'h3c;
    owner_target='0; target_ready='0; ARESETn=0; tick(); tick(); ARESETn=1; tick();
    for (t=0; t<4; t=t+1) begin
      owner_target='0; owner_target[0][t]=1'b1; target_ready='0;
      #1;
      check(wready[t] == 3'b001, "only matching target accepts owner W");
      for (u=0; u<4; u=u+1)
        check((u == t) ? (wready[u] == 3'b001) : (wready[u] == 3'b000),
              "other target paths block W");
      tick();
      check(target_valid[t] && target_data[t] == 64'hface_cafe_face_cafe &&
            target_strb[t] == 8'h3c && target_last[t], "target payload preserved");
      target_ready[t]=1'b1; #1; check(target_fire[t] && owner_fire[t] == 3'b001,
                                      "matching target delivers owner beat");
      tick();
      check(!target_valid[t], "target slot clears after final delivery");
    end
    $display("PASS axi_w_target_route_tb checks=%0d", checks);
    $finish;
  end
endmodule
