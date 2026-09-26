module aw_target_scheduler_formal(input logic ACLK);
  (* anyseq *) logic ARESETn;
  (* anyseq *) logic [2:0] request_present;
  (* anyseq *) logic [2:0] request_legal;
  (* anyseq *) logic [2:0] target_match;
  (* anyseq *) logic [2:0] outstanding_allowed;
  (* anyseq *) logic [2:0] owner_active;
  (* anyseq *) logic [3:0] owner_target_m0, owner_target_m1, owner_target_m2;
  (* anyseq *) logic target_ready;

  logic [2:0] raw_eligible, grant;
  logic target_owner_busy, grant_valid, aw_accept_fire;
  logic [1:0] selected_manager;
  logic [2:0] formal_arbiter_request;

  axi_aw_target_scheduler_a #(.TARGET_INDEX(0)) dut (
    .ACLK, .ARESETn, .request_present, .request_legal, .target_match,
    .outstanding_allowed, .owner_active, .owner_target_m0, .owner_target_m1,
    .owner_target_m2, .target_ready, .raw_eligible, .target_owner_busy,
    .grant, .grant_valid, .selected_manager, .aw_accept_fire,
    .formal_arbiter_request
  );

  logic [2:0] expected_raw;
  always_comb begin
    expected_raw = request_present & request_legal & target_match &
                   outstanding_allowed;
    if (owner_active[0] && owner_target_m0[0]) expected_raw = 3'b000;
    if (owner_active[1] && owner_target_m1[0]) expected_raw = 3'b000;
    if (owner_active[2] && owner_target_m2[0]) expected_raw = 3'b000;
    expected_raw[0] = expected_raw[0] && !owner_active[0];
    expected_raw[1] = expected_raw[1] && !owner_active[1];
    expected_raw[2] = expected_raw[2] && !owner_active[2];
  end

  initial assume (!ARESETn);

  always @* begin
    if (ARESETn) begin
      assert (raw_eligible == expected_raw);
      assert (target_owner_busy ==
              ((owner_active[0] && owner_target_m0[0]) ||
               (owner_active[1] && owner_target_m1[0]) ||
               (owner_active[2] && owner_target_m2[0])));
      if (target_owner_busy) begin
        assert (raw_eligible == 3'b000);
        assert (!aw_accept_fire);
      end
      assert (!aw_accept_fire || grant_valid);
      assert (!aw_accept_fire || !target_owner_busy);
      assert ($onehot0(grant));
      assert (grant_valid == (grant != 3'b000));
      assert (!grant_valid || ((selected_manager == 2'b00 && grant == 3'b001) ||
                               (selected_manager == 2'b01 && grant == 3'b010) ||
                               (selected_manager == 2'b10 && grant == 3'b100)));
      // D031 is implemented at the boundary input to the registered RR.
      if (aw_accept_fire) assert (formal_arbiter_request == 3'b000);
    end

    cover (ARESETn && raw_eligible == 3'b001 && !grant_valid);
    cover (ARESETn && raw_eligible == 3'b010 && !grant_valid);
    cover (ARESETn && raw_eligible == 3'b100 && !grant_valid);
    cover (ARESETn && raw_eligible == 3'b111 && !target_ready);
    cover (ARESETn && aw_accept_fire);
    cover (ARESETn && target_owner_busy && raw_eligible == 3'b000);
  end
endmodule
