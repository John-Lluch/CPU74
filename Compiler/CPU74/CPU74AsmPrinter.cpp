//===-- CPU74AsmPrinter.cpp - CPU74 LLVM assembly writer ----------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains a printer that converts from our internal representation
// of machine-dependent LLVM code to the CPU74 assembly language.
//
//===----------------------------------------------------------------------===//

#include "InstPrinter/CPU74InstPrinter.h"
#include "CPU74.h"
#include "CPU74InstrInfo.h"
#include "CPU74MCInstLower.h"
#include "CPU74TargetMachine.h"
#include "llvm/CodeGen/AsmPrinter.h"
#include "llvm/CodeGen/MachineConstantPool.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineInstr.h"
#include "llvm/CodeGen/MachineModuleInfo.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Mangler.h"
#include "llvm/IR/Module.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/Support/TargetRegistry.h"
#include "llvm/Support/raw_ostream.h"
using namespace llvm;

#define DEBUG_TYPE "asm-printer"

namespace {
  class CPU74AsmPrinter : public AsmPrinter {
  public:
    CPU74AsmPrinter(TargetMachine &TM, std::unique_ptr<MCStreamer> Streamer)
        : AsmPrinter(TM, std::move(Streamer)), globalsPrinted(false) {}

    StringRef getPassName() const override { return "CPU74 Assembly Printer"; }

    void printOperand(const MachineInstr *MI, int OpNum, raw_ostream &O, const char* Modifier = nullptr);
    void printMemOperand(const MachineInstr *MI, int OpNum, raw_ostream &O);
    
    bool PrintAsmOperand(const MachineInstr *MI, unsigned OpNo,
                               const char *ExtraCode, raw_ostream &OS) override;
//    bool PrintAsmOperand(const MachineInstr *MI, unsigned OpNo, unsigned AsmVariant, const char *ExtraCode, raw_ostream &O) override;
    bool PrintAsmMemoryOperand(const MachineInstr *MI, unsigned OpNo,
                            const char *ExtraCode, raw_ostream &O) override;
    void EmitInstruction(const MachineInstr *MI) override;
    
    void EmitFunctionBodyStart() override;
    void EmitFunctionBodyEnd() override;
    void EmitConstantPool() override;
    void EmitGlobalVariable(const GlobalVariable *GV) override;

    //void EmitFunctionEntryLabel() override;
    
  private:
    bool globalsPrinted;
    //void EmitFunctionHeader() override;   // Call super
    
    
  };
} // end of anonymous namespace


void CPU74AsmPrinter::printOperand(const MachineInstr *MI, int OpNum,
                                    raw_ostream &O, const char *Modifier)
                                    {
  const MachineOperand &MO = MI->getOperand(OpNum);
  
  switch (MO.getType())
  {
    default: llvm_unreachable("Not implemented yet!");
        return;
      
    case MachineOperand::MO_Register:
        O << CPU74InstPrinter::getRegisterName(MO.getReg());
        return;
      
    case MachineOperand::MO_Immediate:
        if (!Modifier || strcmp(Modifier, "nohash"))
              O << '#';
        O << MO.getImm();
        return;
      
    case MachineOperand::MO_MachineBasicBlock:
        MO.getMBB()->getSymbol()->print(O, MAI);
        return;
      
    case MachineOperand::MO_GlobalAddress:
        bool isMemOp  = Modifier && !strcmp(Modifier, "mem");
        uint64_t Offset = MO.getOffset();

    // If the global address expression is a part of displacement field with a
    // register base, we should not emit any prefix symbol here, e.g.
    //   mov.w &foo, r1
    // vs
    //   mov.w glb(r1), r2
    // Otherwise (!) CPU74-as will silently miscompile the output :(
      if (!Modifier || strcmp(Modifier, "nohash"))
          O << (isMemOp ? '&' : '#');
      if (Offset)
          O << '(' << Offset << '+';

      getSymbol(MO.getGlobal())->print(O, MAI);

      if (Offset)
          O << ')';

      return;
  }
}

