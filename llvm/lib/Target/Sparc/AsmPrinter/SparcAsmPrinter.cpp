//===-- SparcAsmPrinter.cpp - Sparc LLVM assembly writer ------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains a printer that converts from our internal representation
// of machine-dependent LLVM code to GAS-format SPARC assembly language.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "asm-printer"
#include "Sparc.h"
#include "SparcInstrInfo.h"
#include "SparcTargetMachine.h"
#include "llvm/Constants.h"
#include "llvm/DerivedTypes.h"
#include "llvm/Module.h"
#include "llvm/CodeGen/AsmPrinter.h"
#include "llvm/CodeGen/DwarfWriter.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineConstantPool.h"
#include "llvm/CodeGen/MachineInstr.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/Target/TargetLoweringObjectFile.h"
#include "llvm/Target/TargetRegistry.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/ADT/StringExtras.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/FormattedStream.h"
#include "llvm/Support/Mangler.h"
#include "llvm/Support/MathExtras.h"
#include <cctype>
#include <cstring>
#include <map>
using namespace llvm;

STATISTIC(EmittedInsts, "Number of machine instrs printed");

namespace {
  class VISIBILITY_HIDDEN SparcAsmPrinter : public AsmPrinter {
    /// We name each basic block in a Function with a unique number, so
    /// that we can consistently refer to them later. This is cleared
    /// at the beginning of each call to runOnMachineFunction().
    ///
    typedef std::map<const Value *, unsigned> ValueMapTy;
    ValueMapTy NumberForBB;
    unsigned BBNumber;
  public:
    explicit SparcAsmPrinter(formatted_raw_ostream &O, TargetMachine &TM,
                             const MCAsmInfo *T, bool V)
      : AsmPrinter(O, TM, T, V), BBNumber(0) {}

    virtual const char *getPassName() const {
      return "Sparc Assembly Printer";
    }

    void PrintGlobalVariable(const GlobalVariable *GVar);
    void printOperand(const MachineInstr *MI, int opNum);
    void printMemOperand(const MachineInstr *MI, int opNum,
                         const char *Modifier = 0);
    void printCCOperand(const MachineInstr *MI, int opNum);

    void printInstruction(const MachineInstr *MI);  // autogenerated.
    static const char *getRegisterName(unsigned RegNo);

    bool runOnMachineFunction(MachineFunction &F);
    bool PrintAsmOperand(const MachineInstr *MI, unsigned OpNo,
                       unsigned AsmVariant, const char *ExtraCode);
    bool PrintAsmMemoryOperand(const MachineInstr *MI, unsigned OpNo,
                             unsigned AsmVariant, const char *ExtraCode);
  };
} // end of anonymous namespace

#include "SparcGenAsmWriter.inc"


/// runOnMachineFunction - This uses the printInstruction()
/// method to print assembly for each instruction.
///
bool SparcAsmPrinter::runOnMachineFunction(MachineFunction &MF) {
  this->MF = &MF;

  SetupMachineFunction(MF);

  // Print out constants referenced by the function
  EmitConstantPool(MF.getConstantPool());

  // BBNumber is used here so that a given Printer will never give two
  // BBs the same name. (If you have a better way, please let me know!)

  O << "\n\n";

  // Print out the label for the function.
  const Function *F = MF.getFunction();
  OutStreamer.SwitchSection(getObjFileLowering().SectionForGlobal(F, Mang, TM));
  EmitAlignment(MF.getAlignment(), F);
  O << "\t.globl\t" << CurrentFnName << '\n';

  printVisibility(CurrentFnName, F->getVisibility());

  O << "\t.type\t" << CurrentFnName << ", #function\n";
  O << CurrentFnName << ":\n";
  // Emit pre-function debug information.
  DW->BeginFunction(&MF);

  // Number each basic block so that we can consistently refer to them
  // in PC-relative references.
  // FIXME: Why not use the MBB numbers?
  NumberForBB.clear();
  for (MachineFunction::const_iterator I = MF.begin(), E = MF.end();
       I != E; ++I) {
    NumberForBB[I->getBasicBlock()] = BBNumber++;
  }

  // Print out code for the function.
  for (MachineFunction::const_iterator I = MF.begin(), E = MF.end();
       I != E; ++I) {
    // Print a label for the basic block.
    if (I != MF.begin()) {
      EmitBasicBlockStart(I);
      O << '\n';
    }
    for (MachineBasicBlock::const_iterator II = I->begin(), E = I->end();
         II != E; ++II) {
      // Print the assembly for the instruction.
      processDebugLoc(II->getDebugLoc());
      printInstruction(II);
      
      if (VerboseAsm && !II->getDebugLoc().isUnknown())
        EmitComments(*II);
      O << '\n';
      
      ++EmittedInsts;
    }
  }

  // Emit post-function debug information.
  DW->EndFunction(&MF);

  // We didn't modify anything.
  return false;
}

