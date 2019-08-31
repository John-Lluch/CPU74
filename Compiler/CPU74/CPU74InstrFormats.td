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

// Relative Call/Jump
class Type1 < bits<1> opcode, dag outs, dag ins, string asmstr, list<dag> pattern>
      : Instruction16< outs, ins, asmstr, pattern>
{
  bits<12> a;   // unbound var
  let Inst{15-13} = 0b111;
  let Inst{12-12} = opcode;
  let Inst{11-0} = a;
}

// Conditional branch
class Type2 < dag outs, dag ins, string asmstr, list<dag> pattern>
      : Instruction16< outs, ins, asmstr, pattern>
{
  bits<3> cc;   // unbound var
  bits<10> a;   // unbound var
  let Inst{15-13} = 0b110;
  let Inst{12-10} = cc;
  let Inst{9-0} = a;
}

// Move, Compare, ALU immediate
class Type3 < bits<3> opcode, dag outs, dag ins, string asmstr, list<dag> pattern>
      : Instruction16< outs, ins, asmstr, pattern>
{
  bits<8> k;   // unbound var
  bits<3> rd;   // unbound var
  let Inst{15-14} = 0b10;
  let Inst{13-11} = opcode;
  let Inst{10-3} = k;
  let Inst{2-0} = rd;
}

// Load/store with immediate offset
class Type4 < bits<2> opcode, dag outs, dag ins, string asmstr, list<dag> pattern>
      : Instruction16< outs, ins, asmstr, pattern>
{
  bits<6> k;    // unbound var
  bits<3> rs;   // unbound var
  bits<3> rd;   // unbound var
  let Inst{15-14} = 0b01;
  let Inst{13-12} = opcode;
  let Inst{11-6} = k;
  let Inst{5-3} = rs;
  let Inst{2-0} = rd;
}

// Three register ALU operation,
// Load/store with register offset
class Type5 < bits<4> opcode, dag outs, dag ins, string asmstr, list<dag> pattern>
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

// Conditional select
class Type6 < dag outs, dag ins, string asmstr, list<dag> pattern>
      : Instruction16< outs, ins, asmstr, pattern>
{
  bits<3> cc;   // unbound var
  bits<3> rn;   // unbound var
  bits<3> rs;   // unbound var
  bits<3> rd;   // unbound var
  let Inst{15-13} = 0b000;
  let Inst{12-10} = cc;
  let Inst{9-9} = 0b1;
  let Inst{8-6} = rn;
  let Inst{5-3} = rs;
  let Inst{2-0} = rd;
}

// Conditional set
class Type7 <dag outs, dag ins, string asmstr, list<dag> pattern>
      : Instruction16< outs, ins, asmstr, pattern>
{
  bits<3> cc;   // unbound var
  bits<3> rd;   // unbound var
  let Inst{15-13} = 0b000;
  let Inst{12-10} = cc;
  let Inst{9-9} = 0b0;
  let Inst{8-6} = 0b111;
  let Inst{5-3} = 0b000;
  let Inst{2-0} = rd;
}

// Zero Operand Instructions
class Type8 < bits<3> opcode, dag outs, dag ins, string asmstr, list<dag> pattern>
      : Instruction16< outs, ins, asmstr, pattern>
{
  let Inst{15-13} = 0b000;
  let Inst{12-10} = opcode;
  let Inst{9-9} = 0b0;
  let Inst{8-6} = 0b110;
  let Inst{5-3} = 0b000;
  let Inst{2-0} = 0b000;
}

// Zero Operand Instructions
class Type8a < bits<3> opcode, dag outs, dag ins, string asmstr, list<dag> pattern>
      : Instruction32< outs, ins, asmstr, pattern>
{
  bits<16> a;     // unbound
  let Inst{31-16} = a;
  let Inst{15-13} = 0b000;
  let Inst{12-10} = opcode;
  let Inst{9-9} = 0b0;
  let Inst{8-6} = 0b110;
  let Inst{5-3} = 0b000;
  let Inst{2-0} = 0b000;
}

// Push/Pop, move SP Register, Branch/Call Indirect
class Type9 < bits<3> opcode, bits<1>mode, dag outs, dag ins, string asmstr, list<dag> pattern>
      : Instruction16< outs, ins, asmstr, pattern>
{
  bits<3> rd;   // unbound var
  let Inst{15-13} = 0b000;
  let Inst{12-10} = opcode;
  let Inst{9-9} = 0b0;
  let Inst{8-7} = 0b10;
  let Inst{6-6} = mode;
  let Inst{5-3} = 0b000;
  let Inst{2-0} = rd;
}

// Move immediate, Load/store with absolute address
class Type9a < bits<3> opcode, bits<1> mode, dag outs, dag ins, string asmstr, list<dag> pattern>
      : Instruction32< outs, ins, asmstr, pattern>
{
  bits<16> a;     // unbound
  bits<3> rd;   // unbound var
  let Inst{31-16} = a;
  let Inst{15-13} = 0b000;
  let Inst{12-10} = opcode;
  let Inst{9-9} = 0b0;
  let Inst{8-7} = 0b10;
  let Inst{6-6} = mode;
  let Inst{5-3} = 0b000;
  let Inst{2-0} = rd;
}

// Two register Move, Compare, ALU operation
class Type10 < bits<3> opcode, bits<2> mode, dag outs, dag ins, string asmstr, list<dag> pattern>
      : Instruction16< outs, ins, asmstr, pattern>
{
  bits<3> rs;   // unbound var
  bits<3> rd;   // unbound var
  let Inst{15-13} = 0b000;
  let Inst{12-10} = opcode;
  let Inst{9-8} = 0b00;
  let Inst{7-6} = mode;
  let Inst{5-3} = rs;
  let Inst{2-0} = rd;
}

// Load/store with immediate offset word
class Type10a < bits<3> opcode, bits<2> mode, dag outs, dag ins, string asmstr, list<dag> pattern>
      : Instruction32< outs, ins, asmstr, pattern>
{
  bits<16> a;     // unbound
  bits<3> rs;   // unbound var
  bits<3> rd;   // unbound var
  let Inst{15-13} = 0b000;
  let Inst{12-10} = opcode;
  let Inst{9-8} = 0b00;
  let Inst{7-6} = mode;
  let Inst{5-3} = rs;
  let Inst{2-0} = rd;
  let Inst{31-16} = a;
}

// Pseudo instruction format
class Pseudo < dag outs, dag ins, string asmstr, list<dag> pattern>
      : Instruction16< outs, ins, asmstr, pattern>
{
  let Inst{15-0} = 0;
  let isPseudo = 1;
}
