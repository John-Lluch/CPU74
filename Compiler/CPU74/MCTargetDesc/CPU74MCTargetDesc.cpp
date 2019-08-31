//===-- CPU74MCTargetDesc.cpp - CPU74 Target Descriptions ---------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file provides CPU74 specific target descriptions.
//
//===----------------------------------------------------------------------===//

#include "CPU74MCTargetDesc.h"
#include "InstPrinter/CPU74InstPrinter.h"
#include "CPU74MCAsmInfo.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/Support/TargetRegistry.h"

using namespace llvm;

#define GET_INSTRINFO_MC_DESC
#include "CPU74GenInstrInfo.inc"

#define GET_SUBTARGETINFO_MC_DESC
#include "CPU74GenSubtargetInfo.inc"

#define GET_REGINFO_MC_DESC
#include "CPU74GenRegisterInfo.inc"

static MCInstrInfo *createCPU74MCInstrInfo() {
  MCInstrInfo *X = new MCInstrInfo();
  InitCPU74MCInstrInfo(X);
  return X;
}

static MCRegisterInfo *createCPU74MCRegisterInfo(const Triple &TT) {
  MCRegisterInfo *X = new MCRegisterInfo();
  InitCPU74MCRegisterInfo(X, CPU74::PC);
  return X;
}

static MCSubtargetInfo *
createCPU74MCSubtargetInfo(const Triple &TT, StringRef CPU, StringRef FS) {
  return createCPU74MCSubtargetInfoImpl(TT, CPU, FS);
}

static MCInstPrinter *createCPU74MCInstPrinter(const Triple &T,
                                                unsigned SyntaxVariant,
                                                const MCAsmInfo &MAI,
                                                const MCInstrInfo &MII,
                                                const MCRegisterInfo &MRI) {
  if (SyntaxVariant == 0)
    return new CPU74InstPrinter(MAI, MII, MRI);
  return nullptr;
}

extern "C" void LLVMInitializeCPU74TargetMC() {
  // Register the MC asm info.
  RegisterMCAsmInfo<CPU74MCAsmInfo> X(getTheCPU74Target());

  // Register the MC instruction info.
  TargetRegistry::RegisterMCInstrInfo(getTheCPU74Target(),
                                      createCPU74MCInstrInfo);

  // Register the MC register info.
  TargetRegistry::RegisterMCRegInfo(getTheCPU74Target(),
                                    createCPU74MCRegisterInfo);

  // Register the MC subtarget info.
  TargetRegistry::RegisterMCSubtargetInfo(getTheCPU74Target(),
                                          createCPU74MCSubtargetInfo);

  // Register the MCInstPrinter.
  TargetRegistry::RegisterMCInstPrinter(getTheCPU74Target(),
                                        createCPU74MCInstPrinter);
  
  // Register the MC Code Emitter
  TargetRegistry::RegisterMCCodeEmitter(getTheCPU74Target(), createCPU74MCCodeEmitter);
}
