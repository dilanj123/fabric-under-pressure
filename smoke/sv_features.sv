package smoke_pkg;
  typedef struct packed {
    logic [7:0] data;
    logic       valid;
  } payload_t;

  function automatic logic [7:0] mix8(input logic [7:0] a, input logic [7:0] b);
    return {a[6:0], a[7]} ^ b;
  endfunction
endpackage

module smoke_lane #(
  parameter int unsigned INDEX = 0
) (
  input  logic                 clk,
  input  logic                 rst_n,
  input  smoke_pkg::payload_t  in_p,
  output smoke_pkg::payload_t  out_p
);
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      out_p <= '0;
    end else begin
      out_p.valid <= in_p.valid;
      out_p.data  <= smoke_pkg::mix8(in_p.data, 8'(INDEX));
    end
  end
endmodule

module sv_features #(parameter int unsigned N = 4) (
  input  logic              clk,
  input  logic              rst_n,
  input  logic [N-1:0][7:0] data_i,
  input  logic [N-1:0]      valid_i,
  output logic [N-1:0][7:0] data_o,
  output logic [N-1:0]      valid_o
);
  import smoke_pkg::*;
  payload_t in_p [N];
  payload_t out_p[N];

  for (genvar i = 0; i < N; i++) begin : g_lane
    always_comb begin
      in_p[i].data  = data_i[i];
      in_p[i].valid = valid_i[i];
      data_o[i]     = out_p[i].data;
      valid_o[i]    = out_p[i].valid;
    end
    smoke_lane #(.INDEX(i)) u_lane (.*);
  end
endmodule
