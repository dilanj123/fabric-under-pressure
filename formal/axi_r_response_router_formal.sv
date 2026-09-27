module axi_r_response_router_formal(input logic ACLK);
  (* anyseq *) logic ARESETn;
  (* anyseq *) logic [3:0] target_rvalid, target_rlast;
  (* anyseq *) logic [3:0][5:0] target_rid;
  (* anyseq *) logic [3:0][63:0] target_rdata;
  (* anyseq *) logic [3:0][1:0] target_rresp;
  (* anyseq *) logic [2:0][15:0] busy_bitmap;
  (* anyseq *) logic [2:0] manager_rready;
  logic [3:0] target_rready, target_r_fire;
  logic [2:0] manager_rvalid, manager_r_fire, r_complete_fire, response_admit_fire;
  logic [2:0][3:0] manager_rid, r_complete_id;
  logic [2:0][63:0] manager_rdata;
  logic [2:0][1:0] manager_rresp;
  logic [2:0] manager_rlast, slot_valid, lock_active;
  logic [2:0][1:0] slot_source_target, lock_target;
  logic [2:0][5:0] lock_internal_id;
  logic [3:0] invalid_manager_violation, nonbusy_id_violation, locked_rid_violation;
  integer init_cycles=0;
  integer m, t;

  axi_r_response_router dut(
    .ACLK,.ARESETn,.target_rvalid,.target_rid,.target_rdata,.target_rresp,.target_rlast,
    .target_rready,.target_r_fire,.busy_bitmap,.manager_rvalid,.manager_rid,
    .manager_rdata,.manager_rresp,.manager_rlast,.manager_rready,.manager_r_fire,
    .r_complete_fire,.r_complete_id,.invalid_manager_violation,.nonbusy_id_violation,
    .locked_rid_violation,.response_admit_fire,.slot_valid,.slot_source_target,
    .lock_active,.lock_target,.lock_internal_id
  );

  function automatic logic busy_at(input logic [1:0] mi, input logic [3:0] id);
    begin
      case (mi)
        2'b00: busy_at = busy_bitmap[0][id];
        2'b01: busy_at = busy_bitmap[1][id];
        2'b10: busy_at = busy_bitmap[2][id];
        default: busy_at = 1'b0;
      endcase
    end
  endfunction

  initial assume(!ARESETn);
  always @(posedge ACLK) begin
    if (init_cycles < 2) begin assume(!ARESETn); init_cycles = init_cycles + 1; end
    if ($initstate) assume(!ARESETn);
    if ($past(ARESETn)) assume(ARESETn);
    if (ARESETn) begin
      // AXI stability is per independent target source.
      for (t=0; t<4; t=t+1) begin
        if ($past(ARESETn && target_rvalid[t] && !target_rready[t])) begin
          assume(target_rvalid[t]);
          assume(target_rid[t] == $past(target_rid[t]));
          assume(target_rdata[t] == $past(target_rdata[t]));
          assume(target_rresp[t] == $past(target_rresp[t]));
          assume(target_rlast[t] == $past(target_rlast[t]));
        end
        if (target_rready[t]) begin
          assert(target_rvalid[t]);
          assert(target_rid[t][5:4] != 2'b11);
          assert(busy_at(target_rid[t][5:4], target_rid[t][3:0]));
        end
        if (target_r_fire[t]) begin
          assert(target_rvalid[t] && target_rready[t]);
          assert(response_admit_fire[target_rid[t][5:4]] ||
                 lock_active[target_rid[t][5:4]]);
        end
      end

      for (m=0; m<3; m=m+1) begin
        assert(r_complete_fire[m] == (manager_rvalid[m] && manager_rready[m] && manager_rlast[m]));
        assert(r_complete_id[m] == manager_rid[m]);
        assert(response_admit_fire[m] ==
               ((target_r_fire[0] && target_rid[0][5:4]==m[1:0]) ||
                (target_r_fire[1] && target_rid[1][5:4]==m[1:0]) ||
                (target_r_fire[2] && target_rid[2][5:4]==m[1:0]) ||
                (target_r_fire[3] && target_rid[3][5:4]==m[1:0])));
        if (lock_active[m]) begin
          for (t=0; t<4; t=t+1)
            if (target_rready[t] && target_rid[t][5:4] == m[1:0]) begin
              assert(t[1:0] == lock_target[m]);
              assert(target_rid[t] == lock_internal_id[m]);
            end
        end
        if (ARESETn && !manager_rready[m] &&
            $past(ARESETn && slot_valid[m] && !manager_rready[m])) begin
          assert(slot_valid[m]);
          assert(lock_active[m] == $past(lock_active[m]));
        end
        if (ARESETn && $past(ARESETn && slot_valid[m] && manager_rready[m] && manager_rlast[m])) begin
          assert($past(r_complete_fire[m]));
          assert(!slot_valid[m]);
          assert(!lock_active[m]);
        end
        if (ARESETn && $past(ARESETn && lock_active[m] && !r_complete_fire[m]) && !r_complete_fire[m]) begin
          assert(lock_active[m]);
        end
        if (slot_valid[m] && !manager_rready[m]) begin
          assert(!response_admit_fire[m]);
          for (t=0; t<4; t=t+1)
            if (target_rid[t][5:4] == m[1:0])
              assert(!target_rready[t]);
        end
      end

      // A first-beat target handshake establishes the exact source/RID lock.
      for (m=0; m<3; m=m+1) begin
        for (t=0; t<4; t=t+1) begin
          if ($past(ARESETn && target_r_fire[t] && !lock_active[m] && target_rid[t][5:4]==m[1:0])) begin
            assert(lock_active[m]);
            assert(lock_target[m] == t[1:0]);
          end
        end
      end
    end
  end

  always @(posedge ACLK) begin
    cover(ARESETn && response_admit_fire[0]);
    cover(ARESETn && lock_active[0] && slot_valid[0]);
    cover(ARESETn && lock_active[0] && !slot_valid[0] && !target_rvalid[0] && target_rvalid[1]);
    cover(ARESETn && manager_r_fire[0] && r_complete_fire[0]);
    cover(ARESETn && response_admit_fire[0] && response_admit_fire[1] && response_admit_fire[2]);
  end
endmodule
