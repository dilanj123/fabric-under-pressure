module formal_counter(input logic clk);
  logic [1:0] count = 0;
  always_ff @(posedge clk) begin
    count <= count + 2'd1;
    assert(count <= 2'd3);
`ifdef EXPECT_FAIL
    assert(count != 2'd2);
`endif
    cover(count == 2'd3);
  end
endmodule
