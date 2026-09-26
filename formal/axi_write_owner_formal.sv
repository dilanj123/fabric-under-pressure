module axi_write_owner_formal(input logic ACLK);
  (* anyseq *) logic ARESETn;
  (* anyseq *) logic allocate_fire;
  (* anyseq *) logic [3:0] allocate_target;
  (* anyseq *) logic [3:0] allocate_id;
  (* anyseq *) logic [5:0] allocate_internal_id;
  (* anyseq *) logic [7:0] allocate_len;
  (* anyseq *) logic w_fire;
  (* anyseq *) logic wlast;

  logic allocate_allowed, active;
  logic [3:0] owner_target, owner_id;
  logic [5:0] owner_internal_id;
  logic [4:0] beats_remaining;
  logic expected_wlast;
  logic allocate_violation, w_without_owner_violation, wlast_mismatch_violation;

  logic ref_active;
  logic [3:0] ref_target, ref_id;
  logic [5:0] ref_internal_id;
  logic [4:0] ref_beats;
  logic allocate_do, final_do;

  axi_write_owner dut (
    .ACLK(ACLK), .ARESETn(ARESETn), .allocate_fire(allocate_fire),
    .allocate_target(allocate_target), .allocate_id(allocate_id),
    .allocate_internal_id(allocate_internal_id), .allocate_len(allocate_len),
    .w_fire(w_fire), .wlast(wlast), .allocate_allowed(allocate_allowed),
    .active(active), .owner_target(owner_target), .owner_id(owner_id),
    .owner_internal_id(owner_internal_id), .beats_remaining(beats_remaining),
    .expected_wlast(expected_wlast), .allocate_violation(allocate_violation),
    .w_without_owner_violation(w_without_owner_violation),
    .wlast_mismatch_violation(wlast_mismatch_violation)
  );

  initial assume (!ARESETn);

  always @* begin
    // Legal allocation length is an upstream request-legality contract.
    if (ARESETn && allocate_fire && !ref_active)
      assume (allocate_len <= 8'd15);

    allocate_do = allocate_fire && !ref_active;
    final_do = ref_active && w_fire && (ref_beats == 5'd1) && wlast;
  end

  always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      ref_active <= 1'b0;
      ref_target <= 4'b0;
      ref_id <= 4'b0;
      ref_internal_id <= 6'b0;
      ref_beats <= 5'b0;
    end else if (allocate_do) begin
      ref_active <= 1'b1;
      ref_target <= allocate_target;
      ref_id <= allocate_id;
      ref_internal_id <= allocate_internal_id;
      ref_beats <= (allocate_len > 8'd15) ? 5'd16 : ({1'b0, allocate_len[3:0]} + 5'd1);
    end else if (final_do) begin
      ref_active <= 1'b0;
      ref_target <= 4'b0;
      ref_id <= 4'b0;
      ref_internal_id <= 6'b0;
      ref_beats <= 5'b0;
    end else if (ref_active && w_fire && (ref_beats > 5'd1)) begin
      ref_beats <= ref_beats - 5'd1;
    end
  end

  // Outputs and diagnostics are checked against registered pre-state.
  always @(posedge ACLK) begin
    if (ARESETn) begin
      assert (active == ref_active);
      assert (allocate_allowed == !ref_active);
      assert (owner_target == (ref_active ? ref_target : 4'b0));
      assert (owner_id == (ref_active ? ref_id : 4'b0));
      assert (owner_internal_id == (ref_active ? ref_internal_id : 6'b0));
      assert (beats_remaining == (ref_active ? ref_beats : 5'b0));
      assert (expected_wlast == (ref_active && (ref_beats == 5'd1)));
      assert (allocate_violation == (allocate_fire && ref_active));
      assert (w_without_owner_violation == (w_fire && !ref_active));
      assert (wlast_mismatch_violation ==
              (ref_active && w_fire &&
               (wlast != (ref_beats == 5'd1))));
      assert (!active || (beats_remaining >= 5'd1 && beats_remaining <= 5'd16));
    end else begin
      assert (!active);
      assert (beats_remaining == 5'b0);
      assert (!allocate_violation && !w_without_owner_violation && !wlast_mismatch_violation);
    end
  end

  always @* begin
    assert (!active || (beats_remaining >= 5'd1 && beats_remaining <= 5'd16));
    assert (active || beats_remaining == 5'b0);

    cover (ARESETn && allocate_do && allocate_len == 8'd0);
    cover (ARESETn && allocate_do && allocate_len == 8'd15);
    cover (ARESETn && ref_active && !w_fire);
    cover (ARESETn && ref_active && w_fire && (ref_beats > 5'd1) && wlast);
    cover (ARESETn && ref_active && w_fire && (ref_beats == 5'd1) && !wlast);
    cover (ARESETn && w_fire && !ref_active);
    cover (ARESETn && allocate_fire && ref_active);
    cover (ARESETn && final_do);
  end
endmodule
