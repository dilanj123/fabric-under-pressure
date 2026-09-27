module axi_write_state_bank_formal(input logic ACLK);
  localparam int M = 3;
  (* anyseq *) logic ARESETn;
  (* anyseq *) logic [M-1:0][3:0] request_awid;
  (* anyseq *) logic [M-1:0] aw_admit_fire;
  (* anyseq *) logic [M-1:0][3:0] aw_admit_id;
  (* anyseq *) logic [M-1:0][5:0] aw_admit_internal_id;
  (* anyseq *) logic [M-1:0][3:0] aw_admit_target;
  (* anyseq *) logic [M-1:0][7:0] aw_admit_len;
  (* anyseq *) logic [M-1:0] w_fire, wlast, b_complete_fire;
  (* anyseq *) logic [M-1:0][3:0] b_complete_id;

  logic [M-1:0] outstanding_allowed, owner_active, owner_expected_wlast;
  logic [M-1:0][15:0] busy_bitmap;
  logic [M-1:0][2:0] outstanding_count;
  logic [M-1:0][3:0] owner_target, owner_id;
  logic [M-1:0][5:0] owner_internal_id;
  logic [M-1:0][4:0] owner_beats_remaining;
  logic [M-1:0] state_allowed, commit_fire, admission_state_violation;
  logic [M-1:0] outstanding_violation, owner_violation;

  axi_write_state_bank dut (
    .ACLK, .ARESETn, .request_awid, .aw_admit_fire, .aw_admit_id,
    .aw_admit_internal_id, .aw_admit_target, .aw_admit_len, .w_fire, .wlast,
    .b_complete_fire, .b_complete_id, .outstanding_allowed, .busy_bitmap,
    .outstanding_count, .owner_active, .owner_target, .owner_id,
    .owner_internal_id, .owner_beats_remaining, .owner_expected_wlast,
    .state_allowed, .commit_fire, .admission_state_violation,
    .outstanding_violation, .owner_violation
  );

  initial assume (!ARESETn);
  integer init_cycles = 0;

  integer m;
  always @(posedge ACLK) begin
    if (init_cycles < 2) begin
      assume (!ARESETn);
      init_cycles = init_cycles + 1;
    end
    if ($initstate) assume (!ARESETn);
    if ($past(ARESETn)) assume (ARESETn);
    if (ARESETn && $past(ARESETn)) begin
      for (m = 0; m < M; m = m + 1) begin
        // W/B events are responses to state that existed at the beginning of
        // the cycle.  Invalid direct admissions remain unconstrained and are
        // checked below through the bank's defensive gating.
        assume (!w_fire[m] || owner_active[m]);
        assume (!b_complete_fire[m] || busy_bitmap[m][b_complete_id[m]]);
        if ($past(commit_fire[m])) begin
          assume (!w_fire[m]);
          assume (!b_complete_fire[m]);
        end
        assert (outstanding_count[m] <= 3'd4);
        if (aw_admit_fire[m] && !state_allowed[m]) begin
          assert (!commit_fire[m]);
          assert (admission_state_violation[m]);
        end
      end
    end
  end

  always @(posedge ACLK) begin
    cover (!ARESETn && busy_bitmap == '0);
    cover (ARESETn && outstanding_count[0] == 3'd1);
    cover (ARESETn && outstanding_count[0] == 3'd2);
    cover (ARESETn && outstanding_count[0] == 3'd3);
    cover (ARESETn && outstanding_count[0] == 3'd4);
    cover (ARESETn && admission_state_violation[0]);
    cover (ARESETn && owner_active[0] && busy_bitmap[0] != '0);
    cover (ARESETn && !owner_active[0] && outstanding_count[0] == 3'd4);
    cover (ARESETn && outstanding_count == {3'd1, 3'd1, 3'd1});
    cover (ARESETn && $past(owner_active[0]) && !owner_active[0] &&
           outstanding_count[0] != 3'd0);
    cover (ARESETn && $past(b_complete_fire[0]) &&
           outstanding_count[0] < 3'd4);
  end
endmodule
