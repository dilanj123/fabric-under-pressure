module aw_target_scheduler_composition_formal(input logic ACLK);
  (* anyseq *) logic ARESETn;
  (* anyseq *) logic [2:0] request_present, request_legal;
  (* anyseq *) logic [2:0] target_match, outstanding_allowed;
  (* anyseq *) logic target_ready;
  (* anyseq *) logic [2:0] w_fire;
  (* anyseq *) logic [2:0] wlast;
  (* anyseq *) logic [3:0] allocate_len;

  logic [2:0] owner_active;
  logic [3:0] owner_target_m0, owner_target_m1, owner_target_m2;
  logic [2:0] raw_eligible, grant;
  logic target_owner_busy, grant_valid, aw_accept_fire;
  logic [1:0] selected_manager;
  logic [2:0] formal_arbiter_request;

  axi_aw_target_scheduler_a #(.TARGET_INDEX(0)) boundary (
    .ACLK, .ARESETn, .request_present, .request_legal, .target_match,
    .outstanding_allowed, .owner_active, .owner_target_m0, .owner_target_m1,
    .owner_target_m2, .target_ready, .raw_eligible, .target_owner_busy,
    .grant, .grant_valid, .selected_manager, .aw_accept_fire,
    .formal_arbiter_request
  );

  logic [2:0] owner_allocate_fire;
  assign owner_allocate_fire = {3{aw_accept_fire}} & grant;

  logic [2:0] owner_allocate_allowed;
  logic [3:0] owner_id0, owner_id1, owner_id2;
  logic [5:0] owner_internal0, owner_internal1, owner_internal2;
  logic [4:0] owner_remaining0, owner_remaining1, owner_remaining2;
  logic owner_expected0, owner_expected1, owner_expected2;
  logic [2:0] alloc_violation, no_owner_violation, wlast_violation;

  axi_write_owner owner0 (
    .ACLK, .ARESETn, .allocate_fire(owner_allocate_fire[0]),
    .allocate_target(4'b0001), .allocate_id(4'b0000),
    .allocate_internal_id(6'b000000), .allocate_len({4'b0000, allocate_len}),
    .w_fire(w_fire[0]), .wlast(wlast[0]),
    .allocate_allowed(owner_allocate_allowed[0]), .active(owner_active[0]),
    .owner_target(owner_target_m0), .owner_id(owner_id0),
    .owner_internal_id(owner_internal0), .beats_remaining(owner_remaining0),
    .expected_wlast(owner_expected0), .allocate_violation(alloc_violation[0]),
    .w_without_owner_violation(no_owner_violation[0]),
    .wlast_mismatch_violation(wlast_violation[0])
  );
  axi_write_owner owner1 (
    .ACLK, .ARESETn, .allocate_fire(owner_allocate_fire[1]),
    .allocate_target(4'b0001), .allocate_id(4'b0000),
    .allocate_internal_id(6'b010000), .allocate_len({4'b0000, allocate_len}),
    .w_fire(w_fire[1]), .wlast(wlast[1]),
    .allocate_allowed(owner_allocate_allowed[1]), .active(owner_active[1]),
    .owner_target(owner_target_m1), .owner_id(owner_id1),
    .owner_internal_id(owner_internal1), .beats_remaining(owner_remaining1),
    .expected_wlast(owner_expected1), .allocate_violation(alloc_violation[1]),
    .w_without_owner_violation(no_owner_violation[1]),
    .wlast_mismatch_violation(wlast_violation[1])
  );
  axi_write_owner owner2 (
    .ACLK, .ARESETn, .allocate_fire(owner_allocate_fire[2]),
    .allocate_target(4'b0001), .allocate_id(4'b0000),
    .allocate_internal_id(6'b100000), .allocate_len({4'b0000, allocate_len}),
    .w_fire(w_fire[2]), .wlast(wlast[2]),
    .allocate_allowed(owner_allocate_allowed[2]), .active(owner_active[2]),
    .owner_target(owner_target_m2), .owner_id(owner_id2),
    .owner_internal_id(owner_internal2), .beats_remaining(owner_remaining2),
    .expected_wlast(owner_expected2), .allocate_violation(alloc_violation[2]),
    .w_without_owner_violation(no_owner_violation[2]),
    .wlast_mismatch_violation(wlast_violation[2])
  );

  initial assume (!ARESETn);

  always @* begin
    if (ARESETn) begin
      assert ($countones(owner_active) <= 1);
      assert (!target_owner_busy || raw_eligible == 3'b000);
      assert (!target_owner_busy || !aw_accept_fire);
      assert (allocate_len <= 4'd15);
      cover (aw_accept_fire);
      cover (target_owner_busy);
      cover (target_owner_busy && !aw_accept_fire);
    end
  end

  always @(posedge ACLK) begin
    if (ARESETn) begin
      if ($past(aw_accept_fire)) begin
        assert (target_owner_busy);
        assert (!aw_accept_fire);
      end
    end
  end
endmodule
