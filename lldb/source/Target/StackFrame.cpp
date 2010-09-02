//===-- StackFrame.cpp ------------------------------------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "lldb/Target/StackFrame.h"

// C Includes
// C++ Includes
// Other libraries and framework includes
// Project includes
#include "lldb/Core/Module.h"
#include "lldb/Core/Disassembler.h"
#include "lldb/Core/Value.h"
#include "lldb/Core/ValueObjectVariable.h"
#include "lldb/Symbol/Function.h"
#include "lldb/Symbol/VariableList.h"
#include "lldb/Target/ExecutionContext.h"
#include "lldb/Target/Process.h"
#include "lldb/Target/RegisterContext.h"
#include "lldb/Target/Target.h"
#include "lldb/Target/Thread.h"

using namespace lldb;
using namespace lldb_private;

// The first bits in the flags are reserved for the SymbolContext::Scope bits
// so we know if we have tried to look up information in our internal symbol
// context (m_sc) already.
#define RESOLVED_FRAME_CODE_ADDR        (uint32_t(eSymbolContextEverything + 1))
#define RESOLVED_FRAME_ID_SYMBOL_SCOPE  (RESOLVED_FRAME_CODE_ADDR << 1)
#define GOT_FRAME_BASE                  (RESOLVED_FRAME_ID_SYMBOL_SCOPE << 1)
#define RESOLVED_VARIABLES              (GOT_FRAME_BASE << 1)

StackFrame::StackFrame 
(
    lldb::user_id_t frame_idx, 
    lldb::user_id_t unwind_frame_index, 
    Thread &thread, 
    lldb::addr_t cfa, 
    lldb::addr_t pc, 
    const SymbolContext *sc_ptr
) :
    m_frame_index (frame_idx),
    m_unwind_frame_index (unwind_frame_index),    
    m_thread (thread),
    m_reg_context_sp (),
    m_id (pc, cfa, NULL),
    m_frame_code_addr (NULL, pc),
    m_sc (),
    m_flags (),
    m_frame_base (),
    m_frame_base_error (),
    m_variable_list_sp (),
    m_variable_list_value_objects ()
{
    if (sc_ptr != NULL)
    {
        m_sc = *sc_ptr;
        m_flags.Set(m_sc.GetResolvedMask ());
    }
}

StackFrame::StackFrame 
(
    lldb::user_id_t frame_idx, 
    lldb::user_id_t unwind_frame_index, 
    Thread &thread, 
    const RegisterContextSP &reg_context_sp, 
    lldb::addr_t cfa, 
    lldb::addr_t pc, 
    const SymbolContext *sc_ptr
) :
    m_frame_index (frame_idx),
    m_unwind_frame_index (unwind_frame_index),    
    m_thread (thread),
    m_reg_context_sp (reg_context_sp),
    m_id (pc, cfa, NULL),
    m_frame_code_addr (NULL, pc),
    m_sc (),
    m_flags (),
    m_frame_base (),
    m_frame_base_error (),
    m_variable_list_sp (),
    m_variable_list_value_objects ()
{
    if (sc_ptr != NULL)
    {
        m_sc = *sc_ptr;
        m_flags.Set(m_sc.GetResolvedMask ());
    }
    
    if (reg_context_sp && !m_sc.target_sp)
    {
        m_sc.target_sp = reg_context_sp->GetThread().GetProcess().GetTarget().GetSP();
        m_flags.Set (eSymbolContextTarget);
    }
}

StackFrame::StackFrame 
(
    lldb::user_id_t frame_idx, 
    lldb::user_id_t unwind_frame_index, 
    Thread &thread, 
    const RegisterContextSP &reg_context_sp, 
    lldb::addr_t cfa, 
    const Address& pc_addr,
    const SymbolContext *sc_ptr
) :
    m_frame_index (frame_idx),
    m_unwind_frame_index (unwind_frame_index),    
    m_thread (thread),
    m_reg_context_sp (reg_context_sp),
    m_id (pc_addr.GetLoadAddress (&thread.GetProcess()), cfa, NULL),
    m_frame_code_addr (pc_addr),
    m_sc (),
    m_flags (),
    m_frame_base (),
    m_frame_base_error (),
    m_variable_list_sp (),
    m_variable_list_value_objects ()
{
    if (sc_ptr != NULL)
    {
        m_sc = *sc_ptr;
        m_flags.Set(m_sc.GetResolvedMask ());
    }
    
    if (m_sc.target_sp.get() == NULL && reg_context_sp)
    {
        m_sc.target_sp = reg_context_sp->GetThread().GetProcess().GetTarget().GetSP();
        m_flags.Set (eSymbolContextTarget);
    }
    
    if (m_sc.module_sp.get() == NULL && pc_addr.GetSection())
    {
        Module *pc_module = pc_addr.GetSection()->GetModule();
        if (pc_module)
        {
            m_sc.module_sp = pc_module->GetSP();
            m_flags.Set (eSymbolContextModule);
        }
    }
}


