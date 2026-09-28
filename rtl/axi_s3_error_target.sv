// Internal AXI default/error target for legal supported requests routed to S3.
// The write and read sides are independent. WDATA/WSTRB are consumed and
// discarded; no memory state is implemented.
module axi_s3_error_target #(
  parameter integer ID_WIDTH = 6,
  parameter integer DATA_WIDTH = 64
) (
  input  logic ACLK,
  input  logic ARESETn,

  input  logic [ID_WIDTH-1:0]   awid,
  input  logic [31:0]           awaddr,
  input  logic [7:0]            awlen,
  input  logic [2:0]            awsize,
  input  logic [1:0]            awburst,
  input  logic                  awlock,
  input  logic [3:0]            awcache,
  input  logic [2:0]            awprot,
  input  logic [3:0]            awqos,
  input  logic [3:0]            awregion,
  input  logic                  awvalid,
  output logic                  awready,

  input  logic [DATA_WIDTH-1:0] wdata,
  input  logic [DATA_WIDTH/8-1:0] wstrb,
  input  logic                  wlast,
  input  logic                  wvalid,
  output logic                  wready,

  output logic [ID_WIDTH-1:0]   bid,
  output logic [1:0]            bresp,
  output logic                  bvalid,
  input  logic                  bready,

  input  logic [ID_WIDTH-1:0]   arid,
  input  logic [31:0]           araddr,
  input  logic [7:0]            arlen,
  input  logic [2:0]            arsize,
  input  logic [1:0]            arburst,
  input  logic                  arlock,
  input  logic [3:0]            arcache,
  input  logic [2:0]            arprot,
  input  logic [3:0]            arqos,
  input  logic [3:0]            arregion,
  input  logic                  arvalid,
  output logic                  arready,

  output logic [ID_WIDTH-1:0]   rid,
  output logic [DATA_WIDTH-1:0] rdata,
  output logic [1:0]            rresp,
  output logic                  rlast,
  output logic                  rvalid,
  input  logic                  rready,

  output logic                  early_wlast_violation,
  output logic                  missing_wlast_violation,
  output logic                  w_without_aw_violation,
  output logic                  write_active,
  output logic [ID_WIDTH-1:0]   write_id,
  output logic [4:0]            write_beats_remaining,
  output logic                  read_active,
  output logic [ID_WIDTH-1:0]   read_id,
  output logic [4:0]            read_beats_remaining
);
  logic [ID_WIDTH-1:0] write_id_q;
  logic [4:0] write_beats_q;
  logic bvalid_q;
  logic [ID_WIDTH-1:0] bid_q;

  logic [ID_WIDTH-1:0] read_id_q;
  logic [4:0] read_beats_q;

  logic aw_fire, w_fire, b_fire, ar_fire, r_fire;
  logic expected_wlast;

  // awlen <= 15 is guaranteed by the supported-request contract. The
  // explicit five-bit extension prevents an 8-bit LEN+1 wrap.
  always_comb begin
    write_active = (write_beats_q != 5'd0);
    read_active = (read_beats_q != 5'd0);
    awready = ARESETn && !write_active && !bvalid_q;
    wready = ARESETn && write_active;
    arready = ARESETn && !read_active;

    bvalid = bvalid_q;
    bid = bid_q;
    bresp = 2'b11;

    rvalid = ARESETn && read_active;
    rid = read_id_q;
    rdata = '0;
    rresp = 2'b11;
    rlast = (read_beats_q == 5'd1);

    aw_fire = awvalid && awready;
    w_fire = wvalid && wready;
    b_fire = bvalid_q && bready;
    ar_fire = arvalid && arready;
    r_fire = rvalid && rready;
    expected_wlast = (write_beats_q == 5'd1);

    early_wlast_violation = ARESETn && w_fire && (write_beats_q > 5'd1) && wlast;
    missing_wlast_violation = ARESETn && w_fire && expected_wlast && !wlast;
    // WVALID may legally precede local AW acceptance.  WREADY is the
    // protocol gate; this diagnostic is retained only as an impossible
    // defensive check for an accepted W without a registered context.
    w_without_aw_violation = ARESETn && w_fire && !write_active;

    write_id = write_id_q;
    write_beats_remaining = write_beats_q;
    read_id = read_id_q;
    read_beats_remaining = read_beats_q;
  end

  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      write_id_q <= '0;
      write_beats_q <= 5'd0;
      bvalid_q <= 1'b0;
      bid_q <= '0;
      read_id_q <= '0;
      read_beats_q <= 5'd0;
    end else begin
      if (aw_fire) begin
        write_id_q <= awid;
        write_beats_q <= {1'b0, awlen[3:0]} + 5'd1;
      end else if (w_fire) begin
        if (write_beats_q > 5'd1) begin
          write_beats_q <= write_beats_q - 5'd1;
        end else if (wlast) begin
          write_beats_q <= 5'd0;
          bvalid_q <= 1'b1;
          bid_q <= write_id_q;
        end
      end

      if (b_fire)
        bvalid_q <= 1'b0;

      if (ar_fire) begin
        read_id_q <= arid;
        read_beats_q <= {1'b0, arlen[3:0]} + 5'd1;
      end else if (r_fire && (read_beats_q == 5'd1)) begin
        read_beats_q <= 5'd0;
      end else if (r_fire) begin
        read_beats_q <= read_beats_q - 5'd1;
      end
    end
  end

  // Keep otherwise-unused compatible request attributes explicit at the
  // interface boundary. S3 does not interpret them after legality checking.
  logic unused_attributes;
  always_comb begin
    unused_attributes = ^{awaddr, awlen[7:4], awsize, awburst, awlock, awcache, awprot,
                          awqos, awregion, wdata, wstrb, araddr, arlen[7:4], arsize,
                          arburst, arlock, arcache, arprot, arqos, arregion};
  end
endmodule
