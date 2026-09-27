module axi_ar_s3_tb;
  logic ACLK=0,ARESETn=0; always #5 ACLK=~ACLK;
  logic [2:0] v,legal,match,lock; logic [2:0][3:0] id,cache,qos,region; logic [2:0][31:0] addr; logic [2:0][7:0] len; logic [2:0][2:0] size,prot; logic [2:0][1:0] burst; logic ready;
  logic [2:0] mr,fire; logic admit,tv,tf; logic [1:0] am; logic [3:0] aid,at; logic [5:0] iid,tid; logic [7:0] alen,tl; logic [2:0] ts,tp; logic [1:0] tb; logic tlk; logic [3:0] tc,tq,tr;
  integer checks=0;
  axi_ar_target_path_a #(.TARGET_INDEX(3)) dut(.ACLK,.ARESETn,.manager_arvalid(v),.manager_arid(id),.manager_araddr(addr),.manager_arlen(len),.manager_arsize(size),.manager_arburst(burst),.manager_arlock(lock),.manager_arcache(cache),.manager_arprot(prot),.manager_arqos(qos),.manager_arregion(region),.request_legal(legal),.target_match(match),.outstanding_allowed(3'b111),.target_arready(ready),.manager_arready(mr),.manager_ar_fire(fire),.ar_admit_fire(admit),.admitted_manager(am),.admitted_arid(aid),.admitted_internal_id(iid),.admitted_target(at),.admitted_arlen(alen),.target_arvalid(tv),.target_arid(tid),.target_araddr(),.target_arlen(tl),.target_arsize(ts),.target_arburst(tb),.target_arlock(tlk),.target_arcache(tc),.target_arprot(tp),.target_arqos(tq),.target_arregion(tr),.target_ar_fire(tf));
  task automatic ck(input logic c,input string s); begin checks++; if(!c) begin $display("FAIL %0s",s); $fatal(1); end end endtask
  initial begin v=0;legal=7;match=0;id='0;addr='0;len='0;size='0;burst='0;lock='0;cache='0;qos='0;region='0;ready=0; repeat(2) @(posedge ACLK); ARESETn=1; @(posedge ACLK); v[1]=1;match[1]=1;id[1]=4'hc;addr[1]=32'hfffffff8;len[1]=0;size[1]=3;burst[1]=1; @(posedge ACLK); #1; ck(tv&&tid==6'b01_1100&&at==4'b1000,"S3 AR transport"); $display("PASS axi_ar_s3_tb checks=%0d",checks); $finish; end
endmodule
