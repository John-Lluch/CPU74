//===-- CPU74FrameLowering.cpp - CPU74 Frame Information ----------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the CPU74 implementation of TargetFrameLowering class.
//
//===----------------------------------------------------------------------===//

#include "CPU74FrameLowering.h"
#include "CPU74InstrInfo.h"
#include "CPU74MachineFunctionInfo.h"
#include "CPU74Subtarget.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineModuleInfo.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/Function.h"
#include "llvm/Target/TargetOptions.h"

using namespace llvm;

/*
Stack frame models

  Stack Frame (SP based frame)          Stack Frame (FP based frame)

       |              |                     |              |
       |--------------|                     |--------------|
       |              |                     |              |
       |  Arguments   |                     |  Arguments   |
       |              |                     |              |
       |--------------|                     |--------------|
       | Return addr  |                     | Return addr  |
SP(*)  |--------------|              SP(*)  |--------------|
       |              |                     |  Saved FP    |
       |  Saved Regs  |              FP(1)  |--------------|
       |--------------|                     |              |
       |              |                     |  Saved Regs  |
       |  Local Vars  |                     |--------------|
       |              |                     |              |
       |--------------|                     |  Local Vars  |
       |              |                     |              |
       |   Spills     |                     |--------------|
SP(1') |--------------|                     |              |
       |              |                     |   Spills     |
       |  Call Args   |      SP(1'), BP(1)  |--------------|
       |              |                     |              |
SP(1)  |--------------|                     |  Call Args   |
                                            |              |
                                     SP(1)  |--------------|


The above represents the possible Stack frame models

SP(*) : Address pointed by SP at the function entry

With reserved call frame:

SP(1) : Address pointed by SP at function prologue completion
FP(1) : Address pointed by FP at function prologue completion

Without reserved call frame:

SP(1') : Address pointed by SP at function prologue completion
FP(1) : Address pointed by FP at function prologue completion

With Base Pointer

BP(1) : Address pointed by the Base Pointer

For CPU74 we do not use a separate register as the BP. Instead, we
chose a role for Register R6 on any given function, either as FP or BP depending
on the following rules:

- If the estimated stack size fits in the immediate load/store offset, use simple SP stack
based frame, R6 remains free for general purpose use. Otherwise use FP based frame.

- If the max size of the Call Args, plus the size of the arguments is above the immediate
load/store offset, use FP based frame with Register R6 as the BP.

- Functions with variable sized object always use the FP model

- Currently, the FP based frame is always associated with the BP role

*/

// Returns whether the estimated frame size is large
static bool hasBigOffsets( const MachineFunction &MF )
{
  const CPU74MachineFunctionInfo *FuncInf = MF.getInfo<CPU74MachineFunctionInfo>();
  return FuncInf->getEstimatedFrameSize() >= CPU74Imm::MaxImm6;
}

static bool hasBigCallFrame( const MachineFunction &MF )
{
  const CPU74MachineFunctionInfo *FuncInf = MF.getInfo<CPU74MachineFunctionInfo>();
  const MachineFrameInfo &MFI = MF.getFrameInfo();
  
  // The ARM target choses to make the switch to non-reserved call frames when
  // the maxCallFrameSize is half the immediate, see Thumb1FrameLowering::hasReservedCallFrame,
  // and ARMFrameLowering::hasReservedCallFrame.
  // On the other hand, the MIPS16 takes the full immediate range,
  // see Mips16FrameLowering::hasReservedCallFrame.
  // For the CPU74 we chose something in the middle by discounting the functon arguments
  // size. The reasoning for this, is that we do not have negative small offsets, therefore
  // we favour reaching the arguments with positive offsets
  return MFI.getMaxCallFrameSize() + FuncInf->getArgumentsSize() >= CPU74Imm::MaxImm6;
}

// Return true if the specified function must have a dedicated frame
// pointer register. This happens if the function meets any of the following
// conditions:
//  - there are SP offsets that are too large for immediate SP load/stores
//  - the function has variable sized objects
//  - there's a call to llvm.frameaddress
// Note that exact offsets are not available for Epilog/Prolog insertion
// until after Register Allocation. Therefore, we make estimates at the
// end of dag iSel. See CPU74TargetLowering::finalizeLowering
bool CPU74FrameLowering::hasFP(const MachineFunction &MF) const
{
  const MachineFrameInfo &MFI = MF.getFrameInfo();

   // ABI-required frame pointer.
// if (MF.getTarget().Options.DisableFramePointerElim(MF))
//    return true;

  return (/*RegInfo->needsStackRealignment(MF) ||*/
          MFI.hasVarSizedObjects() ||
          hasBigOffsets(MF) ||
          hasBigCallFrame(MF) ||
          MFI.isFrameAddressTaken() );
}

bool CPU74FrameLowering::hasReservedCallFrame(const MachineFunction &MF) const
{
  const MachineFrameInfo &MFI = MF.getFrameInfo();
  // It's not always a good idea to include the call frame as part of the
  // stack frame. CPU74 has small immediate offset to
  // address the stack frame. So a large call frame can cause poor codegen
  // and may even make it impossible to scavenge a register.

  if ( hasBigCallFrame(MF) )
    return false;
  
  return !MFI.hasVarSizedObjects();
}


