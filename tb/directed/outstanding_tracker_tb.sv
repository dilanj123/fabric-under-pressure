module outstanding_tracker_tb;
  logic ACLK;
  logic ARESETn;
  logic allocate_fire;
  logic [3:0] allocate_id;
  logic [3:0] allocate_target;
  logic [7:0] allocate_len;
  logic complete_fire;
  logic [3:0] complete_id;
  logic [3:0] lookup_id;
  logic allocate_allowed, complete_known;
  logic allocate_violation, complete_violation;
  logic [15:0] busy_bitmap;
  logic [2:0] outstanding_count;
  logic lookup_busy;
  logic [3:0] lookup_target;
  logic [7:0] lookup_len;

  logic w_allocate_fire, w_complete_fire;
  logic [3:0] w_allocate_id, w_complete_id;
  logic w_allocate_allowed, w_complete_known;
  logic w_allocate_violation, w_complete_violation;
  logic [15:0] w_busy_bitmap;
  logic [2:0] w_outstanding_count;
  logic w_lookup_busy;
  logic [3:0] w_lookup_target;
  logic [7:0] w_lookup_len;

  integer checks;

  axi_outstanding_tracker dut (
    .ACLK(ACLK), .ARESETn(ARESETn),
    .allocate_fire(allocate_fire), .allocate_id(allocate_id),
    .allocate_target(allocate_target), .allocate_len(allocate_len),
    .complete_fire(complete_fire), .complete_id(complete_id),
    .lookup_id(lookup_id), .allocate_allowed(allocate_allowed),
    .complete_known(complete_known), .allocate_violation(allocate_violation),
    .complete_violation(complete_violation), .busy_bitmap(busy_bitmap),
    .outstanding_count(outstanding_count), .lookup_busy(lookup_busy),
    .lookup_target(lookup_target), .lookup_len(lookup_len)
  );

  axi_outstanding_tracker write_dut (
    .ACLK(ACLK), .ARESETn(ARESETn),
    .allocate_fire(w_allocate_fire), .allocate_id(w_allocate_id),
    .allocate_target(4'hb), .allocate_len(8'hb0),
    .complete_fire(w_complete_fire), .complete_id(w_complete_id),
    .lookup_id(4'd9), .allocate_allowed(w_allocate_allowed),
    .complete_known(w_complete_known),
    .allocate_violation(w_allocate_violation),
    .complete_violation(w_complete_violation),
    .busy_bitmap(w_busy_bitmap), .outstanding_count(w_outstanding_count),
    .lookup_busy(w_lookup_busy), .lookup_target(w_lookup_target),
    .lookup_len(w_lookup_len)
  );

  initial ACLK = 1'b0;
  always #5 ACLK = ~ACLK;

  task automatic fail(input string name);
    begin
      $fatal(1, "FAIL %s reset=%b alloc_id=%h complete_id=%h count=%0d bitmap=%h alloc_allowed=%b complete_known=%b alloc_violation=%b complete_violation=%b lookup_busy=%b target=%h len=%h",
             name, ARESETn, allocate_id, complete_id, outstanding_count, busy_bitmap, allocate_allowed,
             complete_known, allocate_violation, complete_violation,
             lookup_busy, lookup_target, lookup_len);
    end
  endtask

  task automatic check_consistency(input string name);
    integer bit_count;
    integer j;
    begin
      bit_count = 0;
      for (j = 0; j < 16; j = j + 1)
        bit_count = bit_count + busy_bitmap[j];
      if (outstanding_count !== bit_count[2:0]) fail(name);
      if (outstanding_count > 3'd4) fail(name);
      checks = checks + 1;
    end
  endtask

  task automatic set_idle;
    begin
      allocate_fire = 1'b0;
      complete_fire = 1'b0;
      allocate_id = 4'b0;
      complete_id = 4'b0;
      allocate_target = 4'b0;
      allocate_len = 8'b0;
      lookup_id = 4'b0;
    end
  endtask

  task automatic allocate(input logic [3:0] id, input logic [3:0] target,
                           input logic [7:0] len);
    begin
      @(negedge ACLK);
      allocate_id = id;
      allocate_target = target;
      allocate_len = len;
      allocate_fire = 1'b1;
      #1;
      if (!allocate_allowed) fail("expected allocation allowed");
      @(posedge ACLK);
      #1;
      allocate_fire = 1'b0;
      check_consistency("after allocation");
    end
  endtask

  task automatic complete(input logic [3:0] id);
    begin
      @(negedge ACLK);
      complete_id = id;
      complete_fire = 1'b1;
      @(posedge ACLK);
      #1;
      complete_fire = 1'b0;
      check_consistency("after completion");
    end
  endtask

  integer id;
  integer k;
  initial begin
    checks = 0;
    ARESETn = 1'b0;
    set_idle();
    w_allocate_fire = 1'b0;
    w_complete_fire = 1'b0;
    w_allocate_id = 4'b0;
    w_complete_id = 4'b0;
    #2;
    if (busy_bitmap !== 16'b0 || outstanding_count !== 3'b0) fail("reset");
    ARESETn = 1'b1;
    @(negedge ACLK);
    check_consistency("empty");

    allocate(4'd3, 4'ha, 8'd3);
    lookup_id = 4'd3; #1;
    if (!lookup_busy || lookup_target !== 4'ha || lookup_len !== 8'd3) fail("metadata lookup");

    // Complete and reallocate the same ID on the following cycle.
    complete(4'd3);
    allocate(4'd3, 4'hc, 8'd7);
    complete(4'd3);

    // Fill all four entries and reject a fifth allocation.
    for (id = 0; id < 4; id = id + 1)
      allocate(id[3:0], id[3:0], 8'(id + 1));
    @(negedge ACLK);
    allocate_id = 4'd4;
    allocate_target = 4'h4;
    allocate_len = 8'd4;
    allocate_fire = 1'b1;
    #1;
    if (allocate_allowed || !allocate_violation) fail("fifth allocation");
    @(posedge ACLK); #1; allocate_fire = 1'b0;
    check_consistency("rejected fifth allocation");

    // Duplicate ID is rejected without state corruption.
    @(negedge ACLK);
    allocate_id = 4'd2; allocate_target = 4'he; allocate_len = 8'hee;
    allocate_fire = 1'b1;
    #1;
    if (allocate_allowed || !allocate_violation) fail("duplicate allocation");
    @(posedge ACLK); #1; allocate_fire = 1'b0;
    check_consistency("rejected duplicate allocation");

    // Unknown completion is reported and cannot underflow.
    @(negedge ACLK);
    complete_id = 4'd15; complete_fire = 1'b1;
    #1;
    if (complete_known || !complete_violation) fail("unknown completion");
    @(posedge ACLK); #1; complete_fire = 1'b0;
    check_consistency("rejected unknown completion");

    // Same-cycle completion and same-ID allocation: allocation is blocked.
    @(negedge ACLK);
    complete_id = 4'd1; complete_fire = 1'b1;
    allocate_id = 4'd1; allocate_target = 4'hf; allocate_len = 8'hff;
    allocate_fire = 1'b1;
    #1;
    if (allocate_allowed || !allocate_violation || !complete_known) fail("same-ID same-cycle policy");
    @(posedge ACLK); #1; allocate_fire = 1'b0; complete_fire = 1'b0;
    check_consistency("same-ID same-cycle result");
    allocate(4'd1, 4'hf, 8'hff);

    // Full count: completion cannot recycle capacity in the same cycle.
    @(negedge ACLK);
    complete_id = 4'd0; complete_fire = 1'b1;
    allocate_id = 4'd4; allocate_target = 4'h4; allocate_len = 8'd4;
    allocate_fire = 1'b1;
    #1;
    if (allocate_allowed || !allocate_violation) fail("full-count pre-state policy");
    @(posedge ACLK); #1; complete_fire = 1'b0; allocate_fire = 1'b0;
    check_consistency("full-count same-cycle result");
    allocate(4'd4, 4'h4, 8'd4);

    // Reset with four active entries clears state and metadata.
    ARESETn = 1'b0; #1;
    if (busy_bitmap !== 16'b0 || outstanding_count !== 3'b0) fail("active reset");
    ARESETn = 1'b1;

    // Read/write ordering domains are independent.
    @(negedge ACLK);
    allocate_id = 4'd9; allocate_target = 4'h9; allocate_len = 8'd9;
    allocate_fire = 1'b1; w_allocate_id = 4'd9; w_allocate_fire = 1'b1;
    @(posedge ACLK); #1;
    allocate_fire = 1'b0; w_allocate_fire = 1'b0;
    if (!busy_bitmap[9] || !w_busy_bitmap[9] || outstanding_count !== 3'd1 || w_outstanding_count !== 3'd1)
      fail("read/write independence allocation");
    checks = checks + 1;
    @(negedge ACLK);
    complete_id = 4'd9; complete_fire = 1'b1;
    @(posedge ACLK); #1; complete_fire = 1'b0;
    if (busy_bitmap[9] || !w_busy_bitmap[9]) fail("read/write independence completion");
    checks = checks + 1;
    @(negedge ACLK); w_complete_id = 4'd9; w_complete_fire = 1'b1;
    @(posedge ACLK); #1; w_complete_fire = 1'b0;
    if (w_busy_bitmap[9]) fail("write completion independence");
    checks = checks + 1;

    $display("PASS outstanding_tracker_tb checks=%0d", checks);
    $finish;
  end
endmodule
