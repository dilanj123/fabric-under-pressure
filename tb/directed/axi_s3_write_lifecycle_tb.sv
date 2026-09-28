module axi_s3_write_lifecycle_tb;
  logic ACLK=0, ARESETn=0; always #5 ACLK=~ACLK;
  logic [2:0] awv, awlegal, awmatch, out_allowed;
  logic [2:0][3:0] awid, awaddr_dummy;
  logic [2:0][31:0] awaddr; logic [2:0][7:0] awlen;
  logic [2:0][2:0] awsize, awprot; logic [2:0][1:0] awburst;
  logic [2:0] awlock; logic [2:0][3:0] awcache,awqos,awregion;
  logic [2:0] owner_active; logic [2:0][3:0] owner_target;
  logic [2:0][3:0] owner_id; logic [2:0][5:0] owner_iid;
  logic [2:0][4:0] owner_beats; logic [2:0] owner_exp;
  logic [3:0] owner_t0,owner_t1,owner_t2;
  logic [2:0] awready,awfire; logic awadmit; logic [1:0] adm_m;
  logic [3:0] adm_id,adm_target; logic [5:0] adm_iid; logic [7:0] adm_len;
  logic tawv,tawready,tawfire; logic [5:0] tawid; logic [31:0] tawaddr;
  logic [7:0] tawlen; logic [2:0] tawsize,tawprot; logic [1:0] tawburst;
  logic tawlock; logic [3:0] tawcache,tawqos,tawregion;

  logic [2:0] wv,wl,wwready,wfire,owner_wfire,owner_wlast;
  logic [2:0][63:0] wd; logic [2:0][7:0] ws;
  logic twv,twready,twfire,twlast; logic [63:0] twd; logic [7:0] tws;

  logic [2:0][3:0] req_awid,admit_id; logic [2:0][5:0] admit_iid;
  logic [2:0][3:0] admit_target; logic [2:0][7:0] admit_len;
  logic [2:0] bcomp; logic [2:0][3:0] bcomp_id;
  logic [2:0][15:0] busy; logic [2:0][2:0] count;
  logic [2:0] state_allowed,commit,admit_violation,ov,ownerv;

  logic [3:0] tbv,tbr,tbf; logic [3:0][5:0] tbid; logic [3:0][1:0] tbresp;
  logic [2:0] mbv,mbr,mbr_fire; logic [2:0][3:0] mbid; logic [2:0][1:0] mbresp;
  logic [2:0] bc_from_router; logic [2:0][3:0] bcid;
  logic [3:0] inv,nonbusy; logic [2:0] radmit,bslot; logic [2:0][1:0] bsource;

  logic [5:0] ep_awid; logic [31:0] ep_awaddr; logic [7:0] ep_awlen; logic [2:0] ep_awsize; logic [1:0] ep_awburst; logic ep_awlock; logic [3:0] ep_awcache,ep_awqos,ep_awregion; logic [2:0] ep_awprot; logic ep_awv,ep_awr;
  logic [63:0] ep_wdata; logic [7:0] ep_wstrb; logic ep_wlast,ep_wvalid,ep_wready;
  logic [5:0] ep_bid; logic [1:0] ep_bresp; logic ep_bvalid,ep_bready;
  integer checks=0;

  assign owner_t0=owner_target[0]; assign owner_t1=owner_target[1]; assign owner_t2=owner_target[2];
  assign req_awid=awid;
  always_comb begin
    admit_id='0; admit_iid='0; admit_target='0; admit_len='0;
    admit_id[0]=adm_id; admit_iid[0]=adm_iid; admit_target[0]=adm_target; admit_len[0]=adm_len;
  end
  axi_write_state_bank sb(.ACLK,.ARESETn,.request_awid(req_awid),.aw_admit_fire({2'b0,awadmit}),.aw_admit_id(admit_id),.aw_admit_internal_id(admit_iid),.aw_admit_target(admit_target),.aw_admit_len(admit_len),.w_fire(owner_wfire),.wlast(owner_wlast),.b_complete_fire(bcomp),.b_complete_id(bcomp_id),.outstanding_allowed(out_allowed),.busy_bitmap(busy),.outstanding_count(count),.owner_active,.owner_target,.owner_id,.owner_internal_id(owner_iid),.owner_beats_remaining(owner_beats),.owner_expected_wlast(owner_exp),.state_allowed,.commit_fire(commit),.admission_state_violation(admit_violation),.outstanding_violation(ov),.owner_violation(ownerv));
  axi_aw_target_path_a #(.TARGET_INDEX(3)) awp(.ACLK,.ARESETn,.manager_awvalid(awv),.manager_awid(awid),.manager_awaddr(awaddr),.manager_awlen(awlen),.manager_awsize(awsize),.manager_awburst(awburst),.manager_awlock(awlock),.manager_awcache(awcache),.manager_awprot(awprot),.manager_awqos(awqos),.manager_awregion(awregion),.request_legal(awlegal),.target_match(awmatch),.outstanding_allowed(out_allowed),.owner_active,.owner_target_m0(owner_t0),.owner_target_m1(owner_t1),.owner_target_m2(owner_t2),.target_awready(ep_awr),.manager_awready(awready),.manager_aw_fire(awfire),.aw_admit_fire(awadmit),.admitted_manager(adm_m),.admitted_awid(adm_id),.admitted_internal_id(adm_iid),.admitted_target(adm_target),.admitted_awlen(adm_len),.target_awvalid(tawv),.target_awid(tawid),.target_awaddr(tawaddr),.target_awlen(tawlen),.target_awsize(tawsize),.target_awburst(tawburst),.target_awlock(tawlock),.target_awcache(tawcache),.target_awprot(tawprot),.target_awqos(tawqos),.target_awregion(tawregion),.target_aw_fire(tawfire));
  axi_w_target_path #(.TARGET_INDEX(3)) wp(.ACLK,.ARESETn,.manager_wvalid(wv),.manager_wdata(wd),.manager_wstrb(ws),.manager_wlast(wl),.owner_active,.owner_target,.target_wready(ep_wready),.manager_wready(wwready),.manager_w_fire(wfire),.target_wvalid(twv),.target_wdata(twd),.target_wstrb(tws),.target_wlast(twlast),.target_w_fire(twfire),.selected_manager(),.selected_owner_valid(),.owner_conflict_violation(),.owner_w_fire(owner_wfire),.owner_wlast(owner_wlast));
  axi_s3_error_target ep(.ACLK,.ARESETn,.awid(tawid),.awaddr(tawaddr),.awlen(tawlen),.awsize(tawsize),.awburst(tawburst),.awlock(tawlock),.awcache(tawcache),.awprot(tawprot),.awqos(tawqos),.awregion(tawregion),.awvalid(tawv),.awready(ep_awr),.wdata(twd),.wstrb(tws),.wlast(twlast),.wvalid(twv),.wready(ep_wready),.bid(ep_bid),.bresp(ep_bresp),.bvalid(ep_bvalid),.bready(ep_bready),.arid(0),.araddr(0),.arlen(0),.arsize(0),.arburst(0),.arlock(0),.arcache(0),.arprot(0),.arqos(0),.arregion(0),.arvalid(0),.arready(),.rid(),.rdata(),.rresp(),.rlast(),.rvalid(),.rready(0),.early_wlast_violation(),.missing_wlast_violation(),.w_without_aw_violation(),.write_active(),.write_id(),.write_beats_remaining(),.read_active(),.read_id(),.read_beats_remaining());
  assign tbv[3]=ep_bvalid; assign tbid[3]=ep_bid; assign tbresp[3]=ep_bresp; assign tbv[2:0]=0; assign tbid[2:0]='0; assign tbresp[2:0]='0; assign ep_bready=tbr[3];
  axi_b_response_router br(.ACLK,.ARESETn,.target_bvalid(tbv),.target_bid(tbid),.target_bresp(tbresp),.target_bready(tbr),.target_b_fire(tbf),.busy_bitmap(busy),.manager_bvalid(mbv),.manager_bid(mbid),.manager_bresp(mbresp),.manager_bready(mbr),.manager_b_fire(mbr_fire),.b_complete_fire(bc_from_router),.b_complete_id(bcid),.invalid_manager_violation(inv),.nonbusy_id_violation(nonbusy),.response_admit_fire(radmit),.slot_valid(bslot),.slot_source_target(bsource));
  assign bcomp=bc_from_router; assign bcomp_id=bcid;

  task automatic ck(input logic c,input string s); begin checks++; if(!c) begin $display("FAIL %s",s); $fatal(1); end end endtask
  task automatic tick; begin @(posedge ACLK); #1; end endtask
  initial begin
    awv=0; awlegal=7; awmatch=7; awid='0; awaddr='0; awlen='0; awsize='0; awburst='0; awlock='0; awcache='0; awprot='0; awqos='0; awregion='0;
    wv=0; wl=0; wd='0; ws='0; mbr=0; ARESETn=0; repeat(2) tick(); ARESETn=1;
    awid[0]=4'hA; awlen[0]=0; awv[0]=1; wd[0]=64'h1234; ws[0]=8'hF0; wl[0]=1; wv[0]=1; tick(); #1; ck(awready[0] && !wwready[0],"AW admission before W"); tick(); awv[0]=0; #1; ck(owner_active[0],"shared owner allocated");
    #1; ck(wwready[0],"W ready after AW"); repeat(5) tick(); wv[0]=0; #1; ck(mbv[0] && mbid[0]==4'hA && mbresp[0]==2'b11,"S3 B reaches manager slot"); mbr[0]=1; tick(); #1; ck(!busy[0][10],"B clears shared write ID");
    $display("PASS axi_s3_write_lifecycle_tb checks=%0d",checks); $finish;
  end
endmodule
