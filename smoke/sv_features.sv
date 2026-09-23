/* verilator lint_off DECLFILENAME */
package sv_features_pkg;
  typedef struct packed {
    logic [7:0] data;
    logic       valid;
  } payload_t;

  function automatic logic [7:0] mix8(input logic [7:0] a, input logic [7:0] b);
    mix8 = {a[6:0], a[7]} ^ b;
  endfunction
endpackage
/* verilator lint_on DECLFILENAME */

module smoke_lane #(
  parameter int unsigned INDEX = 0
) (
  input  logic                 clk,
  input  logic                 rst_n,
  input  sv_features_pkg::payload_t  in_p,
  output sv_features_pkg::payload_t  out_p
);
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      out_p <= '0;
    end else begin
      out_p.valid <= in_p.valid;
      out_p.data  <= sv_features_pkg::mix8(in_p.data, 8'(INDEX));
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
  sv_features_pkg::payload_t in_p [N];
  sv_features_pkg::payload_t out_p[N];

  for (genvar i = 0; i < N; i++) begin : g_lane
    always_comb begin
      in_p[i].data  = data_i[i];
      in_p[i].valid = valid_i[i];
      data_o[i]     = out_p[i].data;
      valid_o[i]    = out_p[i].valid;
    end
    smoke_lane #(.INDEX(i)) u_lane (
      .clk   (clk),
      .rst_n (rst_n),
      .in_p  (in_p[i]),
      .out_p (out_p[i])
    );
  end
endmodule
