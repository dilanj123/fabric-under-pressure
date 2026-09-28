module axi_s3_error_target_write_formal(input logic ACLK);
  (* anyseq *) logic ARESETn, awvalid, wvalid, wlast, bready;
  (* anyseq *) logic [5:0] awid;
  (* anyseq *) logic [7:0] awlen;
  logic awready,wready,bvalid; logic [5:0] bid; logic [1:0] bresp;
  logic early_wlast_violation,missing_wlast_violation,w_without_aw_violation;
  logic write_active; logic [4:0] write_beats_remaining;
  integer init_cycles=0;
  axi_s3_error_target dut(
    .ACLK,.ARESETn,.awid,.awaddr(0),.awlen,.awsize(0),.awburst(0),.awlock(0),
    .awcache(0),.awprot(0),.awqos(0),.awregion(0),.awvalid,.awready,
    .wdata(0),.wstrb(0),.wlast,.wvalid,.wready,.bid,.bresp,.bvalid,.bready,
    .arid(0),.araddr(0),.arlen(0),.arsize(0),.arburst(0),.arlock(0),
    .arcache(0),.arprot(0),.arqos(0),.arregion(0),.arvalid(0),.arready(),
    .rid(),.rdata(),.rresp(),.rlast(),.rvalid(),.rready(0),
    .early_wlast_violation,.missing_wlast_violation,.w_without_aw_violation,
    .write_active,.write_id(),.write_beats_remaining,.read_active(),.read_id(),
    .read_beats_remaining());
  initial assume(!ARESETn);
  always @(posedge ACLK) begin
    if (init_cycles < 2) begin assume(!ARESETn); init_cycles=init_cycles+1; end
    if ($initstate) assume(!ARESETn);
    if ($past(ARESETn)) assume(ARESETn);
    if (ARESETn && awvalid && awready) assume(awlen <= 8'd15);
    if (ARESETn) begin
      assert(awready == (!write_active && !bvalid));
      assert(wready == write_active);
      // WVALID may be asserted before local AW acceptance; only WREADY gates
      // the handshake and state transition.
      if (!write_active) assert(!wready);
      assert(!bvalid || (bresp == 2'b11));
      assert(!bvalid || !write_active);
      if ($past(ARESETn && bvalid && !bready)) begin
        assert(bvalid); assert(bid == $past(bid)); assert(bresp == $past(bresp));
      end
      if (bvalid && !bready) assert(!awready);
      assert(!write_active || (write_beats_remaining >= 1 && write_beats_remaining <= 16));
    end else begin
      assert(!write_active && !bvalid);
    end
  end
  always @(posedge ACLK) begin
    cover(ARESETn && awvalid && awready && awlen==0);
    cover(ARESETn && awvalid && awready && awlen==15);
    cover(ARESETn && bvalid && !bready);
    cover(ARESETn && wvalid && !write_active && !wready);
    cover(ARESETn && $past(ARESETn && wvalid && !write_active) && awvalid && awready);
  end
endmodule
