//===-- CPU74InstPrinter.cpp - Convert CPU74 MCInst to assembly syntax --===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This class prints an CPU74 MCInst to a .s file.
//
//===----------------------------------------------------------------------===//

#include "CPU74InstPrinter.h"
#include "CPU74InstrInfo.h"
#include "CPU74.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/FormattedStream.h"
using namespace llvm;

#define DEBUG_TYPE "asm-printer"


// Include the auto-generated portion of the assembly writer.
#include "CPU74GenAsmWriter.inc"

static const char *ImmPfix[] = { "", "" };      // An embedded short immediate
static const char *ImmWordPfix[] = { "", "L" }; // A large immediate in the next word
static const char *GblSymPrefix = "&";  // An absolute address in data memory
static const char *PCRelSymPrefix = ""; // A PC relative address in program memory
static const char *PrgSymPrefix = "@";  // An absolute address in program memory

void CPU74InstPrinter::printInst(const MCInst *MI, raw_ostream &O,
                                  StringRef Annot, const MCSubtargetInfo &STI)
{
  printInstruction(MI, O);
  printAnnotation(O, Annot);
}


void CPU74InstPrinter::printOperand(const MCInst *MI, unsigned OpNo, raw_ostream &O)
{
  const MCOperand &op = MI->getOperand(OpNo);
  doPrintOperand(MI, op, O, ImmPfix, GblSymPrefix);
}

void CPU74InstPrinter::printLargeOperand(const MCInst *MI, unsigned OpNo, raw_ostream &O)
{
  const MCOperand &op = MI->getOperand(OpNo);
  assert((op.isImm() || op.isExpr()) && "Expected immediate or expression");
  doPrintOperand(MI, op, O, ImmWordPfix, GblSymPrefix);
}

void CPU74InstPrinter::printPCRelOperand(const MCInst *MI, unsigned OpNo, raw_ostream &O)
{
  const MCOperand &op = MI->getOperand(OpNo);
  assert(op.isExpr() && "unknown PC relative operand");
  doPrintOperand(MI, op, O, NULL, PCRelSymPrefix);
}

void CPU74InstPrinter::printProgAbsOperand( const MCInst *MI, unsigned OpNo, raw_ostream &O)
{
  const MCOperand &op = MI->getOperand(OpNo);
  assert(op.isExpr() && "unknown program memory operand");
  doPrintOperand(MI, op, O, NULL, PrgSymPrefix);
}

void CPU74InstPrinter::printMemIndexed(const MCInst *MI, unsigned OpNo, raw_ostream &O)
{
  doPrintMemIndexed(MI, OpNo, O, ImmPfix );
}

void CPU74InstPrinter::printMemWordIndexed(const MCInst *MI, unsigned OpNo, raw_ostream &O)
{
  doPrintMemIndexed(MI, OpNo, O, ImmWordPfix );
}

void CPU74InstPrinter::printLeaWordIndexed(const MCInst *MI, unsigned OpNo, raw_ostream &O)
{
  doPrintLeaIndexed(MI, OpNo, O, ImmWordPfix );
}

void CPU74InstPrinter::printAddress(const MCInst *MI, unsigned OpNo, raw_ostream &O)
{
  doPrintMemAddress(MI, OpNo, O);
}

void CPU74InstPrinter::doPrintOperand( const MCInst *MI, const MCOperand &op, raw_ostream &O,
                                      const char *pfix[], const char *spfix)
{
  if (op.isReg())         { O << getRegisterName(op.getReg()); }
  else if (op.isImm())    { O << pfix[0] << op.getImm() << pfix[1]; }
  else if ( op.isExpr())  { O << spfix; op.getExpr()->print(O, &MAI); }
  else                    { assert(false && "unknown operand kind in printOperand"); }
}

void CPU74InstPrinter::doPrintLeaIndexed(const MCInst *MI, unsigned OpNo, raw_ostream &O, const char *pfix[])
{
  const MCOperand &Base = MI->getOperand(OpNo);
  const MCOperand &Disp = MI->getOperand(OpNo+1);
  
  assert(Base.isReg() && "Expected register as base in displacement field");
  doPrintOperand( MI, Base, O, NULL, NULL ) ; O << ", " ;
  assert((Disp.isImm() || Disp.isExpr()) && "Expected immediate or expression in displacement field");
  doPrintOperand( MI, Disp, O, pfix, GblSymPrefix );
}

void CPU74InstPrinter::doPrintLeaAddress(const MCInst *MI, unsigned OpNo, raw_ostream &O)
{
  const MCOperand &Base = MI->getOperand(OpNo);
  assert(Base.isExpr() && "Expected expression in absolute address field");
  doPrintOperand( MI, Base, O, NULL, GblSymPrefix );
}

void CPU74InstPrinter::doPrintMemIndexed(const MCInst *MI, unsigned OpNo, raw_ostream &O, const char *pfix[])
{
  O << '['; doPrintLeaIndexed(MI, OpNo, O, pfix ); O << ']';
}

void CPU74InstPrinter::doPrintMemAddress(const MCInst *MI, unsigned OpNo, raw_ostream &O)
{
  O << '[' ; doPrintLeaAddress(MI, OpNo, O) ; O << ']';
}

void CPU74InstPrinter::printCCOperand(const MCInst *MI, unsigned OpNo, raw_ostream &O)
{
  unsigned CC = MI->getOperand(OpNo).getImm();

  switch (CC) {
  default:
   llvm_unreachable("Unsupported CC code");
  case CPU74CC::COND_NE:
    O << "ne";
    break;
  case CPU74CC::COND_EQ:
    O << "eq";
    break;
  case CPU74CC::COND_GT:
    O << "gt";
    break;
  case CPU74CC::COND_GE:
    O << "ge";
    break;
  case CPU74CC::COND_LT:
    O << "lt";
    break;
  case CPU74CC::COND_LE:
    O << "le";
    break;
  case CPU74CC::COND_UGT:
    O << "ugt";
    break;
  case CPU74CC::COND_UGE:
    O << "uge";
    break;
  case CPU74CC::COND_ULT:
    O << "ult";
    break;
  case CPU74CC::COND_ULE:
    O << "ule";
    break;
  }
}