//bool CPU74FrameLowering::hasBasePointer(const MachineFunction &MF) const
//{
//  // If call frames are big, force the use of a base pointer
//  // This in turn implies that we do NOT have reservedCallFrame
//  return hasBigCallFrame(MF);
//}


void CPU74FrameLowering::emitPrologue(MachineFunction &MF, MachineBasicBlock &MBB) const
{
  assert(&MF.front() == &MBB && "Shrink-wrapping not yet supported");
  
  const MachineFrameInfo &MFI = MF.getFrameInfo();
  CPU74MachineFunctionInfo *FuncInf = MF.getInfo<CPU74MachineFunctionInfo>();
  const TargetRegisterInfo *RegInfo = MF.getSubtarget().getRegisterInfo();
  
  const CPU74InstrInfo &TII = *static_cast<const CPU74InstrInfo *>(MF.getSubtarget().getInstrInfo());

  MachineBasicBlock::iterator MBBI = MBB.begin();
  DebugLoc dl = MBBI != MBB.end() ? MBBI->getDebugLoc() : DebugLoc();
  
  bool usesFP = hasFP(MF);
  bool usesBP = !hasReservedCallFrame(MF); // this also implies usesFP

#ifdef FP_AS_SPILL
  bool hasResFr = hasReservedCallFrame(MF);
  if (!usesFP && hasResFr)
  {
    // if we will be using R6 as a spill, we should discard such spill from the
    // stack size (see CPU74RegisterInfo::eliminateFrameIndex)
    if ( FuncInf->getHasSpills() )
      FuncInf->setReplacedSpillsFrameSize( 2 );
  }
#endif

  // Get the number of bytes to allocate from the FrameInfo.
  uint64_t FrameSize = MFI.getStackSize() - FuncInf->getCalleeSavedFrameSize();
  
  //if ( usesFP || FuncInf->getHasSpills() )
#ifdef FP_AS_SPILL
  if ( usesFP || FuncInf->getReplacedSpillsFrameSize() > 0 )
#else
  if ( usesFP )
#endif
  {
    // Push FP into the stack
    BuildMI(MBB, MBBI, dl, TII.get(CPU74::PUSH16r)).addReg(CPU74::R6, RegState::Kill);
  }

  if ( usesFP && !usesBP )
  {
    // Update FP with the new base value...
    BuildMI(MBB, MBBI, dl, TII.get(CPU74::MOVrr16), CPU74::R6)
      .addReg(CPU74::SP);
  }

  if ( usesFP )
  {
    // Mark the FramePtr as live-in in every block except the entry.
    for (MachineFunction::iterator I = std::next(MF.begin()), E = MF.end(); I != E; ++I)
      I->addLiveIn(CPU74::R6);
  }

  // Skip down the callee-saved push instructions.
  while (MBBI != MBB.end() && (MBBI->getOpcode() == CPU74::PUSH16r))
    ++MBBI;

  if (MBBI != MBB.end())
    dl = MBBI->getDebugLoc();


  // FrameSize is non zero and fits in immediate sub instruction
  if ( FrameSize && FrameSize < CPU74Imm::MaxSize )
  {
    MachineInstr *MI = BuildMI(MBB, MBBI, dl, TII.get(CPU74::SUBkr16), CPU74::SP)
      .addReg(CPU74::SP)
      .addImm(FrameSize);
    MI->getOperand(3).setIsDead(); // The SR implicit def is dead.
  }
  
  // Otherwise sub instruction must be generated through 'lea' instruction
  // We load the constant in an intermediate register and use the SUBrs16 instruction
  else if ( FrameSize )
  {
    unsigned VReg = MF.getRegInfo().createVirtualRegister(&CPU74::GR16RegClass);
    BuildMI(MBB, MBBI, dl, TII.get(CPU74::LEAKr16), VReg)
      .addImm(FrameSize);

    MachineInstr *MI = BuildMI(MBB, MBBI, dl, TII.get(CPU74::SUBrrr16), CPU74::SP)
      .addReg(CPU74::SP)
      .addReg(VReg);
    MI->getOperand(3).setIsDead(); // The SR implicit def is dead.
  }
  
  // If we need a base pointer, set it up here. It's whatever the value
  // of the stack pointer is at this point. Any variable size objects
  // will be allocated after this, so we can still use the base pointer
  // to reference locals.
  if ( usesFP && usesBP )
  {
    // Update FP with the new base value...
    BuildMI(MBB, MBBI, dl, TII.get(CPU74::MOVrr16), CPU74::R6)
      .addReg(CPU74::SP);
  }
}


