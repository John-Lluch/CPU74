//===-- CPU74InstrInfo.h - CPU74 Instruction Information ------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the CPU74 implementation of the TargetInstrInfo class.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_CPU74_CPU74INSTRINFO_H
#define LLVM_LIB_TARGET_CPU74_CPU74INSTRINFO_H

#include "CPU74RegisterInfo.h"
#include "llvm/CodeGen/TargetInstrInfo.h"

#define GET_INSTRINFO_HEADER
#include "CPU74GenInstrInfo.inc"

namespace llvm {

//class CPU74Subtarget;

/// CPU74II - This namespace holds all of the target specific flags that
/// instruction info tracks.
///
namespace CPU74II {
  enum {
    SizeShift   = 2,
    SizeMask    = 7 << SizeShift,

    SizeUnknown = 0 << SizeShift,
    SizeSpecial = 1 << SizeShift,
    Size2Bytes  = 2 << SizeShift,
    Size4Bytes  = 3 << SizeShift,
    Size6Bytes  = 4 << SizeShift
  };
}


namespace CPU74CC
{
  // CPU74 specific condition code.
  enum CondCodes
  {
    // fully supported codes
    COND_EQ =  0,
    COND_NE =  1,
    COND_UGE = 2,
    COND_ULT = 3,
    COND_GE =  4,
    COND_LT =  5,
    
    COND_UGT = 6,
    COND_GT =  7,

    // partially unsuported codes
    COND_ULE = 8,
    COND_LE =  9,

    COND_INVALID = -1
  };
  
CondCodes getOppositeCondition( CondCodes CC );
}



class CPU74InstrInfo : public CPU74GenInstrInfo
{
  const CPU74RegisterInfo RI;
  virtual void anchor();
public:
  explicit CPU74InstrInfo(/*jlz CPU74Subtarget &STI*/);

  /// getRegisterInfo - TargetInstrInfo is a superset of MRegister info.  As
  /// such, whenever a client has an instance of instruction info, it should
  /// always be able to get register info as well (through this method).
  ///
  const TargetRegisterInfo &getRegisterInfo() const { return RI; }

  unsigned isLoadFromStackSlot(const MachineInstr &MI,
                                             int &FrameIndex) const override;
  
  unsigned isStoreToStackSlot(const MachineInstr &MI,
                                            int &FrameIndex) const override;

  void copyPhysReg(MachineBasicBlock &MBB, MachineBasicBlock::iterator I,
                   const DebugLoc &DL, unsigned DestReg, unsigned SrcReg,
                   bool KillSrc) const override;

  void storeRegToStackSlot(MachineBasicBlock &MBB,
                           MachineBasicBlock::iterator MI,
                           unsigned SrcReg, bool isKill,
                           int FrameIndex,
                           const TargetRegisterClass *RC,
                           const TargetRegisterInfo *TRI) const override;
  void loadRegFromStackSlot(MachineBasicBlock &MBB,
                            MachineBasicBlock::iterator MI,
                            unsigned DestReg, int FrameIdx,
                            const TargetRegisterClass *RC,
                            const TargetRegisterInfo *TRI) const override;

  unsigned getInstSizeInBytes(const MachineInstr &MI) const override;

  // Branch folding goodness
  bool reverseBranchCondition(SmallVectorImpl<MachineOperand> &Cond) const override;
  bool analyzeBranch(MachineBasicBlock &MBB, MachineBasicBlock *&TBB,
                     MachineBasicBlock *&FBB,
                     SmallVectorImpl<MachineOperand> &Cond,
                     bool AllowModify) const override;

  unsigned removeBranch(MachineBasicBlock &MBB,
                        int *BytesRemoved = nullptr) const override;
  unsigned insertBranch(MachineBasicBlock &MBB, MachineBasicBlock *TBB,
                        MachineBasicBlock *FBB, ArrayRef<MachineOperand> Cond,
                        const DebugLoc &DL,
                        int *BytesAdded = nullptr) const override;

};

}

#endif
