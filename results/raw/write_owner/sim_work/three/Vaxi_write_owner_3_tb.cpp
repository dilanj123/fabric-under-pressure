// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vaxi_write_owner_3_tb__pch.h"

//============================================================
// Constructors

Vaxi_write_owner_3_tb::Vaxi_write_owner_3_tb(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vaxi_write_owner_3_tb__Syms(contextp(), _vcname__, this)}
    , m_evalLoop{*this, /*convergeLimit:*/ 10000}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Vaxi_write_owner_3_tb::Vaxi_write_owner_3_tb(const char* _vcname__)
    : Vaxi_write_owner_3_tb(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vaxi_write_owner_3_tb::~Vaxi_write_owner_3_tb() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vaxi_write_owner_3_tb___024root___eval_debug_assertions(Vaxi_write_owner_3_tb___024root* vlSelf);
#endif  // VL_DEBUG
VL_ATTR_COLD void Vaxi_write_owner_3_tb___024root___eval_static(Vaxi_write_owner_3_tb___024root* vlSelf);
void Vaxi_write_owner_3_tb___024root___eval_initial(Vaxi_write_owner_3_tb___024root* vlSelf);
VL_ATTR_COLD bool Vaxi_write_owner_3_tb___024root___eval_stl(Vaxi_write_owner_3_tb___024root* vlSelf, CData/*0:0*/ firstIteration);
void Vaxi_write_owner_3_tb___024root___eval_sample(Vaxi_write_owner_3_tb___024root* vlSelf);
bool Vaxi_write_owner_3_tb___024root___eval_ico(Vaxi_write_owner_3_tb___024root* vlSelf, CData/*0:0*/ firstIteration);
bool Vaxi_write_owner_3_tb___024root___eval_act(Vaxi_write_owner_3_tb___024root* vlSelf);
bool Vaxi_write_owner_3_tb___024root___eval_inact(Vaxi_write_owner_3_tb___024root* vlSelf);
bool Vaxi_write_owner_3_tb___024root___eval_nba(Vaxi_write_owner_3_tb___024root* vlSelf);
bool Vaxi_write_owner_3_tb___024root___eval_obs(Vaxi_write_owner_3_tb___024root* vlSelf);
bool Vaxi_write_owner_3_tb___024root___eval_react(Vaxi_write_owner_3_tb___024root* vlSelf);
void Vaxi_write_owner_3_tb___024root___eval_postponed(Vaxi_write_owner_3_tb___024root* vlSelf);
VL_ATTR_COLD void Vaxi_write_owner_3_tb___024root___eval_final(Vaxi_write_owner_3_tb___024root* vlSelf);
VL_ATTR_COLD void Vaxi_write_owner_3_tb___024root___eval_dump_triggers__stl(Vaxi_write_owner_3_tb___024root* vlSelf);
VL_ATTR_COLD void Vaxi_write_owner_3_tb___024root___eval_dump_triggers__ico(Vaxi_write_owner_3_tb___024root* vlSelf);
VL_ATTR_COLD void Vaxi_write_owner_3_tb___024root___eval_dump_triggers__act(Vaxi_write_owner_3_tb___024root* vlSelf);
VL_ATTR_COLD void Vaxi_write_owner_3_tb___024root___eval_dump_triggers__nba(Vaxi_write_owner_3_tb___024root* vlSelf);
VL_ATTR_COLD void Vaxi_write_owner_3_tb___024root___eval_dump_triggers__obs(Vaxi_write_owner_3_tb___024root* vlSelf);
VL_ATTR_COLD void Vaxi_write_owner_3_tb___024root___eval_dump_triggers__react(Vaxi_write_owner_3_tb___024root* vlSelf);

void Vaxi_write_owner_3_tb::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vaxi_write_owner_3_tb::eval_step\n"); );
    m_evalLoop.eval();
}

void Vaxi_write_owner_3_tb::evalBegin() {
#ifdef VL_DEBUG
    // Debug assertions
    Vaxi_write_owner_3_tb___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
}

void Vaxi_write_owner_3_tb::evalEnd() {
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
    vlSymsp->TOP.__VdlySched.cleanupForevered();
}

void Vaxi_write_owner_3_tb::evalStatic() {
    Vaxi_write_owner_3_tb___024root___eval_static(&(vlSymsp->TOP));
}