//void CPU74FrameLowering::emitPrologue(MachineFunction &MF, MachineBasicBlock &MBB) const
//{
//  assert(&MF.front() == &MBB && "Shrink-wrapping not yet supported");
//
//  const MachineFrameInfo &MFI = MF.getFrameInfo();
//  CPU74MachineFunctionInfo *FuncInf = MF.getInfo<CPU74MachineFunctionInfo>();
//
//  // Calculate for the incomming function whether big offsets will
//  // require the use of a FP.
//
//  int maxOffset = MFI.getStackSize() - FuncInf->getCalleeSavedFrameSize();
//  int maxFrame = MFI.getMaxCallFrameSize();  // TODO should we add this??
//
//  if ( maxOffset < CPU74Imm::MaxSize )
//  {
//    int beg = MFI.getObjectIndexBegin();
//
//    // If there are negative indexes (arguments) account for the saved PC
//    // and count back the callee saved registers
//    if ( beg < 0 )
//      maxOffset += 2 + FuncInf->getCalleeSavedFrameSize();
//
//    // Check for argument sizes and add them to the max offset
//    for ( int i = beg ; i < 0 && maxOffset < CPU74Imm::MaxSize ; i++ )
//      maxOffset += MFI.getObjectSize(i);
//  }
//
//  // Set the condition to account in that we will need FP
//  FuncInf->setHasBigOffsets( !(maxOffset < CPU74Imm::MaxSize) );
//
//  const CPU74InstrInfo &TII = *static_cast<const CPU74InstrInfo *>(MF.getSubtarget().getInstrInfo());
//
//  MachineBasicBlock::iterator MBBI = MBB.begin();
//  DebugLoc DL = MBBI != MBB.end() ? MBBI->getDebugLoc() : DebugLoc();
//
//  bool usesFP = hasFP(MF);
//  bool hasResFr = hasReservedCallFrame(MF);
//  if (1 && !usesFP && hasResFr)
//  {
//    // if we will be using R7 as a spill, we should discard such spill from the
//    // stack size (see CPU74RegisterInfo::eliminateFrameIndex)
//    if ( FuncInf->getHasSpills() && FuncInf->getFirstSpillIndex() == 0 )
//      FuncInf->setReplacedSpillsFrameSize( 2 );
//  }
//
//  // Get the number of bytes to allocate from the FrameInfo.
//  uint64_t FrameSize = MFI.getStackSize() - FuncInf->getCalleeSavedFrameSize() - FuncInf->getReplacedSpillsFrameSize();
//
//  if (usesFP || FuncInf->getHasSpills())
//  {
//    // Save FP into the appropriate stack slot...
//    BuildMI(MBB, MBBI, DL, TII.get(CPU74::PUSH16r)).addReg(CPU74::R7, RegState::Kill);
//  }
//
//  if (usesFP)
//  {
//    // Update FP with the new base value...
//    BuildMI(MBB, MBBI, DL, TII.get(CPU74::MOVsr16), CPU74::R7).addReg(CPU74::SP);    // TODO can we reverse this
//
//    // Mark the FramePtr as live-in in every block except the entry.
//    for (MachineFunction::iterator I = std::next(MF.begin()), E = MF.end(); I != E; ++I)
//      I->addLiveIn(CPU74::R7);
//  }
//
//  // Skip down the callee-saved push instructions.
//  while (MBBI != MBB.end() && (MBBI->getOpcode() == CPU74::PUSH16r))
//    ++MBBI;
//
//  if (MBBI != MBB.end())
//    DL = MBBI->getDebugLoc();
//
//
//  // FrameSize is non zero and fits in immediate instruction
//  if ( FrameSize && FrameSize < CPU74Imm::MaxSize )
//  {
//    MachineInstr *MI = BuildMI(MBB, MBBI, DL, TII.get(CPU74::SUBks16), CPU74::SP).addReg(CPU74::SP).addImm(FrameSize);
//    MI->getOperand(3).setIsDead(); // The SR implicit def is dead.
//  }
//
//  // Sub instruction must be generated through intermediate register
//  // We load the constant in an intermediate register and use the SUBrs16 instruction
//  else if ( FrameSize )
//  {
////    unsigned VReg = MF.getRegInfo().createVirtualRegister(&CPU74::GR16RegClass);
////    BuildMI(MBB, MBBI, DL, TII.get(CPU74::MOVKr16), VReg)
////      .addImm(-FrameSize);
////
////    MachineInstr *MI = BuildMI(MBB, MBBI, DL, TII.get(CPU74::ADDrs16), CPU74::SP).addReg(CPU74::SP).addReg(VReg);
////    MI->getOperand(3).setIsDead(); // The SR implicit def is dead.
//
//    unsigned VReg = MF.getRegInfo().createVirtualRegister(&CPU74::GR16RegClass);
//    BuildMI(MBB, MBBI, DL, TII.get(CPU74::MOVKr16), VReg)
//      .addImm(FrameSize);
//
//    MachineInstr *MI = BuildMI(MBB, MBBI, DL, TII.get(CPU74::SUBrs16), CPU74::SP).addReg(CPU74::SP).addReg(VReg);
//    MI->getOperand(3).setIsDead(); // The SR implicit def is dead.
//
//  }
//}

