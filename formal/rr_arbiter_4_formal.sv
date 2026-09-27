module rr_arbiter_4_formal;
  (* gclk *) logic ACLK;
  (* anyseq *) logic ARESETn;
  (* anyseq *) logic [3:0] request;
  (* anyseq *) logic downstream_ready;
  logic [3:0] grant;
  logic grant_valid;
  logic [1:0] selected_source;
  logic [1:0] pointer;

  axi_rr_arbiter_4 dut (.*);

  initial assume (!ARESETn);

  always @(posedge ACLK) begin
    if (ARESETn) begin
      assert ($onehot0(grant));
      assert (grant_valid == (grant != 4'b0000));
      if ($past(ARESETn) && $past(grant_valid && !downstream_ready)) begin
        assert (grant_valid);
        assert (grant == $past(grant));
        assert (selected_source == $past(selected_source));
        assert (pointer == $past(pointer));
      end
      if ($past(ARESETn) && $past(grant_valid && downstream_ready)) begin
        case ($past(selected_source))
          2'b00: assert (pointer == 2'b01);
          2'b01: assert (pointer == 2'b10);
          2'b10: assert (pointer == 2'b11);
          default: assert (pointer == 2'b00);
        endcase
      end
    end
    cover (ARESETn && grant_valid && selected_source == 2'b00);
    cover (ARESETn && grant_valid && selected_source == 2'b01);
    cover (ARESETn && grant_valid && selected_source == 2'b10);
    cover (ARESETn && grant_valid && selected_source == 2'b11);
    cover (ARESETn && grant_valid && !downstream_ready);
    cover (ARESETn && grant_valid && downstream_ready &&
           $past(grant_valid && $past(grant_valid && downstream_ready)));
  end
endmodule
