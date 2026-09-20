module handshake_counter (
  input  logic       clk,
  input  logic       rst_n,
  input  logic       in_valid,
  output logic       in_ready,
  input  logic [7:0] in_data,
  output logic [7:0] accepted_count,
  output logic [7:0] last_data
);
  assign in_ready = 1'b1;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      accepted_count <= '0;
      last_data       <= '0;
    end else if (in_valid && in_ready) begin
      accepted_count <= accepted_count + 8'd1;
      last_data       <= in_data;
    end
  end
endmodule