void CPU74FrameLowering::emitEpilogue(MachineFunction &MF, MachineBasicBlock &MBB) const
{
  const MachineFrameInfo &MFI = MF.getFrameInfo();
  CPU74MachineFunctionInfo *FuncInf = MF.getInfo<CPU74MachineFunctionInfo>();
  const CPU74InstrInfo &TII = *static_cast<const CPU74InstrInfo *>(MF.getSubtarget().getInstrInfo());

  MachineBasicBlock::iterator MBBI = MBB.getLastNonDebugInstr();
  unsigned RetOpcode = MBBI->getOpcode();
  DebugLoc DL = MBBI->getDebugLoc();

  switch (RetOpcode)
  {
    case CPU74::RET:
    case CPU74::RETI: break;  // These are ok
    default:
      llvm_unreachable("Can only insert epilog into returning blocks");
  }

  bool usesFP = hasFP(MF);
  bool usesBP = !hasReservedCallFrame(MF);  // this also implies usesFP

  // Get the number of bytes to allocate from the FrameInfo
  uint64_t FrameSize = MFI.getStackSize() - FuncInf->getCalleeSavedFrameSize(); //- FuncInf->getReplacedSpillsFrameSize();;
  
#ifdef FP_AS_SPILL
  bool hasResFr = hasReservedCallFrame(MF);
  if ( usesFP || FuncInf->getReplacedSpillsFrameSize() > 0 )
#else
  if ( usesFP )
#endif
  {
    // Pop FP, that's the last instruction
    BuildMI(MBB, MBBI, DL, TII.get(CPU74::POP16r), CPU74::R6);
  }

  // Skip up the callee-saved pop instructions.
  while (MBBI != MBB.begin())
  {
    MachineBasicBlock::iterator PI = std::prev(MBBI);
    if (PI->getOpcode() != CPU74::POP16r && !PI->isTerminator()) break;
    --MBBI;
  }
  
  DL = MBBI->getDebugLoc();
  
  // TO DO
  // Optimize stack pointer adjustment by removing
  // add SP, #imm, SP  created by non reserved frames
  
  // If it has variable sized objects just restore the stack pointer from it
  if (MFI.hasVarSizedObjects())
  {
      // TODO We could optimize stack pointer adjustment by removing
      // any previous add SP, #imm, SP created by call end sequences
  
    BuildMI(MBB, MBBI, DL, TII.get(CPU74::MOVrr16), CPU74::SP)
      .addReg(CPU74::R6);
  
    // If we are not using the BP the saved callee registers were pushed after
    // the SP save, so we need to decrement the SP back for this to work
    // NOTE: This should never happen with the current implementation
    // because we always use the BP for non-reserved call frames, thus
    // hasVarSizedObjects() always imply usesBP == true
    if ( !usesBP )
    {
      uint64_t savedFrame = FuncInf->getCalleeSavedFrameSize();
      if (savedFrame > 0)
      {
        MachineInstr *MI = BuildMI(MBB, MBBI, DL, TII.get(CPU74::SUBkr16), CPU74::SP)
          .addReg(CPU74::SP)
          .addImm(savedFrame);
        MI->getOperand(3).setIsDead(); // The SR implicit def is dead.
      }
      // return now, as we are done with this
      return;
    }
  }
  
  // Adjust stack pointer back: SP += numbytes
  // FrameSize is non zero and fits in immediate instruction
  //   TODO We could optimize stack pointer adjustment by consolidating
  //   add SP, #imm, SP  created by non reserved frame calls
  if ( FrameSize && FrameSize < CPU74Imm::MaxSize )
  {
    MachineInstr *MI = BuildMI(MBB, MBBI, DL, TII.get(CPU74::ADDkr16), CPU74::SP)
      .addReg(CPU74::SP)
      .addImm(FrameSize);
    MI->getOperand(3).setIsDead(); // The SR implicit def is dead.
  }
  
  // Add instruction must be generated through 'lea' instruction
  else if ( FrameSize )
  {
    unsigned VReg = MF.getRegInfo().createVirtualRegister(&CPU74::GR16RegClass);
    BuildMI(MBB, MBBI, DL, TII.get(CPU74::LEAKr16), VReg)
      .addImm(FrameSize);
    
    MachineInstr *MI = BuildMI(MBB, MBBI, DL, TII.get(CPU74::ADDrrr16), CPU74::SP)
      .addReg(CPU74::SP)
      .addReg(VReg);
    MI->getOperand(3).setIsDead(); // The SR implicit def is dead.
  }
}


