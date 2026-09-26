// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vaxi_write_owner_tb.h for the primary calling header

#include "Vaxi_write_owner_tb__pch.h"

VlCoroutine Vaxi_write_owner_tb___024root___eval_initial__TOP__Vtiming__0(Vaxi_write_owner_tb___024root* vlSelf);
VlCoroutine Vaxi_write_owner_tb___024root___eval_initial__TOP__Vtiming__1(Vaxi_write_owner_tb___024root* vlSelf);

void Vaxi_write_owner_tb___024root___eval_initial(Vaxi_write_owner_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_tb___024root___eval_initial\n"); );
    Vaxi_write_owner_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    Vaxi_write_owner_tb___024root___eval_initial__TOP__Vtiming__0(vlSelf);
    Vaxi_write_owner_tb___024root___eval_initial__TOP__Vtiming__1(vlSelf);
}

void Vaxi_write_owner_tb___024root___eval_sample(Vaxi_write_owner_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_tb___024root___eval_sample\n"); );
    Vaxi_write_owner_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vaxi_write_owner_tb___024root___dump_triggers__ico(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag);
#endif  // VL_DEBUG

bool Vaxi_write_owner_tb___024root___eval_ico(Vaxi_write_owner_tb___024root* vlSelf, CData/*0:0*/ firstIteration) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_tb___024root___eval_ico\n"); );
    Vaxi_write_owner_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VicoTriggered[0U] = ((0xfffffffffffffffeULL 
                                      & vlSelfRef.__VicoTriggered[0U]) 
                                     | (IData)((IData)(firstIteration)));
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vaxi_write_owner_tb___024root___dump_triggers__ico(vlSelfRef.__VicoTriggered, "ico"s);
    }
#endif
    return (0U);
}

void Vaxi_write_owner_tb___024root___timing_ready(Vaxi_write_owner_tb___024root* vlSelf);
void Vaxi_write_owner_tb___024root___trigger_orInto__act_vec_vec(VlUnpacked<QData/*63:0*/, 1> &out, const VlUnpacked<QData/*63:0*/, 1> &in);
#ifdef VL_DEBUG
VL_ATTR_COLD void Vaxi_write_owner_tb___024root___dump_triggers__act(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag);
#endif  // VL_DEBUG
bool Vaxi_write_owner_tb___024root___trigger_anySet__act(const VlUnpacked<QData/*63:0*/, 1> &in);
void Vaxi_write_owner_tb___024root___timing_resume(Vaxi_write_owner_tb___024root* vlSelf);

bool Vaxi_write_owner_tb___024root___eval_act(Vaxi_write_owner_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_tb___024root___eval_act\n"); );
    Vaxi_write_owner_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VactExecute;
    // Body
    {
        // Inlined CFunc: _eval_triggers_vec__act
        vlSelfRef.__VactTriggered[0U] = (QData)((IData)(
                                                        (((((~ (IData)(vlSelfRef.axi_write_owner_tb__DOT__ACLK)) 
                                                            & (IData)(vlSelfRef.__Vtrigprevexpr___TOP__axi_write_owner_tb__DOT__ACLK__0)) 
                                                           << 3U) 
                                                          | (vlSelfRef.__VdlySched.awaitingCurrentTime() 
                                                             << 2U)) 
                                                         | ((((~ (IData)(vlSelfRef.axi_write_owner_tb__DOT__ARESETn)) 
                                                              & (IData)(vlSelfRef.__Vtrigprevexpr___TOP__axi_write_owner_tb__DOT__ARESETn__0)) 
                                                             << 1U) 
                                                            | ((IData)(vlSelfRef.axi_write_owner_tb__DOT__ACLK) 
                                                               & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__axi_write_owner_tb__DOT__ACLK__0)))))));
        vlSelfRef.__Vtrigprevexpr___TOP__axi_write_owner_tb__DOT__ACLK__0 
            = vlSelfRef.axi_write_owner_tb__DOT__ACLK;
        vlSelfRef.__Vtrigprevexpr___TOP__axi_write_owner_tb__DOT__ARESETn__0 
            = vlSelfRef.axi_write_owner_tb__DOT__ARESETn;
    }
    Vaxi_write_owner_tb___024root___timing_ready(vlSelf);
    Vaxi_write_owner_tb___024root___trigger_orInto__act_vec_vec(vlSelfRef.__VactTriggered, vlSelfRef.__VactTriggeredAcc);
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vaxi_write_owner_tb___024root___dump_triggers__act(vlSelfRef.__VactTriggered, "act"s);
    }
#endif
    Vaxi_write_owner_tb___024root___trigger_orInto__act_vec_vec(vlSelfRef.__VnbaTriggered, vlSelfRef.__VactTriggered);
    __VactExecute = Vaxi_write_owner_tb___024root___trigger_anySet__act(vlSelfRef.__VactTriggered);
    if (__VactExecute) {
        vlSelfRef.__VactTriggeredAcc.fill(0ULL);
        Vaxi_write_owner_tb___024root___timing_resume(vlSelf);
        {
            // Inlined CFunc: _eval_body__act
            if ((0x000000000000000dULL & vlSelfRef.__VactTriggered[0U])) {
                {
                    // Inlined CFunc: _act_comb__TOP__0
                    CData/*0:0*/ __Vinline_0__eval_body__act___Vinline_1__act_comb__TOP__0___VdfgRegularize_hebeb780c_0_0;
                    __Vinline_0__eval_body__act___Vinline_1__act_comb__TOP__0___VdfgRegularize_hebeb780c_0_0 = 0;
                    vlSelfRef.axi_write_owner_tb__DOT__allocate_allowed 
                        = ((~ (IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q)) 
                           & (IData)(vlSelfRef.axi_write_owner_tb__DOT__ARESETn));
                    vlSelfRef.axi_write_owner_tb__DOT__w_without_owner_violation 
                        = ((IData)(vlSelfRef.axi_write_owner_tb__DOT__w_fire) 
                           & ((~ (IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q)) 
                              & (IData)(vlSelfRef.axi_write_owner_tb__DOT__ARESETn)));
                    __Vinline_0__eval_body__act___Vinline_1__act_comb__TOP__0___VdfgRegularize_hebeb780c_0_0 
                        = ((IData)(vlSelfRef.axi_write_owner_tb__DOT__ARESETn) 
                           & (IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q));
                    vlSelfRef.axi_write_owner_tb__DOT__allocate_violation 
                        = ((IData)(vlSelfRef.axi_write_owner_tb__DOT__allocate_fire) 
                           & __Vinline_0__eval_body__act___Vinline_1__act_comb__TOP__0___VdfgRegularize_hebeb780c_0_0);
                    vlSelfRef.axi_write_owner_tb__DOT__wlast_mismatch_violation 
                        = (__Vinline_0__eval_body__act___Vinline_1__act_comb__TOP__0___VdfgRegularize_hebeb780c_0_0 
                           & ((IData)(vlSelfRef.axi_write_owner_tb__DOT__w_fire) 
                              & ((IData)(vlSelfRef.axi_write_owner_tb__DOT__wlast) 
                                 != ((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q) 
                                     & (1U == (IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__beats_q))))));
                }
            }
        }
    }
    return (__VactExecute);
}

