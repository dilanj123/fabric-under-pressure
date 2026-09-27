// Shared per-manager read transaction state.
// AR admission allocates one manager's read tracker; target AR consumption does not.
module axi_read_state_bank #(
  parameter integer MANAGER_COUNT = 3
) (
  input  logic       ACLK,
  input  logic       ARESETn,
  input  logic [MANAGER_COUNT-1:0][3:0] request_arid,
  input  logic [MANAGER_COUNT-1:0]       ar_admit_fire,
  input  logic [MANAGER_COUNT-1:0][3:0] ar_admit_id,
  input  logic [MANAGER_COUNT-1:0][3:0] ar_admit_target,
  input  logic [MANAGER_COUNT-1:0][7:0] ar_admit_len,
  input  logic [MANAGER_COUNT-1:0]       r_complete_fire,
  input  logic [MANAGER_COUNT-1:0][3:0] r_complete_id,
  output logic [MANAGER_COUNT-1:0]       outstanding_allowed,
  output logic [MANAGER_COUNT-1:0][15:0] busy_bitmap,
  output logic [MANAGER_COUNT-1:0][2:0] outstanding_count,
  output logic [MANAGER_COUNT-1:0]       admission_state_violation,
  output logic [MANAGER_COUNT-1:0]       outstanding_violation,
  output logic [MANAGER_COUNT-1:0]       commit_fire
);
  genvar g;
  generate
    for (g = 0; g < MANAGER_COUNT; g = g + 1) begin : gen_read_state
      logic allocate_violation;
      logic complete_violation;
      logic metadata_match;
      logic allowed_lane;

      /* verilator lint_off PINCONNECTEMPTY */
      axi_outstanding_tracker u_tracker (
        .ACLK(ACLK), .ARESETn(ARESETn),
        .allocate_fire(commit_fire[g]),
        .allocate_id(request_arid[g]),
        .allocate_target(ar_admit_target[g]),
        .allocate_len(ar_admit_len[g]),
        .complete_fire(r_complete_fire[g]),
        .complete_id(r_complete_id[g]),
        .lookup_id(request_arid[g]),
        .allocate_allowed(allowed_lane),
        .complete_known(),
        .allocate_violation(allocate_violation),
        .complete_violation(complete_violation),
        .busy_bitmap(busy_bitmap[g]),
        .outstanding_count(outstanding_count[g]),
         .lookup_busy(),
        .lookup_target(),
        .lookup_len()
      );
      /* verilator lint_on PINCONNECTEMPTY */

      always_comb begin
        outstanding_allowed[g] = allowed_lane;
        metadata_match = (ar_admit_id[g] == request_arid[g]);
        commit_fire[g] = ar_admit_fire[g] && allowed_lane && metadata_match;
        admission_state_violation[g] = ARESETn && ar_admit_fire[g] &&
                                       !(allowed_lane && metadata_match);
        outstanding_violation[g] = ARESETn &&
                                   (allocate_violation || complete_violation);
      end
    end
  endgenerate
endmodule
