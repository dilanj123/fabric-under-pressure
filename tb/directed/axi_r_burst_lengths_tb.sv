module axi_r_burst_lengths_tb;
  logic ACLK=0, ARESETn=0; always #5 ACLK=~ACLK;
  logic [3:0] tv,rlast,tready,tfire,invalid,nonbusy,locked;
  logic [3:0][5:0] rid; logic [3:0][63:0] data; logic [3:0][1:0] resp;
  logic [2:0][15:0] busy; logic [2:0] mv,mready,mfire,complete,slot,lock,mlast;
  logic [2:0][3:0] mid,complete_id; logic [2:0][63:0] mdata; logic [2:0][1:0] mresp,source,lock_target; logic [2:0][5:0] lock_id;
  integer checks=0;
  axi_r_response_router dut(.ACLK,.ARESETn,.target_rvalid(tv),.target_rid(rid),.target_rdata(data),.target_rresp(resp),.target_rlast(rlast),.target_rready(tready),.target_r_fire(tfire),.busy_bitmap(busy),.manager_rvalid(mv),.manager_rid(mid),.manager_rdata(mdata),.manager_rresp(mresp),.manager_rlast(mlast),.manager_rready(mready),.manager_r_fire(mfire),.r_complete_fire(complete),.r_complete_id(complete_id),.invalid_manager_violation(invalid),.nonbusy_id_violation(nonbusy),.locked_rid_violation(locked),.response_admit_fire(),.slot_valid(slot),.slot_source_target(source),.lock_active(lock),.lock_target,.lock_internal_id(lock_id));
  task automatic ck(input logic c,input string s); begin checks++; if(!c) begin $display("FAIL %0s",s); $fatal(1); end end endtask
  task automatic tick; begin @(posedge ACLK); #1; end endtask
  task automatic clear_inputs; begin tv='0; rlast='0; rid='0; data='0; resp='0; mready='0; end endtask
  task automatic reset_all; begin clear_inputs(); busy='0; ARESETn=0; repeat(2) tick(); ARESETn=1; tick(); end endtask
  task automatic run_burst(input integer beats, input integer id_base);
    integer i;
    begin
      reset_all(); busy[0][id_base]=1; rid[0]=id_base[5:0]; tv[0]=1; data[0]=64'h1000; resp[0]=2'b00; rlast[0]=(beats==1);
      tick(); ck(tready[0] && tfire[0], "initial burst target fire"); tick();
      ck(mv[0] && lock[0], "burst lock established");
      mready[0]=1;
      for (i=1; i<beats; i=i+1) begin
        rid[0]=id_base[5:0]; data[0]=64'h1000+64'(i); resp[0]=i[1:0]; rlast[0]=(i==beats-1); tv[0]=1;
        #1; ck(tready[0] && tfire[0] && mfire[0], "full-rate non-final delivery");
        tick(); ck(mv[0] && mdata[0]==64'h1000+64'(i), "burst data order");
      end
      tv[0]=0; #1; ck(mlast[0] && complete[0] && mid[0]==id_base[3:0], "burst final completion"); tick();
      ck(!lock[0] && !mv[0], "burst lock release");
    end
  endtask
  initial begin
    run_burst(2,1); run_burst(4,3); run_burst(16,5);
    $display("PASS axi_r_burst_lengths_tb checks=%0d",checks); $finish;
  end
endmodule
