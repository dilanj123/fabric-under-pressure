module axi_aw_w_state_composition_tb;
  logic ACLK = 0;
  always #5 ACLK = ~ACLK;
  logic ARESETn;

  logic [2:0] awvalid, awlegal, awmatch;
  logic [2:0][3:0] awid;
  logic [2:0][31:0] awaddr;
  logic [2:0][7:0] awlen;
  logic [2:0][2:0] awsize;
  logic [2:0][1:0] awburst;
  logic [2:0] awlock;
  logic [2:0][3:0] awcache, awqos, awregion;
  logic [2:0][2:0] awprot;
  logic aw_target_ready;
  logic [2:0] awready, awfire;
  logic aw_admit_fire;
  logic [1:0] admitted_manager;
  logic [3:0] admitted_awid, admitted_target;
  logic [5:0] admitted_internal_id;
  logic [7:0] admitted_len;
  logic target_awvalid, target_awready, target_awfire;
  logic [5:0] target_awid;
  logic [31:0] target_awaddr;
  logic [7:0] target_awlen;
  logic [2:0] target_awsize;
  logic [1:0] target_awburst;
  logic target_awlock;
  logic [3:0] target_awcache, target_awqos, target_awregion;
  logic [2:0] target_awprot;

  logic [2:0] outstanding_allowed;
  logic [2:0][15:0] busy_bitmap;
  logic [2:0][2:0] outstanding_count;
  logic [2:0] owner_active;
  logic [2:0][3:0] owner_target, owner_id;
  logic [2:0][5:0] owner_internal_id;
  logic [2:0][4:0] owner_beats_remaining;
  logic [2:0] owner_expected_wlast;
  logic [2:0] state_allowed, commit_fire, admission_state_violation;
  logic [2:0] outstanding_violation, owner_violation;
  logic [2:0] bank_w_fire, bank_wlast, b_complete_fire;
  logic [2:0][3:0] b_complete_id;
  logic [2:0][3:0] admit_id, admit_target;
  logic [2:0][5:0] admit_internal_id;
  logic [2:0][7:0] admit_len;

  logic [2:0] wvalid, wlast, wready, wfire;
  logic [2:0][63:0] wdata;
  logic [2:0][7:0] wstrb;
  logic target_wready, target_wvalid, target_wlast, target_wfire;
  logic [63:0] target_wdata;
  logic [7:0] target_wstrb;
  logic [1:0] selected_w_manager;
  logic selected_owner_valid, owner_conflict_violation;
  logic [2:0] owner_w_fire, owner_wlast;
  integer checks = 0;

  axi_aw_target_path_a #(.TARGET_INDEX(0)) u_aw (
    .ACLK(ACLK), .ARESETn(ARESETn),
    .manager_awvalid(awvalid), .manager_awid(awid), .manager_awaddr(awaddr),
    .manager_awlen(awlen), .manager_awsize(awsize), .manager_awburst(awburst),
    .manager_awlock(awlock), .manager_awcache(awcache), .manager_awprot(awprot),
    .manager_awqos(awqos), .manager_awregion(awregion),
    .request_legal(awlegal), .target_match(awmatch),
    .outstanding_allowed(outstanding_allowed), .owner_active(owner_active),
    .owner_target_m0(owner_target[0]), .owner_target_m1(owner_target[1]),
    .owner_target_m2(owner_target[2]), .target_awready(aw_target_ready),
    .manager_awready(awready), .manager_aw_fire(awfire),
    .aw_admit_fire(aw_admit_fire), .admitted_manager(admitted_manager),
    .admitted_awid(admitted_awid), .admitted_internal_id(admitted_internal_id),
    .admitted_target(admitted_target), .admitted_awlen(admitted_len),
    .target_awvalid(target_awvalid), .target_awid(target_awid),
    .target_awaddr(target_awaddr), .target_awlen(target_awlen),
    .target_awsize(target_awsize), .target_awburst(target_awburst),
    .target_awlock(target_awlock), .target_awcache(target_awcache),
    .target_awprot(target_awprot), .target_awqos(target_awqos),
    .target_awregion(target_awregion), .target_aw_fire(target_awfire)
  );

  always_comb begin
    admit_id = awid;
    admit_target = '0;
    admit_target[0] = 4'b0001;
    admit_target[1] = 4'b0001;
    admit_target[2] = 4'b0001;
    admit_internal_id[0] = {2'b00, awid[0]};
    admit_internal_id[1] = {2'b01, awid[1]};
    admit_internal_id[2] = {2'b10, awid[2]};
    admit_len = awlen;
  end

  axi_write_state_bank u_bank (
    .ACLK(ACLK), .ARESETn(ARESETn), .request_awid(awid),
    .aw_admit_fire(awfire), .aw_admit_id(admit_id),
    .aw_admit_internal_id(admit_internal_id), .aw_admit_target(admit_target),
    .aw_admit_len(admit_len), .w_fire(bank_w_fire), .wlast(bank_wlast),
    .b_complete_fire(b_complete_fire), .b_complete_id(b_complete_id),
    .outstanding_allowed(outstanding_allowed), .busy_bitmap(busy_bitmap),
    .outstanding_count(outstanding_count), .owner_active(owner_active),
    .owner_target(owner_target), .owner_id(owner_id),
    .owner_internal_id(owner_internal_id),
    .owner_beats_remaining(owner_beats_remaining),
    .owner_expected_wlast(owner_expected_wlast), .state_allowed(state_allowed),
    .commit_fire(commit_fire), .admission_state_violation(admission_state_violation),
    .outstanding_violation(outstanding_violation), .owner_violation(owner_violation)
  );

  axi_w_target_path #(.TARGET_INDEX(0)) u_w (
    .ACLK(ACLK), .ARESETn(ARESETn), .manager_wvalid(wvalid),
    .manager_wdata(wdata), .manager_wstrb(wstrb), .manager_wlast(wlast),
    .owner_active(owner_active), .owner_target(owner_target),
    .target_wready(target_wready), .manager_wready(wready),
    .manager_w_fire(wfire), .target_wvalid(target_wvalid),
    .target_wdata(target_wdata), .target_wstrb(target_wstrb),
    .target_wlast(target_wlast), .target_w_fire(target_wfire),
    .selected_manager(selected_w_manager),
    .selected_owner_valid(selected_owner_valid),
    .owner_conflict_violation(owner_conflict_violation),
    .owner_w_fire(owner_w_fire), .owner_wlast(owner_wlast)
  );
  assign bank_w_fire = owner_w_fire;
  assign bank_wlast = owner_wlast;

  task automatic check(input logic condition, input string message);
    begin checks = checks + 1; if (!condition) begin $display("FAIL: %s", message); $fatal(1); end end
  endtask
  task automatic clear_inputs;
    begin
      awvalid='0; awlegal=3'b111; awmatch=3'b111; awid='0; awaddr='0;
      awlen='0; awsize='0; awburst='0; awlock='0; awcache='0; awqos='0;
      awregion='0; awprot='0; aw_target_ready=1; target_awready=1;
      wvalid='0; wlast='0; wdata='0; wstrb='0; target_wready=0;
      b_complete_fire='0; b_complete_id='0;
    end
  endtask
  task automatic tick; begin @(posedge ACLK); #1; end endtask

  initial begin
    clear_inputs(); ARESETn=0; tick(); tick(); ARESETn=1; tick();

    // W-before-AW is held until AW admission creates registered ownership.
    awid[1]=4'h9; awlen[1]=8'd0; awvalid[1]=1; awmatch[1]=1;
    wvalid[1]=1; wdata[1]=64'h1111; wstrb[1]=8'hf0; wlast[1]=1;
    #1; check(wready == 0, "W-before-AW is blocked");
    tick();
    #1; check(wready == 0 && awready == 3'b010, "AW selection after registered RR grant");
    tick();
    check(owner_active[1] && busy_bitmap[1][9] && outstanding_count[1] == 1,
          "AW admission atomically allocates shared owner and outstanding state");
    check(wready == 3'b010, "W becomes ready after registered owner allocation");
    target_wready=0; tick();
    check(target_wvalid && target_wdata == 64'h1111 && owner_active[1],
          "manager W admission fills stalled target slot without releasing owner");
    target_wready=1; #1; check(target_wfire && owner_w_fire == 3'b010, "target delivery drives owner event");
    tick();
    check(!owner_active[1] && busy_bitmap[1][9] && outstanding_count[1] == 1,
          "final target W clears owner but not outstanding write");
    b_complete_fire[1]=1; b_complete_id[1]=4'h9; tick(); b_complete_fire[1]=0;
    check(!busy_bitmap[1][9] && outstanding_count[1] == 0, "B completion alone clears outstanding state");

    // Same-cycle AW/W: the pre-state owner is absent, so WREADY is low.
    awvalid='0; wvalid='0; awid[0]=4'h3; awlen[0]=0; awvalid[0]=1;
    wvalid[0]=1; wdata[0]=64'h2222; wstrb[0]=8'h0f; wlast[0]=1; target_wready=1;
    tick();
    #1; check(awready == 3'b001 && wready == 3'b000, "same-cycle AW/W keeps WREADY low");
    tick(); check(owner_active[0] && wready == 3'b001, "owner enables W next cycle");
    tick(); check(target_wvalid && target_wdata == 64'h2222, "same-cycle AW/W payload waits then routes");
    #1; tick(); check(!owner_active[0], "single-beat owner clears on target W delivery");

    // Complete the same-cycle single-beat owner, then populate independent
    // manager lanes sequentially. Simultaneous different-manager bank
    // admissions are covered by the shared-bank regression.
    tick(); tick();
    awvalid='0; wvalid='0; awid[0]=4'h1; awlen[0]=0;
    awvalid[0]=1; awmatch[0]=1; tick(); #1; check(awready[0], "M0 second admission available"); tick();
    check(owner_active[0] && outstanding_count[0] == 2 && outstanding_count[2] == 0,
          "shared state remains manager-indexed");

    $display("PASS axi_aw_w_state_composition_tb checks=%0d", checks);
    $finish;
  end
endmodule
