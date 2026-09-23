module outstanding_tracker_formal(input logic ACLK);
  (* anyseq *) logic ARESETn;
  (* anyseq *) logic allocate_fire;
  (* anyseq *) logic [3:0] allocate_id;
  (* anyseq *) logic [3:0] allocate_target;
  (* anyseq *) logic [7:0] allocate_len;
  (* anyseq *) logic complete_fire;
  (* anyseq *) logic [3:0] complete_id;
  (* anyseq *) logic [3:0] lookup_id;

  logic allocate_allowed, complete_known;
  logic allocate_violation, complete_violation;
  logic [15:0] busy_bitmap;
  logic [2:0] outstanding_count;
  logic lookup_busy;
  logic [3:0] lookup_target;
  logic [7:0] lookup_len;

  logic [15:0] ref_busy;
  logic [2:0] ref_count;
  logic [3:0] ref_target [0:15];
  logic [7:0] ref_len [0:15];
  logic alloc_do;
  logic complete_do;
  logic saw_full;
  integer i;
  integer bit_count;

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

  initial assume (!ARESETn);
  initial saw_full = 1'b0;

  always @* begin
    alloc_do = allocate_fire && (ref_count < 3'd4) && !ref_busy[allocate_id];
    complete_do = complete_fire && ref_busy[complete_id];
  end

  always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      ref_busy <= 16'b0;
      ref_count <= 3'b0;
      for (i = 0; i < 16; i = i + 1) begin
        ref_target[i] <= 4'b0;
        ref_len[i] <= 8'b0;
      end
    end else begin
      if (complete_do) begin
        ref_busy[complete_id] <= 1'b0;
        ref_target[complete_id] <= 4'b0;
        ref_len[complete_id] <= 8'b0;
      end
      if (alloc_do) begin
        ref_busy[allocate_id] <= 1'b1;
        ref_target[allocate_id] <= allocate_target;
        ref_len[allocate_id] <= allocate_len;
      end
      case ({alloc_do, complete_do})
        2'b10: ref_count <= ref_count + 3'd1;
        2'b01: ref_count <= ref_count - 3'd1;
        default: ref_count <= ref_count;
      endcase
    end
  end

  // Compare pre-state before applying the DUT/reference nonblocking updates.
  // Keeping these checks on ACLK avoids making the asynchronous reset event
  // itself an assertion trigger in the formal frontend.
  always @(posedge ACLK) begin
    if (ARESETn) begin
      assert (busy_bitmap == ref_busy);
      assert (outstanding_count == ref_count);
      assert (allocate_allowed == ((ref_count < 3'd4) && !ref_busy[allocate_id]));
      assert (complete_known == ref_busy[complete_id]);
      assert (allocate_violation == (allocate_fire && !allocate_allowed));
      assert (complete_violation == (complete_fire && !complete_known));
      assert (lookup_busy == ref_busy[lookup_id]);
      assert (lookup_target == ref_target[lookup_id]);
      assert (lookup_len == ref_len[lookup_id]);
    end
  end

  always @* begin
    bit_count = 0;
    for (i = 0; i < 16; i = i + 1)
      bit_count = bit_count + busy_bitmap[i];
    assert (outstanding_count <= 3'd4);
    assert (outstanding_count == bit_count[2:0]);
    if (!ARESETn) begin
      assert (busy_bitmap == 16'b0);
      assert (outstanding_count == 3'b0);
      assert (!allocate_violation && !complete_violation);
    end

    cover (outstanding_count == 3'd0);
    cover (outstanding_count == 3'd1);
    cover (outstanding_count == 3'd2);
    cover (outstanding_count == 3'd3);
    cover (outstanding_count == 3'd4);
    cover (allocate_violation);
    cover (complete_violation);
    cover (alloc_do && complete_do && allocate_id != complete_id);
    cover (allocate_fire && complete_fire && allocate_id == complete_id && ref_busy[allocate_id]);
    cover (outstanding_count == 3'd4 && complete_fire && complete_do && allocate_fire);
    cover (saw_full && !ARESETn);
  end

  always @(posedge ACLK) begin
    if (ref_count == 3'd4)
      saw_full <= 1'b1;
  end
endmodule
