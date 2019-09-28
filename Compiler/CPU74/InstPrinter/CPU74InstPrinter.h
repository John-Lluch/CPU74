//= CPU74InstPrinter.h - Convert CPU74 MCInst to assembly syntax -*- C++ -*-//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This class prints a CPU74 MCInst to a .s file.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_CPU74_INSTPRINTER_CPU74INSTPRINTER_H
#define LLVM_LIB_TARGET_CPU74_INSTPRINTER_CPU74INSTPRINTER_H

#include "llvm/MC/MCInstPrinter.h"
#include "llvm/MC/MCInst.h"

namespace llvm {
  class CPU74InstPrinter : public MCInstPrinter {
  public:
    CPU74InstPrinter(const MCAsmInfo &MAI, const MCInstrInfo &MII,
                      const MCRegisterInfo &MRI)
      : MCInstPrinter(MAI, MII, MRI) {}

    void printInst(const MCInst *MI, raw_ostream &O, StringRef Annot,
                   const MCSubtargetInfo &STI) override;

    // Autogenerated by tblgen.
    void printInstruction(const MCInst *MI, raw_ostream &O);
    static const char *getRegisterName(unsigned RegNo);

    void printOperand(const MCInst *MI, unsigned OpNo, raw_ostream &O);
    void printPCRelOperand(const MCInst *MI, unsigned OpNo, raw_ostream &O);
    void printProgAbsOperand(const MCInst *MI, unsigned OpNo, raw_ostream &O);
    void printMemIndexed(const MCInst *MI, unsigned OpNo, raw_ostream &O);
    void printMemWordIndexed(const MCInst *MI, unsigned OpNo, raw_ostream &O);
    void printLeaWordIndexed(const MCInst *MI, unsigned OpNo, raw_ostream &O);
    void printAddress(const MCInst *MI, unsigned OpNo, raw_ostream &O);
    void printCCOperand(const MCInst *MI, unsigned OpNo, raw_ostream &O);
    void printLargeOperand(const MCInst *MI, unsigned OpNo, raw_ostream &O);
    
  private:
  
    void doPrintOperand(const MCInst *MI, const MCOperand &op, raw_ostream &O, const char *pfix[], const char *spfix);
    void doPrintLeaIndexed(const MCInst *MI, unsigned OpNo, raw_ostream &O, const char *pfix[]);
    void doPrintMemIndexed(const MCInst *MI, unsigned OpNo, raw_ostream &O, const char *pfix[]);
    void doPrintLeaAddress(const MCInst *MI, unsigned OpNo, raw_ostream &O);
    void doPrintMemAddress(const MCInst *MI, unsigned OpNo, raw_ostream &O);

  };
}

#endif