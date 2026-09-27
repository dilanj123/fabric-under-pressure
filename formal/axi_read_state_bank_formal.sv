module axi_read_state_bank_formal(input logic ACLK);
  localparam int M=3;
  (* anyseq *) logic ARESETn;
  (* anyseq *) logic [M-1:0][3:0] request_arid, ar_admit_id, ar_admit_target, r_complete_id;
  (* anyseq *) logic [M-1:0][7:0] ar_admit_len;
  (* anyseq *) logic [M-1:0] ar_admit_fire, r_complete_fire;
  logic [M-1:0] allowed, admission_violation, outstanding_violation, commit;
  logic [M-1:0][15:0] busy; logic [M-1:0][2:0] count;
  axi_read_state_bank dut(.ACLK,.ARESETn,.request_arid,.ar_admit_fire,.ar_admit_id,.ar_admit_target,.ar_admit_len,.r_complete_fire,.r_complete_id,.outstanding_allowed(allowed),.busy_bitmap(busy),.outstanding_count(count),.admission_state_violation(admission_violation),.outstanding_violation(outstanding_violation),.commit_fire(commit));
  initial assume(!ARESETn); integer init_cycles=0; integer m;
  always @(posedge ACLK) begin
    if(init_cycles<2) begin assume(!ARESETn); init_cycles=init_cycles+1; end
    if($initstate) assume(!ARESETn);
    if($past(ARESETn)) assume(ARESETn);
    if(ARESETn) for(m=0;m<M;m=m+1) begin
      assert(count[m] <= 3'd4);
      assert(count[m] == busy[m][0] + busy[m][1] + busy[m][2] + busy[m][3] + busy[m][4] + busy[m][5] + busy[m][6] + busy[m][7] + busy[m][8] + busy[m][9] + busy[m][10] + busy[m][11] + busy[m][12] + busy[m][13] + busy[m][14] + busy[m][15]);
      assert(admission_violation[m] == (ar_admit_fire[m] && !(allowed[m] && (ar_admit_id[m]==request_arid[m]))));
      if(ar_admit_fire[m] && !admission_violation[m]) assert(commit[m]);
      if(ar_admit_fire[m] && admission_violation[m]) assert(!commit[m]);
      if(r_complete_fire[m]) assume(busy[m][r_complete_id[m]]);
    end
  end
  always @(posedge ACLK) begin
    cover(!ARESETn && busy=='0);
    cover(ARESETn && count[0]==3'd1);
    cover(ARESETn && count[0]==3'd2);
    cover(ARESETn && count[0]==3'd3);
    cover(ARESETn && count[0]==3'd4);
    cover(ARESETn && count=={3'd1,3'd1,3'd1});
    cover(ARESETn && admission_violation[0]);
  end
endmodule
