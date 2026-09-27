module axi_b_response_router_formal;
  (* gclk *) logic ACLK;
  (* anyseq *) logic ARESETn;
  (* anyseq *) logic [3:0] target_bvalid;
  (* anyseq *) logic [3:0][5:0] target_bid;
  (* anyseq *) logic [3:0][1:0] target_bresp;
  (* anyseq *) logic [2:0][15:0] busy_bitmap;
  (* anyseq *) logic [2:0] manager_bready;

  logic [3:0] target_bready, target_b_fire;
  logic [2:0] manager_bvalid, manager_b_fire;
  logic [2:0][3:0] manager_bid, b_complete_id;
  logic [2:0][1:0] manager_bresp;
  logic [2:0] b_complete_fire, slot_valid;
  logic [3:0] invalid_manager_violation, nonbusy_id_violation;
  logic [2:0] response_admit_fire;
  logic [2:0][1:0] slot_source_target;

  axi_b_response_router dut (.*);

  initial assume (!ARESETn);

  always @(posedge ACLK) begin
    if ($past(ARESETn) && $past(target_bvalid[0] && !target_bready[0])) begin
      assume (target_bvalid[0]);
      assume (target_bid[0] == $past(target_bid[0]));
      assume (target_bresp[0] == $past(target_bresp[0]));
    end
    if ($past(ARESETn) && $past(target_bvalid[1] && !target_bready[1])) begin
      assume (target_bvalid[1]);
      assume (target_bid[1] == $past(target_bid[1]));
      assume (target_bresp[1] == $past(target_bresp[1]));
    end
    if ($past(ARESETn) && $past(target_bvalid[2] && !target_bready[2])) begin
      assume (target_bvalid[2]);
      assume (target_bid[2] == $past(target_bid[2]));
      assume (target_bresp[2] == $past(target_bresp[2]));
    end
    if ($past(ARESETn) && $past(target_bvalid[3] && !target_bready[3])) begin
      assume (target_bvalid[3]);
      assume (target_bid[3] == $past(target_bid[3]));
      assume (target_bresp[3] == $past(target_bresp[3]));
    end

    if (ARESETn) begin
      assert (manager_b_fire == (manager_bvalid & manager_bready));
      assert (b_complete_fire == manager_b_fire);
      assert (!b_complete_fire[0] || b_complete_id[0] == manager_bid[0]);
      assert (!b_complete_fire[1] || b_complete_id[1] == manager_bid[1]);
      assert (!b_complete_fire[2] || b_complete_id[2] == manager_bid[2]);

      assert (target_bvalid[0] && target_bid[0][5:4] == 2'b11
              ? (invalid_manager_violation[0] && !target_bready[0]) : 1'b1);
      assert (target_bvalid[1] && target_bid[1][5:4] == 2'b11
              ? (invalid_manager_violation[1] && !target_bready[1]) : 1'b1);
      assert (target_bvalid[2] && target_bid[2][5:4] == 2'b11
              ? (invalid_manager_violation[2] && !target_bready[2]) : 1'b1);
      assert (target_bvalid[3] && target_bid[3][5:4] == 2'b11
              ? (invalid_manager_violation[3] && !target_bready[3]) : 1'b1);

      assert (!nonbusy_id_violation[0] || !target_bready[0]);
      assert (!nonbusy_id_violation[1] || !target_bready[1]);
      assert (!nonbusy_id_violation[2] || !target_bready[2]);
      assert (!nonbusy_id_violation[3] || !target_bready[3]);

      assert (!target_bready[0] || (target_bvalid[0] &&
              target_bid[0][5:4] != 2'b11 && !nonbusy_id_violation[0]));
      assert (!target_bready[1] || (target_bvalid[1] &&
              target_bid[1][5:4] != 2'b11 && !nonbusy_id_violation[1]));
      assert (!target_bready[2] || (target_bvalid[2] &&
              target_bid[2][5:4] != 2'b11 && !nonbusy_id_violation[2]));
      assert (!target_bready[3] || (target_bvalid[3] &&
              target_bid[3][5:4] != 2'b11 && !nonbusy_id_violation[3]));

      assert (manager_bvalid[0] == slot_valid[0]);
      assert (manager_bvalid[1] == slot_valid[1]);
      assert (manager_bvalid[2] == slot_valid[2]);

    end

    cover (ARESETn && target_bready[0]);
    cover (ARESETn && target_bready[1]);
    cover (ARESETn && target_bready[2]);
    cover (ARESETn && target_bready[3]);
    cover (ARESETn && manager_bvalid[0] && !manager_bready[0]);
    cover (ARESETn && target_bvalid[3] && target_bid[3][5:4] == 2'b10 &&
           !nonbusy_id_violation[3]);
  end

  // Target-side safety is combinationally tied to the registered slot
  // pre-state, so these properties are checked without NBA sampling skew.
  always_comb begin
    if (ARESETn) begin
    assert (!slot_valid[0] || !response_admit_fire[0]);
    assert (!slot_valid[1] || !response_admit_fire[1]);
    assert (!slot_valid[2] || !response_admit_fire[2]);
    assert (!slot_valid[0] || !target_bvalid[0] || target_bid[0][5:4] != 2'b00 || !target_bready[0]);
    assert (!slot_valid[0] || !target_bvalid[1] || target_bid[1][5:4] != 2'b00 || !target_bready[1]);
    assert (!slot_valid[0] || !target_bvalid[2] || target_bid[2][5:4] != 2'b00 || !target_bready[2]);
    assert (!slot_valid[0] || !target_bvalid[3] || target_bid[3][5:4] != 2'b00 || !target_bready[3]);
    assert (!slot_valid[1] || !target_bvalid[0] || target_bid[0][5:4] != 2'b01 || !target_bready[0]);
    assert (!slot_valid[1] || !target_bvalid[1] || target_bid[1][5:4] != 2'b01 || !target_bready[1]);
    assert (!slot_valid[1] || !target_bvalid[2] || target_bid[2][5:4] != 2'b01 || !target_bready[2]);
    assert (!slot_valid[1] || !target_bvalid[3] || target_bid[3][5:4] != 2'b01 || !target_bready[3]);
    assert (!slot_valid[2] || !target_bvalid[0] || target_bid[0][5:4] != 2'b10 || !target_bready[0]);
    assert (!slot_valid[2] || !target_bvalid[1] || target_bid[1][5:4] != 2'b10 || !target_bready[1]);
    assert (!slot_valid[2] || !target_bvalid[2] || target_bid[2][5:4] != 2'b10 || !target_bready[2]);
    assert (!slot_valid[2] || !target_bvalid[3] || target_bid[3][5:4] != 2'b10 || !target_bready[3]);
    assert (!response_admit_fire[0] || |target_b_fire);
    assert (!response_admit_fire[1] || |target_b_fire);
    assert (!response_admit_fire[2] || |target_b_fire);
    assert (!(target_b_fire[0] && target_bid[0][5:4] == 2'b00) || response_admit_fire[0]);
    assert (!(target_b_fire[1] && target_bid[1][5:4] == 2'b00) || response_admit_fire[0]);
    assert (!(target_b_fire[2] && target_bid[2][5:4] == 2'b00) || response_admit_fire[0]);
    assert (!(target_b_fire[3] && target_bid[3][5:4] == 2'b00) || response_admit_fire[0]);
    assert (!(target_b_fire[0] && target_bid[0][5:4] == 2'b01) || response_admit_fire[1]);
    assert (!(target_b_fire[1] && target_bid[1][5:4] == 2'b01) || response_admit_fire[1]);
    assert (!(target_b_fire[2] && target_bid[2][5:4] == 2'b01) || response_admit_fire[1]);
    assert (!(target_b_fire[3] && target_bid[3][5:4] == 2'b01) || response_admit_fire[1]);
    assert (!(target_b_fire[0] && target_bid[0][5:4] == 2'b10) || response_admit_fire[2]);
    assert (!(target_b_fire[1] && target_bid[1][5:4] == 2'b10) || response_admit_fire[2]);
    assert (!(target_b_fire[2] && target_bid[2][5:4] == 2'b10) || response_admit_fire[2]);
    assert (!(target_b_fire[3] && target_bid[3][5:4] == 2'b10) || response_admit_fire[2]);
  end
  end
endmodule
