// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vaxi_write_owner_3_tb.h for the primary calling header

#include "Vaxi_write_owner_3_tb__pch.h"

VlCoroutine Vaxi_write_owner_3_tb___024root___eval_initial__TOP__Vtiming__0(Vaxi_write_owner_3_tb___024root* vlSelf);
VlCoroutine Vaxi_write_owner_3_tb___024root___eval_initial__TOP__Vtiming__1(Vaxi_write_owner_3_tb___024root* vlSelf);

void Vaxi_write_owner_3_tb___024root___eval_initial(Vaxi_write_owner_3_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_3_tb___024root___eval_initial\n"); );
    Vaxi_write_owner_3_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    Vaxi_write_owner_3_tb___024root___eval_initial__TOP__Vtiming__0(vlSelf);
    Vaxi_write_owner_3_tb___024root___eval_initial__TOP__Vtiming__1(vlSelf);
}

void Vaxi_write_owner_3_tb___024root___eval_sample(Vaxi_write_owner_3_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_3_tb___024root___eval_sample\n"); );
    Vaxi_write_owner_3_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vaxi_write_owner_3_tb___024root___dump_triggers__ico(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag);
#endif  // VL_DEBUG

bool Vaxi_write_owner_3_tb___024root___eval_ico(Vaxi_write_owner_3_tb___024root* vlSelf, CData/*0:0*/ firstIteration) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_3_tb___024root___eval_ico\n"); );
    Vaxi_write_owner_3_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VicoTriggered[0U] = ((0xfffffffffffffffeULL 
                                      & vlSelfRef.__VicoTriggered[0U]) 
                                     | (IData)((IData)(firstIteration)));
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vaxi_write_owner_3_tb___024root___dump_triggers__ico(vlSelfRef.__VicoTriggered, "ico"s);
    }
#endif
    return (0U);
}

void Vaxi_write_owner_3_tb___024root___timing_ready(Vaxi_write_owner_3_tb___024root* vlSelf);
void Vaxi_write_owner_3_tb___024root___trigger_orInto__act_vec_vec(VlUnpacked<QData/*63:0*/, 1> &out, const VlUnpacked<QData/*63:0*/, 1> &in);
#ifdef VL_DEBUG
VL_ATTR_COLD void Vaxi_write_owner_3_tb___024root___dump_triggers__act(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag);
#endif  // VL_DEBUG
bool Vaxi_write_owner_3_tb___024root___trigger_anySet__act(const VlUnpacked<QData/*63:0*/, 1> &in);
void Vaxi_write_owner_3_tb___024root___timing_resume(Vaxi_write_owner_3_tb___024root* vlSelf);

bool Vaxi_write_owner_3_tb___024root___eval_act(Vaxi_write_owner_3_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_3_tb___024root___eval_act\n"); );
    Vaxi_write_owner_3_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VactExecute;
    // Body
    {
        // Inlined CFunc: _eval_triggers_vec__act
        vlSelfRef.__VactTriggered[0U] = (QData)((IData)(
                                                        ((vlSelfRef.__VdlySched.awaitingCurrentTime() 
                                                          << 2U) 
                                                         | ((((~ (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__ARESETn)) 
                                                              & (IData)(vlSelfRef.__Vtrigprevexpr___TOP__axi_write_owner_3_tb__DOT__ARESETn__0)) 
                                                             << 1U) 
                                                            | ((IData)(vlSelfRef.axi_write_owner_3_tb__DOT__ACLK) 
                                                               & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__axi_write_owner_3_tb__DOT__ACLK__0)))))));
        vlSelfRef.__Vtrigprevexpr___TOP__axi_write_owner_3_tb__DOT__ACLK__0 
            = vlSelfRef.axi_write_owner_3_tb__DOT__ACLK;
        vlSelfRef.__Vtrigprevexpr___TOP__axi_write_owner_3_tb__DOT__ARESETn__0 
            = vlSelfRef.axi_write_owner_3_tb__DOT__ARESETn;
    }
    Vaxi_write_owner_3_tb___024root___timing_ready(vlSelf);
    Vaxi_write_owner_3_tb___024root___trigger_orInto__act_vec_vec(vlSelfRef.__VactTriggered, vlSelfRef.__VactTriggeredAcc);
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vaxi_write_owner_3_tb___024root___dump_triggers__act(vlSelfRef.__VactTriggered, "act"s);
    }