//void CPU74FrameLowering::emitEpilogue(MachineFunction &MF, MachineBasicBlock &MBB) const
//{
//  const MachineFrameInfo &MFI = MF.getFrameInfo();
//  CPU74MachineFunctionInfo *FuncInf = MF.getInfo<CPU74MachineFunctionInfo>();
//  const CPU74InstrInfo &TII = *static_cast<const CPU74InstrInfo *>(MF.getSubtarget().getInstrInfo());
//
//  MachineBasicBlock::iterator MBBI = MBB.getLastNonDebugInstr();
//  unsigned RetOpcode = MBBI->getOpcode();
//  DebugLoc DL = MBBI->getDebugLoc();
//
//  switch (RetOpcode)
//  {
//    case CPU74::RET:
//    case CPU74::RETI: break;  // These are ok
//    default:
//      llvm_unreachable("Can only insert epilog into returning blocks");
//  }
//
//  // Get the number of bytes to allocate from the FrameInfo
//  uint64_t FrameSize = MFI.getStackSize() - FuncInf->getCalleeSavedFrameSize() ;
//
//  if (hasFP(MF) )
//  {
//    // Pop FP, that's the last instruction
//    BuildMI(MBB, MBBI, DL, TII.get(CPU74::POP16r), CPU74::R6);
//  }
//
//  // Skip up the callee-saved pop instructions.
//  while (MBBI != MBB.begin())
//  {
//    MachineBasicBlock::iterator PI = std::prev(MBBI);
//    if (PI->getOpcode() != CPU74::POP16r && !PI->isTerminator()) break;
//    --MBBI;
//  }
//
//  DL = MBBI->getDebugLoc();
//
//  if (MFI.hasVarSizedObjects())
//  {
//    BuildMI(MBB, MBBI, DL, TII.get(CPU74::MOVrr16), CPU74::SP).addReg(CPU74::R6);
//    uint64_t savedFrame = FuncInf->getCalleeSavedFrameSize();
//    if (savedFrame > 0)
//    {
//      MachineInstr *MI = BuildMI(MBB, MBBI, DL, TII.get(CPU74::SUBkr16), CPU74::SP).addReg(CPU74::SP).addImm(savedFrame);
//      MI->getOperand(3).setIsDead(); // The SR implicit def is dead.
//    }
//    return;
//  }
//
//  // Adjust stack pointer back: SP += numbytes
//  // FrameSize is non zero and fits in immediate instruction
//  if ( FrameSize && FrameSize < CPU74Imm::MaxSize )
//  {
//    MachineInstr *MI = BuildMI(MBB, MBBI, DL, TII.get(CPU74::ADDkr16), CPU74::SP).addReg(CPU74::SP).addImm(FrameSize);
//    MI->getOperand(3).setIsDead(); // The SR implicit def is dead.
//  }
//
//  // Add instruction must be generated through 'lea' instruction
//  else if ( FrameSize )
//  {
////    unsigned VReg = MF.getRegInfo().createVirtualRegister(&CPU74::GR16RegClass);
////    BuildMI(MBB, MBBI, DL, TII.get(CPU74::MOVKr16), VReg)
////      .addImm(FrameSize);
//
//    MachineInstr *MI = BuildMI(MBB, MBBI, DL, TII.get(CPU74::LEAMr16), CPU74::SP).addReg(CPU74::SP).addImm(FrameSize);
//    //MI->getOperand(3).setIsDead(); // The SR implicit def is dead.
//  }
//}


// FIXME: Can we eleminate these in favour of generic code?
bool CPU74FrameLowering::spillCalleeSavedRegisters(MachineBasicBlock &MBB,
      MachineBasicBlock::iterator MI, const std::vector<CalleeSavedInfo> &CSI,
      const TargetRegisterInfo *TRI) const
{
  if (CSI.empty())
    return false;

  DebugLoc DL;
  if (MI != MBB.end()) DL = MI->getDebugLoc();

  MachineFunction &MF = *MBB.getParent();
  const TargetInstrInfo &TII = *MF.getSubtarget().getInstrInfo();
  CPU74MachineFunctionInfo *FuncInf = MF.getInfo<CPU74MachineFunctionInfo>();
  FuncInf->setCalleeSavedFrameSize(CSI.size() * 2);
  
  for (unsigned i = CSI.size(); i != 0; --i)
  {
    unsigned Reg = CSI[i-1].getReg();
    // Add the callee-saved register as live-in. It's killed at the spill.
    MBB.addLiveIn(Reg);
    BuildMI(MBB, MI, DL, TII.get(CPU74::PUSH16r))
      .addReg(Reg, RegState::Kill);
  }
  return true;
}

bool CPU74FrameLowering::restoreCalleeSavedRegisters(MachineBasicBlock &MBB,
          MachineBasicBlock::iterator MI, std::vector<CalleeSavedInfo> &CSI,
          const TargetRegisterInfo *TRI) const
{
  if (CSI.empty())
    return false;

  DebugLoc DL;
  if (MI != MBB.end()) DL = MI->getDebugLoc();

  MachineFunction &MF = *MBB.getParent();
  const TargetInstrInfo &TII = *MF.getSubtarget().getInstrInfo();

  for (unsigned i = 0, e = CSI.size(); i != e; ++i)
    BuildMI(MBB, MI, DL, TII.get(CPU74::POP16r), CSI[i].getReg());

  return true;
}

// Helper function for eliminateCallFramePseudoInstr
static int64_t getFramePoppedByCallee(const MachineInstr &I)
{
    assert(I.getOperand(1).getImm() >= 0 && "Size must not be negative");
    return I.getOperand(1).getImm();
}

