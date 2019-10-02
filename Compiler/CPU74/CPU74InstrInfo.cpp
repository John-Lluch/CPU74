//===-- CPU74InstrInfo.cpp - CPU74 Instruction Information --------------===//
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

#include "CPU74InstrInfo.h"
#include "CPU74.h"
#include "CPU74MachineFunctionInfo.h"
#include "CPU74TargetMachine.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/TargetRegistry.h"

using namespace llvm;

#define GET_INSTRINFO_CTOR_DTOR
#include "CPU74GenInstrInfo.inc"

// Pin the vtable to this file.
void CPU74InstrInfo::anchor() {}

CPU74InstrInfo::CPU74InstrInfo( /*CPU74Subtarget &STI*/)
  : CPU74GenInstrInfo(CPU74::CALLSQ_START, CPU74::CALLSQ_END),
    RI() {}




// isLoadFromStackSlot - If the specified machine instruction is a direct
// load from a stack slot, return the virtual or physical register number of
// the destination along with the FrameIndex of the loaded stack slot.  If
// not, return 0.  This predicate must return 0 if the instruction has
// any side effects other than loading from the stack slot.
unsigned CPU74InstrInfo::isLoadFromStackSlot(const MachineInstr &MI, int &FrameIndex) const
{
  unsigned op = MI.getOpcode();
  if ( op == CPU74::MOVqr16_core || op == CPU74::MOVqr8s_core || op == CPU74::MOVqr8z_core )
  {
    if (MI.getOperand(1).isFI() && MI.getOperand(2).isImm() &&
                                    MI.getOperand(2).getImm() == 0)
    {
      FrameIndex = MI.getOperand(1).getIndex();
      return MI.getOperand(0).getReg();
    }
  }
  return 0;
}

// isStoreToStackSlot - If the specified machine instruction is a direct
// store to a stack slot, return the virtual or physical register number of
// the source reg along with the FrameIndex of the loaded stack slot.  If
// not, return 0.  This predicate must return 0 if the instruction has
// any side effects other than storing to the stack slot.
unsigned CPU74InstrInfo::isStoreToStackSlot(const MachineInstr &MI, int &FrameIndex) const
{
  unsigned op = MI.getOpcode();
  if ( op == CPU74::MOVrq16_core || op == CPU74::MOVrq8_core )
  {
    if (MI.getOperand(0).isFI() && MI.getOperand(1).isImm() &&
                                    MI.getOperand(1).getImm() == 0)
    {
      FrameIndex = MI.getOperand(0).getIndex();
      return MI.getOperand(2).getReg();
    }
  }
  return 0;
}


// Generate instructions to store register to the stack

void CPU74InstrInfo::storeRegToStackSlot(MachineBasicBlock &MBB,
    MachineBasicBlock::iterator MI, unsigned SrcReg, bool isKill, int FrameIdx,
    const TargetRegisterClass *RC, const TargetRegisterInfo *TRI) const
{
  DebugLoc DL;
  if (MI != MBB.end()) DL = MI->getDebugLoc();
  
  MachineFunction &MF = *MBB.getParent();
  const MachineFrameInfo &MFI = MF.getFrameInfo();

  MachineMemOperand *MMO = MF.getMachineMemOperand(
      MachinePointerInfo::getFixedStack(MF, FrameIdx), MachineMemOperand::MOStore,
      MFI.getObjectSize(FrameIdx), MFI.getObjectAlignment(FrameIdx));
  
  unsigned opcode = 0;
  if (RC == &CPU74::GR16RegClass ) opcode = CPU74::MOVrq16_core;
  //if (RC == &CPU74::GR16RegClass) opcode = CPU74::MOVrm16;

  assert( opcode && "Cannot store this register to stack slot!");
  
  BuildMI(MBB, MI, DL, get(opcode))
      .addReg(SrcReg, getKillRegState(isKill))
      .addFrameIndex(FrameIdx).addImm(0)
      .addMemOperand(MMO);
}

// Generate instructions to load register from the stack