#endif
    Vaxi_write_owner_3_tb___024root___trigger_orInto__act_vec_vec(vlSelfRef.__VnbaTriggered, vlSelfRef.__VactTriggered);
    __VactExecute = Vaxi_write_owner_3_tb___024root___trigger_anySet__act(vlSelfRef.__VactTriggered);
    if (__VactExecute) {
        vlSelfRef.__VactTriggeredAcc.fill(0ULL);
        Vaxi_write_owner_3_tb___024root___timing_resume(vlSelf);
    }
    return (__VactExecute);
}

bool Vaxi_write_owner_3_tb___024root___eval_inact(Vaxi_write_owner_3_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_3_tb___024root___eval_inact\n"); );
    Vaxi_write_owner_3_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VinactExecute;
    // Body
    __VinactExecute = vlSelfRef.__VdlySched.awaitingZeroDelay();
    if (__VinactExecute) {
        VL_FATAL_MT("/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_3_tb.sv", 1, "", "ZERODLY: Design Verilated with '--no-sched-zero-delay', but #0 delay executed at runtime");
    }
    return (__VinactExecute);
}

void Vaxi_write_owner_3_tb___024root___nba_sequent__TOP__0(Vaxi_write_owner_3_tb___024root* vlSelf);
void Vaxi_write_owner_3_tb___024root___trigger_clear__act(VlUnpacked<QData/*63:0*/, 1> &out);

bool Vaxi_write_owner_3_tb___024root___eval_nba(Vaxi_write_owner_3_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_3_tb___024root___eval_nba\n"); );
    Vaxi_write_owner_3_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = Vaxi_write_owner_3_tb___024root___trigger_anySet__act(vlSelfRef.__VnbaTriggered);
    if (__VnbaExecute) {
        {
            // Inlined CFunc: _eval_body__nba
            if ((3ULL & vlSelfRef.__VnbaTriggered[0U])) {
                Vaxi_write_owner_3_tb___024root___nba_sequent__TOP__0(vlSelf);
            }
        }
        Vaxi_write_owner_3_tb___024root___trigger_clear__act(vlSelfRef.__VnbaTriggered);
    }
    return (__VnbaExecute);
}

bool Vaxi_write_owner_3_tb___024root___eval_obs(Vaxi_write_owner_3_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_3_tb___024root___eval_obs\n"); );
    Vaxi_write_owner_3_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    return (0U);
}

bool Vaxi_write_owner_3_tb___024root___eval_react(Vaxi_write_owner_3_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_3_tb___024root___eval_react\n"); );
    Vaxi_write_owner_3_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    return (0U);
}

