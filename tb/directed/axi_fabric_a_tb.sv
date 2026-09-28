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

  assign tawready = 3'b111;
  assign twready = 3'b111;
  assign tarready = 3'b111;

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

  initial begin
    awid='0; awaddr='0; awlen='0; awsize='0; awburst='0; awlock='0; awcache='0; awprot='0; awqos='0; awregion='0; awvalid='0;
    wdata='0; wstrb='0; wlast='0; wvalid='0; bready='0;
    arid='0; araddr='0; arlen='0; arsize='0; arburst='0; arlock='0; arcache='0; arprot='0; arqos='0; arregion='0; arvalid='0; rready='0;
    ARESETn=0; repeat(3) tick(); ARESETn=1; repeat(2) tick();
    for (integer m=0; m<3; m=m+1) begin
      for (integer t=0; t<4; t=t+1) begin
        do_write(m,t,4'(m*4+t),1);
        do_read(m,t,4'(m*4+t),1);
      end
    end
    // S3 multi-beat error traffic and one external multi-beat route.
    do_write(0,3,4'hd,16); do_read(0,3,4'he,16);
    do_write(1,0,4'hf,16); do_read(1,0,4'hc,16);
    $display("PASS axi_fabric_a_tb checks=%0d", checks); $finish;
  end
endmodule
