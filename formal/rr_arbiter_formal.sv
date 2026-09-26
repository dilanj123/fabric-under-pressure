module rr_arbiter_formal(input logic ACLK);
  (* anyseq *) logic ARESETn;
  (* anyseq *) logic [2:0] request;
  (* anyseq *) logic downstream_ready;

  logic [2:0] grant;
  logic grant_valid;
  logic [1:0] selected_manager;
  logic [1:0] formal_pointer_q, formal_pointer_d;
  logic [2:0] formal_grant_q, formal_grant_d;
  logic formal_grant_valid_q, formal_grant_valid_d;
  logic [1:0] formal_selected_manager_q, formal_selected_manager_d;

  axi_rr_arbiter_3 dut (
    .ACLK(ACLK), .ARESETn(ARESETn), .request(request),
    .downstream_ready(downstream_ready), .grant(grant),
    .grant_valid(grant_valid), .selected_manager(selected_manager),
    .formal_pointer_q(formal_pointer_q), .formal_pointer_d(formal_pointer_d),
    .formal_grant_q(formal_grant_q), .formal_grant_d(formal_grant_d),
    .formal_grant_valid_q(formal_grant_valid_q),
    .formal_grant_valid_d(formal_grant_valid_d),
    .formal_selected_manager_q(formal_selected_manager_q),
    .formal_selected_manager_d(formal_selected_manager_d)
  );

  function automatic logic [2:0] reference_grant(
      input logic [1:0] pointer, input logic [2:0] req);
    begin
      reference_grant = 3'b000;
      case (pointer)
        2'b00: begin
          if (req[0]) reference_grant = 3'b001;
          else if (req[1]) reference_grant = 3'b010;
          else if (req[2]) reference_grant = 3'b100;
        end
        2'b01: begin
          if (req[1]) reference_grant = 3'b010;
          else if (req[2]) reference_grant = 3'b100;
          else if (req[0]) reference_grant = 3'b001;
        end
        2'b10: begin
          if (req[2]) reference_grant = 3'b100;
          else if (req[0]) reference_grant = 3'b001;
          else if (req[1]) reference_grant = 3'b010;
        end
        default: reference_grant = 3'b000;
      endcase
    end
  endfunction

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

  initial assume (!ARESETn);

  always @* begin
    if (ARESETn) begin
      assert ($onehot0(grant));
      assert (grant_valid == (grant != 3'b000));
      assert (formal_pointer_q != 2'b11);
      if (grant_valid)
        assert (grant == (3'b001 << selected_manager));

      if (formal_grant_valid_q && !downstream_ready) begin
        assert (formal_grant_valid_d);
        assert (formal_grant_d == formal_grant_q);
        assert (formal_selected_manager_d == formal_selected_manager_q);
        assert (formal_pointer_d == formal_pointer_q);
      end

      if (formal_grant_valid_q && downstream_ready)
        assert (formal_pointer_d == next_pointer(formal_selected_manager_q));
      else
        assert (formal_pointer_d == formal_pointer_q);

      if (!formal_grant_valid_q)
        assert (formal_grant_d == reference_grant(formal_pointer_q, request));
      else if (downstream_ready)
        assert (formal_grant_d == reference_grant(
            next_pointer(formal_selected_manager_q), request));

      if (!formal_grant_valid_q || downstream_ready)
        assert (formal_grant_valid_d == (formal_grant_d != 3'b000));
    end

    cover (ARESETn && formal_pointer_q == 2'b00);
    cover (ARESETn && formal_pointer_q == 2'b01);
    cover (ARESETn && formal_pointer_q == 2'b10);
    cover (ARESETn && formal_grant_q == 3'b001);
    cover (ARESETn && formal_grant_q == 3'b010);
    cover (ARESETn && formal_grant_q == 3'b100);
    cover (ARESETn && formal_grant_valid_q && !downstream_ready &&
           formal_grant_q == 3'b001);
    cover (ARESETn && formal_grant_valid_q && !downstream_ready &&
           formal_grant_q == 3'b010);
    cover (ARESETn && formal_grant_valid_q && !downstream_ready &&
           formal_grant_q == 3'b100);
    cover (ARESETn && formal_grant_valid_q && !downstream_ready &&
           request != formal_grant_q);
    cover (ARESETn && formal_pointer_q == 2'b00 && formal_grant_q == 3'b100 &&
           downstream_ready);
    cover (ARESETn && formal_grant_q == 3'b001 &&
           formal_grant_d == 3'b010 && downstream_ready);
    cover (ARESETn && formal_grant_q == 3'b010 &&
           formal_grant_d == 3'b100 && downstream_ready);
    cover (ARESETn && formal_grant_q == 3'b100 &&
           formal_grant_d == 3'b001 && downstream_ready);
    cover (!ARESETn && formal_grant_q == 3'b000);
  end
endmodule
