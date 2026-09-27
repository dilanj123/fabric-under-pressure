module axi_r_response_router_tb;
  logic ACLK=0, ARESETn=0; always #5 ACLK=~ACLK;
  integer checks=0;
  logic [3:0] tv, trlast;
  logic [3:0][5:0] trid;
  logic [3:0][63:0] tdata;
  logic [3:0][1:0] tresp;
  logic [3:0] tready, tfire, invalid, nonbusy, locked;
  logic [2:0][15:0] busy;
  logic [2:0] mv, mr, mfire, complete, slot, lock;
  logic [2:0][3:0] mid, complete_id;
  logic [2:0][63:0] mdata;
  logic [2:0][1:0] mresp, source, lock_target;
  logic [2:0] mlast, mready;
  logic [2:0][5:0] lock_id;

  axi_r_response_router dut(
    .ACLK(ACLK), .ARESETn(ARESETn),
    .target_rvalid(tv), .target_rid(trid), .target_rdata(tdata),
    .target_rresp(tresp), .target_rlast(trlast), .target_rready(tready),
    .target_r_fire(tfire), .busy_bitmap(busy),
    .manager_rvalid(mv), .manager_rid(mid), .manager_rdata(mdata),
    .manager_rresp(mresp), .manager_rlast(mlast), .manager_rready(mready),
    .manager_r_fire(mfire), .r_complete_fire(complete),
    .r_complete_id(complete_id), .invalid_manager_violation(invalid),
    .nonbusy_id_violation(nonbusy), .locked_rid_violation(locked),
    .response_admit_fire(), .slot_valid(slot), .slot_source_target(source),
    .lock_active(lock), .lock_target(lock_target), .lock_internal_id(lock_id)
  );

  task automatic ck(input logic c, input string s);
    begin checks++; if (!c) begin $display("FAIL %0s",s); $fatal(1); end end
  endtask
  task automatic tick; begin @(posedge ACLK); #1; end endtask
  task automatic clear_inputs;
    integer i;
    begin
      tv='0; trlast='0; trid='0; tdata='0; tresp='0; mready='0;
      for (i=0;i<4;i=i+1) begin trid[i]=6'b0; tdata[i]=64'b0; tresp[i]=2'b0; end
    end
  endtask
  task automatic reset_all;
    begin
      clear_inputs(); busy='0; ARESETn=0; repeat(2) tick(); ARESETn=1; tick();
    end
  endtask
  task automatic set_resp(input integer t, input logic [5:0] id, input logic [63:0] d,
                          input logic [1:0] r, input logic last);
    begin
      trid[t]=id[5:0]; tdata[t]=d; tresp[t]=r; trlast[t]=last; tv[t]=1'b1;
    end
  endtask

  initial begin
    reset_all();

    // First beat establishes source/RID lock only after a real target handshake.
    busy[0][5]=1'b1;
    set_resp(0, 6'b00_0101, 64'hA0, 2'b00, 1'b0);
    tick(); ck(tready[0] && tfire[0], "first target handshake");
    tick(); ck(mv[0] && mdata[0]==64'hA0 && mid[0]==4'h5 &&
                    !mlast[0] && lock[0] && lock_target[0]==0 &&
                    lock_id[0]==6'b00_0101, "first slot and lock");

    // Manager stall holds the registered beat and blocks target traffic.
    mready[0]=0; set_resp(1, 6'b00_0101, 64'hB0, 2'b10, 1'b1);
    #1; ck(tready[0]==0 && mv[0] && mdata[0]==64'hA0 &&
           mresp[0]==2'b00 && source[0]==0, "manager stall blocks other target");
    repeat(3) begin tick(); ck(mv[0] && mdata[0]==64'hA0 && !tfire[1], "stall stability"); end

    // Non-final drain/refill from the locked source is allowed.
    tv[1]=0; mready[0]=1; set_resp(0, 6'b00_0101, 64'hA1, 2'b10, 1'b0);
    #1; ck(tready[0] && tfire[0] && mfire[0] && !complete[0], "nonfinal drain refill");
    tick(); ck(mv[0] && mdata[0]==64'hA1 && mresp[0]==2'b10 && !mlast[0] && lock[0], "refilled slot");

    // Gap in locked source: other target cannot interleave.
    tv[0]=0; set_resp(1, 6'b00_0101, 64'hC0, 2'b00, 1'b1);
    #1; ck(!tready[1], "locked gap blocks other source"); tick();
    ck(!mv[0] && lock[0], "empty locked slot");
    tv[0]=1; trid[0]=6'b00_0101; tdata[0]=64'hA2; tresp[0]=2'b00; trlast[0]=1;
    #1; ck(tready[0] && !tready[1], "locked source ready"); tick(); ck(mv[0] && mdata[0]==64'hA2 && mlast[0], "locked source resumes");

    // Final beat cannot drain/refill and completes only at manager handshake.
    set_resp(1, 6'b00_0101, 64'hC1, 2'b00, 1'b1); mready[0]=0; #1;
    ck(tready[1]==0 && lock[0] && !complete[0], "final slot blocks refill");
    mready[0]=1; #1; ck(mfire[0] && complete[0] && complete_id[0]==4'h5, "manager RLAST completion");
    tick(); ck(!mv[0] && !lock[0], "final clears slot and lock");

    // Invalid prefix and nonbusy ID are rejected.
    reset_all(); set_resp(0, 6'b11_0001, 64'hD0, 2'b11, 1'b1); #1;
    ck(invalid[0] && !tready[0], "invalid prefix rejected"); tick(); ck(!mv[0], "invalid prefix no slot");
    clear_inputs(); busy[0][2]=0; set_resp(0, 6'b00_0010, 64'hD1, 2'b10, 1'b1); #1;
    ck(nonbusy[0] && !tready[0], "nonbusy ID rejected"); tick(); ck(!mv[0], "nonbusy no slot");

    // Locked RID change is diagnosed and held, then the valid stream resumes.
    reset_all(); busy[0][5]=1; busy[0][6]=1; set_resp(0, 6'b00_0101, 64'hE0, 2'b00, 1'b0); tick(); tick();
    mready[0]=1; tv[0]=0; tick(); ck(!mv[0] && lock[0], "lock survives consumed nonfinal");
    set_resp(0, 6'b00_0110, 64'hE1, 2'b00, 1'b0); #1; ck(locked[0] && !tready[0], "locked RID violation");
    trid[0]=6'b00_0101; tdata[0]=64'hE2; trlast[0]=1; #1; ck(tready[0], "restored locked RID ready"); tick();
    mready[0]=1; #1; ck(complete[0], "locked burst completion"); tick();

    // Four-target initial contention and RR order after completion.
    reset_all(); busy[0][0]=1; busy[0][1]=1; busy[0][2]=1; busy[0][3]=1;
    set_resp(0,6'b00_0000,64'h10,2'b00,1); set_resp(1,6'b00_0001,64'h11,2'b10,1);
    set_resp(2,6'b00_0010,64'h12,2'b11,1); set_resp(3,6'b00_0011,64'h13,2'b00,1);
    tick(); #1; ck(tready[0] && !tready[1] && !tready[2] && !tready[3], "RR first target"); tick();
    mready[0]=1; #1; ck(complete[0], "first RR response completion"); tick();
    tv[0]=0; tick(); ck(tready[1], "RR advances to second target"); tick(); ck(mid[0]==1 && mresp[0]==2'b10, "second target response");

    // Different IDs may complete out of issue order.
    reset_all(); busy[0][2]=1; busy[0][9]=1;
    set_resp(0,6'b00_1001,64'h91,2'b00,1); set_resp(1,6'b00_0010,64'h92,2'b10,1);
    tick(); tick(); ck(mid[0]==4'h9 && mdata[0]==64'h91, "different-ID out-of-order first response");
    mready[0]=1; #1; ck(complete[0], "out-of-order first completion"); tick(); tv[0]=0; tick(); ck(tready[1], "out-of-order second target ready"); tick();
    ck(mid[0]==4'h2 && mdata[0]==64'h92 && mresp[0]==2'b10, "different-ID out-of-order second response");

    // Different managers can accept concurrently, including same visible ID.
    reset_all(); busy[0][5]=1; busy[1][5]=1; busy[2][5]=1;
    set_resp(0,6'b00_0101,64'h20,2'b00,1); set_resp(1,6'b01_0101,64'h21,2'b10,1); set_resp(2,6'b10_0101,64'h22,2'b11,1);
    tick(); tick(); ck(mv==3'b111 && mid[0]==5 && mid[1]==5 && mid[2]==5 &&
                        mresp[0]==2'b00 && mresp[1]==2'b10 && mresp[2]==2'b11, "manager concurrency and ID strip");

    // S3 DECERR transport.
    mready=3'b111; tick(); reset_all(); busy[2][4]=1; set_resp(3,6'b10_0100,64'h30,2'b11,1); tick(); tick();
    ck(mv[2] && mid[2]==4 && mdata[2]==64'h30 && mresp[2]==2'b11 && mlast[2], "S3 DECERR transport");

    // Reset clears a stalled slot and lock.
    mready='0; ARESETn=0; #1; ck(!mv[2] && !lock[2], "reset clears R state"); ARESETn=1; tick();
    $display("PASS axi_r_response_router_tb checks=%0d",checks); $finish;
  end
endmodule
