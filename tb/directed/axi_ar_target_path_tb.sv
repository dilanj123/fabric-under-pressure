module axi_ar_target_path_tb;
  logic ACLK=0, ARESETn=0;
  always #5 ACLK=~ACLK;
  logic [2:0] v; logic [2:0][3:0] id; logic [2:0][31:0] addr; logic [2:0][7:0] len;
  logic [2:0][2:0] size; logic [2:0][1:0] burst; logic [2:0] lock;
  logic [2:0][3:0] cache,qos,region; logic [2:0][2:0] prot;
  logic [2:0] legal,match,allowed; logic ready;
  logic [2:0] arready, arfire; logic admit; logic [1:0] adm_mgr; logic [3:0] adm_id,adm_t; logic [5:0] adm_iid; logic [7:0] adm_len;
  logic tvalid; logic [5:0] tid; logic [31:0] taddr; logic [7:0] tlen; logic [2:0] tsize; logic [1:0] tburst; logic tlock; logic [3:0] tcache,tqos,tregion; logic [2:0] tprot; logic tfire;
  integer checks=0;
  logic [5:0] hold_id;
  axi_ar_target_path_a #(.TARGET_INDEX(1)) dut(
    .ACLK(ACLK), .ARESETn(ARESETn), .manager_arvalid(v),.manager_arid(id),.manager_araddr(addr),.manager_arlen(len),.manager_arsize(size),.manager_arburst(burst),.manager_arlock(lock),.manager_arcache(cache),.manager_arprot(prot),.manager_arqos(qos),.manager_arregion(region),.request_legal(legal),.target_match(match),.outstanding_allowed(allowed),.target_arready(ready),.manager_arready(arready),.manager_ar_fire(arfire),.ar_admit_fire(admit),.admitted_manager(adm_mgr),.admitted_arid(adm_id),.admitted_internal_id(adm_iid),.admitted_target(adm_t),.admitted_arlen(adm_len),.target_arvalid(tvalid),.target_arid(tid),.target_araddr(taddr),.target_arlen(tlen),.target_arsize(tsize),.target_arburst(tburst),.target_arlock(tlock),.target_arcache(tcache),.target_arprot(tprot),.target_arqos(tqos),.target_arregion(tregion),.target_ar_fire(tfire));
  task automatic ck(input logic c, input string s); begin checks++; if(!c) begin $display("FAIL %0s",s); $fatal(1); end end endtask
  task automatic defaults; integer i; begin v=0; legal=7; match=0; allowed=7; ready=0; for(i=0;i<3;i++) begin id[i]=4'(i+1); addr[i]=32'h1000+i; len[i]=8'(i+1); size[i]=3'b011; burst[i]=2'b01; lock[i]=0; cache[i]=4'(10+i); prot[i]=3'(i); qos[i]=4'(4+i); region[i]=4'(i); end end endtask
  task automatic pulse_reset; begin ARESETn=0; repeat(2) @(posedge ACLK); ARESETn=1; @(posedge ACLK); end endtask
  initial begin
    defaults(); pulse_reset();
    // Each manager can be selected and its complete payload reaches S1.
    for(integer m=0;m<3;m++) begin
      defaults(); pulse_reset(); v[m]=1; match[m]=1; ready=1; @(posedge ACLK); @(posedge ACLK); #1;
      ck(arfire[m] && $onehot(arfire),"manager AR fire");
      @(posedge ACLK); #1;
      ck(tvalid,"target valid after admission"); ck(tid=={m[1:0],id[m]},"widened ID"); ck(taddr==addr[m],"address"); ck(tlen==len[m],"length"); ck(tsize==size[m] && tburst==burst[m],"shape"); ck(tlock==lock[m] && tcache==cache[m] && tprot==prot[m],"attributes"); ck(tqos==qos[m] && tregion==region[m],"QoS region");
      #1; ck(tfire,"target fire"); v=0; @(posedge ACLK); #1;
      @(posedge ACLK); #1;
    end
    // blocker matrix for M0 on S1
    defaults(); pulse_reset(); v[0]=1; match[0]=1; ready=0; #1; ck(dut.u_scheduler.raw_eligible[0],"baseline eligible");
    legal[0]=0; #1; ck(!dut.u_scheduler.raw_eligible[0],"illegal blocked"); legal[0]=1; match[0]=0; #1; ck(!dut.u_scheduler.raw_eligible[0],"target mismatch blocked"); match[0]=1; allowed[0]=0; #1; ck(!dut.u_scheduler.raw_eligible[0],"outstanding blocked"); v[0]=0; #1; ck(!dut.u_scheduler.raw_eligible[0],"absent blocked");
    // stall stability and no drain/refill
    defaults(); pulse_reset(); v[0]=1; match[0]=1; ready=0; @(posedge ACLK); @(posedge ACLK); #1; ck(tvalid,"stall setup"); ready=0; hold_id=tid; id[0]=4'he; addr[0]=32'hdead; v=3'b111; match=3'b111; repeat(3) begin @(posedge ACLK); #1; ck(tvalid && tid==hold_id && taddr==32'h1000,"stall stable"); ck(arfire==0,"no admission while full"); end
    ready=1; #1; ck(tfire,"drain"); ck(arfire==0,"no same-cycle drain/refill"); @(posedge ACLK); #1; ck(!tvalid,"slot empty");
    // S3 parameterized transport is checked by a second instance in a tiny separate compile regression.
    $display("PASS axi_ar_target_path_tb checks=%0d",checks); $finish;
  end
endmodule