//----------------------------------------------------------------------
// Destructor
//----------------------------------------------------------------------
StackFrame::~StackFrame()
{
}

StackID&
StackFrame::GetStackID()
{
    // Make sure we have resolved the StackID object's symbol context scope if
    // we already haven't looked it up.

    if (m_flags.IsClear (RESOLVED_FRAME_ID_SYMBOL_SCOPE))
    {
        if (m_id.GetSymbolContextScope () == NULL)
        {
            m_flags.Set (RESOLVED_FRAME_ID_SYMBOL_SCOPE);
        }
        else
        {
            GetSymbolContext (eSymbolContextFunction | eSymbolContextBlock);
            
            if (m_sc.block)
            {
                Block *inline_block = m_sc.block->GetContainingInlinedBlock();
                if (inline_block)
                {
                    // Use the block with the inlined function info
                    // as the symbol context since we want this frame
                    // to have only the variables for the inlined function
                    SetSymbolContextScope (inline_block);
                }
                else
                {
                    // This block is not inlined with means it has no
                    // inlined parents either, so we want to use the top
                    // most function block.
                    SetSymbolContextScope (&m_sc.function->GetBlock(false));
                }
            }
            else
            {
                // The current stack frame doesn't have a block. Check to see
                // if it has a symbol. If it does we will use this as the 
                // symbol scope. It is ok if "m_sc.symbol" is NULL below as
                // it will set the symbol context to NULL and set the
                // RESOLVED_FRAME_ID_SYMBOL_SCOPE flag bit.
                GetSymbolContext (eSymbolContextSymbol);
                SetSymbolContextScope (m_sc.symbol);
            }
        }
    }
    return m_id;
}

void
StackFrame::SetSymbolContextScope (SymbolContextScope *symbol_scope)
{
    m_flags.Set (RESOLVED_FRAME_ID_SYMBOL_SCOPE);
    m_id.SetSymbolContextScope (symbol_scope);
}

Address&
StackFrame::GetFrameCodeAddress()
{
    if (m_flags.IsClear(RESOLVED_FRAME_CODE_ADDR) && !m_frame_code_addr.IsSectionOffset())
    {
        m_flags.Set (RESOLVED_FRAME_CODE_ADDR);

        // Resolve the PC into a temporary address because if ResolveLoadAddress
        // fails to resolve the address, it will clear the address object...
        Address resolved_pc;
        if (m_thread.GetProcess().ResolveLoadAddress(m_frame_code_addr.GetOffset(), resolved_pc))
        {
            m_frame_code_addr = resolved_pc;
            const Section *section = m_frame_code_addr.GetSection();
            if (section)
            {
                Module *module = section->GetModule();
                if (module)
                {
                    m_sc.module_sp = module->GetSP();
                    if (m_sc.module_sp)
                        m_flags.Set(eSymbolContextModule);
                }
            }
        }
    }
    return m_frame_code_addr;
}

void
StackFrame::ChangePC (addr_t pc)
{
    m_frame_code_addr.SetOffset(pc);
    m_frame_code_addr.SetSection(NULL);
    m_sc.Clear();
    m_flags.SetAllFlagBits(0);
    m_thread.ClearStackFrames ();
}

const char *
StackFrame::Disassemble ()
{
    if (m_disassembly.GetSize() == 0)
    {
        ExecutionContext exe_ctx;
        Calculate(exe_ctx);
        Target &target = m_thread.GetProcess().GetTarget();
        Disassembler::Disassemble (target.GetDebugger(),
                                   target.GetArchitecture(),
                                   exe_ctx,
                                   0,
                                   false,
                                   m_disassembly);
        if (m_disassembly.GetSize() == 0)
            return NULL;
    }
    return m_disassembly.GetData();
}