void CPU74InstrInfo::loadRegFromStackSlot(MachineBasicBlock &MBB,
        MachineBasicBlock::iterator MI, unsigned DestReg, int FrameIdx,
        const TargetRegisterClass *RC, const TargetRegisterInfo *TRI) const
{
  DebugLoc DL;
  if (MI != MBB.end()) DL = MI->getDebugLoc();
  
  MachineFunction &MF = *MBB.getParent();
  const MachineFrameInfo &MFI = MF.getFrameInfo();

  MachineMemOperand *MMO = MF.getMachineMemOperand(
      MachinePointerInfo::getFixedStack(MF, FrameIdx), MachineMemOperand::MOLoad,
      MFI.getObjectSize(FrameIdx), MFI.getObjectAlignment(FrameIdx));
  
  unsigned opcode = 0;
  if (RC == &CPU74::GR16RegClass ) opcode = CPU74::MOVqr16_core;
  //if (RC == &CPU74::GR16RegClass) opcode = CPU74::MOVmr16;
  
  assert( opcode && "Cannot load this register from stack slot!");
  
#ifdef FP_AS_SPILL
    CPU74MachineFunctionInfo *FuncInf = MF.getInfo<CPU74MachineFunctionInfo>();
    if ( !FuncInf->getHasSpills() )
    {
      FuncInf->setHasSpills(true);
      FuncInf->setFirstSpillIndex(FrameIdx);
      // TODO: This might be optimized by determining the most used spill
    }
  
    if ( FuncInf->getHasSpills() && (FuncInf->getFirstSpillIndex() > FrameIdx ) )
      FuncInf->setFirstSpillIndex(FrameIdx);
#endif
  
  BuildMI(MBB, MI, DL, get(opcode))
      .addReg(DestReg, getDefRegState(true))
      .addFrameIndex(FrameIdx).addImm(0)
      .addMemOperand(MMO);
  
}

// generate instruction to copy register to register

void CPU74InstrInfo::copyPhysReg(MachineBasicBlock &MBB,
    MachineBasicBlock::iterator I, const DebugLoc &DL, unsigned DestReg,
    unsigned SrcReg, bool KillSrc) const
{
  if (CPU74::GR16RegClass.contains(DestReg) && CPU74::SSPRegClass.contains(SrcReg))
  {
    BuildMI(MBB, I, DL, get(CPU74::LEAqr16_core), DestReg)
      .addReg(SrcReg, getKillRegState(KillSrc))
      .addImm(0);
    return;
  }
  
  unsigned opcode = 0;
  if (CPU74::GR16RegClass.contains(DestReg, SrcReg))
    opcode = CPU74::MOVrr16;
  
  else if (CPU74::SSPRegClass.contains(DestReg) && CPU74::GR16RegClass.contains(SrcReg))
    opcode = CPU74::MOVrq16;
  
  assert( opcode && "Impossible reg-to-reg copy" );

  BuildMI(MBB, I, DL, get(opcode), DestReg)
      .addReg(SrcReg, getKillRegState(KillSrc));
}

CPU74CC::CondCodes CPU74CC::getOppositeCondition( CPU74CC::CondCodes CondCode )
{
  switch (CondCode)
  {
    default: llvm_unreachable("Unknown condition code");
    case CPU74CC::COND_EQ: return CPU74CC::COND_NE;
    case CPU74CC::COND_NE: return CPU74CC::COND_EQ;
    case CPU74CC::COND_UGE: return CPU74CC::COND_ULT;
    case CPU74CC::COND_ULT: return CPU74CC::COND_UGE;
    case CPU74CC::COND_GE: return CPU74CC::COND_LT;
    case CPU74CC::COND_LT: return CPU74CC::COND_GE;
    
    case CPU74CC::COND_UGT: return CPU74CC::COND_INVALID; // would be CPU74CC::COND_ULE;
    case CPU74CC::COND_GT: return CPU74CC::COND_INVALID; // would be CPU74CC::COND_LE
    case CPU74CC::COND_ULE: return CPU74CC::COND_UGT;
    case CPU74CC::COND_LE: return CPU74CC::COND_GT;
  }
}

