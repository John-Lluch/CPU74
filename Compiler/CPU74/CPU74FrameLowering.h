//==- CPU74FrameLowering.h - Define frame lowering for CPU74 --*- C++ -*--==//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
//
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_CPU74_CPU74FRAMELOWERING_H
#define LLVM_LIB_TARGET_CPU74_CPU74FRAMELOWERING_H

#include "CPU74.h"
#include "llvm/CodeGen/TargetFrameLowering.h"

namespace llvm {
class CPU74FrameLowering : public TargetFrameLowering {
protected:

public:
  explicit CPU74FrameLowering()
      : TargetFrameLowering(TargetFrameLowering::StackGrowsDown, 2, -2, 2) {}

  /// emitProlog/emitEpilog - These methods insert prolog and epilog code into
  /// the function.
  void emitPrologue(MachineFunction &MF, MachineBasicBlock &MBB) const override;
  void emitEpilogue(MachineFunction &MF, MachineBasicBlock &MBB) const override;

  MachineBasicBlock::iterator
  eliminateCallFramePseudoInstr(MachineFunction &MF, MachineBasicBlock &MBB,
                                MachineBasicBlock::iterator I) const override;

  bool spillCalleeSavedRegisters(MachineBasicBlock &MBB,
                                 MachineBasicBlock::iterator MI,
                                 const std::vector<CalleeSavedInfo> &CSI,
                                 const TargetRegisterInfo *TRI) const override;
  bool restoreCalleeSavedRegisters(MachineBasicBlock &MBB,
                                  MachineBasicBlock::iterator MI,
                                  std::vector<CalleeSavedInfo> &CSI,
                                  const TargetRegisterInfo *TRI) const override;

  bool hasFP(const MachineFunction &MF) const override;
  bool hasReservedCallFrame(const MachineFunction &MF) const override;
  
  void processFunctionBeforeFrameFinalized(MachineFunction &MF,
                                     RegScavenger *RS = nullptr) const override;
  
public:
  bool hasBasePointer(const MachineFunction &MF) const;

private:
  int estimateMaxOffset(const MachineFunction &MF, RegScavenger *RS) const;
  
};

} // End llvm namespace

#endif
