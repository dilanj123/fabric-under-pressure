module axi_write_owner_tb;
  logic ACLK = 1'b0;
  logic ARESETn = 1'b0;
  always #5 ACLK = ~ACLK;

  logic allocate_fire, w_fire, wlast;
  logic [3:0] allocate_target, allocate_id;
  logic [5:0] allocate_internal_id;
  logic [7:0] allocate_len;
  logic allocate_allowed, active;
  logic [3:0] owner_target, owner_id;
  logic [5:0] owner_internal_id;
  logic [4:0] beats_remaining;
  logic expected_wlast, allocate_violation;
  logic w_without_owner_violation, wlast_mismatch_violation;
  integer checks = 0;
  bit pre_violation;
  bit ownerless_seen;
  bit wlast_seen;

  axi_write_owner dut (.*);

  task automatic check(input bit condition, input string message);
    checks = checks + 1;
    if (!condition) begin
      $display("FAIL %s", message);
      $fatal(1);
    end
  endtask

  task automatic idle_cycles(input integer count);
    repeat (count) @(posedge ACLK);
  endtask

  task automatic allocate(input [7:0] len, input [3:0] target, input [3:0] id, input [5:0] internal_id);
    allocate_len = len; allocate_target = target; allocate_id = id;
    allocate_internal_id = internal_id; allocate_fire = 1'b1;
    @(posedge ACLK); #1; allocate_fire = 1'b0;
  endtask

  task automatic wbeat(input bit last);
    @(negedge ACLK); wlast = last; w_fire = 1'b1;
    @(posedge ACLK); #1;
    ownerless_seen = w_without_owner_violation; wlast_seen = wlast_mismatch_violation;
    w_fire = 1'b0;
  endtask

  initial begin
    ARESETn = 1'b1; #1; ARESETn = 1'b0; #1;
    allocate_fire = 0; w_fire = 0; wlast = 0;
    allocate_target = 0; allocate_id = 0; allocate_internal_id = 0; allocate_len = 0;
    #1;
    check(!active && beats_remaining == 0, "reset state");
    ARESETn = 1'b1; #1;
    check(allocate_allowed, "allocation permitted after reset");

    // W before AW is diagnostic-only and cannot create state.
    wbeat(1'b1);
    check(ownerless_seen && !active && beats_remaining == 0, "W without owner");

    // Same-cycle allocate/W uses registered pre-state: W cannot consume new owner.
    allocate_len = 0; allocate_target = 4'h3; allocate_id = 4'h5; allocate_internal_id = 6'h21;
    allocate_fire = 1'b1; w_fire = 1'b1; wlast = 1'b1;
    #1; pre_violation = w_without_owner_violation;
    @(posedge ACLK); #1; allocate_fire = 0; w_fire = 0;
    check(active && beats_remaining == 1 && pre_violation, "same-cycle allocate/W pre-state");
    check(owner_target == 4'h3 && owner_id == 4'h5 && owner_internal_id == 6'h21, "metadata capture");
    wbeat(1'b1);
    check(!active && beats_remaining == 0, "single-beat completion without B");

    // Multi-beat allocation, metadata stability and pre-first/mid/final stalls.
    allocate(8'd3, 4'h1, 4'h2, 6'h12);
    check(active && beats_remaining == 4 && !expected_wlast, "four-beat allocation");
    idle_cycles(2);
    check(active && beats_remaining == 4 && owner_target == 4'h1, "pre-first stall");
    wbeat(1'b0);
    check(beats_remaining == 3 && active && !expected_wlast, "first non-final beat");
    idle_cycles(2);
    check(beats_remaining == 3 && active, "mid-burst stall");
    // Early WLAST diagnoses but does not release ownership; beat is counted.
    wbeat(1'b1);
    check(wlast_seen && active && beats_remaining == 2, "early WLAST");
    wbeat(1'b0);
    check(beats_remaining == 1 && expected_wlast, "expected final beat reached");
    idle_cycles(2);
    check(active && beats_remaining == 1, "final-beat stall");
    // Missing WLAST diagnoses and holds the counter at one.
    wbeat(1'b0);
    check(wlast_seen && active && beats_remaining == 1, "missing WLAST");
    wbeat(1'b1);
    check(!active && beats_remaining == 0, "correct WLAST release");

    // Allocation while active is rejected and cannot overwrite metadata.
    allocate(8'd1, 4'h7, 4'h7, 6'h37);
    allocate_len = 0; allocate_target = 4'hf; allocate_id = 4'hf; allocate_internal_id = 6'h3f; allocate_fire = 1;
    @(posedge ACLK); #1; allocate_fire = 0;
    check(allocate_violation && owner_target == 4'h7 && beats_remaining == 2, "allocation while active");
    wbeat(1'b0); wbeat(1'b1);
    check(!active, "second write release");

    // Same-cycle final W/new AW is blocked; following-cycle allocation succeeds.
    allocate(8'd0, 4'h2, 4'h1, 6'h11);
    allocate_fire = 1; allocate_target = 4'h4; allocate_id = 4'h4; allocate_internal_id = 6'h24;
    w_fire = 1; wlast = 1;
    #1; pre_violation = allocate_violation;
    @(posedge ACLK); #1; allocate_fire = 0; w_fire = 0;
    check(!active && pre_violation, "same-cycle final/reallocation block");
    @(posedge ACLK); #1;
    check(allocate_allowed, "following-cycle allocation permitted");
    allocate_len = 0; allocate_target = 4'h4; allocate_id = 4'h4; allocate_internal_id = 6'h24; allocate_fire = 1;
    @(posedge ACLK); #1; allocate_fire = 0;
    check(active && owner_target == 4'h4, "following-cycle reallocation");
    wbeat(1'b1);

    // Reset abandons active owner deterministically.
    allocate(8'd15, 4'h9, 4'h9, 6'h29);
    check(active && beats_remaining == 16, "sixteen-beat allocation");
    ARESETn = 0; #1;
    check(!active && beats_remaining == 0 && owner_target == 0, "reset while active");
    ARESETn = 1;

    $display("PASS axi_write_owner_tb checks=%0d", checks);
    $finish;
  end
endmodule
