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
  output logic                 axi_awready,

  input  logic [DATA_W-1:0]    axi_wdata,
  input  logic [STRB_W-1:0]    axi_wstrb,
  input  logic                 axi_wlast,
  input  logic                 axi_wvalid,
  output logic                 axi_wready,

  output logic [ID_W-1:0]      axi_bid,
  output logic [1:0]           axi_bresp,
  output logic                 axi_bvalid,
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
  output logic                 axi_arready,

  output logic [ID_W-1:0]      axi_rid,
  output logic [DATA_W-1:0]    axi_rdata,
  output logic [1:0]           axi_rresp,
  output logic                 axi_rlast,
  output logic                 axi_rvalid,
  input  logic                 axi_rready
);
  // Deliberately no RTL behavior: this is a signal namespace that lets a
  // cocotbext-axi AxiMaster and AxiRam drive opposite sides of the same bus.
endmodule
