module rr_arbiter_tb;
  logic ACLK;
  logic ARESETn;
  logic [2:0] request;
  logic downstream_ready;
  logic [2:0] grant;
  logic grant_valid;
  logic [1:0] selected_manager;
  integer checks;

  axi_rr_arbiter_3 dut (.*);

  initial ACLK = 1'b0;
  always #5 ACLK = ~ACLK;

  function automatic [2:0] reference_grant(input integer ptr, input [2:0] req);
    begin
      reference_grant = 3'b000;
      case (ptr)
        0: if (req[0]) reference_grant = 3'b001;
           else if (req[1]) reference_grant = 3'b010;
           else if (req[2]) reference_grant = 3'b100;
        1: if (req[1]) reference_grant = 3'b010;
           else if (req[2]) reference_grant = 3'b100;
           else if (req[0]) reference_grant = 3'b001;
        2: if (req[2]) reference_grant = 3'b100;
           else if (req[0]) reference_grant = 3'b001;
           else if (req[1]) reference_grant = 3'b010;
        default: reference_grant = 3'b000;
      endcase
    end
  endfunction

  function automatic integer winner_index(input [2:0] onehot);
    begin
      case (onehot)
        3'b001: winner_index = 0;
        3'b010: winner_index = 1;
        3'b100: winner_index = 2;
        default: winner_index = 0;
      endcase
    end
  endfunction

  task automatic fail(input string name);
    begin
      $fatal(1, "FAIL %s reset=%b req=%b ready=%b grant=%b valid=%b selected=%0d pointer=%0d",
             name, ARESETn, request, downstream_ready, grant, grant_valid,
             selected_manager, dut.pointer_q);
    end
  endtask

  task automatic cycle(input [2:0] req, input logic ready);
    begin
      @(negedge ACLK);
      request = req;
      downstream_ready = ready;
      @(posedge ACLK);
      #1;
    end
  endtask

  task automatic reset_arbiter;
    begin
      ARESETn = 1'b0;
      request = 3'b000;
      downstream_ready = 1'b0;
      #1;
      if (grant !== 3'b000 || grant_valid !== 1'b0 || dut.pointer_q !== 2'b00)
        fail("reset state");
      @(negedge ACLK);
      ARESETn = 1'b1;
      request = 3'b000;
      downstream_ready = 1'b0;
      #1;
    end
  endtask

  task automatic advance_pointer(input integer ptr);
    begin
      cycle((3'b001 << ptr), 1'b1);
      cycle(3'b000, 1'b1);
    end
  endtask

  task automatic set_pointer(input integer ptr);
    integer p;
    begin
      reset_arbiter();
      for (p = 0; p < ptr; p = p + 1)
        advance_pointer(p);
      if (dut.pointer_q !== ptr[1:0]) fail("pointer setup");
    end
  endtask

  task automatic check_base(input integer ptr, input [2:0] req);
    reg [2:0] expected;
    reg [1:0] expected_manager;
    begin
      set_pointer(ptr);
      expected = reference_grant(ptr, req);
      case (expected)
        3'b001: expected_manager = 2'b00;
        3'b010: expected_manager = 2'b01;
        3'b100: expected_manager = 2'b10;
        default: expected_manager = 2'b00;
      endcase
      cycle(req, 1'b0);
      if (grant !== expected || grant_valid !== (expected != 3'b000) ||
          (grant_valid && selected_manager !== expected_manager))
        fail("base scheduling");
      checks = checks + 1;
    end
  endtask

  integer ptr;
  integer mask;
  integer stall;
  reg [2:0] expected;
  initial begin
    checks = 0;
    ARESETn = 1'b0;
    request = 3'b000;
    downstream_ready = 1'b0;
    #2;

    // Exhaustive 3 pointer states x 8 request masks.
    for (ptr = 0; ptr < 3; ptr = ptr + 1)
      for (mask = 0; mask < 8; mask = mask + 1)
        check_base(ptr, mask[2:0]);

    // Persistent all-request rotation, with no bubbles between handshakes.
    reset_arbiter();
    cycle(3'b111, 1'b1);
    if (grant !== 3'b001) fail("initial rotation winner");
    checks = checks + 1;
    for (ptr = 1; ptr < 10; ptr = ptr + 1) begin
      expected = 3'b001 << (ptr % 3);
      cycle(3'b111, 1'b1);
      if (grant !== expected || !grant_valid) fail("three-way rotation");
      checks = checks + 1;
    end

    // Persistent two-request combinations exercise skipped requesters.
    reset_arbiter();
    cycle(3'b011, 1'b1);
    if (grant !== 3'b001) fail("M0/M1 initial winner");
    checks = checks + 1;
    for (ptr = 1; ptr < 7; ptr = ptr + 1) begin
      expected = (ptr % 2 == 1) ? 3'b010 : 3'b001;
      cycle(3'b011, 1'b1);
      if (grant !== expected) fail("M0/M1 persistence");
      checks = checks + 1;
    end
    reset_arbiter();
    cycle(3'b101, 1'b1);
    if (grant !== 3'b001) fail("M0/M2 initial winner");
    checks = checks + 1;
    for (ptr = 1; ptr < 7; ptr = ptr + 1) begin
      expected = (ptr % 2 == 1) ? 3'b100 : 3'b001;
      cycle(3'b101, 1'b1);
      if (grant !== expected) fail("M0/M2 persistence");
      checks = checks + 1;
    end
    reset_arbiter();
    cycle(3'b110, 1'b1);
    if (grant !== 3'b010) fail("M1/M2 initial winner");
    checks = checks + 1;
    for (ptr = 1; ptr < 7; ptr = ptr + 1) begin
      expected = (ptr % 2 == 1) ? 3'b100 : 3'b010;
      cycle(3'b110, 1'b1);
      if (grant !== expected) fail("M1/M2 persistence");
      checks = checks + 1;
    end

    // A stalled winner is held while requests change.
    reset_arbiter();
    cycle(3'b001, 1'b0);
    for (stall = 1; stall <= 10; stall = stall + 1) begin
      cycle(((stall % 2) != 0) ? 3'b110 : 3'b111, 1'b0);
      if (grant !== 3'b001 || !grant_valid || selected_manager !== 2'b00)
        fail("held grant stability");
      checks = checks + 1;
    end
    cycle(3'b111, 1'b1);
    if (grant !== 3'b010 || dut.pointer_q !== 2'b01) fail("held handshake rotation");
    checks = checks + 1;

    // Dynamic arrival cannot pre-empt a stalled winner.
    reset_arbiter();
    cycle(3'b001, 1'b0);
    cycle(3'b111, 1'b0);
    if (grant !== 3'b001) fail("dynamic arrival hold");
    cycle(3'b111, 1'b1);
    if (grant !== 3'b010) fail("dynamic arrival release");
    checks = checks + 2;

    // Reset clears a held grant and restores M0 priority.
    reset_arbiter();
    cycle(3'b100, 1'b0);
    ARESETn = 1'b0;
    #1;
    if (grant !== 3'b000 || grant_valid || dut.pointer_q !== 2'b00)
      fail("reset during hold");
    checks = checks + 1;
    ARESETn = 1'b1;
    cycle(3'b111, 1'b0);
    if (grant !== 3'b001) fail("post-reset M0 priority");
    checks = checks + 1;

    $display("PASS rr_arbiter_tb checks=%0d", checks);
    $finish;
  end
endmodule
