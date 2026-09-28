module axi_s3_error_target_read_formal(input logic ACLK);
  (* anyseq *) logic ARESETn, arvalid, rready;
  (* anyseq *) logic [5:0] arid;
  (* anyseq *) logic [7:0] arlen;
  logic arready,rvalid,rlast; logic [5:0] rid; logic [63:0] rdata; logic [1:0] rresp;
  logic read_active; logic [4:0] read_beats_remaining;
  integer init_cycles=0;
  axi_s3_error_target dut(
    .ACLK,.ARESETn,.awid(0),.awaddr(0),.awlen(0),.awsize(0),.awburst(0),.awlock(0),
    .awcache(0),.awprot(0),.awqos(0),.awregion(0),.awvalid(0),.awready(),
    .wdata(0),.wstrb(0),.wlast(0),.wvalid(0),.wready(),.bid(),.bresp(),.bvalid(),.bready(0),
    .arid,.araddr(0),.arlen,.arsize(0),.arburst(0),.arlock(0),.arcache(0),
    .arprot(0),.arqos(0),.arregion(0),.arvalid,.arready,.rid,.rdata,.rresp,.rlast,.rvalid,.rready,
    .early_wlast_violation(),.missing_wlast_violation(),.w_without_aw_violation(),
    .write_active(),.write_id(),.write_beats_remaining(),.read_active,.read_id(),.read_beats_remaining);
  initial assume(!ARESETn);
  always @(posedge ACLK) begin
    if (init_cycles < 2) begin assume(!ARESETn); init_cycles=init_cycles+1; end
    if ($initstate) assume(!ARESETn);
    if ($past(ARESETn)) assume(ARESETn);
    if (ARESETn && arvalid && arready) assume(arlen <= 8'd15);
    if (ARESETn) begin
      assert(arready == !read_active);
      if (rvalid) begin
        assert(rdata == 64'b0); assert(rresp == 2'b11);
        assert(rlast == (read_beats_remaining == 1));
      end
      if ($past(ARESETn && rvalid && !rready)) begin
        assert(rvalid); assert(rid == $past(rid)); assert(rdata == $past(rdata));
        assert(rresp == $past(rresp)); assert(rlast == $past(rlast));
        assert(read_beats_remaining == $past(read_beats_remaining));
      end
      assert(!read_active || (read_beats_remaining >= 1 && read_beats_remaining <= 16));
    end else assert(!read_active && !rvalid);
  end
  always @(posedge ACLK) begin
    cover(ARESETn && arvalid && arready && arlen==0);
    cover(ARESETn && arvalid && arready && arlen==15);
    cover(ARESETn && rvalid && !rready);
    cover(ARESETn && rvalid && rlast);
  end
endmodule
