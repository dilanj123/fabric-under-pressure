// One logical-target Architecture-A AR channel boundary.
// Manager-facing AR admission allocates shared read state; target AR consumes
// only the registered one-entry address slot.
module axi_ar_target_path_a #(
  parameter integer TARGET_INDEX = 0
) (
  input  logic       ACLK,
  input  logic       ARESETn,
  input  logic [2:0] manager_arvalid,
  input  logic [2:0][3:0] manager_arid,
  input  logic [2:0][31:0] manager_araddr,
  input  logic [2:0][7:0] manager_arlen,
  input  logic [2:0][2:0] manager_arsize,
  input  logic [2:0][1:0] manager_arburst,
  input  logic [2:0] manager_arlock,
  input  logic [2:0][3:0] manager_arcache,
  input  logic [2:0][2:0] manager_arprot,
  input  logic [2:0][3:0] manager_arqos,
  input  logic [2:0][3:0] manager_arregion,
  input  logic [2:0] request_legal,
  input  logic [2:0] target_match,
  input  logic [2:0] outstanding_allowed,
  input  logic       target_arready,
  output logic [2:0] manager_arready,
  output logic [2:0] manager_ar_fire,
  output logic       ar_admit_fire,
  output logic [1:0] admitted_manager,
  output logic [3:0] admitted_arid,
  output logic [5:0] admitted_internal_id,
  output logic [3:0] admitted_target,
  output logic [7:0] admitted_arlen,
  output logic       target_arvalid,
  output logic [5:0] target_arid,
  output logic [31:0] target_araddr,
  output logic [7:0] target_arlen,
  output logic [2:0] target_arsize,
  output logic [1:0] target_arburst,
  output logic       target_arlock,
  output logic [3:0] target_arcache,
  output logic [2:0] target_arprot,
  output logic [3:0] target_arqos,
  output logic [3:0] target_arregion,
  output logic       target_ar_fire
`ifdef FORMAL
  , output logic [2:0] formal_scheduler_request
  , output logic       formal_scheduler_ar_accept
  , output logic [2:0] formal_raw_eligible
  , output logic [2:0] formal_grant
  , output logic       formal_grant_valid
  , output logic [1:0] formal_selected_manager
  , output logic [3:0] formal_selected_arid
  , output logic [31:0] formal_selected_araddr
  , output logic [7:0] formal_selected_arlen
  , output logic [2:0] formal_selected_arsize
  , output logic [1:0] formal_selected_arburst
  , output logic formal_selected_arlock
  , output logic [3:0] formal_selected_arcache
  , output logic [2:0] formal_selected_arprot
  , output logic [3:0] formal_selected_arqos
  , output logic [3:0] formal_selected_arregion
`endif
);
  logic [2:0] raw_eligible, grant;
  logic grant_valid;
  logic [1:0] selected_manager;
  logic scheduler_ar_accept_fire;
  logic slot_valid_q, slot_capture_allowed;
  logic [3:0] selected_arid;
  logic [31:0] selected_araddr;
  logic [7:0] selected_arlen;
  logic [2:0] selected_arsize;
  logic [1:0] selected_arburst;
  logic selected_arlock;
  logic [3:0] selected_arcache;
  logic [2:0] selected_arprot;
  logic [3:0] selected_arqos, selected_arregion;
  logic [5:0] selected_internal_id;
  logic [5:0] slot_arid_q;
  logic [31:0] slot_araddr_q;
  logic [7:0] slot_arlen_q;
  logic [2:0] slot_arsize_q;
  logic [1:0] slot_arburst_q;
  logic slot_arlock_q;
  logic [3:0] slot_arcache_q;
  logic [2:0] slot_arprot_q;
  logic [3:0] slot_arqos_q, slot_arregion_q;

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
    selected_arid = 4'b0; selected_araddr = 32'b0; selected_arlen = 8'b0;
    selected_arsize = 3'b0; selected_arburst = 2'b0; selected_arlock = 1'b0;
    selected_arcache = 4'b0; selected_arprot = 3'b0; selected_arqos = 4'b0;
    selected_arregion = 4'b0;
    case (selected_manager)
      2'b00: begin
        selected_arid=manager_arid[0]; selected_araddr=manager_araddr[0];
        selected_arlen=manager_arlen[0]; selected_arsize=manager_arsize[0];
        selected_arburst=manager_arburst[0]; selected_arlock=manager_arlock[0];
        selected_arcache=manager_arcache[0]; selected_arprot=manager_arprot[0];
        selected_arqos=manager_arqos[0]; selected_arregion=manager_arregion[0];
      end
      2'b01: begin
        selected_arid=manager_arid[1]; selected_araddr=manager_araddr[1];
        selected_arlen=manager_arlen[1]; selected_arsize=manager_arsize[1];
        selected_arburst=manager_arburst[1]; selected_arlock=manager_arlock[1];
        selected_arcache=manager_arcache[1]; selected_arprot=manager_arprot[1];
        selected_arqos=manager_arqos[1]; selected_arregion=manager_arregion[1];
      end
      2'b10: begin
        selected_arid=manager_arid[2]; selected_araddr=manager_araddr[2];
        selected_arlen=manager_arlen[2]; selected_arsize=manager_arsize[2];
        selected_arburst=manager_arburst[2]; selected_arlock=manager_arlock[2];
        selected_arcache=manager_arcache[2]; selected_arprot=manager_arprot[2];
        selected_arqos=manager_arqos[2]; selected_arregion=manager_arregion[2];
      end
      default: begin end
    endcase
  end

  assign selected_internal_id = {selected_manager, selected_arid};
  assign slot_capture_allowed = !slot_valid_q;

  axi_ar_target_scheduler_a u_scheduler (
    .ACLK(ACLK), .ARESETn(ARESETn), .request_present(manager_arvalid),
    .request_legal(request_legal), .target_match(target_match),
    .outstanding_allowed(outstanding_allowed), .target_ready(slot_capture_allowed),
    .raw_eligible(raw_eligible), .grant(grant), .grant_valid(grant_valid),
    .selected_manager(selected_manager), .ar_accept_fire(scheduler_ar_accept_fire)
`ifdef FORMAL
    ,.formal_arbiter_request(formal_scheduler_request)
`endif
  );

  always_comb begin
    manager_arready = grant & {3{slot_capture_allowed && ARESETn &&
                                 grant_valid && scheduler_ar_accept_fire &&
                                 (raw_eligible != 3'b000)}};
    manager_ar_fire = manager_arvalid & manager_arready;
    ar_admit_fire = (|manager_ar_fire) && ARESETn;
    admitted_manager = selected_manager;
    admitted_arid = selected_arid;
    admitted_internal_id = selected_internal_id;
    admitted_target = target_mask(TARGET_INDEX);
    admitted_arlen = selected_arlen;
    target_arvalid = slot_valid_q && ARESETn;
    target_arid = slot_arid_q; target_araddr = slot_araddr_q; target_arlen = slot_arlen_q;
    target_arsize = slot_arsize_q; target_arburst = slot_arburst_q;
    target_arlock = slot_arlock_q; target_arcache = slot_arcache_q;
    target_arprot = slot_arprot_q; target_arqos = slot_arqos_q;
    target_arregion = slot_arregion_q;
    target_ar_fire = target_arvalid && target_arready;
`ifdef FORMAL
    formal_scheduler_ar_accept = scheduler_ar_accept_fire && ARESETn;
    formal_raw_eligible = raw_eligible; formal_grant = grant;
    formal_grant_valid = grant_valid; formal_selected_manager = selected_manager;
    formal_selected_arid = selected_arid; formal_selected_araddr = selected_araddr;
    formal_selected_arlen = selected_arlen; formal_selected_arsize = selected_arsize;
    formal_selected_arburst = selected_arburst; formal_selected_arlock = selected_arlock;
    formal_selected_arcache = selected_arcache; formal_selected_arprot = selected_arprot;
    formal_selected_arqos = selected_arqos; formal_selected_arregion = selected_arregion;
`endif
  end

  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      slot_valid_q<=1'b0; slot_arid_q<=6'b0; slot_araddr_q<=32'b0; slot_arlen_q<=8'b0;
      slot_arsize_q<=3'b0; slot_arburst_q<=2'b0; slot_arlock_q<=1'b0;
      slot_arcache_q<=4'b0; slot_arprot_q<=3'b0; slot_arqos_q<=4'b0; slot_arregion_q<=4'b0;
    end else if (target_ar_fire) begin
      slot_valid_q<=1'b0; slot_arid_q<=6'b0; slot_araddr_q<=32'b0; slot_arlen_q<=8'b0;
      slot_arsize_q<=3'b0; slot_arburst_q<=2'b0; slot_arlock_q<=1'b0;
      slot_arcache_q<=4'b0; slot_arprot_q<=3'b0; slot_arqos_q<=4'b0; slot_arregion_q<=4'b0;
    end else if (ar_admit_fire) begin
      slot_valid_q<=1'b1; slot_arid_q<=selected_internal_id; slot_araddr_q<=selected_araddr;
      slot_arlen_q<=selected_arlen; slot_arsize_q<=selected_arsize; slot_arburst_q<=selected_arburst;
      slot_arlock_q<=selected_arlock; slot_arcache_q<=selected_arcache; slot_arprot_q<=selected_arprot;
      slot_arqos_q<=selected_arqos; slot_arregion_q<=selected_arregion;
    end
  end
endmodule