bool Vaxi_write_owner_tb___024root___eval_inact(Vaxi_write_owner_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_tb___024root___eval_inact\n"); );
    Vaxi_write_owner_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VinactExecute;
    // Body
    __VinactExecute = vlSelfRef.__VdlySched.awaitingZeroDelay();
    if (__VinactExecute) {
        VL_FATAL_MT("/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 1, "", "ZERODLY: Design Verilated with '--no-sched-zero-delay', but #0 delay executed at runtime");
    }
    return (__VinactExecute);
}

void Vaxi_write_owner_tb___024root___trigger_clear__act(VlUnpacked<QData/*63:0*/, 1> &out);

bool Vaxi_write_owner_tb___024root___eval_nba(Vaxi_write_owner_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_tb___024root___eval_nba\n"); );
    Vaxi_write_owner_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = Vaxi_write_owner_tb___024root___trigger_anySet__act(vlSelfRef.__VnbaTriggered);
    if (__VnbaExecute) {
        {
            // Inlined CFunc: _eval_body__nba
            if ((3ULL & vlSelfRef.__VnbaTriggered[0U])) {
                {
                    // Inlined CFunc: _nba_sequent__TOP__0
                    CData/*0:0*/ __Vinline_0__eval_body__nba___Vinline_0__nba_sequent__TOP__0___Vdly__axi_write_owner_tb__DOT__dut__DOT__active_q;
                    __Vinline_0__eval_body__nba___Vinline_0__nba_sequent__TOP__0___Vdly__axi_write_owner_tb__DOT__dut__DOT__active_q = 0;
                    CData/*4:0*/ __Vinline_0__eval_body__nba___Vinline_0__nba_sequent__TOP__0___Vdly__axi_write_owner_tb__DOT__dut__DOT__beats_q;
                    __Vinline_0__eval_body__nba___Vinline_0__nba_sequent__TOP__0___Vdly__axi_write_owner_tb__DOT__dut__DOT__beats_q = 0;
                    __Vinline_0__eval_body__nba___Vinline_0__nba_sequent__TOP__0___Vdly__axi_write_owner_tb__DOT__dut__DOT__beats_q 
                        = vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__beats_q;
                    __Vinline_0__eval_body__nba___Vinline_0__nba_sequent__TOP__0___Vdly__axi_write_owner_tb__DOT__dut__DOT__active_q 
                        = vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q;
                    if (vlSelfRef.axi_write_owner_tb__DOT__ARESETn) {
                        if (((IData)(vlSelfRef.axi_write_owner_tb__DOT__allocate_fire) 
                             & (~ (IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q)))) {
                            __Vinline_0__eval_body__nba___Vinline_0__nba_sequent__TOP__0___Vdly__axi_write_owner_tb__DOT__dut__DOT__beats_q 
                                = ((0x0fU < (IData)(vlSelfRef.axi_write_owner_tb__DOT__allocate_len))
                                    ? 0x00000010U : 
                                   (0x0000001fU & ((IData)(1U) 
                                                   + 
                                                   (0x0000000fU 
                                                    & (IData)(vlSelfRef.axi_write_owner_tb__DOT__allocate_len)))));
                            __Vinline_0__eval_body__nba___Vinline_0__nba_sequent__TOP__0___Vdly__axi_write_owner_tb__DOT__dut__DOT__active_q = 1U;
                            vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__target_q 
                                = vlSelfRef.axi_write_owner_tb__DOT__allocate_target;
                            vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__id_q 
                                = vlSelfRef.axi_write_owner_tb__DOT__allocate_id;
                            vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__internal_id_q 
                                = vlSelfRef.axi_write_owner_tb__DOT__allocate_internal_id;
                        } else if (((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q) 
                                    & (IData)(vlSelfRef.axi_write_owner_tb__DOT__w_fire))) {
                            if (((1U == (IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__beats_q)) 
                                 & (IData)(vlSelfRef.axi_write_owner_tb__DOT__wlast))) {
                                __Vinline_0__eval_body__nba___Vinline_0__nba_sequent__TOP__0___Vdly__axi_write_owner_tb__DOT__dut__DOT__beats_q = 0U;
                                __Vinline_0__eval_body__nba___Vinline_0__nba_sequent__TOP__0___Vdly__axi_write_owner_tb__DOT__dut__DOT__active_q = 0U;
                                vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__target_q = 0U;
                                vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__id_q = 0U;
                                vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__internal_id_q = 0U;
                            } else if ((1U < (IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__beats_q))) {
                                __Vinline_0__eval_body__nba___Vinline_0__nba_sequent__TOP__0___Vdly__axi_write_owner_tb__DOT__dut__DOT__beats_q 
                                    = (0x0000001fU 
                                       & ((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__beats_q) 
                                          - (IData)(1U)));
                            }
                        }
                    } else {
                        __Vinline_0__eval_body__nba___Vinline_0__nba_sequent__TOP__0___Vdly__axi_write_owner_tb__DOT__dut__DOT__beats_q = 0U;
                        __Vinline_0__eval_body__nba___Vinline_0__nba_sequent__TOP__0___Vdly__axi_write_owner_tb__DOT__dut__DOT__active_q = 0U;
                        vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__target_q = 0U;
                        vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__id_q = 0U;
                        vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__internal_id_q = 0U;
                    }
                    vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__beats_q 
                        = __Vinline_0__eval_body__nba___Vinline_0__nba_sequent__TOP__0___Vdly__axi_write_owner_tb__DOT__dut__DOT__beats_q;
                    vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q 
                        = __Vinline_0__eval_body__nba___Vinline_0__nba_sequent__TOP__0___Vdly__axi_write_owner_tb__DOT__dut__DOT__active_q;
                }
            }
            if ((0x000000000000000fULL & vlSelfRef.__VnbaTriggered[0U])) {
                {
                    // Inlined CFunc: _act_comb__TOP__0
                    CData/*0:0*/ __Vinline_0__eval_body__nba___Vinline_2__act_comb__TOP__0___VdfgRegularize_hebeb780c_0_0;
                    __Vinline_0__eval_body__nba___Vinline_2__act_comb__TOP__0___VdfgRegularize_hebeb780c_0_0 = 0;
                    vlSelfRef.axi_write_owner_tb__DOT__allocate_allowed 
                        = ((~ (IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q)) 
                           & (IData)(vlSelfRef.axi_write_owner_tb__DOT__ARESETn));
                    vlSelfRef.axi_write_owner_tb__DOT__w_without_owner_violation 
                        = ((IData)(vlSelfRef.axi_write_owner_tb__DOT__w_fire) 
                           & ((~ (IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q)) 
                              & (IData)(vlSelfRef.axi_write_owner_tb__DOT__ARESETn)));
                    __Vinline_0__eval_body__nba___Vinline_2__act_comb__TOP__0___VdfgRegularize_hebeb780c_0_0 
                        = ((IData)(vlSelfRef.axi_write_owner_tb__DOT__ARESETn) 
                           & (IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q));
                    vlSelfRef.axi_write_owner_tb__DOT__allocate_violation 
                        = ((IData)(vlSelfRef.axi_write_owner_tb__DOT__allocate_fire) 
                           & __Vinline_0__eval_body__nba___Vinline_2__act_comb__TOP__0___VdfgRegularize_hebeb780c_0_0);
                    vlSelfRef.axi_write_owner_tb__DOT__wlast_mismatch_violation 
                        = (__Vinline_0__eval_body__nba___Vinline_2__act_comb__TOP__0___VdfgRegularize_hebeb780c_0_0 
                           & ((IData)(vlSelfRef.axi_write_owner_tb__DOT__w_fire) 
                              & ((IData)(vlSelfRef.axi_write_owner_tb__DOT__wlast) 
                                 != ((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q) 
                                     & (1U == (IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__beats_q))))));
                }
            }
        }
        Vaxi_write_owner_tb___024root___trigger_clear__act(vlSelfRef.__VnbaTriggered);
    }
    return (__VnbaExecute);
}

bool Vaxi_write_owner_tb___024root___eval_obs(Vaxi_write_owner_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_tb___024root___eval_obs\n"); );
    Vaxi_write_owner_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    return (0U);
}

bool Vaxi_write_owner_tb___024root___eval_react(Vaxi_write_owner_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_tb___024root___eval_react\n"); );
    Vaxi_write_owner_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    return (0U);
}

void Vaxi_write_owner_tb___024root___eval_postponed(Vaxi_write_owner_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_tb___024root___eval_postponed\n"); );
    Vaxi_write_owner_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

void Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1e69__0(Vaxi_write_owner_tb___024root* vlSelf, const char* __VeventDescription);
void Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1db6__0(Vaxi_write_owner_tb___024root* vlSelf, const char* __VeventDescription);

VlCoroutine Vaxi_write_owner_tb___024root___eval_initial__TOP__Vtiming__0(Vaxi_write_owner_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_tb___024root___eval_initial__TOP__Vtiming__0\n"); );
    Vaxi_write_owner_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ axi_write_owner_tb__DOT__pre_violation;
    axi_write_owner_tb__DOT__pre_violation = 0;
    CData/*0:0*/ axi_write_owner_tb__DOT__ownerless_seen;
    axi_write_owner_tb__DOT__ownerless_seen = 0;
    CData/*0:0*/ axi_write_owner_tb__DOT__wlast_seen;
    axi_write_owner_tb__DOT__wlast_seen = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_tb__DOT__check__0__condition;
    __Vtask_axi_write_owner_tb__DOT__check__0__condition = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_tb__DOT__check__1__condition;
    __Vtask_axi_write_owner_tb__DOT__check__1__condition = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_tb__DOT__wbeat__2__last;
    __Vtask_axi_write_owner_tb__DOT__wbeat__2__last = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_tb__DOT__check__3__condition;
    __Vtask_axi_write_owner_tb__DOT__check__3__condition = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_tb__DOT__check__4__condition;
    __Vtask_axi_write_owner_tb__DOT__check__4__condition = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_tb__DOT__check__5__condition;
    __Vtask_axi_write_owner_tb__DOT__check__5__condition = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_tb__DOT__wbeat__6__last;
    __Vtask_axi_write_owner_tb__DOT__wbeat__6__last = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_tb__DOT__check__7__condition;
    __Vtask_axi_write_owner_tb__DOT__check__7__condition = 0;
    CData/*7:0*/ __Vtask_axi_write_owner_tb__DOT__allocate__8__len;
    __Vtask_axi_write_owner_tb__DOT__allocate__8__len = 0;
    CData/*3:0*/ __Vtask_axi_write_owner_tb__DOT__allocate__8__target;
    __Vtask_axi_write_owner_tb__DOT__allocate__8__target = 0;
    CData/*3:0*/ __Vtask_axi_write_owner_tb__DOT__allocate__8__id;
    __Vtask_axi_write_owner_tb__DOT__allocate__8__id = 0;
    CData/*5:0*/ __Vtask_axi_write_owner_tb__DOT__allocate__8__internal_id;
    __Vtask_axi_write_owner_tb__DOT__allocate__8__internal_id = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_tb__DOT__check__9__condition;
    __Vtask_axi_write_owner_tb__DOT__check__9__condition = 0;
    IData/*31:0*/ __Vtask_axi_write_owner_tb__DOT__idle_cycles__10__count;
    __Vtask_axi_write_owner_tb__DOT__idle_cycles__10__count = 0;
    IData/*31:0*/ __Vtask_axi_write_owner_tb__DOT__idle_cycles__10__axi_write_owner_tb__DOT__unnamedblk1_1__DOT____Vrepeat0;
    __Vtask_axi_write_owner_tb__DOT__idle_cycles__10__axi_write_owner_tb__DOT__unnamedblk1_1__DOT____Vrepeat0 = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_tb__DOT__check__11__condition;
    __Vtask_axi_write_owner_tb__DOT__check__11__condition = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_tb__DOT__wbeat__12__last;
    __Vtask_axi_write_owner_tb__DOT__wbeat__12__last = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_tb__DOT__check__13__condition;
    __Vtask_axi_write_owner_tb__DOT__check__13__condition = 0;
    IData/*31:0*/ __Vtask_axi_write_owner_tb__DOT__idle_cycles__14__count;
    __Vtask_axi_write_owner_tb__DOT__idle_cycles__14__count = 0;
    IData/*31:0*/ __Vtask_axi_write_owner_tb__DOT__idle_cycles__14__axi_write_owner_tb__DOT__unnamedblk1_1__DOT____Vrepeat0;
    __Vtask_axi_write_owner_tb__DOT__idle_cycles__14__axi_write_owner_tb__DOT__unnamedblk1_1__DOT____Vrepeat0 = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_tb__DOT__check__15__condition;
    __Vtask_axi_write_owner_tb__DOT__check__15__condition = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_tb__DOT__wbeat__16__last;
    __Vtask_axi_write_owner_tb__DOT__wbeat__16__last = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_tb__DOT__check__17__condition;
    __Vtask_axi_write_owner_tb__DOT__check__17__condition = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_tb__DOT__wbeat__18__last;
    __Vtask_axi_write_owner_tb__DOT__wbeat__18__last = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_tb__DOT__check__19__condition;
    __Vtask_axi_write_owner_tb__DOT__check__19__condition = 0;
    IData/*31:0*/ __Vtask_axi_write_owner_tb__DOT__idle_cycles__20__count;
    __Vtask_axi_write_owner_tb__DOT__idle_cycles__20__count = 0;
    IData/*31:0*/ __Vtask_axi_write_owner_tb__DOT__idle_cycles__20__axi_write_owner_tb__DOT__unnamedblk1_1__DOT____Vrepeat0;
    __Vtask_axi_write_owner_tb__DOT__idle_cycles__20__axi_write_owner_tb__DOT__unnamedblk1_1__DOT____Vrepeat0 = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_tb__DOT__check__21__condition;
    __Vtask_axi_write_owner_tb__DOT__check__21__condition = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_tb__DOT__wbeat__22__last;
    __Vtask_axi_write_owner_tb__DOT__wbeat__22__last = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_tb__DOT__check__23__condition;
    __Vtask_axi_write_owner_tb__DOT__check__23__condition = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_tb__DOT__wbeat__24__last;
    __Vtask_axi_write_owner_tb__DOT__wbeat__24__last = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_tb__DOT__check__25__condition;
    __Vtask_axi_write_owner_tb__DOT__check__25__condition = 0;
    CData/*7:0*/ __Vtask_axi_write_owner_tb__DOT__allocate__26__len;
    __Vtask_axi_write_owner_tb__DOT__allocate__26__len = 0;
    CData/*3:0*/ __Vtask_axi_write_owner_tb__DOT__allocate__26__target;
    __Vtask_axi_write_owner_tb__DOT__allocate__26__target = 0;
    CData/*3:0*/ __Vtask_axi_write_owner_tb__DOT__allocate__26__id;
    __Vtask_axi_write_owner_tb__DOT__allocate__26__id = 0;
    CData/*5:0*/ __Vtask_axi_write_owner_tb__DOT__allocate__26__internal_id;
    __Vtask_axi_write_owner_tb__DOT__allocate__26__internal_id = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_tb__DOT__check__27__condition;
    __Vtask_axi_write_owner_tb__DOT__check__27__condition = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_tb__DOT__wbeat__28__last;
    __Vtask_axi_write_owner_tb__DOT__wbeat__28__last = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_tb__DOT__wbeat__29__last;
    __Vtask_axi_write_owner_tb__DOT__wbeat__29__last = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_tb__DOT__check__30__condition;
    __Vtask_axi_write_owner_tb__DOT__check__30__condition = 0;
    CData/*7:0*/ __Vtask_axi_write_owner_tb__DOT__allocate__31__len;
    __Vtask_axi_write_owner_tb__DOT__allocate__31__len = 0;
    CData/*3:0*/ __Vtask_axi_write_owner_tb__DOT__allocate__31__target;
    __Vtask_axi_write_owner_tb__DOT__allocate__31__target = 0;
    CData/*3:0*/ __Vtask_axi_write_owner_tb__DOT__allocate__31__id;
    __Vtask_axi_write_owner_tb__DOT__allocate__31__id = 0;
    CData/*5:0*/ __Vtask_axi_write_owner_tb__DOT__allocate__31__internal_id;
    __Vtask_axi_write_owner_tb__DOT__allocate__31__internal_id = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_tb__DOT__check__32__condition;
    __Vtask_axi_write_owner_tb__DOT__check__32__condition = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_tb__DOT__check__33__condition;
    __Vtask_axi_write_owner_tb__DOT__check__33__condition = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_tb__DOT__check__34__condition;
    __Vtask_axi_write_owner_tb__DOT__check__34__condition = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_tb__DOT__wbeat__35__last;
    __Vtask_axi_write_owner_tb__DOT__wbeat__35__last = 0;
    CData/*7:0*/ __Vtask_axi_write_owner_tb__DOT__allocate__36__len;
    __Vtask_axi_write_owner_tb__DOT__allocate__36__len = 0;
    CData/*3:0*/ __Vtask_axi_write_owner_tb__DOT__allocate__36__target;
    __Vtask_axi_write_owner_tb__DOT__allocate__36__target = 0;
    CData/*3:0*/ __Vtask_axi_write_owner_tb__DOT__allocate__36__id;
    __Vtask_axi_write_owner_tb__DOT__allocate__36__id = 0;
    CData/*5:0*/ __Vtask_axi_write_owner_tb__DOT__allocate__36__internal_id;
    __Vtask_axi_write_owner_tb__DOT__allocate__36__internal_id = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_tb__DOT__check__37__condition;
    __Vtask_axi_write_owner_tb__DOT__check__37__condition = 0;
    CData/*0:0*/ __Vtask_axi_write_owner_tb__DOT__check__38__condition;
    __Vtask_axi_write_owner_tb__DOT__check__38__condition = 0;
    // Body
    vlSelfRef.axi_write_owner_tb__DOT__ARESETn = 1U;
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                         49);
    vlSelfRef.axi_write_owner_tb__DOT__ARESETn = 0U;
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                         49);
    vlSelfRef.axi_write_owner_tb__DOT__allocate_fire = 0U;
    vlSelfRef.axi_write_owner_tb__DOT__w_fire = 0U;
    vlSelfRef.axi_write_owner_tb__DOT__wlast = 0U;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_target = 0U;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_id = 0U;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_internal_id = 0U;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_len = 0U;
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                         52);
    vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__0__message = "reset state"s;
    __Vtask_axi_write_owner_tb__DOT__check__0__condition 
        = ((~ (IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q)) 
           & (0U == ((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__beats_q) 
                     & (- (IData)((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q))))));
    vlSelfRef.axi_write_owner_tb__DOT__checks = ((IData)(1U) 
                                                 + vlSelfRef.axi_write_owner_tb__DOT__checks);
    if (VL_UNLIKELY(((1U & (~ (IData)(__Vtask_axi_write_owner_tb__DOT__check__0__condition)))))) {
        VL_WRITEF_NX("FAIL %s\n[%0t] %%Fatal: axi_write_owner_tb.sv:27: Assertion failed in %m\n",4, 'M',vlSymsp->name(),"axi_write_owner_tb.check", 'T',-12
                     , 'S',&(vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__0__message)
                     , '#',64,VL_TIME_UNITED_Q(1));
        VL_STOP_MT("/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 27, "", false);
    }
    vlSelfRef.axi_write_owner_tb__DOT__ARESETn = 1U;
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                         54);
    vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__1__message = "allocation permitted after reset"s;
    __Vtask_axi_write_owner_tb__DOT__check__1__condition 
        = vlSelfRef.axi_write_owner_tb__DOT__allocate_allowed;
    vlSelfRef.axi_write_owner_tb__DOT__checks = ((IData)(1U) 
                                                 + vlSelfRef.axi_write_owner_tb__DOT__checks);
    if (VL_UNLIKELY(((1U & (~ (IData)(__Vtask_axi_write_owner_tb__DOT__check__1__condition)))))) {
        VL_WRITEF_NX("FAIL %s\n[%0t] %%Fatal: axi_write_owner_tb.sv:27: Assertion failed in %m\n",4, 'M',vlSymsp->name(),"axi_write_owner_tb.check", 'T',-12
                     , 'S',&(vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__1__message)
                     , '#',64,VL_TIME_UNITED_Q(1));
        VL_STOP_MT("/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 27, "", false);
    }
    __Vtask_axi_write_owner_tb__DOT__wbeat__2__last = 1U;
    Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1e69__0(vlSelf, 
                                                              "@(negedge axi_write_owner_tb.ACLK)");
    co_await vlSelfRef.__VtrigSched_h3bfb1e69__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(negedge axi_write_owner_tb.ACLK)", 
                                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                                         42);
    vlSelfRef.axi_write_owner_tb__DOT__wlast = __Vtask_axi_write_owner_tb__DOT__wbeat__2__last;
    vlSelfRef.axi_write_owner_tb__DOT__w_fire = 1U;
    Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1db6__0(vlSelf, 
                                                              "@(posedge axi_write_owner_tb.ACLK)");
    co_await vlSelfRef.__VtrigSched_h3bfb1db6__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(posedge axi_write_owner_tb.ACLK)", 
                                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                                         43);
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                         43);
    axi_write_owner_tb__DOT__ownerless_seen = vlSelfRef.axi_write_owner_tb__DOT__w_without_owner_violation;
    axi_write_owner_tb__DOT__wlast_seen = vlSelfRef.axi_write_owner_tb__DOT__wlast_mismatch_violation;
    vlSelfRef.axi_write_owner_tb__DOT__w_fire = 0U;
    vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__3__message = "W without owner"s;
    __Vtask_axi_write_owner_tb__DOT__check__3__condition 
        = (((IData)(axi_write_owner_tb__DOT__ownerless_seen) 
            & (~ (IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q))) 
           & (0U == ((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__beats_q) 
                     & (- (IData)((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q))))));
    vlSelfRef.axi_write_owner_tb__DOT__checks = ((IData)(1U) 
                                                 + vlSelfRef.axi_write_owner_tb__DOT__checks);
    if (VL_UNLIKELY(((1U & (~ (IData)(__Vtask_axi_write_owner_tb__DOT__check__3__condition)))))) {
        VL_WRITEF_NX("FAIL %s\n[%0t] %%Fatal: axi_write_owner_tb.sv:27: Assertion failed in %m\n",4, 'M',vlSymsp->name(),"axi_write_owner_tb.check", 'T',-12
                     , 'S',&(vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__3__message)
                     , '#',64,VL_TIME_UNITED_Q(1));
        VL_STOP_MT("/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 27, "", false);
    }
    vlSelfRef.axi_write_owner_tb__DOT__allocate_len = 0U;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_target = 3U;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_id = 5U;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_internal_id = 0x21U;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_fire = 1U;
    vlSelfRef.axi_write_owner_tb__DOT__w_fire = 1U;
    vlSelfRef.axi_write_owner_tb__DOT__wlast = 1U;
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                         64);
    axi_write_owner_tb__DOT__pre_violation = vlSelfRef.axi_write_owner_tb__DOT__w_without_owner_violation;
    Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1db6__0(vlSelf, 
                                                              "@(posedge axi_write_owner_tb.ACLK)");
    co_await vlSelfRef.__VtrigSched_h3bfb1db6__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(posedge axi_write_owner_tb.ACLK)", 
                                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                                         65);
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                         65);
    vlSelfRef.axi_write_owner_tb__DOT__allocate_fire = 0U;
    vlSelfRef.axi_write_owner_tb__DOT__w_fire = 0U;
    vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__4__message = "same-cycle allocate/W pre-state"s;
    __Vtask_axi_write_owner_tb__DOT__check__4__condition 
        = (((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q) 
            & (1U == ((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__beats_q) 
                      & (- (IData)((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q)))))) 
           & (IData)(axi_write_owner_tb__DOT__pre_violation));
    vlSelfRef.axi_write_owner_tb__DOT__checks = ((IData)(1U) 
                                                 + vlSelfRef.axi_write_owner_tb__DOT__checks);
    if (VL_UNLIKELY(((1U & (~ (IData)(__Vtask_axi_write_owner_tb__DOT__check__4__condition)))))) {
        VL_WRITEF_NX("FAIL %s\n[%0t] %%Fatal: axi_write_owner_tb.sv:27: Assertion failed in %m\n",4, 'M',vlSymsp->name(),"axi_write_owner_tb.check", 'T',-12
                     , 'S',&(vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__4__message)
                     , '#',64,VL_TIME_UNITED_Q(1));
        VL_STOP_MT("/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 27, "", false);
    }
    vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__5__message = "metadata capture"s;
    __Vtask_axi_write_owner_tb__DOT__check__5__condition 
        = (((3U == ((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__target_q) 
                    & (- (IData)((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q))))) 
            & (5U == ((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__id_q) 
                      & (- (IData)((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q)))))) 
           & (0x21U == ((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__internal_id_q) 
                        & (- (IData)((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q))))));
    vlSelfRef.axi_write_owner_tb__DOT__checks = ((IData)(1U) 
                                                 + vlSelfRef.axi_write_owner_tb__DOT__checks);
    if (VL_UNLIKELY(((1U & (~ (IData)(__Vtask_axi_write_owner_tb__DOT__check__5__condition)))))) {
        VL_WRITEF_NX("FAIL %s\n[%0t] %%Fatal: axi_write_owner_tb.sv:27: Assertion failed in %m\n",4, 'M',vlSymsp->name(),"axi_write_owner_tb.check", 'T',-12
                     , 'S',&(vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__5__message)
                     , '#',64,VL_TIME_UNITED_Q(1));
        VL_STOP_MT("/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 27, "", false);
    }
    __Vtask_axi_write_owner_tb__DOT__wbeat__6__last = 1U;
    Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1e69__0(vlSelf, 
                                                              "@(negedge axi_write_owner_tb.ACLK)");
    co_await vlSelfRef.__VtrigSched_h3bfb1e69__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(negedge axi_write_owner_tb.ACLK)", 
                                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                                         42);
    vlSelfRef.axi_write_owner_tb__DOT__wlast = __Vtask_axi_write_owner_tb__DOT__wbeat__6__last;
    vlSelfRef.axi_write_owner_tb__DOT__w_fire = 1U;
    Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1db6__0(vlSelf, 
                                                              "@(posedge axi_write_owner_tb.ACLK)");
    co_await vlSelfRef.__VtrigSched_h3bfb1db6__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(posedge axi_write_owner_tb.ACLK)", 
                                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                                         43);
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                         43);
    axi_write_owner_tb__DOT__ownerless_seen = vlSelfRef.axi_write_owner_tb__DOT__w_without_owner_violation;
    axi_write_owner_tb__DOT__wlast_seen = vlSelfRef.axi_write_owner_tb__DOT__wlast_mismatch_violation;
    vlSelfRef.axi_write_owner_tb__DOT__w_fire = 0U;
    vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__7__message = "single-beat completion without B"s;
    __Vtask_axi_write_owner_tb__DOT__check__7__condition 
        = ((~ (IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q)) 
           & (0U == ((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__beats_q) 
                     & (- (IData)((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q))))));
    vlSelfRef.axi_write_owner_tb__DOT__checks = ((IData)(1U) 
                                                 + vlSelfRef.axi_write_owner_tb__DOT__checks);
    if (VL_UNLIKELY(((1U & (~ (IData)(__Vtask_axi_write_owner_tb__DOT__check__7__condition)))))) {
        VL_WRITEF_NX("FAIL %s\n[%0t] %%Fatal: axi_write_owner_tb.sv:27: Assertion failed in %m\n",4, 'M',vlSymsp->name(),"axi_write_owner_tb.check", 'T',-12
                     , 'S',&(vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__7__message)
                     , '#',64,VL_TIME_UNITED_Q(1));
        VL_STOP_MT("/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 27, "", false);
    }
    __Vtask_axi_write_owner_tb__DOT__allocate__8__internal_id = 0x12U;
    __Vtask_axi_write_owner_tb__DOT__allocate__8__id = 2U;
    __Vtask_axi_write_owner_tb__DOT__allocate__8__target = 1U;
    __Vtask_axi_write_owner_tb__DOT__allocate__8__len = 3U;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_len 
        = __Vtask_axi_write_owner_tb__DOT__allocate__8__len;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_target 
        = __Vtask_axi_write_owner_tb__DOT__allocate__8__target;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_id 
        = __Vtask_axi_write_owner_tb__DOT__allocate__8__id;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_internal_id 
        = __Vtask_axi_write_owner_tb__DOT__allocate__8__internal_id;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_fire = 1U;
    Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1db6__0(vlSelf, 
                                                              "@(posedge axi_write_owner_tb.ACLK)");
    co_await vlSelfRef.__VtrigSched_h3bfb1db6__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(posedge axi_write_owner_tb.ACLK)", 
                                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                                         38);
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                         38);
    vlSelfRef.axi_write_owner_tb__DOT__allocate_fire = 0U;
    vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__9__message = "four-beat allocation"s;
    __Vtask_axi_write_owner_tb__DOT__check__9__condition 
        = (((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q) 
            & (4U == ((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__beats_q) 
                      & (- (IData)((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q)))))) 
           & (~ ((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q) 
                 & (1U == (IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__beats_q)))));
    vlSelfRef.axi_write_owner_tb__DOT__checks = ((IData)(1U) 
                                                 + vlSelfRef.axi_write_owner_tb__DOT__checks);
    if (VL_UNLIKELY(((1U & (~ (IData)(__Vtask_axi_write_owner_tb__DOT__check__9__condition)))))) {
        VL_WRITEF_NX("FAIL %s\n[%0t] %%Fatal: axi_write_owner_tb.sv:27: Assertion failed in %m\n",4, 'M',vlSymsp->name(),"axi_write_owner_tb.check", 'T',-12
                     , 'S',&(vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__9__message)
                     , '#',64,VL_TIME_UNITED_Q(1));
        VL_STOP_MT("/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 27, "", false);
    }
    __Vtask_axi_write_owner_tb__DOT__idle_cycles__10__count = 2U;
    __Vtask_axi_write_owner_tb__DOT__idle_cycles__10__axi_write_owner_tb__DOT__unnamedblk1_1__DOT____Vrepeat0 = 0U;
    __Vtask_axi_write_owner_tb__DOT__idle_cycles__10__axi_write_owner_tb__DOT__unnamedblk1_1__DOT____Vrepeat0 
        = __Vtask_axi_write_owner_tb__DOT__idle_cycles__10__count;
    while (VL_LTS_III(32, 0U, __Vtask_axi_write_owner_tb__DOT__idle_cycles__10__axi_write_owner_tb__DOT__unnamedblk1_1__DOT____Vrepeat0)) {
        Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1db6__0(vlSelf, 
                                                                  "@(posedge axi_write_owner_tb.ACLK)");
        co_await vlSelfRef.__VtrigSched_h3bfb1db6__0.trigger(0U, 
                                                             nullptr, 
                                                             "@(posedge axi_write_owner_tb.ACLK)", 
                                                             "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                                             32);
        __Vtask_axi_write_owner_tb__DOT__idle_cycles__10__axi_write_owner_tb__DOT__unnamedblk1_1__DOT____Vrepeat0 
            = (__Vtask_axi_write_owner_tb__DOT__idle_cycles__10__axi_write_owner_tb__DOT__unnamedblk1_1__DOT____Vrepeat0 
               - (IData)(1U));
    }
    vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__11__message = "pre-first stall"s;
    __Vtask_axi_write_owner_tb__DOT__check__11__condition 
        = (((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q) 
            & (4U == ((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__beats_q) 
                      & (- (IData)((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q)))))) 
           & (1U == ((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__target_q) 
                     & (- (IData)((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q))))));
    vlSelfRef.axi_write_owner_tb__DOT__checks = ((IData)(1U) 
                                                 + vlSelfRef.axi_write_owner_tb__DOT__checks);
    if (VL_UNLIKELY(((1U & (~ (IData)(__Vtask_axi_write_owner_tb__DOT__check__11__condition)))))) {
        VL_WRITEF_NX("FAIL %s\n[%0t] %%Fatal: axi_write_owner_tb.sv:27: Assertion failed in %m\n",4, 'M',vlSymsp->name(),"axi_write_owner_tb.check", 'T',-12
                     , 'S',&(vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__11__message)
                     , '#',64,VL_TIME_UNITED_Q(1));
        VL_STOP_MT("/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 27, "", false);
    }
    __Vtask_axi_write_owner_tb__DOT__wbeat__12__last = 0U;
    Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1e69__0(vlSelf, 
                                                              "@(negedge axi_write_owner_tb.ACLK)");
    co_await vlSelfRef.__VtrigSched_h3bfb1e69__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(negedge axi_write_owner_tb.ACLK)", 
                                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                                         42);
    vlSelfRef.axi_write_owner_tb__DOT__wlast = __Vtask_axi_write_owner_tb__DOT__wbeat__12__last;
    vlSelfRef.axi_write_owner_tb__DOT__w_fire = 1U;
    Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1db6__0(vlSelf, 
                                                              "@(posedge axi_write_owner_tb.ACLK)");
    co_await vlSelfRef.__VtrigSched_h3bfb1db6__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(posedge axi_write_owner_tb.ACLK)", 
                                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                                         43);
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                         43);
    axi_write_owner_tb__DOT__ownerless_seen = vlSelfRef.axi_write_owner_tb__DOT__w_without_owner_violation;
    axi_write_owner_tb__DOT__wlast_seen = vlSelfRef.axi_write_owner_tb__DOT__wlast_mismatch_violation;
    vlSelfRef.axi_write_owner_tb__DOT__w_fire = 0U;
    vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__13__message = "first non-final beat"s;
    __Vtask_axi_write_owner_tb__DOT__check__13__condition 
        = (((3U == ((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__beats_q) 
                    & (- (IData)((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q))))) 
            & (IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q)) 
           & (~ ((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q) 
                 & (1U == (IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__beats_q)))));
    vlSelfRef.axi_write_owner_tb__DOT__checks = ((IData)(1U) 
                                                 + vlSelfRef.axi_write_owner_tb__DOT__checks);
    if (VL_UNLIKELY(((1U & (~ (IData)(__Vtask_axi_write_owner_tb__DOT__check__13__condition)))))) {
        VL_WRITEF_NX("FAIL %s\n[%0t] %%Fatal: axi_write_owner_tb.sv:27: Assertion failed in %m\n",4, 'M',vlSymsp->name(),"axi_write_owner_tb.check", 'T',-12
                     , 'S',&(vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__13__message)
                     , '#',64,VL_TIME_UNITED_Q(1));
        VL_STOP_MT("/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 27, "", false);
    }
    __Vtask_axi_write_owner_tb__DOT__idle_cycles__14__count = 2U;
    __Vtask_axi_write_owner_tb__DOT__idle_cycles__14__axi_write_owner_tb__DOT__unnamedblk1_1__DOT____Vrepeat0 = 0U;
    __Vtask_axi_write_owner_tb__DOT__idle_cycles__14__axi_write_owner_tb__DOT__unnamedblk1_1__DOT____Vrepeat0 
        = __Vtask_axi_write_owner_tb__DOT__idle_cycles__14__count;
    while (VL_LTS_III(32, 0U, __Vtask_axi_write_owner_tb__DOT__idle_cycles__14__axi_write_owner_tb__DOT__unnamedblk1_1__DOT____Vrepeat0)) {
        Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1db6__0(vlSelf, 
                                                                  "@(posedge axi_write_owner_tb.ACLK)");
        co_await vlSelfRef.__VtrigSched_h3bfb1db6__0.trigger(0U, 
                                                             nullptr, 
                                                             "@(posedge axi_write_owner_tb.ACLK)", 
                                                             "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                                             32);
        __Vtask_axi_write_owner_tb__DOT__idle_cycles__14__axi_write_owner_tb__DOT__unnamedblk1_1__DOT____Vrepeat0 
            = (__Vtask_axi_write_owner_tb__DOT__idle_cycles__14__axi_write_owner_tb__DOT__unnamedblk1_1__DOT____Vrepeat0 
               - (IData)(1U));
    }
    vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__15__message = "mid-burst stall"s;
    __Vtask_axi_write_owner_tb__DOT__check__15__condition 
        = ((3U == ((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__beats_q) 
                   & (- (IData)((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q))))) 
           & (IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q));
    vlSelfRef.axi_write_owner_tb__DOT__checks = ((IData)(1U) 
                                                 + vlSelfRef.axi_write_owner_tb__DOT__checks);
    if (VL_UNLIKELY(((1U & (~ (IData)(__Vtask_axi_write_owner_tb__DOT__check__15__condition)))))) {
        VL_WRITEF_NX("FAIL %s\n[%0t] %%Fatal: axi_write_owner_tb.sv:27: Assertion failed in %m\n",4, 'M',vlSymsp->name(),"axi_write_owner_tb.check", 'T',-12
                     , 'S',&(vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__15__message)
                     , '#',64,VL_TIME_UNITED_Q(1));
        VL_STOP_MT("/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 27, "", false);
    }
    __Vtask_axi_write_owner_tb__DOT__wbeat__16__last = 1U;
    Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1e69__0(vlSelf, 
                                                              "@(negedge axi_write_owner_tb.ACLK)");
    co_await vlSelfRef.__VtrigSched_h3bfb1e69__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(negedge axi_write_owner_tb.ACLK)", 
                                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                                         42);
    vlSelfRef.axi_write_owner_tb__DOT__wlast = __Vtask_axi_write_owner_tb__DOT__wbeat__16__last;
    vlSelfRef.axi_write_owner_tb__DOT__w_fire = 1U;
    Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1db6__0(vlSelf, 
                                                              "@(posedge axi_write_owner_tb.ACLK)");
    co_await vlSelfRef.__VtrigSched_h3bfb1db6__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(posedge axi_write_owner_tb.ACLK)", 
                                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                                         43);
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                         43);
    axi_write_owner_tb__DOT__ownerless_seen = vlSelfRef.axi_write_owner_tb__DOT__w_without_owner_violation;
    axi_write_owner_tb__DOT__wlast_seen = vlSelfRef.axi_write_owner_tb__DOT__wlast_mismatch_violation;
    vlSelfRef.axi_write_owner_tb__DOT__w_fire = 0U;
    vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__17__message = "early WLAST"s;
    __Vtask_axi_write_owner_tb__DOT__check__17__condition 
        = (((IData)(axi_write_owner_tb__DOT__wlast_seen) 
            & (IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q)) 
           & (2U == ((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__beats_q) 
                     & (- (IData)((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q))))));
    vlSelfRef.axi_write_owner_tb__DOT__checks = ((IData)(1U) 
                                                 + vlSelfRef.axi_write_owner_tb__DOT__checks);
    if (VL_UNLIKELY(((1U & (~ (IData)(__Vtask_axi_write_owner_tb__DOT__check__17__condition)))))) {
        VL_WRITEF_NX("FAIL %s\n[%0t] %%Fatal: axi_write_owner_tb.sv:27: Assertion failed in %m\n",4, 'M',vlSymsp->name(),"axi_write_owner_tb.check", 'T',-12
                     , 'S',&(vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__17__message)
                     , '#',64,VL_TIME_UNITED_Q(1));
        VL_STOP_MT("/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 27, "", false);
    }
    __Vtask_axi_write_owner_tb__DOT__wbeat__18__last = 0U;
    Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1e69__0(vlSelf, 
                                                              "@(negedge axi_write_owner_tb.ACLK)");
    co_await vlSelfRef.__VtrigSched_h3bfb1e69__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(negedge axi_write_owner_tb.ACLK)", 
                                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                                         42);
    vlSelfRef.axi_write_owner_tb__DOT__wlast = __Vtask_axi_write_owner_tb__DOT__wbeat__18__last;
    vlSelfRef.axi_write_owner_tb__DOT__w_fire = 1U;
    Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1db6__0(vlSelf, 
                                                              "@(posedge axi_write_owner_tb.ACLK)");
    co_await vlSelfRef.__VtrigSched_h3bfb1db6__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(posedge axi_write_owner_tb.ACLK)", 
                                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                                         43);
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                         43);
    axi_write_owner_tb__DOT__ownerless_seen = vlSelfRef.axi_write_owner_tb__DOT__w_without_owner_violation;
    axi_write_owner_tb__DOT__wlast_seen = vlSelfRef.axi_write_owner_tb__DOT__wlast_mismatch_violation;
    vlSelfRef.axi_write_owner_tb__DOT__w_fire = 0U;
    vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__19__message = "expected final beat reached"s;
    __Vtask_axi_write_owner_tb__DOT__check__19__condition 
        = ((1U == ((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__beats_q) 
                   & (- (IData)((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q))))) 
           & ((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q) 
              & (1U == (IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__beats_q))));
    vlSelfRef.axi_write_owner_tb__DOT__checks = ((IData)(1U) 
                                                 + vlSelfRef.axi_write_owner_tb__DOT__checks);
    if (VL_UNLIKELY(((1U & (~ (IData)(__Vtask_axi_write_owner_tb__DOT__check__19__condition)))))) {
        VL_WRITEF_NX("FAIL %s\n[%0t] %%Fatal: axi_write_owner_tb.sv:27: Assertion failed in %m\n",4, 'M',vlSymsp->name(),"axi_write_owner_tb.check", 'T',-12
                     , 'S',&(vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__19__message)
                     , '#',64,VL_TIME_UNITED_Q(1));
        VL_STOP_MT("/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 27, "", false);
    }
    __Vtask_axi_write_owner_tb__DOT__idle_cycles__20__count = 2U;
    __Vtask_axi_write_owner_tb__DOT__idle_cycles__20__axi_write_owner_tb__DOT__unnamedblk1_1__DOT____Vrepeat0 = 0U;
    __Vtask_axi_write_owner_tb__DOT__idle_cycles__20__axi_write_owner_tb__DOT__unnamedblk1_1__DOT____Vrepeat0 
        = __Vtask_axi_write_owner_tb__DOT__idle_cycles__20__count;
    while (VL_LTS_III(32, 0U, __Vtask_axi_write_owner_tb__DOT__idle_cycles__20__axi_write_owner_tb__DOT__unnamedblk1_1__DOT____Vrepeat0)) {
        Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1db6__0(vlSelf, 
                                                                  "@(posedge axi_write_owner_tb.ACLK)");
        co_await vlSelfRef.__VtrigSched_h3bfb1db6__0.trigger(0U, 
                                                             nullptr, 
                                                             "@(posedge axi_write_owner_tb.ACLK)", 
                                                             "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                                             32);
        __Vtask_axi_write_owner_tb__DOT__idle_cycles__20__axi_write_owner_tb__DOT__unnamedblk1_1__DOT____Vrepeat0 
            = (__Vtask_axi_write_owner_tb__DOT__idle_cycles__20__axi_write_owner_tb__DOT__unnamedblk1_1__DOT____Vrepeat0 
               - (IData)(1U));
    }
    vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__21__message = "final-beat stall"s;
    __Vtask_axi_write_owner_tb__DOT__check__21__condition 
        = ((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q) 
           & (1U == ((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__beats_q) 
                     & (- (IData)((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q))))));
    vlSelfRef.axi_write_owner_tb__DOT__checks = ((IData)(1U) 
                                                 + vlSelfRef.axi_write_owner_tb__DOT__checks);
    if (VL_UNLIKELY(((1U & (~ (IData)(__Vtask_axi_write_owner_tb__DOT__check__21__condition)))))) {
        VL_WRITEF_NX("FAIL %s\n[%0t] %%Fatal: axi_write_owner_tb.sv:27: Assertion failed in %m\n",4, 'M',vlSymsp->name(),"axi_write_owner_tb.check", 'T',-12
                     , 'S',&(vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__21__message)
                     , '#',64,VL_TIME_UNITED_Q(1));
        VL_STOP_MT("/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 27, "", false);
    }
    __Vtask_axi_write_owner_tb__DOT__wbeat__22__last = 0U;
    Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1e69__0(vlSelf, 
                                                              "@(negedge axi_write_owner_tb.ACLK)");
    co_await vlSelfRef.__VtrigSched_h3bfb1e69__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(negedge axi_write_owner_tb.ACLK)", 
                                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                                         42);
    vlSelfRef.axi_write_owner_tb__DOT__wlast = __Vtask_axi_write_owner_tb__DOT__wbeat__22__last;
    vlSelfRef.axi_write_owner_tb__DOT__w_fire = 1U;
    Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1db6__0(vlSelf, 
                                                              "@(posedge axi_write_owner_tb.ACLK)");
    co_await vlSelfRef.__VtrigSched_h3bfb1db6__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(posedge axi_write_owner_tb.ACLK)", 
                                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                                         43);
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                         43);
    axi_write_owner_tb__DOT__ownerless_seen = vlSelfRef.axi_write_owner_tb__DOT__w_without_owner_violation;
    axi_write_owner_tb__DOT__wlast_seen = vlSelfRef.axi_write_owner_tb__DOT__wlast_mismatch_violation;
    vlSelfRef.axi_write_owner_tb__DOT__w_fire = 0U;
    vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__23__message = "missing WLAST"s;
    __Vtask_axi_write_owner_tb__DOT__check__23__condition 
        = (((IData)(axi_write_owner_tb__DOT__wlast_seen) 
            & (IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q)) 
           & (1U == ((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__beats_q) 
                     & (- (IData)((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q))))));
    vlSelfRef.axi_write_owner_tb__DOT__checks = ((IData)(1U) 
                                                 + vlSelfRef.axi_write_owner_tb__DOT__checks);
    if (VL_UNLIKELY(((1U & (~ (IData)(__Vtask_axi_write_owner_tb__DOT__check__23__condition)))))) {
        VL_WRITEF_NX("FAIL %s\n[%0t] %%Fatal: axi_write_owner_tb.sv:27: Assertion failed in %m\n",4, 'M',vlSymsp->name(),"axi_write_owner_tb.check", 'T',-12
                     , 'S',&(vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__23__message)
                     , '#',64,VL_TIME_UNITED_Q(1));
        VL_STOP_MT("/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 27, "", false);
    }
    __Vtask_axi_write_owner_tb__DOT__wbeat__24__last = 1U;
    Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1e69__0(vlSelf, 
                                                              "@(negedge axi_write_owner_tb.ACLK)");
    co_await vlSelfRef.__VtrigSched_h3bfb1e69__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(negedge axi_write_owner_tb.ACLK)", 
                                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                                         42);
    vlSelfRef.axi_write_owner_tb__DOT__wlast = __Vtask_axi_write_owner_tb__DOT__wbeat__24__last;
    vlSelfRef.axi_write_owner_tb__DOT__w_fire = 1U;
    Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1db6__0(vlSelf, 
                                                              "@(posedge axi_write_owner_tb.ACLK)");
    co_await vlSelfRef.__VtrigSched_h3bfb1db6__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(posedge axi_write_owner_tb.ACLK)", 
                                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                                         43);
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                         43);
    axi_write_owner_tb__DOT__ownerless_seen = vlSelfRef.axi_write_owner_tb__DOT__w_without_owner_violation;
    axi_write_owner_tb__DOT__wlast_seen = vlSelfRef.axi_write_owner_tb__DOT__wlast_mismatch_violation;
    vlSelfRef.axi_write_owner_tb__DOT__w_fire = 0U;
    vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__25__message = "correct WLAST release"s;
    __Vtask_axi_write_owner_tb__DOT__check__25__condition 
        = ((~ (IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q)) 
           & (0U == ((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__beats_q) 
                     & (- (IData)((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q))))));
    vlSelfRef.axi_write_owner_tb__DOT__checks = ((IData)(1U) 
                                                 + vlSelfRef.axi_write_owner_tb__DOT__checks);
    if (VL_UNLIKELY(((1U & (~ (IData)(__Vtask_axi_write_owner_tb__DOT__check__25__condition)))))) {
        VL_WRITEF_NX("FAIL %s\n[%0t] %%Fatal: axi_write_owner_tb.sv:27: Assertion failed in %m\n",4, 'M',vlSymsp->name(),"axi_write_owner_tb.check", 'T',-12
                     , 'S',&(vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__25__message)
                     , '#',64,VL_TIME_UNITED_Q(1));
        VL_STOP_MT("/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 27, "", false);
    }
    __Vtask_axi_write_owner_tb__DOT__allocate__26__internal_id = 0x37U;
    __Vtask_axi_write_owner_tb__DOT__allocate__26__id = 7U;
    __Vtask_axi_write_owner_tb__DOT__allocate__26__target = 7U;
    __Vtask_axi_write_owner_tb__DOT__allocate__26__len = 1U;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_len 
        = __Vtask_axi_write_owner_tb__DOT__allocate__26__len;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_target 
        = __Vtask_axi_write_owner_tb__DOT__allocate__26__target;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_id 
        = __Vtask_axi_write_owner_tb__DOT__allocate__26__id;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_internal_id 
        = __Vtask_axi_write_owner_tb__DOT__allocate__26__internal_id;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_fire = 1U;
    Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1db6__0(vlSelf, 
                                                              "@(posedge axi_write_owner_tb.ACLK)");
    co_await vlSelfRef.__VtrigSched_h3bfb1db6__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(posedge axi_write_owner_tb.ACLK)", 
                                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                                         38);
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                         38);
    vlSelfRef.axi_write_owner_tb__DOT__allocate_fire = 0U;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_len = 0U;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_target = 0x0fU;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_id = 0x0fU;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_internal_id = 0x3fU;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_fire = 1U;
    Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1db6__0(vlSelf, 
                                                              "@(posedge axi_write_owner_tb.ACLK)");
    co_await vlSelfRef.__VtrigSched_h3bfb1db6__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(posedge axi_write_owner_tb.ACLK)", 
                                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                                         96);
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                         96);
    vlSelfRef.axi_write_owner_tb__DOT__allocate_fire = 0U;
    vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__27__message = "allocation while active"s;
    __Vtask_axi_write_owner_tb__DOT__check__27__condition 
        = (((IData)(vlSelfRef.axi_write_owner_tb__DOT__allocate_violation) 
            & (7U == ((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__target_q) 
                      & (- (IData)((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q)))))) 
           & (2U == ((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__beats_q) 
                     & (- (IData)((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q))))));
    vlSelfRef.axi_write_owner_tb__DOT__checks = ((IData)(1U) 
                                                 + vlSelfRef.axi_write_owner_tb__DOT__checks);
    if (VL_UNLIKELY(((1U & (~ (IData)(__Vtask_axi_write_owner_tb__DOT__check__27__condition)))))) {
        VL_WRITEF_NX("FAIL %s\n[%0t] %%Fatal: axi_write_owner_tb.sv:27: Assertion failed in %m\n",4, 'M',vlSymsp->name(),"axi_write_owner_tb.check", 'T',-12
                     , 'S',&(vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__27__message)
                     , '#',64,VL_TIME_UNITED_Q(1));
        VL_STOP_MT("/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 27, "", false);
    }
    __Vtask_axi_write_owner_tb__DOT__wbeat__28__last = 0U;
    Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1e69__0(vlSelf, 
                                                              "@(negedge axi_write_owner_tb.ACLK)");
    co_await vlSelfRef.__VtrigSched_h3bfb1e69__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(negedge axi_write_owner_tb.ACLK)", 
                                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                                         42);
    vlSelfRef.axi_write_owner_tb__DOT__wlast = __Vtask_axi_write_owner_tb__DOT__wbeat__28__last;
    vlSelfRef.axi_write_owner_tb__DOT__w_fire = 1U;
    Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1db6__0(vlSelf, 
                                                              "@(posedge axi_write_owner_tb.ACLK)");
    co_await vlSelfRef.__VtrigSched_h3bfb1db6__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(posedge axi_write_owner_tb.ACLK)", 
                                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                                         43);
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                         43);
    axi_write_owner_tb__DOT__ownerless_seen = vlSelfRef.axi_write_owner_tb__DOT__w_without_owner_violation;
    axi_write_owner_tb__DOT__wlast_seen = vlSelfRef.axi_write_owner_tb__DOT__wlast_mismatch_violation;
    vlSelfRef.axi_write_owner_tb__DOT__w_fire = 0U;
    __Vtask_axi_write_owner_tb__DOT__wbeat__29__last = 1U;
    Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1e69__0(vlSelf, 
                                                              "@(negedge axi_write_owner_tb.ACLK)");
    co_await vlSelfRef.__VtrigSched_h3bfb1e69__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(negedge axi_write_owner_tb.ACLK)", 
                                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                                         42);
    vlSelfRef.axi_write_owner_tb__DOT__wlast = __Vtask_axi_write_owner_tb__DOT__wbeat__29__last;
    vlSelfRef.axi_write_owner_tb__DOT__w_fire = 1U;
    Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1db6__0(vlSelf, 
                                                              "@(posedge axi_write_owner_tb.ACLK)");
    co_await vlSelfRef.__VtrigSched_h3bfb1db6__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(posedge axi_write_owner_tb.ACLK)", 
                                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                                         43);
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                         43);
    axi_write_owner_tb__DOT__ownerless_seen = vlSelfRef.axi_write_owner_tb__DOT__w_without_owner_violation;
    axi_write_owner_tb__DOT__wlast_seen = vlSelfRef.axi_write_owner_tb__DOT__wlast_mismatch_violation;
    vlSelfRef.axi_write_owner_tb__DOT__w_fire = 0U;
    vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__30__message = "second write release"s;
    __Vtask_axi_write_owner_tb__DOT__check__30__condition 
        = (1U & (~ (IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q)));
    vlSelfRef.axi_write_owner_tb__DOT__checks = ((IData)(1U) 
                                                 + vlSelfRef.axi_write_owner_tb__DOT__checks);
    if (VL_UNLIKELY(((1U & (~ (IData)(__Vtask_axi_write_owner_tb__DOT__check__30__condition)))))) {
        VL_WRITEF_NX("FAIL %s\n[%0t] %%Fatal: axi_write_owner_tb.sv:27: Assertion failed in %m\n",4, 'M',vlSymsp->name(),"axi_write_owner_tb.check", 'T',-12
                     , 'S',&(vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__30__message)
                     , '#',64,VL_TIME_UNITED_Q(1));
        VL_STOP_MT("/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 27, "", false);
    }
    __Vtask_axi_write_owner_tb__DOT__allocate__31__internal_id = 0x11U;
    __Vtask_axi_write_owner_tb__DOT__allocate__31__id = 1U;
    __Vtask_axi_write_owner_tb__DOT__allocate__31__target = 2U;
    __Vtask_axi_write_owner_tb__DOT__allocate__31__len = 0U;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_len 
        = __Vtask_axi_write_owner_tb__DOT__allocate__31__len;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_target 
        = __Vtask_axi_write_owner_tb__DOT__allocate__31__target;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_id 
        = __Vtask_axi_write_owner_tb__DOT__allocate__31__id;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_internal_id 
        = __Vtask_axi_write_owner_tb__DOT__allocate__31__internal_id;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_fire = 1U;
    Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1db6__0(vlSelf, 
                                                              "@(posedge axi_write_owner_tb.ACLK)");
    co_await vlSelfRef.__VtrigSched_h3bfb1db6__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(posedge axi_write_owner_tb.ACLK)", 
                                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                                         38);
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                         38);
    vlSelfRef.axi_write_owner_tb__DOT__allocate_fire = 0U;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_fire = 1U;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_target = 4U;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_id = 4U;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_internal_id = 0x24U;
    vlSelfRef.axi_write_owner_tb__DOT__w_fire = 1U;
    vlSelfRef.axi_write_owner_tb__DOT__wlast = 1U;
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                         105);
    axi_write_owner_tb__DOT__pre_violation = vlSelfRef.axi_write_owner_tb__DOT__allocate_violation;
    Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1db6__0(vlSelf, 
                                                              "@(posedge axi_write_owner_tb.ACLK)");
    co_await vlSelfRef.__VtrigSched_h3bfb1db6__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(posedge axi_write_owner_tb.ACLK)", 
                                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                                         106);
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                         106);
    vlSelfRef.axi_write_owner_tb__DOT__allocate_fire = 0U;
    vlSelfRef.axi_write_owner_tb__DOT__w_fire = 0U;
    vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__32__message = "same-cycle final/reallocation block"s;
    __Vtask_axi_write_owner_tb__DOT__check__32__condition 
        = ((~ (IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q)) 
           & (IData)(axi_write_owner_tb__DOT__pre_violation));
    vlSelfRef.axi_write_owner_tb__DOT__checks = ((IData)(1U) 
                                                 + vlSelfRef.axi_write_owner_tb__DOT__checks);
    if (VL_UNLIKELY(((1U & (~ (IData)(__Vtask_axi_write_owner_tb__DOT__check__32__condition)))))) {
        VL_WRITEF_NX("FAIL %s\n[%0t] %%Fatal: axi_write_owner_tb.sv:27: Assertion failed in %m\n",4, 'M',vlSymsp->name(),"axi_write_owner_tb.check", 'T',-12
                     , 'S',&(vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__32__message)
                     , '#',64,VL_TIME_UNITED_Q(1));
        VL_STOP_MT("/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 27, "", false);
    }
    Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1db6__0(vlSelf, 
                                                              "@(posedge axi_write_owner_tb.ACLK)");
    co_await vlSelfRef.__VtrigSched_h3bfb1db6__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(posedge axi_write_owner_tb.ACLK)", 
                                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                                         108);
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                         108);
    vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__33__message = "following-cycle allocation permitted"s;
    __Vtask_axi_write_owner_tb__DOT__check__33__condition 
        = vlSelfRef.axi_write_owner_tb__DOT__allocate_allowed;
    vlSelfRef.axi_write_owner_tb__DOT__checks = ((IData)(1U) 
                                                 + vlSelfRef.axi_write_owner_tb__DOT__checks);
    if (VL_UNLIKELY(((1U & (~ (IData)(__Vtask_axi_write_owner_tb__DOT__check__33__condition)))))) {
        VL_WRITEF_NX("FAIL %s\n[%0t] %%Fatal: axi_write_owner_tb.sv:27: Assertion failed in %m\n",4, 'M',vlSymsp->name(),"axi_write_owner_tb.check", 'T',-12
                     , 'S',&(vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__33__message)
                     , '#',64,VL_TIME_UNITED_Q(1));
        VL_STOP_MT("/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 27, "", false);
    }
    vlSelfRef.axi_write_owner_tb__DOT__allocate_len = 0U;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_target = 4U;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_id = 4U;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_internal_id = 0x24U;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_fire = 1U;
    Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1db6__0(vlSelf, 
                                                              "@(posedge axi_write_owner_tb.ACLK)");
    co_await vlSelfRef.__VtrigSched_h3bfb1db6__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(posedge axi_write_owner_tb.ACLK)", 
                                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                                         111);
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                         111);
    vlSelfRef.axi_write_owner_tb__DOT__allocate_fire = 0U;
    vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__34__message = "following-cycle reallocation"s;
    __Vtask_axi_write_owner_tb__DOT__check__34__condition 
        = ((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q) 
           & (4U == ((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__target_q) 
                     & (- (IData)((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q))))));
    vlSelfRef.axi_write_owner_tb__DOT__checks = ((IData)(1U) 
                                                 + vlSelfRef.axi_write_owner_tb__DOT__checks);
    if (VL_UNLIKELY(((1U & (~ (IData)(__Vtask_axi_write_owner_tb__DOT__check__34__condition)))))) {
        VL_WRITEF_NX("FAIL %s\n[%0t] %%Fatal: axi_write_owner_tb.sv:27: Assertion failed in %m\n",4, 'M',vlSymsp->name(),"axi_write_owner_tb.check", 'T',-12
                     , 'S',&(vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__34__message)
                     , '#',64,VL_TIME_UNITED_Q(1));
        VL_STOP_MT("/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 27, "", false);
    }
    __Vtask_axi_write_owner_tb__DOT__wbeat__35__last = 1U;
    Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1e69__0(vlSelf, 
                                                              "@(negedge axi_write_owner_tb.ACLK)");
    co_await vlSelfRef.__VtrigSched_h3bfb1e69__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(negedge axi_write_owner_tb.ACLK)", 
                                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                                         42);
    vlSelfRef.axi_write_owner_tb__DOT__wlast = __Vtask_axi_write_owner_tb__DOT__wbeat__35__last;
    vlSelfRef.axi_write_owner_tb__DOT__w_fire = 1U;
    Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1db6__0(vlSelf, 
                                                              "@(posedge axi_write_owner_tb.ACLK)");
    co_await vlSelfRef.__VtrigSched_h3bfb1db6__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(posedge axi_write_owner_tb.ACLK)", 
                                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                                         43);
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                         43);
    axi_write_owner_tb__DOT__ownerless_seen = vlSelfRef.axi_write_owner_tb__DOT__w_without_owner_violation;
    axi_write_owner_tb__DOT__wlast_seen = vlSelfRef.axi_write_owner_tb__DOT__wlast_mismatch_violation;
    vlSelfRef.axi_write_owner_tb__DOT__w_fire = 0U;
    __Vtask_axi_write_owner_tb__DOT__allocate__36__internal_id = 0x29U;
    __Vtask_axi_write_owner_tb__DOT__allocate__36__id = 9U;
    __Vtask_axi_write_owner_tb__DOT__allocate__36__target = 9U;
    __Vtask_axi_write_owner_tb__DOT__allocate__36__len = 0x0fU;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_len 
        = __Vtask_axi_write_owner_tb__DOT__allocate__36__len;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_target 
        = __Vtask_axi_write_owner_tb__DOT__allocate__36__target;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_id 
        = __Vtask_axi_write_owner_tb__DOT__allocate__36__id;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_internal_id 
        = __Vtask_axi_write_owner_tb__DOT__allocate__36__internal_id;
    vlSelfRef.axi_write_owner_tb__DOT__allocate_fire = 1U;
    Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1db6__0(vlSelf, 
                                                              "@(posedge axi_write_owner_tb.ACLK)");
    co_await vlSelfRef.__VtrigSched_h3bfb1db6__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(posedge axi_write_owner_tb.ACLK)", 
                                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                                         38);
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                         38);
    vlSelfRef.axi_write_owner_tb__DOT__allocate_fire = 0U;
    vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__37__message = "sixteen-beat allocation"s;
    __Vtask_axi_write_owner_tb__DOT__check__37__condition 
        = ((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q) 
           & (0x10U == ((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__beats_q) 
                        & (- (IData)((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q))))));
    vlSelfRef.axi_write_owner_tb__DOT__checks = ((IData)(1U) 
                                                 + vlSelfRef.axi_write_owner_tb__DOT__checks);
    if (VL_UNLIKELY(((1U & (~ (IData)(__Vtask_axi_write_owner_tb__DOT__check__37__condition)))))) {
        VL_WRITEF_NX("FAIL %s\n[%0t] %%Fatal: axi_write_owner_tb.sv:27: Assertion failed in %m\n",4, 'M',vlSymsp->name(),"axi_write_owner_tb.check", 'T',-12
                     , 'S',&(vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__37__message)
                     , '#',64,VL_TIME_UNITED_Q(1));
        VL_STOP_MT("/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 27, "", false);
    }
    vlSelfRef.axi_write_owner_tb__DOT__ARESETn = 0U;
    co_await vlSelfRef.__VdlySched.delay(1ULL, nullptr, 
                                         "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                         118);
    vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__38__message = "reset while active"s;
    __Vtask_axi_write_owner_tb__DOT__check__38__condition 
        = (((~ (IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q)) 
            & (0U == ((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__beats_q) 
                      & (- (IData)((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q)))))) 
           & (0U == ((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__target_q) 
                     & (- (IData)((IData)(vlSelfRef.axi_write_owner_tb__DOT__dut__DOT__active_q))))));
    vlSelfRef.axi_write_owner_tb__DOT__checks = ((IData)(1U) 
                                                 + vlSelfRef.axi_write_owner_tb__DOT__checks);
    if (VL_UNLIKELY(((1U & (~ (IData)(__Vtask_axi_write_owner_tb__DOT__check__38__condition)))))) {
        VL_WRITEF_NX("FAIL %s\n[%0t] %%Fatal: axi_write_owner_tb.sv:27: Assertion failed in %m\n",4, 'M',vlSymsp->name(),"axi_write_owner_tb.check", 'T',-12
                     , 'S',&(vlSelfRef.__Vtask_axi_write_owner_tb__DOT__check__38__message)
                     , '#',64,VL_TIME_UNITED_Q(1));
        VL_STOP_MT("/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 27, "", false);
    }
    vlSelfRef.axi_write_owner_tb__DOT__ARESETn = 1U;
    VL_WRITEF_NX("PASS axi_write_owner_tb checks=%0d\n",1
                 , '~',32,vlSelfRef.axi_write_owner_tb__DOT__checks);
    VL_FINISH_MT("/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 123, "");
    co_return;
}

VlCoroutine Vaxi_write_owner_tb___024root___eval_initial__TOP__Vtiming__1(Vaxi_write_owner_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_tb___024root___eval_initial__TOP__Vtiming__1\n"); );
    Vaxi_write_owner_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    while (VL_LIKELY(!vlSymsp->_vm_contextp__->gotFinish())) {
        co_await vlSelfRef.__VdlySched.delay(5ULL, 
                                             nullptr, 
                                             "/Users/Dilan/Projects/fabric-under-pressure/tb/directed/axi_write_owner_tb.sv", 
                                             4);
        vlSelfRef.axi_write_owner_tb__DOT__ACLK = (1U 
                                                   & (~ (IData)(vlSelfRef.axi_write_owner_tb__DOT__ACLK)));
    }
    co_return;
}

bool Vaxi_write_owner_tb___024root___trigger_anySet__ico(const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_tb___024root___trigger_anySet__ico\n"); );
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

bool Vaxi_write_owner_tb___024root___trigger_anySet__act(const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_tb___024root___trigger_anySet__act\n"); );
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

void Vaxi_write_owner_tb___024root___timing_ready(Vaxi_write_owner_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_tb___024root___timing_ready\n"); );
    Vaxi_write_owner_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((8ULL & vlSelfRef.__VactTriggered[0U])) {
        vlSelfRef.__VtrigSched_h3bfb1e69__0.ready("@(negedge axi_write_owner_tb.ACLK)");
    }
    if ((1ULL & vlSelfRef.__VactTriggered[0U])) {
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready("@(posedge axi_write_owner_tb.ACLK)");
    }
}

void Vaxi_write_owner_tb___024root___timing_resume(Vaxi_write_owner_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_tb___024root___timing_resume\n"); );
    Vaxi_write_owner_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VtrigSched_h3bfb1e69__0.moveToResumeQueue(
                                                          "@(negedge axi_write_owner_tb.ACLK)");
    vlSelfRef.__VtrigSched_h3bfb1db6__0.moveToResumeQueue(
                                                          "@(posedge axi_write_owner_tb.ACLK)");
    vlSelfRef.__VtrigSched_h3bfb1e69__0.resume("@(negedge axi_write_owner_tb.ACLK)");
    vlSelfRef.__VtrigSched_h3bfb1db6__0.resume("@(posedge axi_write_owner_tb.ACLK)");
    if ((4ULL & vlSelfRef.__VactTriggered[0U])) {
        vlSelfRef.__VdlySched.resume();
    }
}

void Vaxi_write_owner_tb___024root___trigger_orInto__act_vec_vec(VlUnpacked<QData/*63:0*/, 1> &out, const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_tb___024root___trigger_orInto__act_vec_vec\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        out[n] = (out[n] | in[n]);
        n = ((IData)(1U) + n);
    } while ((0U >= n));
}

void Vaxi_write_owner_tb___024root___trigger_clear__act(VlUnpacked<QData/*63:0*/, 1> &out) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_tb___024root___trigger_clear__act\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        out[n] = 0ULL;
        n = ((IData)(1U) + n);
    } while ((1U > n));
}

void Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1e69__0(Vaxi_write_owner_tb___024root* vlSelf, const char* __VeventDescription) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1e69__0\n"); );
    Vaxi_write_owner_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    VlUnpacked<QData/*63:0*/, 1> __VTmp;
    // Body
    __VTmp[0U] = (QData)((IData)(((((~ (IData)(vlSelfRef.axi_write_owner_tb__DOT__ACLK)) 
                                    & (IData)(vlSelfRef.__Vtrigprevexpr___TOP__axi_write_owner_tb__DOT__ACLK__0)) 
                                   << 3U) | ((IData)(vlSelfRef.axi_write_owner_tb__DOT__ACLK) 
                                             & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__axi_write_owner_tb__DOT__ACLK__0))))));
    vlSelfRef.__Vtrigprevexpr___TOP__axi_write_owner_tb__DOT__ACLK__0 
        = vlSelfRef.axi_write_owner_tb__DOT__ACLK;
    if ((1ULL & __VTmp[0U])) {
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
    }
    if ((8ULL & __VTmp[0U])) {
        vlSelfRef.__VtrigSched_h3bfb1e69__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1e69__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1e69__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1e69__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1e69__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1e69__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1e69__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1e69__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1e69__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1e69__0.ready(__VeventDescription);
    }
    vlSelfRef.__VactTriggeredAcc[0U] = (vlSelfRef.__VactTriggeredAcc[0U] 
                                        | __VTmp[0U]);
}

void Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1db6__0(Vaxi_write_owner_tb___024root* vlSelf, const char* __VeventDescription) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_tb___024root____VbeforeTrig_h3bfb1db6__0\n"); );
    Vaxi_write_owner_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    VlUnpacked<QData/*63:0*/, 1> __VTmp;
    // Body
    __VTmp[0U] = (QData)((IData)(((((~ (IData)(vlSelfRef.axi_write_owner_tb__DOT__ACLK)) 
                                    & (IData)(vlSelfRef.__Vtrigprevexpr___TOP__axi_write_owner_tb__DOT__ACLK__0)) 
                                   << 3U) | ((IData)(vlSelfRef.axi_write_owner_tb__DOT__ACLK) 
                                             & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__axi_write_owner_tb__DOT__ACLK__0))))));
    vlSelfRef.__Vtrigprevexpr___TOP__axi_write_owner_tb__DOT__ACLK__0 
        = vlSelfRef.axi_write_owner_tb__DOT__ACLK;
    if ((1ULL & __VTmp[0U])) {
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1db6__0.ready(__VeventDescription);
    }
    if ((8ULL & __VTmp[0U])) {
        vlSelfRef.__VtrigSched_h3bfb1e69__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1e69__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1e69__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1e69__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1e69__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1e69__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1e69__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1e69__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1e69__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h3bfb1e69__0.ready(__VeventDescription);
    }
    vlSelfRef.__VactTriggeredAcc[0U] = (vlSelfRef.__VactTriggeredAcc[0U] 
                                        | __VTmp[0U]);
}

#ifdef VL_DEBUG
void Vaxi_write_owner_tb___024root___eval_debug_assertions(Vaxi_write_owner_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_tb___024root___eval_debug_assertions\n"); );
    Vaxi_write_owner_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}
#endif  // VL_DEBUG
