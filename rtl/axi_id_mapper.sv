// Manager-visible AXI IDs are widened with the originating manager index.
// This primitive performs only combinational encoding/decoding; it does not
// track outstanding transactions or validate response ownership.
module axi_id_mapper (
  input  logic [1:0] manager_index,
  input  logic [3:0] manager_id,
  output logic [5:0] internal_id,

  input  logic [5:0] return_internal_id,
  output logic [1:0] return_manager_index,
  output logic [3:0] return_manager_id,
  output logic       return_manager_valid
);
  always_comb begin
    internal_id = {manager_index, manager_id};
    return_manager_index = return_internal_id[5:4];
    return_manager_id = return_internal_id[3:0];
    return_manager_valid = (return_manager_index != 2'b11);
  end
endmodule
