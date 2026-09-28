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

  axi_fabric_a dut (.*,
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
    tbid = ext_bid_q;
    tbresp = '0;
    trvalid = ext_rvalid_q;
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

  initial begin
    awid='0; awaddr='0; awlen='0; awsize='0; awburst='0; awlock='0; awcache='0; awprot='0; awqos='0; awregion='0; awvalid='0;
    wdata='0; wstrb='0; wlast='0; wvalid='0; bready='0;
    arid='0; araddr='0; arlen='0; arsize='0; arburst='0; arlock='0; arcache='0; arprot='0; arqos='0; arregion='0; arvalid='0; rready='0;
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
    $display("PASS axi_fabric_a_tb checks=%0d", checks); $finish;
  end
endmodule