void Vaxi_write_owner_3_tb::evalInitial() {
    Vaxi_write_owner_3_tb___024root___eval_initial(&(vlSymsp->TOP));
}

bool Vaxi_write_owner_3_tb::evalStl(bool firstIteration) {
    return Vaxi_write_owner_3_tb___024root___eval_stl(&(vlSymsp->TOP), firstIteration);
}

void Vaxi_write_owner_3_tb::evalSample() {
    Vaxi_write_owner_3_tb___024root___eval_sample(&(vlSymsp->TOP));
}

bool Vaxi_write_owner_3_tb::evalIco(bool firstIteration) {
    return Vaxi_write_owner_3_tb___024root___eval_ico(&(vlSymsp->TOP), firstIteration);
}

bool Vaxi_write_owner_3_tb::evalAct() {
    return Vaxi_write_owner_3_tb___024root___eval_act(&(vlSymsp->TOP));
}

bool Vaxi_write_owner_3_tb::evalInact() {
    return Vaxi_write_owner_3_tb___024root___eval_inact(&(vlSymsp->TOP));
}

bool Vaxi_write_owner_3_tb::evalNba() {
    return Vaxi_write_owner_3_tb___024root___eval_nba(&(vlSymsp->TOP));
}

bool Vaxi_write_owner_3_tb::evalObs() {
    return Vaxi_write_owner_3_tb___024root___eval_obs(&(vlSymsp->TOP));
}

bool Vaxi_write_owner_3_tb::evalReact() {
    return Vaxi_write_owner_3_tb___024root___eval_react(&(vlSymsp->TOP));
}

void Vaxi_write_owner_3_tb::evalPostponed() {
    Vaxi_write_owner_3_tb___024root___eval_postponed(&(vlSymsp->TOP));
}

void Vaxi_write_owner_3_tb::evalFinal() {
    Vaxi_write_owner_3_tb___024root___eval_final(&(vlSymsp->TOP));
}

VL_ATTR_COLD void Vaxi_write_owner_3_tb::dumpTriggersStl() {
    Vaxi_write_owner_3_tb___024root___eval_dump_triggers__stl(&(vlSymsp->TOP));
}

VL_ATTR_COLD void Vaxi_write_owner_3_tb::dumpTriggersIco() {
    Vaxi_write_owner_3_tb___024root___eval_dump_triggers__ico(&(vlSymsp->TOP));
}

VL_ATTR_COLD void Vaxi_write_owner_3_tb::dumpTriggersAct() {
    Vaxi_write_owner_3_tb___024root___eval_dump_triggers__act(&(vlSymsp->TOP));
}

VL_ATTR_COLD void Vaxi_write_owner_3_tb::dumpTriggersNba() {
    Vaxi_write_owner_3_tb___024root___eval_dump_triggers__nba(&(vlSymsp->TOP));
}

VL_ATTR_COLD void Vaxi_write_owner_3_tb::dumpTriggersObs() {
    Vaxi_write_owner_3_tb___024root___eval_dump_triggers__obs(&(vlSymsp->TOP));
}

VL_ATTR_COLD void Vaxi_write_owner_3_tb::dumpTriggersReact() {
    Vaxi_write_owner_3_tb___024root___eval_dump_triggers__react(&(vlSymsp->TOP));
}

//============================================================
// Events and timing
bool Vaxi_write_owner_3_tb::eventsPending() { return !vlSymsp->TOP.__VdlySched.empty() && !contextp()->gotFinish(); }

uint64_t Vaxi_write_owner_3_tb::nextTimeSlot() { return vlSymsp->TOP.__VdlySched.nextTimeSlot(); }

//============================================================
// Utilities

const char* Vaxi_write_owner_3_tb::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

VL_ATTR_COLD void Vaxi_write_owner_3_tb::final() {
    contextp()->executingFinal(true);
    evalFinal();
    contextp()->executingFinal(false);
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vaxi_write_owner_3_tb::hierName() const { return vlSymsp->name(); }
const char* Vaxi_write_owner_3_tb::modelName() const { return "Vaxi_write_owner_3_tb"; }
unsigned Vaxi_write_owner_3_tb::threads() const { return 1; }
void Vaxi_write_owner_3_tb::prepareClone() const { contextp()->prepareClone(); }
void Vaxi_write_owner_3_tb::atClone() const {
    contextp()->threadPoolpOnClone();
}
