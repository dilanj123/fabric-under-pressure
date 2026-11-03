// Common small-I/O wrapper for Architecture-A and future Architecture-B PPA.
// The wrapper registers changing internal stimulus and folds public Fabric
// responses into a registered signature so the complete instance stays used.
module arch_fabric_wrapper (
  input  logic       clk,
  output logic [7:0] signature_o
);
  logic [4:0] boot_count = 5'd0;
  logic [31:0] stimulus_lfsr = 32'h1;
  logic [7:0] signature = 8'h0;
  wire ACLK = clk;
  wire ARESETn = boot_count[4];

  logic [2:0][3:0] manager_awid, manager_awqos, manager_awregion, manager_awcache;
  logic [2:0][31:0] manager_awaddr;
  logic [2:0][7:0] manager_awlen;
  logic [2:0][2:0] manager_awsize, manager_awprot;
  logic [2:0][1:0] manager_awburst;
  logic [2:0] manager_awlock, manager_awvalid;
  logic [2:0][63:0] manager_wdata;
  logic [2:0][7:0] manager_wstrb;
  logic [2:0] manager_wlast, manager_wvalid, manager_bready;
  logic [2:0] manager_awready, manager_wready;
  logic [2:0][3:0] manager_bid;
  logic [2:0][1:0] manager_bresp;
  logic [2:0] manager_bvalid;
  logic [2:0][3:0] manager_arid, manager_arqos, manager_arregion, manager_arcache;
  logic [2:0][31:0] manager_araddr;
  logic [2:0][7:0] manager_arlen;
  logic [2:0][2:0] manager_arsize, manager_arprot;
  logic [2:0][1:0] manager_arburst;
  logic [2:0] manager_arlock, manager_arvalid, manager_rready;
  logic [2:0] manager_arready;
  logic [2:0][3:0] manager_rid;
  logic [2:0][63:0] manager_rdata;
  logic [2:0][1:0] manager_rresp;
  logic [2:0] manager_rlast, manager_rvalid;

  logic [2:0][5:0] target_awid, target_bid, target_arid, target_rid;
  logic [2:0][31:0] target_awaddr, target_araddr;
  logic [2:0][7:0] target_awlen, target_arlen, target_wstrb;
  logic [2:0][2:0] target_awsize, target_awprot, target_arsize, target_arprot;
  logic [2:0][1:0] target_awburst, target_bresp, target_arburst, target_rresp;
  logic [2:0][3:0] target_awcache, target_awqos, target_awregion;
  logic [2:0][3:0] target_arcache, target_arqos, target_arregion;
  logic [2:0] target_awlock, target_awvalid, target_awready;
  logic [2:0][63:0] target_wdata, target_rdata;
  logic [2:0] target_wlast, target_wvalid, target_wready;
  logic [2:0] target_bvalid, target_bready;
  logic [2:0] target_arlock, target_arvalid, target_arready;
  logic [2:0] target_rlast, target_rvalid, target_rready;

  function automatic logic [31:0] address_for(input logic [1:0] target_sel,
                                                input logic [6:0] word_index);
    logic [31:0] base;
    case (target_sel)
      2'd0: base = 32'h0000_0000;
      2'd1: base = 32'h1000_0000;
      2'd2: base = 32'h2000_0000;
      default: base = 32'h3000_0000;
    endcase
    address_for = base + {word_index, 3'b000};
  endfunction

  always_ff @(posedge clk) begin
    boot_count <= boot_count + 1'b1;
    stimulus_lfsr <= {stimulus_lfsr[30:0],
                      stimulus_lfsr[31] ^ stimulus_lfsr[21] ^
                      stimulus_lfsr[1]};
    if (!ARESETn) begin
      manager_awvalid <= '0;
      manager_wvalid <= '0;
      manager_arvalid <= '0;
      manager_bready <= '1;
      manager_rready <= '1;
      target_awready <= '1;
      target_wready <= '1;
      target_arready <= '1;
      target_bvalid <= '0;
      target_rvalid <= '0;
      target_bid <= '0;
      target_bresp <= '0;
      target_rid <= '0;
      target_rdata <= '0;
      target_rresp <= '0;
      target_rlast <= '0;
      signature <= '0;
    end else begin
      for (int m = 0; m < 3; m++) begin
        // One-beat legal address/W traffic with changing target, ID and QoS.
        if (!manager_awvalid[m] || manager_awready[m]) begin
          manager_awvalid[m] <= stimulus_lfsr[m];
          manager_awid[m] <= stimulus_lfsr[4 +: 4] ^ m;
          manager_awaddr[m] <= address_for(stimulus_lfsr[8 +: 2],
                                             stimulus_lfsr[10 +: 7]);
          manager_awlen[m] <= '0;
          manager_awsize[m] <= 3'd3;
          manager_awburst[m] <= 2'b01;
          manager_awlock[m] <= 1'b0;
          manager_awcache[m] <= '0;
          manager_awprot[m] <= '0;
          manager_awqos[m] <= stimulus_lfsr[17 +: 4];
          manager_awregion[m] <= '0;
        end
        if (!manager_arvalid[m] || manager_arready[m]) begin
          manager_arvalid[m] <= stimulus_lfsr[m + 4];
          manager_arid[m] <= stimulus_lfsr[21 +: 4] ^ m;
          manager_araddr[m] <= address_for(stimulus_lfsr[25 +: 2],
                                             stimulus_lfsr[27 +: 7]);
          manager_arlen[m] <= '0;
          manager_arsize[m] <= 3'd3;
          manager_arburst[m] <= 2'b01;
          manager_arlock[m] <= 1'b0;
          manager_arcache[m] <= '0;
          manager_arprot[m] <= '0;
          manager_arqos[m] <= stimulus_lfsr[13 +: 4];
          manager_arregion[m] <= '0;
        end
        if (!manager_wvalid[m] || manager_wready[m]) begin
          manager_wvalid[m] <= stimulus_lfsr[m + 8];
          manager_wdata[m] <= {stimulus_lfsr, stimulus_lfsr} ^ (64'(m) << 48);
          manager_wstrb[m] <= 8'hff;
          manager_wlast[m] <= 1'b1;
        end
      end

      for (int t = 0; t < 3; t++) begin
        if (target_bvalid[t] && target_bready[t]) target_bvalid[t] <= 1'b0;
        if (target_awvalid[t] && target_awready[t]) begin
          target_bvalid[t] <= 1'b1;
          target_bid[t] <= target_awid[t];
          target_bresp[t] <= 2'b00;
        end
        if (target_rvalid[t] && target_rready[t]) target_rvalid[t] <= 1'b0;
        if (target_arvalid[t] && target_arready[t]) begin
          target_rvalid[t] <= 1'b1;
          target_rid[t] <= target_arid[t];
          target_rdata[t] <= {target_araddr[t], target_araddr[t]} ^ 64'hc39a_51e7_0b6d_248f;
          target_rresp[t] <= 2'b00;
          target_rlast[t] <= 1'b1;
        end
      end

      signature <= signature ^ {
        ^manager_awready, ^manager_wready, ^manager_bid, ^manager_bresp,
        ^manager_bvalid, ^manager_arready, ^manager_rid, ^manager_rdata,
        ^manager_rresp, ^manager_rlast, ^manager_rvalid,
        ^target_awid, ^target_awaddr, ^target_awlen, ^target_awvalid,
        ^target_wdata, ^target_wstrb, ^target_wlast, ^target_wvalid,
        ^target_arid, ^target_araddr, ^target_arlen, ^target_arvalid,
        ^target_rready, ^stimulus_lfsr
      };
    end
    signature_o <= signature;
  end

  (* keep_hierarchy *) axi_fabric_a u_fabric (.*);
endmodule
