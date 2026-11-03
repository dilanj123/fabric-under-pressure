module axi_qos_aging_arbiter_3_formal(input logic ACLK);
  (* anyseq *) logic ARESETn;
  (* anyseq *) logic [2:0] legal_pending, eligible;
  (* anyseq *) logic [2:0][3:0] qos;
  (* anyseq *) logic accept;
  logic [2:0] grant, candidate, starved, normal_set, grant_next;
  logic grant_valid, grant_valid_next;
  logic [1:0] selected_manager, pointer, selected_next, pointer_next;
  logic [2:0][7:0] age, age_next;

  axi_qos_aging_arbiter_3 dut (
    .ACLK, .ARESETn, .legal_pending, .eligible, .qos, .accept,
    .grant, .grant_valid, .selected_manager, .age, .pointer,
    .formal_candidate(candidate), .formal_starved(starved),
    .formal_normal_set(normal_set), .formal_age_next(age_next),
    .formal_pointer_next(pointer_next), .formal_grant_next(grant_next),
    .formal_grant_valid_next(grant_valid_next), .formal_selected_next(selected_next)
  );

  function automatic logic [1:0] next_pointer(input logic [1:0] winner);
    case (winner)
      0: next_pointer=1;
      1: next_pointer=2;
      default: next_pointer=0;
    endcase
  endfunction

  function automatic logic [2:0] rr_pick(input logic [2:0] set_bits,
                                           input logic [1:0] start);
    logic found;
    integer idx;
    begin
      rr_pick=0; found=0;
      for (integer n=0; n<3; n=n+1) begin
        idx=(start+n)%3;
        if (!found && set_bits[idx]) begin rr_pick[idx]=1; found=1; end
      end
    end
  endfunction

  initial assume (!ARESETn);
  always @* begin
    if (ARESETn) begin
      assume ((eligible & ~legal_pending)==0);
      if (accept) assume (grant_valid && (|(grant & eligible)));
      // Legal AXI requesters hold a selected address until it is admitted.
      if (grant_valid) assume (legal_pending[selected_manager]);
      assert ($onehot0(grant));
      assert (grant_valid == (grant != 0));
      if (grant_valid) assert (legal_pending[selected_manager]);
      assert ($onehot0(candidate));
      assert ((candidate & ~eligible)==0);
      if (|starved) begin
        assert ((candidate & ~starved)==0);
        assert (candidate == rr_pick(starved, pointer));
      end else if (|eligible) begin
        assert (candidate == rr_pick(normal_set, pointer));
        for (integer m=0; m<3; m=m+1)
          if (candidate[m])
            for (integer n=0; n<3; n=n+1)
              if (eligible[n]) assert (qos[m] >= qos[n]);
      end else assert (candidate==0);
    end else begin
      assert (age==0 && pointer==0 && grant==0 && !grant_valid);
    end
  end

  always @* begin
    if (ARESETn) begin
      for (integer m=0; m<3; m=m+1) begin
        if (!legal_pending[m] || (accept && grant[m])) assert (age_next[m]==0);
        else if (age[m]==8'hff) assert (age_next[m]==8'hff);
        else assert (age_next[m]==(age[m]+8'd1));
      end
      if (accept && grant_valid) begin
        assert (pointer_next==next_pointer(selected_manager));
        assert (grant_next==0 && !grant_valid_next);
      end else begin
        assert (pointer_next==pointer);
        if (grant_valid && legal_pending[selected_manager]) begin
          assert (grant_next==grant);
          assert (grant_valid_next);
          assert (selected_next==selected_manager);
        end else begin
          assert (grant_next==candidate);
          assert (grant_valid_next==(candidate!=0));
        end
      end
    end
  end

  always @* begin
    cover (ARESETn && age[0]==8'd63 && legal_pending[0]);
    cover (ARESETn && age[0]==8'd64 && eligible[0] && eligible[1] &&
           !starved[1] && candidate==3'b001);
    cover (ARESETn && starved[0] && starved[1] &&
           candidate==rr_pick(starved,pointer));
    cover (ARESETn && grant_valid && !accept);
  end
endmodule
