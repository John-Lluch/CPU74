//==-- CPU74.h - Top-level interface for CPU74 representation --*- C++ -*-==//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the entry points for global functions defined in
// the LLVM CPU74 backend.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_CPU74_CPU74_H
#define LLVM_LIB_TARGET_CPU74_CPU74_H

#include "MCTargetDesc/CPU74MCTargetDesc.h"
#include "llvm/Target/TargetMachine.h"

#include <stdlib.h>

namespace CPU74Imm
{
  static const int Imm5Disp = 0;
  static const int MaxImm5 = 32;
  static inline bool isImm5_d( int imm ){ return (imm+Imm5Disp) >= 0 && (imm+Imm5Disp) < MaxImm5; }


  // Immediate mov, cmp
  static inline bool isImm8s( int imm ){ return imm >= -128 && imm < 128; }
  
  // Immediate add/sub, SP indexed load/stores
  static const int MaxImm8 = 256;
  static inline bool isImm8u( int imm ){ return imm >= 0 && imm < MaxImm8; }
}


namespace llvm {
  class CPU74TargetMachine;
  class FunctionPass;
  class ModulePass;
  class formatted_raw_ostream;

  ModulePass  *createAlignVisitPass();
  FunctionPass *createCPU74ISelDag(CPU74TargetMachine &TM, CodeGenOpt::Level OptLevel);
//  FunctionPass *createCPU74FrameAnalyzerPass();
  FunctionPass *createCPU74BranchSelectionPass();

} // end namespace llvm;


#endif