void Vaxi_write_owner_3_tb___024root___eval_postponed(Vaxi_write_owner_3_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_3_tb___024root___eval_postponed\n"); );
    Vaxi_write_owner_3_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

void Vaxi_write_owner_3_tb___024root____VbeforeTrig_h32687589__0(Vaxi_write_owner_3_tb___024root* vlSelf, const char* __VeventDescription);

VlCoroutine Vaxi_write_owner_3_tb___024root___eval_initial__TOP__Vtiming__0(Vaxi_write_owner_3_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_3_tb___024root___eval_initial__TOP__Vtiming__0\n"); );
    Vaxi_write_owner_3_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    SData/*11:0*/ axi_write_owner_3_tb__DOT__allocate_target;
    axi_write_owner_3_tb__DOT__allocate_target = 0;
    SData/*11:0*/ axi_write_owner_3_tb__DOT__allocate_id;
    axi_write_owner_3_tb__DOT__allocate_id = 0;
    IData/*17:0*/ axi_write_owner_3_tb__DOT__allocate_internal_id;
    axi_write_owner_3_tb__DOT__allocate_internal_id = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_3_tb__DOT__check__0__condition;
    __Vtask_axi_write_owner_3_tb__DOT__check__0__condition = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_3_tb__DOT__check__1__condition;
    __Vtask_axi_write_owner_3_tb__DOT__check__1__condition = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_3_tb__DOT__check__2__condition;
    __Vtask_axi_write_owner_3_tb__DOT__check__2__condition = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_3_tb__DOT__check__3__condition;
    __Vtask_axi_write_owner_3_tb__DOT__check__3__condition = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_3_tb__DOT__check__4__condition;
    __Vtask_axi_write_owner_3_tb__DOT__check__4__condition = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_3_tb__DOT__check__5__condition;
    __Vtask_axi_write_owner_3_tb__DOT__check__5__condition = 0;
    // Body
    vlSelfRef.axi_write_owner_3_tb__DOT__ARESETn = 1U;
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_3_tb.sv", 
                                         29);
    vlSelfRef.axi_write_owner_3_tb__DOT__ARESETn = 0U;
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_3_tb.sv", 
                                         29);
    vlSelfRef.axi_write_owner_3_tb__DOT__allocate_fire = 0U;
    vlSelfRef.axi_write_owner_3_tb__DOT__w_fire = 0U;
    vlSelfRef.axi_write_owner_3_tb__DOT__wlast = 0U;
    vlSelfRef.axi_write_owner_3_tb__DOT__allocate_len = 0U;
    axi_write_owner_3_tb__DOT__allocate_target = 0U;
    axi_write_owner_3_tb__DOT__allocate_id = 0U;
    axi_write_owner_3_tb__DOT__allocate_internal_id = 0U;
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_3_tb.sv", 
                                         31);
    vlSelfRef.axi_write_owner_3_tb__DOT__ARESETn = 1U;
    vlSelfRef.__Vtask_axi_write_owner_3_tb__DOT__check__0__message = "allocation permitted after reset"s;
    __Vtask_axi_write_owner_3_tb__DOT__check__0__condition 
        = ((((~ (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__active_q)) 
             & (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__ARESETn)) 
            & (~ (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__1__KET____DOT__dut__DOT__active_q))) 
           & (~ (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__active_q)));
    vlSelfRef.axi_write_owner_3_tb__DOT__checks = ((IData)(1U) 
                                                   + vlSelfRef.axi_write_owner_3_tb__DOT__checks);
    if (VL_UNLIKELY(((1U & (~ (IData)(__Vtask_axi_write_owner_3_tb__DOT__check__0__condition)))))) {
        VL_WRITEF_NX("FAIL %s\n[%0t] %%Fatal: axi_write_owner_3_tb.sv:26: Assertion failed in %m\n",4, 'M',vlSymsp->name(),"axi_write_owner_3_tb.check", 'T',-12
                     , 'S',&(vlSelfRef.__Vtask_axi_write_owner_3_tb__DOT__check__0__message)
                     , '#',64,VL_TIME_UNITED_Q(1));
        VL_STOP_MT("/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_3_tb.sv", 26, "", false);
    }
    vlSelfRef.axi_write_owner_3_tb__DOT__allocate_len 
        = (2U | (0x00ffff00U & vlSelfRef.axi_write_owner_3_tb__DOT__allocate_len));
    axi_write_owner_3_tb__DOT__allocate_target = (0x0ff0U 
                                                  & (IData)(axi_write_owner_3_tb__DOT__allocate_target));
    axi_write_owner_3_tb__DOT__allocate_id = (0x0ff0U 
                                              & (IData)(axi_write_owner_3_tb__DOT__allocate_id));
    axi_write_owner_3_tb__DOT__allocate_internal_id 
        = (0x00000010U | (0x0003ffc0U & axi_write_owner_3_tb__DOT__allocate_internal_id));
    vlSelfRef.axi_write_owner_3_tb__DOT__allocate_fire 
        = (1U | (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__allocate_fire));
    vlSelfRef.axi_write_owner_3_tb__DOT__allocate_len 
        = (0x00000200U | (0x00ff00ffU & vlSelfRef.axi_write_owner_3_tb__DOT__allocate_len));
    axi_write_owner_3_tb__DOT__allocate_target = (0x00000010U 
                                                  | (0x0f0fU 
                                                     & (IData)(axi_write_owner_3_tb__DOT__allocate_target)));
    axi_write_owner_3_tb__DOT__allocate_id = (0x00000010U 
                                              | (0x0f0fU 
                                                 & (IData)(axi_write_owner_3_tb__DOT__allocate_id)));
    axi_write_owner_3_tb__DOT__allocate_internal_id 
        = (0x00000440U | (0x0003f03fU & axi_write_owner_3_tb__DOT__allocate_internal_id));
    vlSelfRef.axi_write_owner_3_tb__DOT__allocate_fire 
        = (2U | (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__allocate_fire));
    vlSelfRef.axi_write_owner_3_tb__DOT__allocate_len 
        = (0x00020000U | (0x0000ffffU & vlSelfRef.axi_write_owner_3_tb__DOT__allocate_len));
    axi_write_owner_3_tb__DOT__allocate_target = (0x00000200U 
                                                  | (0x00ffU 
                                                     & (IData)(axi_write_owner_3_tb__DOT__allocate_target)));
    axi_write_owner_3_tb__DOT__allocate_id = (0x00000200U 
                                              | (0x00ffU 
                                                 & (IData)(axi_write_owner_3_tb__DOT__allocate_id)));
    axi_write_owner_3_tb__DOT__allocate_internal_id 
        = (0x00012000U | (0x00000fffU & axi_write_owner_3_tb__DOT__allocate_internal_id));
    vlSelfRef.axi_write_owner_3_tb__DOT__allocate_fire 
        = (4U | (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__allocate_fire));
    Vaxi_write_owner_3_tb___024root____VbeforeTrig_h32687589__0(vlSelf, 
                                                                "@(posedge axi_write_owner_3_tb.ACLK)");
    co_await vlSelfRef.__VtrigSched_h32687589__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(posedge axi_write_owner_3_tb.ACLK)", 
                                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_3_tb.sv", 
                                                         36);
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_3_tb.sv", 
                                         36);
    vlSelfRef.axi_write_owner_3_tb__DOT__allocate_fire = 0U;
    vlSelfRef.__Vtask_axi_write_owner_3_tb__DOT__check__1__message = "three independent owners"s;
    __Vtask_axi_write_owner_3_tb__DOT__check__1__condition 
        = (((((IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__active_q) 
              & ((IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__1__KET____DOT__dut__DOT__active_q) 
                 & (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__active_q))) 
             & (3U == ((IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__beats_q) 
                       & (- (IData)((IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__active_q)))))) 
            & (3U == ((IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__1__KET____DOT__dut__DOT__beats_q) 
                      & (- (IData)((IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__1__KET____DOT__dut__DOT__active_q)))))) 
           & (3U == ((IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__beats_q) 
                     & (- (IData)((IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__active_q))))));
    vlSelfRef.axi_write_owner_3_tb__DOT__checks = ((IData)(1U) 
                                                   + vlSelfRef.axi_write_owner_3_tb__DOT__checks);
    if (VL_UNLIKELY(((1U & (~ (IData)(__Vtask_axi_write_owner_3_tb__DOT__check__1__condition)))))) {
        VL_WRITEF_NX("FAIL %s\n[%0t] %%Fatal: axi_write_owner_3_tb.sv:26: Assertion failed in %m\n",4, 'M',vlSymsp->name(),"axi_write_owner_3_tb.check", 'T',-12
                     , 'S',&(vlSelfRef.__Vtask_axi_write_owner_3_tb__DOT__check__1__message)
                     , '#',64,VL_TIME_UNITED_Q(1));
        VL_STOP_MT("/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_3_tb.sv", 26, "", false);
    }
    vlSelfRef.axi_write_owner_3_tb__DOT__w_fire = (2U 
                                                   | (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__w_fire));
    vlSelfRef.axi_write_owner_3_tb__DOT__wlast = (5U 
                                                  & (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__wlast));
    Vaxi_write_owner_3_tb___024root____VbeforeTrig_h32687589__0(vlSelf, 
                                                                "@(posedge axi_write_owner_3_tb.ACLK)");
    co_await vlSelfRef.__VtrigSched_h32687589__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(posedge axi_write_owner_3_tb.ACLK)", 
                                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_3_tb.sv", 
                                                         38);
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_3_tb.sv", 
                                         38);
    vlSelfRef.axi_write_owner_3_tb__DOT__w_fire = (5U 
                                                   & (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__w_fire));
    vlSelfRef.__Vtask_axi_write_owner_3_tb__DOT__check__2__message = "other owners unaffected"s;
    __Vtask_axi_write_owner_3_tb__DOT__check__2__condition 
        = ((((IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__active_q) 
             & (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__active_q)) 
            & (3U == ((IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__beats_q) 
                      & (- (IData)((IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__active_q)))))) 
           & (3U == ((IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__beats_q) 
                     & (- (IData)((IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__active_q))))));
    vlSelfRef.axi_write_owner_3_tb__DOT__checks = ((IData)(1U) 
                                                   + vlSelfRef.axi_write_owner_3_tb__DOT__checks);
    if (VL_UNLIKELY(((1U & (~ (IData)(__Vtask_axi_write_owner_3_tb__DOT__check__2__condition)))))) {
        VL_WRITEF_NX("FAIL %s\n[%0t] %%Fatal: axi_write_owner_3_tb.sv:26: Assertion failed in %m\n",4, 'M',vlSymsp->name(),"axi_write_owner_3_tb.check", 'T',-12
                     , 'S',&(vlSelfRef.__Vtask_axi_write_owner_3_tb__DOT__check__2__message)
                     , '#',64,VL_TIME_UNITED_Q(1));
        VL_STOP_MT("/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_3_tb.sv", 26, "", false);
    }
    vlSelfRef.axi_write_owner_3_tb__DOT__w_fire = (1U 
                                                   | (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__w_fire));
    vlSelfRef.axi_write_owner_3_tb__DOT__wlast = (6U 
                                                  & (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__wlast));
    vlSelfRef.axi_write_owner_3_tb__DOT__w_fire = (4U 
                                                   | (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__w_fire));
    vlSelfRef.axi_write_owner_3_tb__DOT__wlast = (3U 
                                                  & (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__wlast));
    Vaxi_write_owner_3_tb___024root____VbeforeTrig_h32687589__0(vlSelf, 
                                                                "@(posedge axi_write_owner_3_tb.ACLK)");
    co_await vlSelfRef.__VtrigSched_h32687589__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(posedge axi_write_owner_3_tb.ACLK)", 
                                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_3_tb.sv", 
                                                         40);
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_3_tb.sv", 
                                         40);
    vlSelfRef.axi_write_owner_3_tb__DOT__w_fire = 0U;
    vlSelfRef.__Vtask_axi_write_owner_3_tb__DOT__check__3__message = "parallel beat accounting"s;
    __Vtask_axi_write_owner_3_tb__DOT__check__3__condition 
        = ((2U == ((IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__beats_q) 
                   & (- (IData)((IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__active_q))))) 
           & (2U == ((IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__beats_q) 
                     & (- (IData)((IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__active_q))))));
    vlSelfRef.axi_write_owner_3_tb__DOT__checks = ((IData)(1U) 
                                                   + vlSelfRef.axi_write_owner_3_tb__DOT__checks);
    if (VL_UNLIKELY(((1U & (~ (IData)(__Vtask_axi_write_owner_3_tb__DOT__check__3__condition)))))) {
        VL_WRITEF_NX("FAIL %s\n[%0t] %%Fatal: axi_write_owner_3_tb.sv:26: Assertion failed in %m\n",4, 'M',vlSymsp->name(),"axi_write_owner_3_tb.check", 'T',-12
                     , 'S',&(vlSelfRef.__Vtask_axi_write_owner_3_tb__DOT__check__3__message)
                     , '#',64,VL_TIME_UNITED_Q(1));
        VL_STOP_MT("/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_3_tb.sv", 26, "", false);
    }
    vlSelfRef.axi_write_owner_3_tb__DOT__w_fire = (2U 
                                                   | (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__w_fire));
    vlSelfRef.axi_write_owner_3_tb__DOT__wlast = (5U 
                                                  & (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__wlast));
    Vaxi_write_owner_3_tb___024root____VbeforeTrig_h32687589__0(vlSelf, 
                                                                "@(posedge axi_write_owner_3_tb.ACLK)");
    co_await vlSelfRef.__VtrigSched_h32687589__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(posedge axi_write_owner_3_tb.ACLK)", 
                                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_3_tb.sv", 
                                                         42);
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_3_tb.sv", 
                                         42);
    vlSelfRef.axi_write_owner_3_tb__DOT__w_fire = (5U 
                                                   & (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__w_fire));
    vlSelfRef.axi_write_owner_3_tb__DOT__w_fire = (2U 
                                                   | (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__w_fire));
    vlSelfRef.axi_write_owner_3_tb__DOT__wlast = (2U 
                                                  | (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__wlast));
    Vaxi_write_owner_3_tb___024root____VbeforeTrig_h32687589__0(vlSelf, 
                                                                "@(posedge axi_write_owner_3_tb.ACLK)");
    co_await vlSelfRef.__VtrigSched_h32687589__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(posedge axi_write_owner_3_tb.ACLK)", 
                                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_3_tb.sv", 
                                                         43);
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_3_tb.sv", 
                                         43);
    vlSelfRef.axi_write_owner_3_tb__DOT__w_fire = (5U 
                                                   & (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__w_fire));
    vlSelfRef.__Vtask_axi_write_owner_3_tb__DOT__check__4__message = "one completion does not modify others"s;
    __Vtask_axi_write_owner_3_tb__DOT__check__4__condition 
        = (((~ (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__1__KET____DOT__dut__DOT__active_q)) 
            & (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__active_q)) 
           & (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__active_q));
    vlSelfRef.axi_write_owner_3_tb__DOT__checks = ((IData)(1U) 
                                                   + vlSelfRef.axi_write_owner_3_tb__DOT__checks);
    if (VL_UNLIKELY(((1U & (~ (IData)(__Vtask_axi_write_owner_3_tb__DOT__check__4__condition)))))) {
        VL_WRITEF_NX("FAIL %s\n[%0t] %%Fatal: axi_write_owner_3_tb.sv:26: Assertion failed in %m\n",4, 'M',vlSymsp->name(),"axi_write_owner_3_tb.check", 'T',-12
                     , 'S',&(vlSelfRef.__Vtask_axi_write_owner_3_tb__DOT__check__4__message)
                     , '#',64,VL_TIME_UNITED_Q(1));
        VL_STOP_MT("/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_3_tb.sv", 26, "", false);
    }
    vlSelfRef.axi_write_owner_3_tb__DOT__w_fire = (1U 
                                                   | (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__w_fire));
    vlSelfRef.axi_write_owner_3_tb__DOT__wlast = (6U 
                                                  & (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__wlast));
    vlSelfRef.axi_write_owner_3_tb__DOT__w_fire = (4U 
                                                   | (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__w_fire));
    vlSelfRef.axi_write_owner_3_tb__DOT__wlast = (3U 
                                                  & (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__wlast));
    Vaxi_write_owner_3_tb___024root____VbeforeTrig_h32687589__0(vlSelf, 
                                                                "@(posedge axi_write_owner_3_tb.ACLK)");
    co_await vlSelfRef.__VtrigSched_h32687589__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(posedge axi_write_owner_3_tb.ACLK)", 
                                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_3_tb.sv", 
                                                         45);
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_3_tb.sv", 
                                         45);
    vlSelfRef.axi_write_owner_3_tb__DOT__w_fire = 0U;
    vlSelfRef.axi_write_owner_3_tb__DOT__w_fire = (1U 
                                                   | (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__w_fire));
    vlSelfRef.axi_write_owner_3_tb__DOT__wlast = (1U 
                                                  | (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__wlast));
    vlSelfRef.axi_write_owner_3_tb__DOT__w_fire = (4U 
                                                   | (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__w_fire));
    vlSelfRef.axi_write_owner_3_tb__DOT__wlast = (4U 
                                                  | (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__wlast));
    Vaxi_write_owner_3_tb___024root____VbeforeTrig_h32687589__0(vlSelf, 
                                                                "@(posedge axi_write_owner_3_tb.ACLK)");
    co_await vlSelfRef.__VtrigSched_h32687589__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(posedge axi_write_owner_3_tb.ACLK)", 
                                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_3_tb.sv", 
                                                         46);
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_3_tb.sv", 
                                         46);
    vlSelfRef.axi_write_owner_3_tb__DOT__w_fire = 0U;
    vlSelfRef.__Vtask_axi_write_owner_3_tb__DOT__check__5__message = "all independent owners complete"s;
    __Vtask_axi_write_owner_3_tb__DOT__check__5__condition 
        = (1U & (~ (((IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__active_q) 
                     | (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__1__KET____DOT__dut__DOT__active_q)) 
                    | (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__active_q))));
    vlSelfRef.axi_write_owner_3_tb__DOT__checks = ((IData)(1U) 
                                                   + vlSelfRef.axi_write_owner_3_tb__DOT__checks);
    if (VL_UNLIKELY(((1U & (~ (IData)(__Vtask_axi_write_owner_3_tb__DOT__check__5__condition)))))) {
        VL_WRITEF_NX("FAIL %s\n[%0t] %%Fatal: axi_write_owner_3_tb.sv:26: Assertion failed in %m\n",4, 'M',vlSymsp->name(),"axi_write_owner_3_tb.check", 'T',-12
                     , 'S',&(vlSelfRef.__Vtask_axi_write_owner_3_tb__DOT__check__5__message)
                     , '#',64,VL_TIME_UNITED_Q(1));
        VL_STOP_MT("/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_3_tb.sv", 26, "", false);
    }
    VL_WRITEF_NX("PASS axi_write_owner_3_tb checks=%0d\n",1
                 , '~',32,vlSelfRef.axi_write_owner_3_tb__DOT__checks);
    VL_FINISH_MT("/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_3_tb.sv", 48, "");
    co_return;
}