//----------------------------------------------------------------------
// Get the symbol context if we already haven't done so by resolving the
// PC address as much as possible. This way when we pass around a
// StackFrame object, everyone will have as much information as
// possible and no one will ever have to look things up manually.
//----------------------------------------------------------------------
const SymbolContext&
StackFrame::GetSymbolContext (uint32_t resolve_scope)
{
    // Copy our internal symbol context into "sc".
    if ((m_flags.GetAllFlagBits() & resolve_scope) != resolve_scope)
    {
        // Resolve our PC to section offset if we haven't alreday done so
        // and if we don't have a module. The resolved address section will
        // contain the module to which it belongs
        if (!m_sc.module_sp && m_flags.IsClear(RESOLVED_FRAME_CODE_ADDR))
            GetFrameCodeAddress();

        // If this is not frame zero, then we need to subtract 1 from the PC
        // value when doing address lookups since the PC will be on the 
        // instruction following the function call instruction...
        
        Address lookup_addr(GetFrameCodeAddress());
        if (m_frame_index > 0 && lookup_addr.IsValid())
        {
            addr_t offset = lookup_addr.GetOffset();
            if (offset > 0)
                lookup_addr.SetOffset(offset - 1);
        }


        uint32_t resolved = 0;
        if (m_sc.module_sp)
        {
            // We have something in our stack frame symbol context, lets check
            // if we haven't already tried to lookup one of those things. If we
            // haven't then we will do the query.
            
            uint32_t actual_resolve_scope = 0;
            
            if (resolve_scope & eSymbolContextCompUnit)
            {
                if (m_flags.IsClear (eSymbolContextCompUnit))
                {
                    if (m_sc.comp_unit)
                        resolved |= eSymbolContextCompUnit;
                    else
                        actual_resolve_scope |= eSymbolContextCompUnit;
                }
            }

            if (resolve_scope & eSymbolContextFunction)
            {
                if (m_flags.IsClear (eSymbolContextFunction))
                {
                    if (m_sc.function)
                        resolved |= eSymbolContextFunction;
                    else
                        actual_resolve_scope |= eSymbolContextFunction;
                }
            }

            if (resolve_scope & eSymbolContextBlock)
            {
                if (m_flags.IsClear (eSymbolContextBlock))
                {
                    if (m_sc.block)
                        resolved |= eSymbolContextBlock;
                    else
                        actual_resolve_scope |= eSymbolContextBlock;
                }
            }

            if (resolve_scope & eSymbolContextSymbol)
            {
                if (m_flags.IsClear (eSymbolContextSymbol))
                {
                    if (m_sc.symbol)
                        resolved |= eSymbolContextSymbol;
                    else
                        actual_resolve_scope |= eSymbolContextSymbol;
                }
            }

            if (resolve_scope & eSymbolContextLineEntry)
            {
                if (m_flags.IsClear (eSymbolContextLineEntry))
                {
                    if (m_sc.line_entry.IsValid())
                        resolved |= eSymbolContextLineEntry;
                    else
                        actual_resolve_scope |= eSymbolContextLineEntry;
                }
            }
            
            if (actual_resolve_scope)
            {
                // We might be resolving less information than what is already
                // in our current symbol context so resolve into a temporary 
                // symbol context "sc" so we don't clear out data we have 
                // already found in "m_sc"
                SymbolContext sc;
                // Set flags that indicate what we have tried to resolve
                resolved |= m_sc.module_sp->ResolveSymbolContextForAddress (lookup_addr, actual_resolve_scope, sc);
                // Only replace what we didn't already have as we may have 
                // information for an inlined function scope that won't match
                // what a standard lookup by address would match
                if ((resolved & eSymbolContextCompUnit)  && m_sc.comp_unit == NULL)  
                    m_sc.comp_unit = sc.comp_unit;
                if ((resolved & eSymbolContextFunction)  && m_sc.function == NULL)  
                    m_sc.function = sc.function;
                if ((resolved & eSymbolContextBlock)     && m_sc.block == NULL)  
                    m_sc.block = sc.block;
                if ((resolved & eSymbolContextSymbol)    && m_sc.symbol == NULL)  
                    m_sc.symbol = sc.symbol;
                if ((resolved & eSymbolContextLineEntry) && !m_sc.line_entry.IsValid()) 
                    m_sc.line_entry = sc.line_entry;

            }
        }
        else
        {
            // If we don't have a module, then we can't have the compile unit,
            // function, block, line entry or symbol, so we can safely call
            // ResolveSymbolContextForAddress with our symbol context member m_sc.
            resolved |= m_thread.GetProcess().GetTarget().GetImages().ResolveSymbolContextForAddress (lookup_addr, resolve_scope, m_sc);
        }

        // If the target was requested add that:
        if (m_sc.target_sp.get() == NULL)
        {
            m_sc.target_sp = CalculateProcess()->GetTarget().GetSP();
            if (m_sc.target_sp)
                resolved |= eSymbolContextTarget;
        }

        // Update our internal flags so we remember what we have tried to locate so
        // we don't have to keep trying when more calls to this function are made.
        // We might have dug up more information that was requested (for example
        // if we were asked to only get the block, we will have gotten the 
        // compile unit, and function) so set any additional bits that we resolved
        m_flags.Set (resolve_scope | resolved);
    }

    // Return the symbol context with everything that was possible to resolve
    // resolved.
    return m_sc;
}


