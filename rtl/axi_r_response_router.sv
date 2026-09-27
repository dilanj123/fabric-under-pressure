// Registered AXI R response return path for four targets and three managers.
// A new burst is selected by per-manager RR; its target and widened RID are
// then locked until manager-facing accepted RLAST.
module axi_r_response_router (
  input  logic       ACLK,
  input  logic       ARESETn,

  input  logic [3:0]       target_rvalid,
  input  logic [3:0][5:0]  target_rid,
  input  logic [3:0][63:0] target_rdata,
  input  logic [3:0][1:0]  target_rresp,
  input  logic [3:0]       target_rlast,
  output logic [3:0]       target_rready,
  output logic [3:0]       target_r_fire,

  input  logic [2:0][15:0] busy_bitmap,
  output logic [2:0]       manager_rvalid,
  output logic [2:0][3:0]  manager_rid,
  output logic [2:0][63:0] manager_rdata,
  output logic [2:0][1:0]  manager_rresp,
  output logic [2:0]       manager_rlast,
  input  logic [2:0]       manager_rready,
  output logic [2:0]       manager_r_fire,

  output logic [2:0]       r_complete_fire,
  output logic [2:0][3:0]  r_complete_id,

  output logic [3:0]       invalid_manager_violation,
  output logic [3:0]       nonbusy_id_violation,
  output logic [3:0]       locked_rid_violation,
  output logic [2:0]       response_admit_fire,
  output logic [2:0]       slot_valid,
  output logic [2:0][1:0]  slot_source_target,
  output logic [2:0]       lock_active,
  output logic [2:0][1:0]  lock_target,
  output logic [2:0][5:0]  lock_internal_id
);
  logic [2:0][3:0] raw_candidate_request;
  logic [2:0][3:0] arbiter_request;
  logic [2:0][3:0] arb_grant;
  logic [2:0] arb_ready;
  logic [3:0] validated_response;
  logic [3:0] slot_can_accept;
  logic [2:0][3:0] slot_rid_q;
  logic [2:0][63:0] slot_rdata_q;
  logic [2:0][1:0] slot_rresp_q;
  logic [2:0] slot_rlast_q;
  logic [2:0][1:0] slot_source_q;
  logic [2:0][5:0] admitted_id;
  logic [2:0][63:0] admitted_data;
  logic [2:0][1:0] admitted_resp;
  logic [2:0] admitted_last;
  logic [2:0][1:0] admitted_target;
  integer dec_t, lock_m, lock_t;
  integer route_m, route_t;
  integer seq_m;

  function automatic logic busy_for(
      input logic [1:0] manager_index,
      input logic [3:0] id
  );
    begin
      case (manager_index)
        2'b00: busy_for = busy_bitmap[0][id];
        2'b01: busy_for = busy_bitmap[1][id];
        2'b10: busy_for = busy_bitmap[2][id];
        default: busy_for = 1'b0;
      endcase
    end
  endfunction

  function automatic logic [1:0] manager_for(input integer target_index);
    begin
      case (target_index)
        0: manager_for = target_rid[0][5:4];
        1: manager_for = target_rid[1][5:4];
        2: manager_for = target_rid[2][5:4];
        default: manager_for = target_rid[3][5:4];
      endcase
    end
  endfunction

  function automatic logic [3:0] id_for(input integer target_index);
    begin
      case (target_index)
        0: id_for = target_rid[0][3:0];
        1: id_for = target_rid[1][3:0];
        2: id_for = target_rid[2][3:0];
        default: id_for = target_rid[3][3:0];
      endcase
    end
  endfunction

  function automatic logic [5:0] full_id_for(input integer target_index);
    begin
      case (target_index)
        0: full_id_for = target_rid[0];
        1: full_id_for = target_rid[1];
        2: full_id_for = target_rid[2];
        default: full_id_for = target_rid[3];
      endcase
    end
  endfunction

  function automatic logic [63:0] data_for(input integer target_index);
    begin
      case (target_index)
        0: data_for = target_rdata[0];
        1: data_for = target_rdata[1];
        2: data_for = target_rdata[2];
        default: data_for = target_rdata[3];
      endcase
    end
  endfunction

  function automatic logic [1:0] resp_for(input integer target_index);
    begin
      case (target_index)
        0: resp_for = target_rresp[0];
        1: resp_for = target_rresp[1];
        2: resp_for = target_rresp[2];
        default: resp_for = target_rresp[3];
      endcase
    end
  endfunction

  function automatic logic last_for(input integer target_index);
    begin
      case (target_index)
        0: last_for = target_rlast[0];
        1: last_for = target_rlast[1];
        2: last_for = target_rlast[2];
        default: last_for = target_rlast[3];
      endcase
    end
  endfunction

  always_comb begin
    raw_candidate_request = '0;
    validated_response = 4'b0;
    invalid_manager_violation = 4'b0;
    nonbusy_id_violation = 4'b0;
    locked_rid_violation = 4'b0;
    lock_t = 0;

    // Decode and validate every target independently. These diagnostics are
    // intentionally retained even when the response is blocked by a lock.
    for (dec_t = 0; dec_t < 4; dec_t = dec_t + 1) begin
      if (target_rvalid[dec_t]) begin
        case (manager_for(dec_t))
          2'b00, 2'b01, 2'b10: begin
            if (busy_for(manager_for(dec_t), id_for(dec_t))) begin
              validated_response[dec_t] = 1'b1;
              case (manager_for(dec_t))
                2'b00: raw_candidate_request[0][dec_t] = 1'b1;
                2'b01: raw_candidate_request[1][dec_t] = 1'b1;
                2'b10: raw_candidate_request[2][dec_t] = 1'b1;
                default: begin end
              endcase
            end else begin
              nonbusy_id_violation[dec_t] = 1'b1;
            end
          end
          default: invalid_manager_violation[dec_t] = 1'b1;
        endcase
      end
    end

    // An active lock owns the source until manager-facing accepted RLAST.
    for (lock_m = 0; lock_m < 3; lock_m = lock_m + 1) begin
      if (lock_active[lock_m]) begin
        for (lock_t = 0; lock_t < 4; lock_t = lock_t + 1) begin
          if ((lock_target[lock_m] == lock_t[1:0]) && target_rvalid[lock_t] &&
              (full_id_for(lock_t) != lock_internal_id[lock_m]))
            locked_rid_violation[lock_t] = 1'b1;
        end
      end
    end
  end

  always_comb begin
    manager_rvalid = slot_valid;
    manager_rid = slot_rid_q;
    manager_rdata = slot_rdata_q;
    manager_rresp = slot_rresp_q;
    manager_rlast = slot_rlast_q;
    manager_r_fire = manager_rvalid & manager_rready;
    r_complete_fire = manager_r_fire & manager_rlast;
    r_complete_id = manager_rid;

    slot_can_accept = '0;
    for (route_m = 0; route_m < 3; route_m = route_m + 1)
      slot_can_accept[route_m] = ARESETn &&
                                 (!slot_valid[route_m] ||
                                  (slot_valid[route_m] && !slot_rlast_q[route_m] &&
                                   manager_rready[route_m]));

    // A target is ready only for the selected manager/source. A new burst
    // starts only with an empty slot; a locked burst may drain/refill only
    // from its locked source.
    target_rready = 4'b0;
    for (route_m = 0; route_m < 3; route_m = route_m + 1) begin
      if (lock_active[route_m]) begin
        if (slot_can_accept[route_m]) begin
          for (route_t = 0; route_t < 4; route_t = route_t + 1) begin
            if ((lock_target[route_m] == route_t[1:0]) && validated_response[route_t] &&
                (full_id_for(route_t) == lock_internal_id[route_m]))
              target_rready[route_t] = 1'b1;
          end
        end
      end else if (!slot_valid[route_m]) begin
        for (route_t = 0; route_t < 4; route_t = route_t + 1) begin
          if (validated_response[route_t] &&
              (manager_for(route_t) == route_m[1:0]))
            target_rready[route_t] = arb_grant[route_m][route_t];
        end
      end
    end
    target_r_fire = target_rvalid & target_rready;
    response_admit_fire = '0;
    admitted_id = '0;
    admitted_data = '0;
    admitted_resp = '0;
    admitted_last = '0;
    admitted_target = '0;
    for (route_t = 0; route_t < 4; route_t = route_t + 1) begin
      if (target_r_fire[route_t]) begin
        case (manager_for(route_t))
          2'b00: begin
            response_admit_fire[0] = 1'b1;
            admitted_id[0] = full_id_for(route_t);
            admitted_data[0] = data_for(route_t);
            admitted_resp[0] = resp_for(route_t);
            admitted_last[0] = last_for(route_t);
            admitted_target[0] = route_t[1:0];
          end
          2'b01: begin
            response_admit_fire[1] = 1'b1;
            admitted_id[1] = full_id_for(route_t);
            admitted_data[1] = data_for(route_t);
            admitted_resp[1] = resp_for(route_t);
            admitted_last[1] = last_for(route_t);
            admitted_target[1] = route_t[1:0];
          end
          2'b10: begin
            response_admit_fire[2] = 1'b1;
            admitted_id[2] = full_id_for(route_t);
            admitted_data[2] = data_for(route_t);
            admitted_resp[2] = resp_for(route_t);
            admitted_last[2] = last_for(route_t);
            admitted_target[2] = route_t[1:0];
          end
          default: begin end
        endcase
      end
    end
    for (route_m = 0; route_m < 3; route_m = route_m + 1)
      arb_ready[route_m] = response_admit_fire[route_m] && !lock_active[route_m];

    // Do not preselect behind a manager slot or an active burst lock. After a
    // first-beat admission, suppress same-edge successor lookahead.
    arbiter_request = raw_candidate_request;
    for (route_m = 0; route_m < 3; route_m = route_m + 1)
      if (slot_valid[route_m] || lock_active[route_m] || response_admit_fire[route_m])
        arbiter_request[route_m] = 4'b0;
  end

  genvar g;
  generate
    for (g = 0; g < 3; g = g + 1) begin : gen_r_arbiter
      /* verilator lint_off PINCONNECTEMPTY */
      axi_rr_arbiter_4 u_rr (
        .ACLK(ACLK), .ARESETn(ARESETn),
        .request(arbiter_request[g]),
        .downstream_ready(arb_ready[g]),
        .grant(arb_grant[g]), .grant_valid(),
        .selected_source(), .pointer()
      );
      /* verilator lint_on PINCONNECTEMPTY */
    end
  endgenerate

  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      slot_valid <= '0;
      slot_rid_q <= '0;
      slot_rdata_q <= '0;
      slot_rresp_q <= '0;
      slot_rlast_q <= '0;
      slot_source_q <= '0;
      lock_active <= '0;
      lock_target <= '0;
      lock_internal_id <= '0;
    end else begin
      for (seq_m = 0; seq_m < 3; seq_m = seq_m + 1) begin
        if (r_complete_fire[seq_m]) begin
          slot_valid[seq_m] <= 1'b0;
          slot_rid_q[seq_m] <= 4'b0;
          slot_rdata_q[seq_m] <= 64'b0;
          slot_rresp_q[seq_m] <= 2'b0;
          slot_rlast_q[seq_m] <= 1'b0;
          slot_source_q[seq_m] <= 2'b0;
          lock_active[seq_m] <= 1'b0;
          lock_target[seq_m] <= 2'b0;
          lock_internal_id[seq_m] <= 6'b0;
        end else if (target_r_fire[0] || target_r_fire[1] ||
                     target_r_fire[2] || target_r_fire[3]) begin
          // Capture only the target handshake decoded to this manager.
          if (response_admit_fire[seq_m]) begin
            slot_valid[seq_m] <= 1'b1;
            slot_rid_q[seq_m] <= admitted_id[seq_m][3:0];
            slot_rdata_q[seq_m] <= admitted_data[seq_m];
            slot_rresp_q[seq_m] <= admitted_resp[seq_m];
            slot_rlast_q[seq_m] <= admitted_last[seq_m];
            slot_source_q[seq_m] <= admitted_target[seq_m];
            if (!lock_active[seq_m]) begin
              lock_active[seq_m] <= 1'b1;
              lock_target[seq_m] <= admitted_target[seq_m];
              lock_internal_id[seq_m] <= admitted_id[seq_m];
            end
          end else if (manager_r_fire[seq_m]) begin
            slot_valid[seq_m] <= 1'b0;
            slot_rid_q[seq_m] <= 4'b0;
            slot_rdata_q[seq_m] <= 64'b0;
            slot_rresp_q[seq_m] <= 2'b0;
            slot_rlast_q[seq_m] <= 1'b0;
            slot_source_q[seq_m] <= 2'b0;
          end
        end else if (manager_r_fire[seq_m]) begin
          slot_valid[seq_m] <= 1'b0;
          slot_rid_q[seq_m] <= 4'b0;
          slot_rdata_q[seq_m] <= 64'b0;
          slot_rresp_q[seq_m] <= 2'b0;
          slot_rlast_q[seq_m] <= 1'b0;
          slot_source_q[seq_m] <= 2'b0;
        end
      end
    end
  end

  assign slot_source_target = slot_source_q;
endmodule
