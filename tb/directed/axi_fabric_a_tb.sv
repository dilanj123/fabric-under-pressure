module axi_fabric_a_tb;
  logic ACLK = 0, ARESETn = 0;
  always #5 ACLK = ~ACLK;

  logic [2:0][3:0] awid, arid;
  logic [2:0][31:0] awaddr, araddr;
  logic [2:0][7:0] awlen, arlen;
  logic [2:0][2:0] awsize, arsize, awprot, arprot;
  logic [2:0][1:0] awburst, arburst;
  logic [2:0] awlock, arlock, awvalid, arvalid;
  logic [2:0][3:0] awcache, awqos, awregion, arcache, arqos, arregion;
  logic [2:0] awready, arready;
  logic [2:0][63:0] wdata;
  logic [2:0][7:0] wstrb;
  logic [2:0] wlast, wvalid, wready;
  logic [2:0][3:0] bid, rid;
  logic [2:0][1:0] bresp, rresp;
  logic [2:0] bvalid, bready, rlast, rvalid, rready;
  logic [2:0][63:0] rdata;

  logic [2:0][5:0] tawid, tarid, tbid, trid;
  logic [2:0][31:0] tawaddr, taraddr;
  logic [2:0][7:0] tawlen, tarlan;
  logic [2:0][2:0] tawsize, tarsize, tawprot, tarprot;
  logic [2:0][1:0] tawburst, tarburst;
  logic [2:0] tawlock, tarlock, tawvalid, tarvalid, twlast, twvalid, tbvalid, trlast, trvalid;
  logic [2:0][3:0] tawcache, tawqos, tawregion, tarcache, tarqos, tarregion;
  logic [2:0][63:0] twdata, trdata;
  logic [2:0][7:0] twstrb;
  logic [2:0][1:0] tbresp, trresp;
  logic [2:0] tawready, twready, tbready, tarready, trready;

  integer checks = 0;
  logic [2:0] ext_aw_seen;
  logic [2:0][5:0] ext_bid_q, ext_rid_q;
  logic [2:0] ext_bvalid_q, ext_rvalid_q;
  logic [2:0][4:0] ext_rbeats_q;
  logic [2:0] ext_rlast_q;
  logic r_gap_s0;
  logic b_hold_s0;
  logic fairness_ar_record, fairness_aw_record;
  integer fairness_ar_count, fairness_aw_count, fairness_cycle;
  integer fairness_ar_manager [0:8], fairness_ar_cycle [0:8];
  integer fairness_aw_manager [0:8], fairness_aw_cycle [0:8];
  logic [3:0] fairness_ar_id [0:8], fairness_aw_id [0:8];
  integer fairness_wlast_count;
  logic [2:0] fairness_w_pending;
  integer fairness_aw_accepted [0:2];
  integer fairness_wlast_by_manager [0:2];
  integer fairness_b_count;
  logic [2:0] fairness_aw_clear, fairness_w_start, fairness_w_clear;
  logic fairness_s0_owner_active;
  integer fairness_owner_overlap_count, fairness_owner_wlast_without_aw;

  // Public manager-side admissions are captured at the accepting edge,
  // before DUT nonblocking state updates.
  always @(posedge ACLK) begin
    fairness_cycle <= fairness_cycle + 1;
    if (!ARESETn) begin
      fairness_ar_count <= 0;
      fairness_aw_count <= 0;
      fairness_b_count <= 0;
      fairness_aw_clear <= '0;
      fairness_w_start <= '0;
      fairness_w_clear <= '0;
      fairness_w_pending <= '0;
      fairness_wlast_count <= 0;
      fairness_s0_owner_active <= 0;
      fairness_owner_overlap_count <= 0;
      fairness_owner_wlast_without_aw <= 0;
      for (integer fm=0; fm<3; fm=fm+1) begin
        fairness_aw_accepted[fm] <= 0;
        fairness_wlast_by_manager[fm] <= 0;
      end
    end else begin
      integer b_fires;
      b_fires = 0;
      for (integer fm=0; fm<3; fm=fm+1) begin
        if (fairness_ar_record && arvalid[fm] && arready[fm] && fairness_ar_count<9) begin
          fairness_ar_manager[fairness_ar_count] <= fm;
          fairness_ar_id[fairness_ar_count] <= arid[fm];
          fairness_ar_cycle[fairness_ar_count] <= fairness_cycle;
          $display("FAIR_AR cycle=%0d m=%0d valid=%b ready=%b id=%0d s0v=%b s0r=%b count=%0d",
                   fairness_cycle,fm,arvalid[fm],arready[fm],arid[fm],tarvalid[0],tarready[0],fairness_ar_count);
          fairness_ar_count <= fairness_ar_count + 1;
        end
        if (fairness_aw_record && awvalid[fm] && awready[fm] && fairness_aw_count<9) begin
          fairness_aw_manager[fairness_aw_count] <= fm;
          fairness_aw_id[fairness_aw_count] <= awid[fm];
          fairness_aw_cycle[fairness_aw_count] <= fairness_cycle;
          $display("FAIR_AW cycle=%0d m=%0d valid=%b ready=%b id=%0d s0v=%b s0r=%b wlast_fire=%b count=%0d",
                   fairness_cycle,fm,awvalid[fm],awready[fm],awid[fm],tawvalid[0],tawready[0],
                   twvalid[0]&&twready[0]&&twlast[0],fairness_aw_count);
          fairness_aw_count <= fairness_aw_count + 1;
          fairness_aw_accepted[fm] <= fairness_aw_accepted[fm] + 1;
          fairness_aw_clear[fm] <= 1;
          fairness_w_pending[fm] <= 1;
        end
        if (fairness_aw_record && wvalid[fm] && wready[fm]) begin
          $display("FAIR_W cycle=%0d m=%0d fire=1 last=%b s0v=%b s0r=%b pending=%b",
                   fairness_cycle,fm,wlast[fm],twvalid[0],twready[0],fairness_w_pending[fm]);
          fairness_w_clear[fm] <= 1;
        end
        if (fairness_aw_record && bvalid[fm] && bready[fm]) begin
          b_fires = b_fires + 1;
          $display("FAIR_B cycle=%0d m=%0d id=%0d resp=%0d",fairness_cycle,fm,bid[fm],bresp[fm]);
        end
      end
      // Wait for actual delivery to S0 before offering this test's W beat.
      // This avoids making the simple endpoint model infer an AW context from
      // a manager-side admission that has not yet crossed the target port.
      if (fairness_aw_record && tawvalid[0] && tawready[0]) begin
        if (fairness_s0_owner_active)
          fairness_owner_overlap_count <= fairness_owner_overlap_count + 1;
        fairness_s0_owner_active <= 1;
        fairness_w_start[tawid[0][5:4]] <= 1;
        $display("FAIR_TAW cycle=%0d id=%0d m=%0d",fairness_cycle,tawid[0],tawid[0][5:4]);
      end
      if (fairness_aw_record && twvalid[0] && twready[0] && twlast[0]) begin
        if (!fairness_s0_owner_active)
          fairness_owner_wlast_without_aw <= fairness_owner_wlast_without_aw + 1;
        fairness_s0_owner_active <= 0;
        fairness_wlast_count <= fairness_wlast_count + 1;
        fairness_wlast_by_manager[twdata[0][17:16]] <=
            fairness_wlast_by_manager[twdata[0][17:16]] + 1;
        $display("FAIR_TWLAST cycle=%0d m=%0d data=%h ext_aw_seen=%b",fairness_cycle,
                 twdata[0][17:16],twdata[0],ext_aw_seen[0]);
      end
      if (b_fires != 0) fairness_b_count <= fairness_b_count + b_fires;
    end
  end

