module rr_arbiter_fairness_case #(
  parameter int WATCHED = 0
) (input logic ACLK);
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

  // Fairness assumptions are local to this standalone bounded harness:
  // the watched requester persists and the downstream accepts every cycle.
  always @* begin
    if (ARESETn) begin
      assume (request[WATCHED]);
      assume (downstream_ready);
    end
  end

  always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      competing_grants <= 3'b000;
    end else if (grant_valid && downstream_ready) begin
      if (grant[WATCHED]) begin
        competing_grants <= 3'b000;
      end else begin
        competing_grants <= competing_grants + 3'd1;
      end
    end
  end

  always @(posedge ACLK) begin
    if (ARESETn && grant_valid && downstream_ready && !grant[WATCHED])
      assert (competing_grants < 3'd2);
  end

  always @* begin
    cover (ARESETn && grant_valid && grant[WATCHED]);
    cover (ARESETn && competing_grants == 3'd0);
    cover (ARESETn && competing_grants == 3'd1);
    cover (ARESETn && competing_grants == 3'd2);
  end
endmodule

module rr_arbiter_fairness_m0(input logic ACLK);
  rr_arbiter_fairness_case #(.WATCHED(0)) u_case (.ACLK(ACLK));
endmodule

module rr_arbiter_fairness_m1(input logic ACLK);
  rr_arbiter_fairness_case #(.WATCHED(1)) u_case (.ACLK(ACLK));
endmodule

module rr_arbiter_fairness_m2(input logic ACLK);
  rr_arbiter_fairness_case #(.WATCHED(2)) u_case (.ACLK(ACLK));
endmodule
