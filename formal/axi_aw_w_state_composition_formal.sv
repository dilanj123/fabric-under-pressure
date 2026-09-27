module axi_aw_w_state_composition_formal(input logic ACLK);
  (* anyseq *) logic ARESETn;
  (* anyseq *) logic [2:0] awvalid, request_legal, target_match;
  (* anyseq *) logic [2:0][3:0] awid;
  (* anyseq *) logic [2:0][31:0] awaddr;
  (* anyseq *) logic [2:0][7:0] awlen;
  (* anyseq *) logic [2:0][2:0] awsize;
  (* anyseq *) logic [2:0][1:0] awburst;
  (* anyseq *) logic [2:0] awlock;
  (* anyseq *) logic [2:0][3:0] awcache, awqos, awregion;
  (* anyseq *) logic [2:0][2:0] awprot;
  (* anyseq *) logic target_awready;
  (* anyseq *) logic [2:0] wvalid, wlast;
  (* anyseq *) logic [2:0][63:0] wdata;
  (* anyseq *) logic [2:0][7:0] wstrb;
  (* anyseq *) logic target_wready;

  logic [2:0] awready, awfire, outstanding_allowed, owner_active;
  logic aw_admit_fire, target_awvalid, target_awfire;
  logic [1:0] admitted_manager;
  logic [3:0] admitted_awid, admitted_target;
  logic [5:0] admitted_internal_id;
  logic [7:0] admitted_len;
  logic [5:0] target_awid; logic [31:0] target_awaddr; logic [7:0] target_awlen;
  logic [2:0] target_awsize; logic [1:0] target_awburst; logic target_awlock;
  logic [3:0] target_awcache, target_awqos, target_awregion; logic [2:0] target_awprot;
  logic [2:0][15:0] busy_bitmap; logic [2:0][2:0] outstanding_count;
  logic [2:0][3:0] owner_target, owner_id; logic [2:0][5:0] owner_internal_id;
  logic [2:0][4:0] owner_beats_remaining; logic [2:0] owner_expected_wlast;
  logic [2:0] state_allowed, commit_fire, admission_state_violation;
  logic [2:0] outstanding_violation, owner_violation;
  logic [2:0][3:0] admit_id, admit_target; logic [2:0][5:0] admit_internal_id;
  logic [2:0][7:0] admit_len;
  logic [2:0] b_complete_fire = 3'b000, b_complete_id = '0;
  logic [2:0] bank_w_fire, bank_wlast;
  logic [2:0] wready, wfire, owner_w_fire, owner_wlast;
  logic target_wvalid, target_wfire, target_wlast, owner_conflict_violation;
  logic [63:0] target_wdata; logic [7:0] target_wstrb; logic [1:0] selected_w_manager;
  logic selected_owner_valid;

  axi_aw_target_path_a #(.TARGET_INDEX(0)) aw_path (
    .ACLK, .ARESETn, .manager_awvalid(awvalid), .manager_awid(awid),
    .manager_awaddr(awaddr), .manager_awlen(awlen), .manager_awsize(awsize),
    .manager_awburst(awburst), .manager_awlock(awlock), .manager_awcache(awcache),
    .manager_awprot(awprot), .manager_awqos(awqos), .manager_awregion(awregion),
    .request_legal, .target_match, .outstanding_allowed, .owner_active,
    .owner_target_m0(owner_target[0]), .owner_target_m1(owner_target[1]),
    .owner_target_m2(owner_target[2]), .target_awready,
    .manager_awready(awready), .manager_aw_fire(awfire), .aw_admit_fire,
    .admitted_manager, .admitted_awid, .admitted_internal_id, .admitted_target,
    .admitted_awlen(admitted_len), .target_awvalid, .target_awid,
    .target_awaddr, .target_awlen, .target_awsize, .target_awburst,
    .target_awlock, .target_awcache, .target_awprot, .target_awqos,
    .target_awregion, .target_aw_fire(target_awfire)
  );

  always_comb begin
    admit_id = awid; admit_target = '0; admit_len = awlen;
    admit_target[0] = 4'b0001; admit_target[1] = 4'b0001; admit_target[2] = 4'b0001;
    admit_internal_id[0] = {2'b00, awid[0]};
    admit_internal_id[1] = {2'b01, awid[1]};
    admit_internal_id[2] = {2'b10, awid[2]};
  end

  axi_write_state_bank bank (
    .ACLK, .ARESETn, .request_awid(awid), .aw_admit_fire(awfire),
    .aw_admit_id(admit_id), .aw_admit_internal_id(admit_internal_id),
    .aw_admit_target(admit_target), .aw_admit_len(admit_len), .w_fire(bank_w_fire),
    .wlast(bank_wlast), .b_complete_fire, .b_complete_id,
    .outstanding_allowed, .busy_bitmap, .outstanding_count, .owner_active,
    .owner_target, .owner_id, .owner_internal_id, .owner_beats_remaining,
    .owner_expected_wlast, .state_allowed, .commit_fire,
    .admission_state_violation, .outstanding_violation, .owner_violation
  );

  axi_w_target_path #(.TARGET_INDEX(0)) w_path (
    .ACLK, .ARESETn, .manager_wvalid(wvalid), .manager_wdata(wdata),
    .manager_wstrb(wstrb), .manager_wlast(wlast), .owner_active, .owner_target,
    .target_wready, .manager_wready(wready), .manager_w_fire(wfire),
    .target_wvalid, .target_wdata, .target_wstrb, .target_wlast,
    .target_w_fire(target_wfire), .selected_manager(selected_w_manager),
    .selected_owner_valid, .owner_conflict_violation, .owner_w_fire,
    .owner_wlast
  );
  assign bank_w_fire = owner_w_fire;
  assign bank_wlast = owner_wlast;

  integer m;
  initial assume (!ARESETn);
  always @(posedge ACLK) begin
    if ($past(ARESETn)) assume (ARESETn);
    if (ARESETn) begin
      for (m = 0; m < 3; m = m + 1) begin
        assume (!wfire[m] || owner_active[m]);
        if ($past(awvalid[m] && !awready[m])) begin
          assume (awvalid[m]); assume (awid[m] == $past(awid[m]));
          assume (awlen[m] == $past(awlen[m])); assume (request_legal[m] == $past(request_legal[m]));
          assume (target_match[m] == $past(target_match[m]));
        end
        if ($past(wvalid[m] && !wready[m])) begin
          assume (wvalid[m]); assume (wdata[m] == $past(wdata[m]));
          assume (wstrb[m] == $past(wstrb[m])); assume (wlast[m] == $past(wlast[m]));
        end
        if (wready[m]) assert (owner_active[m] && owner_target[m][0]);
      end
      assert ($onehot0(awfire)); assert ($onehot0(wready)); assert ($onehot0(wfire));
      assert (!target_wfire || (target_wvalid && target_wready));
      if (target_awfire) assert (awfire == 3'b000);
      if (target_wfire && !target_wlast) assert (owner_w_fire != 3'b000);
      if ($past(target_wvalid && !target_wready)) begin
        assert (target_wvalid); assert (target_wdata == $past(target_wdata));
        assert (target_wstrb == $past(target_wstrb)); assert (target_wlast == $past(target_wlast));
      end
    end else begin
      assert (!target_wvalid && wready == 3'b000);
    end
  end

  always @(posedge ACLK) begin
    cover (ARESETn && aw_admit_fire && $past(wvalid != 3'b000) && wready == 3'b000);
    cover (ARESETn && target_wvalid && !target_wready);
    cover (ARESETn && target_wfire && !target_wlast && (|owner_w_fire));
    cover (ARESETn && target_wfire && target_wlast);
    cover (ARESETn && $past(target_wfire && target_wlast) && outstanding_count[0] != 0);
  end
endmodule
