// Registered four-source round-robin arbiter.
// A selected source is held until downstream_ready is asserted.
module axi_rr_arbiter_4 (
  input  logic       ACLK,
  input  logic       ARESETn,
  input  logic [3:0] request,
  input  logic       downstream_ready,
  output logic [3:0] grant,
  output logic       grant_valid,
  output logic [1:0] selected_source,
  output logic [1:0] pointer
);
  logic [1:0] pointer_q, pointer_d;
  logic [3:0] grant_q, grant_d;
  logic       grant_valid_q, grant_valid_d;
  logic [1:0] selected_q, selected_d;
  logic [1:0] selection_pointer;
  logic [3:0] candidate_grant;
  logic       candidate_valid;
  logic [1:0] candidate_source;

  function automatic logic [1:0] next_pointer(input logic [1:0] source);
    begin
      case (source)
        2'b00: next_pointer = 2'b01;
        2'b01: next_pointer = 2'b10;
        2'b10: next_pointer = 2'b11;
        default: next_pointer = 2'b00;
      endcase
    end
  endfunction

  always_comb begin
    candidate_grant = 4'b0000;
    candidate_valid = 1'b0;
    candidate_source = 2'b00;
    case (selection_pointer)
      2'b00: begin
        if (request[0]) begin candidate_grant=4'b0001; candidate_source=2'b00; candidate_valid=1'b1; end
        else if (request[1]) begin candidate_grant=4'b0010; candidate_source=2'b01; candidate_valid=1'b1; end
        else if (request[2]) begin candidate_grant=4'b0100; candidate_source=2'b10; candidate_valid=1'b1; end
        else if (request[3]) begin candidate_grant=4'b1000; candidate_source=2'b11; candidate_valid=1'b1; end
      end
      2'b01: begin
        if (request[1]) begin candidate_grant=4'b0010; candidate_source=2'b01; candidate_valid=1'b1; end
        else if (request[2]) begin candidate_grant=4'b0100; candidate_source=2'b10; candidate_valid=1'b1; end
        else if (request[3]) begin candidate_grant=4'b1000; candidate_source=2'b11; candidate_valid=1'b1; end
        else if (request[0]) begin candidate_grant=4'b0001; candidate_source=2'b00; candidate_valid=1'b1; end
      end
      2'b10: begin
        if (request[2]) begin candidate_grant=4'b0100; candidate_source=2'b10; candidate_valid=1'b1; end
        else if (request[3]) begin candidate_grant=4'b1000; candidate_source=2'b11; candidate_valid=1'b1; end
        else if (request[0]) begin candidate_grant=4'b0001; candidate_source=2'b00; candidate_valid=1'b1; end
        else if (request[1]) begin candidate_grant=4'b0010; candidate_source=2'b01; candidate_valid=1'b1; end
      end
      default: begin
        if (request[3]) begin candidate_grant=4'b1000; candidate_source=2'b11; candidate_valid=1'b1; end
        else if (request[0]) begin candidate_grant=4'b0001; candidate_source=2'b00; candidate_valid=1'b1; end
        else if (request[1]) begin candidate_grant=4'b0010; candidate_source=2'b01; candidate_valid=1'b1; end
        else if (request[2]) begin candidate_grant=4'b0100; candidate_source=2'b10; candidate_valid=1'b1; end
      end
    endcase
  end

  always_comb begin
    pointer_d = pointer_q;
    grant_d = grant_q;
    grant_valid_d = grant_valid_q;
    selected_d = selected_q;
    selection_pointer = pointer_q;
    if (grant_valid_q) begin
      if (downstream_ready) begin
        pointer_d = next_pointer(selected_q);
        selection_pointer = next_pointer(selected_q);
        grant_d = candidate_grant;
        grant_valid_d = candidate_valid;
        selected_d = candidate_source;
      end
    end else begin
      grant_d = candidate_grant;
      grant_valid_d = candidate_valid;
      selected_d = candidate_source;
    end
  end

  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      pointer_q <= 2'b00;
      grant_q <= 4'b0000;
      grant_valid_q <= 1'b0;
      selected_q <= 2'b00;
    end else begin
      pointer_q <= pointer_d;
      grant_q <= grant_d;
      grant_valid_q <= grant_valid_d;
      selected_q <= selected_d;
    end
  end

  always_comb begin
    grant = grant_q;
    grant_valid = grant_valid_q;
    selected_source = selected_q;
    pointer = pointer_q;
  end
endmodule
