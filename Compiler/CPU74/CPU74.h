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


// #define FP_AS_SPILL  // use #ifdef in the code

namespace CPU74Imm
{
  //typedef bool (*ImmTestF)(int);

  // Immediate indexed General Register load/stores
  //static const int Imm6Disp = 16;
  static const int Imm6Disp = 0;
  static const int MaxImm6 = 64;
  static inline bool isImm6_d( int imm ){ return (imm+Imm6Disp) >= 0 && (imm+Imm6Disp) < MaxImm6; }
  //static ImmTestF isImm6_d_test = isImm6_d ; //( int imm ){ return (imm+Imm6Disp) >= 0 && (imm+Imm6Disp) < 64; }
  
  // Immediate and, or
  static inline bool isImm6u( int imm ){ return imm >= 0 && imm < MaxImm6; }

  // Immediate mov, cmp
  static inline bool isImm8s( int imm ){ return imm >= -128 && imm < 128; }
  
  // Immediate add/sub
  static const int MaxSize = 256;
  static inline bool isImm8u( int imm ){ return imm >= 0 && imm < MaxSize; }
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
