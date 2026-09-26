// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vaxi_write_owner_3_tb.h for the primary calling header

#include "Vaxi_write_owner_3_tb__pch.h"

void Vaxi_write_owner_3_tb___024root___timing_ready(Vaxi_write_owner_3_tb___024root* vlSelf);

VL_ATTR_COLD void Vaxi_write_owner_3_tb___024root___eval_static(Vaxi_write_owner_3_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_3_tb___024root___eval_static\n"); );
    Vaxi_write_owner_3_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    {
        // Inlined CFunc: _eval_static__TOP
        vlSelfRef.axi_write_owner_3_tb__DOT__ACLK = 0U;
        vlSelfRef.axi_write_owner_3_tb__DOT__ARESETn = 0U;
        vlSelfRef.axi_write_owner_3_tb__DOT__checks = 0U;
    }
    vlSelfRef.__Vtrigprevexpr___TOP__axi_write_owner_3_tb__DOT__ACLK__0 = 0U;
    vlSelfRef.__Vtrigprevexpr___TOP__axi_write_owner_3_tb__DOT__ARESETn__0 = 0U;
    Vaxi_write_owner_3_tb___024root___timing_ready(vlSelf);
    do {
        vlSelfRef.__VactTriggeredAcc[vlSelfRef.__Vi] 
            = vlSelfRef.__VactTriggered[vlSelfRef.__Vi];
        vlSelfRef.__Vi = ((IData)(1U) + vlSelfRef.__Vi);
    } while ((0U >= vlSelfRef.__Vi));
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vaxi_write_owner_3_tb___024root___dump_triggers__stl(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag);
#endif  // VL_DEBUG

VL_ATTR_COLD bool Vaxi_write_owner_3_tb___024root___eval_stl(Vaxi_write_owner_3_tb___024root* vlSelf, CData/*0:0*/ firstIteration) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_3_tb___024root___eval_stl\n"); );
    Vaxi_write_owner_3_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VstlTriggered[0U] = ((0xfffffffffffffffeULL 
                                      & vlSelfRef.__VstlTriggered[0U]) 
                                     | (IData)((IData)(firstIteration)));
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vaxi_write_owner_3_tb___024root___dump_triggers__stl(vlSelfRef.__VstlTriggered, "stl"s);
    }
#endif
    return (0U);
}

