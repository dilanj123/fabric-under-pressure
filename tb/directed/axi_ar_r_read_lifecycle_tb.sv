module axi_ar_r_read_lifecycle_tb;
  logic ACLK=0, ARESETn=0; always #5 ACLK=~ACLK;
  logic [2:0] av, legal, match, alock; logic [2:0][3:0] aid, acache, aqos, aregion;
  logic [2:0][31:0] aaddr; logic [2:0][7:0] alen; logic [2:0][2:0] asize, aprot; logic [2:0][1:0] aburst;
  logic [2:0] aready, afire; logic ar_admit; logic [1:0] admitted_manager; logic [3:0] admitted_id, admitted_target; logic [5:0] admitted_internal; logic [7:0] admitted_len;
  logic target_arready, target_arvalid, target_arfire; logic [5:0] target_arid; logic [31:0] target_araddr; logic [7:0] target_arlen; logic [2:0] target_arsize, target_arprot; logic [1:0] target_arburst; logic target_arlock; logic [3:0] target_arcache, target_arqos, target_arregion;
  logic [2:0] bank_admit, allow, admission_violation, outstanding_violation, commit; logic [2:0][3:0] bank_id, bank_target, complete_id; logic [2:0][7:0] bank_len; logic [2:0][15:0] busy; logic [2:0][2:0] count;
  logic [3:0] rv, rlast, rready, rfire, invalid, nonbusy, locked; logic [3:0][5:0] rid; logic [3:0][63:0] rdata; logic [3:0][1:0] rresp;
  logic [2:0] mv, mready, mfire, rcomplete, slot, lock; logic [2:0][3:0] mid; logic [2:0][63:0] mdata; logic [2:0][1:0] mresp, source, lock_target; logic [2:0] mlast; logic [2:0][5:0] lock_id;
  integer checks=0;

  axi_ar_target_path_a #(.TARGET_INDEX(0)) ar_path(
    .ACLK,.ARESETn,.manager_arvalid(av),.manager_arid(aid),.manager_araddr(aaddr),.manager_arlen(alen),.manager_arsize(asize),.manager_arburst(aburst),.manager_arlock(alock),.manager_arcache(acache),.manager_arprot(aprot),.manager_arqos(aqos),.manager_arregion(aregion),.request_legal(legal),.target_match(match),.outstanding_allowed(allow),.target_arready,
    .manager_arready(aready),.manager_ar_fire(afire),.ar_admit_fire(ar_admit),.admitted_manager,.admitted_arid(admitted_id),.admitted_internal_id(admitted_internal),.admitted_target,.admitted_arlen(admitted_len),.target_arvalid,.target_arid,.target_araddr,.target_arlen,.target_arsize,.target_arburst,.target_arlock,.target_arcache,.target_arprot,.target_arqos,.target_arregion,.target_ar_fire(target_arfire));
  always_comb begin
    bank_admit='0; bank_id='0; bank_target='0; bank_len='0;
    if (ar_admit) begin bank_admit[admitted_manager]=1'b1; bank_id[admitted_manager]=admitted_id; bank_target[admitted_manager]=admitted_target; bank_len[admitted_manager]=admitted_len; end
  end
  axi_read_state_bank bank(.ACLK,.ARESETn,.request_arid(aid),.ar_admit_fire(bank_admit),.ar_admit_id(bank_id),.ar_admit_target(bank_target),.ar_admit_len(bank_len),.r_complete_fire(rcomplete),.r_complete_id(complete_id),.outstanding_allowed(allow),.busy_bitmap(busy),.outstanding_count(count),.admission_state_violation(admission_violation),.outstanding_violation(),.commit_fire(commit));
  axi_r_response_router r_router(.ACLK,.ARESETn,.target_rvalid(rv),.target_rid(rid),.target_rdata(rdata),.target_rresp(rresp),.target_rlast(rlast),.target_rready(rready),.target_r_fire(rfire),.busy_bitmap(busy),.manager_rvalid(mv),.manager_rid(mid),.manager_rdata(mdata),.manager_rresp(mresp),.manager_rlast(mlast),.manager_rready(mready),.manager_r_fire(mfire),.r_complete_fire(rcomplete),.r_complete_id(complete_id),.invalid_manager_violation(invalid),.nonbusy_id_violation(nonbusy),.locked_rid_violation(locked),.response_admit_fire(),.slot_valid(slot),.slot_source_target(source),.lock_active(lock),.lock_target,.lock_internal_id(lock_id));

  task automatic ck(input logic c,input string s); begin checks++; if(!c) begin $display("FAIL %0s",s); $fatal(1); end end endtask
  task automatic tick; begin @(posedge ACLK); #1; end endtask
  task automatic init; begin
    av='0; legal='0; match='0; aid='0; aaddr='0; alen='0; asize='0; aburst='0; alock='0; acache='0; aprot='0; aqos='0; aregion='0; target_arready=0;
    rv='0; rid='0; rdata='0; rresp='0; rlast='0; mready='0; complete_id='0; ARESETn=0; repeat(2) tick(); ARESETn=1; tick();
  end endtask
  initial begin
    init();
    // AR admission creates shared state before target AR consumption.
    av[0]=1; legal[0]=1; match[0]=1; aid[0]=4'h5; aaddr[0]=32'h4000; alen[0]=8'd1; asize[0]=3; aburst[0]=1; target_arready=1;
    tick(); tick(); ck(busy[0][5] && count[0]==1 && admitted_internal==6'h05, "AR admission state");
    av='0; #1; ck(target_arfire && busy[0][5], "AR target consumption does not complete"); tick();

    // Two-beat R burst: first beat fills the manager slot, second beat refills after consumption.
    rv[0]=1; rid[0]=6'h05; rdata[0]=64'h100; rresp[0]=2'b00; rlast[0]=0; tick(); tick();
    ck(mv[0] && mdata[0]==64'h100 && lock[0] && busy[0][5], "R first beat and lock");
    mready[0]=1; rdata[0]=64'h101; rlast[0]=1; #1; ck(rfire[0] && mfire[0], "R nonfinal drain/refill"); tick();
    rv[0]=0; #1; ck(mv[0] && mdata[0]==64'h101 && mlast[0], "R final slot held");
    mready[0]=0; tick(); ck(busy[0][5] && count[0]==1, "final response stall keeps read busy");
    mready[0]=1; #1; ck(rcomplete[0] && complete_id[0]==4'h5, "accepted RLAST completion event");
    // Same-ID request is blocked from registered pre-state on completion cycle.
    av[0]=1; legal[0]=1; match[0]=1; aid[0]=4'h5; #1; ck(!allow[0] && !afire[0], "same ID blocked on completion cycle"); tick();
    ck(!busy[0][5] && count[0]==0 && allow[0], "read ID freed following cycle");
    $display("PASS axi_ar_r_read_lifecycle_tb checks=%0d",checks); $finish;
  end
endmodule