VlCoroutine Vaxi_write_owner_3_tb___024root___eval_initial__TOP__Vtiming__1(Vaxi_write_owner_3_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_3_tb___024root___eval_initial__TOP__Vtiming__1\n"); );
    Vaxi_write_owner_3_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    while (VL_LIKELY(!vlSymsp->_vm_contextp__->gotFinish())) {
        co_await vlSelfRef.__VdlySched.delay(5ULL, 
                                             nullptr, 
                                             "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_3_tb.sv", 
                                             2);
        vlSelfRef.axi_write_owner_3_tb__DOT__ACLK = 
            (1U & (~ (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__ACLK)));
    }
    co_return;
}

bool Vaxi_write_owner_3_tb___024root___trigger_anySet__ico(const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_3_tb___024root___trigger_anySet__ico\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        if (in[n]) {
            return (1U);
        }
        n = ((IData)(1U) + n);
    } while ((1U > n));
    return (0U);
}

bool Vaxi_write_owner_3_tb___024root___trigger_anySet__act(const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_3_tb___024root___trigger_anySet__act\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        if (in[n]) {
            return (1U);
        }
        n = ((IData)(1U) + n);
    } while ((1U > n));
    return (0U);
}

void Vaxi_write_owner_3_tb___024root___nba_sequent__TOP__0(Vaxi_write_owner_3_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_3_tb___024root___nba_sequent__TOP__0\n"); );
    Vaxi_write_owner_3_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__active_q;
    __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__active_q = 0;
    CData/*4:0*/ __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__beats_q;
    __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__beats_q = 0;
    CData/*0:0*/ __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__1__KET____DOT__dut__DOT__active_q;
    __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__1__KET____DOT__dut__DOT__active_q = 0;
    CData/*4:0*/ __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__1__KET____DOT__dut__DOT__beats_q;
    __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__1__KET____DOT__dut__DOT__beats_q = 0;
    CData/*0:0*/ __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__active_q;
    __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__active_q = 0;
    CData/*4:0*/ __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__beats_q;
    __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__beats_q = 0;
    // Body
    __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__active_q 
        = vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__active_q;
    __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__1__KET____DOT__dut__DOT__active_q 
        = vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__1__KET____DOT__dut__DOT__active_q;
    __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__active_q 
        = vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__active_q;
    __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__beats_q 
        = vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__beats_q;
    __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__1__KET____DOT__dut__DOT__beats_q 
        = vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__1__KET____DOT__dut__DOT__beats_q;
    __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__beats_q 
        = vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__beats_q;
    if (vlSelfRef.axi_write_owner_3_tb__DOT__ARESETn) {
        if ((IData)((((IData)(vlSelfRef.axi_write_owner_3_tb__DOT__allocate_fire) 
                      >> 2U) & (~ (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__active_q))))) {
            __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__active_q = 1U;
            __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__beats_q 
                = ((0x0fU < (0x000000ffU & (vlSelfRef.axi_write_owner_3_tb__DOT__allocate_len 
                                            >> 0x00000010U)))
                    ? 0x00000010U : (0x0000001fU & 
                                     ((IData)(1U) + 
                                      (0x0000000fU 
                                       & (vlSelfRef.axi_write_owner_3_tb__DOT__allocate_len 
                                          >> 0x00000010U)))));
        } else if (((IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__active_q) 
                    & ((IData)(vlSelfRef.axi_write_owner_3_tb__DOT__w_fire) 
                       >> 2U))) {
            if (((1U == (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__beats_q)) 
                 & ((IData)(vlSelfRef.axi_write_owner_3_tb__DOT__wlast) 
                    >> 2U))) {
                __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__active_q = 0U;
                __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__beats_q = 0U;
            } else if ((1U < (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__beats_q))) {
                __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__beats_q 
                    = (0x0000001fU & ((IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__beats_q) 
                                      - (IData)(1U)));
            }
        }
        if ((1U & (((IData)(vlSelfRef.axi_write_owner_3_tb__DOT__allocate_fire) 
                    >> 1U) & (~ (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__1__KET____DOT__dut__DOT__active_q))))) {
            __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__1__KET____DOT__dut__DOT__active_q = 1U;
            __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__1__KET____DOT__dut__DOT__beats_q 
                = ((0x0fU < (0x000000ffU & (vlSelfRef.axi_write_owner_3_tb__DOT__allocate_len 
                                            >> 8U)))
                    ? 0x00000010U : (0x0000001fU & 
                                     ((IData)(1U) + 
                                      (0x0000000fU 
                                       & (vlSelfRef.axi_write_owner_3_tb__DOT__allocate_len 
                                          >> 8U)))));
        } else if (((IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__1__KET____DOT__dut__DOT__active_q) 
                    & ((IData)(vlSelfRef.axi_write_owner_3_tb__DOT__w_fire) 
                       >> 1U))) {
            if (((1U == (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__1__KET____DOT__dut__DOT__beats_q)) 
                 & ((IData)(vlSelfRef.axi_write_owner_3_tb__DOT__wlast) 
                    >> 1U))) {
                __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__1__KET____DOT__dut__DOT__active_q = 0U;
                __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__1__KET____DOT__dut__DOT__beats_q = 0U;
            } else if ((1U < (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__1__KET____DOT__dut__DOT__beats_q))) {
                __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__1__KET____DOT__dut__DOT__beats_q 
                    = (0x0000001fU & ((IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__1__KET____DOT__dut__DOT__beats_q) 
                                      - (IData)(1U)));
            }
        }
        if ((1U & ((IData)(vlSelfRef.axi_write_owner_3_tb__DOT__allocate_fire) 
                   & (~ (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__active_q))))) {
            __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__active_q = 1U;
            __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__beats_q 
                = ((0x0fU < (0x000000ffU & vlSelfRef.axi_write_owner_3_tb__DOT__allocate_len))
                    ? 0x00000010U : (0x0000001fU & 
                                     ((IData)(1U) + 
                                      (0x0000000fU 
                                       & vlSelfRef.axi_write_owner_3_tb__DOT__allocate_len))));
        } else if (((IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__active_q) 
                    & (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__w_fire))) {
            if (((1U == (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__beats_q)) 
                 & (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__wlast))) {
                __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__active_q = 0U;
                __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__beats_q = 0U;
            } else if ((1U < (IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__beats_q))) {
                __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__beats_q 
                    = (0x0000001fU & ((IData)(vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__beats_q) 
                                      - (IData)(1U)));
            }
        }
    } else {
        __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__active_q = 0U;
        __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__1__KET____DOT__dut__DOT__active_q = 0U;
        __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__active_q = 0U;
        __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__beats_q = 0U;
        __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__1__KET____DOT__dut__DOT__beats_q = 0U;
        __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__beats_q = 0U;
    }
    vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__active_q 
        = __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__active_q;
    vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__beats_q 
        = __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__beats_q;
    vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__1__KET____DOT__dut__DOT__active_q 
        = __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__1__KET____DOT__dut__DOT__active_q;
    vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__1__KET____DOT__dut__DOT__beats_q 
        = __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__1__KET____DOT__dut__DOT__beats_q;
    vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__active_q 
        = __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__active_q;
    vlSelfRef.axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__beats_q 
        = __Vdly__axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__beats_q;
}

