module axi_write_state_bank_tb;
  localparam int M = 3;
  logic ACLK = 1'b0;
  logic ARESETn = 1'b0;
  always #5 ACLK = ~ACLK;

  logic [M-1:0][3:0] request_awid;
  logic [M-1:0] aw_admit_fire;
  logic [M-1:0][3:0] aw_admit_id;
  logic [M-1:0][5:0] aw_admit_internal_id;
  logic [M-1:0][3:0] aw_admit_target;
  logic [M-1:0][7:0] aw_admit_len;
  logic [M-1:0] w_fire, wlast, b_complete_fire;
  logic [M-1:0][3:0] b_complete_id;
  logic [M-1:0] outstanding_allowed;
  logic [M-1:0][15:0] busy_bitmap;
  logic [M-1:0][2:0] outstanding_count;
  logic [M-1:0] owner_active;
  logic [M-1:0][3:0] owner_target, owner_id;
  logic [M-1:0][5:0] owner_internal_id;
  logic [M-1:0][4:0] owner_beats_remaining;
  logic [M-1:0] owner_expected_wlast;
  logic [M-1:0] state_allowed, commit_fire, admission_state_violation;
  logic [M-1:0] outstanding_violation, owner_violation;
  integer checks = 0;

  axi_write_state_bank dut (
    .ACLK, .ARESETn, .request_awid, .aw_admit_fire, .aw_admit_id,
    .aw_admit_internal_id, .aw_admit_target, .aw_admit_len, .w_fire, .wlast,
    .b_complete_fire, .b_complete_id, .outstanding_allowed, .busy_bitmap,
    .outstanding_count, .owner_active, .owner_target, .owner_id,
    .owner_internal_id, .owner_beats_remaining, .owner_expected_wlast,
    .state_allowed, .commit_fire, .admission_state_violation,
    .outstanding_violation, .owner_violation
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

  task automatic clear_events;
    begin
      aw_admit_fire = '0;
      b_complete_fire = '0;
      w_fire = '0;
      wlast = '0;
    end
  endtask

  task automatic prepare_all;
    integer i;
    begin
      request_awid = '0;
      aw_admit_id = '0;
      aw_admit_internal_id = '0;
      aw_admit_target = '0;
      aw_admit_len = '0;
      b_complete_id = '0;
      clear_events();
      for (i = 0; i < M; i = i + 1) begin
        request_awid[i] = i[3:0];
        aw_admit_id[i] = i[3:0];
        aw_admit_internal_id[i] = {i[1:0], i[3:0]};
      end
    end
  endtask

  task automatic allocate_one(input integer manager, input logic [3:0] id,
                              input logic [3:0] target, input logic [7:0] len);
    begin
      aw_admit_id[manager] = id;
      aw_admit_internal_id[manager] = {manager[1:0], id};
      aw_admit_target[manager] = target;
      aw_admit_len[manager] = len;
      request_awid[manager] = id;
      aw_admit_fire[manager] = 1'b1;
      #1;
      check(commit_fire[manager], "valid admission commits atomically");
      @(posedge ACLK); #1;
      aw_admit_fire[manager] = 1'b0;
    end
  endtask

  initial begin
    prepare_all();
    repeat (2) @(posedge ACLK);
    ARESETn = 1'b1;
    #1;
    check(outstanding_count == '0 && owner_active == '0 && busy_bitmap == '0,
          "reset clears all managers");

    // One admission allocates both state elements exactly once.
    allocate_one(0, 4'h3, 4'h1, 8'd1);
    check(outstanding_count[0] == 3'd1 && busy_bitmap[0][3],
          "M0 outstanding entry allocated");
    check(owner_active[0] && owner_target[0] == 4'h1 && owner_id[0] == 4'h3 &&
          owner_internal_id[0] == 6'b00_0011 && owner_beats_remaining[0] == 5'd2,
          "M0 owner metadata allocated");
    check(outstanding_count[1] == '0 && outstanding_count[2] == '0 &&
          !owner_active[1] && !owner_active[2], "manager state is independent");

    // W completion releases owner only; B is still required for outstanding.
    w_fire[0] = 1'b1; wlast[0] = 1'b0; @(posedge ACLK); #1;
    check(owner_active[0] && owner_beats_remaining[0] == 5'd1,
          "non-final W beat retains owner");
    wlast[0] = 1'b1; @(posedge ACLK); #1; clear_events();
    check(!owner_active[0] && busy_bitmap[0][3] && outstanding_count[0] == 3'd1,
          "final W clears owner but not outstanding");
    check(!outstanding_allowed[0], "same ID remains blocked before B");

    // A different ID can be admitted after WLAST while B remains pending.
    allocate_one(0, 4'h4, 4'h2, 8'd0);
    check(outstanding_count[0] == 3'd2 && owner_active[0] && busy_bitmap[0][4],
          "different ID admitted after WLAST");
    w_fire[0] = 1'b1; wlast[0] = 1'b1; @(posedge ACLK); #1; clear_events();
    check(!owner_active[0] && outstanding_count[0] == 3'd2,
          "second owner completes independently");

    // Fill four outstanding writes while completing each W burst.
    allocate_one(0, 4'h5, 4'h0, 8'd0);
    w_fire[0] = 1'b1; wlast[0] = 1'b1; @(posedge ACLK); #1; clear_events();
    allocate_one(0, 4'h6, 4'h0, 8'd0);
    w_fire[0] = 1'b1; wlast[0] = 1'b1; @(posedge ACLK); #1; clear_events();
    check(outstanding_count[0] == 3'd4 && !owner_active[0],
          "four outstanding writes and free W owner");
    request_awid[0] = 4'h7; #1;
    check(!state_allowed[0] && !outstanding_allowed[0], "fifth write blocked");

    // Completion at count four does not recycle capacity in the same cycle.
    b_complete_id[0] = 4'h3; b_complete_fire[0] = 1'b1;
    aw_admit_id[0] = 4'h7; aw_admit_internal_id[0] = 6'b00_0111;
    aw_admit_target[0] = 4'h0; aw_admit_len[0] = 8'd0;
    aw_admit_fire[0] = 1'b1; #1;
    check(!commit_fire[0] && admission_state_violation[0],
          "same-cycle B completion does not provide AW credit");
    @(posedge ACLK); #1; clear_events();
    check(outstanding_count[0] == 3'd3 && !busy_bitmap[0][3],
          "B completion frees capacity on next state");
    check(state_allowed[0], "capacity is available following cycle");
    aw_admit_fire[0] = 1'b1; @(posedge ACLK); #1; aw_admit_fire[0] = 1'b0;
    check(outstanding_count[0] == 3'd4 && busy_bitmap[0][7],
          "following-cycle AW admission succeeds");

    // Invalid admission while the owner is active must not partially allocate.
    aw_admit_id[0] = 4'h8; aw_admit_internal_id[0] = 6'b00_1000;
    request_awid[0] = 4'h8; aw_admit_fire[0] = 1'b1; #1;
    check(!state_allowed[0] && admission_state_violation[0] && !commit_fire[0],
          "owner-unavailable admission is rejected atomically");
    @(posedge ACLK); #1; aw_admit_fire[0] = 1'b0;
    check(!busy_bitmap[0][8] && owner_id[0] == 4'h7,
          "invalid admission changes neither state component");

    // Independent simultaneous admissions for M1 and M2.
    clear_events();
    aw_admit_id[1] = 4'h9; aw_admit_internal_id[1] = 6'b01_1001;
    aw_admit_target[1] = 4'h1; aw_admit_len[1] = 8'd0;
    aw_admit_id[2] = 4'hA; aw_admit_internal_id[2] = 6'b10_1010;
    aw_admit_target[2] = 4'h2; aw_admit_len[2] = 8'd0;
    request_awid[1] = 4'h9; request_awid[2] = 4'hA;
    aw_admit_fire[1] = 1'b1; aw_admit_fire[2] = 1'b1; #1;
    check(commit_fire[1] && commit_fire[2] && !admission_state_violation[1] &&
          !admission_state_violation[2], "M1 and M2 admit independently");
    @(posedge ACLK); #1; aw_admit_fire[1] = 1'b0; aw_admit_fire[2] = 1'b0;
    check(outstanding_count[1] == 3'd1 && outstanding_count[2] == 3'd1 &&
          owner_active[1] && owner_active[2], "M1/M2 state populated");

    // Reset while populated clears every shared lane.
    ARESETn = 1'b0; #1;
    check(busy_bitmap == '0 && outstanding_count == '0 && owner_active == '0,
          "reset clears all shared write state");
    ARESETn = 1'b1;
    $display("PASS axi_write_state_bank_tb checks=%0d", checks);
    $finish;
  end
endmodule