// This is called to create stack space when passing arguments on the stack
// to a function, just before the actual callee call, in cases where we did
// not reserve space in the caller.
// This is commonly the case for functions with variable size objects
// that are calling another function, or when we are optimizing stack frame
// immediate offsets
MachineBasicBlock::iterator CPU74FrameLowering::eliminateCallFramePseudoInstr(
    MachineFunction &MF, MachineBasicBlock &MBB,
    MachineBasicBlock::iterator I) const
{
  
  const CPU74InstrInfo &TII =
      *static_cast<const CPU74InstrInfo *>(MF.getSubtarget().getInstrInfo());
  
  unsigned StackAlign = getStackAlignment();

  if (!hasReservedCallFrame(MF))
  {
    // If the stack pointer can be changed after prologue, turn the
    // CALLSQ_END instruction into a 'sub SP, <amt>' and the
    // CALLSQ_START instruction into 'add SP, <amt>'
    // TODO: consider using push / pop instead of sub + store / add
    // FIX ME: check immediate sizes !!  ( look at eliminate frame index )
    MachineInstr &Old = *I;
    uint64_t Amount = TII.getFrameSize(Old);
    if (Amount != 0)
    {
      MachineInstr *New = nullptr;
      
      // We need to keep the stack aligned properly.  To do this, we round the
      // amount of space needed for the outgoing arguments up to the next
      // alignment boundary.
      Amount = (Amount+StackAlign-1)/StackAlign*StackAlign;
      
      // Frame start
      if (Old.getOpcode() == TII.getCallFrameSetupOpcode())  // This is CPU74::CALLSQ_START
      {
        New = BuildMI(MF, Old.getDebugLoc(), TII.get(CPU74::SUBkr16), CPU74::SP)
          .addReg(CPU74::SP)
          .addImm(Amount);
        //New = BuildMI(MF, Old.getDebugLoc(), TII.get(CPU74::SUBks16), CPU74::SP).addReg(CPU74::SP).addImm(Amount);
      }
      
      // Frame end
      else
      {
        assert(Old.getOpcode() == TII.getCallFrameDestroyOpcode());  // This is CPU74::CALLSQ_SEND
        // factor out the amount the callee already popped.
        //Amount -= TII.getFramePoppedByCallee(Old);
        Amount -= getFramePoppedByCallee(Old);
        if (Amount)
          New = BuildMI(MF, Old.getDebugLoc(), TII.get(CPU74::ADDkr16),CPU74::SP)
            .addReg(CPU74::SP)
            .addImm(Amount);
          //New = BuildMI(MF, Old.getDebugLoc(), TII.get(CPU74::ADDks16),CPU74::SP).addReg(CPU74::SP).addImm(Amount);
      }

      // Materialize the instruction
      if (New)
      {
        // The SR implicit def is dead.
        New->getOperand(3).setIsDead();

        // Replace the pseudo instruction with a new instruction...
        MBB.insert(I, New);
      }
    }
  }
  
  else if (I->getOpcode() == TII.getCallFrameDestroyOpcode()) // This is CPU74::CALLSQ_END
  {
    // If we are performing frame pointer elimination and if the callee pops
    // something off the stack pointer, add it back.
    //if (uint64_t CalleeAmt = TII.getFramePoppedByCallee(*I))
    if (uint64_t CalleeAmt = getFramePoppedByCallee(*I))
    {
      MachineInstr &Old = *I;
      MachineInstr *New = BuildMI(MF, Old.getDebugLoc(), TII.get(CPU74::SUBkr16), CPU74::SP)
        .addReg(CPU74::SP)
        .addImm(CalleeAmt);
      //MachineInstr *New = BuildMI(MF, Old.getDebugLoc(), TII.get(CPU74::SUBks16), CPU74::SP).addReg(CPU74::SP).addImm(CalleeAmt);
      // The SR implicit def is dead.
      New->getOperand(3).setIsDead();

      MBB.insert(I, New);
    }
  }

  return MBB.erase(I);
}

//// This is called to create stack space when passing arguments on the stack
//// to a function, just before the actual callee call, in cases where we did
//// not reserve space in the caller.
//// This is commonly the case for functions with variable size objects
//// that are calling another function
//MachineBasicBlock::iterator CPU74FrameLowering::eliminateCallFramePseudoInstr(
//    MachineFunction &MF, MachineBasicBlock &MBB,
//    MachineBasicBlock::iterator I) const {
//
//  const CPU74InstrInfo &TII =
//      *static_cast<const CPU74InstrInfo *>(MF.getSubtarget().getInstrInfo());
//
//  unsigned StackAlign = getStackAlignment();
//
//  if (!hasReservedCallFrame(MF))
//  {
//    // If the stack pointer can be changed after prologue, turn the
//    // CALLSQ_END instruction into a 'sub SP, <amt>' and the
//    // CALLSQ_START instruction into 'add SP, <amt>'
//    // TODO: consider using push / pop instead of sub + store / add
//    // TODO: check immediate sizes !!  ( look at eliminate frame index )
//    MachineInstr &Old = *I;
//    uint64_t Amount = TII.getFrameSize(Old);
//    if (Amount != 0) {
//      // We need to keep the stack aligned properly.  To do this, we round the
//      // amount of space needed for the outgoing arguments up to the next
//      // alignment boundary.
//      Amount = (Amount+StackAlign-1)/StackAlign*StackAlign;
//
//      MachineInstr *New = nullptr;
//      if (Old.getOpcode() == TII.getCallFrameSetupOpcode())  // This is CPU74::ADJCALLSTACKDOWN
//      {
//        //New = BuildMI(MF, Old.getDebugLoc(), TII.get(CPU74::SUBkr16), CPU74::SP).addReg(CPU74::SP).addImm(Amount);
//        New = BuildMI(MF, Old.getDebugLoc(), TII.get(CPU74::SUBks16), CPU74::SP).addReg(CPU74::SP).addImm(Amount);
//      } else {
//        assert(Old.getOpcode() == TII.getCallFrameDestroyOpcode());  // This is CPU74::CALLSQ_START
//        // factor out the amount the callee already popped.
//        //Amount -= TII.getFramePoppedByCallee(Old);
//        Amount -= getFramePoppedByCallee(Old);
//        if (Amount)
//          //New = BuildMI(MF, Old.getDebugLoc(), TII.get(CPU74::ADDkr16),CPU74::SP).addReg(CPU74::SP).addImm(Amount);
//          New = BuildMI(MF, Old.getDebugLoc(), TII.get(CPU74::ADDks16),CPU74::SP).addReg(CPU74::SP).addImm(Amount);
//      }
//
//      if (New) {
//        // The SR implicit def is dead.
//        New->getOperand(3).setIsDead();
//
//        // Replace the pseudo instruction with a new instruction...
//        MBB.insert(I, New);
//      }
//    }
//  }
//  else if (I->getOpcode() == TII.getCallFrameDestroyOpcode()) // This is CPU74::CALLSQ_END
//  {
//    // If we are performing frame pointer elimination and if the callee pops
//    // something off the stack pointer, add it back.
//    //if (uint64_t CalleeAmt = TII.getFramePoppedByCallee(*I))
//    if (uint64_t CalleeAmt = getFramePoppedByCallee(*I))
//    {
//      MachineInstr &Old = *I;
//      //MachineInstr *New = BuildMI(MF, Old.getDebugLoc(), TII.get(CPU74::SUBkr16), CPU74::SP).addReg(CPU74::SP).addImm(CalleeAmt);
//      MachineInstr *New = BuildMI(MF, Old.getDebugLoc(), TII.get(CPU74::SUBks16), CPU74::SP).addReg(CPU74::SP).addImm(CalleeAmt);
//      // The SRW implicit def is dead.
//      New->getOperand(3).setIsDead();
//
//      MBB.insert(I, New);
//    }
//  }
//
//  return MBB.erase(I);
//}



