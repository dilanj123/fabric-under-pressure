// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vaxi_write_owner_3_tb.h for the primary calling header

#include "Vaxi_write_owner_3_tb__pch.h"

void Vaxi_write_owner_3_tb___024root___ctor_var_reset(Vaxi_write_owner_3_tb___024root* vlSelf);

Vaxi_write_owner_3_tb___024root::Vaxi_write_owner_3_tb___024root(Vaxi_write_owner_3_tb__Syms* symsp, const char* namep)
    : __VdlySched{*symsp->_vm_contextp__}
 {
    vlSymsp = symsp;
    vlNamep = strdup(namep);
    // Reset structure values
    Vaxi_write_owner_3_tb___024root___ctor_var_reset(this);
}

Vaxi_write_owner_3_tb___024root::~Vaxi_write_owner_3_tb___024root() {
    VL_DO_DANGLING(std::free(const_cast<char*>(vlNamep)), vlNamep);
}
