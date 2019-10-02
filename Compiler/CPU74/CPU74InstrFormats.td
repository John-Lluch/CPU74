//===-- CPU74InstrFormats.td - CPU74 Instruction Formats -*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source 
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
//  Describe CPU74 instructions format here
//

// Generic CPU74 Instruction Format

class InstructionBase< dag outs, dag ins, string asmstr, list<dag> pattern >
    : Instruction
{
  let Namespace = "CPU74";
  let AsmString   = asmstr;
  let Pattern = pattern;

  let OutOperandList = outs;
  let InOperandList  = ins;
}

// Generic Single Word CPU74 Instruction Format
class Instruction16< dag outs, dag ins, string asmstr, list<dag> pattern >
      : InstructionBase< outs, ins, asmstr, pattern >
{
  field bits<16> Inst = 0;
  let Size = 2;
}

// Generic Two Word CPU74 Instruction Format
class Instruction32< dag outs, dag ins, string asmstr, list<dag> pattern >
      : InstructionBase< outs, ins, asmstr, pattern >
{
  field bits<32> Inst = 0;
  let Size = 4;
}

// Type P

class TypeP_call <dag outs, dag ins, string asmstr, list<dag> pattern>
      : Instruction16< outs, ins, asmstr, pattern>
{
  bits<11> a;   // unbound var
  let Inst{15-11} = 0b11110;
  let Inst{10-0} = a;
}

class TypePP_call <dag outs, dag ins, string asmstr, list<dag> pattern>
      : Instruction32< outs, ins, asmstr, pattern>
{
  bits<16> a;   // unbound var
  let Inst{31-27} = 0b11111;
  let Inst{26-16} = a{15-5};
  let Inst{15-11} = 0b11110;
  let Inst{10-5} = 0b000000;
  let Inst{4-0} = a{4-0};
}

// Type I1

class TypeI1 < bits<3> opcode, dag outs, dag ins, string asmstr, list<dag> pattern>
      : Instruction16< outs, ins, asmstr, pattern>
{
  bits<5> k;    // unbound var
  bits<3> rs;   // unbound var
  bits<3> rd;   // unbound var
  let Inst{15-14} = 0b11;
  let Inst{13-11} = opcode;
  let Inst{10-6} = k;
  let Inst{5-3} = rs;
  let Inst{2-0} = rd;
}

// Type Prefixed I1

class TypePI1 < bits<3> opcode, dag outs, dag ins, string asmstr, list<dag> pattern>
      : Instruction32< outs, ins, asmstr, pattern>
{
  bits<16> K;   // unbound var
  bits<3> rs;   // unbound var
  bits<3> rd;   // unbound var
  let Inst{31-27} = 0b11111;
  let Inst{26-16} = K{15-5};
  let Inst{15-14} = 0b11;
  let Inst{13-11} = opcode;
  let Inst{10-6} = K{4-0};
  let Inst{5-3} = rs;
  let Inst{2-0} = rd;
}

// Type I2

class TypeI2 < bits<5> opcode, dag outs, dag ins, string asmstr, list<dag> pattern>
      : Instruction16< outs, ins, asmstr, pattern>
{
  bits<8> k;   // unbound var
  bits<3> rd;   // unbound var
  let Inst{15-11} = opcode;
  let Inst{10-3} = k;
  let Inst{2-0} = rd;
}

// Type prefixed I2

class TypePI2 < bits<5> opcode, dag outs, dag ins, string asmstr, list<dag> pattern>
      : Instruction32< outs, ins, asmstr, pattern>
{
  bits<16> K;   // unbound var
  bits<3> rd;   // unbound var
  let Inst{31-27} = 0b11111;
  let Inst{26-16} = K{15-5};
  let Inst{15-11} = opcode;
  let Inst{10-8} = 0b000;
  let Inst{7-3} = K{4-0};
  let Inst{2-0} = rd;
}


// Type J

class TypeJ_cc < dag outs, dag ins, string asmstr, list<dag> pattern>
      : Instruction16< outs, ins, asmstr, pattern>
{
  bits<3> cc;   // unbound var
  bits<9> a;   // unbound var
  let Inst{15-12} = 0b0100;
  let Inst{11-9} = cc;
  let Inst{8-0} = a;
}

