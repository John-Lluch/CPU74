//=== CPU74MachineFunctionInfo.h - CPU74 machine function info -*- C++ -*-==//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file declares CPU74-specific per-machine-function information.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_CPU74_CPU74MACHINEFUNCTIONINFO_H
#define LLVM_LIB_TARGET_CPU74_CPU74MACHINEFUNCTIONINFO_H

#include "llvm/CodeGen/MachineFunction.h"

namespace llvm {

/// CPU74MachineFunctionInfo - This class is derived from MachineFunction and
/// contains private CPU74 target-specific information for each MachineFunction.
class CPU74MachineFunctionInfo : public MachineFunctionInfo {
  virtual void anchor();

  /// CalleeSavedFrameSize - Size of the callee-saved register portion of the
  /// stack frame in bytes.
  unsigned CalleeSavedFrameSize;

  /// ReturnAddrIndex - FrameIndex for return slot.
  int ReturnAddrIndex;

  /// VarArgsFrameIndex - FrameIndex for start of varargs area.
  int VarArgsFrameIndex;

  /// SRetReturnReg - Some subtargets require that sret lowering includes
  /// returning the value of the returned struct in a register. This field
  /// holds the virtual register into which the sret argument is passed.
  unsigned SRetReturnReg;
  
  /// Estimates of frame sizes for prolog/epilog
  unsigned estimatedFrameSize;
  unsigned argumentsSize;

public:
  CPU74MachineFunctionInfo() : CalleeSavedFrameSize(0),
                              ReturnAddrIndex(0), SRetReturnReg(0),
                              estimatedFrameSize(0), argumentsSize(0)
                              {}

  explicit CPU74MachineFunctionInfo(MachineFunction &MF)
       : CalleeSavedFrameSize(0), //ReplacedSpillFrameSize(0),
         ReturnAddrIndex(0), SRetReturnReg(0),
         estimatedFrameSize(0), argumentsSize(0)
         {}

  unsigned getCalleeSavedFrameSize() const { return CalleeSavedFrameSize; }
  void setCalleeSavedFrameSize(unsigned bytes) { CalleeSavedFrameSize = bytes; }
  
//  unsigned getReplacedSpillsFrameSize() const { return ReplacedSpillFrameSize; }
//  void setReplacedSpillsFrameSize(unsigned bytes) { ReplacedSpillFrameSize = bytes; }

  unsigned getSRetReturnReg() const { return SRetReturnReg; }
  void setSRetReturnReg(unsigned Reg) { SRetReturnReg = Reg; }

  int getRAIndex() const { return ReturnAddrIndex; }
  void setRAIndex(int Index) { ReturnAddrIndex = Index; }

  int getVarArgsFrameIndex() const { return VarArgsFrameIndex; }
  void setVarArgsFrameIndex(int Index) { VarArgsFrameIndex = Index; }
  
  // We use this to compute that the function can not cheapily handle some offsets
  // with the SP immediate instructions alone and thus requires the
  // implementation of a FP. Return true if FP was determined to be required.
  // This is updated after DAG iSel just in time for reserving physical registers
  // and before RA. It does not account for any spills that
  // might be produced during RA,
  unsigned getEstimatedFrameSize() const { return estimatedFrameSize; }
  void setEstimatedFrameSize( unsigned newSize ) { estimatedFrameSize = newSize; }
  unsigned getArgumentsSize() const { return argumentsSize; }
  void setArgumentsSize( unsigned newSize ) { argumentsSize = newSize; }
};

} // End llvm namespace

#endif
