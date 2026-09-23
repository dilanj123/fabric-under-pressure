module id_mapper_formal;
  (* anyconst *) logic [1:0] manager_index;
  (* anyconst *) logic [3:0] manager_id;
  (* anyconst *) logic [5:0] return_internal_id;

  logic [5:0] internal_id;
  logic [1:0] return_manager_index;
  logic [3:0] return_manager_id;
  logic       return_manager_valid;
  logic [1:0] roundtrip_manager_index;
  logic [3:0] roundtrip_manager_id;
  logic       roundtrip_manager_valid;
  logic [5:0] m0_id;
  logic [5:0] m1_id;
  logic [5:0] m2_id;

  axi_id_mapper dut (
    .manager_index(manager_index), .manager_id(manager_id),
    .internal_id(internal_id), .return_internal_id(return_internal_id),
    .return_manager_index(return_manager_index),
    .return_manager_id(return_manager_id),
    .return_manager_valid(return_manager_valid)
  );
  axi_id_mapper roundtrip (
    .manager_index(2'b00), .manager_id(4'b0), .internal_id(),
    .return_internal_id(internal_id),
    .return_manager_index(roundtrip_manager_index),
    .return_manager_id(roundtrip_manager_id),
    .return_manager_valid(roundtrip_manager_valid)
  );
  axi_id_mapper map_m0 (.manager_index(2'b00), .manager_id(manager_id), .internal_id(m0_id), .return_internal_id(6'b0), .return_manager_index(), .return_manager_id(), .return_manager_valid());
  axi_id_mapper map_m1 (.manager_index(2'b01), .manager_id(manager_id), .internal_id(m1_id), .return_internal_id(6'b0), .return_manager_index(), .return_manager_id(), .return_manager_valid());
  axi_id_mapper map_m2 (.manager_index(2'b10), .manager_id(manager_id), .internal_id(m2_id), .return_internal_id(6'b0), .return_manager_index(), .return_manager_id(), .return_manager_valid());

  always @* begin
    assert (internal_id == {manager_index, manager_id});
    assert (return_manager_index == return_internal_id[5:4]);
    assert (return_manager_id == return_internal_id[3:0]);
    assert (return_manager_valid == (return_internal_id[5:4] != 2'b11));
    if (manager_index != 2'b11) begin
      assert (roundtrip_manager_valid);
      assert (roundtrip_manager_index == manager_index);
      assert (roundtrip_manager_id == manager_id);
    end
    assert (m0_id != m1_id);
    assert (m0_id != m2_id);
    assert (m1_id != m2_id);

    cover (manager_index == 2'b00 && manager_id == 4'h0);
    cover (manager_index == 2'b01 && manager_id == 4'hf);
    cover (manager_index == 2'b10 && manager_id == 4'h0);
    cover (manager_index == 2'b10 && manager_id == 4'hf);
    cover (return_internal_id[5:4] == 2'b11);
    cover (m0_id[3:0] == 4'h5 && m1_id[3:0] == 4'h5 && m2_id[3:0] == 4'h5);
  end
endmodule
