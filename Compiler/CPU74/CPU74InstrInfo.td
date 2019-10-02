//===-- CPU74InstrInfo.td - CPU74 Instruction defs -------*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source 
// License. See LICENSE.TXT for details.
//
//
// This file describes the CPU74 instructions in TableGen format.
//
// --------------------------------------------------------------------

include "CPU74InstrFormats.td"

// --------------------------------------------------------------------
// Support for alternative assembly instrucion names
// --------------------------------------------------------------------

class AltName < bits<1> alt >
{
  bits<1> a;
  let a = alt;
}

// Enable choice of alternative assembler names
// Set to 0 to use the machine native names
// Set to 1 to use the alternative names
def UseAlt : AltName<1>;

// Helper class
class AsmStr <string normal, string alt, string rest>
{
  string n;
  let n = !strconcat( !if( !eq( UseAlt.a, 0), normal, alt), rest );
}


// --------------------------------------------------------------------
// Type Profiles.
// --------------------------------------------------------------------

// SDTUnaryArithWithFlagsOut - Res1, Flags = op LHS
def SDT_UnaryArithWithFlagsOut : SDTypeProfile<2, 1,
      [SDTCisSameAs<0, 2>, SDTCisInt<0>, SDTCisVT<1, i16>]>;

// SDTUnaryArithWithFlagsInOut - Res1, Flags = op LHS, Flags
def SDT_UnaryArithWithFlagsInOut : SDTypeProfile<2, 2,
      [SDTCisSameAs<0, 2>, SDTCisInt<0>, SDTCisVT<1, i16>, SDTCisVT<3, i16>]>;

// SDTBinaryArithWithFlagsOut - Res1, Flags = op LHS, RHS
def SDT_BinaryArithWithFlagsOut : SDTypeProfile<2, 2,
      [SDTCisSameAs<0, 2>, SDTCisSameAs<0, 3>, SDTCisInt<0>, SDTCisVT<1, i16>]>;

// SDTBinaryArithWithFlagsInOut - Res1, Flags = op LHS, RHS, Flags
def SDT_BinaryArithWithFlagsInOut : SDTypeProfile<2, 3,
      [SDTCisSameAs<0, 2>, SDTCisSameAs<0, 3>, SDTCisInt<0>, SDTCisVT<1, i16>, SDTCisVT<4, i16>]>;

// SDTBinaryTestWithFlagsOut - Flags = op LHS, RHS
def SDT_BinaryTestWithFlagsOut : SDTypeProfile<1, 2,
      [SDTCisVT<0, i16>, SDTCisInt<1>, SDTCisInt<2>]>;

// SDTBinaryTestWithFlagsInOut - Flags = op LHS, RHS, Flags
def SDT_BinaryTestWithFlagsInOut : SDTypeProfile<1, 3,
      [SDTCisVT<0, i16>, SDTCisInt<1>, SDTCisInt<2>, SDTCisVT<3, i16>]>;

// Calling stuff
def SDT_CPU74Call         : SDTypeProfile<0, -1, [SDTCisVT<0, iPTR>]>;             // 0 results, -1 operands?, type is exactly a iPTR
def SDT_CPU74CallSeqStart : SDCallSeqStart<[SDTCisVT<0, i16>, SDTCisVT<1, i16>]>;   // 0 results, 2 operands, operand 0 is i16, operand 1 is i16
def SDT_CPU74CallSeqEnd   : SDCallSeqEnd<[SDTCisVT<0, i16>, SDTCisVT<1, i16>]>;     // 0 results, 2 operands, operand 0 is i16, operand 1 is i16
def SDT_CPU74CallArgLoc   : SDTypeProfile<1, 0, [SDTCisPtrTy<0>]>;                   // 1 result, 0 operands, operands 0 is pointer type

// Convenience wrapper for global addresses
def SDT_CPU74Wrapper      : SDTypeProfile<1, 1, [SDTCisSameAs<0, 1>, SDTCisPtrTy<0>]>; // 1 result, 1 operands, operands 0 and 1 have identical types, pointer type

// void = jmptarget, CC, i16
def SDT_CPU74BrCC         : SDTypeProfile<0, 3, [SDTCisVT<0, OtherVT>, SDTCisVT<1, i16>, SDTCisVT<2, i16>]>;

// Res = CC, flags
def SDT_CPU74SetCC        : SDTypeProfile<1, 2, [SDTCisInt<0>, SDTCisVT<1,i16>, SDTCisVT<2,i16>]>;

// Res = TrueV, FalseV, CC, flags
def SDT_CPU74SelCC        : SDTypeProfile<1, 4, [SDTCisInt<0>, SDTCisSameAs<0, 1>, SDTCisSameAs<0, 2>, SDTCisVT<3,i16>, SDTCisVT<4,i16>]>;


// --------------------------------------------------------------------
// CPU74 Specific Node Definitions.
// --------------------------------------------------------------------

// Wrappers
//def CPU74SingleValWrapper : SDNode<"CPU74ISD::SingleValWrapper", SDT_CPU74Wrapper>;
def CPU74AggregateWrapper : SDNode<"CPU74ISD::AggregateWrapper", SDT_CPU74Wrapper>;

// Calling convention stuff
def CPU74callseq_start : SDNode<"ISD::CALLSEQ_START", SDT_CPU74CallSeqStart, [SDNPHasChain, SDNPOutGlue]>;
def CPU74callseq_end : SDNode<"ISD::CALLSEQ_END",   SDT_CPU74CallSeqEnd, [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue]>;
def CPU74callarg_loc : SDNode<"CPU74ISD::CallArgLoc", SDT_CPU74CallArgLoc, []>;
def CPU74call        : SDNode<"CPU74ISD::CALL", SDT_CPU74Call, [SDNPHasChain, SDNPOutGlue, SDNPOptInGlue, SDNPVariadic]>;

