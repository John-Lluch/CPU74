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
       |    Spills    |                     |--------------|
       |--------------|                     |              |
       |              |                     |   Spills     |
       |  Local Vars  |                     |--------------|
       |              |                     |              |
SP(1') |--------------|                     |  Local Vars  |
       |              |                     |              |
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
FP(1) : Address pointed by BP at function prologue completion

With Base Pointer

BP(1) : Address pointed by the Base Pointer

For CPU74 we do not use a separate register as the BP. Instead, we
chose a role for Register R7 on any given function, either as FP or BP depending
on the following rules:

- If the estimated stack size fits in the immediate load/store offset, use simple SP stack
based frame, R6 remains free for general purpose use. Otherwise use FP based frame.

- If the max size of the Call Args, plus the size of the arguments is above the immediate
load/store offset, use FP based frame with Register R7 as the BP.

- Functions with variable sized object always use the FP model

- Currently, the FP based frame is always associated with R6 as a BP, so
there's no actual FP in this mode

*/

// Returns whether the estimated frame size is large
static bool hasBigOffsets( const MachineFunction &MF )
{
  const CPU74MachineFunctionInfo *FuncInf = MF.getInfo<CPU74MachineFunctionInfo>();
  return FuncInf->getEstimatedFrameSize() >= CPU74Imm::MaxImm8;
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
  return MFI.getMaxCallFrameSize() + FuncInf->getArgumentsSize() >= CPU74Imm::MaxImm8;
  //return MFI.getMaxCallFrameSize() + FuncInf->getArgumentsSize() >= CPU74Imm::MaxImm6;
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
  // stack frame. CPU74 has a small immediate offset to
  // address the stack frame. So a large call frame can cause poor codegen
  // and may even make it impossible to scavenge a register.
  
  return !( hasBigCallFrame(MF) || MFI.hasVarSizedObjects() );
}

bool CPU74FrameLowering::hasBasePointer(const MachineFunction &MF) const
{
  const MachineFrameInfo &MFI = MF.getFrameInfo();
  
  // If call frames are big, force the use of a base pointer
  // This in turn implies that we do NOT have reservedCallFrame
  return hasBigCallFrame(MF) || MFI.hasVarSizedObjects();
}

void CPU74FrameLowering::emitPrologue(MachineFunction &MF, MachineBasicBlock &MBB) const
{
  assert(&MF.front() == &MBB && "Shrink-wrapping not yet supported");
  
  const MachineFrameInfo &MFI = MF.getFrameInfo();
  CPU74MachineFunctionInfo *FuncInf = MF.getInfo<CPU74MachineFunctionInfo>();
  //const TargetRegisterInfo *RegInfo = MF.getSubtarget().getRegisterInfo();
  
  const CPU74InstrInfo &TII = *static_cast<const CPU74InstrInfo *>(MF.getSubtarget().getInstrInfo());

  MachineBasicBlock::iterator MBBI = MBB.begin();
  DebugLoc dl = MBBI != MBB.end() ? MBBI->getDebugLoc() : DebugLoc();
  
  bool usesFP = hasFP(MF);
  //bool hasResFr = hasReservedCallFrame(MF);
  bool usesBP = hasBasePointer(MF); // this also implies usesFP

  // Get the number of bytes to allocate from the FrameInfo.
  uint64_t FrameSize = MFI.getStackSize() - FuncInf->getCalleeSavedFrameSize();
  
  if ( usesFP )
  {
    // Push FP into the stack
    BuildMI(MBB, MBBI, dl, TII.get(CPU74::PUSH16r)).addReg(CPU74::R7, RegState::Kill);
  }

  if ( usesFP && !usesBP )
  {
    // Update FP with the new base value...
    BuildMI(MBB, MBBI, dl, TII.get(CPU74::LEAqr16_core), CPU74::R7)
      .addReg(CPU74::SP)
      .addImm(0);
  }

  if ( usesFP )
  {
    // Mark the FramePtr as live-in in every block except the entry.
    for (MachineFunction::iterator I = std::next(MF.begin()), E = MF.end(); I != E; ++I)
      I->addLiveIn(CPU74::R7);
  }

  // Skip down the callee-saved push instructions.
  while (MBBI != MBB.end() && (MBBI->getOpcode() == CPU74::PUSH16r))
    ++MBBI;

  if (MBBI != MBB.end())
    dl = MBBI->getDebugLoc();

  // Generate stack frame based on FrameSize
  if ( FrameSize )
  {
    unsigned opCode = (FrameSize < CPU74Imm::MaxImm8 ? CPU74::ADDkq16_core : CPU74::ADDkq16_pfix);
    MachineInstr *MI = BuildMI(MBB, MBBI, dl, TII.get(opCode), CPU74::SP)
      .addReg(CPU74::SP)
      .addImm(-FrameSize);
  }
  
  // If we need a base pointer, set it up here. It's whatever the value
  // of the stack pointer is at this point. Any variable size objects
  // will be allocated after this, so we can still use the base pointer
  // to reference locals.
  if ( usesFP && usesBP )
  {
    BuildMI(MBB, MBBI, dl, TII.get(CPU74::LEAqr16_core), CPU74::R7)
      .addReg(CPU74::SP)
      .addImm(0);
  }
}

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
  bool hasResFr = hasReservedCallFrame(MF);
  //bool usesBP = !hasReservedCallFrame(MF); // this also implies usesFP
  bool usesBP = hasBasePointer(MF); // this also implies usesFP

  // Get the number of bytes to allocate from the FrameInfo
  uint64_t FrameSize = MFI.getStackSize() - FuncInf->getCalleeSavedFrameSize(); //- FuncInf->getReplacedSpillsFrameSize();;
  
  if ( usesFP )
  {
    // Pop FP, that's the last instruction
    BuildMI(MBB, MBBI, DL, TII.get(CPU74::POP16r), CPU74::R7);
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
  // Optimize stack pointer adjustment by removing redundant
  // add SP, #imm, SP  created by non reserved frames
  
  // If it has variable sized objects just restore the stack pointer from it
  //if (MFI.hasVarSizedObjects())
  if (!hasResFr)
  {
    BuildMI(MBB, MBBI, DL, TII.get(CPU74::MOVrq16), CPU74::SP)
      .addReg(CPU74::R7);

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
        MachineInstr *MI = BuildMI(MBB, MBBI, DL, TII.get(CPU74::ADDkq16_core), CPU74::SP)
          .addReg(CPU74::SP)
          .addImm(-savedFrame);
      }
      // return now, as we are done with this
      return;
    }
  }
  
  // Adjust stack pointer back: SP += numbytes
  if ( FrameSize )
  {
    unsigned opCode = (FrameSize < CPU74Imm::MaxImm8 ? CPU74::ADDkq16_core : CPU74::ADDkq16_pfix);
    MachineInstr *MI = BuildMI(MBB, MBBI, DL, TII.get(opCode), CPU74::SP)
      .addReg(CPU74::SP)
      .addImm(FrameSize);
  }
}

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
        New = BuildMI(MF, Old.getDebugLoc(), TII.get(CPU74::SUBkr16_core), CPU74::SP)     // FIX ME: check immediate sizes !!  ( look at eliminate frame index )
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
          New = BuildMI(MF, Old.getDebugLoc(), TII.get(CPU74::ADDkr16_core),CPU74::SP)
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
      MachineInstr *New = BuildMI(MF, Old.getDebugLoc(), TII.get(CPU74::SUBkr16_core), CPU74::SP)
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

void CPU74FrameLowering::processFunctionBeforeFrameFinalized(
        MachineFunction &MF, RegScavenger *RS) const
{
  // Nothing to do
}









