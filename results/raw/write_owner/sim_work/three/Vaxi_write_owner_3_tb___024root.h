// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vaxi_write_owner_3_tb.h for the primary calling header

#ifndef VERILATED_VAXI_WRITE_OWNER_3_TB___024ROOT_H_
#define VERILATED_VAXI_WRITE_OWNER_3_TB___024ROOT_H_  // guard

#include "verilated.h"
#include "verilated_timing.h"


class Vaxi_write_owner_3_tb__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vaxi_write_owner_3_tb___024root final {
  public:

    // DESIGN-SPECIFIC STATE
    CData/*0:0*/ axi_write_owner_3_tb__DOT__ACLK;
    CData/*0:0*/ axi_write_owner_3_tb__DOT__ARESETn;
    CData/*2:0*/ axi_write_owner_3_tb__DOT__allocate_fire;
    CData/*2:0*/ axi_write_owner_3_tb__DOT__w_fire;
    CData/*2:0*/ axi_write_owner_3_tb__DOT__wlast;
    IData/*23:0*/ axi_write_owner_3_tb__DOT__allocate_len;
    CData/*0:0*/ axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__active_q;
    CData/*4:0*/ axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__beats_q;
    CData/*0:0*/ axi_write_owner_3_tb__DOT__managers__BRA__1__KET____DOT__dut__DOT__active_q;
    CData/*4:0*/ axi_write_owner_3_tb__DOT__managers__BRA__1__KET____DOT__dut__DOT__beats_q;
    CData/*0:0*/ axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__active_q;
    CData/*4:0*/ axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__beats_q;
    CData/*0:0*/ __Vtrigprevexpr___TOP__axi_write_owner_3_tb__DOT__ACLK__0;
    CData/*0:0*/ __Vtrigprevexpr___TOP__axi_write_owner_3_tb__DOT__ARESETn__0;
    IData/*31:0*/ axi_write_owner_3_tb__DOT__checks;
    IData/*31:0*/ __Vi;
    VlUnpacked<QData/*63:0*/, 1> __VstlTriggered;
    VlUnpacked<QData/*63:0*/, 1> __VicoTriggered;
    VlUnpacked<QData/*63:0*/, 1> __VactTriggered;
    VlUnpacked<QData/*63:0*/, 1> __VactTriggeredAcc;
    VlUnpacked<QData/*63:0*/, 1> __VnbaTriggered;
    std::string __Vtask_axi_write_owner_3_tb__DOT__check__0__message;
    std::string __Vtask_axi_write_owner_3_tb__DOT__check__1__message;
    std::string __Vtask_axi_write_owner_3_tb__DOT__check__2__message;
    std::string __Vtask_axi_write_owner_3_tb__DOT__check__3__message;
    std::string __Vtask_axi_write_owner_3_tb__DOT__check__4__message;
    std::string __Vtask_axi_write_owner_3_tb__DOT__check__5__message;
    VlDelayScheduler __VdlySched;
    VlTriggerScheduler __VtrigSched_h32687589__0;

    // INTERNAL VARIABLES
    Vaxi_write_owner_3_tb__Syms* vlSymsp;
    const char* vlNamep;

    // CONSTRUCTORS
    Vaxi_write_owner_3_tb___024root(Vaxi_write_owner_3_tb__Syms* symsp, const char* namep);
    ~Vaxi_write_owner_3_tb___024root();
    VL_UNCOPYABLE(Vaxi_write_owner_3_tb___024root);

    // INTERNAL METHODS
};


#endif  // guard
