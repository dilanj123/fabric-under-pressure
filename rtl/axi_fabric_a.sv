// The top intentionally retains diagnostic, admission-metadata and structural
// observation nets from the composed primitives. They are consumed by focused
// integration assertions and future verification harnesses; some are not part
// of the external production interface.
/* verilator lint_off PINCONNECTEMPTY */
/* verilator lint_off UNUSEDSIGNAL */
/* verilator lint_off SYNCASYNCNET */
module axi_fabric_a (
  input logic ACLK,
  input logic ARESETn,

  input logic [2:0][3:0]  manager_awid,
  input logic [2:0][31:0] manager_awaddr,
  input logic [2:0][7:0]  manager_awlen,
  input logic [2:0][2:0]  manager_awsize,
  input logic [2:0][1:0]  manager_awburst,
  input logic [2:0]       manager_awlock,
  input logic [2:0][3:0]  manager_awcache,
  input logic [2:0][2:0]  manager_awprot,
  input logic [2:0][3:0]  manager_awqos,
  input logic [2:0][3:0]  manager_awregion,
  input logic [2:0]       manager_awvalid,
  output logic [2:0]      manager_awready,

  input logic [2:0][63:0] manager_wdata,
  input logic [2:0][7:0]  manager_wstrb,
  input logic [2:0]       manager_wlast,
  input logic [2:0]       manager_wvalid,
  output logic [2:0]      manager_wready,

  output logic [2:0][3:0] manager_bid,
  output logic [2:0][1:0] manager_bresp,
  output logic [2:0]      manager_bvalid,
  input logic [2:0]       manager_bready,

  input logic [2:0][3:0]  manager_arid,
  input logic [2:0][31:0] manager_araddr,
  input logic [2:0][7:0]  manager_arlen,
  input logic [2:0][2:0]  manager_arsize,
  input logic [2:0][1:0]  manager_arburst,
  input logic [2:0]       manager_arlock,
  input logic [2:0][3:0]  manager_arcache,
  input logic [2:0][2:0]  manager_arprot,
  input logic [2:0][3:0]  manager_arqos,
  input logic [2:0][3:0]  manager_arregion,
  input logic [2:0]       manager_arvalid,
  output logic [2:0]      manager_arready,

  output logic [2:0][3:0] manager_rid,
  output logic [2:0][63:0] manager_rdata,
  output logic [2:0][1:0] manager_rresp,
  output logic [2:0]       manager_rlast,
  output logic [2:0]       manager_rvalid,
  input logic [2:0]        manager_rready,

  output logic [2:0][5:0] target_awid,
  output logic [2:0][31:0] target_awaddr,
  output logic [2:0][7:0] target_awlen,
  output logic [2:0][2:0] target_awsize,
  output logic [2:0][1:0] target_awburst,
  output logic [2:0]       target_awlock,
  output logic [2:0][3:0] target_awcache,
  output logic [2:0][2:0] target_awprot,
  output logic [2:0][3:0] target_awqos,
  output logic [2:0][3:0] target_awregion,
  output logic [2:0]       target_awvalid,
  input logic [2:0]        target_awready,

  output logic [2:0][63:0] target_wdata,
  output logic [2:0][7:0]  target_wstrb,
  output logic [2:0]       target_wlast,
  output logic [2:0]       target_wvalid,
  input logic [2:0]        target_wready,

  input logic [2:0][5:0]   target_bid,
  input logic [2:0][1:0]   target_bresp,
  input logic [2:0]        target_bvalid,
  output logic [2:0]       target_bready,

  output logic [2:0][5:0]  target_arid,
  output logic [2:0][31:0] target_araddr,
  output logic [2:0][7:0]  target_arlen,
  output logic [2:0][2:0] target_arsize,
  output logic [2:0][1:0] target_arburst,
  output logic [2:0]      target_arlock,
  output logic [2:0][3:0] target_arcache,
  output logic [2:0][2:0] target_arprot,
  output logic [2:0][3:0] target_arqos,
  output logic [2:0][3:0] target_arregion,
  output logic [2:0]      target_arvalid,
  input logic [2:0]       target_arready,

  input logic [2:0][5:0]  target_rid,
  input logic [2:0][63:0] target_rdata,
  input logic [2:0][1:0]  target_rresp,
  input logic [2:0]       target_rlast,
  input logic [2:0]       target_rvalid,
  output logic [2:0]      target_rready
);
  logic [2:0][3:0] aw_decoded, ar_decoded;
  logic [2:0] aw_legal, ar_legal;
  logic [3:0][2:0] aw_match_t, ar_match_t;

  logic [3:0][2:0] aw_ready_t, aw_fire_t;
  logic [3:0] aw_admit_t;
  logic [3:0][3:0] aw_adm_id_t, aw_adm_target_t;
  logic [3:0][5:0] aw_adm_iid_t;
  logic [3:0][7:0] aw_adm_len_t;
  logic [3:0] aw_valid_t;
  logic [3:0][5:0] aw_id_t;
  logic [3:0][31:0] aw_addr_t;
  logic [3:0][7:0] aw_len_t;
  logic [3:0][2:0] aw_size_t, aw_prot_t;
  logic [3:0][1:0] aw_burst_t;
  logic [3:0] aw_lock_t;
  logic [3:0][3:0] aw_cache_t, aw_qos_t, aw_region_t;
  logic [3:0] aw_target_ready_t, aw_target_fire_t;

  logic [3:0][2:0] w_ready_t, w_fire_t, owner_w_fire_t, owner_wlast_t;
  logic [3:0] w_valid_t, w_last_t, w_target_ready_t, w_target_fire_t;
  logic [3:0][63:0] w_data_t;
  logic [3:0][7:0] w_strb_t;
  logic [3:0][1:0] w_selected_manager_t;

  logic [3:0][2:0] ar_ready_t, ar_fire_t;
  logic [3:0] ar_admit_t;
  logic [3:0][3:0] ar_adm_id_t, ar_adm_target_t;
  logic [3:0][5:0] ar_adm_iid_t;
  logic [3:0][7:0] ar_adm_len_t;
  logic [3:0] ar_valid_t;
  logic [3:0][5:0] ar_id_t;
  logic [3:0][31:0] ar_addr_t;
  logic [3:0][7:0] ar_len_t;
  logic [3:0][2:0] ar_size_t, ar_prot_t;
  logic [3:0][1:0] ar_burst_t;
  logic [3:0] ar_lock_t;
  logic [3:0][3:0] ar_cache_t, ar_qos_t, ar_region_t;
  logic [3:0] ar_target_ready_t, ar_target_fire_t;

  logic [2:0] outstanding_w_allowed, owner_active, state_allowed;
  logic [2:0][15:0] write_busy;
  logic [2:0][2:0] write_count;
  logic [2:0][3:0] owner_target, owner_id;
  logic [2:0][5:0] owner_internal_id;
  logic [2:0][4:0] owner_beats;
  logic [2:0] owner_expected_wlast;

  logic [2:0] outstanding_r_allowed;
  logic [2:0][15:0] read_busy;
  logic [2:0][2:0] read_count;

  logic [2:0] aw_state_fire;
  logic [2:0][3:0] aw_state_id_bus, aw_state_target;
  logic [2:0][5:0] aw_state_iid;
  logic [2:0][7:0] aw_state_len;
  logic [2:0] w_state_fire, w_state_last;
  logic [2:0] b_complete_fire;
  logic [2:0][3:0] b_complete_id;

  logic [2:0] ar_state_fire;
  logic [2:0][3:0] ar_state_id, ar_state_target, r_complete_id;
  logic [2:0][7:0] ar_state_len;
  logic [2:0] r_complete_fire;

  logic [3:0] b_valid_all, b_ready_all, b_fire_all;
  logic [3:0][5:0] b_id_all;
  logic [3:0][1:0] b_resp_all;
  logic [2:0] b_router_valid, b_router_fire;
  logic [2:0][3:0] b_router_id;
  logic [2:0][1:0] b_router_resp;
  logic [3:0] b_invalid, b_nonbusy;
  logic [2:0] b_admit;
  logic [2:0][1:0] b_source;

  logic [3:0] r_valid_all, r_ready_all, r_fire_all, r_last_all;
  logic [3:0][5:0] r_id_all;
  logic [3:0][63:0] r_data_all;
  logic [3:0][1:0] r_resp_all;
  logic [2:0] r_router_valid, r_router_fire, r_router_last;
  logic [2:0][3:0] r_router_id;
  logic [2:0][63:0] r_router_data;
  logic [2:0][1:0] r_router_resp;
  logic [3:0] r_invalid, r_nonbusy, r_locked;
  logic [2:0] r_admit, r_lock_active;
  logic [2:0][1:0] r_source, r_lock_target;
  logic [2:0][5:0] r_lock_iid;

  logic s3_awready, s3_wready, s3_awvalid, s3_wvalid, s3_wlast;
  logic [5:0] s3_awid, s3_bid, s3_arid, s3_rid;
  logic [31:0] s3_awaddr, s3_araddr;
  logic [7:0] s3_awlen, s3_arlen;
  logic [2:0] s3_awsize, s3_arsize, s3_awprot, s3_arprot;
  logic [1:0] s3_awburst, s3_arburst, s3_bresp, s3_rresp;
  logic s3_awlock, s3_arlock, s3_bvalid, s3_bready, s3_arvalid, s3_arready, s3_rvalid, s3_rready, s3_rlast;
  logic [3:0] s3_awcache, s3_awqos, s3_awregion, s3_arcache, s3_arqos, s3_arregion;
  logic [63:0] s3_wdata, s3_rdata;
  logic [7:0] s3_wstrb;

  always_comb begin
    for (integer mt=0; mt<4; mt=mt+1) begin
      for (integer mm=0; mm<3; mm=mm+1) begin
        // Decoder output is one-hot: S0=0001, S1=0010, S2=0100,
        // S3=1000. The target-path parameter is a binary index.
        aw_match_t[mt][mm] = (aw_decoded[mm] == (4'b0001 << mt));
        ar_match_t[mt][mm] = (ar_decoded[mm] == (4'b0001 << mt));
      end
    end
  end

  genvar g;
  generate
    for (g=0; g<3; g=g+1) begin : gen_decode
      axi_address_decoder u_aw_decode(.addr(manager_awaddr[g]), .target_select(aw_decoded[g]));
      axi_request_legal u_aw_legal(.addr(manager_awaddr[g]), .len(manager_awlen[g]), .size(manager_awsize[g]), .burst(manager_awburst[g]), .lock(manager_awlock[g]), .request_legal(aw_legal[g]));
      axi_address_decoder u_ar_decode(.addr(manager_araddr[g]), .target_select(ar_decoded[g]));
      axi_request_legal u_ar_legal(.addr(manager_araddr[g]), .len(manager_arlen[g]), .size(manager_arsize[g]), .burst(manager_arburst[g]), .lock(manager_arlock[g]), .request_legal(ar_legal[g]));
    end
    for (g=0; g<4; g=g+1) begin : gen_paths
      axi_aw_target_path_a #(.TARGET_INDEX(g)) u_aw (
        .ACLK,.ARESETn,.manager_awvalid,.manager_awid,.manager_awaddr,.manager_awlen,.manager_awsize,.manager_awburst,.manager_awlock,.manager_awcache,.manager_awprot,.manager_awqos,.manager_awregion,
        .request_legal(aw_legal), .target_match(aw_match_t[g]), .outstanding_allowed(outstanding_w_allowed),
        .owner_active,.owner_target_m0(owner_target[0]),.owner_target_m1(owner_target[1]),.owner_target_m2(owner_target[2]),
        .target_awready(aw_target_ready_t[g]), .manager_awready(aw_ready_t[g]), .manager_aw_fire(aw_fire_t[g]), .aw_admit_fire(aw_admit_t[g]),
        .admitted_manager(),.admitted_awid(aw_adm_id_t[g]),.admitted_internal_id(aw_adm_iid_t[g]),.admitted_target(aw_adm_target_t[g]),.admitted_awlen(aw_adm_len_t[g]),
        .target_awvalid(aw_valid_t[g]),.target_awid(aw_id_t[g]),.target_awaddr(aw_addr_t[g]),.target_awlen(aw_len_t[g]),.target_awsize(aw_size_t[g]),.target_awburst(aw_burst_t[g]),.target_awlock(aw_lock_t[g]),.target_awcache(aw_cache_t[g]),.target_awprot(aw_prot_t[g]),.target_awqos(aw_qos_t[g]),.target_awregion(aw_region_t[g]),.target_aw_fire(aw_target_fire_t[g])
      );
      axi_ar_target_path_a #(.TARGET_INDEX(g)) u_ar (
        .ACLK,.ARESETn,.manager_arvalid,.manager_arid,.manager_araddr,.manager_arlen,.manager_arsize,.manager_arburst,.manager_arlock,.manager_arcache,.manager_arprot,.manager_arqos,.manager_arregion,
        .request_legal(ar_legal), .target_match(ar_match_t[g]), .outstanding_allowed(outstanding_r_allowed),
        .target_arready(ar_target_ready_t[g]), .manager_arready(ar_ready_t[g]), .manager_ar_fire(ar_fire_t[g]), .ar_admit_fire(ar_admit_t[g]),
        .admitted_manager(),.admitted_arid(ar_adm_id_t[g]),.admitted_internal_id(ar_adm_iid_t[g]),.admitted_target(ar_adm_target_t[g]),.admitted_arlen(ar_adm_len_t[g]),
        .target_arvalid(ar_valid_t[g]),.target_arid(ar_id_t[g]),.target_araddr(ar_addr_t[g]),.target_arlen(ar_len_t[g]),.target_arsize(ar_size_t[g]),.target_arburst(ar_burst_t[g]),.target_arlock(ar_lock_t[g]),.target_arcache(ar_cache_t[g]),.target_arprot(ar_prot_t[g]),.target_arqos(ar_qos_t[g]),.target_arregion(ar_region_t[g]),.target_ar_fire(ar_target_fire_t[g])
      );
      axi_w_target_path #(.TARGET_INDEX(g)) u_w (
        .ACLK,.ARESETn,.manager_wvalid,.manager_wdata,.manager_wstrb,.manager_wlast,.owner_active,.owner_target,
        .target_wready(w_target_ready_t[g]),.manager_wready(w_ready_t[g]),.manager_w_fire(w_fire_t[g]),
        .target_wvalid(w_valid_t[g]),.target_wdata(w_data_t[g]),.target_wstrb(w_strb_t[g]),.target_wlast(w_last_t[g]),.target_w_fire(w_target_fire_t[g]),
        .selected_manager(w_selected_manager_t[g]),.selected_owner_valid(),.owner_conflict_violation(),.owner_w_fire(owner_w_fire_t[g]),.owner_wlast(owner_wlast_t[g])
      );
    end
  endgenerate

  axi_write_state_bank write_state (
    .ACLK,.ARESETn,.request_awid(manager_awid),.aw_admit_fire(aw_state_fire),.aw_admit_id(aw_state_id_bus),
    .aw_admit_internal_id(aw_state_iid),.aw_admit_target(aw_state_target),.aw_admit_len(aw_state_len),
    .w_fire(w_state_fire),.wlast(w_state_last),.b_complete_fire,.b_complete_id,
    .outstanding_allowed(outstanding_w_allowed),.busy_bitmap(write_busy),.outstanding_count(write_count),
    .owner_active,.owner_target,.owner_id,.owner_internal_id,.owner_beats_remaining(owner_beats),.owner_expected_wlast,
    .state_allowed,.commit_fire(),.admission_state_violation(),.outstanding_violation(),.owner_violation()
  );

  axi_read_state_bank read_state (
    .ACLK,.ARESETn,.request_arid(manager_arid),.ar_admit_fire(ar_state_fire),.ar_admit_id(ar_state_id),
    .ar_admit_target(ar_state_target),.ar_admit_len(ar_state_len),.r_complete_fire,.r_complete_id,
    .outstanding_allowed(outstanding_r_allowed),.busy_bitmap(read_busy),.outstanding_count(read_count),
    .admission_state_violation(),.outstanding_violation(),.commit_fire()
  );

  axi_s3_error_target s3 (
    .ACLK,.ARESETn,.awid(s3_awid),.awaddr(s3_awaddr),.awlen(s3_awlen),.awsize(s3_awsize),.awburst(s3_awburst),.awlock(s3_awlock),.awcache(s3_awcache),.awprot(s3_awprot),.awqos(s3_awqos),.awregion(s3_awregion),.awvalid(s3_awvalid),.awready(s3_awready),
    .wdata(s3_wdata),.wstrb(s3_wstrb),.wlast(s3_wlast),.wvalid(s3_wvalid),.wready(s3_wready),.bid(s3_bid),.bresp(s3_bresp),.bvalid(s3_bvalid),.bready(s3_bready),
    .arid(s3_arid),.araddr(s3_araddr),.arlen(s3_arlen),.arsize(s3_arsize),.arburst(s3_arburst),.arlock(s3_arlock),.arcache(s3_arcache),.arprot(s3_arprot),.arqos(s3_arqos),.arregion(s3_arregion),.arvalid(s3_arvalid),.arready(s3_arready),
    .rid(s3_rid),.rdata(s3_rdata),.rresp(s3_rresp),.rlast(s3_rlast),.rvalid(s3_rvalid),.rready(s3_rready),.early_wlast_violation(),.missing_wlast_violation(),.w_without_aw_violation(),.write_active(),.write_id(),.write_beats_remaining(),.read_active(),.read_id(),.read_beats_remaining()
  );

  always_comb begin
    aw_state_fire='0; aw_state_id_bus='0; aw_state_iid='0; aw_state_target='0; aw_state_len='0;
    w_state_fire='0; w_state_last='0;
    ar_state_fire='0; ar_state_id='0; ar_state_target='0; ar_state_len='0;
    for (integer m=0;m<3;m=m+1) begin
      for (integer t=0;t<4;t=t+1) begin
        if (aw_fire_t[t][m]) begin
          aw_state_fire[m]=1; aw_state_id_bus[m]=aw_adm_id_t[t]; aw_state_iid[m]=aw_adm_iid_t[t]; aw_state_target[m]=aw_adm_target_t[t]; aw_state_len[m]=aw_adm_len_t[t];
        end
        if (ar_fire_t[t][m]) begin
          ar_state_fire[m]=1; ar_state_id[m]=ar_adm_id_t[t]; ar_state_target[m]=ar_adm_target_t[t]; ar_state_len[m]=ar_adm_len_t[t];
        end
        if (owner_w_fire_t[t][m]) begin
          w_state_fire[m]=1;
          w_state_last[m]=owner_wlast_t[t][m];
        end
      end
    end
  end

  always_comb begin
    manager_awready='0; manager_arready='0; manager_wready='0;
    for (integer m=0;m<3;m=m+1) begin
      for (integer t=0;t<4;t=t+1) begin
        manager_awready[m] |= aw_ready_t[t][m];
        manager_arready[m] |= ar_ready_t[t][m];
        manager_wready[m] |= w_ready_t[t][m];
      end
    end
    for (integer t=0;t<3;t=t+1) begin
      target_awid[t]=aw_id_t[t]; target_awaddr[t]=aw_addr_t[t]; target_awlen[t]=aw_len_t[t]; target_awsize[t]=aw_size_t[t]; target_awburst[t]=aw_burst_t[t]; target_awlock[t]=aw_lock_t[t]; target_awcache[t]=aw_cache_t[t]; target_awprot[t]=aw_prot_t[t]; target_awqos[t]=aw_qos_t[t]; target_awregion[t]=aw_region_t[t]; target_awvalid[t]=aw_valid_t[t]; aw_target_ready_t[t]=target_awready[t];
      target_wdata[t]=w_data_t[t]; target_wstrb[t]=w_strb_t[t]; target_wlast[t]=w_last_t[t]; target_wvalid[t]=w_valid_t[t]; w_target_ready_t[t]=target_wready[t];
      target_arid[t]=ar_id_t[t]; target_araddr[t]=ar_addr_t[t]; target_arlen[t]=ar_len_t[t]; target_arsize[t]=ar_size_t[t]; target_arburst[t]=ar_burst_t[t]; target_arlock[t]=ar_lock_t[t]; target_arcache[t]=ar_cache_t[t]; target_arprot[t]=ar_prot_t[t]; target_arqos[t]=ar_qos_t[t]; target_arregion[t]=ar_region_t[t]; target_arvalid[t]=ar_valid_t[t]; ar_target_ready_t[t]=target_arready[t];
    end
    target_bready=b_ready_all[2:0]; target_rready=r_ready_all[2:0];
    s3_awvalid=aw_valid_t[3]; s3_awid=aw_id_t[3]; s3_awaddr=aw_addr_t[3]; s3_awlen=aw_len_t[3]; s3_awsize=aw_size_t[3]; s3_awburst=aw_burst_t[3]; s3_awlock=aw_lock_t[3]; s3_awcache=aw_cache_t[3]; s3_awprot=aw_prot_t[3]; s3_awqos=aw_qos_t[3]; s3_awregion=aw_region_t[3]; aw_target_ready_t[3]=s3_awready;
    s3_wvalid=w_valid_t[3]; s3_wdata=w_data_t[3]; s3_wstrb=w_strb_t[3]; s3_wlast=w_last_t[3]; w_target_ready_t[3]=s3_wready;
    s3_arvalid=ar_valid_t[3]; s3_arid=ar_id_t[3]; s3_araddr=ar_addr_t[3]; s3_arlen=ar_len_t[3]; s3_arsize=ar_size_t[3]; s3_arburst=ar_burst_t[3]; s3_arlock=ar_lock_t[3]; s3_arcache=ar_cache_t[3]; s3_arprot=ar_prot_t[3]; s3_arqos=ar_qos_t[3]; s3_arregion=ar_region_t[3]; ar_target_ready_t[3]=s3_arready;
  end

  always_comb begin
    b_valid_all='0; b_id_all='0; b_resp_all='0;
    b_valid_all[2:0]=target_bvalid; b_id_all[2:0]=target_bid; b_resp_all[2:0]=target_bresp;
    b_valid_all[3]=s3_bvalid; b_id_all[3]=s3_bid; b_resp_all[3]=s3_bresp;
    r_valid_all='0; r_id_all='0; r_data_all='0; r_resp_all='0; r_last_all='0;
    r_valid_all[2:0]=target_rvalid; r_id_all[2:0]=target_rid; r_data_all[2:0]=target_rdata; r_resp_all[2:0]=target_rresp; r_last_all[2:0]=target_rlast;
    r_valid_all[3]=s3_rvalid; r_id_all[3]=s3_rid; r_data_all[3]=s3_rdata; r_resp_all[3]=s3_rresp; r_last_all[3]=s3_rlast;
  end

  axi_b_response_router b_router(.ACLK,.ARESETn,.target_bvalid(b_valid_all),.target_bid(b_id_all),.target_bresp(b_resp_all),.target_bready(b_ready_all),.target_b_fire(b_fire_all),.busy_bitmap(write_busy),.manager_bvalid(b_router_valid),.manager_bid(b_router_id),.manager_bresp(b_router_resp),.manager_bready,.manager_b_fire(b_router_fire),.b_complete_fire,.b_complete_id,.invalid_manager_violation(b_invalid),.nonbusy_id_violation(b_nonbusy),.response_admit_fire(b_admit),.slot_valid(),.slot_source_target(b_source));
  assign manager_bvalid=b_router_valid; assign manager_bid=b_router_id; assign manager_bresp=b_router_resp;
  assign s3_bready=b_ready_all[3];

  axi_r_response_router r_router(.ACLK,.ARESETn,.target_rvalid(r_valid_all),.target_rid(r_id_all),.target_rdata(r_data_all),.target_rresp(r_resp_all),.target_rlast(r_last_all),.target_rready(r_ready_all),.target_r_fire(r_fire_all),.busy_bitmap(read_busy),.manager_rvalid(r_router_valid),.manager_rid(r_router_id),.manager_rdata(r_router_data),.manager_rresp(r_router_resp),.manager_rlast(r_router_last),.manager_rready,.manager_r_fire(r_router_fire),.r_complete_fire,.r_complete_id,.invalid_manager_violation(r_invalid),.nonbusy_id_violation(r_nonbusy),.locked_rid_violation(r_locked),.response_admit_fire(r_admit),.slot_valid(),.slot_source_target(r_source),.lock_active(r_lock_active),.lock_target(r_lock_target),.lock_internal_id(r_lock_iid));
  assign manager_rvalid=r_router_valid; assign manager_rid=r_router_id; assign manager_rdata=r_router_data; assign manager_rresp=r_router_resp; assign manager_rlast=r_router_last;
  assign s3_rready=r_ready_all[3];

`ifndef SYNTHESIS
  // Composition invariants: each manager-facing contribution is the OR of
  // mutually exclusive target-path handshakes, and shared state sees one
  // admission/progress event at most once per manager and cycle.
  always_ff @(posedge ACLK) begin
    if (ARESETn) begin
      for (integer am=0; am<3; am=am+1) begin
        assert ($onehot0({aw_ready_t[3][am],aw_ready_t[2][am],aw_ready_t[1][am],aw_ready_t[0][am]}));
        assert ($onehot0({aw_fire_t[3][am],aw_fire_t[2][am],aw_fire_t[1][am],aw_fire_t[0][am]}));
        assert ($onehot0({ar_ready_t[3][am],ar_ready_t[2][am],ar_ready_t[1][am],ar_ready_t[0][am]}));
        assert ($onehot0({ar_fire_t[3][am],ar_fire_t[2][am],ar_fire_t[1][am],ar_fire_t[0][am]}));
        assert ($onehot0({w_ready_t[3][am],w_ready_t[2][am],w_ready_t[1][am],w_ready_t[0][am]}));
        assert ($onehot0({owner_w_fire_t[3][am],owner_w_fire_t[2][am],owner_w_fire_t[1][am],owner_w_fire_t[0][am]}));
        assert (aw_state_fire[am] == (manager_awvalid[am] && manager_awready[am]));
        assert (ar_state_fire[am] == (manager_arvalid[am] && manager_arready[am]));
      end
    end
  end
`endif

endmodule
/* verilator lint_on UNUSEDSIGNAL */
/* verilator lint_on PINCONNECTEMPTY */
/* verilator lint_on SYNCASYNCNET */
