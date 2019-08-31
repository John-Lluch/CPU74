//===-- CPU74RegisterInfo.cpp - CPU74 Register Information --------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the CPU74 implementation of the TargetRegisterInfo class.
//
//===----------------------------------------------------------------------===//

#include "CPU74RegisterInfo.h"
#include "CPU74.h"
#include "CPU74MachineFunctionInfo.h"
#include "CPU74TargetMachine.h"
#include "llvm/ADT/BitVector.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/IR/Function.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Target/TargetOptions.h"

using namespace llvm;

#define DEBUG_TYPE "cpu74-reg-info"

#define GET_REGINFO_TARGET_DESC
#include "CPU74GenRegisterInfo.inc"

// FIXME: Provide proper call frame setup / destroy opcodes.
CPU74RegisterInfo::CPU74RegisterInfo()
  : CPU74GenRegisterInfo(CPU74::PC) {}

const MCPhysReg *CPU74RegisterInfo::getCalleeSavedRegs(const MachineFunction *MF) const
{
  const Function* F = &MF->getFunction();

  if (F->getCallingConv() == CallingConv::CPU74_INTR )
    return SavedRegs_Interrupts_SaveList;
  
  return SavedRegs_Normal_SaveList;
}

const uint32_t *CPU74RegisterInfo::getCallPreservedMask(const MachineFunction &MF, CallingConv::ID CC) const
{
  if (CC == CallingConv::CPU74_INTR )
      return SavedRegs_Interrupts_RegMask;
  
  return SavedRegs_Normal_RegMask;
}

BitVector CPU74RegisterInfo::getReservedRegs(const MachineFunction &MF) const
{
  BitVector Reserved(getNumRegs());
  const CPU74FrameLowering *TFI = getFrameLowering(MF);
  
  Reserved.set(CPU74::PC);
  Reserved.set(CPU74::SP);
  Reserved.set(CPU74::SR);
  Reserved.set(CPU74::AR);
  
  // We can not tell whether a function may require the r6 register as
  // a frame pointer until frame lowering, which is too late.
  // Therefore, we unconditionally reserve the r6 register here.
  // If the function didn't end up needing a frame pointer, we may
  // convert one of its spills to use the r6 register.
  // See comments on CPU74MachineFunctionInfo:getHasSpills() for more details

#ifdef FP_AS_SPILL
  if ( 1 )   // Reserve always
#else
  if ( TFI->hasFP(MF))   // Reserve the FP if needed
#endif
    Reserved.set(CPU74::R6);
  
  return Reserved;
}

// All general purpose registers can be pointers
const TargetRegisterClass *CPU74RegisterInfo::getPointerRegClass(const MachineFunction &MF, unsigned Kind) const
{
  return &CPU74::GR16RegClass;
}

// This is for debug purposes, I think otherwise this is never called
Register CPU74RegisterInfo::getFrameRegister(const MachineFunction &MF) const
{
  const CPU74FrameLowering *TFI = getFrameLowering(MF);
  return TFI->hasFP(MF) ? CPU74::R6 : CPU74::SP;
}

bool CPU74RegisterInfo::requiresFrameIndexScavenging(const MachineFunction &MF) const
{
  //return false;
  return true;
}

bool CPU74RegisterInfo::requiresRegisterScavenging(const MachineFunction &MF) const
{
  //return false;
  return true;
}

// This function is required when we may use R6 as spill replacement.
bool CPU74RegisterInfo::hasReservedSpillSlot(const MachineFunction &MF,
                                              unsigned Reg, int &FrameIdx) const
{
#ifdef FP_AS_SPILL
  if ( Reg == CPU74::R6)
  {
    FrameIdx = 0;
    return true;
  }
#endif
  return false;
}

bool CPU74RegisterInfo::requiresFrameIndexReplacementScavenging(const MachineFunction &MF) const {
  return false;
}

bool CPU74RegisterInfo::trackLivenessAfterRegAlloc(const MachineFunction &MF) const {
  return false;
}

bool CPU74RegisterInfo::requiresVirtualBaseRegisters(const MachineFunction &MF) const {
  return false;
}

//This function is called for each instruction that references a word of data in a stack slot.
//All previous passes of the code generator have been addressing stack slots through an abstract
//frame index and an immediate offset. The purpose of this function is to translate such a reference into
//a register+offset pair. Both the frame pointer register R7 or the stack pointer SP can be used
//as the base register. The frame pointer is required for frame indexes with big offsets and in
//functions with variable sized objects. The offsets are computed accordingly:
//i.e for frame pointer addressing, the offset is increased by two additional bytes to account
//for the saved FP; for stack pointer indexing the offset needs to be increased by the frame stack size.
//An attempt is made to translate frame indexes into Load/stores with immediate offset instructions.
//If the instruction cannot handle a too large offset, a sequence of instructions is emitted
//that explicitly compute the effective address with intermediate registers.
//LLVM’s framework RegScavenger is used for the purpose of finding an unused register
//or to scavenge an already ocuppied one.

