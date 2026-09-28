module axi_s3_read_lifecycle_tb;
  logic ACLK=0,ARESETn=0; always #5 ACLK=~ACLK;
  logic [2:0] arv,arlegal,armatch,out_allowed; logic [2:0][3:0] arid,arcache,arqos,arregion;
  logic [2:0][31:0] araddr; logic [2:0][7:0] arlen; logic [2:0][2:0] arsize,arprot; logic [2:0][1:0] arburst; logic [2:0] arlock;
  logic [2:0] arready,arfire; logic aradmit; logic [1:0] adm_m; logic [3:0] adm_id,adm_target; logic [5:0] adm_iid; logic [7:0] adm_len;
  logic tarv,tarready,tarfire; logic [5:0] tarid; logic [31:0] taraddr; logic [7:0] tarlen; logic [2:0] tarsize,tarprot; logic [1:0] tarburst; logic tarlock; logic [3:0] tarcache,tarqos,tarregion;
  logic [2:0][3:0] req_id,aid; logic [2:0][3:0] atarget; logic [2:0][7:0] alen; logic [2:0] rcomp; logic [2:0][3:0] rcomp_id;
  logic [2:0][15:0] busy; logic [2:0][2:0] count; logic [2:0] state_violation,ov,commit;
  logic [3:0] trv,trready,trfire,tlast; logic [3:0][5:0] trid; logic [3:0][63:0] trdata; logic [3:0][1:0] trresp;
  logic [2:0] mrv,mrready,mrfire,complete; logic [2:0][3:0] mrid; logic [2:0][63:0] mrdata; logic [2:0][1:0] mrresp; logic [2:0] mrlast; logic [2:0][1:0] source; logic [2:0] slot,lock; logic [3:0] inv,nonbusy,locked;
  logic [5:0] ep_arid,ep_rid; logic [31:0] ep_araddr; logic [7:0] ep_arlen; logic [2:0] ep_arsize; logic [1:0] ep_arburst; logic ep_arlock,ep_arvalid,ep_arready; logic [3:0] ep_arcache,ep_arqos,ep_arregion; logic [2:0] ep_arprot;
  logic [63:0] ep_rdata; logic [1:0] ep_rresp; logic ep_rlast,ep_rvalid,ep_rready;
  integer checks=0;
  assign req_id=arid;
  always_comb begin aid='0; atarget='0; alen='0; aid[0]=adm_id; atarget[0]=adm_target; alen[0]=adm_len; end
  axi_read_state_bank sb(.ACLK,.ARESETn,.request_arid(req_id),.ar_admit_fire({2'b0,aradmit}),.ar_admit_id(aid),.ar_admit_target(atarget),.ar_admit_len(alen),.r_complete_fire(rcomp),.r_complete_id(rcomp_id),.outstanding_allowed(out_allowed),.busy_bitmap(busy),.outstanding_count(count),.admission_state_violation(state_violation),.outstanding_violation(ov),.commit_fire(commit));
  axi_ar_target_path_a #(.TARGET_INDEX(3)) arp(.ACLK,.ARESETn,.manager_arvalid(arv),.manager_arid(arid),.manager_araddr(araddr),.manager_arlen(arlen),.manager_arsize(arsize),.manager_arburst(arburst),.manager_arlock(arlock),.manager_arcache(arcache),.manager_arprot(arprot),.manager_arqos(arqos),.manager_arregion(arregion),.request_legal(arlegal),.target_match(armatch),.outstanding_allowed(out_allowed),.target_arready(ep_arready),.manager_arready(arready),.manager_ar_fire(arfire),.ar_admit_fire(aradmit),.admitted_manager(adm_m),.admitted_arid(adm_id),.admitted_internal_id(adm_iid),.admitted_target(adm_target),.admitted_arlen(adm_len),.target_arvalid(tarv),.target_arid(tarid),.target_araddr(taraddr),.target_arlen(tarlen),.target_arsize(tarsize),.target_arburst(tarburst),.target_arlock(tarlock),.target_arcache(tarcache),.target_arprot(tarprot),.target_arqos(tarqos),.target_arregion(tarregion),.target_ar_fire(tarfire));
  axi_s3_error_target ep(.ACLK,.ARESETn,.awid(0),.awaddr(0),.awlen(0),.awsize(0),.awburst(0),.awlock(0),.awcache(0),.awprot(0),.awqos(0),.awregion(0),.awvalid(0),.awready(),.wdata(0),.wstrb(0),.wlast(0),.wvalid(0),.wready(),.bid(),.bresp(),.bvalid(),.bready(0),.arid(tarid),.araddr(taraddr),.arlen(tarlen),.arsize(tarsize),.arburst(tarburst),.arlock(tarlock),.arcache(tarcache),.arprot(tarprot),.arqos(tarqos),.arregion(tarregion),.arvalid(tarv),.arready(ep_arready),.rid(ep_rid),.rdata(ep_rdata),.rresp(ep_rresp),.rlast(ep_rlast),.rvalid(ep_rvalid),.rready(ep_rready),.early_wlast_violation(),.missing_wlast_violation(),.w_without_aw_violation(),.write_active(),.write_id(),.write_beats_remaining(),.read_active(),.read_id(),.read_beats_remaining());
  assign trv[3]=ep_rvalid; assign trid[3]=ep_rid; assign trdata[3]=ep_rdata; assign trresp[3]=ep_rresp; assign tlast[3]=ep_rlast; assign trv[2:0]=0; assign trid[2:0]='0; assign trdata[2:0]='0; assign trresp[2:0]='0; assign tlast[2:0]=0; assign ep_rready=trready[3];
  axi_r_response_router rr(.ACLK,.ARESETn,.target_rvalid(trv),.target_rid(trid),.target_rdata(trdata),.target_rresp(trresp),.target_rlast(tlast),.target_rready(trready),.target_r_fire(trfire),.busy_bitmap(busy),.manager_rvalid(mrv),.manager_rid(mrid),.manager_rdata(mrdata),.manager_rresp(mrresp),.manager_rlast(mrlast),.manager_rready(mrready),.manager_r_fire(mrfire),.r_complete_fire(rcomp),.r_complete_id(rcomp_id),.invalid_manager_violation(inv),.nonbusy_id_violation(nonbusy),.locked_rid_violation(locked),.response_admit_fire(),.slot_valid(slot),.slot_source_target(source),.lock_active(lock),.lock_target(),.lock_internal_id());
  task automatic ck(input logic c,input string s); begin checks++; if(!c) begin $display("FAIL %s",s); $fatal(1); end end endtask
  task automatic tick; begin @(posedge ACLK); #1; end endtask
  initial begin
    arv=0; arlegal=7; armatch=7; arid='0; araddr='0; arlen='0; arsize='0; arburst='0; arlock='0; arcache='0; arprot='0; arqos='0; arregion='0; mrready=0; ARESETn=0; repeat(2) tick(); ARESETn=1;
    arid[0]=4'h5; arlen[0]=1; arv[0]=1; tick(); #1; ck(arready[0],"AR scheduler selects request"); tick(); arv[0]=0; #1; ck(busy[0][5] && count[0]==1,"AR allocates shared read state");
    repeat(3) tick(); #1; ck(mrv[0] && mrid[0]==4'h5 && mrdata[0]==0 && mrresp[0]==2'b11,"S3 DECERR R reaches manager"); ck(!mrlast[0],"first R beat non-final"); mrready[0]=1; tick(); #1; ck(mrv[0] && mrlast[0],"final RLAST follows first beat"); tick(); #1; ck(!busy[0][5] && count[0]==0,"accepted manager RLAST clears read state");
    $display("PASS axi_s3_read_lifecycle_tb checks=%0d",checks); $finish;
  end
endmodule

