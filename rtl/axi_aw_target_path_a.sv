// One logical-target Architecture-A AW channel boundary.
// The manager-facing handshake is the Fabric admission event. An admitted AW
// is then held in one registered target-facing slot until target handshake.
module axi_aw_target_path_a #(
  parameter integer TARGET_INDEX = 0
) (
  input  logic       ACLK,
  input  logic       ARESETn,

  input  logic [2:0] manager_awvalid,
  input  logic [2:0][3:0] manager_awid,
  input  logic [2:0][31:0] manager_awaddr,
  input  logic [2:0][7:0] manager_awlen,
  input  logic [2:0][2:0] manager_awsize,
  input  logic [2:0][1:0] manager_awburst,
  input  logic [2:0]       manager_awlock,
  input  logic [2:0][3:0] manager_awcache,
  input  logic [2:0][2:0] manager_awprot,
  input  logic [2:0][3:0] manager_awqos,
  input  logic [2:0][3:0] manager_awregion,

  input  logic [2:0] request_legal,
  input  logic [2:0] target_match,
  input  logic [2:0] outstanding_allowed,
  input  logic [2:0] owner_active,
  input  logic [3:0] owner_target_m0,
  input  logic [3:0] owner_target_m1,
  input  logic [3:0] owner_target_m2,

  input  logic       target_awready,

  output logic [2:0] manager_awready,
  output logic [2:0] manager_aw_fire,
  output logic       aw_admit_fire,
  output logic [1:0] admitted_manager,
  output logic [3:0] admitted_awid,
  output logic [5:0] admitted_internal_id,
  output logic [3:0] admitted_target,
  output logic [7:0] admitted_awlen,

  output logic       target_awvalid,
  output logic [5:0] target_awid,
  output logic [31:0] target_awaddr,
  output logic [7:0] target_awlen,
  output logic [2:0] target_awsize,
  output logic [1:0] target_awburst,
  output logic       target_awlock,
  output logic [3:0] target_awcache,
  output logic [2:0] target_awprot,
  output logic [3:0] target_awqos,
  output logic [3:0] target_awregion,
  output logic       target_aw_fire
`ifdef FORMAL
  , output logic [2:0] formal_scheduler_request
  , output logic       formal_scheduler_aw_accept
  , output logic [2:0] formal_raw_eligible
  , output logic       formal_target_owner_busy
  , output logic [2:0] formal_grant
  , output logic       formal_grant_valid
  , output logic [1:0] formal_selected_manager
  , output logic [3:0] formal_selected_awid
  , output logic [31:0] formal_selected_awaddr
  , output logic [7:0] formal_selected_awlen
  , output logic [2:0] formal_selected_awsize
  , output logic [1:0] formal_selected_awburst
  , output logic       formal_selected_awlock
  , output logic [3:0] formal_selected_awcache
  , output logic [2:0] formal_selected_awprot
  , output logic [3:0] formal_selected_awqos
  , output logic [3:0] formal_selected_awregion
`endif
);
  logic [2:0] raw_eligible;
  logic       target_owner_busy;
  logic [2:0] grant;
  logic       grant_valid;
  logic [1:0] selected_manager;
  logic       scheduler_aw_accept_fire;
  logic       slot_valid_q;
  logic       slot_capture_allowed;

  logic [3:0] selected_awid;
  logic [31:0] selected_awaddr;
  logic [7:0] selected_awlen;
  logic [2:0] selected_awsize;
  logic [1:0] selected_awburst;
  logic       selected_awlock;
  logic [3:0] selected_awcache;
  logic [2:0] selected_awprot;
  logic [3:0] selected_awqos;
  logic [3:0] selected_awregion;
  logic [5:0] selected_internal_id;

  logic [5:0] slot_awid_q;
  logic [31:0] slot_awaddr_q;
  logic [7:0] slot_awlen_q;
  logic [2:0] slot_awsize_q;
  logic [1:0] slot_awburst_q;
  logic       slot_awlock_q;
  logic [3:0] slot_awcache_q;
  logic [2:0] slot_awprot_q;
  logic [3:0] slot_awqos_q;
  logic [3:0] slot_awregion_q;

  function automatic logic [3:0] target_mask(input integer index);
    begin
      case (index)
        0: target_mask = 4'b0001;
        1: target_mask = 4'b0010;
        2: target_mask = 4'b0100;
        3: target_mask = 4'b1000;
        default: target_mask = 4'b0000;
      endcase
    end
  endfunction

  always_comb begin
    selected_awid = 4'b0000;
    selected_awaddr = 32'h0000_0000;
    selected_awlen = 8'h00;
    selected_awsize = 3'b000;
    selected_awburst = 2'b00;
    selected_awlock = 1'b0;
    selected_awcache = 4'h0;
    selected_awprot = 3'b000;
    selected_awqos = 4'h0;
    selected_awregion = 4'h0;

    case (selected_manager)
      2'b00: begin
        selected_awid = manager_awid[0];
        selected_awaddr = manager_awaddr[0];
        selected_awlen = manager_awlen[0];
        selected_awsize = manager_awsize[0];
        selected_awburst = manager_awburst[0];
        selected_awlock = manager_awlock[0];
        selected_awcache = manager_awcache[0];
        selected_awprot = manager_awprot[0];
        selected_awqos = manager_awqos[0];
        selected_awregion = manager_awregion[0];
      end
      2'b01: begin
        selected_awid = manager_awid[1];
        selected_awaddr = manager_awaddr[1];
        selected_awlen = manager_awlen[1];
        selected_awsize = manager_awsize[1];
        selected_awburst = manager_awburst[1];
        selected_awlock = manager_awlock[1];
        selected_awcache = manager_awcache[1];
        selected_awprot = manager_awprot[1];
        selected_awqos = manager_awqos[1];
        selected_awregion = manager_awregion[1];
      end
      2'b10: begin
        selected_awid = manager_awid[2];
        selected_awaddr = manager_awaddr[2];
        selected_awlen = manager_awlen[2];
        selected_awsize = manager_awsize[2];
        selected_awburst = manager_awburst[2];
        selected_awlock = manager_awlock[2];
        selected_awcache = manager_awcache[2];
        selected_awprot = manager_awprot[2];
        selected_awqos = manager_awqos[2];
        selected_awregion = manager_awregion[2];
      end
      default: begin
      end
    endcase
  end

  assign selected_internal_id = {selected_manager, selected_awid};
  assign slot_capture_allowed = !slot_valid_q;

  axi_aw_target_scheduler_a #(.TARGET_INDEX(TARGET_INDEX)) u_scheduler (
    .ACLK(ACLK),
    .ARESETn(ARESETn),
    .request_present(manager_awvalid),
    .request_legal(request_legal),
    .target_match(target_match),
    .outstanding_allowed(outstanding_allowed),
    .owner_active(owner_active),
    .owner_target_m0(owner_target_m0),
    .owner_target_m1(owner_target_m1),
    .owner_target_m2(owner_target_m2),
    .target_ready(slot_capture_allowed),
    .raw_eligible(raw_eligible),
    .target_owner_busy(target_owner_busy),
    .grant(grant),
    .grant_valid(grant_valid),
    .selected_manager(selected_manager),
    .aw_accept_fire(scheduler_aw_accept_fire)
