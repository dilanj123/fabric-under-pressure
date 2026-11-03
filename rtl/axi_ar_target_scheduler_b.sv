// Architecture-B AR boundary. Age tracks legal mapped requests even while
// current outstanding-ID/capacity rules make them temporarily ineligible.
module axi_ar_target_scheduler_b (
  input logic ACLK, ARESETn,
  input logic [2:0] request_present, request_legal, target_match, outstanding_allowed,
  input logic [2:0][3:0] request_qos,
  input logic target_ready,
  output logic [2:0] raw_eligible,
  output logic [2:0] grant,
  output logic grant_valid,
  output logic [1:0] selected_manager,
  output logic ar_accept_fire
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
    legal_pending = request_present & request_legal & target_match;
    raw_eligible = legal_pending & outstanding_allowed;
    effective_target_ready = target_ready;
    ar_accept_fire = grant_valid && effective_target_ready &&
                     (|(grant & raw_eligible));
`ifdef FORMAL
    formal_arbiter_request = raw_eligible;
`endif
  end
  axi_qos_aging_arbiter_3 u_scheduler (
    .ACLK, .ARESETn, .legal_pending, .eligible(raw_eligible),
    .qos(request_qos), .accept(ar_accept_fire), .grant, .grant_valid,
    .selected_manager, .age(age_state), .pointer(rr_pointer_state)
  );
endmodule