void SparcAsmPrinter::printOperand(const MachineInstr *MI, int opNum) {
  const MachineOperand &MO = MI->getOperand (opNum);
  bool CloseParen = false;
  if (MI->getOpcode() == SP::SETHIi && !MO.isReg() && !MO.isImm()) {
    O << "%hi(";
    CloseParen = true;
  } else if ((MI->getOpcode() == SP::ORri || MI->getOpcode() == SP::ADDri) &&
             !MO.isReg() && !MO.isImm()) {
    O << "%lo(";
    CloseParen = true;
  }
  switch (MO.getType()) {
  case MachineOperand::MO_Register:
    O << "%" << LowercaseString(getRegisterName(MO.getReg()));
    break;

  case MachineOperand::MO_Immediate:
    O << (int)MO.getImm();
    break;
  case MachineOperand::MO_MachineBasicBlock:
    GetMBBSymbol(MO.getMBB()->getNumber())->print(O, MAI);
    return;
  case MachineOperand::MO_GlobalAddress:
    O << Mang->getMangledName(MO.getGlobal());
    break;
  case MachineOperand::MO_ExternalSymbol:
    O << MO.getSymbolName();
    break;
  case MachineOperand::MO_ConstantPoolIndex:
    O << MAI->getPrivateGlobalPrefix() << "CPI" << getFunctionNumber() << "_"
      << MO.getIndex();
    break;
  default:
    llvm_unreachable("<unknown operand type>");
  }
  if (CloseParen) O << ")";
}

void SparcAsmPrinter::printMemOperand(const MachineInstr *MI, int opNum,
                                      const char *Modifier) {
  printOperand(MI, opNum);

  // If this is an ADD operand, emit it like normal operands.
  if (Modifier && !strcmp(Modifier, "arith")) {
    O << ", ";
    printOperand(MI, opNum+1);
    return;
  }

  if (MI->getOperand(opNum+1).isReg() &&
      MI->getOperand(opNum+1).getReg() == SP::G0)
    return;   // don't print "+%g0"
  if (MI->getOperand(opNum+1).isImm() &&
      MI->getOperand(opNum+1).getImm() == 0)
    return;   // don't print "+0"

  O << "+";
  if (MI->getOperand(opNum+1).isGlobal() ||
      MI->getOperand(opNum+1).isCPI()) {
    O << "%lo(";
    printOperand(MI, opNum+1);
    O << ")";
  } else {
    printOperand(MI, opNum+1);
  }
}

void SparcAsmPrinter::printCCOperand(const MachineInstr *MI, int opNum) {
  int CC = (int)MI->getOperand(opNum).getImm();
  O << SPARCCondCodeToString((SPCC::CondCodes)CC);
}

