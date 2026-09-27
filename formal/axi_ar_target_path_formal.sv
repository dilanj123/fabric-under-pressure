module axi_ar_target_path_formal(input logic ACLK);
  (* anyseq *) logic ARESETn;
  (* anyseq *) logic [2:0] manager_arvalid, request_legal, target_match;
  (* anyseq *) logic [2:0][3:0] manager_arid;
  (* anyseq *) logic [2:0][31:0] manager_araddr;
  (* anyseq *) logic [2:0][7:0] manager_arlen;
  (* anyseq *) logic [2:0][2:0] manager_arsize, manager_arprot;
  (* anyseq *) logic [2:0][1:0] manager_arburst;
  (* anyseq *) logic [2:0] manager_arlock;
  (* anyseq *) logic [2:0][3:0] manager_arcache, manager_arqos, manager_arregion;
  (* anyseq *) logic target_arready;
  logic [2:0] manager_arready, manager_ar_fire;
  logic ar_admit_fire; logic [1:0] admitted_manager; logic [3:0] admitted_arid, admitted_target;
  logic [5:0] admitted_internal_id; logic [7:0] admitted_arlen;
  logic target_arvalid; logic [5:0] target_arid; logic [31:0] target_araddr; logic [7:0] target_arlen;
  logic [2:0] target_arsize, target_arprot; logic [1:0] target_arburst; logic target_arlock;
  logic [3:0] target_arcache,target_arqos,target_arregion; logic target_ar_fire;
  logic [2:0] formal_scheduler_request, formal_raw_eligible, formal_grant;
  logic formal_scheduler_ar_accept, formal_grant_valid; logic [1:0] formal_selected_manager;
  logic [3:0] formal_selected_arid; logic [31:0] formal_selected_araddr; logic [7:0] formal_selected_arlen;
  logic [2:0] formal_selected_arsize, formal_selected_arprot; logic [1:0] formal_selected_arburst; logic formal_selected_arlock;
  logic [3:0] formal_selected_arcache,formal_selected_arqos,formal_selected_arregion;
  axi_ar_target_path_a #(.TARGET_INDEX(0)) dut(
    .ACLK,.ARESETn,.manager_arvalid,.manager_arid,.manager_araddr,.manager_arlen,.manager_arsize,.manager_arburst,.manager_arlock,.manager_arcache,.manager_arprot,.manager_arqos,.manager_arregion,
    .request_legal,.target_match,.outstanding_allowed(3'b111),.target_arready,.manager_arready,.manager_ar_fire,.ar_admit_fire,.admitted_manager,.admitted_arid,.admitted_internal_id,.admitted_target,.admitted_arlen,
    .target_arvalid,.target_arid,.target_araddr,.target_arlen,.target_arsize,.target_arburst,.target_arlock,.target_arcache,.target_arprot,.target_arqos,.target_arregion,.target_ar_fire,
    .formal_scheduler_request,.formal_scheduler_ar_accept,.formal_raw_eligible,.formal_grant,.formal_grant_valid,.formal_selected_manager,.formal_selected_arid,.formal_selected_araddr,.formal_selected_arlen,.formal_selected_arsize,.formal_selected_arburst,.formal_selected_arlock,.formal_selected_arcache,.formal_selected_arprot,.formal_selected_arqos,.formal_selected_arregion);
  initial assume(!ARESETn);
  integer m;
  always @(posedge ACLK) begin
    if ($initstate) assume(!ARESETn);
    if ($past(ARESETn)) assume(ARESETn);
    if (ARESETn) begin
      assert($onehot0(manager_arready));
      assert($onehot0(manager_ar_fire));
      assert(formal_raw_eligible == (manager_arvalid & request_legal & target_match & 3'b111));
      assert(ar_admit_fire == (|manager_ar_fire));
      assert(manager_arready == (manager_arready & formal_grant));
      assert(!formal_scheduler_ar_accept || formal_scheduler_request == 3'b000);
      if (|manager_arready) assert(formal_grant_valid);
      assert(formal_grant_valid == (formal_grant != 3'b000));
      assert($onehot0(formal_grant));
      if (ar_admit_fire) assert(formal_scheduler_ar_accept);
      if (target_arvalid) assert(!ar_admit_fire);
      assert(target_ar_fire == (target_arvalid && target_arready));
    end else begin
      assert(!target_arvalid && !ar_admit_fire);
    end
  end
  always @(posedge ACLK) begin
    if (ARESETn) begin
      if ($past(ar_admit_fire)) begin
        assert(target_arvalid);
        assert(target_arid == $past(admitted_internal_id));
        assert(target_araddr == $past(formal_selected_araddr));
        assert(target_arlen == $past(admitted_arlen));
        assert(target_arsize == $past(formal_selected_arsize));
        assert(target_arburst == $past(formal_selected_arburst));
        assert(target_arlock == $past(formal_selected_arlock));
        assert(target_arcache == $past(formal_selected_arcache));
        assert(target_arprot == $past(formal_selected_arprot));
        assert(target_arqos == $past(formal_selected_arqos));
        assert(target_arregion == $past(formal_selected_arregion));
      end
      if ($past(target_arvalid && !target_arready)) begin
        assert(target_arvalid);
        assert(target_arid == $past(target_arid));
        assert(target_araddr == $past(target_araddr));
        assert(target_arlen == $past(target_arlen));
        assert(target_arsize == $past(target_arsize));
        assert(target_arburst == $past(target_arburst));
        assert(target_arlock == $past(target_arlock));
        assert(target_arcache == $past(target_arcache));
        assert(target_arprot == $past(target_arprot));
        assert(target_arqos == $past(target_arqos));
        assert(target_arregion == $past(target_arregion));
      end
    end
  end
  always @(posedge ACLK) begin
    cover(ARESETn && ar_admit_fire && admitted_manager==2'b00);
    cover(ARESETn && ar_admit_fire && admitted_manager==2'b01);
    cover(ARESETn && ar_admit_fire && admitted_manager==2'b10);
    cover(ARESETn && target_arvalid && !target_arready);
    cover(ARESETn && target_arvalid && target_arready);
    cover(ARESETn && $past(target_ar_fire) && ar_admit_fire);
  end
endmodule