void Vaxi_write_owner_3_tb___024root___timing_ready(Vaxi_write_owner_3_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_3_tb___024root___timing_ready\n"); );
    Vaxi_write_owner_3_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VactTriggered[0U])) {
        vlSelfRef.__VtrigSched_h32687589__0.ready("@(posedge axi_write_owner_3_tb.ACLK)");
    }
}

void Vaxi_write_owner_3_tb___024root___timing_resume(Vaxi_write_owner_3_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_3_tb___024root___timing_resume\n"); );
    Vaxi_write_owner_3_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VtrigSched_h32687589__0.moveToResumeQueue(
                                                          "@(posedge axi_write_owner_3_tb.ACLK)");
    vlSelfRef.__VtrigSched_h32687589__0.resume("@(posedge axi_write_owner_3_tb.ACLK)");
    if ((4ULL & vlSelfRef.__VactTriggered[0U])) {
        vlSelfRef.__VdlySched.resume();
    }
}

void Vaxi_write_owner_3_tb___024root___trigger_orInto__act_vec_vec(VlUnpacked<QData/*63:0*/, 1> &out, const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_3_tb___024root___trigger_orInto__act_vec_vec\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        out[n] = (out[n] | in[n]);
        n = ((IData)(1U) + n);
    } while ((0U >= n));
}

