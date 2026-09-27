module axi_b_write_state_composition_tb;
  logic ACLK = 0;
  always #5 ACLK = ~ACLK;
  logic ARESETn;

  logic [2:0][3:0] request_awid;
  logic [2:0] aw_admit_fire;
  logic [2:0][3:0] aw_admit_id;
  logic [2:0][5:0] aw_admit_internal_id;
  logic [2:0][3:0] aw_admit_target;
  logic [2:0][7:0] aw_admit_len;
  logic [2:0] w_fire, wlast;
  logic [2:0] b_complete_fire;
  logic [2:0][3:0] b_complete_id;
  logic [2:0] outstanding_allowed, owner_active, state_allowed, commit_fire;
  logic [2:0][15:0] busy_bitmap;
  logic [2:0][2:0] outstanding_count;
  logic [2:0][3:0] owner_target, owner_id;
  logic [2:0][5:0] owner_internal_id;
  logic [2:0][4:0] owner_beats_remaining;
  logic [2:0] owner_expected_wlast;
  logic [2:0] admission_state_violation, outstanding_violation, owner_violation;

  logic [3:0] target_bvalid, target_bready, target_b_fire;
  logic [3:0][5:0] target_bid;
  logic [3:0][1:0] target_bresp;
  logic [2:0] manager_bvalid, manager_bready, manager_b_fire;
  logic [2:0][3:0] manager_bid;
  logic [2:0][1:0] manager_bresp;
  logic [2:0] router_b_complete_fire;
  logic [2:0][3:0] router_b_complete_id;
  logic [3:0] invalid_manager_violation, nonbusy_id_violation;
  logic [2:0] response_admit_fire;
  logic [2:0] slot_valid;
  logic [2:0][1:0] slot_source_target;
  integer checks = 0;

  axi_write_state_bank state_bank (.*);
  axi_b_response_router b_router (
    .ACLK, .ARESETn, .target_bvalid, .target_bid, .target_bresp,
    .target_bready, .target_b_fire, .busy_bitmap,
    .manager_bvalid, .manager_bid, .manager_bresp, .manager_bready,
    .manager_b_fire, .b_complete_fire(router_b_complete_fire),
    .b_complete_id(router_b_complete_id), .invalid_manager_violation,
    .nonbusy_id_violation, .response_admit_fire, .slot_valid, .slot_source_target
  );
  assign b_complete_fire = router_b_complete_fire;
  assign b_complete_id = router_b_complete_id;

  task automatic check(input logic condition, input string message);
    begin checks = checks + 1; if (!condition) begin $display("FAIL: %s", message); $fatal(1); end end
  endtask
  task automatic tick; begin @(posedge ACLK); #1; end endtask
  task automatic clear_inputs;
    begin
      request_awid = '0; aw_admit_fire = 0; aw_admit_id = '0;
      aw_admit_internal_id = '0; aw_admit_target = '0; aw_admit_len = '0;
      w_fire = 0; wlast = 0; b_complete_fire = 0; b_complete_id = '0;
      target_bvalid = 0; target_bid = '0; target_bresp = '0; manager_bready = 0;
    end
  endtask
  task automatic reset_all;
    begin clear_inputs(); ARESETn = 0; tick(); tick(); ARESETn = 1; end
  endtask

  initial begin
    reset_all();
    // M0 AW admission allocates shared outstanding and owner state once.
    request_awid[0] = 4'h5;
    aw_admit_id[0] = 4'h5; aw_admit_internal_id[0] = 6'b00_0101;
    aw_admit_target[0] = 4'b0001; aw_admit_len[0] = 8'd0;
    aw_admit_fire[0] = 1'b1;
    #1; check(commit_fire[0] && state_allowed[0], "AW commits shared state");
    tick(); aw_admit_fire[0] = 1'b0;
    check(busy_bitmap[0][5] && outstanding_count[0] == 1 && owner_active[0],
          "AW admission allocates busy ID, count and owner");

    // Final W delivery clears only the owner; the write remains outstanding.
    w_fire[0] = 1'b1; wlast[0] = 1'b1; tick(); w_fire[0] = 1'b0; wlast[0] = 1'b0;
    check(!owner_active[0] && busy_bitmap[0][5] && outstanding_count[0] == 1,
          "W completion releases owner but not outstanding write");

    // Target B admission fills the manager slot but does not complete the write.
    target_bvalid[0] = 1'b1; target_bid[0] = {2'b00,4'h5}; target_bresp[0] = 2'b10;
    tick();
    check(target_bready[0] && target_b_fire[0], "target B is admitted");
    tick();
    check(manager_bvalid[0] && manager_bid[0] == 4'h5 &&
          busy_bitmap[0][5] && outstanding_count[0] == 1 && b_complete_fire == 0,
          "target B admission does not complete write");

    // Completion and same-ID re-admission see registered pre-state.
    manager_bready[0] = 1'b1; aw_admit_fire[0] = 1'b1;
    #1; check(manager_b_fire[0] && !commit_fire[0] && !state_allowed[0],
             "same-ID AW blocked on B completion cycle");
    tick(); aw_admit_fire[0] = 1'b0; manager_bready[0] = 1'b0;
    check(!busy_bitmap[0][5] && outstanding_count[0] == 0 && !manager_bvalid[0],
          "manager B handshake clears outstanding state");
    #1; check(state_allowed[0], "same-ID capacity returns following cycle");

    $display("PASS axi_b_write_state_composition_tb checks=%0d", checks);
    $finish;
  end
endmodule
