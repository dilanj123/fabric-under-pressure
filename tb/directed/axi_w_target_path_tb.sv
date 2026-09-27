module axi_w_target_path_tb;
  logic ACLK = 0;
  always #5 ACLK = ~ACLK;
  logic ARESETn;
  logic [2:0] manager_wvalid, manager_wlast, owner_active;
  logic [2:0][63:0] manager_wdata;
  logic [2:0][7:0] manager_wstrb;
  logic [2:0][3:0] owner_target;
  logic target_wready;
  logic [2:0] manager_wready, manager_w_fire;
  logic target_wvalid, target_wlast, target_w_fire;
  logic [63:0] target_wdata;
  logic [7:0] target_wstrb;
  logic [1:0] selected_manager;
  logic selected_owner_valid, owner_conflict_violation;
  logic [2:0] owner_w_fire, owner_wlast;
  integer checks = 0;

  axi_w_target_path #(.TARGET_INDEX(0)) dut (.*);

  task automatic check(input logic condition, input string message);
    begin
      checks = checks + 1;
      if (!condition) begin
        $display("FAIL: %s", message);
        $fatal(1);
      end
    end
  endtask

  task automatic clear_inputs;
    begin
      manager_wvalid = 3'b000;
      manager_wlast = 3'b000;
      manager_wdata = '0;
      manager_wstrb = '0;
      owner_active = 3'b000;
      owner_target = '0;
      target_wready = 1'b0;
    end
  endtask

  task automatic tick;
    begin
      @(posedge ACLK); #1;
    end
  endtask

  initial begin
    clear_inputs();
    ARESETn = 1'b0;
    tick(); tick();
    ARESETn = 1'b1;
    tick();
    check(manager_wready == 3'b000, "no owner blocks WREADY");

    // W before AW/owner: the source may wait, but the path cannot accept it.
    manager_wvalid[1] = 1'b1;
    manager_wdata[1] = 64'h1111_2222_3333_4444;
    manager_wstrb[1] = 8'h5a;
    manager_wlast[1] = 1'b1;
    tick();
    check(manager_wready == 3'b000 && manager_w_fire == 3'b000,
          "W before owner is blocked");

    owner_active[1] = 1'b1;
    owner_target[1] = 4'b0001;
    #1;
    check(manager_wready == 3'b010, "only registered owner receives WREADY");
    check(manager_w_fire == 3'b010, "owner W admission fires");
    tick();
    check(target_wvalid && target_wdata == 64'h1111_2222_3333_4444 &&
          target_wstrb == 8'h5a && target_wlast,
          "captured W payload reaches target");

    // Final beat may stall and must remain stable; owner progress is target-side.
    manager_wdata[1] = 64'hdead_beef_dead_beef;
    manager_wstrb[1] = 8'hff;
    check(target_wvalid && target_wdata == 64'h1111_2222_3333_4444 &&
          target_wstrb == 8'h5a && target_wlast &&
          owner_w_fire == 3'b000,
          "stalled final W is stable and has not progressed owner");
    target_wready = 1'b1;
    #1;
    check(target_w_fire && manager_wready == 3'b000 &&
          owner_w_fire == 3'b010 && owner_wlast == 3'b010,
          "final target delivery progresses the owning manager only");
    tick();
    check(!target_wvalid, "final delivery empties slot without refill");

    // Non-final delivery may drain and refill in the same cycle.
    manager_wvalid = 3'b010;
    manager_wdata[1] = 64'h0000_0000_0000_0001;
    manager_wstrb[1] = 8'h01;
    manager_wlast[1] = 1'b0;
    target_wready = 1'b0;
    #1;
    check(manager_wready == 3'b010, "owner can fill empty slot");
    tick();
    manager_wdata[1] = 64'h0000_0000_0000_0002;
    manager_wstrb[1] = 8'h02;
    manager_wlast[1] = 1'b1;
    target_wready = 1'b1;
    #1;
    check(target_w_fire && manager_w_fire == 3'b010,
          "non-final target delivery and refill occur together");
    tick();
    check(target_wvalid && target_wdata == 64'h2 && target_wstrb == 8'h02 &&
          target_wlast, "replacement beat is registered exactly");

    // A final slot forbids same-cycle refill.
    manager_wdata[1] = 64'h3;
    manager_wlast[1] = 1'b0;
    #1;
    check(target_wvalid && target_wlast && manager_wready == 3'b000 &&
          manager_w_fire == 3'b000, "final slot blocks drain/refill");
    tick();
    check(!target_wvalid, "final slot clears");

    // Wrong target and conflicting owners are both blocked.
    owner_target[1] = 4'b0010;
    manager_wvalid = 3'b010;
    #1;
    check(manager_wready == 3'b000, "owner on another target is blocked");
    owner_target[1] = 4'b0001;
    owner_active[0] = 1'b1;
    owner_target[0] = 4'b0001;
    #1;
    check(owner_conflict_violation && manager_wready == 3'b000,
          "conflicting owners raise violation and suppress WREADY");

    $display("PASS axi_w_target_path_tb checks=%0d", checks);
    $finish;
  end
endmodule
