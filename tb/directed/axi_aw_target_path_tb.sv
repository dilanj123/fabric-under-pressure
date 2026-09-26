module axi_aw_target_path_tb;
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
  logic [2:0][3:0] manager_awqos;
  logic [2:0][3:0] manager_awregion;
  logic [2:0] request_legal, target_match, outstanding_allowed, owner_active;
  logic [3:0] owner_target_m0, owner_target_m1, owner_target_m2;
  logic target_awready;
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
  integer checks = 0;

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
    .target_awprot, .target_awqos, .target_awregion, .target_aw_fire
  );

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
    integer i;
    begin
      manager_awvalid = 3'b000;
      request_legal = 3'b000;
      target_match = 3'b000;
      outstanding_allowed = 3'b000;
      owner_active = 3'b000;
      owner_target_m0 = 4'b0000;
      owner_target_m1 = 4'b0000;
      owner_target_m2 = 4'b0000;
      target_awready = 1'b0;
      for (i = 0; i < 3; i = i + 1) begin
        manager_awid[i] = 4'h0;
        manager_awaddr[i] = 32'h0;
        manager_awlen[i] = 8'h0;
        manager_awsize[i] = 3'h0;
        manager_awburst[i] = 2'h0;
        manager_awlock[i] = 1'b0;
        manager_awcache[i] = 4'h0;
        manager_awprot[i] = 3'h0;
        manager_awqos[i] = 4'h0;
        manager_awregion[i] = 4'h0;
      end
    end
  endtask

  task automatic make_eligible(input logic [2:0] mask);
    begin
      manager_awvalid = mask;
      request_legal = mask;
      target_match = mask;
      outstanding_allowed = mask;
    end
  endtask

  initial begin
    clear_inputs();
    repeat (2) @(posedge ACLK);
    ARESETn = 1'b1;
    #1;
    check(s3_mready == 3'b001 && s3_admit, "legal S3 request is admitted");
    @(posedge ACLK); #1;

    // M0 admission with deliberately unique values on every AW field.
    manager_awid[0] = 4'hA;
    manager_awaddr[0] = 32'h0000_1238;
    manager_awlen[0] = 8'h0F;
    manager_awsize[0] = 3'h3;
    manager_awburst[0] = 2'b01;
    manager_awlock[0] = 1'b0;
    manager_awcache[0] = 4'h5;
    manager_awprot[0] = 3'h2;
    manager_awqos[0] = 4'h8;
    manager_awregion[0] = 4'h1;
    make_eligible(3'b001);
    @(posedge ACLK); #1;
    check(manager_awready == 3'b001, "M0 only selected manager is ready");
    check(manager_aw_fire == 3'b001 && aw_admit_fire, "M0 admission fire");
    check(admitted_manager == 2'b00 && admitted_awid == 4'hA,
          "M0 admission metadata");
    check(admitted_internal_id == 6'b00_1010 && admitted_target == 4'b0001,
          "M0 internal ID and target");
    @(posedge ACLK); #1;
    check(target_awvalid && target_awid == 6'b00_1010,
          "registered target AW valid and widened ID");
    check(target_awaddr == 32'h0000_1238 && target_awlen == 8'h0F &&
          target_awsize == 3'h3 && target_awburst == 2'b01,
          "target address burst fields captured");
    check(target_awlock == 1'b0 && target_awcache == 4'h5 &&
          target_awprot == 3'h2 && target_awqos == 4'h8 &&
          target_awregion == 4'h1,
          "target attributes captured unchanged");

    // Reset while the target slot is valid. Reset clears the admitted token
    // and the scheduler state; the still-present manager request may be
    // admitted again only after reset release.
    ARESETn = 1'b0; #1;
    check(!target_awvalid && !aw_admit_fire && manager_awready == 3'b000,
          "reset clears valid and admission");
    ARESETn = 1'b1;
    @(posedge ACLK); #1;
    check(manager_awready == 3'b001 && manager_aw_fire == 3'b001,
          "M0 can be admitted after reset release");
    @(posedge ACLK); #1;
    check(target_awvalid && target_awid == 6'b00_1010,
          "M0 is recaptured after reset");

    // Target stall: manager-side inputs change, registered target payload does not.
    manager_awid[0] = 4'h1; manager_awaddr[0] = 32'hDEAD_BEEF;
    manager_awlen[0] = 8'h02; manager_awqos[0] = 4'hF;
    manager_awvalid = 3'b111; request_legal = 3'b111;
    target_match = 3'b111; outstanding_allowed = 3'b111;
    repeat (3) begin
      @(posedge ACLK); #1;
      check(target_awvalid && target_awid == 6'b00_1010 &&
            target_awaddr == 32'h0000_1238 && target_awlen == 8'h0F,
            "target payload stable while stalled");
      check(target_awqos == 4'h8 && target_awregion == 4'h1,
            "target attributes stable while stalled");
    end

    // Target consumption clears the slot; D032 forbids same-cycle drain/refill.
    target_awready = 1'b1;
    #1;
    check(target_aw_fire && manager_awready == 3'b000,
          "target drains while manager admission remains blocked");
    @(posedge ACLK); #1;
    check(!target_awvalid && manager_awready == 3'b010 && manager_aw_fire == 3'b010,
          "following cycle permits the held M1 admission after drain");
    @(posedge ACLK); #1;
    check(target_awvalid && target_awid == 6'b01_0000,
          "following-cycle admission fills the slot");

    // Empty the prior slot before the remaining blocker checks.
    target_awready = 1'b1;
    @(posedge ACLK); #1;
    check(!target_awvalid, "prior slot drains before reset scenarios");
    clear_inputs();

    // Owner, legality and outstanding blockers suppress manager READY.
    manager_awvalid = 3'b111; request_legal = 3'b111;
    target_match = 3'b111; outstanding_allowed = 3'b111;
    owner_active[1] = 1'b1; owner_target_m1 = 4'b0001;
    #1; check(manager_awready == 3'b000, "target owner blocks all manager READY");
    owner_active = 3'b000; owner_target_m1 = 4'b0000;
    request_legal[0] = 1'b0; outstanding_allowed[1] = 1'b0; target_match[2] = 1'b0;
    #1; check(manager_awready == 3'b000, "individual eligibility blockers suppress READY");

    $display("PASS axi_aw_target_path_tb checks=%0d", checks);
    $finish;
  end

  // Separate S3 instance: a legal unmapped request is admitted and held like
  // any other supported address. No DECERR endpoint exists in this task.
  logic [2:0] s3_valid = 3'b001, s3_legal = 3'b001, s3_match = 3'b001;
  logic [2:0] s3_allowed = 3'b001, s3_mready;
  logic s3_ready = 1'b0;
  logic s3_admit, s3_tvalid;
  logic [2:0][3:0] s3_id = '{4'hC, 4'h0, 4'h0};
  logic [2:0][31:0] s3_addr = '{32'h3000_0008, 32'h0, 32'h0};
  logic [2:0][7:0] s3_len = '{8'h0, 8'h0, 8'h0};
  logic [2:0][2:0] s3_size = '{3'h3, 3'h0, 3'h0};
  logic [2:0][1:0] s3_burst = '{2'b01, 2'b0, 2'b0};
  logic [2:0] s3_lock = 3'b000;
  logic [2:0][3:0] s3_cache = '{4'h9, 4'h0, 4'h0};
  logic [2:0][2:0] s3_prot = '{3'h4, 3'h0, 3'h0};
  logic [2:0][3:0] s3_qos = '{4'h7, 4'h0, 4'h0};
  logic [2:0][3:0] s3_region = '{4'h3, 4'h0, 4'h0};
  logic [2:0] s3_fire;
  axi_aw_target_path_a #(.TARGET_INDEX(3)) s3 (
    .ACLK, .ARESETn, .manager_awvalid(s3_valid), .manager_awid(s3_id),
    .manager_awaddr(s3_addr), .manager_awlen(s3_len), .manager_awsize(s3_size),
    .manager_awburst(s3_burst), .manager_awlock(s3_lock), .manager_awcache(s3_cache),
    .manager_awprot(s3_prot), .manager_awqos(s3_qos), .manager_awregion(s3_region),
    .request_legal(s3_legal), .target_match(s3_match),
    .outstanding_allowed(s3_allowed), .owner_active(3'b000),
    .owner_target_m0(4'b0), .owner_target_m1(4'b0), .owner_target_m2(4'b0),
    .target_awready(s3_ready), .manager_awready(s3_mready),
    .manager_aw_fire(s3_fire), .aw_admit_fire(s3_admit), .admitted_manager(),
    .admitted_awid(), .admitted_internal_id(), .admitted_target(), .admitted_awlen(),
    .target_awvalid(s3_tvalid), .target_awid(), .target_awaddr(), .target_awlen(),
    .target_awsize(), .target_awburst(), .target_awlock(), .target_awcache(),
    .target_awprot(), .target_awqos(), .target_awregion(), .target_aw_fire()
  );
endmodule