#ifdef FP_AS_SPILL
// Estimate the size of the stack, including the incoming arguments. We need to
// account for push register spills, local objects, reserved call frame and incoming
// arguments. This is required to determine the largest possible positive offset
// from SP so that it can be determined if an  spill slot for stack
// addresses is required. See: MipsFrameLowering::estimateStackSize
static int estimateMaxOffset(const MachineFunction &MF, RegScavenger *RS) const
{
  const MachineFrameInfo &MFI = MF.getFrameInfo();
  const TargetRegisterInfo *RegInfo = MF.getSubtarget().getRegisterInfo();

  int offset = 0;

  // Iterate over fixed sized objects which are incoming arguments.
  int beg = MFI.getObjectIndexBegin();
  for (int i = beg; i < 0; i++)
      offset += MFI.getObjectSize(i);

  // Get the size of the rest of the frame objects and any possible reserved
  // call frame, accounting for alignment.
  return offset + MFI.estimateStackSize(MF);
}
#endif

//void CPU74FrameLowering::determineCalleeSaves(MachineFunction &MF,
//    BitVector &SavedRegs, RegScavenger *RS ) const
//{
//  int stackSize = estimateMaxOffset(MF, RS);
//  TargetFrameLowering::determineCalleeSaves( MF, SavedRegs, RS );
//}


void CPU74FrameLowering::processFunctionBeforeFrameFinalized(
        MachineFunction &MF, RegScavenger *RS) const
{
//   // Create a frame entry for the FP register that must be saved
//  if (hasFP(MF))
//  {
//    int FrameIdx = MF.getFrameInfo().CreateFixedObject(2, -4, true);
//    (void)FrameIdx;
//    assert(FrameIdx == MF.getFrameInfo().getObjectIndexBegin() &&
//           "Slot for FP register must be last in order to be found!");
//  }

#ifdef FP_AS_SPILL
  const MachineFrameInfo &MFI = MF.getFrameInfo();
  CPU74MachineFunctionInfo *FuncInf = MF.getInfo<CPU74MachineFunctionInfo>();
  
  int maxOffset = estimateMaxOffset(MF, RS);
  FuncInf->setHasBigOffsets( !(maxOffset + 2 <= CPU74Imm::MaxImm6) ); // add 2 to account PC
  
  int spillsFrameSize = 0;
  if ( FuncInf->getHasSpills() )
  {
    spillsFrameSize = MFI.getObjectIndexEnd() - FuncInf->getFirstSpillIndex();
    FuncInf->setHasSpills( spillsFrameSize > 0 );
  }
#endif
}




/// AQUESTA ES INTERESSANT

//void SystemZFrameLowering::
//processFunctionBeforeFrameFinalized(MachineFunction &MF,
//                                    RegScavenger *RS) const {
//  MachineFrameInfo &MFFrame = MF.getFrameInfo();
//  // Get the size of our stack frame to be allocated ...
//  uint64_t StackSize = (MFFrame.estimateStackSize(MF) +
//                        SystemZMC::CallFrameSize);
//  // ... and the maximum offset we may need to reach into the
//  // caller's frame to access the save area or stack arguments.
//  int64_t MaxArgOffset = SystemZMC::CallFrameSize;
//  for (int I = MFFrame.getObjectIndexBegin(); I != 0; ++I)
//    if (MFFrame.getObjectOffset(I) >= 0) {
//      int64_t ArgOffset = SystemZMC::CallFrameSize +
//                          MFFrame.getObjectOffset(I) +
//                          MFFrame.getObjectSize(I);
//      MaxArgOffset = std::max(MaxArgOffset, ArgOffset);
//    }
//
//  uint64_t MaxReach = StackSize + MaxArgOffset;
//  if (!isUInt<12>(MaxReach)) {
//    // We may need register scavenging slots if some parts of the frame
//    // are outside the reach of an unsigned 12-bit displacement.
//    // Create 2 for the case where both addresses in an MVC are
//    // out of range.
//    RS->addScavengingFrameIndex(MFFrame.CreateStackObject(8, 8, false));
//    RS->addScavengingFrameIndex(MFFrame.CreateStackObject(8, 8, false));
//  }
//}



