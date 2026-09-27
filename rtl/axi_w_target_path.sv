// One logical-target registered W datapath.
// W routing is driven only by the registered shared write-owner context.
module axi_w_target_path #(
  parameter integer TARGET_INDEX = 0
) (
  input  logic       ACLK,
  input  logic       ARESETn,

  input  logic [2:0]       manager_wvalid,
  input  logic [2:0][63:0] manager_wdata,
  input  logic [2:0][7:0]  manager_wstrb,
  input  logic [2:0]       manager_wlast,

  input  logic [2:0]       owner_active,
  input  logic [2:0][3:0]  owner_target,

  input  logic             target_wready,

  output logic [2:0]       manager_wready,
  output logic [2:0]       manager_w_fire,

  output logic             target_wvalid,
  output logic [63:0]      target_wdata,
  output logic [7:0]       target_wstrb,
  output logic             target_wlast,
  output logic             target_w_fire,

  output logic [1:0]       selected_manager,
  output logic             selected_owner_valid,
  output logic             owner_conflict_violation,

  output logic [2:0]       owner_w_fire,
  output logic [2:0]       owner_wlast
);
  logic [2:0] owner_match;
  logic       slot_valid_q;
  logic [1:0] slot_manager_q;
  logic [63:0] slot_wdata_q;
  logic [7:0]  slot_wstrb_q;
  logic        slot_wlast_q;
  logic        slot_can_accept;
  logic        target_draining;

  always_comb begin
    owner_match[0] = owner_active[0] && owner_target[0][TARGET_INDEX];
    owner_match[1] = owner_active[1] && owner_target[1][TARGET_INDEX];
    owner_match[2] = owner_active[2] && owner_target[2][TARGET_INDEX];

    owner_conflict_violation = ARESETn &&
      ((owner_match[0] && owner_match[1]) ||
       (owner_match[0] && owner_match[2]) ||
       (owner_match[1] && owner_match[2]));

    selected_manager = 2'b00;
    if (owner_match[1])
      selected_manager = 2'b01;
    else if (owner_match[2])
      selected_manager = 2'b10;
    selected_owner_valid = ARESETn && !owner_conflict_violation &&
                           (|owner_match);

    target_wvalid = ARESETn && slot_valid_q;
    target_wdata = slot_wdata_q;
    target_wstrb = slot_wstrb_q;
    target_wlast = slot_wlast_q;
    target_w_fire = target_wvalid && target_wready;
    target_draining = target_w_fire;

    slot_can_accept = !slot_valid_q ||
                      (target_draining && !slot_wlast_q);

    manager_wready = 3'b000;
    if (selected_owner_valid && slot_can_accept) begin
      case (selected_manager)
        2'b00: manager_wready[0] = 1'b1;
        2'b01: manager_wready[1] = 1'b1;
        2'b10: manager_wready[2] = 1'b1;
        default: manager_wready = 3'b000;
      endcase
    end
    manager_w_fire = manager_wvalid & manager_wready;

    owner_w_fire = 3'b000;
    owner_wlast = 3'b000;
    if (target_w_fire) begin
      case (slot_manager_q)
        2'b00: begin owner_w_fire[0] = 1'b1; owner_wlast[0] = slot_wlast_q; end
        2'b01: begin owner_w_fire[1] = 1'b1; owner_wlast[1] = slot_wlast_q; end
        2'b10: begin owner_w_fire[2] = 1'b1; owner_wlast[2] = slot_wlast_q; end
        default: begin end
      endcase
    end
  end

  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      slot_valid_q <= 1'b0;
      slot_manager_q <= 2'b00;
      slot_wdata_q <= 64'b0;
      slot_wstrb_q <= 8'b0;
      slot_wlast_q <= 1'b0;
    end else if (target_w_fire && slot_wlast_q) begin
      // A final beat cannot be replaced on its delivery cycle.
      slot_valid_q <= 1'b0;
      slot_manager_q <= 2'b00;
      slot_wdata_q <= 64'b0;
      slot_wstrb_q <= 8'b0;
      slot_wlast_q <= 1'b0;
    end else if (|manager_w_fire) begin
      slot_valid_q <= 1'b1;
      case (selected_manager)
        2'b00: begin
          slot_manager_q <= 2'b00;
          slot_wdata_q <= manager_wdata[0];
          slot_wstrb_q <= manager_wstrb[0];
          slot_wlast_q <= manager_wlast[0];
        end
        2'b01: begin
          slot_manager_q <= 2'b01;
          slot_wdata_q <= manager_wdata[1];
          slot_wstrb_q <= manager_wstrb[1];
          slot_wlast_q <= manager_wlast[1];
        end
        2'b10: begin
          slot_manager_q <= 2'b10;
          slot_wdata_q <= manager_wdata[2];
          slot_wstrb_q <= manager_wstrb[2];
          slot_wlast_q <= manager_wlast[2];
        end
        default: begin
          slot_manager_q <= 2'b00;
          slot_wdata_q <= 64'b0;
          slot_wstrb_q <= 8'b0;
          slot_wlast_q <= 1'b0;
        end
      endcase
    end else if (target_w_fire) begin
      slot_valid_q <= 1'b0;
      slot_manager_q <= 2'b00;
      slot_wdata_q <= 64'b0;
      slot_wstrb_q <= 8'b0;
      slot_wlast_q <= 1'b0;
    end
  end
endmodule