class TypeJ < bits<1> opcode, dag outs, dag ins, string asmstr, list<dag> pattern>
      : Instruction16< outs, ins, asmstr, pattern>
{
  bits<9> a;   // unbound var
  let Inst{15-10} = 0b001111;
  let Inst{9-9} = opcode;
  let Inst{8-0} = a;
}

// Type Prefixed J

class TypePJ_cc < dag outs, dag ins, string asmstr, list<dag> pattern>
      : Instruction32< outs, ins, asmstr, pattern>
{
  bits<3> cc;   // unbound var
  bits<16> a;   // unbound var
  let Inst{31-27} = 0b11111;
  let Inst{26-16} = a{15-5};
  let Inst{15-12} = 0b0100;
  let Inst{11-9} = cc;
  let Inst{8-5} = 0b0000;
  let Inst{4-0} = a{4-0};
}

class TypePJ < bits<1> opcode, dag outs, dag ins, string asmstr, list<dag> pattern>
      : Instruction32< outs, ins, asmstr, pattern>
{
  bits<16> a;   // unbound var
  let Inst{31-27} = 0b11111;
  let Inst{26-16} = a{15-5};
  let Inst{15-10} = 0b001111;
  let Inst{9-9} = opcode;
  let Inst{8-5} = 0b0000;
  let Inst{4-0} = a{4-0};
}

// Type R1

class TypeR1 < bits<4> opcode, dag outs, dag ins, string asmstr, list<dag> pattern>
      : Instruction16< outs, ins, asmstr, pattern>
{
  bits<3> rd;   // unbound var
  bits<3> rn;   // unbound var
  bits<3> rs;   // unbound var
  let Inst{15-13} = 0b001;
  let Inst{12-9} = opcode;
  let Inst{8-6} = rn;
  let Inst{5-3} = rs;
  let Inst{2-0} = rd;
}

class TypeR1_cc < dag outs, dag ins, string asmstr, list<dag> pattern>
      : Instruction16< outs, ins, asmstr, pattern>
{
  bits<3> cc;   // unbound var
  bits<3> rn;   // unbound var
  bits<3> rs;   // unbound var
  bits<3> rd;   // unbound var
  let Inst{15-12} = 0b0001;
  let Inst{11-9} = cc;
  let Inst{8-6} = rn;
  let Inst{5-3} = rs;
  let Inst{2-0} = rd;
}

// Type R2

class TypeR2_cc <dag outs, dag ins, string asmstr, list<dag> pattern>
      : Instruction16< outs, ins, asmstr, pattern>
{
  bits<3> cc;   // unbound var
  bits<3> rd;   // unbound var
  let Inst{15-12} = 0b0000;
  let Inst{11-9} = cc;
  let Inst{8-6} = 0b111;
  let Inst{5-3} = 0b000;
  let Inst{2-0} = rd;
}

class TypeR2_0 < bits<3> opcode, bits<3> mode, dag outs, dag ins, string asmstr, list<dag> pattern>
      : Instruction16< outs, ins, asmstr, pattern>
{
  let Inst{15-12} = 0b0000;
  let Inst{11-9} = opcode;
  let Inst{8-6} = mode;
  let Inst{5-3} = 0b000;
  let Inst{2-0} = 0b000;
}

class TypeR2_1 < bits<3> opcode, bits<3> mode, dag outs, dag ins, string asmstr, list<dag> pattern>
      : Instruction16< outs, ins, asmstr, pattern>
{
  bits<3> rd;   // unbound var
  let Inst{15-12} = 0b0000;
  let Inst{11-9} = opcode;
  let Inst{8-6} = mode;
  let Inst{5-3} = 0b000;
  let Inst{2-0} = rd;
}

class TypeR2_2 < bits<3> opcode, bits<3> mode, dag outs, dag ins, string asmstr, list<dag> pattern>
      : Instruction16< outs, ins, asmstr, pattern>
{
  bits<3> rs;   // unbound var
  bits<3> rd;   // unbound var
  let Inst{15-12} = 0b0000;
  let Inst{11-9} = opcode;
  let Inst{8-6} = mode;
  let Inst{5-3} = rs;
  let Inst{2-0} = rd;
}

// Pseudo instruction format
class Pseudo < dag outs, dag ins, string asmstr, list<dag> pattern>
      : Instruction16< outs, ins, asmstr, pattern>
{
  let Inst{15-0} = 0;
  let isPseudo = 1;
}
