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
  
  // We can not tell whether a function may require the r6 register as
  // a frame pointer until frame lowering, which is too late.
  // Therefore, we unconditionally reserve the r6 register here.
  // If the function didn't end up needing a frame pointer, we may
  // convert one of its spills to use the r6 register.
  // See comments on CPU74MachineFunctionInfo:getHasSpills() for more details

  if ( TFI->hasFP(MF))   // Reserve the FP if needed
    Reserved.set(CPU74::R7);
  
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
  return TFI->hasFP(MF) ? CPU74::R7 : CPU74::SP;
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
  if ( Reg == CPU74::R7)
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
  //CPU74MachineFunctionInfo *FuncInf = MF.getInfo<CPU74MachineFunctionInfo>();
  
  int frameIndex = MI.getOperand(FIOperandNum).getIndex();
  bool usesFP = TFI->hasFP(MF); // implementation already accounts for reservedCallFrame, this means that FP can be used
  bool hasResFr = TFI->hasReservedCallFrame(MF); // this essentially means that SP can be used
  //bool usesBP = !TFI->hasReservedCallFrame(MF); // use FP as Base Pointer
  bool usesBP = TFI->hasBasePointer(MF); // use BP as Base Pointer, this implies usesFP
  
  // Base offset
  int offset = MFI.getObjectOffset(frameIndex);
  offset +=2 ;    // Add 2 to skip the saved PC
  offset += MI.getOperand(FIOperandNum + 1).getImm();  // Add the incoming offset.
  
  // Offset adjustment
  // For offsets to function arguments we eventually
  // need to add 2 to skip saved FP
  if ( frameIndex < 0 )
  {
    if ( usesFP ) offset += 2;
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
    baseReg = CPU74::R7;
  }
  
  // Get instruction opCode
  unsigned opCode = MI.getOpcode();
  unsigned newOpCode = 0;
  bool needsExtension = false;
  
  // We should only have frame indexed lea and load/store instructions getting here
  assert( (opCode == CPU74::LEAqr16_core ||
           opCode == CPU74::MOVqr16_core || opCode == CPU74::MOVqr8s_core || opCode == CPU74::MOVqr8z_core ||
           opCode == CPU74::MOVrq16_core || opCode == CPU74::MOVrq8_core) &&
           "Unsupported opcode entering eliminateFrameIndex");

  // If fits in base register offsets
  if ( baseReg == CPU74::R7 && CPU74Imm::isImm5_d(theOffset) )
  {
    switch ( opCode )
    {
      default: llvm_unreachable("Unsupported opcode entering eliminateFrameIndex");
      case CPU74::LEAqr16_core : newOpCode = CPU74::LEArkr16_core; break;
      case CPU74::MOVqr16_core : newOpCode = CPU74::MOVmr16_core; break;
      case CPU74::MOVqr8s_core : newOpCode = CPU74::MOVmr8s_core; break;
      case CPU74::MOVqr8z_core : newOpCode = CPU74::MOVmr8z_core; break;
      case CPU74::MOVrq16_core : newOpCode = CPU74::MOVrm16_core; break;
      case CPU74::MOVrq8_core  : newOpCode = CPU74::MOVrm8_core; break;
    }
  }
  
  // If fits in SP offset
  else if ( baseReg == CPU74::SP && CPU74Imm::isImm8u(theOffset) )
  {
    newOpCode = opCode ;
    if ( opCode == CPU74::MOVqr8z_core ) // Opcode needs to be replaced by sext loads
    {
      // add an explicit Sext
      newOpCode = CPU74::MOVqr8s_core, needsExtension = true;
    }
  }
  
  // It didn't fit. Replace the instruction by a prefixed one
  else if ( baseReg == CPU74::R7 )
  {
    switch ( opCode )
    {
      default: llvm_unreachable("Unsupported opcode entering eliminateFrameIndex");
      case CPU74::LEAqr16_core : newOpCode = CPU74::LEArkr16_pfix; break;
      case CPU74::MOVqr16_core : newOpCode = CPU74::MOVmr16_pfix; break;
      case CPU74::MOVqr8z_core : newOpCode = CPU74::MOVmr8z_pfix; break;
      case CPU74::MOVqr8s_core : newOpCode = CPU74::MOVmr8s_pfix; break;
      case CPU74::MOVrq16_core : newOpCode = CPU74::MOVrm16_pfix; break;
      case CPU74::MOVrq8_core  : newOpCode = CPU74::MOVrm8_pfix; break;
    }
  }
  
  // It didn't fit. Replace the instruction by a prefixed one
  else if ( baseReg == CPU74::SP )
  {
    switch ( opCode )
    {
      default: llvm_unreachable("Unsupported opcode entering eliminateFrameIndex");
      case CPU74::LEAqr16_core : newOpCode = CPU74::LEAqr16_pfix; break;
      case CPU74::MOVqr16_core : newOpCode = CPU74::MOVqr16_pfix; break;
      case CPU74::MOVqr8z_core : newOpCode = CPU74::MOVqr8s_pfix, needsExtension = true; break;
      case CPU74::MOVqr8s_core : newOpCode = CPU74::MOVqr8s_pfix; break;
      case CPU74::MOVrq16_core : newOpCode = CPU74::MOVrq16_pfix; break;
      case CPU74::MOVrq8_core  : newOpCode = CPU74::MOVrq8_pfix; break;
    }
  
  }
  
  assert( newOpCode && "Could not find a way to eliminate frame index" );
  
  // 'ld [fp, imm], Rd' or 'st Rd, [fp, imm]'
  MI.setDesc(TII.get(newOpCode));
  MI.getOperand(FIOperandNum).ChangeToRegister(baseReg, false);
  MI.getOperand(FIOperandNum + 1).ChangeToImmediate(theOffset);
  
  if ( needsExtension )
  {
    unsigned dstReg = MI.getOperand(0).getReg();
    BuildMI(MBB, std::next(II), dl, TII.get(CPU74::ZEXTrr16), dstReg)  // add sign extend
        .addReg(dstReg);
  }
}