VariableList *
StackFrame::GetVariableList (bool get_file_globals)
{
    if (m_flags.IsClear(RESOLVED_VARIABLES))
    {
        m_flags.Set(RESOLVED_VARIABLES);

        GetSymbolContext (eSymbolContextCompUnit | 
                          eSymbolContextFunction | 
                          eSymbolContextBlock);

        if (m_sc.block)
        {
            bool get_child_variables = true;
            bool can_create = true;
            m_variable_list_sp = m_sc.function->GetBlock (can_create).GetVariableList (get_child_variables, can_create);
        }
        
        if (get_file_globals && m_sc.comp_unit)
        {
            VariableListSP global_variable_list_sp (m_sc.comp_unit->GetVariableList(true));
            if (m_variable_list_sp)
                m_variable_list_sp->AddVariables (global_variable_list_sp.get());
            else
                m_variable_list_sp = global_variable_list_sp;
        }
    }
    return m_variable_list_sp.get();
}


bool
StackFrame::GetFrameBaseValue (Scalar &frame_base, Error *error_ptr)
{
    if (m_flags.IsClear(GOT_FRAME_BASE))
    {
        if (m_sc.function)
        {
            m_frame_base.Clear();
            m_frame_base_error.Clear();

            m_flags.Set(GOT_FRAME_BASE);
            ExecutionContext exe_ctx (&m_thread.GetProcess(), &m_thread, this);
            Value expr_value;
            if (m_sc.function->GetFrameBaseExpression().Evaluate(&exe_ctx, NULL, NULL, expr_value, &m_frame_base_error) < 0)
            {
                // We should really have an error if evaluate returns, but in case
                // we don't, lets set the error to something at least.
                if (m_frame_base_error.Success())
                    m_frame_base_error.SetErrorString("Evaluation of the frame base expression failed.");
            }
            else
            {
                m_frame_base = expr_value.ResolveValue(&exe_ctx, NULL);
            }
        }
        else
        {
            m_frame_base_error.SetErrorString ("No function in symbol context.");
        }
    }

    if (m_frame_base_error.Success())
        frame_base = m_frame_base;

    if (error_ptr)
        *error_ptr = m_frame_base_error;
    return m_frame_base_error.Success();
}

RegisterContext *
StackFrame::GetRegisterContext ()
{
    if (m_reg_context_sp.get() == NULL)
        m_reg_context_sp.reset (m_thread.CreateRegisterContextForFrame (this));
    return m_reg_context_sp.get();
}

bool
StackFrame::HasDebugInformation ()
{
    GetSymbolContext (eSymbolContextLineEntry);
    return m_sc.line_entry.IsValid();
}


ValueObjectSP
StackFrame::GetValueObjectForFrameVariable (const VariableSP &variable_sp)
{
    ValueObjectSP valobj_sp;
    VariableList *var_list = GetVariableList (true);
    if (var_list)
    {
        // Make sure the variable is a frame variable
        const uint32_t var_idx = var_list->FindIndexForVariable (variable_sp.get());
        const uint32_t num_variables = var_list->GetSize();
        if (var_idx < num_variables)
        {
            valobj_sp = m_variable_list_value_objects.GetValueObjectAtIndex (var_idx);
            if (valobj_sp.get() == NULL)
            {
                if (m_variable_list_value_objects.GetSize() < num_variables)
                    m_variable_list_value_objects.Resize(num_variables);
                valobj_sp.reset (new ValueObjectVariable (variable_sp));
                m_variable_list_value_objects.SetValueObjectAtIndex (var_idx, valobj_sp);
            }
        }
    }
    return valobj_sp;
}

