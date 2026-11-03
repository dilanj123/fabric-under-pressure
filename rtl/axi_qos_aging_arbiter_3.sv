// Three-manager Architecture-B scheduler for one target and direction.
// Selection is registered and held until the manager-facing address handshake.
module axi_qos_aging_arbiter_3 (
  input logic ACLK, ARESETn,
  input logic [2:0] legal_pending,
  input logic [2:0] eligible,
  input logic [2:0][3:0] qos,
  input logic accept,
  output logic [2:0] grant,
  output logic grant_valid,
  output logic [1:0] selected_manager,
  output logic [2:0][7:0] age,
  output logic [1:0] pointer
`ifdef FORMAL
  , output logic [2:0] formal_candidate
  , output logic [2:0] formal_starved
  , output logic [2:0] formal_normal_set
  , output logic [2:0][7:0] formal_age_next
  , output logic [1:0] formal_pointer_next
  , output logic [2:0] formal_grant_next
  , output logic formal_grant_valid_next
  , output logic [1:0] formal_selected_next
`endif
);
  logic [2:0] candidate, starved, normal_set, grant_d;
  logic candidate_valid, grant_valid_d;
  logic [1:0] candidate_manager, selected_manager_d;
  logic [2:0][7:0] age_d;
  logic [1:0] pointer_d;
  integer offset, manager_index;
  logic found;

  // Arbitration uses registered pre-state age. A 63->64 increment becomes
  // visible to a fresh selection in the following cycle.
  always_comb begin
    starved = 3'b000;
    normal_set = 3'b000;
    candidate = 3'b000;
    candidate_valid = 1'b0;
    candidate_manager = 2'b00;
    found = 1'b0;
    manager_index = 0;
    for (integer m=0; m<3; m=m+1)
      if (eligible[m] && age[m] >= 8'd64) starved[m] = 1'b1;

    if (|starved) begin
      normal_set = starved;
    end else begin
      for (integer m=0; m<3; m=m+1) begin
        if (eligible[m] && (!found || qos[m] > qos[manager_index])) begin
          manager_index = m;
          found = 1'b1;
        end
      end
      if (found) begin
        for (integer m=0; m<3; m=m+1)
          if (eligible[m] && qos[m] == qos[manager_index]) normal_set[m] = 1'b1;
      end
    end
    // Pick the first member of the eligible class from the shared RR pointer.
    found = 1'b0;
    manager_index = 0;
    for (offset=0; offset<3; offset=offset+1) begin
      manager_index = (integer'(pointer) + offset) % 3;
      if (!found && normal_set[manager_index]) begin
        candidate[manager_index] = 1'b1;
        candidate_manager = manager_index[1:0];
        candidate_valid = 1'b1;
        found = 1'b1;
      end
    end
  end

  function automatic logic [1:0] next_pointer(input logic [1:0] winner);
    case (winner)
      2'd0: next_pointer = 2'd1;
      2'd1: next_pointer = 2'd2;
      default: next_pointer = 2'd0;
    endcase
  endfunction

  always_comb begin
    age_d = age;
    pointer_d = pointer;
    grant_d = grant;
    grant_valid_d = grant_valid;
    selected_manager_d = selected_manager;

    for (integer m=0; m<3; m=m+1) begin
      if (!legal_pending[m] || (accept && grant[m])) age_d[m] = 8'd0;
      else if (age[m] != 8'hff) age_d[m] = age[m] + 8'd1;
    end

    if (accept && grant_valid) begin
      pointer_d = next_pointer(selected_manager);
      // Match A's D031/D036 behavior: do not preload a successor from the
      // pre-handshake request vector. A new selection is registered next.
      grant_d = '0;
      grant_valid_d = 1'b0;
      selected_manager_d = 2'd0;
    end else if (grant_valid && legal_pending[selected_manager]) begin
      // A held legal request is never pre-empted by new QoS/age changes.
    end else begin
      // Withdrawn selections disappear; only a real eligible fire advances RR.
      grant_d = candidate;
      grant_valid_d = candidate_valid;
      selected_manager_d = candidate_manager;
    end
  end

  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      age <= '0;
      pointer <= 2'd0;
      grant <= '0;
      grant_valid <= 1'b0;
      selected_manager <= 2'd0;
    end else begin
      age <= age_d;
      pointer <= pointer_d;
      grant <= grant_d;
      grant_valid <= grant_valid_d;
      selected_manager <= selected_manager_d;
    end
  end

`ifdef FORMAL
  assign formal_candidate = candidate;
  assign formal_starved = starved;
  assign formal_normal_set = normal_set;
  assign formal_age_next = age_d;
  assign formal_pointer_next = pointer_d;
  assign formal_grant_next = grant_d;
  assign formal_grant_valid_next = grant_valid_d;
  assign formal_selected_next = selected_manager_d;
`endif
endmodule