VL_ATTR_COLD void Vaxi_write_owner_3_tb___024root___eval_dump_triggers__stl(Vaxi_write_owner_3_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_3_tb___024root___eval_dump_triggers__stl\n"); );
    Vaxi_write_owner_3_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
#ifdef VL_DEBUG
    Vaxi_write_owner_3_tb___024root___dump_triggers__stl(vlSelfRef.__VstlTriggered, "stl"s);
#endif
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vaxi_write_owner_3_tb___024root___dump_triggers__ico(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag);
#endif  // VL_DEBUG

VL_ATTR_COLD void Vaxi_write_owner_3_tb___024root___eval_dump_triggers__ico(Vaxi_write_owner_3_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_3_tb___024root___eval_dump_triggers__ico\n"); );
    Vaxi_write_owner_3_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
#ifdef VL_DEBUG
    Vaxi_write_owner_3_tb___024root___dump_triggers__ico(vlSelfRef.__VicoTriggered, "ico"s);
#endif
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vaxi_write_owner_3_tb___024root___dump_triggers__act(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag);
#endif  // VL_DEBUG

VL_ATTR_COLD void Vaxi_write_owner_3_tb___024root___eval_dump_triggers__act(Vaxi_write_owner_3_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_3_tb___024root___eval_dump_triggers__act\n"); );
    Vaxi_write_owner_3_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
#ifdef VL_DEBUG
    Vaxi_write_owner_3_tb___024root___dump_triggers__act(vlSelfRef.__VactTriggered, "act"s);
#endif
}

VL_ATTR_COLD void Vaxi_write_owner_3_tb___024root___eval_dump_triggers__nba(Vaxi_write_owner_3_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_3_tb___024root___eval_dump_triggers__nba\n"); );
    Vaxi_write_owner_3_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
#ifdef VL_DEBUG
    Vaxi_write_owner_3_tb___024root___dump_triggers__act(vlSelfRef.__VnbaTriggered, "nba"s);
#endif
}

VL_ATTR_COLD void Vaxi_write_owner_3_tb___024root___eval_dump_triggers__obs(Vaxi_write_owner_3_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_3_tb___024root___eval_dump_triggers__obs\n"); );
    Vaxi_write_owner_3_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

VL_ATTR_COLD void Vaxi_write_owner_3_tb___024root___eval_dump_triggers__react(Vaxi_write_owner_3_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_3_tb___024root___eval_dump_triggers__react\n"); );
    Vaxi_write_owner_3_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

VL_ATTR_COLD void Vaxi_write_owner_3_tb___024root___eval_final(Vaxi_write_owner_3_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_3_tb___024root___eval_final\n"); );
    Vaxi_write_owner_3_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

VL_ATTR_COLD bool Vaxi_write_owner_3_tb___024root___trigger_anySet__stl(const VlUnpacked<QData/*63:0*/, 1> &in);

#ifdef VL_DEBUG
VL_ATTR_COLD void Vaxi_write_owner_3_tb___024root___dump_triggers__stl(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_3_tb___024root___dump_triggers__stl\n"); );
    // Body
    if ((1U & (~ (IData)(Vaxi_write_owner_3_tb___024root___trigger_anySet__stl(triggers))))) {
        VL_DBG_MSGS("         No '" + tag + "' region triggers active\n");
    }
    if ((1U & (IData)(triggers[0U]))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 0 is active: Internal 'stl' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD bool Vaxi_write_owner_3_tb___024root___trigger_anySet__stl(const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_3_tb___024root___trigger_anySet__stl\n"); );
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

bool Vaxi_write_owner_3_tb___024root___trigger_anySet__ico(const VlUnpacked<QData/*63:0*/, 1> &in);

#ifdef VL_DEBUG
VL_ATTR_COLD void Vaxi_write_owner_3_tb___024root___dump_triggers__ico(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_3_tb___024root___dump_triggers__ico\n"); );
    // Body
    if ((1U & (~ (IData)(Vaxi_write_owner_3_tb___024root___trigger_anySet__ico(triggers))))) {
        VL_DBG_MSGS("         No '" + tag + "' region triggers active\n");
    }
    if ((1U & (IData)(triggers[0U]))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 0 is active: Internal 'ico' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

bool Vaxi_write_owner_3_tb___024root___trigger_anySet__act(const VlUnpacked<QData/*63:0*/, 1> &in);

#ifdef VL_DEBUG
VL_ATTR_COLD void Vaxi_write_owner_3_tb___024root___dump_triggers__act(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_3_tb___024root___dump_triggers__act\n"); );
    // Body
    if ((1U & (~ (IData)(Vaxi_write_owner_3_tb___024root___trigger_anySet__act(triggers))))) {
        VL_DBG_MSGS("         No '" + tag + "' region triggers active\n");
    }
    if ((1U & (IData)(triggers[0U]))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 0 is active: @(posedge axi_write_owner_3_tb.ACLK)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 1U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 1 is active: @(negedge axi_write_owner_3_tb.ARESETn)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 2U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 2 is active: @([true] __VdlySched.awaitingCurrentTime())\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vaxi_write_owner_3_tb___024root___ctor_var_reset(Vaxi_write_owner_3_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vaxi_write_owner_3_tb___024root___ctor_var_reset\n"); );
    Vaxi_write_owner_3_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    const uint64_t __VscopeHash = VL_MURMUR64_HASH(vlSelf->vlNamep);
    vlSelf->axi_write_owner_3_tb__DOT__allocate_fire = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 15505007614640984086ull);
    vlSelf->axi_write_owner_3_tb__DOT__w_fire = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 5962991404539818281ull);
    vlSelf->axi_write_owner_3_tb__DOT__wlast = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 18337641787562059427ull);
    vlSelf->axi_write_owner_3_tb__DOT__allocate_len = VL_SCOPED_RAND_RESET_I(24, __VscopeHash, 6068854359361069007ull);
    vlSelf->axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__active_q = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 597139972035638068ull);
    vlSelf->axi_write_owner_3_tb__DOT__managers__BRA__2__KET____DOT__dut__DOT__beats_q = VL_SCOPED_RAND_RESET_I(5, __VscopeHash, 1208105531780834679ull);
    vlSelf->axi_write_owner_3_tb__DOT__managers__BRA__1__KET____DOT__dut__DOT__active_q = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2815781191495181152ull);
    vlSelf->axi_write_owner_3_tb__DOT__managers__BRA__1__KET____DOT__dut__DOT__beats_q = VL_SCOPED_RAND_RESET_I(5, __VscopeHash, 1366431227011175633ull);
    vlSelf->axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__active_q = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 18243382043006255695ull);
    vlSelf->axi_write_owner_3_tb__DOT__managers__BRA__0__KET____DOT__dut__DOT__beats_q = VL_SCOPED_RAND_RESET_I(5, __VscopeHash, 8124568444984648497ull);
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VstlTriggered[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VicoTriggered[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VactTriggered[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VactTriggeredAcc[__Vi0] = 0;
    }
    vlSelf->__Vtrigprevexpr___TOP__axi_write_owner_3_tb__DOT__ACLK__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__axi_write_owner_3_tb__DOT__ARESETn__0 = 0;
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VnbaTriggered[__Vi0] = 0;
    }
    vlSelf->__Vi = 0;
}
