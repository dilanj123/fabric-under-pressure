module rr_arbiter_fairness(input logic ACLK);
  (* anyseq *) logic ARESETn;
  (* anyseq *) logic [2:0] request;
  (* anyseq *) logic downstream_ready;
  logic [2:0] grant;
  logic grant_valid;
  logic [1:0] selected_manager;
  logic [2:0] formal_grant_q;
  logic [2:0] competing_grants;

  axi_rr_arbiter_3 dut (
    .ACLK(ACLK), .ARESETn(ARESETn), .request(request),
    .downstream_ready(downstream_ready), .grant(grant),
    .grant_valid(grant_valid), .selected_manager(selected_manager),
    .formal_grant_q(formal_grant_q)
  );

  initial assume (!ARESETn);

  // These assumptions apply only to this fairness harness. Safety is proved
  // separately with unconstrained requests and READY.
  always @* begin
    if (ARESETn) begin
      assume (request[0]);
      assume (downstream_ready);
    end
  end

  always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      competing_grants <= 3'b000;
    end else if (grant_valid && downstream_ready) begin
      if (grant[0]) begin
        competing_grants <= 3'b000;
      end else begin
        competing_grants <= competing_grants + 3'd1;
      end
    end
  end

  always @(posedge ACLK) begin
    if (ARESETn && grant_valid && downstream_ready && !grant[0])
      assert (competing_grants < 3'd2);
  end

  always @* begin
    cover (ARESETn && formal_grant_q == 3'b001 && grant_valid);
    cover (ARESETn && formal_grant_q == 3'b010 && grant_valid);
    cover (ARESETn && formal_grant_q == 3'b100 && grant_valid);
    cover (ARESETn && competing_grants == 3'd2);
    cover (ARESETn && formal_grant_q == 3'b001 && competing_grants == 3'd0);
  end
endmodule
