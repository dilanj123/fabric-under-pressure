module ecp5_smoke (
  input  logic clk,
  input  logic seed,
  output logic signature
);
  logic [31:0] state = 32'h1;
  always_ff @(posedge clk) begin
    state <= {state[30:0], state[31] ^ state[21] ^ seed};
    signature <= ^state;
  end
endmodule