//
///*==-----------------------------------------------------------------------------==*/
//
//
///// The frame analyzer pass.
/////
///// Scans the function for big offsets and used arguments
///// that are passed through the stack.
////namespace {
//class CPU74FrameAnalyzer : public MachineFunctionPass
//{
//  public:
//    static char ID;
//    CPU74FrameAnalyzer() : MachineFunctionPass(ID) {}
//
//    bool runOnMachineFunction(MachineFunction &MF);
//    StringRef getPassName() const { return "CPU74 Frame Analyzer"; }
//
//    int estimateMaxOffset(const MachineFunction &MF ) const;
//};
//
//int CPU74FrameAnalyzer::estimateMaxOffset(const MachineFunction &MF) const
//{
//  const MachineFrameInfo &MFI = MF.getFrameInfo();
//  const TargetFrameLowering *TFI = MF.getSubtarget().getFrameLowering();
//  const TargetRegisterInfo *RegInfo = MF.getSubtarget().getRegisterInfo();
//
//  int offset = 0;
//
//  // Iterate over fixed sized objects which are incoming arguments.
//  int beg = MFI.getObjectIndexBegin();
//  for (int i = beg; i < 0; i++)
//      offset += MFI.getObjectSize(i);
//
//  // Conservatively assume all callee-saved registers will be saved.
//  for (const MCPhysReg *reg = RegInfo->getCalleeSavedRegs(&MF); *reg != 0; ++reg)
//  {
//    unsigned RegSize = RegInfo->getSpillSize(  CPU74::GR16RegClass /* *(RegInfo->getMinimalPhysRegClass(*reg))*/ );
//    offset = alignTo(offset + RegSize, RegSize);
//  }
//
////  if ( TFI->hasReservedCallFrame(MF) )
////    offset += MFI.getMaxCallFrameSize();
//
////  SmallVector<int, 2> SFIs;
////  RS->getScavengingFrameIndices(SFIs);
////  int numindices = SFIs.end() - SFIs.begin();
//
////  offset += numindices*2;
////  for (SmallVectorImpl<int>::iterator I = SFIs.begin(), IE = SFIs.end(); I != IE; ++I)
////      AdjustStackOffset(MFI, *I, StackGrowsDown, Offset, MaxAlign, Skew);
//
//  // Get the size of the rest of the frame objects and any possible reserved
//  // call frame, accounting for alignment.
//  return offset + MFI.estimateStackSize(MF);
//}
//
//
//
//bool CPU74FrameAnalyzer::runOnMachineFunction(MachineFunction &MF)
//{
//  // This pass is run after Dag isel but before physical register allocaton
//  // Calculates whether there are big frame offsets that will forbid the use
//  // of immediate SP load/stores. The result is a early estimate
//  // that does not include yet any callee saved objects
//
//  const MachineFrameInfo &MFI = MF.getFrameInfo();
//  CPU74MachineFunctionInfo *FuncInf = MF.getInfo<CPU74MachineFunctionInfo>();
//
//  unsigned maxOffset = estimateMaxOffset(MF);
//  if ( MFI.getObjectIndexBegin() > 0 )
//    maxOffset += 4; // account for PC and eventual R7
//
//  FuncInf->setEstimatedFrameSize( maxOffset );
//  return false;
//}
//
//char CPU74FrameAnalyzer::ID = 0;
//
///// Creates instance of the frame analyzer pass.
//FunctionPass *llvm::createCPU74FrameAnalyzerPass() {
//  return new CPU74FrameAnalyzer();
//}
//
//







//  // If there are no fixed frame indexes during this stage it means there
//  // are allocas present in the function.
//  if (MFI.getNumObjects() != MFI.getNumFixedObjects()) {
//
//      // Check for the type of allocas present in the function. We only care
//      // about fixed size allocas so do not give false positives if only
//      // variable sized allocas are present.
//      for (unsigned i = 0, e = MFI.getObjectIndexEnd(); i != e; ++i) {
//        // Variable sized objects have size 0.
//        if (MFI.getObjectSize(i)) {
//          FuncInfo->setHasAllocas(true);
//          break;
//        }
//      }
//    }
//
//    // If there are fixed frame indexes present, scan the function to see if
//    // they are really being used.
//    if (MFI.getNumFixedObjects() == 0) {
//      return false;
//    }
//
//    // Ok fixed frame indexes present, now scan the function to see if they
//    // are really being used, otherwise we can ignore them.
//    for (const MachineBasicBlock &BB : MF) {
//      for (const MachineInstr &MI : BB) {
//        int Opcode = MI.getOpcode();
//
//        if ((Opcode != CPU74::LDDRdPtrQ) && (Opcode != CPU74::LDDWRdPtrQ) &&
//            (Opcode != CPU74::STDPtrQRr) && (Opcode != CPU74::STDWPtrQRr)) {
//          continue;
//        }
//
//        for (const MachineOperand &MO : MI.operands()) {
//          if (!MO.isFI()) {
//            continue;
//          }
//
//          if (MFI.isFixedObjectIndex(MO.getIndex())) {
//            FuncInfo->setHasStackArgs(true);
//            return false;
//          }
//        }
//      }
//    }
//
//    return false;
//  }
//




