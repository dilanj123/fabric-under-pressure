// Standalone Architecture-A scheduler for one target and one direction.
// Requests are already eligible; this block only selects and holds one manager.
module axi_rr_arbiter_3 (
  input  logic       ACLK,
  input  logic       ARESETn,

  input  logic [2:0] request,
  input  logic       downstream_ready,

  output logic [2:0] grant,
  output logic       grant_valid,
  output logic [1:0] selected_manager
`ifdef FORMAL
  , output logic [1:0] formal_pointer_q,
  output logic [1:0] formal_pointer_d,
  output logic [2:0] formal_grant_q,
  output logic [2:0] formal_grant_d,
  output logic       formal_grant_valid_q,
  output logic       formal_grant_valid_d,
  output logic [1:0] formal_selected_manager_q,
  output logic [1:0] formal_selected_manager_d
`endif
);
  logic [1:0] pointer_q;
  logic [1:0] pointer_d;
  logic [2:0] grant_q;
  logic [2:0] grant_d;
  logic       grant_valid_q;
  logic       grant_valid_d;
  logic [1:0] selected_manager_q;
  logic [1:0] selected_manager_d;

  logic [1:0] selection_pointer;
  logic [2:0] candidate_grant;
  logic       candidate_valid;
  logic [1:0] candidate_manager;

  function automatic logic [1:0] next_pointer(input logic [1:0] winner);
    begin
      case (winner)
        2'b00: next_pointer = 2'b01;
        2'b01: next_pointer = 2'b10;
        2'b10: next_pointer = 2'b00;
        default: next_pointer = 2'b00;
      endcase
    end
  endfunction

  always_comb begin
    candidate_grant = 3'b000;
    candidate_valid = 1'b0;
    candidate_manager = 2'b00;

    case (selection_pointer)
      2'b00: begin
        if (request[0]) begin
          candidate_grant = 3'b001;
          candidate_manager = 2'b00;
          candidate_valid = 1'b1;
        end else if (request[1]) begin
          candidate_grant = 3'b010;
          candidate_manager = 2'b01;
          candidate_valid = 1'b1;
        end else if (request[2]) begin
          candidate_grant = 3'b100;
          candidate_manager = 2'b10;
          candidate_valid = 1'b1;
        end
      end
      2'b01: begin
        if (request[1]) begin
          candidate_grant = 3'b010;
          candidate_manager = 2'b01;
          candidate_valid = 1'b1;
        end else if (request[2]) begin
          candidate_grant = 3'b100;
          candidate_manager = 2'b10;
          candidate_valid = 1'b1;
        end else if (request[0]) begin
          candidate_grant = 3'b001;
          candidate_manager = 2'b00;
          candidate_valid = 1'b1;
        end
      end
      2'b10: begin
        if (request[2]) begin
          candidate_grant = 3'b100;
          candidate_manager = 2'b10;
          candidate_valid = 1'b1;
        end else if (request[0]) begin
          candidate_grant = 3'b001;
          candidate_manager = 2'b00;
          candidate_valid = 1'b1;
        end else if (request[1]) begin
          candidate_grant = 3'b010;
          candidate_manager = 2'b01;
          candidate_valid = 1'b1;
        end
      end
      default: begin
        candidate_grant = 3'b000;
        candidate_valid = 1'b0;
        candidate_manager = 2'b00;
      end
    endcase
  end

  always_comb begin
    pointer_d = pointer_q;
    grant_d = grant_q;
    grant_valid_d = grant_valid_q;
    selected_manager_d = selected_manager_q;
    selection_pointer = pointer_q;

    if (grant_valid_q) begin
      if (downstream_ready) begin
        pointer_d = next_pointer(selected_manager_q);
        selection_pointer = next_pointer(selected_manager_q);
        grant_d = candidate_grant;
        grant_valid_d = candidate_valid;
        selected_manager_d = candidate_manager;
      end
    end else begin
      grant_d = candidate_grant;
      grant_valid_d = candidate_valid;
      selected_manager_d = candidate_manager;
    end
  end

  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      pointer_q <= 2'b00;
      grant_q <= 3'b000;
      grant_valid_q <= 1'b0;
      selected_manager_q <= 2'b00;
    end else begin
      pointer_q <= pointer_d;
      grant_q <= grant_d;
      grant_valid_q <= grant_valid_d;
      selected_manager_q <= selected_manager_d;
    end
  end

  always_comb begin
    grant = grant_q;
    grant_valid = grant_valid_q;
    selected_manager = selected_manager_q;
  end

`ifdef FORMAL
  assign formal_pointer_q = pointer_q;
  assign formal_pointer_d = pointer_d;
  assign formal_grant_q = grant_q;
  assign formal_grant_d = grant_d;
  assign formal_grant_valid_q = grant_valid_q;
  assign formal_grant_valid_d = grant_valid_d;
  assign formal_selected_manager_q = selected_manager_q;
  assign formal_selected_manager_d = selected_manager_d;
`endif
endmodule
