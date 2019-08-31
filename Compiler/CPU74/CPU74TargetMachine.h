//===-- CPU74TargetMachine.h - Define TargetMachine for CPU74 -*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file declares the CPU74 specific subclass of TargetMachine.
//
//===----------------------------------------------------------------------===//


#ifndef LLVM_LIB_TARGET_CPU74_CPU74TARGETMACHINE_H
#define LLVM_LIB_TARGET_CPU74_CPU74TARGETMACHINE_H

#include "CPU74Subtarget.h"

#include "llvm/CodeGen/TargetFrameLowering.h"
#include "llvm/Target/TargetMachine.h"

namespace llvm {

/// CPU74TargetMachine
///
class CPU74TargetMachine : public LLVMTargetMachine {
  std::unique_ptr<TargetLoweringObjectFile> TLOF;
  CPU74Subtarget        Subtarget;

public:
  CPU74TargetMachine(const Target &T, const Triple &TT, StringRef CPU,
                      StringRef FS, const TargetOptions &Options,
                      Optional<Reloc::Model> RM, Optional<CodeModel::Model> CM,
                      CodeGenOpt::Level OL, bool JIT);
  ~CPU74TargetMachine() override;


  const CPU74Subtarget *getSubtargetImpl() const { return &Subtarget; }
  const CPU74Subtarget *getSubtargetImpl(const Function &F) const override { return &Subtarget; }
  TargetTransformInfo getTargetTransformInfo(const Function &F) override;
  
  TargetPassConfig *createPassConfig(PassManagerBase &PM) override;
  
  TargetLoweringObjectFile *getObjFileLowering() const override {return TLOF.get();}
  
}; // CPU74TargetMachine.

} // end namespace llvm

#endif
