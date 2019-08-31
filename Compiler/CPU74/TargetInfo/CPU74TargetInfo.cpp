//===-- CPU74TargetInfo.cpp - CPU74 Target Implementation ---------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "CPU74.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/TargetRegistry.h"
using namespace llvm;

Target &llvm::getTheCPU74Target() {
  static Target TheCPU74Target;
  return TheCPU74Target;
}

extern "C" void LLVMInitializeCPU74TargetInfo() {
  RegisterTarget<Triple::cpu74> X(getTheCPU74Target(), "cpu74",
                                   "CPU74 [experimental]", "CPU74");
}
