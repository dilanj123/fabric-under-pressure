module axi_aw_target_scheduler_tb;
  logic ACLK = 1'b0;
  logic ARESETn = 1'b0;
  always #5 ACLK = ~ACLK;

  logic [2:0] request_present, request_legal, target_match;
  logic [2:0] outstanding_allowed, owner_active;
  logic [3:0] owner_target_m0, owner_target_m1, owner_target_m2;
  logic target_ready;
  logic [2:0] raw_eligible, grant;
  logic target_owner_busy, grant_valid, aw_accept_fire;
  logic [1:0] selected_manager;
  integer checks = 0;

  axi_aw_target_scheduler_a #(.TARGET_INDEX(0)) dut (
    .ACLK, .ARESETn, .request_present, .request_legal, .target_match,
    .outstanding_allowed, .owner_active, .owner_target_m0, .owner_target_m1,
    .owner_target_m2, .target_ready, .raw_eligible, .target_owner_busy,
    .grant, .grant_valid, .selected_manager, .aw_accept_fire
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

  task automatic settle;
    begin
      #1;
    end
  endtask

  task automatic clear_inputs;
    begin
      request_present = 3'b000;
      request_legal = 3'b000;
      target_match = 3'b000;
      outstanding_allowed = 3'b000;
      owner_active = 3'b000;
      owner_target_m0 = 4'b0000;
      owner_target_m1 = 4'b0000;
      owner_target_m2 = 4'b0000;
      target_ready = 1'b0;
    end
  endtask

  task automatic make_valid(input logic [2:0] mask);
    begin
      request_present = mask;
      request_legal = mask;
      target_match = mask;
      outstanding_allowed = mask;
    end
  endtask

  initial begin
    clear_inputs();
    repeat (2) @(posedge ACLK);
    ARESETn = 1'b1;
    @(posedge ACLK);

    // Eligibility truth table, including the legal S3/unmapped case.
    make_valid(3'b111);
    settle();
    check(raw_eligible == 3'b111, "all valid requests eligible");
    request_present[0] = 1'b0; settle();
    check(!raw_eligible[0] && raw_eligible[1] && raw_eligible[2], "presence blocker");
    request_present[0] = 1'b1; request_legal[0] = 1'b0; settle();
    check(!raw_eligible[0], "legality blocker");
    request_legal[0] = 1'b1; target_match[0] = 1'b0; settle();
    check(!raw_eligible[0], "target blocker");
    target_match[0] = 1'b1; outstanding_allowed[0] = 1'b0; settle();
    check(!raw_eligible[0], "outstanding blocker");
    outstanding_allowed[0] = 1'b1; owner_active[0] = 1'b1; settle();
    check(!raw_eligible[0] && raw_eligible[1] && raw_eligible[2], "manager owner blocker");
    owner_active[0] = 1'b0; owner_active[1] = 1'b1; owner_target_m1 = 4'b0001; settle();
    check(target_owner_busy && raw_eligible == 3'b000, "target owner blocker");
    owner_active[1] = 1'b0; owner_target_m1 = 4'b0000;
    owner_active[0] = 1'b1; owner_target_m0 = 4'b0001; settle();
    check(target_owner_busy && raw_eligible == 3'b000, "M0 target owner blocker");
    owner_active[0] = 1'b0; owner_target_m0 = 4'b0000;
    owner_active[2] = 1'b1; owner_target_m2 = 4'b0001; settle();
    check(target_owner_busy && raw_eligible == 3'b000, "M2 target owner blocker");
    owner_active[2] = 1'b0; owner_target_m2 = 4'b0000;
    owner_target_m1 = 4'b0010; settle();
    check(!target_owner_busy && raw_eligible == 3'b111, "different target owner does not block S0");

    // RR composition and target-ready stall.
    clear_inputs(); make_valid(3'b011); target_ready = 1'b0;
    @(posedge ACLK); settle();
    check(grant_valid && grant == 3'b001 && !aw_accept_fire, "RR selects M0 and stalls");
    make_valid(3'b111); repeat (3) @(posedge ACLK); settle();
    check(grant == 3'b001 && grant_valid, "held winner is stable while stalled");
    target_ready = 1'b1; settle();
    check(aw_accept_fire, "accepted AW when target becomes ready");
    @(posedge ACLK); settle();
    check(!grant_valid, "D031 suppresses successor after accepted AW");

    // Registered owner state blocks the target after acceptance, then resume
    // from the advanced RR pointer after ownership clears.
    owner_active[0] = 1'b1; owner_target_m0 = 4'b0001; settle();
    check(target_owner_busy && raw_eligible == 3'b000 && !aw_accept_fire,
          "owner blocks all AW scheduling");
    repeat (2) @(posedge ACLK);
    owner_active[0] = 1'b0; owner_target_m0 = 4'b0000; target_ready = 1'b0;
    settle();
    @(posedge ACLK); settle();
    check(grant == 3'b010 && grant_valid, "resume uses advanced RR pointer and selects M1");
    target_ready = 1'b1; settle();
    check(aw_accept_fire && grant == 3'b010, "resumed M1 grant accepts");

    // S3 configuration is checked by a second instance below through the same
    // legal/unmapped request facts.
    $display("PASS axi_aw_target_scheduler_tb checks=%0d", checks);
    $finish;
  end

  logic s3_busy;
  logic [2:0] s3_raw;
  logic s1_busy;
  logic [2:0] s1_raw;
  axi_aw_target_scheduler_a #(.TARGET_INDEX(3)) s3 (
    .ACLK, .ARESETn, .request_present(3'b001), .request_legal(3'b001),
    .target_match(3'b001), .outstanding_allowed(3'b001),
    .owner_active(3'b000), .owner_target_m0(4'b0000),
    .owner_target_m1(4'b0000), .owner_target_m2(4'b0000),
    .target_ready(1'b0), .raw_eligible(s3_raw), .target_owner_busy(s3_busy),
    .grant(), .grant_valid(), .selected_manager(), .aw_accept_fire()
  );
  axi_aw_target_scheduler_a #(.TARGET_INDEX(1)) s1 (
    .ACLK, .ARESETn, .request_present(3'b010), .request_legal(3'b010),
    .target_match(3'b010), .outstanding_allowed(3'b010),
    .owner_active(3'b001), .owner_target_m0(4'b0001),
    .owner_target_m1(4'b0000), .owner_target_m2(4'b0000),
    .target_ready(1'b0), .raw_eligible(s1_raw), .target_owner_busy(s1_busy),
    .grant(), .grant_valid(), .selected_manager(), .aw_accept_fire()
  );
  always @(posedge ACLK) if (ARESETn) begin
    #1;
    check(!s3_busy && s3_raw == 3'b001, "S3 owner-free legal request remains eligible context");
    check(!s1_busy && s1_raw == 3'b010, "different target remains schedulable while S0 is owned");
  end
endmodule