void Vaxi_write_owner_3_tb___024root___trigger_clear__act(VlUnpacked<QData/*63:0*/, 1> &out) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_3_tb___024root___trigger_clear__act\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        out[n] = 0ULL;
        n = ((IData)(1U) + n);
    } while ((1U > n));
}

void Vaxi_write_owner_3_tb___024root____VbeforeTrig_h32687589__0(Vaxi_write_owner_3_tb___024root* vlSelf, const char* __VeventDescription) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_3_tb___024root____VbeforeTrig_h32687589__0\n"); );
    Vaxi_write_owner_3_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    VlUnpacked<QData/*63:0*/, 1> __VTmp;
    // Body
    __VTmp[0U] = (QData)((IData)(((IData)(vlSelfRef.axi_write_owner_3_tb__DOT__ACLK) 
                                  & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__axi_write_owner_3_tb__DOT__ACLK__0)))));
    vlSelfRef.__Vtrigprevexpr___TOP__axi_write_owner_3_tb__DOT__ACLK__0 
        = vlSelfRef.axi_write_owner_3_tb__DOT__ACLK;
    if ((1ULL & __VTmp[0U])) {
        vlSelfRef.__VtrigSched_h32687589__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h32687589__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h32687589__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h32687589__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h32687589__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h32687589__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h32687589__0.ready(__VeventDescription);
    }
    vlSelfRef.__VactTriggeredAcc[0U] = (vlSelfRef.__VactTriggeredAcc[0U] 
                                        | __VTmp[0U]);
}

#ifdef VL_DEBUG
void Vaxi_write_owner_3_tb___024root___eval_debug_assertions(Vaxi_write_owner_3_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_3_tb___024root___eval_debug_assertions\n"); );
    Vaxi_write_owner_3_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}
#endif  // VL_DEBUG
