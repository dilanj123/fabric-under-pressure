module address_decoder_formal;
  (* anyconst *) logic [31:0] addr;
  logic [3:0] target_select;

  axi_address_decoder dut (
    .addr(addr),
    .target_select(target_select)
  );

  always @* begin
    assert (target_select == fabric_addr_map_pkg::TARGET_S0 ||
            target_select == fabric_addr_map_pkg::TARGET_S1 ||
            target_select == fabric_addr_map_pkg::TARGET_S2 ||
            target_select == fabric_addr_map_pkg::TARGET_S3);

    if ((addr >= fabric_addr_map_pkg::S0_BASE) && (addr <= fabric_addr_map_pkg::S0_LAST))
      assert (target_select == fabric_addr_map_pkg::TARGET_S0);
    else if ((addr >= fabric_addr_map_pkg::S1_BASE) && (addr <= fabric_addr_map_pkg::S1_LAST))
      assert (target_select == fabric_addr_map_pkg::TARGET_S1);
    else if ((addr >= fabric_addr_map_pkg::S2_BASE) && (addr <= fabric_addr_map_pkg::S2_LAST))
      assert (target_select == fabric_addr_map_pkg::TARGET_S2);
    else
      assert (target_select == fabric_addr_map_pkg::TARGET_S3);

    cover (target_select == fabric_addr_map_pkg::TARGET_S0);
    cover (target_select == fabric_addr_map_pkg::TARGET_S1);
    cover (target_select == fabric_addr_map_pkg::TARGET_S2);
    cover (target_select == fabric_addr_map_pkg::TARGET_S3);
  end
endmodule
