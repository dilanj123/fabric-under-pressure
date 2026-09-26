module axi_aw_target_path_formal(input logic ACLK);
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
  (* anyseq *) logic [2:0][3:0] manager_awqos;
  (* anyseq *) logic [2:0][3:0] manager_awregion;
  (* anyseq *) logic [2:0] request_legal, target_match, outstanding_allowed;
  (* anyseq *) logic [2:0] owner_active;
  (* anyseq *) logic [3:0] owner_target_m0, owner_target_m1, owner_target_m2;
  (* anyseq *) logic target_awready;

  logic [2:0] manager_awready, manager_aw_fire;
  logic aw_admit_fire;
  logic [1:0] admitted_manager;
  logic [3:0] admitted_awid, admitted_target;
  logic [5:0] admitted_internal_id;
  logic [7:0] admitted_awlen;
  logic target_awvalid;
  logic [5:0] target_awid;
  logic [31:0] target_awaddr;
  logic [7:0] target_awlen;
  logic [2:0] target_awsize;
  logic [1:0] target_awburst;
  logic target_awlock;
  logic [3:0] target_awcache;
  logic [2:0] target_awprot;
  logic [3:0] target_awqos, target_awregion;
  logic target_aw_fire;
  logic [2:0] formal_scheduler_request;
  logic formal_scheduler_aw_accept;
  logic [2:0] formal_raw_eligible;
  logic formal_target_owner_busy, formal_grant_valid;
  logic [2:0] formal_grant;
  logic [1:0] formal_selected_manager;
  logic [3:0] formal_selected_awid;
  logic [31:0] formal_selected_awaddr;
  logic [7:0] formal_selected_awlen;
  logic [2:0] formal_selected_awsize;
  logic [1:0] formal_selected_awburst;
  logic formal_selected_awlock;
  logic [3:0] formal_selected_awcache;
  logic [2:0] formal_selected_awprot;
  logic [3:0] formal_selected_awqos, formal_selected_awregion;

  axi_aw_target_path_a #(.TARGET_INDEX(0)) dut (
    .ACLK, .ARESETn, .manager_awvalid, .manager_awid, .manager_awaddr,
    .manager_awlen, .manager_awsize, .manager_awburst, .manager_awlock,
    .manager_awcache, .manager_awprot, .manager_awqos, .manager_awregion,
    .request_legal, .target_match, .outstanding_allowed, .owner_active,
    .owner_target_m0, .owner_target_m1, .owner_target_m2, .target_awready,
    .manager_awready, .manager_aw_fire, .aw_admit_fire, .admitted_manager,
    .admitted_awid, .admitted_internal_id, .admitted_target, .admitted_awlen,
    .target_awvalid, .target_awid, .target_awaddr, .target_awlen,
    .target_awsize, .target_awburst, .target_awlock, .target_awcache,
    .target_awprot, .target_awqos, .target_awregion, .target_aw_fire,
    .formal_scheduler_request, .formal_scheduler_aw_accept,
    .formal_raw_eligible, .formal_target_owner_busy, .formal_grant,
    .formal_grant_valid, .formal_selected_manager, .formal_selected_awid,
    .formal_selected_awaddr, .formal_selected_awlen, .formal_selected_awsize,
    .formal_selected_awburst, .formal_selected_awlock, .formal_selected_awcache,
    .formal_selected_awprot, .formal_selected_awqos, .formal_selected_awregion
  );

  // A second parameterization supplies an S3 reachability cover without
  // changing the production boundary or adding a multi-target implementation.
  (* anyseq *) logic s3_target_awready;
  logic s3_aw_admit;
  axi_aw_target_path_a #(.TARGET_INDEX(3)) s3 (
    .ACLK, .ARESETn, .manager_awvalid, .manager_awid, .manager_awaddr,
    .manager_awlen, .manager_awsize, .manager_awburst, .manager_awlock,
    .manager_awcache, .manager_awprot, .manager_awqos, .manager_awregion,
    .request_legal, .target_match(manager_awvalid),
    .outstanding_allowed, .owner_active, .owner_target_m0, .owner_target_m1,
    .owner_target_m2, .target_awready(s3_target_awready),
    .manager_awready(), .manager_aw_fire(), .aw_admit_fire(s3_aw_admit),
    .admitted_manager(), .admitted_awid(), .admitted_internal_id(),
    .admitted_target(), .admitted_awlen(), .target_awvalid(), .target_awid(),
    .target_awaddr(), .target_awlen(), .target_awsize(), .target_awburst(),
    .target_awlock(), .target_awcache(), .target_awprot(), .target_awqos(),
    .target_awregion(), .target_aw_fire()
  );

  initial assume (!ARESETn);

  integer m;
  always @(posedge ACLK) begin
    if (ARESETn) begin
      // Supported manager sources hold AWVALID and payload while stalled.
      for (m = 0; m < 3; m = m + 1) begin
        if ($past(manager_awvalid[m] && !manager_awready[m])) begin
          assume (manager_awvalid[m]);
          assume (manager_awid[m] == $past(manager_awid[m]));
          assume (manager_awaddr[m] == $past(manager_awaddr[m]));
          assume (manager_awlen[m] == $past(manager_awlen[m]));
          assume (manager_awsize[m] == $past(manager_awsize[m]));
          assume (manager_awburst[m] == $past(manager_awburst[m]));
          assume (manager_awlock[m] == $past(manager_awlock[m]));
          assume (manager_awcache[m] == $past(manager_awcache[m]));
          assume (manager_awprot[m] == $past(manager_awprot[m]));
          assume (manager_awqos[m] == $past(manager_awqos[m]));
          assume (manager_awregion[m] == $past(manager_awregion[m]));
        end
      end

      assert ($onehot0(manager_awready));
      assert ($onehot0(manager_aw_fire));
      assert (aw_admit_fire == (|manager_aw_fire));
      if (aw_admit_fire) assert (formal_scheduler_aw_accept);
      assert ((manager_awready & ~formal_grant) == 3'b000);
      if (|manager_awready) assert (formal_grant_valid);
      assert (formal_grant_valid == (formal_grant != 3'b000));
      assert ($onehot0(formal_grant));
      assert (!formal_target_owner_busy || manager_awready == 3'b000);
      assert (target_aw_fire == (target_awvalid && target_awready));

      // D032: an occupied slot cannot be replaced on its drain cycle.
      if (target_awvalid) assert (aw_admit_fire == 1'b0);
      // D031 remains visible at the composed boundary.
      if (aw_admit_fire) assert (formal_scheduler_request == 3'b000);
    end else begin
      assert (!target_awvalid);
      assert (!aw_admit_fire);
    end
  end

  always @(posedge ACLK) begin
    if (ARESETn) begin
      if ($past(aw_admit_fire)) begin
        assert (target_awvalid);
        assert (target_awid == $past(admitted_internal_id));
        assert (target_awaddr == $past(formal_selected_awaddr));
        assert (target_awlen == $past(admitted_awlen));
        assert (target_awsize == $past(formal_selected_awsize));
        assert (target_awburst == $past(formal_selected_awburst));
        assert (target_awlock == $past(formal_selected_awlock));
        assert (target_awcache == $past(formal_selected_awcache));
        assert (target_awprot == $past(formal_selected_awprot));
        assert (target_awqos == $past(formal_selected_awqos));
        assert (target_awregion == $past(formal_selected_awregion));
        assert (target_awid == {$past(admitted_manager), $past(formal_selected_awid)});
      end
      if ($past(target_awvalid && !target_awready)) begin
        assert (target_awvalid);
        assert (target_awid == $past(target_awid));
        assert (target_awaddr == $past(target_awaddr));
        assert (target_awlen == $past(target_awlen));
        assert (target_awsize == $past(target_awsize));
        assert (target_awburst == $past(target_awburst));
        assert (target_awlock == $past(target_awlock));
        assert (target_awcache == $past(target_awcache));
        assert (target_awprot == $past(target_awprot));
        assert (target_awqos == $past(target_awqos));
        assert (target_awregion == $past(target_awregion));
      end
    end
  end

  always @(posedge ACLK) begin
    cover (ARESETn && aw_admit_fire && admitted_manager == 2'b00);
    cover (ARESETn && aw_admit_fire && admitted_manager == 2'b01);
    cover (ARESETn && aw_admit_fire && admitted_manager == 2'b10);
    cover (ARESETn && s3_aw_admit);
    cover (ARESETn && target_awvalid && !target_awready);
    cover (ARESETn && target_awvalid && target_awready);
    cover (ARESETn && target_awvalid && manager_awvalid != 3'b000);
    cover (ARESETn && $past(target_aw_fire) && aw_admit_fire);
    cover (!ARESETn && !target_awvalid);
  end
endmodule
