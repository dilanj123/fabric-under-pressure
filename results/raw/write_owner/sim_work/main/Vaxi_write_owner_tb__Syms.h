// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VAXI_WRITE_OWNER_TB__SYMS_H_
#define VERILATED_VAXI_WRITE_OWNER_TB__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "Vaxi_write_owner_tb.h"

// INCLUDE MODULE CLASSES
#include "Vaxi_write_owner_tb___024root.h"

// SYMS CLASS (contains all model state)
class alignas(VL_CACHE_LINE_BYTES) Vaxi_write_owner_tb__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    Vaxi_write_owner_tb* const __Vm_modelp;
    VlDeleter __Vm_deleter;
    bool& __Vm_didInit;

    // MODULE INSTANCE STATE
    Vaxi_write_owner_tb___024root  TOP;

    // CONSTRUCTORS
    Vaxi_write_owner_tb__Syms(VerilatedContext* contextp, const char* namep, Vaxi_write_owner_tb* modelp);
    ~Vaxi_write_owner_tb__Syms();

    // METHODS
    const char* name() const { return TOP.vlNamep; }
};

#endif  // guard
