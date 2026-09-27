module axi_ar_read_state_composition_formal(input logic ACLK);
  localparam int M=3;
  (* anyseq *) logic ARESETn;
  (* anyseq *) logic [M-1:0] manager_arvalid, request_legal, target_match;
  (* anyseq *) logic [M-1:0][3:0] manager_arid;
  (* anyseq *) logic [M-1:0][31:0] manager_araddr;
  (* anyseq *) logic [M-1:0][7:0] manager_arlen;
  (* anyseq *) logic [M-1:0][2:0] manager_arsize, manager_arprot;
  (* anyseq *) logic [M-1:0][1:0] manager_arburst;
  (* anyseq *) logic [M-1:0] manager_arlock;
  (* anyseq *) logic [M-1:0][3:0] manager_arcache, manager_arqos, manager_arregion;
  (* anyseq *) logic target_arready;
  (* anyseq *) logic [M-1:0] r_complete_fire;
  (* anyseq *) logic [M-1:0][3:0] r_complete_id;
  logic [M-1:0] manager_arready, manager_ar_fire; logic path_ar_admit_fire;
  logic [1:0] admitted_manager; logic [3:0] admitted_arid, admitted_target; logic [5:0] admitted_internal_id; logic [7:0] admitted_arlen;
  logic target_arvalid,target_ar_fire; logic [5:0] target_arid; logic [31:0] target_araddr; logic [7:0] target_arlen;
  logic [2:0] target_arsize,target_arprot; logic [1:0] target_arburst; logic target_arlock; logic [3:0] target_arcache,target_arqos,target_arregion;
  logic [M-1:0] allowed, admission_violation, commit;
  logic [M-1:0][15:0] busy; logic [M-1:0][2:0] count;
  logic [M-1:0][3:0] bank_id,bank_target; logic [M-1:0][7:0] bank_len; logic [M-1:0] bank_fire;
  axi_read_state_bank bank(.ACLK,.ARESETn,.request_arid(manager_arid),.ar_admit_fire(bank_fire),.ar_admit_id(bank_id),.ar_admit_target(bank_target),.ar_admit_len(bank_len),.r_complete_fire,.r_complete_id,.outstanding_allowed(allowed),.busy_bitmap(busy),.outstanding_count(count),.admission_state_violation(admission_violation),.outstanding_violation(),.commit_fire(commit));
  axi_ar_target_path_a path(.ACLK,.ARESETn,.manager_arvalid,.manager_arid,.manager_araddr,.manager_arlen,.manager_arsize,.manager_arburst,.manager_arlock,.manager_arcache,.manager_arprot,.manager_arqos,.manager_arregion,.request_legal,.target_match,.outstanding_allowed(allowed),.target_arready,.manager_arready,.manager_ar_fire,.ar_admit_fire(path_ar_admit_fire),.admitted_manager,.admitted_arid,.admitted_internal_id,.admitted_target,.admitted_arlen,.target_arvalid,.target_arid,.target_araddr,.target_arlen,.target_arsize,.target_arburst,.target_arlock,.target_arcache,.target_arprot,.target_arqos,.target_arregion,.target_ar_fire);
  always_comb begin
    bank_fire='0; bank_id='0; bank_target='0; bank_len='0;
    if(path_ar_admit_fire) begin bank_fire[admitted_manager]=1'b1; bank_id[admitted_manager]=admitted_arid; bank_target[admitted_manager]=admitted_target; bank_len[admitted_manager]=admitted_arlen; end
  end
  initial assume(!ARESETn); integer init_cycles=0; integer m;
  always @(posedge ACLK) begin
    if(init_cycles<2) begin assume(!ARESETn); init_cycles=init_cycles+1; end
    if($initstate) assume(!ARESETn);
    if($past(ARESETn)) assume(ARESETn);
    if(ARESETn) begin
      for(m=0;m<M;m=m+1) begin
        if($past(ARESETn && manager_arvalid[m] && !manager_arready[m])) begin
          assume(manager_arvalid[m]);
          assume(manager_arid[m] == $past(manager_arid[m]));
          assume(manager_araddr[m] == $past(manager_araddr[m]));
          assume(manager_arlen[m] == $past(manager_arlen[m]));
          assume(request_legal[m] == $past(request_legal[m]));
          assume(target_match[m] == $past(target_match[m]));
          assume(allowed[m] == $past(allowed[m]));
        end
        assume(!r_complete_fire[m] || busy[m][r_complete_id[m]]);
      end
      assert($onehot0(manager_arready)); assert($onehot0(manager_ar_fire));
      assert(path_ar_admit_fire == (|manager_ar_fire));
      for(m=0;m<M;m=m+1) begin
        if(manager_ar_fire[m]) begin assert(!admission_violation[m]); assert(commit[m]); end
        if(target_ar_fire) assert(!path_ar_admit_fire && commit[m]==0);
        assert(count[m] <= 3'd4);
      end
    end
  end
  always @(posedge ACLK) begin
    cover(ARESETn && path_ar_admit_fire);
    cover(ARESETn && target_ar_fire && !path_ar_admit_fire);
    cover(ARESETn && count[0]==3'd1);
  end
endmodule
