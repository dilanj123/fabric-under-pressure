// Architecture-B AW boundary: legal-pending aging is separate from current
// admission eligibility (credits and unfinished target write ownership).
module axi_aw_target_scheduler_b #(parameter integer TARGET_INDEX=0) (
  input logic ACLK, ARESETn,
  input logic [2:0] request_present, request_legal, target_match, outstanding_allowed,
  input logic [2:0][3:0] request_qos,
  input logic [2:0] owner_active,
  input logic [3:0] owner_target_m0, owner_target_m1, owner_target_m2,
  input logic target_ready,
  output logic [2:0] raw_eligible,
  output logic target_owner_busy,
  output logic [2:0] grant,
  output logic grant_valid,
  output logic [1:0] selected_manager,
  output logic aw_accept_fire
`ifdef FORMAL
  , output logic [2:0] formal_arbiter_request
`endif
);
  logic [2:0] legal_pending;
  logic effective_target_ready;
  /* verilator lint_off UNUSEDSIGNAL */
  logic [2:0][7:0] age_state;
  logic [1:0] rr_pointer_state;
  /* verilator lint_on UNUSEDSIGNAL */
  always_comb begin
    target_owner_busy = (owner_active[0] && owner_target_m0[TARGET_INDEX]) ||
                        (owner_active[1] && owner_target_m1[TARGET_INDEX]) ||
                        (owner_active[2] && owner_target_m2[TARGET_INDEX]);
    legal_pending = request_present & request_legal & target_match;
    raw_eligible = legal_pending & outstanding_allowed & ~owner_active;
    if (target_owner_busy) raw_eligible = '0;
    effective_target_ready = target_ready && !target_owner_busy;
    aw_accept_fire = grant_valid && effective_target_ready &&
                     (|(grant & raw_eligible));
`ifdef FORMAL
    formal_arbiter_request = raw_eligible;
`endif
  end
  axi_qos_aging_arbiter_3 u_scheduler (
    .ACLK, .ARESETn, .legal_pending, .eligible(raw_eligible),
    .qos(request_qos), .accept(aw_accept_fire), .grant, .grant_valid,
    .selected_manager, .age(age_state), .pointer(rr_pointer_state)
  );
endmodule
