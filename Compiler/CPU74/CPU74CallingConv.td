//==- CPU74CallingConv.td - Calling Conventions for CPU74 -*- tablegen -*-==//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
// This describes the calling conventions for CPU74 architecture.
//===----------------------------------------------------------------------===//


// CPU74 Return Value Calling Convention
def CC_CPU74_Return : CallingConv<
[
  CCIfType< [i16], CCAssignToReg<[R0, R1, R2, R3]> >
]>;


// CPU74 Argument Calling Convention

def CC_CPU74_AssignStack : CallingConv<
[
  // Pass by value if the byval attribute is given
  CCIfByVal< CCPassByVal<2, 2> >,

  // Pass by registers up to 4 arguments
  CCIfType< [i16], CCAssignToReg<[R0, R1, R2, R3]> >,

  // Integer values get stored in stack slots that are 2 bytes in
  // size and 2-byte aligned.
  CCIfType< [i16], CCAssignToStack<2, 2> >
]>;


// CPU74 VarArg Argument Calling Convention

def CC_CPU74_VaArgStack : CallingConv<
[
  // Integer values get stored in stack slots that are 2 bytes in
  // size and 2-byte aligned.
  CCIfType< [i16], CCAssignToStack<2, 2> >
]>;


// CPU74 RTL Calling Convention

def CC_CPU74_Rtlib : CallingConv<
[
  // Pass by registers
  CCIfType< [i16], CCAssignToReg<[R0, R1, R2, R3]> >,

  CCIfType< [i16], CCAssignToStack<2, 2> >
]>;


//===----------------------------------------------------------------------===//
// Callee-saved register lists.
//===----------------------------------------------------------------------===//

def SavedRegs_Normal : CalleeSavedRegs<
(
  add R4, R5, R6, R7
)>;

def SavedRegs_Interrupts : CalleeSavedRegs<
(
  add R0, R1, R2, R3, R4, R5, R6, R7
)>;



