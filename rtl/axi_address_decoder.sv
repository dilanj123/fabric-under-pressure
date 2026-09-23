module axi_address_decoder (
  input  logic [31:0]           addr,
  output logic [3:0]            target_select
);
  // This primitive decodes the raw address only. Supported-request legality,
  // burst boundary checks, and unsupported-request policy remain external.
  always_comb begin
    target_select = fabric_addr_map_pkg::TARGET_S3;
    // S0 starts at the minimum unsigned address; retain the explicit lower
    // bound as part of the map definition.
    // verilator lint_off UNSIGNED
    if ((addr >= fabric_addr_map_pkg::S0_BASE) && (addr <= fabric_addr_map_pkg::S0_LAST)) begin
    // verilator lint_on UNSIGNED
      target_select = fabric_addr_map_pkg::TARGET_S0;
    end else if ((addr >= fabric_addr_map_pkg::S1_BASE) && (addr <= fabric_addr_map_pkg::S1_LAST)) begin
      target_select = fabric_addr_map_pkg::TARGET_S1;
    end else if ((addr >= fabric_addr_map_pkg::S2_BASE) && (addr <= fabric_addr_map_pkg::S2_LAST)) begin
      target_select = fabric_addr_map_pkg::TARGET_S2;
    end
  end
endmodule
