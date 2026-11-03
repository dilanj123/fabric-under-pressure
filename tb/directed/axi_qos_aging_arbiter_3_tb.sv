module axi_qos_aging_arbiter_3_tb;
  logic ACLK = 0;
  logic ARESETn = 0;
  logic [2:0] legal_pending = '0, eligible = '0, grant;
  logic [2:0][3:0] qos = '0;
  logic accept = 0, grant_valid;
  logic [1:0] selected_manager, pointer;
  logic [2:0][7:0] age;
  integer checks = 0;
  always #5 ACLK = ~ACLK;

  axi_qos_aging_arbiter_3 dut (.*);

  task automatic check(input logic ok, input string label);
    begin
      checks = checks + 1;
      if (!ok) $fatal(1, "FAIL %s grant=%b valid=%b selected=%0d age=%0d,%0d,%0d ptr=%0d",
                       label, grant, grant_valid, selected_manager,
                       age[0], age[1], age[2], pointer);
    end
  endtask

  task automatic tick;
    begin @(posedge ACLK); #1; end
  endtask

  task automatic reset_case;
    begin
      @(negedge ACLK);
      ARESETn=0; legal_pending='0; eligible='0; qos='0; accept=0;
      repeat (2) tick();
      @(negedge ACLK); ARESETn=1;
      tick();
      check(grant=='0 && !grant_valid && pointer==0, "reset clears grant and pointer");
    end
  endtask

  task automatic accepted_grant;
    begin
      @(negedge ACLK); accept=1;
      tick();
      @(negedge ACLK); accept=0;
    end
  endtask

  initial begin
    reset_case();
    // Higher QoS wins when neither request is starved.
    @(negedge ACLK); legal_pending=3'b011; eligible=3'b011;
    qos[0]=0; qos[1]=15;
    tick(); check(grant==3'b010, "QoS 15 wins over QoS 0");

    // A selected request cannot be pre-empted while held, even by a new QoS 15.
    @(negedge ACLK); legal_pending=3'b111; eligible=3'b111;
    qos[0]=1; qos[1]=15; qos[2]=0;
    // Existing grant is still M1; accept it so a fresh choice is made next.
    accepted_grant(); tick(); check(grant==3'b010, "fresh high QoS after prior grant");
    @(negedge ACLK); qos[0]=15; qos[1]=0; qos[2]=0;
    tick(); check(grant==3'b010, "higher QoS arrival cannot pre-empt held grant");
    accepted_grant();

    // Equal QoS ties rotate from reset pointer and after each successful admission.
    reset_case();
    @(negedge ACLK); legal_pending=3'b111; eligible=3'b111; qos[0]=7; qos[1]=7; qos[2]=7;
    tick(); check(grant==3'b001, "equal QoS first M0");
    accepted_grant(); tick(); check(grant==3'b010, "equal QoS second M1");
    accepted_grant(); tick(); check(grant==3'b100, "equal QoS third M2");
    accepted_grant(); tick(); check(grant==3'b001, "equal QoS wraps to M0");

    // Three different priorities choose the maximum.
    reset_case();
    @(negedge ACLK); legal_pending=3'b111; eligible=3'b111;
    qos[0]=3; qos[1]=12; qos[2]=9;
    tick(); check(grant==3'b010, "maximum of three QoS values wins");

    // 63 is not starved. One more pending edge reaches 64; selection on the
    // next fresh opportunity uses registered age=64 and excludes fresh QoS 15.
    reset_case();
    @(negedge ACLK); legal_pending=3'b001; eligible=3'b000; qos[0]=0;
    repeat (63) tick();
    check(age[0]==8'd63, "age reaches 63 but not escape");
    tick(); check(age[0]==8'd64, "age crosses threshold to 64");
    @(negedge ACLK); legal_pending=3'b011; eligible=3'b011; qos[0]=0; qos[1]=15;
    tick(); check(grant==3'b001, "starved QoS 0 beats fresh QoS 15");

    // Multiple starved requests are selected round-robin.
    reset_case();
    @(negedge ACLK); legal_pending=3'b011; eligible=3'b000; qos[0]=1; qos[1]=1;
    repeat (64) tick();
    check(age[0]==64 && age[1]==64, "both requests reach escape age");
    @(negedge ACLK); eligible=3'b011;
    tick(); check(grant==3'b001, "starved RR begins at M0");
    accepted_grant(); tick(); check(grant==3'b010, "next starved requester M1");

    // Saturation and age reset when a request disappears.
    reset_case();
    @(negedge ACLK); legal_pending=3'b001; eligible=0;
    repeat (260) tick();
    check(age[0]==8'hff, "age saturates at 255");
    @(negedge ACLK); legal_pending=0; eligible=0;
    tick(); check(age[0]==0, "age resets when legal request disappears");

    // Grant held under lack of acceptance, then withdrawn request clears it
    // without advancing the pointer or leaving stale age.
    reset_case();
    @(negedge ACLK); legal_pending=3'b001; eligible=3'b001;
    tick(); check(grant==3'b001, "M0 selected before withdrawal");
    repeat (3) tick(); check(grant==3'b001 && pointer==0, "grant stable without acceptance");
    @(negedge ACLK); legal_pending=0; eligible=0;
    tick(); check(grant==0 && !grant_valid && pointer==0 && age[0]==0,
                  "withdrawal clears selection without pointer update");

    // Reset with pending state clears accumulated age and held grant.
    @(negedge ACLK); legal_pending=3'b010; eligible=3'b010; qos[1]=4;
    tick(); check(grant==3'b010, "M1 held before reset");
    reset_case();

    $display("PASS axi_qos_aging_arbiter_3_tb checks=%0d", checks);
    $finish;
  end
endmodule