`ifdef FORMAL
    ,.formal_arbiter_request(formal_scheduler_request)
`endif
  );

  always_comb begin
    manager_awready = grant & {3{slot_capture_allowed && ARESETn &&
                                 grant_valid && !target_owner_busy &&
                                 scheduler_aw_accept_fire &&
                                 (raw_eligible != 3'b000)}};
    manager_aw_fire = manager_awvalid & manager_awready;
    // The manager-facing handshake is the authoritative admission event.
    // Legal AXI sources keep a held AWVALID/payload stable until this event,
    // so it corresponds to the scheduler acceptance in the supported subset.
    aw_admit_fire = (|manager_aw_fire) && ARESETn;

    admitted_manager = selected_manager;
    admitted_awid = selected_awid;
    admitted_internal_id = selected_internal_id;
    admitted_target = target_mask(TARGET_INDEX);
    admitted_awlen = selected_awlen;

    target_awvalid = slot_valid_q && ARESETn;
    target_awid = slot_awid_q;
    target_awaddr = slot_awaddr_q;
    target_awlen = slot_awlen_q;
    target_awsize = slot_awsize_q;
    target_awburst = slot_awburst_q;
    target_awlock = slot_awlock_q;
    target_awcache = slot_awcache_q;
    target_awprot = slot_awprot_q;
    target_awqos = slot_awqos_q;
    target_awregion = slot_awregion_q;
    target_aw_fire = target_awvalid && target_awready;
`ifdef FORMAL
    formal_scheduler_aw_accept = scheduler_aw_accept_fire && ARESETn;
    formal_raw_eligible = raw_eligible;
    formal_target_owner_busy = target_owner_busy;
    formal_grant = grant;
    formal_grant_valid = grant_valid;
    formal_selected_manager = selected_manager;
    formal_selected_awid = selected_awid;
    formal_selected_awaddr = selected_awaddr;
    formal_selected_awlen = selected_awlen;
    formal_selected_awsize = selected_awsize;
    formal_selected_awburst = selected_awburst;
    formal_selected_awlock = selected_awlock;
    formal_selected_awcache = selected_awcache;
    formal_selected_awprot = selected_awprot;
    formal_selected_awqos = selected_awqos;
    formal_selected_awregion = selected_awregion;
`endif
  end

  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      slot_valid_q <= 1'b0;
      slot_awid_q <= 6'b000000;
      slot_awaddr_q <= 32'h0000_0000;
      slot_awlen_q <= 8'h00;
      slot_awsize_q <= 3'b000;
      slot_awburst_q <= 2'b00;
      slot_awlock_q <= 1'b0;
      slot_awcache_q <= 4'h0;
      slot_awprot_q <= 3'b000;
      slot_awqos_q <= 4'h0;
      slot_awregion_q <= 4'h0;
    end else if (target_aw_fire) begin
      slot_valid_q <= 1'b0;
      slot_awid_q <= 6'b000000;
      slot_awaddr_q <= 32'h0000_0000;
      slot_awlen_q <= 8'h00;
      slot_awsize_q <= 3'b000;
      slot_awburst_q <= 2'b00;
      slot_awlock_q <= 1'b0;
      slot_awcache_q <= 4'h0;
      slot_awprot_q <= 3'b000;
      slot_awqos_q <= 4'h0;
      slot_awregion_q <= 4'h0;
    end else if (aw_admit_fire) begin
      slot_valid_q <= 1'b1;
      slot_awid_q <= selected_internal_id;
      slot_awaddr_q <= selected_awaddr;
      slot_awlen_q <= selected_awlen;
      slot_awsize_q <= selected_awsize;
      slot_awburst_q <= selected_awburst;
      slot_awlock_q <= selected_awlock;
      slot_awcache_q <= selected_awcache;
      slot_awprot_q <= selected_awprot;
      slot_awqos_q <= selected_awqos;
      slot_awregion_q <= selected_awregion;
    end
  end
endmodule