`ifdef ARCHITECTURE_B
  axi_fabric_b dut (.*,
`else
  axi_fabric_a dut (.*,
`endif
    .manager_awid(awid), .manager_awaddr(awaddr), .manager_awlen(awlen), .manager_awsize(awsize),
    .manager_awburst(awburst), .manager_awlock(awlock), .manager_awcache(awcache), .manager_awprot(awprot),
    .manager_awqos(awqos), .manager_awregion(awregion), .manager_awvalid(awvalid), .manager_awready(awready),
    .manager_wdata(wdata), .manager_wstrb(wstrb), .manager_wlast(wlast), .manager_wvalid(wvalid), .manager_wready(wready),
    .manager_bid(bid), .manager_bresp(bresp), .manager_bvalid(bvalid), .manager_bready(bready),
    .manager_arid(arid), .manager_araddr(araddr), .manager_arlen(arlen), .manager_arsize(arsize), .manager_arburst(arburst),
    .manager_arlock(arlock), .manager_arcache(arcache), .manager_arprot(arprot), .manager_arqos(arqos), .manager_arregion(arregion),
    .manager_arvalid(arvalid), .manager_arready(arready), .manager_rid(rid), .manager_rdata(rdata), .manager_rresp(rresp),
    .manager_rlast(rlast), .manager_rvalid(rvalid), .manager_rready(rready),
    .target_awid(tawid), .target_awaddr(tawaddr), .target_awlen(tawlen), .target_awsize(tawsize), .target_awburst(tawburst),
    .target_awlock(tawlock), .target_awcache(tawcache), .target_awprot(tawprot), .target_awqos(tawqos), .target_awregion(tawregion),
    .target_awvalid(tawvalid), .target_awready(tawready), .target_wdata(twdata), .target_wstrb(twstrb), .target_wlast(twlast),
    .target_wvalid(twvalid), .target_wready(twready), .target_bid(tbid), .target_bresp(tbresp), .target_bvalid(tbvalid),
    .target_bready(tbready), .target_arid(tarid), .target_araddr(taraddr), .target_arlen(tarlan), .target_arsize(tarsize),
    .target_arburst(tarburst), .target_arlock(tarlock), .target_arcache(tarcache), .target_arprot(tarprot), .target_arqos(tarqos),
    .target_arregion(tarregion), .target_arvalid(tarvalid), .target_arready(tarready), .target_rid(trid), .target_rdata(trdata),
    .target_rresp(trresp), .target_rlast(trlast), .target_rvalid(trvalid), .target_rready(trready));

  initial begin tawready = 3'b111; twready = 3'b111; tarready = 3'b111; end

  always_comb begin
    tbvalid = ext_bvalid_q;
    if (b_hold_s0) tbvalid[0] = 1'b0;
    tbid = ext_bid_q;
    tbresp = '0;
    trvalid = ext_rvalid_q;
    if (r_gap_s0) trvalid[0] = 1'b0;
    trid = ext_rid_q;
    trdata = '0;
    trresp = '0;
    trlast = ext_rlast_q;
  end

  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      ext_aw_seen <= '0; ext_bid_q <= '0; ext_bvalid_q <= '0;
      ext_rid_q <= '0; ext_rvalid_q <= '0; ext_rbeats_q <= '0; ext_rlast_q <= '0;
    end else begin
      for (integer t=0; t<3; t=t+1) begin
        if (tawvalid[t] && tawready[t]) begin
          ext_aw_seen[t] <= 1'b1;
          ext_bid_q[t] <= tawid[t];
        end
        if (twvalid[t] && twready[t] && twlast[t] && ext_aw_seen[t]) begin
          ext_bvalid_q[t] <= 1'b1;
        end
        if (tbvalid[t] && tbready[t]) begin
          ext_bvalid_q[t] <= 1'b0;
          ext_aw_seen[t] <= 1'b0;
        end
        if (tarvalid[t] && tarready[t]) begin
          ext_rid_q[t] <= tarid[t];
          ext_rbeats_q[t] <= tarlan[t][4:0] + 1'b1;
          ext_rlast_q[t] <= (tarlan[t] == 0);
          ext_rvalid_q[t] <= 1'b1;
        end else if (trvalid[t] && trready[t]) begin
          if (ext_rbeats_q[t] == 1) begin
            ext_rvalid_q[t] <= 1'b0;
            ext_rlast_q[t] <= 1'b0;
          end else begin
            ext_rbeats_q[t] <= ext_rbeats_q[t] - 1'b1;
            ext_rlast_q[t] <= (ext_rbeats_q[t] == 2);
          end
        end
      end
    end
  end

  task automatic check(input logic ok, input string name);
    begin checks = checks + 1; if (!ok) begin $display("FAIL %s", name); $fatal(1); end end
  endtask
  task automatic tick; begin @(posedge ACLK); #1; end endtask

  task automatic reset_dut;
    begin
      awvalid='0; wvalid='0; arvalid='0; bready='0; rready='0;
      tawready='1; twready='1; tarready='1;
      ARESETn=0; repeat(3) tick(); ARESETn=1; repeat(2) tick();
    end
  endtask

  task automatic do_write(input integer m, input integer t, input logic [3:0] id, input integer beats);
    logic [31:0] base; integer n;
    begin
      base = (t==0) ? 32'h0000_0100 : (t==1) ? 32'h1000_0100 : (t==2) ? 32'h2000_0100 : 32'h3000_0100;
      awid[m]=id; awaddr[m]=base; awlen[m]=beats-1; awsize[m]=3; awburst[m]=1; awlock[m]=0; awcache[m]=0; awprot[m]=0; awqos[m]=0; awregion[m]=0; awvalid[m]=1;
      for (n=0; n<100 && !awready[m]; n=n+1) begin tick(); end
      check(awready[m], "AW route ready");
      tick(); awvalid[m]=0;
      for (n=0; n<beats; n=n+1) begin
        wdata[m] = 64'h1000 + n; wstrb[m]=8'hff; wlast[m]=(n==beats-1); wvalid[m]=1;
        for (integer q=0; q<100 && !wready[m]; q=q+1) begin tick(); end
        check(wready[m], "W route ready");
        tick(); wvalid[m]=0;
      end
      bready[m]=1;
      for (n=0; n<100 && !bvalid[m]; n=n+1) begin tick(); end
      check(bvalid[m], "B response available");
      check(bid[m] == id, "write BID restored");
      check(bresp[m] == 2'b00 || (t==3 && bresp[m] == 2'b11), "write BRESP routed");
      tick(); bready[m]=0;
    end
  endtask

  task automatic do_read(input integer m, input integer t, input logic [3:0] id, input integer beats);
    logic [31:0] base; integer n;
    begin
      base = (t==0) ? 32'h0000_0200 : (t==1) ? 32'h1000_0200 : (t==2) ? 32'h2000_0200 : 32'h3000_0200;
      arid[m]=id; araddr[m]=base; arlen[m]=beats-1; arsize[m]=3; arburst[m]=1; arlock[m]=0; arcache[m]=0; arprot[m]=0; arqos[m]=0; arregion[m]=0; arvalid[m]=1;
      for (n=0; n<100 && !arready[m]; n=n+1) begin tick(); end
      check(arready[m], "AR route ready");
      tick(); arvalid[m]=0; rready[m]=1;
      for (n=0; n<beats; n=n+1) begin
        for (integer q=0; q<100 && !rvalid[m]; q=q+1) begin tick(); end
        check(rvalid[m], "R response available");
        check(rid[m] == id, "read RID restored");
        check(rdata[m] == 0, "read data propagated");
        if (n==beats-1) check(rlast[m], "read RLAST final");
        tick();
      end
      rready[m]=0;
    end
  endtask

  task automatic write_without_b(input integer m, input integer t, input logic [3:0] id);
    logic [31:0] base;
    begin
      base = (t==0) ? 32'h0000_0300 : (t==1) ? 32'h1000_0300 : (t==2) ? 32'h2000_0300 : 32'h3000_0300;
      awid[m]=id; awaddr[m]=base; awlen[m]=0; awsize[m]=3; awburst[m]=1; awlock[m]=0; awcache[m]=0; awprot[m]=0; awqos[m]=0; awregion[m]=0; awvalid[m]=1;
      while (!awready[m]) tick(); tick(); awvalid[m]=0;
      wdata[m]=64'h55+id; wstrb[m]=8'hff; wlast[m]=1; wvalid[m]=1;
      while (!wready[m]) tick(); tick(); wvalid[m]=0;
    end
  endtask

  task automatic read_without_r(input integer m, input integer t, input logic [3:0] id);
    logic [31:0] base;
    begin
      base = (t==0) ? 32'h0000_0400 : (t==1) ? 32'h1000_0400 : (t==2) ? 32'h2000_0400 : 32'h3000_0400;
      arid[m]=id; araddr[m]=base; arlen[m]=0; arsize[m]=3; arburst[m]=1; arlock[m]=0; arcache[m]=0; arprot[m]=0; arqos[m]=0; arregion[m]=0; arvalid[m]=1;
      while (!arready[m]) tick(); tick(); arvalid[m]=0;
    end
  endtask

  task automatic test_integrated_ar_fairness;
    integer cycles, m, expected;
    logic [5:0] held_id;
    logic [31:0] held_addr;
    begin
      $display("G3 integrated AR fairness"); reset_dut();
      rready='1; tarready[0]=0; fairness_ar_record=1;
      fairness_ar_count=0;
      for (integer k=0;k<3;k=k+1) begin
        arid[k]=k; araddr[k]=32'h0000_2000 + (k*8); arlen[k]=0;
        arsize[k]=3; arburst[k]=1; arlock[k]=0; arcache[k]=0;
        arprot[k]=0; arqos[k]=0; arregion[k]=0; arvalid[k]=1;
      end
      // Manager admission fills the registered S0 slot.  Hold S0 stalled and
      // verify the selected public target payload remains stable.
      for (integer waitc=0;waitc<40 && !tarvalid[0];waitc=waitc+1) tick();
      check(tarvalid[0], "AR fairness target slot presented");
      held_id=tarid[0]; held_addr=taraddr[0];
      repeat(3) begin
        check(tarvalid[0] && !tarready[0] && tarid[0]==held_id && taraddr[0]==held_addr,
              "AR fairness held target payload stable"); tick();
      end
      tarready[0]=1; cycles=0;
      while (fairness_ar_count<9 && cycles<300) begin
        tick(); cycles=cycles+1;
        for (m=0;m<3;m=m+1) begin
          integer accepted;
          accepted=0;
          for (integer q=0;q<fairness_ar_count;q=q+1)
            if (fairness_ar_manager[q]==m) accepted=accepted+1;
          if (accepted<3 && !arvalid[m]) begin
            arid[m]=accepted; araddr[m]=32'h0000_2100+(m*8)+(accepted*8);
            arlen[m]=0; arsize[m]=3; arburst[m]=1; arlock[m]=0;
            arcache[m]=0; arprot[m]=0; arqos[m]=0; arregion[m]=0; arvalid[m]=1;
          end
        end
      end
      check(fairness_ar_count==9, "AR fairness nine admissions complete");
      fairness_ar_record=0;
      $write("FAIR_AR_ORDER");
      for (integer q=0;q<9;q=q+1) begin
        expected=q%3;
        $write(" %0d",fairness_ar_manager[q]);
        check(fairness_ar_manager[q]==expected, "AR fairness cyclic manager order");
      end
      $write("\n");
      reset_dut();
    end
  endtask

  // Apply monitor results after tick() has returned from the accepting edge.
  // This keeps stimulus changes out of the DUT's sampling region.
  task automatic service_aw_fairness;
    begin
      for (integer fm=0; fm<3; fm=fm+1) begin
        if (fairness_aw_clear[fm]) begin
          awvalid[fm]=0;
          fairness_aw_clear[fm]=0;
        end
        if (fairness_w_start[fm]) begin
          wdata[fm]=64'hA000_0000_0000_0000 + (fm*64'h0000_0000_0001_0000)
                    + fairness_aw_accepted[fm]-1;
          wstrb[fm]=8'hff; wlast[fm]=1; wvalid[fm]=1;
          fairness_w_start[fm]=0;
        end
        if (fairness_w_clear[fm]) begin
          wvalid[fm]=0;
          fairness_w_pending[fm]=0;
          fairness_w_clear[fm]=0;
        end
      end
      // A manager may issue its next address after its prior final target W
      // handshake. B retirement is deliberately independent of AW issuance.
      for (integer fm=0; fm<3; fm=fm+1) begin
        if (fairness_aw_accepted[fm] < 3 && !awvalid[fm] &&
            !fairness_w_pending[fm] &&
            fairness_wlast_by_manager[fm] >= fairness_aw_accepted[fm]) begin
          awid[fm]=fairness_aw_accepted[fm];
          awaddr[fm]=32'h0000_3100+(fm*8)+(fairness_aw_accepted[fm]*8);
          awlen[fm]=0; awsize[fm]=3; awburst[fm]=1; awlock[fm]=0;
          awcache[fm]=0; awprot[fm]=0; awqos[fm]=0; awregion[fm]=0;
          awvalid[fm]=1;
        end
      end
    end
  endtask

  task automatic test_integrated_aw_fairness;
    integer cycles;
    logic [5:0] held_id;
    logic [31:0] held_addr;
    begin
      $display("G3 integrated AW fairness"); reset_dut();
      bready='1; tawready[0]=0; fairness_w_pending='0; fairness_aw_record=1;
      fairness_aw_count=0; fairness_wlast_count=0; fairness_b_count=0;
      fairness_aw_clear='0; fairness_w_start='0; fairness_w_clear='0;
      fairness_s0_owner_active=0; fairness_owner_overlap_count=0;
      fairness_owner_wlast_without_aw=0;
      for (integer k=0;k<3;k=k+1) begin
        fairness_aw_accepted[k]=0; fairness_wlast_by_manager[k]=0;
        awid[k]=0; awaddr[k]=32'h0000_3000+(k*8); awlen[k]=0;
        awsize[k]=3; awburst[k]=1; awlock[k]=0; awcache[k]=0;
        awprot[k]=0; awqos[k]=0; awregion[k]=0; awvalid[k]=1;
      end
      // First manager admission creates the registered target AW slot.
      for (integer waitc=0;waitc<40 && !tawvalid[0];waitc=waitc+1) begin
        tick(); service_aw_fairness();
      end
      check(tawvalid[0], "AW fairness target slot presented");
      held_id=tawid[0]; held_addr=tawaddr[0];
      repeat(3) begin
        check(tawvalid[0] && !tawready[0] && tawid[0]==held_id && tawaddr[0]==held_addr,
              "AW fairness held target payload stable"); tick(); service_aw_fairness();
      end
      tawready[0]=1;
      cycles=0;
      while (fairness_aw_count<9 && cycles<500) begin
        tick(); service_aw_fairness(); cycles=cycles+1;
      end
      check(fairness_aw_count==9, "AW fairness nine admissions complete");
      $write("FAIR_AW_ORDER");
      for (integer q=0;q<9;q=q+1) begin
        $write(" %0d",fairness_aw_manager[q]);
        check(fairness_aw_manager[q]==q%3, "AW fairness cyclic manager order");
      end
      $write("\n");
      // Drain final W/B work; the per-target endpoint model emits B after
      // accepted final target WLAST.  Limit the wait to keep failures clear.
      for (integer drain=0;drain<150 &&
           (fairness_b_count<9 || fairness_wlast_count<9 || fairness_w_pending!='0);drain=drain+1) begin
        tick(); service_aw_fairness();
      end
      fairness_aw_record=0;
      $display("FAIR_AW_DRAIN accepted=%0d wlast=%0d b=%0d pending=%b aw_counts=%0d,%0d,%0d wlast_counts=%0d,%0d,%0d",
               fairness_aw_count,fairness_wlast_count,fairness_b_count,fairness_w_pending,
               fairness_aw_accepted[0],fairness_aw_accepted[1],fairness_aw_accepted[2],
               fairness_wlast_by_manager[0],fairness_wlast_by_manager[1],fairness_wlast_by_manager[2]);
      check(fairness_w_pending==0, "AW fairness manager W beats accepted");
      check(fairness_wlast_count==9, "AW fairness nine target WLAST handshakes");
      check(fairness_b_count==9, "AW fairness nine B responses retired");
      check(fairness_owner_overlap_count==0, "AW fairness S0 owner not overwritten before WLAST");
      check(fairness_owner_wlast_without_aw==0 && !fairness_s0_owner_active,
            "AW fairness each target WLAST releases one S0 owner");
      for (integer m=0;m<3;m=m+1)
        check(fairness_aw_accepted[m]==3, "AW fairness exactly three requests per manager");
      reset_dut();
    end
  endtask

`ifdef ARCHITECTURE_B
  integer b_starve_cycles;
  task automatic b_high_qos_read(input logic [3:0] id);
    integer wait_cycles;
    logic accepted, completed;
    begin
      arid[1]=id; araddr[1]=32'h0000_2800+(id*8); arlen[1]=0; arsize[1]=3;
      arburst[1]=1; arlock[1]=0; arcache[1]=0; arprot[1]=0;
      arqos[1]=15; arregion[1]=0; arvalid[1]=1; rready[1]=1;
      accepted=0; wait_cycles=0;
      while (!accepted && wait_cycles<60) begin
        @(posedge ACLK);
        if (arvalid[1] && arready[1]) begin accepted=1; #1; arvalid[1]=0; end
        else #1;
        wait_cycles=wait_cycles+1;
        if (arvalid[0]) b_starve_cycles=b_starve_cycles+1;
      end
      check(accepted, "B high-QoS contender AR admitted");
      completed=0; wait_cycles=0;
      while (!completed && wait_cycles<60) begin
        @(posedge ACLK);
        if (rvalid[1] && rready[1]) begin
          check(rid[1]==id && rlast[1], "B high-QoS contender R completion");
          completed=1;
        end
        #1; wait_cycles=wait_cycles+1;
        if (arvalid[0]) b_starve_cycles=b_starve_cycles+1;
      end
      check(completed, "B high-QoS contender response drained");
    end
  endtask

  task automatic test_b_ar_independent_of_aw_owner;
    integer wait_cycles;
    logic aw_done, w_done, ar_done;
    begin
      $display("B AR scheduling independent of active AW/W owner");
      reset_dut();
      twready[0]=0; tawready[0]=1; tarready[0]=1; rready[1]=1;
      awid[0]=4'h9; awaddr[0]=32'h0000_2b00; awlen[0]=0; awsize[0]=3;
      awburst[0]=1; awlock[0]=0; awcache[0]=0; awprot[0]=0;
      awqos[0]=0; awregion[0]=0; awvalid[0]=1;
      aw_done=0; wait_cycles=0;
      while (!aw_done && wait_cycles<40) begin
        @(posedge ACLK);
        if (awvalid[0] && awready[0]) begin aw_done=1; #1; awvalid[0]=0; end
        else #1;
        wait_cycles=wait_cycles+1;
      end
      check(aw_done, "B owner test AW admitted");
      for (wait_cycles=0;wait_cycles<30 && !tawvalid[0];wait_cycles=wait_cycles+1) tick();
      check(tawvalid[0] && tawready[0], "B owner test target AW delivered");
      tick();
      wdata[0]=64'hB00B_0000_0000_0009; wstrb[0]=8'hff; wlast[0]=1; wvalid[0]=1;
      for (wait_cycles=0;wait_cycles<30 && !wready[0];wait_cycles=wait_cycles+1) tick();
      check(wready[0], "B owner test manager W accepted into target slot");
      tick(); wvalid[0]=0;
      check(twvalid[0] && !twready[0] && twlast[0], "B final W remains held and owns S0");

      arid[1]=4'hA; araddr[1]=32'h0000_2c00; arlen[1]=0; arsize[1]=3;
      arburst[1]=1; arlock[1]=0; arcache[1]=0; arprot[1]=0;
      arqos[1]=12; arregion[1]=0; arvalid[1]=1;
      ar_done=0; wait_cycles=0;
      while (!ar_done && wait_cycles<50) begin
        @(posedge ACLK);
        if (arvalid[1] && arready[1]) begin ar_done=1; #1; arvalid[1]=0; end
        else #1;
        wait_cycles=wait_cycles+1;
      end
      check(ar_done, "B AR admission progresses during active S0 W owner");
      for (wait_cycles=0;wait_cycles<30 && !tarvalid[0];wait_cycles=wait_cycles+1) tick();
      check(tarvalid[0] && tarready[0] && taraddr[0]==32'h0000_2c00,
            "B AR target delivery independent of S0 W owner");
      $display("B_AR_DURING_AW_OWNER PASS");
      reset_dut();
    end
  endtask

  task automatic test_integrated_b_starvation_escape;
    integer first_manager, wait_cycles;
    logic fire0, fire1;
    begin
      $display("B integrated age/starvation escape");
      reset_dut();
      b_starve_cycles=0;
      // Fill M0's four-read capacity on distinct targets while retaining its
      // responses. The fifth legal S0 request then ages but is not eligible.
      read_without_r(0,0,4'h0);
      read_without_r(0,1,4'h1);
      read_without_r(0,2,4'h2);
      read_without_r(0,3,4'h3);
      arid[0]=4'h4; araddr[0]=32'h0000_2900; arlen[0]=0; arsize[0]=3;
      arburst[0]=1; arlock[0]=0; arcache[0]=0; arprot[0]=0;
      arqos[0]=0; arregion[0]=0; arvalid[0]=1;
      check(!arready[0], "fifth M0 AR blocked at four outstanding");
      for (integer i=0;i<16;i=i+1) b_high_qos_read(i[3:0]);
      while (b_starve_cycles<70) begin
        tick(); b_starve_cycles=b_starve_cycles+1;
        check(!arready[0], "aged M0 request remains credit-blocked");
      end
      check(b_starve_cycles>=64, "M0 request remained pending through age threshold");

      // Retire one M0 read. Present a fresh QoS-15 request in the newly
      // eligible arbitration window; the aged M0 request must be selected.
      while (!rvalid[0]) tick();
      @(negedge ACLK); rready[0]=1;
      @(posedge ACLK);
      check(rvalid[0] && rready[0] && rlast[0], "one M0 read credit retires");
      #1;
      arid[1]=4'h7; araddr[1]=32'h0000_2a00; arlen[1]=0; arsize[1]=3;
      arburst[1]=1; arlock[1]=0; arcache[1]=0; arprot[1]=0;
      arqos[1]=15; arregion[1]=0; arvalid[1]=1;
      first_manager=-1; wait_cycles=0;
      while (first_manager<0 && wait_cycles<30) begin
        @(posedge ACLK);
        fire0=arvalid[0] && arready[0];
        fire1=arvalid[1] && arready[1];
        if (fire0) first_manager=0;
        if (fire1) first_manager=1;
        #1;
        if (fire0) arvalid[0]=0;
        if (fire1) arvalid[1]=0;
        wait_cycles=wait_cycles+1;
      end
      check(first_manager==0, "aged low-QoS M0 selected before fresh QoS-15 M1");
      $display("B_STARVATION pending_cycles=%0d first_manager=%0d",b_starve_cycles,first_manager);
      reset_dut();
    end
  endtask

  task automatic test_integrated_b_qos_priority;
    integer cycles, first_manager, accepted_count;
    begin
      $display("B integrated QoS priority");
      reset_dut();
      rready='1; tarready='1;
      arid[0]=4'h1; araddr[0]=32'h0000_2500; arlen[0]=0; arsize[0]=3; arburst[0]=1; arlock[0]=0; arcache[0]=0; arprot[0]=0; arqos[0]=0; arregion[0]=0; arvalid[0]=1;
      arid[1]=4'h2; araddr[1]=32'h0000_2510; arlen[1]=0; arsize[1]=3; arburst[1]=1; arlock[1]=0; arcache[1]=0; arprot[1]=0; arqos[1]=15; arregion[1]=0; arvalid[1]=1;
      first_manager=-1; accepted_count=0;
      for (cycles=0; cycles<60 && accepted_count<2; cycles=cycles+1) begin
        logic fire0, fire1;
        @(posedge ACLK);
        fire0=arvalid[0] && arready[0];
        fire1=arvalid[1] && arready[1];
        if (fire0) begin
          if (first_manager<0) first_manager=0;
          accepted_count=accepted_count+1;
        end
        if (fire1) begin
          if (first_manager<0) first_manager=1;
          accepted_count=accepted_count+1;
        end
        #1;
        if (fire0) arvalid[0]=0;
        if (fire1) arvalid[1]=0;
      end
      check(first_manager==1, "B integrated maximum QoS request admitted first");
      check(accepted_count==2, "B integrated competing AR requests both admitted");
      $display("B_QOS_AR_FIRST manager=%0d admissions=%0d cycles=%0d", first_manager, accepted_count, cycles);
      reset_dut();
    end
  endtask
`endif

  initial begin
    awid='0; awaddr='0; awlen='0; awsize='0; awburst='0; awlock='0; awcache='0; awprot='0; awqos='0; awregion='0; awvalid='0;
    wdata='0; wstrb='0; wlast='0; wvalid='0; bready='0;
    arid='0; araddr='0; arlen='0; arsize='0; arburst='0; arlock='0; arcache='0; arprot='0; arqos='0; arregion='0; arvalid='0; rready='0; r_gap_s0=0; b_hold_s0=0;
    reset_dut();
    for (integer m=0; m<3; m=m+1) begin
      for (integer t=0; t<4; t=t+1) begin
        do_write(m,t,4'(m*4+t),1);
        do_read(m,t,4'(m*4+t),1);
      end
    end
    // S3 multi-beat error traffic and one external multi-beat route.
    do_write(0,3,4'hd,16); do_read(0,3,4'he,16);
    do_write(1,0,4'hf,16); do_read(1,0,4'hc,16);

    // Gate-2 closure scenarios use a fresh coordinated reset.
    $display("G2 W-before-AW"); reset_dut();
    // W-before-AW, including the internal S3 endpoint.
    wdata[0]=64'hdead; wstrb[0]=8'hf0; wlast[0]=1; wvalid[0]=1;
    repeat(3) begin check(!wready[0], "W-before-AW backpressured"); tick(); end
    awid[0]=4'h1; awaddr[0]=32'h3000_0500; awlen[0]=0; awsize[0]=3; awburst[0]=1; awlock[0]=0; awcache[0]=0; awprot[0]=0; awqos[0]=0; awregion[0]=0; awvalid[0]=1;
    while (!awready[0]) tick(); tick(); awvalid[0]=0;
    while (!wready[0]) tick(); tick(); wvalid[0]=0; bready[0]=1;
    while (!bvalid[0]) tick(); check(bresp[0]==2'b11, "W-before-AW S3 DECERR"); tick(); bready[0]=0;

    // Four shared write entries, then fifth-ID blocking and following-cycle reuse.
    $display("G2 write capacity"); reset_dut();
    bready[0]=0;
    write_without_b(0,0,4'h1); write_without_b(0,1,4'h2); write_without_b(0,2,4'h3); write_without_b(0,3,4'h4);
    repeat(2) tick();
    awid[0]=4'h5; awaddr[0]=32'h0000_0600; awlen[0]=0; awsize[0]=3; awburst[0]=1; awlock[0]=0; awcache[0]=0; awprot[0]=0; awqos[0]=0; awregion[0]=0; awvalid[0]=1;
    repeat(3) begin check(!awready[0], "fifth write blocked at capacity"); tick(); end
    bready[0]=1; while (!bvalid[0]) tick(); tick(); bready[0]=0; tick();
    check(awready[0], "write capacity returns following cycle"); awvalid[0]=0;

    // Four shared read entries, then fifth-ID blocking and following-cycle reuse.
    $display("G2 read capacity"); reset_dut(); rready[0]=0;
    read_without_r(0,0,4'h1); read_without_r(0,1,4'h2); read_without_r(0,2,4'h3); read_without_r(0,3,4'h4);
    repeat(2) tick();
    arid[0]=4'h5; araddr[0]=32'h0000_0700; arlen[0]=0; arsize[0]=3; arburst[0]=1; arlock[0]=0; arcache[0]=0; arprot[0]=0; arqos[0]=0; arregion[0]=0; arvalid[0]=1;
    repeat(3) begin check(!arready[0], "fifth read blocked at capacity"); tick(); end
    rready[0]=1; while (!rvalid[0]) tick(); tick(); rready[0]=0; tick();
    check(arready[0], "read capacity returns following cycle"); arvalid[0]=0;

    // Unsupported shape is rejected and does not reach S3.
    $display("G2 unsupported"); reset_dut();
    awid[0]=4'h6; awaddr[0]=32'h3000_0801; awlen[0]=0; awsize[0]=2; awburst[0]=2; awlock[0]=0; awcache[0]=0; awprot[0]=0; awqos[0]=0; awregion[0]=0; awvalid[0]=1;
    repeat(3) begin check(!awready[0], "unsupported AW rejected"); tick(); end
    awvalid[0]=0;

    // Target-side AW and AR backpressure preserve registered payload.
    $display("G2 AW backpressure"); reset_dut(); tawready[0]=0;
    awid[0]=4'h7; awaddr[0]=32'h0000_0000; awlen[0]=0; awsize[0]=3; awburst[0]=1; awlock[0]=0; awcache[0]=0; awprot[0]=0; awqos[0]=0; awregion[0]=0; awvalid[0]=1;
    while (!awready[0]) tick(); tick(); awvalid[0]=0;
    repeat(3) begin check(tawvalid[0] && tawid[0]==6'h07 && tawaddr[0]==0, "AW slot stable under target stall"); tick(); end
    tawready[0]=1; tick();
    $display("G2 AR backpressure"); reset_dut(); tarready[0]=0;
    arid[0]=4'h8; araddr[0]=32'h0000_0000; arlen[0]=0; arsize[0]=3; arburst[0]=1; arlock[0]=0; arcache[0]=0; arprot[0]=0; arqos[0]=0; arregion[0]=0; arvalid[0]=1;
    while (!arready[0]) tick(); tick(); arvalid[0]=0;
    repeat(3) begin check(tarvalid[0] && tarid[0]==6'h08, "AR slot stable under target stall"); tick(); end
    tarready[0]=1; tick();

    // Same-cycle AW/W: AW may admit, W waits for the registered owner.
    $display("G2 same-cycle AW/W");
    reset_dut(); awid[0]=4'h9; awaddr[0]=32'h2000_0000; awlen[0]=0; awsize[0]=3; awburst[0]=1; awlock[0]=0; awcache[0]=0; awprot[0]=0; awqos[0]=0; awregion[0]=0; awvalid[0]=1;
    wdata[0]=64'h99; wstrb[0]=8'hff; wlast[0]=1; wvalid[0]=1;
    while (!awready[0]) tick(); check(!wready[0], "same-cycle AW/W uses pre-state owner"); tick(); awvalid[0]=0;
    for (integer z=0; z<100 && !wready[0]; z=z+1) begin tick(); end
    check(wready[0], "same-cycle W eventually ready");
    tick(); wvalid[0]=0; bready[0]=1;
    for (integer z=0; z<100 && !bvalid[0]; z=z+1) tick();
    check(bvalid[0], "same-cycle write completes"); tick(); bready[0]=0;

    // Response backpressure and registered payload stability.
    $display("G2 B/R backpressure"); reset_dut();
    write_without_b(0,0,4'ha); for (integer bp=0; bp<20 && !bvalid[0]; bp=bp+1) tick(); check(bvalid[0], "B response reaches stalled manager");
    repeat(2) begin check(bvalid[0], "B held under manager backpressure"); check(bid[0]==6'ha, "BID stable under backpressure"); tick(); end
    bready[0]=1; tick(); bready[0]=0;
    reset_dut(); rready[0]=0; read_without_r(0,0,4'hb); for (integer rp=0; rp<20 && !rvalid[0]; rp=rp+1) tick(); check(rvalid[0], "R response reaches stalled manager");
    repeat(2) begin check(rvalid[0], "R held under manager backpressure"); check(rid[0]==6'hb && rlast[0], "R payload stable under backpressure"); tick(); end
    rready[0]=1; tick(); rready[0]=0;

    // Same-target contention and independent parallel targets.
    $display("G2 contention and parallel targets"); reset_dut();
    for (integer cm=0; cm<3; cm=cm+1) begin
      awid[cm]=cm+1; awaddr[cm]=32'h0000_0900; awlen[cm]=0; awsize[cm]=3; awburst[cm]=1; awlock[cm]=0; awcache[cm]=0; awprot[cm]=0; awqos[cm]=0; awregion[cm]=0; awvalid[cm]=1;
    end
    #1;
    tick();
    begin $display("contend awr=%b legal=%b match=%b allowed=%b own=%b", awready, dut.aw_legal, dut.aw_match_t[0], dut.outstanding_w_allowed, dut.owner_active); check((awready[0]+awready[1]+awready[2])==1, "same-target AW RR selects one manager"); tick(); end
    awvalid='0; reset_dut();
    for (integer pm=0; pm<3; pm=pm+1) begin
      awid[pm]=pm+1; awaddr[pm]=(pm==0)?32'h0000_0a00:(pm==1)?32'h1000_0a00:32'h2000_0a00; awlen[pm]=0; awsize[pm]=3; awburst[pm]=1; awlock[pm]=0; awcache[pm]=0; awprot[pm]=0; awqos[pm]=0; awregion[pm]=0; awvalid[pm]=1;
    end
    #1;
    tick();
    begin $display("parallel awr=%b", awready); check((awready[0]&&awready[1]&&awready[2]), "parallel target AW progress"); tick(); end
    awvalid='0;

    // Same visible ID from all managers, with distinct external targets.
    $display("G2 same visible ID across managers"); reset_dut(); bready='0;
    for (integer im=0; im<3; im=im+1) begin
      awid[im]=4'h5; awaddr[im]=(im==0)?32'h0000_0b00:(im==1)?32'h1000_0b00:32'h2000_0b00; awlen[im]=0; awsize[im]=3; awburst[im]=1; awlock[im]=0; awcache[im]=0; awprot[im]=0; awqos[im]=0; awregion[im]=0; awvalid[im]=1;
      wdata[im]=64'h5000+im; wstrb[im]=8'hff; wlast[im]=1; wvalid[im]=1;
    end
    repeat(5) tick();
    check(ext_bid_q[0]==6'b00_0101 && ext_bid_q[1]==6'b01_0101 && ext_bid_q[2]==6'b10_0101, "widened write IDs disambiguate managers");
    awvalid='0; wvalid='0; bready='1; repeat(8) tick();
    for (integer im2=0; im2<3; im2=im2+1) if (bvalid[im2]) check(bid[im2]==4'h5, "same-ID write BID restored");
    reset_dut(); rready='0;
    for (integer ir=0; ir<3; ir=ir+1) begin
      arid[ir]=4'h5; araddr[ir]=(ir==0)?32'h0000_0c00:(ir==1)?32'h1000_0c00:32'h2000_0c00; arlen[ir]=0; arsize[ir]=3; arburst[ir]=1; arlock[ir]=0; arcache[ir]=0; arprot[ir]=0; arqos[ir]=0; arregion[ir]=0; arvalid[ir]=1;
    end
    repeat(5) tick();
    check(ext_rid_q[0]==6'b00_0101 && ext_rid_q[1]==6'b01_0101 && ext_rid_q[2]==6'b10_0101, "widened read IDs disambiguate managers");
    arvalid='0; rready='1; repeat(8) tick();
    for (integer ir2=0; ir2<3; ir2=ir2+1) if (rvalid[ir2]) check(rid[ir2]==4'h5, "same-ID read RID restored");

    // Distinct-ID out-of-order completion: rotate each response pointer first,
    // then leave S0/S1 responses pending so S1 is serviced before S0.
    $display("G2 distinct-ID out-of-order completion"); reset_dut();
    do_write(0,0,4'h0,1); bready[0]=0; b_hold_s0=1;
    write_without_b(0,0,4'h1); write_without_b(0,1,4'h2); repeat(4) tick();
    b_hold_s0=0; repeat(2) tick(); check(bvalid[0] && bid[0]==4'h2, "later write ID completes first"); bready[0]=1; tick(); bready[0]=0; repeat(2) tick();
    check(bvalid[0] && bid[0]==4'h1, "earlier write ID completes second"); bready[0]=1; tick(); bready[0]=0;
    reset_dut(); rready[0]=0;
    do_read(0,0,4'h0,1); rready[0]=0; r_gap_s0=1;
    read_without_r(0,0,4'h1); read_without_r(0,1,4'h2); repeat(4) tick();
    check(rvalid[0] && rid[0]==4'h2, "later read ID completes first"); rready[0]=1; tick(); rready[0]=0; r_gap_s0=0; repeat(2) tick();
    check(rvalid[0] && rid[0]==4'h1, "earlier read ID completes second"); rready[0]=1; tick(); rready[0]=0;

    // First, middle and final target-W stalls preserve registered beats.
    $display("G2 target W stalls"); reset_dut(); twready[0]=0;
    awid[0]=4'hc; awaddr[0]=32'h0000_0d00; awlen[0]=3; awsize[0]=3; awburst[0]=1; awlock[0]=0; awcache[0]=0; awprot[0]=0; awqos[0]=0; awregion[0]=0; awvalid[0]=1;
    while (!awready[0]) tick(); tick(); awvalid[0]=0;
    wdata[0]=64'hd0; wstrb[0]=8'hf0; wlast[0]=0; wvalid[0]=1; while (!wready[0]) tick(); tick(); wvalid[0]=0;
    repeat(3) begin check(twvalid[0] && twdata[0]==64'hd0 && !twlast[0], "first W beat stable while target stalled"); tick(); end
    twready[0]=1; tick(); twready[0]=0;
    wdata[0]=64'hd1; wstrb[0]=8'h0f; wlast[0]=0; wvalid[0]=1; while (!wready[0]) tick(); tick(); wvalid[0]=0;
    repeat(2) begin check(twvalid[0] && twdata[0]==64'hd1 && !twlast[0], "middle W beat stable while target stalled"); tick(); end
    twready[0]=1; tick(); twready[0]=0;
    wdata[0]=64'hd2; wstrb[0]=8'hff; wlast[0]=0; wvalid[0]=1; while (!wready[0]) tick(); tick(); wvalid[0]=0; twready[0]=1; tick(); twready[0]=0;
    wdata[0]=64'hd3; wstrb[0]=8'hff; wlast[0]=1; wvalid[0]=1; while (!wready[0]) tick(); tick(); wvalid[0]=0;
    repeat(3) begin check(twvalid[0] && twdata[0]==64'hd3 && twlast[0], "final WLAST stable while target stalled"); tick(); end
    twready[0]=1; bready[0]=1; repeat(8) tick(); bready[0]=0;

    // Locked-source gap: S1 must wait while M0's S0 burst is temporarily absent.
    $display("G2 R locked-source gap"); reset_dut(); rready[0]=1; r_gap_s0=0;
    arid[0]=4'h1; araddr[0]=32'h0000_1100; arlen[0]=3; arsize[0]=3; arburst[0]=1; arlock[0]=0; arcache[0]=0; arprot[0]=0; arqos[0]=0; arregion[0]=0; arvalid[0]=1;
    while (!arready[0]) tick(); tick(); arvalid[0]=0;
    arid[0]=4'h2; araddr[0]=32'h1000_1100; arlen[0]=0; arsize[0]=3; arburst[0]=1; arlock[0]=0; arcache[0]=0; arprot[0]=0; arqos[0]=0; arregion[0]=0; arvalid[0]=1;
    while (!arready[0]) tick(); tick(); arvalid[0]=0;
    for (integer rg=0; rg<30 && !(rvalid[0] && rid[0]==4'h1); rg=rg+1) tick(); check(rvalid[0] && rid[0]==4'h1, "S0 establishes first R burst"); tick();
    r_gap_s0=1;
    repeat(3) begin check(!trready[1] && trvalid[1], "alternate R source blocked during locked-source gap"); tick(); end
    r_gap_s0=0;
    for (integer rc=0; rc<30 && !(rvalid[0] && rlast[0]); rc=rc+1) tick(); check(rvalid[0] && rlast[0], "locked S0 burst resumes to RLAST"); tick();
    for (integer rs=0; rs<30 && !(rvalid[0] && rid[0]==4'h2); rs=rs+1) tick(); check(rvalid[0] && rid[0]==4'h2, "waiting S1 response follows accepted RLAST"); tick();
    rready[0]=0; r_gap_s0=0;

    // Reset abandonment for stalled address slots and a fresh recovery.
    $display("G2 reset partial traffic"); reset_dut(); tawready[0]=0;
    awid[0]=4'h1; awaddr[0]=32'h0000_0e00; awlen[0]=0; awsize[0]=3; awburst[0]=1; awlock[0]=0; awcache[0]=0; awprot[0]=0; awqos[0]=0; awregion[0]=0; awvalid[0]=1;
    while (!awready[0]) tick(); tick(); awvalid[0]=0; check(tawvalid[0], "AW slot occupied before reset"); reset_dut(); check(!tawvalid[0] && !bvalid[0] && !rvalid[0], "reset clears address/response state");
    tarready[0]=0; arid[0]=4'h2; araddr[0]=32'h0000_0f00; arlen[0]=0; arsize[0]=3; arburst[0]=1; arlock[0]=0; arcache[0]=0; arprot[0]=0; arqos[0]=0; arregion[0]=0; arvalid[0]=1;
    while (!arready[0]) tick(); tick(); arvalid[0]=0; check(tarvalid[0], "AR slot occupied before reset"); reset_dut(); check(!tarvalid[0] && !rvalid[0], "reset abandons stalled read");
    reset_dut(); bready[0]=0; write_without_b(0,0,4'h5); for (integer rb=0; rb<20 && !bvalid[0]; rb=rb+1) tick(); check(bvalid[0], "B slot occupied before reset"); reset_dut(); check(!bvalid[0], "reset clears stalled B slot");
    reset_dut(); rready[0]=0; read_without_r(0,0,4'h6); for (integer rr=0; rr<20 && !rvalid[0]; rr=rr+1) tick(); check(rvalid[0], "R slot occupied before reset"); reset_dut(); check(!rvalid[0], "reset clears stalled R slot");
    reset_dut(); twready[0]=0; awid[0]=4'h7; awaddr[0]=32'h0000_1000; awlen[0]=0; awsize[0]=3; awburst[0]=1; awlock[0]=0; awcache[0]=0; awprot[0]=0; awqos[0]=0; awregion[0]=0; awvalid[0]=1; while (!awready[0]) tick(); tick(); awvalid[0]=0; wdata[0]=64'h77; wstrb[0]=8'hff; wlast[0]=1; wvalid[0]=1; while (!wready[0]) tick(); tick(); wvalid[0]=0; check(twvalid[0], "W slot occupied before reset"); reset_dut(); check(!twvalid[0], "reset clears stalled W slot");
    reset_dut(); rready[0]=0; read_without_r(0,3,4'h8); for (integer rf=0; rf<20 && !rvalid[0]; rf=rf+1) tick(); check(rvalid[0] && rlast[0], "final RLAST stalled before reset"); reset_dut(); check(!rvalid[0], "reset clears stalled final RLAST");
    do_write(0,0,4'h3,1); do_read(0,0,4'h4,1);
    test_integrated_ar_fairness();
    test_integrated_aw_fairness();
`ifdef ARCHITECTURE_B
    test_integrated_b_qos_priority();
    test_integrated_b_starvation_escape();
    test_b_ar_independent_of_aw_owner();
    $display("PASS axi_fabric_b_tb checks=%0d", checks);
`else
    $display("PASS axi_fabric_a_tb checks=%0d", checks);
`endif $finish;
  end
endmodule
