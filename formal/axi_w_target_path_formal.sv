module axi_w_target_path_formal(input logic ACLK);
  (* anyseq *) logic ARESETn;
  (* anyseq *) logic [2:0] manager_wvalid, manager_wlast, owner_active;
  (* anyseq *) logic [2:0][63:0] manager_wdata;
  (* anyseq *) logic [2:0][7:0] manager_wstrb;
  (* anyseq *) logic [2:0][3:0] owner_target;
  (* anyseq *) logic target_wready;

  logic [2:0] manager_wready, manager_w_fire;
  logic target_wvalid, target_wlast, target_w_fire;
  logic [63:0] target_wdata;
  logic [7:0] target_wstrb;
  logic [1:0] selected_manager;
  logic selected_owner_valid, owner_conflict_violation;
  logic [2:0] owner_w_fire, owner_wlast;

  axi_w_target_path #(.TARGET_INDEX(0)) dut (.*);

  initial assume (!ARESETn);
  integer m;
  always @(posedge ACLK) begin
    if (ARESETn) begin
      for (m = 0; m < 3; m = m + 1) begin
        if ($past(manager_wvalid[m] && !manager_wready[m])) begin
          assume (manager_wvalid[m]);
          assume (manager_wdata[m] == $past(manager_wdata[m]));
          assume (manager_wstrb[m] == $past(manager_wstrb[m]));
          assume (manager_wlast[m] == $past(manager_wlast[m]));
        end
      end
      assert ($onehot0(manager_wready));
      assert ($onehot0(manager_w_fire));
      assert ($onehot0(owner_w_fire));
      assert ($onehot0(owner_wlast));
      assert (owner_w_fire == 3'b000 || target_w_fire);
      assert (owner_wlast == 3'b000 || target_w_fire);
      assert (owner_conflict_violation || !selected_owner_valid ||
              ((selected_manager == 2'b00 && owner_active[0] && owner_target[0][0]) ||
               (selected_manager == 2'b01 && owner_active[1] && owner_target[1][0]) ||
               (selected_manager == 2'b10 && owner_active[2] && owner_target[2][0])));
      if (owner_conflict_violation) assert (manager_wready == 3'b000);
      if (!selected_owner_valid) assert (manager_wready == 3'b000);
      if (manager_wready[0]) assert (owner_active[0] && owner_target[0][0]);
      if (manager_wready[1]) assert (owner_active[1] && owner_target[1][0]);
      if (manager_wready[2]) assert (owner_active[2] && owner_target[2][0]);
      if (target_wvalid && target_wready && target_wlast)
        assert (manager_w_fire == 3'b000);
      if ($past(target_wvalid && target_wready && target_wlast))
        assert (!target_wvalid);
      if ($past(target_wvalid && !target_wready)) begin
        assert (target_wvalid);
        assert (target_wdata == $past(target_wdata));
        assert (target_wstrb == $past(target_wstrb));
        assert (target_wlast == $past(target_wlast));
      end
    end else begin
      assert (manager_wready == 3'b000);
      assert (manager_w_fire == 3'b000);
      assert (!target_wvalid);
      assert (owner_w_fire == 3'b000);
    end
  end

  always @(posedge ACLK) begin
    cover (ARESETn && !selected_owner_valid && manager_wvalid != 3'b000);
    cover (ARESETn && selected_owner_valid && manager_w_fire != 3'b000);
    cover (ARESETn && target_wvalid && !target_wready);
    cover (ARESETn && target_wvalid && target_wready && !target_wlast &&
           manager_w_fire != 3'b000);
    cover (ARESETn && target_wvalid && target_wready && target_wlast);
    cover (ARESETn && owner_conflict_violation);
  end
endmodule