void CPU74AsmPrinter::printMemOperand(const MachineInstr *MI, int OpNum,
                                          raw_ostream &O)
                                          {
  const MachineOperand &Base = MI->getOperand(OpNum);
  const MachineOperand &Disp = MI->getOperand(OpNum+1);

  
  // Print displacement first

  // Imm here is in fact global address - print extra modifier.
  if (Disp.isImm() && !Base.isReg())
    O << '&';
  printOperand(MI, OpNum+1, O, "nohash");

  // Print register base field
  if (Base.isReg()) {
    O << '(';
    printOperand(MI, OpNum, O);
    O << ')';
  }
}



/// PrintAsmOperand - Print out an operand for an inline asm expression.
///
bool CPU74AsmPrinter::PrintAsmOperand(const MachineInstr *MI, unsigned OpNo,
                                       const char *ExtraCode, raw_ostream &O) {
  // Does this asm operand have a single letter operand modifier?
  if (ExtraCode && ExtraCode[0])
    return true; // Unknown modifier.

  printOperand(MI, OpNo, O);
  return false;
}

bool CPU74AsmPrinter::PrintAsmMemoryOperand(const MachineInstr *MI,
                                             unsigned OpNo,
                                             const char *ExtraCode,
                                             raw_ostream &O)
{
  if (ExtraCode && ExtraCode[0]) {
    return true; // Unknown modifier.
  }
  printMemOperand(MI, OpNo, O);
  return false;
}

//===----------------------------------------------------------------------===//

//void CPU74AsmPrinter::EmitFunctionHeader()
//{
//    OutStreamer->EmitRawText( "#--------- " + CurrentFnSym->getName() + " --------------" );
//    AsmPrinter::EmitFunctionHeader();
//}

void CPU74AsmPrinter::EmitFunctionBodyStart()
{
 //OutStreamer->EmitRawText( "# BEGIN ----------------------" + CurrentFnSym->getName() );
 int dummy = 0;
}

void CPU74AsmPrinter::EmitFunctionBodyEnd()
{
 // OutStreamer->EmitRawText( "# END -----------------------" + CurrentFnSym->getName());
}

void CPU74AsmPrinter::EmitGlobalVariable(const GlobalVariable *GV)
{
  if ( !globalsPrinted )
  {
    globalsPrinted = true;
    OutStreamer->EmitRawText( "# ---------------------------------------------");
    OutStreamer->EmitRawText( "# Global Data" );
    OutStreamer->EmitRawText( "# ---------------------------------------------");
    //OutStreamer->EmitRawText( "\n" );
  }
  AsmPrinter::EmitGlobalVariable(GV);
}


void CPU74AsmPrinter::EmitConstantPool()
{
  //OutStreamer->EmitRawText( "\n" );
  OutStreamer->EmitRawText( "# ---------------------------------------------");
  OutStreamer->EmitRawText( "# " + CurrentFnSym->getName() );
  OutStreamer->EmitRawText( "# ---------------------------------------------");
  //OutStreamer->EmitRawText( "\n" );
  AsmPrinter::EmitConstantPool();
}
//
//void CPU74AsmPrinter::EmitFunctionEntryLabel()
//{
//  // Mark the start of the function
//  //OutStreamer->EmitRawText( "# BEGIN ----------------------" + CurrentFnSym->getName() );
//  AsmPrinter::EmitFunctionEntryLabel();
//}


void CPU74AsmPrinter::EmitInstruction(const MachineInstr *MI)
{
  CPU74MCInstLower MCInstLower(OutContext, *this);

  MCInst I;
  MCInstLower.lowerInstruction(MI, I);   // crida CPU74MCInstLower
  EmitToStreamer(*OutStreamer, I);
}

// Force static initialization.
extern "C" void LLVMInitializeCPU74AsmPrinter() {
  RegisterAsmPrinter<CPU74AsmPrinter> X(getTheCPU74Target());
}
