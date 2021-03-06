//===-- CPU74RegisterInfo.td - CPU74 Register defs -------*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source 
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
//  Declarations that describe the CPU74 register file
//===----------------------------------------------------------------------===//


class CPU74Reg< bits<16> num, string name > : Register<name>
{
  field bits<16> Num = num;
  let HWEncoding = num;
  let Namespace = "CPU74";
}



class CPU74FlagBit< bits<16> num, string name > : Register<name>
{
  field bits<16> Num = num;
  let Namespace = "CPU74";
}

class CPU74StatusRegister< bits<16> num, string name, list<Register> subregs > : RegisterWithSubRegs<name, subregs>
{
  field bits<16> Num = num;
  let Namespace = "CPU74";
}


//===----------------------------------------------------------------------===//
//  Registers
//===----------------------------------------------------------------------===//

def R0  : CPU74Reg<0,  "r0">;
def R1  : CPU74Reg<1,  "r1">;
def R2  : CPU74Reg<2,  "r2">;
def R3  : CPU74Reg<3,  "r3">;
def R4  : CPU74Reg<4,  "r4">;
def R5  : CPU74Reg<5,  "r5">;
def R6  : CPU74Reg<6,  "r6">;
def R7  : CPU74Reg<7,  "r7">;

def SP :  CPU74Reg<11, "SP">;
def PC  : CPU74Reg<15, "PC">;

def GR16 : RegisterClass<"CPU74", [i16], 16,
(
  // Return value and argument registers.
  add R0, R1, R2, R3,
  // Callee saved registers
  R4, R5, R6, R7
)>;


// Legacy
def SSP : RegisterClass<"CPU74", [i16], 16,
(
  add SP
)>;

def FPP : RegisterClass<"CPU74", [i16], 16,
(
  add R7, SP
)>;


// status register definitions

def SR_C : CPU74FlagBit<0,"CARRY">;
def SR_Z : CPU74FlagBit<1,"ZERO">;
def SR_V : CPU74FlagBit<2,"OVERF">;
def SR_S : CPU74FlagBit<3,"SIGN">;

let SubRegIndices = [SubRegIndex<1>, SubRegIndex<1,1>, SubRegIndex<1,2>, SubRegIndex<1,3>] in
{
  def SR : CPU74StatusRegister<0,"FLAGS", [SR_C, SR_Z, SR_V, SR_S]>;
}

// the status register
def SRClass : RegisterClass<"CPU74", [i16], 16,
(
  add SR
)>
{
  let CopyCost = -1;  // Don't allow copying of status registers.
  let isAllocatable = 0;
}



