// Architecture-A target-specific AW eligibility and scheduling boundary.
// This block composes upstream request facts with registered owner status and
// delegates selection/holding to axi_rr_arbiter_3.
module axi_aw_target_scheduler_a #(
  parameter integer TARGET_INDEX = 0
) (
  input  logic       ACLK,
  input  logic       ARESETn,

  input  logic [2:0] request_present,
  input  logic [2:0] request_legal,
  input  logic [2:0] target_match,
  input  logic [2:0] outstanding_allowed,

  input  logic [2:0] owner_active,
  input  logic [3:0] owner_target_m0,
  input  logic [3:0] owner_target_m1,
  input  logic [3:0] owner_target_m2,

  input  logic       target_ready,

  output logic [2:0] raw_eligible,
  output logic       target_owner_busy,
  output logic [2:0] grant,
  output logic       grant_valid,
  output logic [1:0] selected_manager,
  output logic       aw_accept_fire
`ifdef FORMAL
  , output logic [2:0] formal_arbiter_request
`endif
);
  logic [2:0] arbiter_request;
  logic       effective_target_ready;

  always_comb begin
    target_owner_busy = 1'b0;
    if (owner_active[0] && owner_target_m0[TARGET_INDEX]) begin
      target_owner_busy = 1'b1;
    end
    if (owner_active[1] && owner_target_m1[TARGET_INDEX]) begin
      target_owner_busy = 1'b1;
    end
    if (owner_active[2] && owner_target_m2[TARGET_INDEX]) begin
      target_owner_busy = 1'b1;
    end

    raw_eligible = request_present & request_legal & target_match &
                   outstanding_allowed;
    raw_eligible[0] = raw_eligible[0] && !owner_active[0] &&
                      !target_owner_busy;
    raw_eligible[1] = raw_eligible[1] && !owner_active[1] &&
                      !target_owner_busy;
    raw_eligible[2] = raw_eligible[2] && !owner_active[2] &&
                      !target_owner_busy;

    effective_target_ready = target_ready && !target_owner_busy;
    aw_accept_fire = grant_valid && effective_target_ready;

    // D031: on an accepted AW, prevent the RR primitive from registering a
    // successor from stale pre-handshake owner-free eligibility.
    arbiter_request = raw_eligible & {3{!aw_accept_fire}};
`ifdef FORMAL
    formal_arbiter_request = arbiter_request;
`endif
  end

  axi_rr_arbiter_3 u_rr (
    .ACLK(ACLK),
    .ARESETn(ARESETn),
    .request(arbiter_request),
    .downstream_ready(effective_target_ready),
    .grant(grant),
    .grant_valid(grant_valid),
    .selected_manager(selected_manager)
  );
endmodule
