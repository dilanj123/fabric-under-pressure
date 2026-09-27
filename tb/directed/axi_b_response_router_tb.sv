module axi_b_response_router_tb;
  logic ACLK = 0;
  always #5 ACLK = ~ACLK;
  logic ARESETn;
  logic [3:0] target_bvalid, target_bready, target_b_fire;
  logic [3:0][5:0] target_bid;
  logic [3:0][1:0] target_bresp;
  logic [2:0][15:0] busy_bitmap;
  logic [2:0] manager_bvalid, manager_bready, manager_b_fire;
  logic [2:0][3:0] manager_bid, b_complete_id;
  logic [2:0][1:0] manager_bresp;
  logic [2:0] b_complete_fire, slot_valid;
  logic [3:0] invalid_manager_violation, nonbusy_id_violation;
  logic [2:0] response_admit_fire;
  logic [2:0][1:0] slot_source_target;
  integer checks=0;

  axi_b_response_router dut (.*);

  task automatic check(input logic condition, input string message);
    begin checks=checks+1; if (!condition) begin $display("FAIL: %s",message); $fatal(1); end end
  endtask
  task automatic clear_inputs;
    begin
      target_bvalid=0; target_bid='0; target_bresp='0; busy_bitmap='0;
      manager_bready=0;
    end
  endtask
  task automatic tick; begin @(posedge ACLK); #1; end endtask
  task automatic reset_router;
    begin clear_inputs(); ARESETn=0; tick(); tick(); ARESETn=1; end
  endtask

  initial begin
    reset_router();
    // All four targets contend for one manager. The slot admits S0 first.
    busy_bitmap[0][0]=1; busy_bitmap[0][1]=1; busy_bitmap[0][2]=1; busy_bitmap[0][3]=1;
    target_bvalid=4'b1111;
    target_bid[0]={2'b00,4'h0}; target_bid[1]={2'b00,4'h1};
    target_bid[2]={2'b00,4'h2}; target_bid[3]={2'b00,4'h3};
    target_bresp[0]=2'b00; target_bresp[1]=2'b10; target_bresp[2]=2'b11; target_bresp[3]=2'b00;
    tick();
    check(target_bready==4'b0001 && target_b_fire==4'b0001, "RR admits S0 first");
    tick();
    check(manager_bvalid[0] && manager_bid[0]==4'h0 && manager_bresp[0]==2'b00,
          "manager slot captures stripped BID and BRESP");
    check(b_complete_fire==0 && busy_bitmap[0][0], "target admission does not complete write");
    target_bresp[0]=2'b11; target_bid[0]={2'b00,4'hf};
    check(manager_bvalid[0] && manager_bid[0]==4'h0 && manager_bresp[0]==2'b00 &&
          target_bready==0, "manager stall holds slot and blocks overwrite");
    manager_bready[0]=1; #1; check(manager_b_fire[0] && b_complete_fire[0] && b_complete_id[0]==0,
                                    "manager handshake is completion event");
    tick(); check(!manager_bvalid[0], "manager completion clears slot");
    target_bvalid[0]=0;
    tick(); check(target_bready==4'b0010 && target_b_fire==4'b0010, "RR selects S1");
    tick(); check(manager_bid[0]==4'h1 && manager_bresp[0]==2'b10, "S1 response preserved");

    // Regression for the occupied-slot overwrite bug: a held response for
    // the same manager must not be preselected or admitted while B stalls.
    reset_router();
    busy_bitmap[0][0]=1; busy_bitmap[0][1]=1;
    target_bvalid=4'b0011;
    target_bid[0]={2'b00,4'h0}; target_bid[1]={2'b00,4'h1};
    target_bresp[0]=2'b00; target_bresp[1]=2'b10;
    tick(); check(target_bready==4'b0001 && target_b_fire==4'b0001,
                  "overwrite regression admits first response");
    tick();
    check(slot_valid[0] && slot_source_target[0]==2'b00 && manager_bid[0]==4'h0,
          "overwrite regression fills S0 slot");
    manager_bready[0]=0;
    repeat (4) begin
      #1;
      check(!target_bready[1] && !target_b_fire[1],
            "occupied slot blocks pending S1 handshake");
      check(slot_valid[0] && slot_source_target[0]==2'b00 && manager_bid[0]==4'h0 &&
            manager_bresp[0]==2'b00 && !manager_b_fire[0] && !response_admit_fire[0],
            "occupied slot remains stable without completion");
      tick();
    end
    manager_bready[0]=1;
    #1; check(manager_b_fire[0] && b_complete_fire[0] && !response_admit_fire[0],
              "stalled slot completes without same-cycle refill");
    tick();
    check(!manager_bvalid[0] && !target_b_fire[1],
          "slot drains before pending response is reconsidered");
    tick(); check(target_bready[1] && target_b_fire[1],
              "pending response resumes after slot becomes empty");
    tick(); check(manager_bid[0]==4'h1 && manager_bresp[0]==2'b10,
                  "pending response reaches manager after stall");

    // Repeat with all other target sources pending for the occupied manager.
    reset_router();
    busy_bitmap[0][0]=1; busy_bitmap[0][1]=1; busy_bitmap[0][2]=1; busy_bitmap[0][3]=1;
    target_bvalid=4'b1111;
    target_bid[0]={2'b00,4'h0}; target_bid[1]={2'b00,4'h1};
    target_bid[2]={2'b00,4'h2}; target_bid[3]={2'b00,4'h3};
    tick(); check(target_bready==4'b0001 && target_b_fire==4'b0001,
                  "all-pending regression admits first response");
    tick(); manager_bready[0]=0;
    repeat (4) begin
      #1;
      check(target_bready==4'b0000 && target_b_fire==4'b0000 &&
            manager_bvalid[0] && manager_bid[0]==4'h0 && slot_source_target[0]==2'b00,
            "all pending responses blocked by occupied slot");
      tick();
    end
    manager_bready[0]=1; #1; check(manager_b_fire[0] && !response_admit_fire[0],
                                    "all-pending slot completion has no refill");
    tick(); check(!manager_bvalid[0], "all-pending slot drains cleanly");

    // Invalid prefix and non-busy ID are rejected.
    reset_router();
    target_bvalid[0]=1; target_bid[0]={2'b11,4'h4}; target_bresp[0]=2'b00;
    #1; check(invalid_manager_violation[0] && !target_bready[0], "invalid prefix rejected");
    target_bid[0]={2'b01,4'h4};
    #1; check(nonbusy_id_violation[0] && !target_bready[0], "nonbusy ID rejected");

    // Responses to different managers are admitted concurrently.
    reset_router();
    busy_bitmap[0][5]=1; busy_bitmap[1][5]=1; busy_bitmap[2][5]=1;
    target_bvalid=4'b0111;
    target_bid[0]={2'b00,4'h5}; target_bid[1]={2'b01,4'h5}; target_bid[2]={2'b10,4'h5};
    target_bresp[0]=2'b00; target_bresp[1]=2'b10; target_bresp[2]=2'b11;
    tick(); check(target_bready==4'b0111,
                  "different-manager B responses admit concurrently");
    tick();
    check(manager_bvalid==3'b111 && manager_bid[0]==5 && manager_bid[1]==5 && manager_bid[2]==5 &&
          manager_bresp[0]==2'b00 && manager_bresp[1]==2'b10 && manager_bresp[2]==2'b11,
          "same visible ID returns to correct managers");

    // S3 is transported as an ordinary valid response source.
    reset_router();
    busy_bitmap[2][7]=1; target_bvalid[3]=1; target_bid[3]={2'b10,4'h7}; target_bresp[3]=2'b11;
    tick(); check(target_bready[3] && target_b_fire[3], "S3 response transport");
    tick(); check(manager_bvalid[2] && manager_bid[2]==4'h7 && manager_bresp[2]==2'b11,
                  "S3 response reaches manager");

    // Reset clears occupied slots and prevents completion events.
    ARESETn=0; #1; check(manager_bvalid==0 && b_complete_fire==0, "reset clears B slots");
    tick(); ARESETn=1;
    $display("PASS axi_b_response_router_tb checks=%0d", checks);
    $finish;
  end
endmodule
