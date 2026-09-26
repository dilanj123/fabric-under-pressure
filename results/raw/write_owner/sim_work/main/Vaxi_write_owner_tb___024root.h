// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vaxi_write_owner_tb.h for the primary calling header

#ifndef VERILATED_VAXI_WRITE_OWNER_TB___024ROOT_H_
#define VERILATED_VAXI_WRITE_OWNER_TB___024ROOT_H_  // guard

#include "verilated.h"
#include "verilated_timing.h"


class Vaxi_write_owner_tb__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vaxi_write_owner_tb___024root final {
  public:

    // DESIGN-SPECIFIC STATE
    CData/*0:0*/ axi_write_owner_tb__DOT__ACLK;
    CData/*0:0*/ axi_write_owner_tb__DOT__ARESETn;
    CData/*0:0*/ axi_write_owner_tb__DOT__allocate_fire;
    CData/*0:0*/ axi_write_owner_tb__DOT__w_fire;
    CData/*0:0*/ axi_write_owner_tb__DOT__wlast;
    CData/*3:0*/ axi_write_owner_tb__DOT__allocate_target;
    CData/*3:0*/ axi_write_owner_tb__DOT__allocate_id;
    CData/*5:0*/ axi_write_owner_tb__DOT__allocate_internal_id;
    CData/*7:0*/ axi_write_owner_tb__DOT__allocate_len;
    CData/*0:0*/ axi_write_owner_tb__DOT__allocate_allowed;
    CData/*0:0*/ axi_write_owner_tb__DOT__allocate_violation;
    CData/*0:0*/ axi_write_owner_tb__DOT__w_without_owner_violation;
    CData/*0:0*/ axi_write_owner_tb__DOT__wlast_mismatch_violation;
    CData/*0:0*/ axi_write_owner_tb__DOT__dut__DOT__active_q;
    CData/*3:0*/ axi_write_owner_tb__DOT__dut__DOT__target_q;
    CData/*3:0*/ axi_write_owner_tb__DOT__dut__DOT__id_q;
    CData/*5:0*/ axi_write_owner_tb__DOT__dut__DOT__internal_id_q;
    CData/*4:0*/ axi_write_owner_tb__DOT__dut__DOT__beats_q;
    CData/*0:0*/ __Vtrigprevexpr___TOP__axi_write_owner_tb__DOT__ACLK__0;
    CData/*0:0*/ __Vtrigprevexpr___TOP__axi_write_owner_tb__DOT__ARESETn__0;
    IData/*31:0*/ axi_write_owner_tb__DOT__checks;
    IData/*31:0*/ __Vi;
    VlUnpacked<QData/*63:0*/, 1> __VstlTriggered;
    VlUnpacked<QData/*63:0*/, 1> __VicoTriggered;
    VlUnpacked<QData/*63:0*/, 1> __VactTriggered;
    VlUnpacked<QData/*63:0*/, 1> __VactTriggeredAcc;
    VlUnpacked<QData/*63:0*/, 1> __VnbaTriggered;
    std::string __Vtask_axi_write_owner_tb__DOT__check__0__message;
    std::string __Vtask_axi_write_owner_tb__DOT__check__1__message;
    std::string __Vtask_axi_write_owner_tb__DOT__check__3__message;
    std::string __Vtask_axi_write_owner_tb__DOT__check__4__message;
    std::string __Vtask_axi_write_owner_tb__DOT__check__5__message;
    std::string __Vtask_axi_write_owner_tb__DOT__check__7__message;
    std::string __Vtask_axi_write_owner_tb__DOT__check__9__message;
    std::string __Vtask_axi_write_owner_tb__DOT__check__11__message;
    std::string __Vtask_axi_write_owner_tb__DOT__check__13__message;
    std::string __Vtask_axi_write_owner_tb__DOT__check__15__message;
    std::string __Vtask_axi_write_owner_tb__DOT__check__17__message;
    std::string __Vtask_axi_write_owner_tb__DOT__check__19__message;
    std::string __Vtask_axi_write_owner_tb__DOT__check__21__message;
    std::string __Vtask_axi_write_owner_tb__DOT__check__23__message;
    std::string __Vtask_axi_write_owner_tb__DOT__check__25__message;
    std::string __Vtask_axi_write_owner_tb__DOT__check__27__message;
    std::string __Vtask_axi_write_owner_tb__DOT__check__30__message;
    std::string __Vtask_axi_write_owner_tb__DOT__check__32__message;
    std::string __Vtask_axi_write_owner_tb__DOT__check__33__message;
    std::string __Vtask_axi_write_owner_tb__DOT__check__34__message;
    std::string __Vtask_axi_write_owner_tb__DOT__check__37__message;
    std::string __Vtask_axi_write_owner_tb__DOT__check__38__message;
    VlDelayScheduler __VdlySched;
    VlTriggerScheduler __VtrigSched_h3bfb1e69__0;
    VlTriggerScheduler __VtrigSched_h3bfb1db6__0;

    // INTERNAL VARIABLES
    Vaxi_write_owner_tb__Syms* vlSymsp;
    const char* vlNamep;

    // CONSTRUCTORS
    Vaxi_write_owner_tb___024root(Vaxi_write_owner_tb__Syms* symsp, const char* namep);
    ~Vaxi_write_owner_tb___024root();
    VL_UNCOPYABLE(Vaxi_write_owner_tb___024root);

    // INTERNAL METHODS
};


#endif  // guard
