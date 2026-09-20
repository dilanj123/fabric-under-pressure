module preserve_payload #(
  parameter int unsigned WIDTH = 256
) (
  input  logic             clk,
  input  logic [WIDTH-1:0] stim,
  output logic [WIDTH-1:0] resp
);
  logic [WIDTH-1:0] s = {{(WIDTH-1){1'b0}},1'b1};
  always_ff @(posedge clk) begin
    for (int i = 0; i < WIDTH; i++) begin
      s[i] <= s[(i+WIDTH-1)%WIDTH] ^ stim[i] ^ (i[0] ? s[(i+7)%WIDTH] : s[(i+13)%WIDTH]);
    end
    resp <= s ^ {s[WIDTH/2-1:0], s[WIDTH-1:WIDTH/2]};
  end
endmodule

module preserve_harness (
  input  logic       clk,
  input  logic [7:0] seed_i,
  output logic [7:0] signature_o
);
  localparam int unsigned WIDTH = 256;
  logic [31:0] prng = 32'h1;
  logic [WIDTH-1:0] stim;
  logic [WIDTH-1:0] resp;
  logic [7:0] signature;

  always_ff @(posedge clk) begin
    prng <= {prng[30:0], prng[31] ^ prng[21] ^ prng[1] ^ seed_i[0]};
    for (int i = 0; i < WIDTH; i++) begin
      stim[i] <= prng[i % 32] ^ seed_i[i % 8] ^ signature[i % 8];
    end
    for (int b = 0; b < 8; b++) begin
      signature[b] <= ^resp[b +: WIDTH/8];
    end
    signature_o <= signature;
  end

  preserve_payload #(.WIDTH(WIDTH)) u_payload (.*);
endmodule
