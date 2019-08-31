//===-- CPU74RegisterInfo.h - CPU74 Register Information Impl -*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the CPU74 implementation of the MRegisterInfo class.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_CPU74_CPU74REGISTERINFO_H
#define LLVM_LIB_TARGET_CPU74_CPU74REGISTERINFO_H

#include "llvm/CodeGen/TargetRegisterInfo.h"

#define GET_REGINFO_HEADER
#include "CPU74GenRegisterInfo.inc"

namespace llvm {

struct CPU74RegisterInfo : public CPU74GenRegisterInfo
{
public:
  CPU74RegisterInfo();

  /// Code Generation virtual methods...

  const MCPhysReg* getCalleeSavedRegs(const MachineFunction *MF) const override;
  const uint32_t*  getCallPreservedMask(const MachineFunction &MF, CallingConv::ID CC) const override;
  BitVector  getReservedRegs(const MachineFunction &MF) const override;
  const TargetRegisterClass*  getPointerRegClass(const MachineFunction &MF, unsigned Kind = 0) const override;
  void  eliminateFrameIndex(MachineBasicBlock::iterator II, int SPAdj, unsigned FIOperandNum, RegScavenger *RS = nullptr) const override;

  // Debug information queries.
  Register getFrameRegister(const MachineFunction &MF) const override; 
  
  /// Code Generation virtual methods...
  bool requiresRegisterScavenging(const MachineFunction &MF) const override;
  bool trackLivenessAfterRegAlloc(const MachineFunction &MF) const override;
  bool requiresFrameIndexScavenging(const MachineFunction &MF) const override;
  bool hasReservedSpillSlot(const MachineFunction &MF, unsigned Reg, int &FrameIdx) const override;
  bool requiresFrameIndexReplacementScavenging(const MachineFunction &MF) const override;
  bool requiresVirtualBaseRegisters(const MachineFunction &MF) const override;
  

};

} // end namespace llvm

#endif
