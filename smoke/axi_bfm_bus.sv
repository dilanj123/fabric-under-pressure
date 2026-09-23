`timescale 1ns/1ps
module axi_bfm_bus #(
  parameter int DATA_W = 64,
  parameter int ADDR_W = 32,
  parameter int ID_W   = 4,
  parameter int STRB_W = DATA_W/8
) (
  input  logic                 clk,
  input  logic                 rst,

  input  logic [ID_W-1:0]      axi_awid,
  input  logic [ADDR_W-1:0]    axi_awaddr,
  input  logic [7:0]           axi_awlen,
  input  logic [2:0]           axi_awsize,
  input  logic [1:0]           axi_awburst,
  input  logic                 axi_awlock,
  input  logic [3:0]           axi_awcache,
  input  logic [2:0]           axi_awprot,
  input  logic [3:0]           axi_awqos,
  input  logic [3:0]           axi_awregion,
  input  logic                 axi_awvalid,
  inout  wire                  axi_awready,

  input  logic [DATA_W-1:0]    axi_wdata,
  input  logic [STRB_W-1:0]    axi_wstrb,
  input  logic                 axi_wlast,
  input  logic                 axi_wvalid,
  inout  wire                  axi_wready,

  inout  wire [ID_W-1:0]       axi_bid,
  inout  wire [1:0]            axi_bresp,
  inout  wire                  axi_bvalid,
  input  logic                 axi_bready,

  input  logic [ID_W-1:0]      axi_arid,
  input  logic [ADDR_W-1:0]    axi_araddr,
  input  logic [7:0]           axi_arlen,
  input  logic [2:0]           axi_arsize,
  input  logic [1:0]           axi_arburst,
  input  logic                 axi_arlock,
  input  logic [3:0]           axi_arcache,
  input  logic [2:0]           axi_arprot,
  input  logic [3:0]           axi_arqos,
  input  logic [3:0]           axi_arregion,
  input  logic                 axi_arvalid,
  inout  wire                  axi_arready,

  inout  wire [ID_W-1:0]       axi_rid,
  inout  wire [DATA_W-1:0]     axi_rdata,
  inout  wire [1:0]            axi_rresp,
  inout  wire                  axi_rlast,
  inout  wire                  axi_rvalid,
  input  logic                 axi_rready
);
  // Deliberately no RTL behavior: this is a signal namespace that lets a
  // cocotbext-axi AxiMaster and AxiRam drive opposite sides of the same bus.
endmodule
