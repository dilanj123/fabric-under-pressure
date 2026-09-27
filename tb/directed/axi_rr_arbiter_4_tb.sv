module axi_rr_arbiter_4_tb;
  logic ACLK = 0;
  always #5 ACLK = ~ACLK;
  logic ARESETn, downstream_ready;
  logic [3:0] request, grant;
  logic grant_valid;
  logic [1:0] selected_source;
  logic [1:0] pointer;
  integer checks=0;
  axi_rr_arbiter_4 dut (.*);

  task automatic check(input logic condition, input string message);
    begin checks=checks+1; if (!condition) begin $display("FAIL: %s",message); $fatal(1); end end
  endtask
  task automatic tick; begin @(posedge ACLK); #1; end endtask
  task automatic reset_arb;
    begin request=0; downstream_ready=0; ARESETn=0; tick(); tick(); ARESETn=1; end
  endtask

  initial begin
    reset_arb();
    // Every requester wins first from reset when it is the only request.
    request=4'b0001; tick(); check(grant==4'b0001 && selected_source==0, "S0 single request");
    request=4'b0000; downstream_ready=1; tick();
    request=4'b0010; downstream_ready=0; tick(); check(grant==4'b0010, "S1 single request");
    request=4'b0000; downstream_ready=1; tick();
    request=4'b0100; downstream_ready=0; tick(); check(grant==4'b0100, "S2 single request");
    request=4'b0000; downstream_ready=1; tick();
    request=4'b1000; downstream_ready=0; tick(); check(grant==4'b1000, "S3 single request");

    reset_arb();
    request=4'b1111; downstream_ready=0; tick(); check(grant==4'b0001, "reset pointer selects S0");
    request=4'b1111; downstream_ready=1; tick(); check(grant==4'b0010, "rotation selects S1");
    tick(); check(grant==4'b0100, "rotation selects S2");
    tick(); check(grant==4'b1000, "rotation selects S3");
    tick(); check(grant==4'b0001, "rotation wraps S3 to S0");

    reset_arb();
    request=4'b0110; downstream_ready=0; tick(); check(grant==4'b0010, "two-source S1/S2 tie from S0");
    request=4'b1100; downstream_ready=1; tick(); check(grant==4'b0100, "held S1 handshake advances to S2");
    downstream_ready=0; request=4'b0000; tick(); check(grant==4'b0100, "held grant survives request withdrawal");
    downstream_ready=1; tick();
    check(grant_valid==0 || grant==4'b0000, "no phantom grant after empty request");

    reset_arb();
    request=4'b1111; downstream_ready=0; tick();
    request=4'b0000; tick(); check(grant==4'b0001, "stall holds S0 despite withdrawal");
    check(grant_valid && !downstream_ready, "held valid remains asserted");
    downstream_ready=1; tick();
    $display("PASS axi_rr_arbiter_4_tb checks=%0d", checks);
    $finish;
  end
endmodule
