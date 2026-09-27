// Registered B response return path for four logical targets and three managers.
// Target-side B admission fills a manager slot; manager-side B handshake is
// the only write-completion event.
module axi_b_response_router (
  input  logic       ACLK,
  input  logic       ARESETn,

  input  logic [3:0]       target_bvalid,
  input  logic [3:0][5:0] target_bid,
  input  logic [3:0][1:0] target_bresp,
  output logic [3:0]       target_bready,
  output logic [3:0]       target_b_fire,

  input  logic [2:0][15:0] busy_bitmap,
  output logic [2:0]       manager_bvalid,
  output logic [2:0][3:0]  manager_bid,
  output logic [2:0][1:0]  manager_bresp,
  input  logic [2:0]       manager_bready,
  output logic [2:0]       manager_b_fire,

  output logic [2:0]       b_complete_fire,
  output logic [2:0][3:0]  b_complete_id,

  output logic [3:0]       invalid_manager_violation,
  output logic [3:0]       nonbusy_id_violation,
  output logic [2:0]       slot_valid,
  output logic [2:0][1:0]  slot_source_target
);
  logic [2:0][3:0] candidate_request;
  logic [2:0][3:0] arb_grant;
  logic [2:0] arb_grant_valid;
  logic [2:0][1:0] arb_selected;
  logic [2:0] arb_ready;
  logic [2:0] slot_can_accept;
  logic [2:0] response_admit_fire;
  logic [3:0] validated_response;
  logic [2:0][3:0] slot_bid_q;
  logic [2:0][1:0] slot_bresp_q;
  logic [2:0][1:0] slot_source_q;
  integer response_m, comb_m, comb_t, seq_m;

  function automatic logic busy_for(
      input logic [1:0] manager_index,
      input logic [3:0] id
  );
    begin
      case (manager_index)
        2'b00: busy_for = (((busy_bitmap[0] >> id) & 16'h0001) != 16'b0);
        2'b01: busy_for = (((busy_bitmap[1] >> id) & 16'h0001) != 16'b0);
        2'b10: busy_for = (((busy_bitmap[2] >> id) & 16'h0001) != 16'b0);
        default: busy_for = 1'b0;
      endcase
    end
  endfunction

  function automatic logic [1:0] manager_for(input integer target_index);
    begin
      case (target_index)
        0: manager_for = target_bid[0][5:4];
        1: manager_for = target_bid[1][5:4];
        2: manager_for = target_bid[2][5:4];
        default: manager_for = target_bid[3][5:4];
      endcase
    end
  endfunction

  function automatic logic [3:0] id_for(input integer target_index);
    begin
      case (target_index)
        0: id_for = target_bid[0][3:0];
        1: id_for = target_bid[1][3:0];
        2: id_for = target_bid[2][3:0];
        default: id_for = target_bid[3][3:0];
      endcase
    end
  endfunction

  always_comb begin
    response_admit_fire = 3'b000;
    for (response_m = 0; response_m < 3; response_m = response_m + 1)
      response_admit_fire[response_m] = |(arb_grant[response_m] & validated_response);
  end

  always_comb begin
    candidate_request = '0;
    validated_response = 4'b0;
    invalid_manager_violation = 4'b0;
    nonbusy_id_violation = 4'b0;

    for (comb_t = 0; comb_t < 4; comb_t = comb_t + 1) begin
      if (target_bvalid[comb_t]) begin
        case (manager_for(comb_t))
          2'b00: begin
            if (!busy_for(2'b00, id_for(comb_t)))
              nonbusy_id_violation[comb_t] = 1'b1;
            else begin
              candidate_request[0][comb_t] = 1'b1;
              validated_response[comb_t] = 1'b1;
            end
          end
          2'b01: begin
            if (!busy_for(2'b01, id_for(comb_t)))
              nonbusy_id_violation[comb_t] = 1'b1;
            else begin
              candidate_request[1][comb_t] = 1'b1;
              validated_response[comb_t] = 1'b1;
            end
          end
          2'b10: begin
            if (!busy_for(2'b10, id_for(comb_t)))
              nonbusy_id_violation[comb_t] = 1'b1;
            else begin
              candidate_request[2][comb_t] = 1'b1;
              validated_response[comb_t] = 1'b1;
            end
          end
          default: invalid_manager_violation[comb_t] = 1'b1;
        endcase
      end
    end

    for (comb_m = 0; comb_m < 3; comb_m = comb_m + 1) begin
      slot_can_accept[comb_m] = ARESETn && !slot_valid[comb_m];
      // Do not select a successor on the same edge that fills the slot.
      if (response_admit_fire[comb_m])
        candidate_request[comb_m] = 4'b0000;
      arb_ready[comb_m] = slot_can_accept[comb_m] &&
                          arb_grant_valid[comb_m] &&
                          (|(arb_grant[comb_m] & validated_response));
    end

    target_bready = 4'b0000;
    for (comb_m = 0; comb_m < 3; comb_m = comb_m + 1)
      if (slot_can_accept[comb_m])
        target_bready = target_bready | (arb_grant[comb_m] & validated_response);
    target_b_fire = target_bvalid & target_bready;

    manager_bvalid = slot_valid;
    manager_bid = slot_bid_q;
    manager_bresp = slot_bresp_q;
    manager_b_fire = manager_bvalid & manager_bready;
    b_complete_fire = manager_b_fire;
    b_complete_id = manager_bid;
  end

  genvar g;
  generate
    for (g = 0; g < 3; g = g + 1) begin : gen_b_arbiter
      /* verilator lint_off UNUSEDSIGNAL */
      logic [1:0] ignored_pointer;
      /* verilator lint_on UNUSEDSIGNAL */
      axi_rr_arbiter_4 u_rr (
        .ACLK(ACLK),
        .ARESETn(ARESETn),
        .request(candidate_request[g]),
        .downstream_ready(arb_ready[g]),
        .grant(arb_grant[g]),
        .grant_valid(arb_grant_valid[g]),
        .selected_source(arb_selected[g]),
        .pointer(ignored_pointer)
      );
    end
  endgenerate

  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      slot_valid <= 3'b000;
      slot_bid_q <= '0;
      slot_bresp_q <= '0;
      slot_source_q <= '0;
    end else begin
      for (seq_m = 0; seq_m < 3; seq_m = seq_m + 1) begin
        if (manager_b_fire[seq_m]) begin
          slot_valid[seq_m] <= 1'b0;
          slot_bid_q[seq_m] <= 4'b0;
          slot_bresp_q[seq_m] <= 2'b0;
          slot_source_q[seq_m] <= 2'b0;
        end else if (response_admit_fire[seq_m]) begin
          slot_valid[seq_m] <= 1'b1;
          case (arb_selected[seq_m])
            2'b00: begin
              slot_bid_q[seq_m] <= target_bid[0][3:0];
              slot_bresp_q[seq_m] <= target_bresp[0];
              slot_source_q[seq_m] <= 2'b00;
            end
            2'b01: begin
              slot_bid_q[seq_m] <= target_bid[1][3:0];
              slot_bresp_q[seq_m] <= target_bresp[1];
              slot_source_q[seq_m] <= 2'b01;
            end
            2'b10: begin
              slot_bid_q[seq_m] <= target_bid[2][3:0];
              slot_bresp_q[seq_m] <= target_bresp[2];
              slot_source_q[seq_m] <= 2'b10;
            end
            default: begin
              slot_bid_q[seq_m] <= target_bid[3][3:0];
              slot_bresp_q[seq_m] <= target_bresp[3];
              slot_source_q[seq_m] <= 2'b11;
            end
          endcase
        end
      end
    end
  end

  always_comb begin
    slot_source_target = slot_source_q;
  end
endmodule