bool CPU74InstrInfo::reverseBranchCondition(SmallVectorImpl<MachineOperand> &Cond) const
{
  assert(Cond.size() == 1 && "Invalid Xbranch condition!");

  CPU74CC::CondCodes CondCode = static_cast<CPU74CC::CondCodes>(Cond[0].getImm());
  CondCode = getOppositeCondition(CondCode);
  
  if ( CondCode == CPU74CC::COND_INVALID)
    return true;
  
  Cond[0].setImm(CondCode);
  return false;
}

/// Analyze the branching code at the end of MBB, returning
/// true if it cannot be understood (e.g. it's a switch dispatch or isn't
/// implemented for a target).  Upon success, this returns false and returns
/// with the following information in various cases:
///
/// 1. If this block ends with no branches (it just falls through to its succ)
///    just return false, leaving TBB/FBB null.
/// 2. If this block ends with only an unconditional branch, it sets TBB to be
///    the destination block.
/// 3. If this block ends with a conditional branch and it falls through to a
///    successor block, it sets TBB to be the branch destination block and a
///    list of operands that evaluate the condition. These operands can be
///    passed to other TargetInstrInfo methods to create new branches.
/// 4. If this block ends with a conditional branch followed by an
///    unconditional branch, it returns the 'true' destination in TBB, the
///    'false' destination in FBB, and a list of operands that evaluate the
///    condition.  These operands can be passed to other TargetInstrInfo
///    methods to create new branches.
///
/// Note that removeBranch and insertBranch must be implemented to support
/// cases where this method returns success.
///
/// If AllowModify is true, then this routine is allowed to modify the basic
/// block (e.g. delete instructions after the unconditional branch).
///
/// The CFG information in MBB.Predecessors and MBB.Successors must be valid
/// before calling this function.
bool CPU74InstrInfo::analyzeBranch(MachineBasicBlock &MBB,
                                    MachineBasicBlock *&TBB,
                                    MachineBasicBlock *&FBB,
                                    SmallVectorImpl<MachineOperand> &Cond,
                                    bool AllowModify) const {
  // Start from the bottom of the block and work up, examining the
  // terminator instructions.
  MachineBasicBlock::iterator I = MBB.end();
  while (I != MBB.begin()) {
    --I;
    //I->dump();     // JLZ // aqui
    if (I->isDebugInstr())
      continue;
    
    // Working from the bottom, when we see a non-terminator
    // instruction, we're done.
    if (!isUnpredicatedTerminator(*I))
      break;

    // A terminator that isn't a branch can't easily be handled
    // by this analysis.
    if (!I->isBranch())
      return true;
    
    // Cannot handle indirect branches.
    if (I->getOpcode() == CPU74::JMPreg)
      return true;

    // Handle unconditional branches.
    if (I->getOpcode() == CPU74::JMP_core) {
      if (!AllowModify) {
        TBB = I->getOperand(0).getMBB();
        continue;
      }

      // If the block has any instructions after a JMP, delete them.
      while (std::next(I) != MBB.end())
        std::next(I)->eraseFromParent();
      Cond.clear();
      FBB = nullptr;

      // Delete the JMP if it's equivalent to a fall-through.
      if (MBB.isLayoutSuccessor(I->getOperand(0).getMBB())) {
        TBB = nullptr;
        I->eraseFromParent();
        I = MBB.end();
        continue;
      }

      // TBB is used to indicate the unconditinal destination.
      TBB = I->getOperand(0).getMBB();
      continue;
    }

    // Handle conditional branches.
    assert(I->getOpcode() == CPU74::BRCC_core && "Invalid conditional branch");
    CPU74CC::CondCodes BranchCode =
      static_cast<CPU74CC::CondCodes>(I->getOperand(1).getImm());
    if (BranchCode == CPU74CC::COND_INVALID)
      return true;  // Can't handle weird stuff.

    // Working from the bottom, handle the first conditional branch.
    if (Cond.empty()) {
      FBB = TBB;
      TBB = I->getOperand(0).getMBB();
      Cond.push_back(MachineOperand::CreateImm(BranchCode));
      continue;
    }

    // Handle subsequent conditional branches. Only handle the case where all
    // conditional branches branch to the same destination.
    assert(Cond.size() == 1);
    assert(TBB);

    // Only handle the case where all conditional branches branch to
    // the same destination.
    if (TBB != I->getOperand(0).getMBB())
      return true;

    CPU74CC::CondCodes OldBranchCode = (CPU74CC::CondCodes)Cond[0].getImm();
    // If the conditions are the same, we can leave them alone.
    if (OldBranchCode == BranchCode)
      continue;
  
    return true;
  }

  return false;
}