void SparcAsmPrinter::PrintGlobalVariable(const GlobalVariable* GVar) {
  const TargetData *TD = TM.getTargetData();

  if (!GVar->hasInitializer())
    return;  // External global require no code

  // Check to see if this is a special global used by LLVM, if so, emit it.
  if (EmitSpecialLLVMGlobal(GVar))
    return;

  O << "\n\n";
  std::string name = Mang->getMangledName(GVar);
  Constant *C = GVar->getInitializer();
  unsigned Size = TD->getTypeAllocSize(C->getType());
  unsigned Align = TD->getPreferredAlignment(GVar);

  printVisibility(name, GVar->getVisibility());

  OutStreamer.SwitchSection(getObjFileLowering().SectionForGlobal(GVar, Mang,
                                                                  TM));

  if (C->isNullValue() && !GVar->hasSection()) {
    if (!GVar->isThreadLocal() &&
        (GVar->hasLocalLinkage() || GVar->isWeakForLinker())) {
      if (Size == 0) Size = 1;   // .comm Foo, 0 is undefined, avoid it.

      if (GVar->hasLocalLinkage())
        O << "\t.local " << name << '\n';

      O << MAI->getCOMMDirective() << name << ',' << Size;
      if (MAI->getCOMMDirectiveTakesAlignment())
        O << ',' << (1 << Align);

      O << '\n';
      return;
    }
  }

  switch (GVar->getLinkage()) {
   case GlobalValue::CommonLinkage:
   case GlobalValue::LinkOnceAnyLinkage:
   case GlobalValue::LinkOnceODRLinkage:
   case GlobalValue::WeakAnyLinkage: // FIXME: Verify correct for weak.
   case GlobalValue::WeakODRLinkage: // FIXME: Verify correct for weak.
    // Nonnull linkonce -> weak
    O << "\t.weak " << name << '\n';
    break;
   case GlobalValue::AppendingLinkage:
    // FIXME: appending linkage variables should go into a section of
    // their name or something.  For now, just emit them as external.
   case GlobalValue::ExternalLinkage:
    // If external or appending, declare as a global symbol
    O << MAI->getGlobalDirective() << name << '\n';
    // FALL THROUGH
   case GlobalValue::PrivateLinkage:
   case GlobalValue::LinkerPrivateLinkage:
   case GlobalValue::InternalLinkage:
    break;
   case GlobalValue::GhostLinkage:
    llvm_unreachable("Should not have any unmaterialized functions!");
   case GlobalValue::DLLImportLinkage:
    llvm_unreachable("DLLImport linkage is not supported by this target!");
   case GlobalValue::DLLExportLinkage:
    llvm_unreachable("DLLExport linkage is not supported by this target!");
   default:
    llvm_unreachable("Unknown linkage type!");
  }

  EmitAlignment(Align, GVar);

  if (MAI->hasDotTypeDotSizeDirective()) {
    O << "\t.type " << name << ",#object\n";
    O << "\t.size " << name << ',' << Size << '\n';
  }

  O << name << ":\n";
  EmitGlobalConstant(C);
}

/// PrintAsmOperand - Print out an operand for an inline asm expression.
///
bool SparcAsmPrinter::PrintAsmOperand(const MachineInstr *MI, unsigned OpNo,
                                      unsigned AsmVariant,
                                      const char *ExtraCode) {
  if (ExtraCode && ExtraCode[0]) {
    if (ExtraCode[1] != 0) return true; // Unknown modifier.

    switch (ExtraCode[0]) {
    default: return true;  // Unknown modifier.
    case 'r':
     break;
    }
  }

  printOperand(MI, OpNo);

  return false;
}

bool SparcAsmPrinter::PrintAsmMemoryOperand(const MachineInstr *MI,
                                            unsigned OpNo,
                                            unsigned AsmVariant,
                                            const char *ExtraCode) {
  if (ExtraCode && ExtraCode[0])
    return true;  // Unknown modifier

  O << '[';
  printMemOperand(MI, OpNo);
  O << ']';

  return false;
}

// Force static initialization.
extern "C" void LLVMInitializeSparcAsmPrinter() { 
  RegisterAsmPrinter<SparcAsmPrinter> X(TheSparcTarget);
}
