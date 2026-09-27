module axi_aw_write_state_composition_tb;
  logic ACLK = 1'b0;
  logic ARESETn = 1'b0;
  always #5 ACLK = ~ACLK;

  logic [2:0] manager_awvalid;
  logic [2:0][3:0] manager_awid;
  logic [2:0][31:0] manager_awaddr;
  logic [2:0][7:0] manager_awlen;
  logic [2:0][2:0] manager_awsize;
  logic [2:0][1:0] manager_awburst;
  logic [2:0] manager_awlock;
  logic [2:0][3:0] manager_awcache;
  logic [2:0][2:0] manager_awprot;
  logic [2:0][3:0] manager_awqos, manager_awregion;
  logic [2:0] request_legal, target_match;
  logic target_awready;
  logic [2:0] manager_awready, manager_aw_fire;
  logic aw_admit_fire;
  logic [1:0] admitted_manager;
  logic [3:0] admitted_awid, admitted_target;
  logic [7:0] admitted_awlen;
  logic [5:0] admitted_internal_id;
  logic target_awvalid, target_aw_fire;
  logic [5:0] target_awid;
  logic [31:0] target_awaddr;
  logic [7:0] target_awlen;
  logic [2:0] target_awsize;
  logic [1:0] target_awburst;
  logic target_awlock;
  logic [3:0] target_awcache;
  logic [2:0] target_awprot;
  logic [3:0] target_awqos, target_awregion;

  logic [2:0][3:0] request_awid;
  logic [2:0] bank_aw_admit_fire;
  logic [2:0][3:0] bank_aw_admit_id, bank_aw_admit_target;
  logic [2:0][5:0] bank_aw_admit_internal_id;
  logic [2:0][7:0] bank_aw_admit_len;
  logic [2:0] w_fire, wlast, b_complete_fire;
  logic [2:0][3:0] b_complete_id;
  logic [2:0] outstanding_allowed, owner_active, state_allowed, commit_fire;
  logic [2:0][15:0] busy_bitmap;
  logic [2:0][2:0] outstanding_count;
  logic [2:0][3:0] owner_target, owner_id;
  logic [2:0][5:0] owner_internal_id;
  logic [2:0][4:0] owner_beats_remaining;
  logic [2:0] owner_expected_wlast, admission_state_violation;
  logic [2:0] outstanding_violation, owner_violation;
  integer checks = 0;

  axi_write_state_bank state (
    .ACLK, .ARESETn, .request_awid, .aw_admit_fire(bank_aw_admit_fire),
    .aw_admit_id(bank_aw_admit_id), .aw_admit_internal_id(bank_aw_admit_internal_id),
    .aw_admit_target(bank_aw_admit_target), .aw_admit_len(bank_aw_admit_len),
    .w_fire, .wlast, .b_complete_fire, .b_complete_id, .outstanding_allowed,
    .busy_bitmap, .outstanding_count, .owner_active, .owner_target, .owner_id,
    .owner_internal_id, .owner_beats_remaining, .owner_expected_wlast,
    .state_allowed, .commit_fire, .admission_state_violation,
    .outstanding_violation, .owner_violation
  );

  axi_aw_target_path_a #(.TARGET_INDEX(0)) path (
    .ACLK, .ARESETn, .manager_awvalid, .manager_awid, .manager_awaddr,
    .manager_awlen, .manager_awsize, .manager_awburst, .manager_awlock,
    .manager_awcache, .manager_awprot, .manager_awqos, .manager_awregion,
    .request_legal, .target_match, .outstanding_allowed, .owner_active,
    .owner_target_m0(owner_target[0]), .owner_target_m1(owner_target[1]),
    .owner_target_m2(owner_target[2]), .target_awready,
    .manager_awready, .manager_aw_fire, .aw_admit_fire, .admitted_manager,
    .admitted_awid, .admitted_internal_id, .admitted_target, .admitted_awlen,
    .target_awvalid, .target_awid, .target_awaddr, .target_awlen,
    .target_awsize, .target_awburst, .target_awlock, .target_awcache,
    .target_awprot, .target_awqos, .target_awregion, .target_aw_fire
  );

  always_comb begin
    request_awid = manager_awid;
    bank_aw_admit_fire = '0;
    bank_aw_admit_id = '0;
    bank_aw_admit_internal_id = '0;
    bank_aw_admit_target = '0;
    bank_aw_admit_len = '0;
    if (aw_admit_fire) begin
      bank_aw_admit_fire[admitted_manager] = 1'b1;
      bank_aw_admit_id[admitted_manager] = admitted_awid;
      bank_aw_admit_internal_id[admitted_manager] = admitted_internal_id;
      bank_aw_admit_target[admitted_manager] = admitted_target;
      bank_aw_admit_len[admitted_manager] = admitted_awlen;
    end
  end

  task automatic check(input logic condition, input string message);
    begin
      checks = checks + 1;
      if (!condition) begin
        $display("FAIL: %s", message);
        $fatal(1);
      end
    end
  endtask

  initial begin
    manager_awvalid = 3'b000; manager_awid = '0; manager_awaddr = '0;
    manager_awlen = '0; manager_awsize = '0; manager_awburst = '0;
    manager_awlock = '0; manager_awcache = '0; manager_awprot = '0;
    manager_awqos = '0; manager_awregion = '0;
    request_legal = 3'b001; target_match = 3'b001; target_awready = 1'b0;
    w_fire = '0; wlast = '0; b_complete_fire = '0; b_complete_id = '0;
    manager_awid[0] = 4'hA; manager_awaddr[0] = 32'h0000_0040;
    manager_awlen[0] = 8'd1; manager_awsize[0] = 3'd3;
    manager_awburst[0] = 2'b01; manager_awcache[0] = 4'h5;
    manager_awprot[0] = 3'h2; manager_awqos[0] = 4'h7; manager_awregion[0] = 4'h1;
    repeat (2) @(posedge ACLK); ARESETn = 1'b1; #1;
    manager_awvalid = 3'b001;
    @(posedge ACLK); #1;
    check(manager_awready == 3'b001 && manager_aw_fire == 3'b001,
          "AW admission reaches shared bank");
    @(posedge ACLK); #1;
    check(aw_admit_fire == 1'b0 && target_awvalid &&
          busy_bitmap[0][10] && outstanding_count[0] == 3'd1 &&
          owner_active[0], "admission allocates shared state before target fire");
    check(owner_target[0] == 4'b0001 && owner_id[0] == 4'hA &&
          owner_internal_id[0] == 6'b00_1010 && owner_beats_remaining[0] == 5'd2,
          "shared owner metadata matches AW admission");

    // Target consumption is independent and cannot allocate a second entry.
    target_awready = 1'b1; #1;
    check(target_aw_fire, "target AW handshake is visible before its edge");
    @(posedge ACLK); #1;
    check(outstanding_count[0] == 3'd1 && busy_bitmap[0][10] && owner_active[0],
          "target AW fire does not allocate shared state again");

    // WLAST releases owner while B-pending ID remains blocked.
    target_awready = 1'b0; w_fire[0] = 1'b1; wlast[0] = 1'b0;
    @(posedge ACLK); #1; wlast[0] = 1'b1; @(posedge ACLK); #1; w_fire[0] = 1'b0; wlast[0] = 1'b0;
    check(!owner_active[0] && busy_bitmap[0][10] && !outstanding_allowed[0],
          "owner clears at WLAST while same ID remains outstanding");

    // B completion does not recycle ID/credit in the same cycle.
    b_complete_id[0] = 4'hA; b_complete_fire[0] = 1'b1;
    #1; check(!state_allowed[0], "B completion does not create same-cycle credit");
    @(posedge ACLK); #1; b_complete_fire[0] = 1'b0;
    check(outstanding_count[0] == 3'd0 && !busy_bitmap[0][10],
          "B completion clears outstanding on clock edge");
    $display("PASS axi_aw_write_state_composition_tb checks=%0d", checks);
    $finish;
  end
endmodule
