module axi_read_write_id_independence_tb;
  logic ACLK=0,ARESETn=0; always #5 ACLK=~ACLK;
  logic [2:0][3:0] rid,aid,ridc; logic [2:0][7:0] rlen,alen; logic [2:0][3:0] rt,at; logic [2:0][5:0] aii;
  logic [2:0] raf,rcf,waf,wf,wl,bf; logic [2:0][3:0] rcid,bcid; logic [2:0] rallow,wallow; logic [2:0][15:0] rbusy,wbusy; logic [2:0][2:0] rcount,wcount; logic [2:0] rv,wv,rvio,wvio,commit;
  logic [2:0][3:0] owner_target,owner_id; logic [2:0][5:0] owner_iid; logic [2:0][4:0] beats; logic [2:0] active,expected,state_allowed,admitvio,ovio,owner_vio;
  axi_read_state_bank rb(.ACLK,.ARESETn,.request_arid(rid),.ar_admit_fire(raf),.ar_admit_id(aid),.ar_admit_target(rt),.ar_admit_len(rlen),.r_complete_fire(rcf),.r_complete_id(rcid),.outstanding_allowed(rallow),.busy_bitmap(rbusy),.outstanding_count(rcount),.admission_state_violation(rvio),.outstanding_violation(),.commit_fire());
  axi_write_state_bank wb(.ACLK,.ARESETn,.request_awid(rid),.aw_admit_fire(waf),.aw_admit_id(aid),.aw_admit_internal_id(aii),.aw_admit_target(at),.aw_admit_len(alen),.w_fire(wf),.wlast(wl),.b_complete_fire(bf),.b_complete_id(bcid),.outstanding_allowed(wallow),.busy_bitmap(wbusy),.outstanding_count(wcount),.owner_active(active),.owner_target, .owner_id, .owner_internal_id(owner_iid),.owner_beats_remaining(beats),.owner_expected_wlast(expected),.state_allowed,.commit_fire(commit),.admission_state_violation(admitvio),.outstanding_violation(ovio),.owner_violation(owner_vio));
  integer checks=0; task automatic ck(input logic c,input string s); begin checks++; if(!c) begin $display("FAIL %0s",s); $fatal(1); end end endtask
  initial begin rid='0; aid='0; ridc='0; rlen='0; alen='0; rt='0; at='0; aii='0; raf=0;rcf=0;waf=0;wf=0;wl=0;bf=0;rcid='0;bcid='0; repeat(2) @(posedge ACLK); ARESETn=1; @(posedge ACLK);
    rid[0]=4'h7; aid[0]=4'h7; at[0]=4'b0001; rt[0]=4'b0001; aii[0]=6'h07; alen[0]=0; rlen[0]=0; waf[0]=1; raf[0]=1; @(posedge ACLK); #1; waf=0;raf=0; ck(wbusy[0][7]&&rbusy[0][7],"same numeric read/write ID coexistence"); ck(wcount[0]==1&&rcount[0]==1,"independent counts"); $display("PASS axi_read_write_id_independence_tb checks=%0d",checks); $finish; end
endmodule
