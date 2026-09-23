module id_mapper_tb;
  logic [1:0] manager_index;
  logic [3:0] manager_id;
  logic [5:0] internal_id;
  logic [5:0] return_internal_id;
  logic [1:0] return_manager_index;
  logic [3:0] return_manager_id;
  logic       return_manager_valid;
  integer test_count;

  axi_id_mapper dut (
    .manager_index(manager_index), .manager_id(manager_id),
    .internal_id(internal_id), .return_internal_id(return_internal_id),
    .return_manager_index(return_manager_index),
    .return_manager_id(return_manager_id),
    .return_manager_valid(return_manager_valid)
  );

  task automatic fail(input string name);
    begin
      $fatal(1, "FAIL %s manager=%b id=%h internal=%h return=%h decoded_manager=%b decoded_id=%h valid=%b",
             name, manager_index, manager_id, internal_id, return_internal_id,
             return_manager_index, return_manager_id, return_manager_valid);
    end
  endtask

  task automatic check_mapping(input logic [1:0] value_manager,
                               input logic [3:0] value_id);
    begin
      manager_index = value_manager;
      manager_id = value_id;
      return_internal_id = {value_manager, value_id};
      #1;
      if (internal_id !== {value_manager, value_id}) fail("forward mapping");
      if (return_manager_index !== value_manager) fail("round-trip manager");
      if (return_manager_id !== value_id) fail("round-trip ID");
      if (return_manager_valid !== 1'b1) fail("valid manager");
      test_count = test_count + 1;
    end
  endtask

  task automatic check_reserved(input logic [3:0] value_id);
    begin
      manager_index = 2'b00;
      manager_id = 4'h0;
      return_internal_id = {2'b11, value_id};
      #1;
      if (return_manager_index !== 2'b11) fail("reserved manager code");
      if (return_manager_id !== value_id) fail("reserved lower ID");
      if (return_manager_valid !== 1'b0) fail("reserved validity");
      test_count = test_count + 1;
    end
  endtask

  integer m;
  integer id;
  integer other_id;
  logic [5:0] map0;
  logic [5:0] map1;
  logic [5:0] map2;
  initial begin
    test_count = 0;

    for (m = 0; m < 3; m = m + 1)
      for (id = 0; id < 16; id = id + 1)
        check_mapping(m[1:0], id[3:0]);

    for (id = 0; id < 16; id = id + 1)
      check_reserved(id[3:0]);

    // Same visible ID cannot collide across any pair of valid managers.
    for (id = 0; id < 16; id = id + 1) begin
      manager_id = id[3:0];
      manager_index = 2'b00; #1; map0 = internal_id;
      manager_index = 2'b01; #1; map1 = internal_id;
      manager_index = 2'b10; #1; map2 = internal_id;
      if (map0 === map1 || map0 === map2 || map1 === map2)
        fail("cross-manager collision");
      test_count = test_count + 3;
    end

    // Different visible IDs remain distinct within each valid manager.
    for (m = 0; m < 3; m = m + 1) begin
      for (id = 0; id < 16; id = id + 1) begin
        manager_index = m[1:0];
        manager_id = id[3:0];
        #1;
        map0 = internal_id;
        for (other_id = id + 1; other_id < 16; other_id = other_id + 1) begin
          manager_id = other_id[3:0];
          #1;
          if (map0 === internal_id) fail("within-manager collision");
          test_count = test_count + 1;
        end
      end
    end

    $display("PASS id_mapper_tb tests=%0d valid_mappings=48 reserved_returns=16 cross_manager_pairs=48 within_manager_pairs=360", test_count);
    $finish;
  end
endmodule