// Returns
def CPU74retflag  : SDNode<"CPU74ISD::RET_FLAG", SDTNone, [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;
def CPU74retiflag : SDNode<"CPU74ISD::RETI_FLAG", SDTNone, [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;

// Conditional instructions
def CPU74brcc     : SDNode<"CPU74ISD::BR_CC", SDT_CPU74BrCC, [SDNPHasChain]>;
def CPU74setcc    : SDNode<"CPU74ISD::SET_CC", SDT_CPU74SetCC>;
def CPU74selcc    : SDNode<"CPU74ISD::SEL_CC", SDT_CPU74SelCC>;

// Compare instruction
def CPU74cmp        : SDNode<"CPU74ISD::CMP",   SDT_BinaryTestWithFlagsOut>;

// Carry flag setting and consuming cmp
def CPU74cmpc        : SDNode<"CPU74ISD::CMPC",   SDT_BinaryTestWithFlagsInOut>;

// Word sign extend
def CPU74sextw   : SDNode<"CPU74ISD::SEXTW", SDTIntUnaryOp, []>;  // 15 bit asr

// Flag setting instructions
def CPU74add:  SDNode<"CPU74ISD::ADD", SDT_BinaryArithWithFlagsOut, [SDNPCommutative, SDNPAssociative]>;
def CPU74sub:  SDNode<"CPU74ISD::SUB", SDT_BinaryArithWithFlagsOut>;
def CPU74and:  SDNode<"CPU74ISD::AND", SDT_BinaryArithWithFlagsOut, [SDNPCommutative, SDNPAssociative]>;
def CPU74or:   SDNode<"CPU74ISD::OR",  SDT_BinaryArithWithFlagsOut, [SDNPCommutative, SDNPAssociative]>;
def CPU74xor:  SDNode<"CPU74ISD::XOR", SDT_BinaryArithWithFlagsOut, [SDNPCommutative, SDNPAssociative]>;

// Carry flag setting and consuming add/sub
def CPU74addc:  SDNode<"CPU74ISD::ADDC", SDT_BinaryArithWithFlagsInOut, [SDNPCommutative]>;
def CPU74subc:  SDNode<"CPU74ISD::SUBC", SDT_BinaryArithWithFlagsInOut>;

// Carry flag setting 1 bit shifts
def CPU74lsl:   SDNode<"CPU74ISD::LSL", SDT_UnaryArithWithFlagsOut, []>;  // one bit shift left (implemented as ADD)
def CPU74lsr:   SDNode<"CPU74ISD::LSR", SDT_UnaryArithWithFlagsOut, []>;  // one bit shift right
def CPU74asr:   SDNode<"CPU74ISD::ASR", SDT_UnaryArithWithFlagsOut, []>;  // one bit shift right arithmetic

// Carry flag setting and consuming 1 bit shifts
def CPU74lslc:  SDNode<"CPU74ISD::LSLC", SDT_UnaryArithWithFlagsInOut, []>;  // one bit rotate left through carry (implemented as ADDC)
def CPU74lsrc:  SDNode<"CPU74ISD::LSRC", SDT_UnaryArithWithFlagsInOut, []>;  // one bit rotate right through carry

// --------------------------------------------------------------------
// Constraint definitions for immediate values.
// --------------------------------------------------------------------

// Return the negation of an immediate value.
// Used to create the negated immediate constraint
def imm_neg_XFORM : SDNodeXForm<imm, [{return CurDAG->getTargetConstant(-(int)N->getZExtValue(), SDLoc(N), MVT::i16);}]>;

// Constraints for immediate operands
def imm8s : ImmLeaf<i16, [{return CPU74Imm::isImm8s(Imm);}]>;   // 8 bit signed immediate
def imm8u : ImmLeaf<i16, [{return CPU74Imm::isImm8u(Imm);}]>;   // 8 bit unsigned immediate
def imm5_d  : ImmLeaf<i16, [{return CPU74Imm::isImm5_d(Imm);}]>;   // 5 bit displaced immediate
def immWord : ImmLeaf<i16, [{return isInt<16>(Imm);}]>;     // value that can't be expressed as a smaller immemdiate
def imm8u_neg : ImmLeaf<i16, [{return CPU74Imm::isImm8u(-Imm);}], imm_neg_XFORM>;  // 8 bit unsigned negated immediate
def imm16u_neg : ImmLeaf<i16, [{return isUInt<16>(-Imm);}], imm_neg_XFORM>;  // 16 bit unsigned negated immediate

// --------------------------------------------------------------------
// Operand definitions.
// --------------------------------------------------------------------

// Memory addressing mode operand base class.
// ( clase base d'operadors en mode de direccionament de memòria )
class MemOperand : Operand<i16> {
  let OperandType = "OPERAND_MEMORY";
}

// Memory pointer with short immediate address mode [Rx,k].
// Does not select Frame Indexes
def memGRImm : MemOperand, ComplexPattern< i16, 2, "SelectARIndexed", [] >
{
  let PrintMethod = "printMemIndexed";
  let MIOperandInfo = (ops GR16:$rs, imm:$k);
}

// Same as above but with print method suitable for LEA instruction
def leaGRImm : MemOperand, ComplexPattern< i16, 2, "SelectARIndexed", [add] >
{
  let PrintMethod = "printLeaIndexed";
  let MIOperandInfo = (ops GR16:$rs, imm:$k);
}

// Memory pointer with immediate address mode.
// Only selects Frame Index [fp,k]
def memFIImm : MemOperand, ComplexPattern< i16, 2, "SelectFIIndexed", [] >
{
  let PrintMethod = "printMemIndexed";
  let MIOperandInfo = (ops SSP:$rs, imm:$k);
}

// Same as above but with print method suitable for LEA instruction
def leaFIImm : MemOperand, ComplexPattern< i16, 2, "SelectFIIndexed", [add, frameindex] >
{
  //let PrintMethod = "printLeaWordIndexed";
  let PrintMethod = "printLeaIndexed";
  let MIOperandInfo = (ops SSP:$rs, imm:$k);
}

// Memory pointer with large immediate address mode [Rx,K] or [Rx,&a].
// Does not select frame indexes
def memWordImm : MemOperand, ComplexPattern< i16, 2, "SelectWordIndexed", [] >
{
  //let PrintMethod = "printMemWordIndexed";
  let PrintMethod = "printMemIndexed";
  let MIOperandInfo = (ops GR16:$rs, imm:$k);
}

// Same as above but with print method suitable for LEA instruction
def leaWordImm : MemOperand, ComplexPattern< i16, 2, "SelectWordIndexed", [add] >
{
  //let PrintMethod = "printMemWordIndexed";
  let PrintMethod = "printLeaIndexed";
  let MIOperandInfo = (ops GR16:$rs, imm:$k);
}

// Memory pointer with absolute address mode [&a].
def memAddr : MemOperand, ComplexPattern< i16, 1, "SelectAddress", [] >
{
  let PrintMethod = "printAddress";
  let MIOperandInfo = (ops imm:$k);
}

// Short jump targets have OtherVT type and are printed as pcrel imm values.
def jmptarget : Operand<OtherVT> {
  let PrintMethod = "printPrgPrivateOperand";
}

// Call addresses that are printed as pcrel imm values.
def calltarget : Operand<OtherVT> {
  let PrintMethod = "printPrgPublicOperand";
}

// Operand for printing a condition code.
def condCode : Operand<i16> {
  let PrintMethod = "printCondCodeOperand";
}

// --------------------------------------------------------------------
// List of callee non-preserved registers
// --------------------------------------------------------------------

class RegList< list<Register> regs>
{
  list<Register> r;
  let r = regs;
}
// These registers are potentially modified by a subroutine
def CallRegs : RegList<[R0, R1, R2, R3, SR /*, AR*/]>;

// --------------------------------------------------------------------
// Stack frame adjustment pseudo instructions
// --------------------------------------------------------------------

// CALLSQ_START/UP implicitly use/def SP because they may be expanded into
// a stack adjustment and the codegen must know that they may modify the stack
// pointer before prolog-epilog rewriting occurs.
// Pessimistically assume CALLSQ_START / CALLSQ_END will become
// sub / add which can affect ASR.

class adjStack< string opcStr, string altOpcStr, SDNode opNode> : Pseudo
                < (outs), (ins i16imm:$amt1, i16imm:$amt2),
                  AsmStr< opcStr, altOpcStr, "\tPSEUDO">.n,
                  [(opNode timm:$amt1, timm:$amt2)]>;

let Defs = [SP, SR /*, AR*/], Uses = [SP] in    // FIX ME: Shoud SR be actually here?
{
  def CALLSQ_START : adjStack< "CALLSQ_START", "CALLSQ_START", CPU74callseq_start >;
  def CALLSQ_END : adjStack< "CALLSQ_END", "CALLSQ_END", CPU74callseq_end >;
}


//class addFrame< string opcStr, string altOpcStr> : Pseudo
//              < (outs GR16:$dst), (ins i16imm:$base, i16imm:$offset),
//                AsmStr< opcStr, altOpcStr, "\tPSEUDO">.n,
//                []>;
//
//let Defs = [SR, AR], Uses = [SP] in
//{
//  def ADDFrame : addFrame< "#ADDframe", "#ADDFrame" >;
//}

// --------------------------------------------------------------------
// Two register Move, Compare, ALU operation
// --------------------------------------------------------------------

class TR2rr16mov<string opcStr, string altOpcStr, bits<3> opcode, bits<3> mode>: TypeR2_2
                <opcode, mode,
                (outs GR16:$rd), (ins GR16:$rs),
                AsmStr< opcStr, altOpcStr, "\t$rs, $rd">.n,
                []>
                {let hasSideEffects = 0;}

class TR2rq16mov<string opcStr, string altOpcStr, bits<3> opcode, bits<3> mode>: TypeR2_2
                <opcode, mode,
                (outs SSP:$rd), (ins GR16:$rs),
                AsmStr< opcStr, altOpcStr, "\t$rs, $rd">.n,
                []>
                //[(set SSP:$rd, GR16:$rs)]>
                {let hasSideEffects = 0;}

class TR2rr16alu_c<string opcStr, string altOpcStr, bits<3> opcode, bits<3> mode>: TypeR2_2
                <opcode, mode,
                (outs GR16:$rd), (ins GR16:$rs),
                AsmStr< opcStr, altOpcStr, "\t$rs, $rd">.n,
                []>;

// Move
def MOVrr16 : TR2rr16mov< "mov_rr", "mov", 0b000, 0b000 >;
def MOVrq16 : TR2rq16mov< "mov_rq", "mov", 0b001, 0b000 >;

// Extend
def ZEXTrr16  : TR2rr16alu_c< "zext",  "zext",  0b010, 0b000 >;
def SEXTrr16  : TR2rr16alu_c< "sext",  "sext",  0b011, 0b000 >;
def SWAPrr16  : TR2rr16alu_c< "bswap", "bswap", 0b100, 0b000 >;
def SEXTWrr16 : TR2rr16alu_c< "sextw", "sextw", 0b101, 0b000 >;

def : Pat<(and GR16:$rs, 255),            (ZEXTrr16 GR16:$rs)>;
def : Pat<(sext_inreg GR16:$rs, i8),      (SEXTrr16 GR16:$rs)>;
def : Pat<(bswap GR16:$rs),               (SWAPrr16 GR16:$rs)>;

def : Pat<(CPU74sextw GR16:$rs),          (SEXTWrr16 GR16:$rs)>;
def : Pat<(sra GR16:$rs, (i16 15)),             (SEXTWrr16 GR16:$rs)>;

// Shifts
let Defs = [SR] in
{
  def LSRrr16  : TR2rr16alu_c< "lsr", "lsr",  0b000, 0b001 >;
  def ASRrr16  : TR2rr16alu_c< "asr", "asr",  0b010, 0b001 >;

  let Uses = [SR] in { def LSRCrr16  : TR2rr16alu_c< "lsrc", "lsrc",  0b011, 0b001 >; }
}


def : Pat<(CPU74lsr GR16:$rs),    (LSRrr16 $rs)>;
def : Pat<(CPU74asr GR16:$rs),    (ASRrr16 $rs)>;

// right shift pairs
def : Pat<(CPU74lsrc GR16:$rs, SR),   (LSRCrr16 GR16:$rs)>;

// Neg, not
let Defs = [SR] in
{
  def NEGrr16 : TR2rr16alu_c< "neg", "neg", 0b101, 0b001 >;
}

let Defs = [SR] in
{
  def NOTrr16 : TR2rr16alu_c< "not", "not", 0b110, 0b001 >;
}

def : Pat<(ineg GR16:$rd0),        (NEGrr16 $rd0)>;
def : Pat<(not GR16:$rd0),         (NOTrr16 $rd0)>;

// ---------------------------------------------------------------------
// Move, Compare, Add, Subtract immediate
// ---------------------------------------------------------------------

multiclass TI2kr16mov<string opcStr, string altOpcStr, bits<5> opcode>
{
  def _core : TypeI2
                <opcode,
                (outs GR16:$rd), (ins i16imm:$k),
                AsmStr< opcStr, altOpcStr, "\t$k, $rd">.n,
                [(set GR16:$rd, imm8s:$k)]>
                {let isAsCheapAsAMove = 1; let isReMaterializable = 1; let isMoveImm = 1;}

  def _pfix : TypePI2
                <opcode,
                (outs GR16:$rd), (ins i16imm:$K),  // immLarge
                AsmStr< opcStr, altOpcStr, "\t$K, $rd">.n,
                [(set GR16:$rd, immWord:$K)]>
                {let isReMaterializable = 1; let isMoveImm = 1;}
}

multiclass TI2kr16cmp<string opcStr, string altOpcStr, bits<5> opcode >
{
  def _core : TypeI2
                <opcode,
                (outs), (ins GR16:$rd, i16imm:$k),
                AsmStr< opcStr, altOpcStr, "\t$rd, $k">.n,
                //[(set SR, (CPU74cmp GR16:$rd, imm8s:$k))]>
                []>
                {let isCompare = 1; let isReMaterializable = 1;}
  
  def _pfix : TypePI2
                <opcode,
                (outs), (ins GR16:$rd, i16imm:$k),      // immLarge
                AsmStr< opcStr, altOpcStr, "\t$rd, $k">.n,
                //[(set SR, (CPU74cmp GR16:$rd, imm8s:$k))]>
                []>
                {let isCompare = 1; let isReMaterializable = 1;}
}

multiclass TI2kr16alu_c<string opcStr, string altOpcStr, bits<5> opcode>
{
  def _core : TypeI2
                <opcode,
                (outs GR16:$rd), (ins GR16:$rd0, i16imm:$k),
                AsmStr< opcStr, altOpcStr, "\t$rd0, $k, $rd">.n,
                []>
                {let Constraints = "$rd0 = $rd";
                 let isAsCheapAsAMove = 1; let isReMaterializable = 1;}
                
  def _pfix : TypePI2
                <opcode,
                (outs GR16:$rd), (ins GR16:$rd0, i16imm:$k),    // immLarge
                AsmStr< opcStr, altOpcStr, "\t$rd0, $k, $rd">.n,
                []>
                {let Constraints = "$rd0 = $rd";
                 let isReMaterializable = 1;}
}


defm MOVkr16 : TI2kr16mov< "mov_kr", "mov", 0b01010 >;

let Defs = [SR] in
{
  defm CMPkr16 : TI2kr16cmp< "cmp_rk", "cmp", 0b01011>;
}

let Defs = [SR] in
{
  defm ADDkr16 : TI2kr16alu_c< "add_kr", "add", 0b01100>;
  defm SUBkr16 : TI2kr16alu_c< "sub_kr", "sub", 0b01101>;   // may get selected as a negated add
}

let Defs = [SR] in
{
  defm ANDkr16 : TI2kr16alu_c< "and_kr", "and", 0b01110>;
}

// move, compare
def : Pat<(CPU74cmp GR16:$rd, imm8s:$k),       (CMPkr16_core GR16:$rd, imm8s:$k)>;
def : Pat<(CPU74cmp GR16:$rd, immWord:$k),     (CMPkr16_pfix GR16:$rd, immWord:$k)>;

// add, sub
def : Pat<(add GR16:$rd0, imm8u:$k),       (ADDkr16_core GR16:$rd0, imm8u:$k)>;
def : Pat<(sub GR16:$rd0, imm8u:$k),       (SUBkr16_core GR16:$rd0, imm8u:$k)>;
def : Pat<(add GR16:$rd0, imm8u_neg:$k),   (SUBkr16_core GR16:$rd0, imm8u_neg:$k)>;

def : Pat<(add GR16:$rd0, immWord:$k),     (ADDkr16_pfix GR16:$rd0, immWord:$k)>;
def : Pat<(sub GR16:$rd0, immWord:$k),     (SUBkr16_pfix GR16:$rd0, immWord:$k)>;
def : Pat<(add GR16:$rd0, imm16u_neg:$k),  (SUBkr16_pfix GR16:$rd0, imm16u_neg:$k)>;

// add, sub tests
def : Pat<(CPU74add GR16:$rd0, imm8u:$k),      (ADDkr16_core GR16:$rd0, imm8u:$k)>;
def : Pat<(CPU74sub GR16:$rd0, imm8u:$k),      (SUBkr16_core GR16:$rd0, imm8u:$k)>;
def : Pat<(CPU74add GR16:$rd0, imm8u_neg:$k),  (SUBkr16_core GR16:$rd0, imm8u_neg:$k)>;

def : Pat<(CPU74add GR16:$rd0, immWord:$k),    (ADDkr16_pfix GR16:$rd0, immWord:$k)>;
def : Pat<(CPU74sub GR16:$rd0, immWord:$k),    (SUBkr16_pfix GR16:$rd0, immWord:$k)>;
def : Pat<(CPU74add GR16:$rd0, imm16u_neg:$k), (SUBkr16_pfix GR16:$rd0, imm16u_neg:$k)>;

// and
def : Pat<(and GR16:$rn, imm8u:$k),    (ANDkr16_core GR16:$rn, imm8u:$k)>;
def : Pat<(and GR16:$rn, immWord:$k),    (ANDkr16_pfix GR16:$rn, immWord:$k)>;

// and test
def : Pat<(CPU74and GR16:$rn, imm8u:$k),    (ANDkr16_core GR16:$rn, imm8u:$k)>;
def : Pat<(CPU74and GR16:$rn, immWord:$k),    (ANDkr16_pfix GR16:$rn, immWord:$k)>;


// -------------------------------------------------------------------------
// SP add signed immediate
// -------------------------------------------------------------------------

multiclass TJkq16add<string opcStr, string altOpcStr, bits<1> opcode>
{
  def _core : TypeJ
                <opcode,
                (outs SSP:$rd), (ins SSP:$rd0, i16imm:$k),
                AsmStr< opcStr, altOpcStr, "\t$rd0, $k, $rd">.n,
                []>
                {let Constraints = "$rd0 = $rd";}

  def _pfix : TypePJ
                <opcode,
                (outs SSP:$rd), (ins SSP:$rd0, i16imm:$k),
                AsmStr< opcStr, altOpcStr, "\t$rd0, $k, $rd">.n,
                []>
                {let Constraints = "$rd0 = $rd";}
}

defm ADDkq16  : TJkq16add< "add_kq", "add", 0b0 >;

// --------------------------------------------------------------------
// Conditional branch
// --------------------------------------------------------------------

multiclass TJbrcc<string opcStr, string altOpcStr>
{
  def _core: TypeJ_cc
                <
                (outs), (ins jmptarget:$a, condCode:$cc),
                AsmStr< opcStr, altOpcStr, "$cc\t$a">.n,
                []>
                {let isBranch = 1; let isTerminator = 1;}
                
  def _pfix: TypePJ_cc
                <
                (outs), (ins jmptarget:$a, condCode:$cc),
                AsmStr< opcStr, altOpcStr, "$cc\t$a">.n,
                []>
                {let isBranch = 1; let isTerminator = 1;}
}

let Uses = [SR] in
{
  defm BRCC  : TJbrcc< "br", "br"> ;
}

def : Pat<(CPU74brcc bb:$a, imm:$cc, SR), (BRCC_core bb:$a, imm:$cc)>;


// -------------------------------------------------------------------------
// Unconditional Branch
// -------------------------------------------------------------------------

multiclass TJjump<string opcStr, string altOpcStr, bits<1> opcode>
{
  def _core : TypeJ
                <opcode,
                (outs), (ins jmptarget:$a),
                AsmStr< opcStr, altOpcStr, "\t$a">.n,
                //[(br bb:$a)]>
                []>
                {let isBranch = 1; let isTerminator = 1; let isBarrier = 1;}

  def _pfix : TypePJ
                <opcode,
                (outs), (ins jmptarget:$a),
                AsmStr< opcStr, altOpcStr, "\t$a">.n,
                //[(br bb:$a)]>
                []>
                {let isBranch = 1; let isTerminator = 1; let isBarrier = 1;}
}

defm JMP  : TJjump< "jmp_k", "jmp", 0b1 >;

// relative unconditinal jump
def : Pat<(br bb:$a), (JMP_core bb:$a)>;

// -------------------------------------------------------------------------
// Call
// -------------------------------------------------------------------------

multiclass TPcall<string opcStr, string altOpcStr>
{
  def _core : TypeP_call
                <
                (outs), (ins calltarget:$a),
                AsmStr< opcStr, altOpcStr, "\t$a">.n,
                []>
                {let isCall = 1;}

  def _pfix : TypePP_call
                <
                (outs), (ins calltarget:$a),
                AsmStr< opcStr, altOpcStr, "\t$a">.n,
                []>
                {let isCall = 1;}
}

let Defs = CallRegs.r, Uses = [SP] in
{
  defm CALL : TPcall< "call_k", "call" >;
}
// absolute call
// conservativelly create prefixed calls
def : Pat<(CPU74call tglobaladdr:$a),  (CALL_pfix tglobaladdr:$a)>;
def : Pat<(CPU74call texternalsym:$a), (CALL_pfix texternalsym:$a)>;


// ---------------------------------------------------------------------
// Load/store frame index with immediate offset
// ---------------------------------------------------------------------

multiclass TI2qrlea<string opcStr, string altOpcStr, bits<5> opcode>
{
  def _core: TypeI2
                <opcode,
                (outs GR16:$rd), (ins leaFIImm:$scr),
                AsmStr< opcStr, altOpcStr, "\t$scr, $rd">.n,
                [(set GR16:$rd, leaFIImm:$scr)]>
                {let isReMaterializable = 1;}
                
  def _pfix: TypePI2
                <opcode,
                (outs GR16:$rd), (ins leaFIImm:$scr),
                AsmStr< opcStr, altOpcStr, "\t$scr, $rd">.n,
                [(set GR16:$rd, leaFIImm:$scr)]>
                {let isReMaterializable = 1;}
}


multiclass TI2qrmov<string opcStr, string altOpcStr, bits<5> opcode>
{
  def _core: TypeI2
                <opcode,
                (outs GR16:$rd), (ins memFIImm:$src),
                AsmStr< opcStr, altOpcStr, "\t$src, $rd">.n,
                []>
                {let canFoldAsLoad = 1; let isReMaterializable = 1;}

  def _pfix: TypePI2
                <opcode,
                (outs GR16:$rd), (ins memFIImm:$src),
                AsmStr< opcStr, altOpcStr, "\t$src, $rd">.n,
                []>
                {let canFoldAsLoad = 1; let isReMaterializable = 1;}
}

multiclass TI2rqmov<string opcStr, string altOpcStr, bits<5> opcode>
{
  def _core: TypeI2
                <opcode,
                (outs), (ins GR16:$rd, memFIImm:$dst),
                AsmStr< opcStr, altOpcStr, "\t$rd, $dst">.n,
                []>;
                
  def _pfix: TypePI2
                <opcode,
                (outs), (ins GR16:$rd, memFIImm:$dst),
                AsmStr< opcStr, altOpcStr, "\t$rd, $dst">.n,
                []>;
}

defm LEAqr16 : TI2qrlea< "lea_qr",  "lea",   0b10011 >;

defm MOVqr16 : TI2qrmov< "movw_qr", "ld.w",   0b10100 >;
defm MOVqr8z : TI2qrmov< "movzb_qr", "ld.zb", 0>;  // This is a pseudo instruction
defm MOVqr8s : TI2qrmov< "movsb_qr", "ld.sb", 0b10101 >;

defm MOVrq16 : TI2rqmov< "movw_rq", "st.w",   0b10110 >;
defm MOVrq8  : TI2rqmov< "movb_rq", "st.b",   0b10111 >;

// loads
def : Pat<(load memFIImm:$src),        (MOVqr16_core memFIImm:$src)>;
def : Pat<(sextloadi8 memFIImm:$src),  (MOVqr8s_core memFIImm:$src)>;

// Zero Extend load instruction (MOVqr8z) does not physically exist, we are selecting it
// in relation with frame index stuff. In such case the instruction may
// get replaced during 'eliminateFrameIndex' by MOVqr8s, ZEXTrr16.
def : Pat<(zextloadi8 memFIImm:$src),  (MOVqr8z_core memFIImm:$src)>;

// AnyExt loads are converted to sextloads
def : Pat<(extloadi8 memFIImm:$src),   (MOVqr8s_core memFIImm:$src)>;

//// ZeroExt load instruction does not physically exist, we are selecting it
//// in two possible ways
//// (1) Based on ZEXTrr16, MOVmr8s
//// (2) In relation with frame index stuff. In such case the instruction may
//// get replaced during 'eliminateFrameIndex' by MOVmr8s, ZEXTrr16 or by MOVMr8z.
//def : Pat<(zextloadi8 memGRImm:$src),  (ZEXTrr16 (MOVqr8s memGRImm:$src))>;
//def : Pat<(zextloadi8 memFIImm:$src),  (MOVqr8z memFIImm:$src)>;

// stores
def : Pat<(store GR16:$rd, memFIImm:$dst),  (MOVrq16_core GR16:$rd, memFIImm:$dst)>;
def : Pat<(truncstorei8 GR16:$rd, memFIImm:$dst),  (MOVrq8_core  GR16:$rd, memFIImm:$dst)>;


// ---------------------------------------------------------------------
// Load/store with immediate offset
// ---------------------------------------------------------------------

multiclass TI1mrlea_k<string opcStr, string altOpcStr, bits<3> opcode>
{
  def _core: TypeI1
                <opcode,
                (outs GR16:$rd), (ins GR16:$rs, i16imm:$k),
                AsmStr< opcStr, altOpcStr, "\t$rs, $k, $rd">.n,
                []>
                {let isReMaterializable = 1;}
          
  def _pfix : TypePI1
                <opcode,
                (outs GR16:$rd), (ins GR16:$rs, i16imm:$K),  // immLarge
                AsmStr< opcStr, altOpcStr, "\t$rs, $K, $rd">.n,
                []>;
}

multiclass TI1mrmov_c<string opcStr, string altOpcStr, bits<3> opcode>
{
  def _core: TypeI1
                <opcode,
                (outs GR16:$rd), (ins memGRImm:$src),
                AsmStr< opcStr, altOpcStr, "\t$src, $rd">.n,
                []>
                {let canFoldAsLoad = 1; let isReMaterializable = 1;}
                
  def _pfix: TypePI1
                <opcode,
                (outs GR16:$rd), (ins memWordImm:$src),
                AsmStr< opcStr, altOpcStr, "\t$src, $rd">.n,
                []>
                {let canFoldAsLoad = 1; let isReMaterializable = 1;}
}

multiclass TI1rmmov_c<string opcStr, string altOpcStr, bits<3> opcode>
{
  def _core: TypeI1
                <opcode,
                (outs), (ins GR16:$rd, memGRImm:$dst),
                AsmStr< opcStr, altOpcStr, "\t$rd, $dst">.n,
                []>;

  def _pfix: TypePI1
                <opcode,
                (outs), (ins GR16:$rd, memWordImm:$dst),
                AsmStr< opcStr, altOpcStr, "\t$rd, $dst">.n,
                []>;
}

defm LEArkr16 : TI1mrlea_k< "lea_rkr",  "lea",   0b000 >;
//def LEAmr16 : TI1mrlea_c< "lea_mr",  "add",   0b000 >;

defm MOVmr16 : TI1mrmov_c< "movw_mr",  "ld.w",  0b001 >;
defm MOVmr8z : TI1mrmov_c< "movzb_mr", "ld.zb", 0b010>;
defm MOVmr8s : TI1mrmov_c< "movsb_mr", "ld.sb", 0b011 >;

defm MOVrm16 : TI1rmmov_c< "movw_rm",  "st.w",  0b100 >;
defm MOVrm8  : TI1rmmov_c< "movb_rm",  "st.b",  0b101 >;

// lea
let AddedComplexity = 1 in {
  def : Pat<(add GR16:$rs, imm5_d:$K),     (LEArkr16_core GR16:$rs, imm5_d:$K)>; }

def : Pat<(add GR16:$rs, immWord:$K),    (LEArkr16_pfix GR16:$rs, immWord:$K)>;

// loads
def : Pat<(load memGRImm:$src),          (MOVmr16_core memGRImm:$src)>;
def : Pat<(zextloadi8 memGRImm:$src),    (MOVmr8z_core memGRImm:$src)>;
def : Pat<(sextloadi8 memGRImm:$src),    (MOVmr8s_core memGRImm:$src)>;
def : Pat<(load memWordImm:$src),        (MOVmr16_pfix memWordImm:$src)>;
def : Pat<(zextloadi8 memWordImm:$src),  (MOVmr8z_pfix memWordImm:$src)>;
def : Pat<(sextloadi8 memWordImm:$src),  (MOVmr8s_pfix memWordImm:$src)>;

// AnyExt loads are converted to sextloads
def : Pat<(extloadi8 memGRImm:$src),   (MOVmr8s_core memGRImm:$src)>;
def : Pat<(extloadi8 memWordImm:$src),   (MOVmr8s_pfix memWordImm:$src)>;

// stores
def : Pat<(store GR16:$rd, memGRImm:$dst),  (MOVrm16_core GR16:$rd, memGRImm:$dst)>;
def : Pat<(truncstorei8 GR16:$rd, memGRImm:$dst),  (MOVrm8_core GR16:$rd, memGRImm:$dst)>;
def : Pat<(store GR16:$rd, memWordImm:$dst),  (MOVrm16_pfix GR16:$rd, memWordImm:$dst)>;
def : Pat<(truncstorei8 GR16:$rd, memWordImm:$dst),  (MOVrm8_pfix  GR16:$rd, memWordImm:$dst)>;


// --------------------------------------------------------------------
// Move Immediate, Load/store with absolute address
// --------------------------------------------------------------------

multiclass TI2armov_c<string opcStr, string altOpcStr, bits<5> opcode>
{
  def _core : TypeI2
                <opcode,
                (outs GR16:$rd), (ins i16imm:$a),
                AsmStr< opcStr, altOpcStr, "\t$a, $rd">.n,
                []>
                {let canFoldAsLoad = 1; let isReMaterializable = 1;}
  
  def _pfix : TypePI2
                <opcode,
                (outs GR16:$rd), (ins memAddr:$a),
                AsmStr< opcStr, altOpcStr, "\t$a, $rd">.n,
                []>
                {let canFoldAsLoad = 1; let isReMaterializable = 1;}
}

multiclass TI2ramov_c<string opcStr, string altOpcStr, bits<5> opcode>
{
  def _core: TypeI2
                <opcode,
                (outs), (ins GR16:$rd, i16imm:$a),       // $a must be the second argument to correctly generate the bitcode
                AsmStr< opcStr, altOpcStr, "\t$rd, $a">.n,
                []>;
  
  def _pfix: TypePI2
                <opcode,
                (outs), (ins GR16:$rd, memAddr:$a),       // $a must be the second argument to correctly generate the bitcode
                AsmStr< opcStr, altOpcStr, "\t$rd, $a">.n,
                []>;
}

defm MOVar16 : TI2armov_c< "movw_ar",  "ld.w",  0b01111 >;
defm MOVsar8 : TI2armov_c< "movsb_ar", "ld.sb", 0b10000 >;

defm MOVra16 : TI2ramov_c< "movw_ra",  "st.w",  0b10001 >;
defm MOVra8  : TI2ramov_c< "movb_ra",  "st.b",  0b10010 >;

// loads
def : Pat<(load imm8u:$a),           (MOVar16_core imm8u:$a)>;
def : Pat<(zextloadi8 imm8u:$a),     (ZEXTrr16 (MOVsar8_core imm8u:$a))>;
def : Pat<(sextloadi8 imm8u:$a),     (MOVsar8_core imm8u:$a)>;

def : Pat<(load memAddr:$a),         (MOVar16_pfix memAddr:$a)>;
def : Pat<(zextloadi8 memAddr:$a),   (ZEXTrr16 (MOVsar8_pfix memAddr:$a))>;
def : Pat<(sextloadi8 memAddr:$a),   (MOVsar8_pfix memAddr:$a)>;

// AnyExt loads are converted to sextloads
def : Pat<(extloadi8 imm8u:$a),   (MOVsar8_core imm8u:$a)>;
def : Pat<(extloadi8 memAddr:$a),   (MOVsar8_pfix memAddr:$a)>;

// stores
def : Pat<(store GR16:$rd, imm8u:$a), (MOVra16_core GR16:$rd, imm8u:$a)>;
def : Pat<(truncstorei8 GR16:$rd, imm8u:$a), (MOVra8_core GR16:$rd, imm8u:$a)>;
def : Pat<(store GR16:$rd, memAddr:$a), (MOVra16_pfix GR16:$rd, memAddr:$a)>;
def : Pat<(truncstorei8 GR16:$rd, memAddr:$a), (MOVra8_pfix GR16:$rd, memAddr:$a)>;

// Patterns for moving global adresses directly into registers

def : Pat<(CPU74AggregateWrapper tglobaladdr:$a), (MOVkr16_pfix tglobaladdr:$a)>;
def : Pat<(CPU74AggregateWrapper texternalsym:$a), (MOVkr16_pfix texternalsym:$a)>;
def : Pat<(CPU74AggregateWrapper tblockaddress:$a), (MOVkr16_pfix tblockaddress:$a)>;
def : Pat<(CPU74AggregateWrapper tjumptable:$a), (MOVkr16_pfix tjumptable:$a)>;


// --------------------------------------------------------------------
// Load/store with register offset
// --------------------------------------------------------------------

class TR1nrmov_c<string opcStr, string altOpcStr, bits<4> opcode>: TypeR1
                <opcode,
                (outs GR16:$rd), (ins GR16:$rs, GR16:$rn),
                AsmStr< opcStr, altOpcStr, "\t[$rs, $rn], $rd">.n,
                []>
                {let isReMaterializable = 1;}

class TR1rnmov_c<string opcStr, string altOpcStr, bits<4> opcode>: TypeR1
                <opcode,
                (outs), (ins GR16:$rd, GR16:$rs, GR16:$rn),
                AsmStr< opcStr, altOpcStr, "\t$rd, [$rs, $rn]">.n,
                []>;

def MOVnr16 : TR1nrmov_c< "movw_nr",  "ld.w",  0b1001 >;
def MOVnr8z : TR1nrmov_c< "movzb_nr", "ld.zb", 0b1010 >;
def MOVnr8s : TR1nrmov_c< "movsb_nr", "ld.sb", 0b1011 >;

def MOVrn16 : TR1rnmov_c< "movw_rn", "st.w",   0b1100 >;
def MOVrn8  : TR1rnmov_c< "movb_rn", "st.b",   0b1101 >;

// loads
def : Pat<(load (add GR16:$rs, GR16:$rn)),        (MOVnr16 GR16:$rs, GR16:$rn)>;
def : Pat<(zextloadi8 (add GR16:$rs, GR16:$rn)),  (MOVnr8z GR16:$rs, GR16:$rn)>;
def : Pat<(sextloadi8 (add GR16:$rs, GR16:$rn)),  (MOVnr8s GR16:$rs, GR16:$rn)>;

// AnyExt loads are translated into sext loads
def : Pat<(extloadi8 (add GR16:$rs, GR16:$rn)),  (MOVnr8z GR16:$rs, GR16:$rn)>;

// stores
def : Pat<(store GR16:$rd, (add GR16:$rs, GR16:$rn)),       (MOVrn16 GR16:$rd, GR16:$rs, GR16:$rn)>;
def : Pat<(truncstorei8 GR16:$rd, (add GR16:$rs, GR16:$rn)), (MOVrn8 GR16:$rd, GR16:$rs, GR16:$rn)>;


// --------------------------------------------------------------------
// Three register ALU operation
// --------------------------------------------------------------------

class TR1rrr16alu_c<string opcStr, string altOpcStr, bits<4> opcode>: TypeR1
                <opcode,
                (outs GR16:$rd), (ins GR16:$rs, GR16:$rn),
                AsmStr< opcStr, altOpcStr, "\t$rs, $rn, $rd">.n,
                []>
                {let isReMaterializable = 1;}

class TR1rr16cmp<string opcStr, string altOpcStr, bits<4> opcode>: TypeR1
                <opcode,
                (outs), (ins GR16:$rs, GR16:$rn),
                AsmStr< opcStr, altOpcStr, "\t$rs, $rn">.n,
                []>
                {let isCompare = 1; let isReMaterializable = 1;}

let Defs = [SR] in
{
  def CMPrr16 : TR1rr16cmp< "cmp_rr", "cmp", 0b0000 >;
}

let Defs = [SR] in
{
  let Uses = [SR] in { def CMPCrr16 : TR1rr16cmp< "cmpc_rr", "cmpc", 0b0001 >; }
}

let Defs = [SR] in
{
  def ADDrrr16 : TR1rrr16alu_c< "add_rrr", "add", 0b1000 >;
  def SUBrrr16 : TR1rrr16alu_c< "sub_rrr", "sub", 0b0010 >;
}

let Defs = [SR] in
{
  let Uses = [SR] in { def ADDCrrr16 : TR1rrr16alu_c< "addc_rrr", "addc", 0b0100 >; }
  let Uses = [SR] in { def SUBCrrr16 : TR1rrr16alu_c< "subc_rrr", "subc", 0b0011 >; }
}

let Defs = [SR] in
{
  def ORrrr16  : TR1rrr16alu_c< "or_rrr",  "or",  0b0101 >;
  def ANDrrr16 : TR1rrr16alu_c< "and_rrr", "and", 0b0110 >;
  def XORrrr16 : TR1rrr16alu_c< "xor_rrr", "xor", 0b0111 >;
}

// compare
def : Pat<(CPU74cmp GR16:$rs, GR16:$rn),  (CMPrr16 GR16:$rs, GR16:$rn)>;

// compare pairs
def : Pat<(CPU74cmpc GR16:$rs, GR16:$rn, SR),  (CMPCrr16 GR16:$rs, GR16:$rn)>;

// add sub
def : Pat<(add GR16:$rs, GR16:$rn),    (ADDrrr16 GR16:$rs, GR16:$rn)>;
def : Pat<(sub GR16:$rs, GR16:$rn),    (SUBrrr16 GR16:$rs, GR16:$rn)>;

// add, sub tests
def : Pat<(CPU74add GR16:$rs, GR16:$rn),    (ADDrrr16 GR16:$rs, GR16:$rn)>;
def : Pat<(CPU74sub GR16:$rs, GR16:$rn),    (SUBrrr16 GR16:$rs, GR16:$rn)>;

// logical
def : Pat<(or GR16:$rs,  GR16:$rn),     (ORrrr16 GR16:$rs, GR16:$rn)>;
def : Pat<(and GR16:$rs, GR16:$rn),    (ANDrrr16 GR16:$rs, GR16:$rn)>;
def : Pat<(xor GR16:$rs, GR16:$rn),    (XORrrr16 GR16:$rs, GR16:$rn)>;

// logical tests
def : Pat<(CPU74or  GR16:$rs, GR16:$rn),     (ORrrr16 GR16:$rs, GR16:$rn)>;
def : Pat<(CPU74and GR16:$rs, GR16:$rn),    (ANDrrr16 GR16:$rs, GR16:$rn)>;
def : Pat<(CPU74xor GR16:$rs, GR16:$rn),    (XORrrr16 GR16:$rs, GR16:$rn)>;

// pairs
def : Pat<(CPU74addc GR16:$rs, GR16:$rn, SR),  (ADDCrrr16 GR16:$rs, GR16:$rn)>;
def : Pat<(CPU74subc GR16:$rs, GR16:$rn, SR),  (SUBCrrr16 GR16:$rs, GR16:$rn)>;

// 1 bit left shifts
def : Pat<(CPU74lsl GR16:$rs),     (ADDrrr16 GR16:$rs, GR16:$rs)>;

// left shift pairs
def : Pat<(CPU74lslc GR16:$rs, SR),   (ADDCrrr16 GR16:$rs, GR16:$rs)>;


// --------------------------------------------------------------------
// Conditional select
// --------------------------------------------------------------------

class TR1ccrrrsel<string opcStr, string altOpcStr>: TypeR1_cc
                <
                (outs GR16:$rd), (ins GR16:$rs, GR16:$rn, condCode:$cc),
                AsmStr< opcStr, altOpcStr, "$cc\t$rs, $rn, $rd">.n,
                []>
                {let isAsCheapAsAMove = 1; let isReMaterializable = 1;}

let Uses = [SR] in
{
  def SELCC : TR1ccrrrsel< "sel", "sel">;
}

def : Pat<(CPU74selcc GR16:$rs, GR16:$rn, imm:$cc, SR),  (SELCC GR16:$rs, GR16:$rn, imm:$cc)>;


// --------------------------------------------------------------------
// Conditional set
// --------------------------------------------------------------------

class TR2ccrset<string opcStr, string altOpcStr>: TypeR2_cc
                <
                (outs GR16:$rd), (ins condCode:$cc),
                AsmStr< opcStr, altOpcStr, "$cc\t$rd">.n,
                []>
                {let isAsCheapAsAMove = 1; let isReMaterializable = 1;}

let Uses = [SR] in
{
  def SETCC : TR2ccrset< "set", "set">;
}

def : Pat<(CPU74setcc imm:$cc, SR), (SETCC imm:$cc)>;


// --------------------------------------------------------------------
// Zero operand instructions
// --------------------------------------------------------------------

class TR2basic<string opcStr, string altOpcStr, bits<3> opcode, bits<3> mode>: TypeR2_0
                <opcode, mode,
                (outs), (ins),
                AsmStr< opcStr, altOpcStr, "">.n,
                []>;

let isReturn = 1, isTerminator = 1, isBarrier = 1 in
{
  def RET  : TR2basic< "ret",  "ret",  0b000, 0b110>;
  def RETI : TR2basic< "reti", "reti", 0b001, 0b110>;
}

def : Pat<(CPU74retflag), (RET)>;
def : Pat<(CPU74retiflag), (RETI)>;


// --------------------------------------------------------------------
// Branch/Call indirect
// --------------------------------------------------------------------

class TR2JumpReg<string opcStr, string altOpcStr, bits<3> opcode, bits<3> mode>: TypeR2_1
                <opcode, mode,
                (outs), (ins GR16:$rd),
                AsmStr< opcStr, altOpcStr, "\t$rd">.n,
                []>
                {let isBranch = 1; let isTerminator = 1; let isBarrier = 1; let isIndirectBranch = 1;}

class TR2CallReg<string opcStr, string altOpcStr, bits<3> opcode, bits<3> mode>: TypeR2_1
                <opcode, mode,
                (outs), (ins GR16:$rd),
                AsmStr< opcStr, altOpcStr, "\t$rd">.n,
                []>
                {let isCall = 1;}

def JMPreg  : TR2JumpReg< "jmp_r", "jmp", 0b000, 0b100 >;

let Defs = CallRegs.r, Uses = [SP] in
{
  def CALLreg : TR2CallReg< "call_r", "call", 0b001, 0b100 >;
}

def : Pat<(brind GR16:$rd),      (JMPreg GR16:$rd)>;
def : Pat<(CPU74call GR16:$rd),  (CALLreg GR16:$rd)>;


// --------------------------------------------------------------------
// Push/Pop
// --------------------------------------------------------------------

class TR2push16r<string opcStr, string altOpcStr, bits<3> opcode, bits<3> mode> : TypeR2_1
                <opcode, mode,
                (outs), (ins GR16:$rd),
                AsmStr< opcStr, altOpcStr, "\t$rd">.n,
                []>
                {let mayStore = 1; let hasSideEffects = 0;}

class TR2pop16r<string opcStr, string altOpcStr, bits<3> opcode, bits<3> mode> : TypeR2_1
                <opcode, mode,
                (outs GR16:$rd), (ins),
                AsmStr< opcStr, altOpcStr, "\t$rd">.n,
                []>
                {let mayLoad = 1; let hasSideEffects = 0;}

let Defs = [SP], Uses = [SP] in
{
  def PUSH16r : TR2push16r< "push", "push", 0b010, 0b100>;
  def POP16r  : TR2pop16r<  "pop",  "pop",  0b011, 0b100>;
}


// --------------------------------------------------------------------
// no operation pseudo instruction
// --------------------------------------------------------------------

let hasSideEffects = 0 in
{
  def NOP : Pseudo<(outs), (ins), "nop", []>;
}




