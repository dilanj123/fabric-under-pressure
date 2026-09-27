module axi_aw_write_state_composition_formal(input logic ACLK);
  localparam int M = 3;
  (* anyseq *) logic ARESETn;
  (* anyseq *) logic [2:0] manager_awvalid;
  (* anyseq *) logic [2:0][3:0] manager_awid;
  (* anyseq *) logic [2:0][31:0] manager_awaddr;
  (* anyseq *) logic [2:0][7:0] manager_awlen;
  (* anyseq *) logic [2:0][2:0] manager_awsize;
  (* anyseq *) logic [2:0][1:0] manager_awburst;
  (* anyseq *) logic [2:0] manager_awlock;
  (* anyseq *) logic [2:0][3:0] manager_awcache;
  (* anyseq *) logic [2:0][2:0] manager_awprot;
  (* anyseq *) logic [2:0][3:0] manager_awqos, manager_awregion;
  (* anyseq *) logic [2:0] request_legal, target_match;
  (* anyseq *) logic target_awready;
  (* anyseq *) logic [2:0] w_fire, wlast, b_complete_fire;
  (* anyseq *) logic [2:0][3:0] b_complete_id;

  logic [2:0] manager_awready, manager_aw_fire;
  logic aw_admit_fire;
  logic [1:0] admitted_manager;
  logic [3:0] admitted_awid, admitted_target;
  logic [5:0] admitted_internal_id;
  logic [7:0] admitted_awlen;
  logic target_awvalid, target_awfire;
  logic [5:0] target_awid;
  logic [31:0] target_awaddr;
  logic [7:0] target_awlen;
  logic [2:0] target_awsize;
  logic [1:0] target_awburst;
  logic target_awlock;
  logic [3:0] target_awcache;
  logic [2:0] target_awprot;
  logic [3:0] target_awqos, target_awregion;

  logic [2:0] outstanding_allowed, owner_active, state_allowed, commit_fire;
  logic [2:0][15:0] busy_bitmap;
  logic [2:0][2:0] outstanding_count;
  logic [2:0][3:0] owner_target, owner_id;
  logic [2:0][5:0] owner_internal_id;
  logic [2:0][4:0] owner_beats_remaining;
  logic [2:0] owner_expected_wlast, admission_state_violation;
  logic [2:0] outstanding_violation, owner_violation;
  logic [2:0][3:0] bank_aw_admit_id, bank_aw_admit_target;
  logic [2:0][5:0] bank_aw_admit_internal_id;
  logic [2:0][7:0] bank_aw_admit_len;
  logic [2:0] bank_aw_admit_fire;

  axi_write_state_bank state (
    .ACLK, .ARESETn, .request_awid(manager_awid),
    .aw_admit_fire(bank_aw_admit_fire), .aw_admit_id(bank_aw_admit_id),
    .aw_admit_internal_id(bank_aw_admit_internal_id),
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
    .target_awprot, .target_awqos, .target_awregion, .target_aw_fire(target_awfire)
  );

  always_comb begin
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

  integer m;
  integer init_cycles = 0;
  initial assume (!ARESETn);
  always @(posedge ACLK) begin
    if (init_cycles < 2) begin
      assume (!ARESETn);
      init_cycles = init_cycles + 1;
    end
    if ($initstate) assume (!ARESETn);
    if ($past(ARESETn)) assume (ARESETn);
    if (ARESETn) begin
      // Completion events represent responses/W handshakes for state that
      // already existed at the beginning of the cycle.  This is a source
      // protocol assumption for the composition harness; it does not relax
      // the bank's defensive handling of directly injected admissions.
      for (m = 0; m < M; m = m + 1) begin
        assume (!w_fire[m] || owner_active[m]);
        assume (!b_complete_fire[m] || busy_bitmap[m][b_complete_id[m]]);
      end
    end
    if (ARESETn) begin
      assert ($onehot0(manager_awready));
      assert ($onehot0(manager_aw_fire));
      assert (aw_admit_fire == (|manager_aw_fire));
      assert (target_awfire == (target_awvalid && target_awready));
      if (aw_admit_fire) begin
        assert (admitted_manager != 2'b11);
        assert (admitted_awid == manager_awid[admitted_manager]);
      end
      if (target_awvalid) assert (!aw_admit_fire);
      for (m = 0; m < M; m = m + 1) begin
        // A manager source holds an unaccepted AW and its request-shape and
        // target facts until the handshake.  This is the AXI VALID stability
        // assumption needed when the composed RR grant is stalled.
        if ($past(ARESETn && manager_awvalid[m] && !manager_awready[m])) begin
          assume (manager_awvalid[m]);
          assume (manager_awid[m] == $past(manager_awid[m]));
          assume (manager_awaddr[m] == $past(manager_awaddr[m]));
          assume (manager_awlen[m] == $past(manager_awlen[m]));
          assume (request_legal[m] == $past(request_legal[m]));
          assume (target_match[m] == $past(target_match[m]));
          assume (outstanding_allowed[m] == $past(outstanding_allowed[m]));
          assume (owner_active[m] == $past(owner_active[m]));
        end
        if (manager_aw_fire[m]) begin
          assert (state_allowed[m]);
          assert (!admission_state_violation[m]);
        end
        // Target-side consumption is not an allocation event.  The bank is
        // driven only by the manager-facing admission demux below.
        if (target_awfire) assert (!aw_admit_fire && !commit_fire[m]);
      end
    end else begin
      assert (!target_awvalid && !aw_admit_fire);
    end
  end

  always @(posedge ACLK) begin
    cover (ARESETn && aw_admit_fire && admitted_manager == 2'b00);
    cover (ARESETn && aw_admit_fire && admitted_manager == 2'b01);
    cover (ARESETn && aw_admit_fire && admitted_manager == 2'b10);
    cover (ARESETn && $past(aw_admit_fire) && target_awvalid && !target_awready);
    cover (ARESETn && target_awvalid && target_awready);
    cover (ARESETn && $past(target_awfire) && aw_admit_fire);
    cover (ARESETn && $past(aw_admit_fire) &&
           (owner_active[0] || owner_active[1] || owner_active[2]));
    cover (ARESETn && $past(owner_active[0]) && !owner_active[0] &&
           outstanding_count[0] != 3'd0);
  end
endmodule