/// Insert branch code into the end of the specified MachineBasicBlock. The
/// operands to this method are the same as those returned by AnalyzeBranch.
/// This is only invoked in cases where AnalyzeBranch returns success. It
/// returns the number of instructions inserted. If \p BytesAdded is non-null,
/// report the change in code size from the added instructions.
///
/// It is also invoked by tail merging to add unconditional branches in
/// cases where AnalyzeBranch doesn't apply because there was no original
/// branch to analyze.  At least this much must be implemented, else tail
/// merging needs to be disabled.
///
/// The CFG information in MBB.Predecessors and MBB.Successors must be valid
/// before calling this function.
unsigned CPU74InstrInfo::insertBranch(MachineBasicBlock &MBB,
                                       MachineBasicBlock *TBB,
                                       MachineBasicBlock *FBB,
                                       ArrayRef<MachineOperand> Cond,
                                       const DebugLoc &DL,
                                       int *BytesAdded) const {
  // Shouldn't be a fall through.
  assert(TBB && "insertBranch must not be told to insert a fallthrough");
  assert((Cond.size() == 1 || Cond.size() == 0) &&
         "CPU74 branch conditions have one component!");
  assert(!BytesAdded && "code size not handled");

  if (Cond.empty()) {
    // Unconditional branch?
    assert(!FBB && "Unconditional branch with multiple successors!");
    BuildMI(&MBB, DL, get(CPU74::JMP_core)).addMBB(TBB);
    return 1;
  }

  // Conditional branch.
  unsigned Count = 0;
  BuildMI(&MBB, DL, get(CPU74::BRCC_core)).addMBB(TBB).addImm(Cond[0].getImm());
  ++Count;

  if (FBB) {
    // Two-way Conditional branch. Insert the second branch.
    BuildMI(&MBB, DL, get(CPU74::JMP_core)).addMBB(FBB);
    ++Count;
  }
  return Count;
}

/// Remove the branching code at the end of the specific MBB.
/// This is only invoked in cases where AnalyzeBranch returns success. It
/// returns the number of instructions that were removed.
/// If \p BytesRemoved is non-null, report the change in code size from the
/// removed instructions.
unsigned CPU74InstrInfo::removeBranch(MachineBasicBlock &MBB,
                                       int *BytesRemoved) const {
  assert(!BytesRemoved && "code size not handled");

  MachineBasicBlock::iterator I = MBB.end();
  unsigned Count = 0;

  while (I != MBB.begin()) {
    --I;
    if (I->isDebugInstr())
      continue;

    if (I->getOpcode() != CPU74::JMP_core &&
        I->getOpcode() != CPU74::BRCC_core &&
        I->getOpcode() != CPU74::JMPreg)
      break;
      
    // Remove the branch.
    I->eraseFromParent();
    I = MBB.end();
    ++Count;
  }

  return Count;
}

/// GetInstSize - Return the number of bytes of code the specified
/// instruction may be.  This returns the maximum number of bytes.
unsigned CPU74InstrInfo::getInstSizeInBytes(const MachineInstr &MI) const
{
  const MCInstrDesc &Desc = MI.getDesc();
  return Desc.getSize();
}

