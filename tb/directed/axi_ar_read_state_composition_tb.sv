module axi_ar_read_state_composition_tb;
  logic ACLK=0, ARESETn=0; always #5 ACLK=~ACLK;
  logic [2:0] v,legal,match; logic [2:0][3:0] id; logic [2:0][31:0] addr; logic [2:0][7:0] len; logic [2:0][2:0] size,prot; logic [2:0][1:0] burst; logic [2:0] lock; logic [2:0][3:0] cache,qos,region; logic ready;
  logic [2:0] arready,arfire; logic admit; logic [1:0] am; logic [3:0] aid,at; logic [5:0] aiid; logic [7:0] alen; logic tv; logic [5:0] tid; logic [31:0] ta; logic [7:0] tl; logic [2:0] ts,tp; logic [1:0] tb; logic tlock,tfire; logic [3:0] tc,tq,tr;
  logic [2:0] cf,af,allow,viol,commit; logic [2:0][3:0] cid,bank_id,bank_target; logic [2:0][7:0] bank_len; logic [2:0][15:0] busy; logic [2:0][2:0] count;
  integer checks=0;
  axi_read_state_bank bank(.ACLK,.ARESETn,.request_arid(id),.ar_admit_fire(af),.ar_admit_id(bank_id),.ar_admit_target(bank_target),.ar_admit_len(bank_len),.r_complete_fire(cf),.r_complete_id(cid),.outstanding_allowed(allow),.busy_bitmap(busy),.outstanding_count(count),.admission_state_violation(viol),.outstanding_violation(),.commit_fire(commit));
  axi_ar_target_path_a #(.TARGET_INDEX(0)) path(.ACLK,.ARESETn,.manager_arvalid(v),.manager_arid(id),.manager_araddr(addr),.manager_arlen(len),.manager_arsize(size),.manager_arburst(burst),.manager_arlock(lock),.manager_arcache(cache),.manager_arprot(prot),.manager_arqos(qos),.manager_arregion(region),.request_legal(legal),.target_match(match),.outstanding_allowed(allow),.target_arready(ready),.manager_arready(arready),.manager_ar_fire(arfire),.ar_admit_fire(admit),.admitted_manager(am),.admitted_arid(aid),.admitted_internal_id(aiid),.admitted_target(at),.admitted_arlen(alen),.target_arvalid(tv),.target_arid(tid),.target_araddr(ta),.target_arlen(tl),.target_arsize(ts),.target_arburst(tb),.target_arlock(tlock),.target_arcache(tc),.target_arprot(tp),.target_arqos(tq),.target_arregion(tr),.target_ar_fire(tfire));
  always_comb begin af='0; bank_id='0; bank_target='0; bank_len='0; if(admit) begin af[am]=1; bank_id[am]=aid; bank_target[am]=at; bank_len[am]=alen; end end
  task automatic ck(input logic c,input string s); begin checks++; if(!c) begin $display("FAIL %0s",s); $fatal(1); end end endtask
  task automatic reset; begin ARESETn=0; repeat(2) @(posedge ACLK); ARESETn=1; @(posedge ACLK); end endtask
  initial begin integer i; v=0; legal=7; match=0; id='0; addr='0; len='0; size='0; burst='0; lock='0; cache='0; qos='0; region='0; ready=0; cf=0; cid='0; reset();
    v[0]=1; match[0]=1; id[0]=4'h5; addr[0]=32'h1234; len[0]=8'h03; size[0]=3; burst[0]=1; @(posedge ACLK); #1;   ck(busy[0][5]&&count[0]==1,"AR admission allocates shared state"); ck(tv&&tid==6'h05&&ta==32'h1234,"slot payload");
    v=0; #1; ready=1; #1; ck(tfire,"target consumption"); @(posedge ACLK); #1; ck(count[0]==1,"target fire no allocation");
    // completion and same-ID request: registered pre-state blocks new request.
    v[0]=1; match[0]=1; id[0]=4'h5; cf[0]=1; cid[0]=4'h5; #1; ck(!allow[0],"same ID blocked on completion cycle"); @(posedge ACLK); @(posedge ACLK); #1; cf=0; ck(count[0]==0&&!busy[0][5],"read completion"); ck(allow[0],"following cycle free");
    // S3 path transport is separately covered by target parameterization compile/sim.
    $display("PASS axi_ar_read_state_composition_tb checks=%0d",checks); $finish;
  end
endmodule