ValueObjectSP
StackFrame::TrackGlobalVariable (const VariableSP &variable_sp)
{
    // Check to make sure we aren't already tracking this variable?
    ValueObjectSP valobj_sp (GetValueObjectForFrameVariable (variable_sp));
    if (!valobj_sp)
    {
        // We aren't already tracking this global
        VariableList *var_list = GetVariableList (true);
        // If this frame has no variables, create a new list
        if (var_list == NULL)
            m_variable_list_sp.reset (new VariableList());

        // Add the global/static variable to this frame
        m_variable_list_sp->AddVariable (variable_sp);

        // Now make a value object for it so we can track its changes
        valobj_sp = GetValueObjectForFrameVariable (variable_sp);
    }
    return valobj_sp;
}

bool
StackFrame::IsInlined ()
{
    if (m_sc.block == NULL)
        GetSymbolContext (eSymbolContextBlock);
    if (m_sc.block)
        return m_sc.block->GetContainingInlinedBlock() != NULL;
    return false;
}

Target *
StackFrame::CalculateTarget ()
{
    return m_thread.CalculateTarget();
}

Process *
StackFrame::CalculateProcess ()
{
    return m_thread.CalculateProcess();
}

Thread *
StackFrame::CalculateThread ()
{
    return &m_thread;
}

StackFrame *
StackFrame::CalculateStackFrame ()
{
    return this;
}


void
StackFrame::Calculate (ExecutionContext &exe_ctx)
{
    m_thread.Calculate (exe_ctx);
    exe_ctx.frame = this;
}

void
StackFrame::Dump (Stream *strm, bool show_frame_index, bool show_fullpaths)
{
    if (strm == NULL)
        return;

    if (show_frame_index)
        strm->Printf("frame #%u: ", m_frame_index);
    strm->Printf("0x%0*llx ", m_thread.GetProcess().GetAddressByteSize() * 2, GetFrameCodeAddress().GetLoadAddress(&m_thread.GetProcess()));
    GetSymbolContext(eSymbolContextEverything);
    const bool show_module = true;
    const bool show_inline = true;
    m_sc.DumpStopContext(strm, &m_thread.GetProcess(), GetFrameCodeAddress(), show_fullpaths, show_module, show_inline);
}

void
StackFrame::UpdateCurrentFrameFromPreviousFrame (StackFrame &prev_frame)
{
    assert (GetStackID() == prev_frame.GetStackID());    // TODO: remove this after some testing
    m_variable_list_sp = prev_frame.m_variable_list_sp;
    m_variable_list_value_objects.Swap (prev_frame.m_variable_list_value_objects);
    if (!m_disassembly.GetString().empty())
        m_disassembly.GetString().swap (m_disassembly.GetString());
}
    

void
StackFrame::UpdatePreviousFrameFromCurrentFrame (StackFrame &curr_frame)
{
    assert (GetStackID() == curr_frame.GetStackID());    // TODO: remove this after some testing
    assert (&m_thread == &curr_frame.m_thread);
    m_frame_index = curr_frame.m_frame_index;
    m_unwind_frame_index = curr_frame.m_unwind_frame_index;
    m_reg_context_sp = curr_frame.m_reg_context_sp;
    m_frame_code_addr = curr_frame.m_frame_code_addr;
    assert (m_sc.target_sp.get() == NULL || curr_frame.m_sc.target_sp.get() == NULL || m_sc.target_sp.get() == curr_frame.m_sc.target_sp.get());
    assert (m_sc.module_sp.get() == NULL || curr_frame.m_sc.module_sp.get() == NULL || m_sc.module_sp.get() == curr_frame.m_sc.module_sp.get());
    assert (m_sc.comp_unit == NULL || curr_frame.m_sc.comp_unit == NULL || m_sc.comp_unit == curr_frame.m_sc.comp_unit);
    assert (m_sc.function == NULL || curr_frame.m_sc.function == NULL || m_sc.function == curr_frame.m_sc.function);
    m_sc = curr_frame.m_sc;
    m_flags.Clear(GOT_FRAME_BASE | eSymbolContextEverything);
    m_flags.Set (m_sc.GetResolvedMask());
    m_frame_base.Clear();
    m_frame_base_error.Clear();
}
    