void CPU74RegisterInfo::eliminateFrameIndex(MachineBasicBlock::iterator II,
                                        int SPAdj, unsigned FIOperandNum,
                                        RegScavenger *RS) const
{
  assert(SPAdj == 0 && "Unexpected");

  MachineInstr &MI = *II;
  DebugLoc dl = MI.getDebugLoc(); 
  MachineBasicBlock &MBB = *MI.getParent();
  /*const*/ MachineFunction &MF = *MBB.getParent();
  const TargetInstrInfo &TII = *MF.getSubtarget().getInstrInfo();
  const MachineFrameInfo &MFI = MF.getFrameInfo();
  const CPU74FrameLowering *TFI = getFrameLowering(MF);
  CPU74MachineFunctionInfo *FuncInf = MF.getInfo<CPU74MachineFunctionInfo>();
  
  int frameIndex = MI.getOperand(FIOperandNum).getIndex();
  bool usesFP = TFI->hasFP(MF); // implementation already accounts for reservedCallFrame, this means that FP can be used
  bool usesBP = !TFI->hasReservedCallFrame(MF); // use FP as Base Pointer
  bool hasResFr = TFI->hasReservedCallFrame(MF); // this essentially means that SP can be used
  
  // Base offset
  int offset = MFI.getObjectOffset(frameIndex);
  offset +=2 ;    // Add 2 to skip the saved PC
  offset += MI.getOperand(FIOperandNum + 1).getImm();  // Add the incoming offset.
  
  // Offset adjustment
  // For offsets to function arguments we eventually
  // need to add 2 to skip saved FP
  if ( frameIndex < 0 )
  {
#ifdef FP_AS_SPILL
    if ( usesFP || FuncInf->getReplacedSpillsFrameSize() > 0 ) offset += 2;
#else
    if ( usesFP ) offset += 2;
#endif
  }

  // Calculate pointer relative offsets
  int offsetSP = offset + MFI.getStackSize();   // SP offset
  int offsetFP = offset + (usesBP ? MFI.getStackSize() : 0 );  // FP offset
  
  // Select the offset and base register
  int theOffset = offsetSP;
  unsigned baseReg = CPU74::SP;

  // use FP only if it has positive offset or we don't have reserved frame
  if ( (usesFP && offsetFP >= 0) || !hasResFr )
  {
    theOffset = offsetFP;
    baseReg = CPU74::R6;
  }
  
  MachineInstr *mi = nullptr;
  
  // Get instruction opCode
  unsigned opCode = MI.getOpcode();
  
  // ADDFrame pseudo instructions are actually "load effective address" of the stack slot
  // instruction. We need to expand them into mov + add
  if ( opCode == CPU74::ADDFrame )
  {
    unsigned dstReg = MI.getOperand(0).getReg();
  
    // Try to fit into an immediate add or sub instruction
    if ( (usesFP && (CPU74Imm::isImm8u(offsetFP) || CPU74Imm::isImm8u(-offsetFP))) ||
         (hasResFr && (CPU74Imm::isImm8u(offsetSP) || CPU74Imm::isImm8u(-offsetSP))) )
    {
      // Move frame base register to the destination register
      // 'mov FP, Rd'
      BuildMI(MBB, II, dl, TII.get(CPU74::MOVrr16), dstReg)
          .addReg(baseReg);

      if ( theOffset > 0 )
      {
        // Materialize the offset via add instruction
        // 'add Rd, #offset, Rd'
        mi = BuildMI(MBB, std::next(II), dl, TII.get(CPU74::ADDkr16), dstReg)
            .addReg(dstReg).addImm(theOffset);
        mi->getOperand(3).setIsDead();  // SR Implicit
      }
      else if ( theOffset < 0 )
      {
        // Materialize the offset via sub instruction
        // 'sub Rd, #offset, Rd'
        mi = BuildMI(MBB, std::next(II), dl, TII.get(CPU74::SUBkr16), dstReg)
            .addReg(dstReg).addImm(-theOffset);
        mi->getOperand(3).setIsDead();  // SR Implicit

      }
    }

    // Offset is too big, we need to materialize the offset via register immediate
    else
    {
      // Use the destination register to materialize sp + offset.
      // 'mov #imm, Rd'
      BuildMI(MBB, II, dl, TII.get(CPU74::LEAKr16), dstReg)
          .addImm(theOffset);  // positive or negative

      // 'add FP, Rd, Rd'
      mi = BuildMI(MBB, II, dl, TII.get(CPU74::ADDrrr16), dstReg)
          .addReg(baseReg)
          .addReg(dstReg);
      mi->getOperand(3).setIsDead();  // SR Implicit
    }
    
    // We are done with the ADDFrame pseudo instruction
    MI.eraseFromParent();
    return ;
  }
  
  // So we have a load/store with constant offset instruction,
  // find the optimal way to eliminate the frame index
  
  // We should only have indexed load/store instructions getting here
  assert( (opCode == CPU74::MOVmr16 || opCode == CPU74::MOVmr8s ||
          opCode == CPU74::MOVmr8z || opCode == CPU74::MOVrm16 ||
          opCode == CPU74::MOVrm8) &&
          "Unsupported opcode entering eliminateFrameIndex");
  
#ifdef FP_AS_SPILL
  // In cases where we do not have a frame pointer, we may be able to use
  // R6 as a replacement of an existing spill. Do it now if possible
    if ( FuncInf->getReplacedSpillsFrameSize() > 0 && FuncInf->getFirstSpillIndex() == frameIndex
    {
      unsigned dstReg = MI.getOperand(0).getReg();
      switch ( opCode )
      {
        default: llvm_unreachable("Unsupported opcode entering eliminateFrameIndex");
        case CPU74::MOVmr16 :  // load
          // 'mov r6, Rd'
          BuildMI(MBB, II, dl, TII.get(CPU74::MOVrr16), dstReg)
            .addReg( CPU74::R6);
          break;

        case CPU74::MOVrm16 : // store
          // 'mov Rd, r6'
          BuildMI(MBB, II, dl, TII.get(CPU74::MOVrr16), CPU74::R6)
            .addReg( dstReg );
          break;
      }
      //MI->getOperand(3).setIsDead(); // The SR implicit def is dead.
      MI.eraseFromParent();
      return;
    }
#endif
  
  bool needsExtension = false;
  
  // Try to fit in load/store immediate instruction
  if ( CPU74Imm::isImm6_d(theOffset) )
  {
      if (opCode == CPU74::MOVmr8z )  // opcode needs to be replaced for zext loads
         MI.setDesc(TII.get(CPU74::MOVmr8s)), needsExtension = true;
    
      // 'ld [fp, imm], Rd' or
      // 'st Rd, [fp, imm]'
      MI.getOperand(FIOperandNum).ChangeToRegister(baseReg, false);
      MI.getOperand(FIOperandNum + 1).ChangeToImmediate(theOffset);
  }
  
  // Offset does not fit
  else
  {
    // Offset was too small for load instruction, but it may still fit
    // in move immediate instruction
    unsigned moveOpCode = CPU74::LEAKr16;
    if ( CPU74Imm::isImm8s(theOffset))
        moveOpCode = CPU74::MOVkr16;

    unsigned dstReg = MI.getOperand(0).getReg();

    // For loads use the destination register to materialize fp + offset.
    if ( MI.mayLoad() )
    {
      unsigned newOpCode = 0;
      switch ( opCode )
      {
        default: llvm_unreachable("Unsupported opcode entering eliminateFrameIndex");
        case CPU74::MOVmr16 :
          newOpCode = CPU74::MOVnr16; break;
        case CPU74::MOVmr8s :
          newOpCode = CPU74::MOVnr8s; break;
        case CPU74::MOVmr8z :
          newOpCode = CPU74::MOVnr8z; break;
      }

      // Use destination register to materialize the offset
      // 'mov #imm, Rd'
      BuildMI(MBB, II, dl, TII.get(moveOpCode), dstReg)
          .addImm(theOffset);

      // 'ld [FP, Rd], Rd'
      MI.setDesc(TII.get(newOpCode));
      MI.getOperand(FIOperandNum).ChangeToRegister(baseReg, false, false, false);
      MI.getOperand(FIOperandNum+1).ChangeToRegister(dstReg, false, false, true);
    }

    else if ( MI.mayStore() )
    {
      unsigned newOpCode = 0;
      switch ( opCode )
      {
        default: llvm_unreachable("Unsupported opcode entering eliminateFrameIndex");
        case CPU74::MOVrm16 :
          newOpCode =  CPU74::MOVrn16; break;
        case CPU74::MOVrm8 :
          newOpCode = CPU74::MOVrn8; break;
      }

      unsigned vReg = MF.getRegInfo().createVirtualRegister(&CPU74::GR16RegClass);     // TODO: mirar que passa si es queda sense registres.
                                                                                      // (s'ha de preveure un stack slot per register scavenger)?
                                                                                      // (es pot utilitzar el register scavenger RS directament,
      // 'mov #imm, Rx'                                                              // despres de posar requiresFrameIndexReplacementScavenging = true)?
      BuildMI(MBB, II, dl, TII.get(moveOpCode), vReg)
          .addImm(offsetFP); //.setMIFlag(MachineInstr::NoFlags);

      // 'st Rd, [FP, Rx]'
      MI.setDesc(TII.get(newOpCode));
      MI.getOperand(FIOperandNum).ChangeToRegister(baseReg, false, false, false);
      MI.getOperand(FIOperandNum+1).ChangeToRegister(vReg, false, false, true); // true a l'ultim?
    }
  }
  
  // If the instruction was a pseudo zero extended load we just replaced it
  // by a supported signextended instruction so we need to insert a ZEXT after it
  if ( needsExtension )
  {
    unsigned dstReg = MI.getOperand(0).getReg();
    BuildMI(MBB, std::next(II), dl, TII.get(CPU74::ZEXTrr16), dstReg)  // add zero extend
        .addReg(dstReg);
  }
}

