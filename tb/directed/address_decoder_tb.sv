module address_decoder_tb;
  logic [31:0] addr;
  logic [3:0] target_select;
  integer test_count;

  axi_address_decoder dut (
    .addr(addr),
    .target_select(target_select)
  );

  task automatic check(input logic [31:0] value, input logic [3:0] expected, input string name);
    begin
      addr = value;
      #1;
      if (target_select !== expected) begin
        $fatal(1, "FAIL %s addr=%h expected=%b actual=%b", name, value, expected, target_select);
      end
      if ((target_select == 4'b0000) || ((target_select & (target_select - 4'b0001)) != 4'b0000)) begin
        $fatal(1, "FAIL %s non-onehot target=%b", name, target_select);
      end
      test_count = test_count + 1;
    end
  endtask

  initial begin
    test_count = 0;

    check(32'h0000_0000, 4'b0001, "S0 lower boundary");
    check(32'h0000_0008, 4'b0001, "S0 aligned interior");
    check(32'h0000_FFF8, 4'b0001, "S0 upper aligned boundary");
    check(32'h0000_FFFF, 4'b0001, "S0 raw upper boundary");
    check(32'h0001_0000, 4'b1000, "after S0");
    check(32'h0FFF_FFF8, 4'b1000, "before S1");

    check(32'h1000_0000, 4'b0010, "S1 lower boundary");
    check(32'h1000_0008, 4'b0010, "S1 aligned interior");
    check(32'h1000_FFF8, 4'b0010, "S1 upper aligned boundary");
    check(32'h1000_FFFF, 4'b0010, "S1 raw upper boundary");
    check(32'h1001_0000, 4'b1000, "after S1");
    check(32'h1FFF_FFFF, 4'b1000, "before S2");

    check(32'h2000_0000, 4'b0100, "S2 lower boundary");
    check(32'h2000_0008, 4'b0100, "S2 aligned interior");
    check(32'h2000_0FF8, 4'b0100, "S2 upper aligned boundary");
    check(32'h2000_0FFF, 4'b0100, "S2 raw upper boundary");
    check(32'h2000_1000, 4'b1000, "after S2");

    check(32'h3000_0000, 4'b1000, "unmapped high interior");
    check(32'hFFFF_FFF8, 4'b1000, "unmapped upper boundary");

    $display("PASS address_decoder_tb tests=%0d", test_count);
    $finish;
  end
endmodule
