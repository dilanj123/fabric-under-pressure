// One manager, one AXI ordering direction. State is allocated on an explicit
// accepted-request event and released on an explicit final-response event.
// Allocation eligibility is intentionally derived from registered pre-state.
module axi_outstanding_tracker (
  input  logic        ACLK,
  input  logic        ARESETn,

  input  logic        allocate_fire,
  input  logic [3:0]  allocate_id,
  input  logic [3:0]  allocate_target,
  input  logic [7:0]  allocate_len,

  input  logic        complete_fire,
  input  logic [3:0]  complete_id,

  input  logic [3:0]  lookup_id,

  output logic        allocate_allowed,
  output logic        complete_known,
  output logic        allocate_violation,
  output logic        complete_violation,
  output logic [15:0] busy_bitmap,
  output logic [2:0]  outstanding_count,
  output logic        lookup_busy,
  output logic [3:0]  lookup_target,
  output logic [7:0]  lookup_len
);
  logic [3:0] target_table [0:15];
  logic [7:0] len_table [0:15];
  logic allocate_do;
  logic complete_do;
  integer i;

  always_comb begin
    allocate_allowed = 1'b0;
    complete_known = 1'b0;
    allocate_violation = 1'b0;
    complete_violation = 1'b0;
    lookup_busy = 1'b0;
    lookup_target = 4'b0;
    lookup_len = 8'b0;

    if (ARESETn) begin
      allocate_allowed = (outstanding_count < 3'd4) &&
                         !busy_bitmap[allocate_id];
      complete_known = busy_bitmap[complete_id];
      allocate_violation = allocate_fire && !allocate_allowed;
      complete_violation = complete_fire && !complete_known;
      lookup_busy = busy_bitmap[lookup_id];
      lookup_target = target_table[lookup_id];
      lookup_len = len_table[lookup_id];
    end
  end

  always_comb begin
    allocate_do = allocate_fire && allocate_allowed;
    complete_do = complete_fire && complete_known;
  end

  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      busy_bitmap <= 16'b0;
      outstanding_count <= 3'b0;
      for (i = 0; i < 16; i = i + 1) begin
        target_table[i] <= 4'b0;
        len_table[i] <= 8'b0;
      end
    end else begin
      if (complete_do) begin
        busy_bitmap[complete_id] <= 1'b0;
        target_table[complete_id] <= 4'b0;
        len_table[complete_id] <= 8'b0;
      end

      if (allocate_do) begin
        busy_bitmap[allocate_id] <= 1'b1;
        target_table[allocate_id] <= allocate_target;
        len_table[allocate_id] <= allocate_len;
      end

      case ({allocate_do, complete_do})
        2'b10: outstanding_count <= outstanding_count + 3'd1;
        2'b01: outstanding_count <= outstanding_count - 3'd1;
        default: outstanding_count <= outstanding_count;
      endcase
    end
  end
endmodule
