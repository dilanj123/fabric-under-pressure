// Shared per-manager write transaction state.
//
// There is one outstanding tracker and one unfinished-W owner per manager,
// shared across all targets.  A manager-facing AW admission is committed to
// both state elements atomically; target-facing AW consumption is not a state
// allocation event.
module axi_write_state_bank #(
  parameter integer MANAGER_COUNT = 3
) (
  input  logic       ACLK,
  input  logic       ARESETn,

  input  logic [MANAGER_COUNT-1:0][3:0] request_awid,
  input  logic [MANAGER_COUNT-1:0]       aw_admit_fire,
  input  logic [MANAGER_COUNT-1:0][3:0] aw_admit_id,
  input  logic [MANAGER_COUNT-1:0][5:0] aw_admit_internal_id,
  input  logic [MANAGER_COUNT-1:0][3:0] aw_admit_target,
  input  logic [MANAGER_COUNT-1:0][7:0] aw_admit_len,

  input  logic [MANAGER_COUNT-1:0]       w_fire,
  input  logic [MANAGER_COUNT-1:0]       wlast,
  input  logic [MANAGER_COUNT-1:0]       b_complete_fire,
  input  logic [MANAGER_COUNT-1:0][3:0] b_complete_id,

  output logic [MANAGER_COUNT-1:0]       outstanding_allowed,
  output logic [MANAGER_COUNT-1:0][15:0] busy_bitmap,
  output logic [MANAGER_COUNT-1:0][2:0] outstanding_count,

  output logic [MANAGER_COUNT-1:0]       owner_active,
  output logic [MANAGER_COUNT-1:0][3:0] owner_target,
  output logic [MANAGER_COUNT-1:0][3:0] owner_id,
  output logic [MANAGER_COUNT-1:0][5:0] owner_internal_id,
  output logic [MANAGER_COUNT-1:0][4:0] owner_beats_remaining,
  output logic [MANAGER_COUNT-1:0]       owner_expected_wlast,

  output logic [MANAGER_COUNT-1:0]       state_allowed,
  output logic [MANAGER_COUNT-1:0]       commit_fire,
  output logic [MANAGER_COUNT-1:0]       admission_state_violation,
  output logic [MANAGER_COUNT-1:0]       outstanding_violation,
  output logic [MANAGER_COUNT-1:0]       owner_violation
);
  genvar g;
  generate
    for (g = 0; g < MANAGER_COUNT; g = g + 1) begin : gen_manager_state
      logic outstanding_allocate_violation;
      logic outstanding_complete_violation;
      logic owner_allocate_allowed;
      logic owner_allocate_violation;
      logic w_without_owner_violation;
      logic wlast_mismatch_violation;
      logic admission_metadata_match;
      logic outstanding_allowed_lane;
      logic [15:0] busy_bitmap_lane;
      logic [2:0] outstanding_count_lane;
      logic owner_active_lane;
      logic [3:0] owner_target_lane, owner_id_lane;
      logic [5:0] owner_internal_id_lane;
      logic [4:0] owner_beats_remaining_lane;
      logic owner_expected_wlast_lane;

      axi_outstanding_tracker u_outstanding (
        .ACLK(ACLK),
        .ARESETn(ARESETn),
        .allocate_fire(commit_fire[g]),
        // Eligibility is evaluated from the manager-facing request ID. The
        // AW path guarantees this equals aw_admit_id on a real handshake;
        // using the request ID here avoids an admission-metadata -> READY
        // combinational loop.
        .allocate_id(request_awid[g]),
        .allocate_target(aw_admit_target[g]),
        .allocate_len(aw_admit_len[g]),
        .complete_fire(b_complete_fire[g]),
        .complete_id(b_complete_id[g]),
        .lookup_id(request_awid[g]),
        .allocate_allowed(outstanding_allowed_lane),
        /* verilator lint_off PINCONNECTEMPTY */
        .complete_known(),
        .allocate_violation(outstanding_allocate_violation),
        .complete_violation(outstanding_complete_violation),
        .busy_bitmap(busy_bitmap_lane),
        .outstanding_count(outstanding_count_lane),
        .lookup_busy(),
        .lookup_target(),
        .lookup_len()
        /* verilator lint_on PINCONNECTEMPTY */
      );

      axi_write_owner u_owner (
        .ACLK(ACLK),
        .ARESETn(ARESETn),
        .allocate_fire(commit_fire[g]),
        .allocate_target(aw_admit_target[g]),
        .allocate_id(aw_admit_id[g]),
        .allocate_internal_id(aw_admit_internal_id[g]),
        .allocate_len(aw_admit_len[g]),
        .w_fire(w_fire[g]),
        .wlast(wlast[g]),
        .allocate_allowed(owner_allocate_allowed),
        .active(owner_active_lane),
        .owner_target(owner_target_lane),
        .owner_id(owner_id_lane),
        .owner_internal_id(owner_internal_id_lane),
        .beats_remaining(owner_beats_remaining_lane),
        .expected_wlast(owner_expected_wlast_lane),
        .allocate_violation(owner_allocate_violation),
        .w_without_owner_violation(w_without_owner_violation),
        .wlast_mismatch_violation(wlast_mismatch_violation)
      );

      always_comb begin
        outstanding_allowed[g] = outstanding_allowed_lane;
        busy_bitmap[g] = busy_bitmap_lane;
        outstanding_count[g] = outstanding_count_lane;
        owner_active[g] = owner_active_lane;
        owner_target[g] = owner_target_lane;
        owner_id[g] = owner_id_lane;
        owner_internal_id[g] = owner_internal_id_lane;
        owner_beats_remaining[g] = owner_beats_remaining_lane;
        owner_expected_wlast[g] = owner_expected_wlast_lane;
        admission_metadata_match = (aw_admit_id[g] == request_awid[g]);
        state_allowed[g] = outstanding_allowed_lane && owner_allocate_allowed &&
                           admission_metadata_match;
        commit_fire[g] = aw_admit_fire[g] && state_allowed[g];
        admission_state_violation[g] = ARESETn &&
                                        aw_admit_fire[g] && !state_allowed[g];
        outstanding_violation[g] = ARESETn &&
                                   (outstanding_allocate_violation ||
                                    outstanding_complete_violation);
        owner_violation[g] = ARESETn &&
                             (owner_allocate_violation ||
                              w_without_owner_violation ||
                              wlast_mismatch_violation);
      end
    end
  endgenerate
endmodule
