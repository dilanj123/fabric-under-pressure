// Architecture-A target-specific AR eligibility and scheduling boundary.
// Read state is supplied by the shared per-manager read bank.
module axi_ar_target_scheduler_a (
  input  logic       ACLK,
  input  logic       ARESETn,
  input  logic [2:0] request_present,
  input  logic [2:0] request_legal,
  input  logic [2:0] target_match,
  input  logic [2:0] outstanding_allowed,
  input  logic       target_ready,
  output logic [2:0] raw_eligible,
  output logic [2:0] grant,
  output logic       grant_valid,
  output logic [1:0] selected_manager,
  output logic       ar_accept_fire
`ifdef FORMAL
  , output logic [2:0] formal_arbiter_request
`endif
);
  logic [2:0] arbiter_request;
  logic       effective_target_ready;

  always_comb begin
    raw_eligible = request_present & request_legal & target_match &
                   outstanding_allowed;
    effective_target_ready = target_ready;
    ar_accept_fire = grant_valid && effective_target_ready;
    // D036: prevent the accepted pre-edge request vector from preloading a
    // successor on the same edge. The RR pointer still advances normally.
    arbiter_request = raw_eligible & {3{!ar_accept_fire}};
`ifdef FORMAL
    formal_arbiter_request = arbiter_request;
`endif
  end

  axi_rr_arbiter_3 u_rr (
    .ACLK(ACLK), .ARESETn(ARESETn), .request(arbiter_request),
    .downstream_ready(effective_target_ready), .grant(grant),
    .grant_valid(grant_valid), .selected_manager(selected_manager)
  );
endmodule
