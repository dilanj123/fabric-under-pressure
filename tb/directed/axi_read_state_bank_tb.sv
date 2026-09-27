module axi_read_state_bank_tb;
 logic ACLK=0,ARESETn=0; always #5 ACLK=~ACLK; integer checks=0;
 logic [2:0][3:0] req,aid,atarget; logic [2:0][7:0] alen; logic [2:0] af,cf; logic [2:0][3:0] cid;
 logic [2:0] allow,viol,commit; logic [2:0][15:0] busy; logic [2:0][2:0] count;
 axi_read_state_bank dut(.ACLK(ACLK),.ARESETn(ARESETn), .request_arid(req),.ar_admit_fire(af),.ar_admit_id(aid),.ar_admit_target(atarget),.ar_admit_len(alen),.r_complete_fire(cf),.r_complete_id(cid),.outstanding_allowed(allow),.busy_bitmap(busy),.outstanding_count(count),.admission_state_violation(viol),.outstanding_violation(),.commit_fire(commit));
 task automatic ck(input logic c,input string s); begin checks++; if(!c) begin $display("FAIL %0s",s); $fatal(1); end end endtask
 task automatic tick; begin @(posedge ACLK); #1; end endtask
 task automatic alloc(input integer m,input integer x); begin req[m]=4'(x); af='0; aid='0; aid[m]=4'(x); atarget='0; alen='0; af[m]=1; tick(); af='0; end endtask
 initial begin req='0; af='0; aid='0; atarget='0; alen='0; cf='0; cid='0; repeat(2) @(posedge ACLK); ARESETn=1; tick(); ck(count=='0,"reset");
   req='0; alloc(0,1); ck(busy[0][1]&&count[0]==1,"allocate M0"); ck(!allow[0],"duplicate blocked"); req[0]=2; #1;  ck(allow[0],"different ID allowed");
   alloc(0,2); alloc(0,3); alloc(0,4); ck(count[0]==4,"four reads"); req[0]=5; #1; ck(!allow[0],"fifth blocked");
   cf[0]=1; cid[0]=1; #1; ck(!allow[0],"completion no same-cycle credit"); tick(); cf='0; ck(count[0]==3&&!busy[0][1],"completion clears");
   req[0]=1; #1; ck(allow[0],"following cycle reuse"); alloc(1,1); alloc(2,1); ck(busy[1][1]&&busy[2][1],"manager independence");
   req[0]=6; req[1]=7; req[2]=8; aid[0]=6; aid[1]=7; aid[2]=8; af=3'b111; tick(); af='0; ck(busy[0][6]&&busy[1][7]&&busy[2][8],"simultaneous manager admissions");
   req[0]=2; af[0]=1; aid[0]=2; #1; ck(viol[0]&&commit[0]==0,"invalid direct admission"); tick(); af='0; ck(count[0]==4,"invalid no mutation");
   cf='0; cid='0; cid[1]=1; cf[1]=1; tick(); tick(); cf='0; ck(!busy[1][1]&&busy[1][7]&&count[1]==1,"known completion");
   $display("PASS axi_read_state_bank_tb checks=%0d",checks); $finish; end
endmodule
