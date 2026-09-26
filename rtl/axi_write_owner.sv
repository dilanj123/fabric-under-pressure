// Registered per-manager context for the unfinished AXI4 W phase.
// AW legality, outstanding capacity and AW arbitration are upstream concerns.
module axi_write_owner (
  input  logic       ACLK,
  input  logic       ARESETn,

  input  logic       allocate_fire,
  input  logic [3:0] allocate_target,
  input  logic [3:0] allocate_id,
  input  logic [5:0] allocate_internal_id,
  input  logic [7:0] allocate_len,

  input  logic       w_fire,
  input  logic       wlast,

  output logic       allocate_allowed,
  output logic       active,
  output logic [3:0] owner_target,
  output logic [3:0] owner_id,
  output logic [5:0] owner_internal_id,
  output logic [4:0] beats_remaining,
  output logic       expected_wlast,

  output logic       allocate_violation,
  output logic       w_without_owner_violation,
  output logic       wlast_mismatch_violation
);
  logic active_q;
  logic [3:0] target_q;
  logic [3:0] id_q;
  logic [5:0] internal_id_q;
  logic [4:0] beats_q;

  always_comb begin
    active = active_q;
    owner_target = active_q ? target_q : 4'b0;
    owner_id = active_q ? id_q : 4'b0;
    owner_internal_id = active_q ? internal_id_q : 6'b0;
    beats_remaining = active_q ? beats_q : 5'b0;
    expected_wlast = active_q && (beats_q == 5'd1);

    allocate_allowed = ARESETn && !active_q;
    allocate_violation = ARESETn && allocate_fire && active_q;
    w_without_owner_violation = ARESETn && w_fire && !active_q;
    wlast_mismatch_violation =
      ARESETn && active_q && w_fire && (wlast != expected_wlast);
  end

  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      active_q <= 1'b0;
      target_q <= 4'b0;
      id_q <= 4'b0;
      internal_id_q <= 6'b0;
      beats_q <= 5'b0;
    end else if (allocate_fire && !active_q) begin
      active_q <= 1'b1;
      target_q <= allocate_target;
      id_q <= allocate_id;
      internal_id_q <= allocate_internal_id;
      beats_q <= (allocate_len > 8'd15) ? 5'd16 : ({1'b0, allocate_len[3:0]} + 5'd1);
    end else if (active_q && w_fire) begin
      if ((beats_q == 5'd1) && wlast) begin
        active_q <= 1'b0;
        target_q <= 4'b0;
        id_q <= 4'b0;
        internal_id_q <= 6'b0;
        beats_q <= 5'b0;
      end else if (beats_q > 5'd1) begin
        // Defensive accounting: an early WLAST still consumes that beat;
        // ownership is retained until a correct final WLAST arrives.
        beats_q <= beats_q - 5'd1;
      end
      // A missing WLAST on the expected final beat deliberately holds 1.
    end
  end
endmodule
