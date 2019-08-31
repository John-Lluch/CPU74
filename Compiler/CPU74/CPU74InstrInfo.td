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

// SDTBinaryArithWithFlagsOut - Res1, Flags = op LHS, RHS
def SDT_BinaryArithWithFlagsOut : SDTypeProfile<2, 2,
      [SDTCisSameAs<0, 2>, SDTCisSameAs<0, 3>, SDTCisInt<0>, SDTCisVT<1, i16>]>;

// SDTBinaryArithWithFlagsInOut - Res1, Flags = op LHS, RHS, Flags
def SDT_BinaryArithWithFlagsInOut : SDTypeProfile<2, 3,
      [SDTCisSameAs<0, 2>, SDTCisSameAs<0, 3>, SDTCisInt<0>, SDTCisVT<1, i16>, SDTCisVT<4, i16>]>;

// SDTBinaryTestWithFlagsOut - SR = op LHS, RHS
def SDT_BinaryTestWithFlagsOut : SDTypeProfile<1, 2,
      [SDTCisVT<0, i16>, SDTCisInt<1>, SDTCisInt<2>]>;

// Calling stuff
def SDT_CPU74Call         : SDTypeProfile<0, -1, [SDTCisVT<0, iPTR>]>;             // 0 results, -1 operands?, type is exactly a iPTR
def SDT_CPU74CallSeqStart : SDCallSeqStart<[SDTCisVT<0, i16>, SDTCisVT<1, i16>]>;   // 0 results, 2 operands, operand 0 is i16, operand 1 is i16
def SDT_CPU74CallSeqEnd   : SDCallSeqEnd<[SDTCisVT<0, i16>, SDTCisVT<1, i16>]>;     // 0 results, 2 operands, operand 0 is i16, operand 1 is i16
def SDT_CPU74CallArgLoc   : SDTypeProfile<1, 0, [SDTCisPtrTy<0>]>;                   // 1 result, 0 operands, operands 0 is pointer type, operand 1 is i16

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

// Shifts
def CPU74lsl     : SDNode<"CPU74ISD::LSL", SDTIntUnaryOp, []>;  // one bit shifts
def CPU74lsr     : SDNode<"CPU74ISD::LSR", SDTIntUnaryOp, []>;  // one bit shifts
def CPU74asr     : SDNode<"CPU74ISD::ASR", SDTIntUnaryOp, []>;  // one bit shifts
def CPU74sextw   : SDNode<"CPU74ISD::SEXTW", SDTIntUnaryOp, []>;  // 15 bit asr

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

// Compare instruction
def CPU74cmp        : SDNode<"CPU74ISD::CMP",   SDT_BinaryTestWithFlagsOut>;

// Conditional instructions
def CPU74brcc     : SDNode<"CPU74ISD::BR_CC", SDT_CPU74BrCC, [SDNPHasChain]>;
def CPU74setcc    : SDNode<"CPU74ISD::SET_CC", SDT_CPU74SetCC>;
def CPU74selcc    : SDNode<"CPU74ISD::SEL_CC", SDT_CPU74SelCC>;

// Conditional flag setting instructions
def CPU74add:  SDNode<"CPU74ISD::ADD", SDT_BinaryArithWithFlagsOut, [SDNPCommutative, SDNPAssociative]>;
def CPU74sub:  SDNode<"CPU74ISD::SUB", SDT_BinaryArithWithFlagsOut>;
def CPU74and:  SDNode<"CPU74ISD::AND", SDT_BinaryArithWithFlagsOut, [SDNPCommutative, SDNPAssociative]>;
def CPU74or:   SDNode<"CPU74ISD::OR",  SDT_BinaryArithWithFlagsOut, [SDNPCommutative, SDNPAssociative]>;
def CPU74xor:  SDNode<"CPU74ISD::XOR", SDT_BinaryArithWithFlagsOut, [SDNPCommutative, SDNPAssociative]>;

// Carry flag setting and consuming instructions
def CPU74addo:  SDNode<"CPU74ISD::ADDO", SDT_BinaryArithWithFlagsOut, [SDNPCommutative]>;
def CPU74subo:  SDNode<"CPU74ISD::SUBO", SDT_BinaryArithWithFlagsOut>;
def CPU74addc:  SDNode<"CPU74ISD::ADDC", SDT_BinaryArithWithFlagsInOut, [SDNPCommutative]>;
def CPU74subc:  SDNode<"CPU74ISD::SUBC", SDT_BinaryArithWithFlagsInOut>;

// --------------------------------------------------------------------
// Constraint definitions for immediate values.
// --------------------------------------------------------------------

// Return the negation of an immediate value.
// Used to create the negated immediate constraint
def imm_neg_XFORM : SDNodeXForm<imm, [{return CurDAG->getTargetConstant(-(int)N->getZExtValue(), SDLoc(N), MVT::i16);}]>;

// Constraints for immediate operands
def imm8s : ImmLeaf<i16, [{return CPU74Imm::isImm8s(Imm);}]>;   // 8 bit signed immediate
def imm8u : ImmLeaf<i16, [{return CPU74Imm::isImm8u(Imm);}]>;   // 8 bit unsigned immediate
def imm6u : ImmLeaf<i16, [{return CPU74Imm::isImm6u(Imm);}]>;   // 6 bit unsigned immediate
def imm6_d  : ImmLeaf<i16, [{return CPU74Imm::isImm6_d(Imm);}]>;   // 6 bit displaced immediate
def immWord : ImmLeaf<i16, [{return isInt<16>(Imm);}]>;     // value that can't be expressed as a smaller immemdiate
def imm8u_neg : ImmLeaf<i16, [{return CPU74Imm::isImm8u(-Imm);}], imm_neg_XFORM>;  // 8 bit unsigned negated immediate

// --------------------------------------------------------------------
// Operand definitions.
// --------------------------------------------------------------------

// Memory addressing mode operand base class.
// ( clase base d'operadors en mode de direccionament de memòria )
class MemOperand : Operand<i16> {
  let OperandType = "OPERAND_MEMORY";
}

// Memory pointer with immediate address mode [Rx,K].
// Does not select Frame Indexes
def memGRImm : MemOperand, ComplexPattern< i16, 2, "SelectGRIndexed", [] >
{
  let PrintMethod = "printMemIndexed";
  let MIOperandInfo = (ops GR16:$rs, imm6_d:$k);
}

// Memory pointer with immediate address mode.
// Only selects Frame Index [fp,K]
def memFIImm : MemOperand, ComplexPattern< i16, 2, "SelectFIIndexed", [add, frameindex] >
{
  let PrintMethod = "printMemIndexed";
  let MIOperandInfo = (ops GR16:$rs, imm6_d:$k);
}

// Same as above but with print method suitable for LEA instruction
def leaFIImm : MemOperand, ComplexPattern< i16, 2, "SelectFIIndexed", [frameindex] >
{
  let PrintMethod = "printLeaWordIndexed";
  let MIOperandInfo = (ops GR16:$rs, imm6_d:$k);
}

// Memory pointer with immediate address mode [Rx,K].
// May select frame indexes as well
def memImm : MemOperand, ComplexPattern< i16, 2, "SelectIndexed", [add, frameindex] >
{
  let PrintMethod = "printMemIndexed";
  let MIOperandInfo = (ops GR16:$rs, imm6_d:$k);
}

// Memory pointer with large immediate address mode [Rx,K] or [Rx,&a].
// Does not select frame indexes
def memWordImm : MemOperand, ComplexPattern< i16, 2, "SelectWordIndexed", [] >
{
  let PrintMethod = "printMemWordIndexed";
  let MIOperandInfo = (ops GR16:$rs, i16:$k);
}

// Memory pointer with absolute address mode [&a].
def memAddr : MemOperand, ComplexPattern< i16, 1, "SelectAddress", [] >
{
  let PrintMethod = "printAddress";
  let MIOperandInfo = (ops i16:$k);
}

// Short jump targets have OtherVT type and are printed as pcrel imm values.
def jmptarget : Operand<OtherVT> {
  let PrintMethod = "printPCRelOperand";
}

// Call addresses that are printed as pcrel imm values.
def calltarget : Operand<OtherVT> {
  let PrintMethod = "printPCRelOperand";
}

// Call addresses that are printed as absolute values.
def callabstarget : Operand<OtherVT> {
  let PrintMethod = "printProgAbsOperand";
}

// Operand for printing a condition code.
def CC : Operand<i16> {
  let PrintMethod = "printCCOperand";
}

// Operand for printing large immediates.
def immLarge : Operand<i16> {
  let PrintMethod = "printLargeOperand";
}

// --------------------------------------------------------------------
// List of callee non-preserved registers
// --------------------------------------------------------------------

class RegList< list<Register> regs>
{
  list<Register> r;
  let r = regs;
}

def CallRegs : RegList<[R0, R1, R2, R3, SR, AR]>;

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

let Defs = [SP, SR, AR], Uses = [SP] in
{
  def CALLSQ_START : adjStack< "CALLSQ_START", "CALLSQ_START", CPU74callseq_start >;
  def CALLSQ_END : adjStack< "CALLSQ_END", "CALLSQ_END", CPU74callseq_end >;
}


class addFrame< string opcStr, string altOpcStr> : Pseudo
              < (outs GR16:$dst), (ins i16imm:$base, i16imm:$offset),
                AsmStr< opcStr, altOpcStr, "\tPSEUDO">.n,
                []>;

let Defs = [SR, AR], Uses = [SP] in
{
  def ADDFrame : addFrame< "#ADDframe", "#ADDFrame" >;
}

// --------------------------------------------------------------------
// Two register Move, Compare, ALU operation
// --------------------------------------------------------------------

class T10xr16mov<string opcStr, string altOpcStr, bits<3> opcode, bits<2> mode>: Type10
                <opcode, mode,
                (outs GR16:$rd), (ins GRX16:$rs),
                AsmStr< opcStr, altOpcStr, "\t$rs, $rd">.n,
                [(set GR16:$rd, GRX16:$rs)]>
                {let hasSideEffects = 0;}

class T10rx16mov<string opcStr, string altOpcStr, bits<3> opcode, bits<2> mode>: Type10
                <opcode, mode,
                (outs GRX16:$rd), (ins GR16:$rs),
                AsmStr< opcStr, altOpcStr, "\t$rs, $rd">.n,
                [(set GRX16:$rd, GR16:$rs)]>
                {let hasSideEffects = 0;}

class T10rr16mov<string opcStr, string altOpcStr, bits<3> opcode, bits<2> mode>: Type10
                <opcode, mode,
                (outs GR16:$rd), (ins GR16:$rs),
                AsmStr< opcStr, altOpcStr, "\t$rs, $rd">.n,
                []>
                {let hasSideEffects = 0;}

class T10rr16cmp<string opcStr, string altOpcStr, bits<3> opcode, bits<2> mode >: Type10
                <opcode, mode,
                (outs), (ins GR16:$rd, GR16:$rs),
                AsmStr< opcStr, altOpcStr, "\t$rd, $rs">.n,
                //[(set SR, (CPU74cmp GR16:$rd, GR16:$rs))]>
                []>
                {let isCompare = 1; let isReMaterializable = 1;}

class T10rr16alu_c<string opcStr, string altOpcStr, bits<3> opcode, bits<2> mode>: Type10
                <opcode, mode,
                (outs GR16:$rd), (ins GR16:$rs),
                AsmStr< opcStr, altOpcStr, "\t$rs, $rd">.n,
                []>;

// Move, compare
def MOVrr16 : T10rr16mov< "movrr", "mov", 0b000, 0b00 >;
def MOVxr16 : T10rr16mov< "movxr", "mov", 0b000, 0b00 >;
def MOVrx16 : T10rr16mov< "movrx", "mov", 0b000, 0b00 >;

let Defs = [SR] in
{
  def CMPrr16 : T10rr16cmp< "cmprr", "cmp", 0b001, 0b00 >;
}

def : Pat<(CPU74cmp GR16:$rd, GR16:$rs),  (CMPrr16 GR16:$rd, GR16:$rs)>;

// Extend
def ZEXTrr16  : T10rr16alu_c< "zext",  "zext",  0b010, 0b00 >;
def SEXTrr16  : T10rr16alu_c< "sext",  "sext",  0b011, 0b00 >;
def SWAPrr16  : T10rr16alu_c< "bswap", "bswap", 0b100, 0b00 >;
def SEXTWrr16 : T10rr16alu_c< "sextw", "sextw", 0b101, 0b00 >;

def : Pat<(and GR16:$rs, 255),            (ZEXTrr16 GR16:$rs)>;
def : Pat<(sext_inreg GR16:$rs, i8),      (SEXTrr16 GR16:$rs)>;
def : Pat<(bswap GR16:$rs),               (SWAPrr16 GR16:$rs)>;

def : Pat<(CPU74sextw GR16:$rs),          (SEXTWrr16 GR16:$rs)>;
def : Pat<(sra GR16:$rs, 15),             (SEXTWrr16 GR16:$rs)>;

// Shifts
def LSRrr16 : T10rr16alu_c<  "lsr", "lsr", 0b000, 0b01 >;
def LSLrr16  : T10rr16alu_c< "lsl", "lsl", 0b001, 0b01 >;
def ASRrr16  : T10rr16alu_c< "asr", "asr", 0b010, 0b01 >;

def : Pat<(CPU74lsr GR16:$rd0),    (LSRrr16 $rd0)>;
def : Pat<(CPU74lsl GR16:$rd0),    (LSLrr16 $rd0)>;
def : Pat<(CPU74asr GR16:$rd0),    (ASRrr16 $rd0)>;

// Neg, not
let Defs = [SR, AR] in
{
  def NEGrr16  : T10rr16alu_c< "neg", "neg", 0b101, 0b01 >;
}

let Defs = [SR] in
{
  def NOTrr16  : T10rr16alu_c< "not", "not", 0b110, 0b01 >;
}

def : Pat<(ineg GR16:$rd0),        (NEGrr16 $rd0)>;
def : Pat<(not GR16:$rd0),         (NOTrr16 $rd0)>;

// -------------------------------------------------------------------------
// Relative Call/Jump
// -------------------------------------------------------------------------

class T1jr<string opcStr, string altOpcStr, bits<1> opcode>: Type1
                <opcode,
                (outs), (ins jmptarget:$a),
                AsmStr< opcStr, altOpcStr, "\t$a">.n,
                //[(br bb:$a)]>
                []>
                {let isBranch = 1; let isTerminator = 1; let isBarrier = 1;}

class T1cr<string opcStr, string altOpcStr, bits<1> opcode>: Type1
                <opcode,
                (outs), (ins calltarget:$a),
                AsmStr< opcStr, altOpcStr, "\t$a">.n,
                []>
                {let isCall = 1;}

def JMP  : T1jr< "jmprel", "jmp", 0b0 >;

let Defs = CallRegs.r, Uses = [SP] in
{
  def CALL : T1cr< "callrel", "jsr", 0b1 >;
}

// relative unconditinal jump
def : Pat<(br bb:$a), (JMP bb:$a)>;

// relative call
def : Pat<(CPU74call tglobaladdr:$a),  (CALL tglobaladdr:$a)>;
def : Pat<(CPU74call texternalsym:$a), (CALL texternalsym:$a)>;

// --------------------------------------------------------------------
// Conditional branch
// --------------------------------------------------------------------

class T2ccbr<string opcStr, string altOpcStr>: Type2
                <
                (outs), (ins jmptarget:$a, CC:$cc),
                AsmStr< opcStr, altOpcStr, "$cc\t$a">.n,
                []>
                {let isBranch = 1; let isTerminator = 1;}


let Uses = [SR] in
{
  def BRCC  : T2ccbr< "br", "br"> ;
}

def : Pat<(CPU74brcc bb:$a, imm:$cc, SR), (BRCC bb:$a, imm:$cc)>;

// ---------------------------------------------------------------------
// Move, Compare, Add, Subtract immediate
// ---------------------------------------------------------------------

class T3kr16mov<string opcStr, string altOpcStr, bits<3> opcode>: Type3
                <opcode,
                (outs GR16:$rd), (ins i16imm:$k),
                AsmStr< opcStr, altOpcStr, "\t$k, $rd">.n,
                [(set GR16:$rd, imm8s:$k)]>
                {let isAsCheapAsAMove = 1; let isReMaterializable = 1; let isMoveImm = 1;}

class T3kr16cmp<string opcStr, string altOpcStr, bits<3> opcode >: Type3
                <opcode,
                (outs), (ins GR16:$rd, i16imm:$k),
                AsmStr< opcStr, altOpcStr, "\t$rd, $k">.n,
                //[(set SR, (CPU74cmp GR16:$rd, imm8s:$k))]>
                []>
                {let isCompare = 1; let isReMaterializable = 1;}
                

class T3kr16alu_c<string opcStr, string altOpcStr, bits<3> opcode>: Type3
                <opcode,
                (outs GR16:$rd), (ins GR16:$rd0, i16imm:$k),
                AsmStr< opcStr, altOpcStr, "\t$rd0, $k, $rd">.n,
                []>
                {let Constraints = "$rd0 = $rd";
                 let isAsCheapAsAMove = 1; let isReMaterializable = 1;}

def MOVkr16 : T3kr16mov< "movkr", "mov", 0b000 >;

let Defs = [SR] in
{
  def CMPkr16 : T3kr16cmp< "cmpkr", "cmp", 0b001>;
}

let Defs = [SR, AR] in
{
  def ADDkr16 : T3kr16alu_c< "addkr", "add", 0b010>;
  def SUBkr16 : T3kr16alu_c< "subkr", "sub", 0b011>;   // gets selected as a negated add
}

let Defs = [AR, SR] in
{
  def ADDkr16_ar : T3kr16alu_c< "addkr", "add", 0b010>;
  def SUBkr16_ar : T3kr16alu_c< "subkr", "sub", 0b011>;   // gets selected as a negated add
}

let Defs = [SR] in
{
  def ANDkr16 : T3kr16alu_c< "andkr", "and", 0b100>;
  def ORkr16  : T3kr16alu_c< "orkr",  "or",  0b101>;
  def XORkr16 : T3kr16alu_c< "xorkr", "xor", 0b110>;
}

// move, compare
def : Pat<(CPU74cmp GR16:$rd, imm8s:$k),      (CMPkr16 GR16:$rd, imm8s:$k)>;

// add, sub
def : Pat<(add GR16:$rd0, imm8u:$k),      (ADDkr16 GR16:$rd0, imm8u:$k)>;
def : Pat<(add GR16:$rd0, imm8u_neg:$k),  (SUBkr16 GR16:$rd0, imm8u_neg:$k)>;

// add, sub tests
def : Pat<(CPU74add GR16:$rd0, imm8u:$k),      (ADDkr16 GR16:$rd0, imm8u:$k)>;
def : Pat<(CPU74add GR16:$rd0, imm8u_neg:$k),  (SUBkr16 GR16:$rd0, imm8u_neg:$k)>;

// add, sub pairs
def : Pat<(CPU74addo GR16:$rn, imm8u:$k),      (ADDkr16_ar GR16:$rn, imm8u:$k)>;
def : Pat<(CPU74addo GR16:$rn, imm8u_neg:$k),  (SUBkr16_ar GR16:$rn, imm8u_neg:$k)>;

// and, or, xor
def : Pat<(and GR16:$rn, imm8u:$k),    (ANDkr16 GR16:$rn, imm8u:$k)>;
def : Pat<(or GR16:$rn, imm8u:$k),     (ORkr16 GR16:$rn, imm8u:$k)>;
def : Pat<(xor GR16:$rn, imm8u:$k),     (XORkr16 GR16:$rn, imm8u:$k)>;

// and, or tests
def : Pat<(CPU74and GR16:$rn, imm8u:$k),    (ANDkr16 GR16:$rn, imm8u:$k)>;
def : Pat<(CPU74or GR16:$rn, imm8u:$k),     (ORkr16 GR16:$rn, imm8u:$k)>;

// ---------------------------------------------------------------------
// Load/store with immediate offset
// ---------------------------------------------------------------------

class T4mrmov_c<string opcStr, string altOpcStr, bits<2> opcode>: Type4
                <opcode,
                (outs GR16:$rd), (ins memImm:$src),
                AsmStr< opcStr, altOpcStr, "\t$src, $rd">.n,
                []>
                {let canFoldAsLoad = 1; let isReMaterializable = 1;}


class T4rmmov_c<string opcStr, string altOpcStr, bits<2> opcode>: Type4
                <opcode,
                (outs), (ins GR16:$rd, memImm:$dst),
                AsmStr< opcStr, altOpcStr, "\t$rd, $dst">.n,
                []>;

def MOVmr16 : T4mrmov_c< "movmr.w", "ld.w", 0b00 >;
def MOVmr8s : T4mrmov_c< "movmr.sb", "ld.sb", 0b01 >;

// this instruction does not physically exist, see below
def MOVmr8z : T4mrmov_c< "movmr.zb", "ld.zb", 0>;

def MOVrm16 : T4rmmov_c< "movrm.w", "st.w", 0b10 >;
def MOVrm8  : T4rmmov_c< "movrm.b", "st.b", 0b11 >;

// loads
def : Pat<(load memImm:$src),        (MOVmr16 memImm:$src)>;
def : Pat<(sextloadi8 memImm:$src),  (MOVmr8s memImm:$src)>;

// AnyExt loads are converted to sextloads
def : Pat<(extloadi8 memImm:$src),   (MOVmr8s memImm:$src)>;

// ZeroExt load instruction does not physically exist, we are selecting it
// in two possible ways
// (1) Based on ZEXTrr16, MOVmr8s
// (2) In relation with frame index stuff. In such case the instruction may
// get replaced during 'eliminateFrameIndex' by MOVmr8s, ZEXTrr16 or by MOVMr8z.
def : Pat<(zextloadi8 memGRImm:$src),  (ZEXTrr16 (MOVmr8s memGRImm:$src))>;
def : Pat<(zextloadi8 memFIImm:$src),  (MOVmr8z memFIImm:$src)>;

// stores
def : Pat<(store GR16:$rd, memImm:$dst),  (MOVrm16 GR16:$rd, memImm:$dst)>;
def : Pat<(truncstorei8 GR16:$rd, memImm:$dst),  (MOVrm8  GR16:$rd, memImm:$dst)>;

// --------------------------------------------------------------------
// Three register ALU operation
// --------------------------------------------------------------------

class T5rrr16alu_c<string opcStr, string altOpcStr, bits<4> opcode>: Type5
                <opcode,
                (outs GR16:$rd), (ins GR16:$rn, GR16:$rs),
                AsmStr< opcStr, altOpcStr, "\t$rn, $rs, $rd">.n,
                []>
                {let isAsCheapAsAMove = 1; let isReMaterializable = 1;}

let Defs = [SR, AR] in
{
  def ADDrrr16 : T5rrr16alu_c< "addrrr", "add", 0b0000 >;
  def SUBrrr16 : T5rrr16alu_c< "subrrr", "sub", 0b0010 >;
}

let Defs = [AR, SR] in
{
  def ADDrrr16_ar : T5rrr16alu_c< "addrrr", "add", 0b0000 >;
  def SUBrrr16_ar : T5rrr16alu_c< "subrrr", "sub", 0b0010 >;
  let Uses = [AR] in { def ADDCrrr16 : T5rrr16alu_c< "addcrrr", "addc", 0b0001 >; }
  let Uses = [AR] in { def SUBCrrr16 : T5rrr16alu_c< "subcrrr", "subc", 0b0011 >; }
}

let Defs = [SR] in
{
  def ORrrr16  : T5rrr16alu_c< "orrrr", "or", 0b0100 >;
  def ANDrrr16 : T5rrr16alu_c< "andrrr", "and", 0b0101 >;
  def XORrrr16: T5rrr16alu_c< "xorrrr", "xor", 0b0110 >;
}

// add sub
def : Pat<(add GR16:$rn, GR16:$rs),    (ADDrrr16 GR16:$rn, GR16:$rs)>;
def : Pat<(sub GR16:$rn, GR16:$rs),    (SUBrrr16 GR16:$rn, GR16:$rs)>;

// add, sub tests
def : Pat<(CPU74add GR16:$rn, GR16:$rs),    (ADDrrr16 GR16:$rn, GR16:$rs)>;
def : Pat<(CPU74sub GR16:$rn, GR16:$rs),    (SUBrrr16 GR16:$rn, GR16:$rs)>;

// logical
def : Pat<(or GR16:$rn,  GR16:$rs),     (ORrrr16 GR16:$rn, GR16:$rs)>;
def : Pat<(and GR16:$rn, GR16:$rs),    (ANDrrr16 GR16:$rn, GR16:$rs)>;
def : Pat<(xor GR16:$rn, GR16:$rs),    (XORrrr16 GR16:$rn, GR16:$rs)>;

// logical tests
def : Pat<(CPU74or  GR16:$rn, GR16:$rs),     (ORrrr16 GR16:$rn, GR16:$rs)>;
def : Pat<(CPU74and GR16:$rn, GR16:$rs),    (ANDrrr16 GR16:$rn, GR16:$rs)>;
def : Pat<(CPU74xor GR16:$rn, GR16:$rs),    (XORrrr16 GR16:$rn, GR16:$rs)>;

// pairs
def : Pat<(CPU74addo GR16:$rn, GR16:$rs),      (ADDrrr16_ar GR16:$rn, GR16:$rs)>;
def : Pat<(CPU74subo GR16:$rn, GR16:$rs),      (SUBrrr16_ar GR16:$rn, GR16:$rs)>;
def : Pat<(CPU74addc GR16:$rn, GR16:$rs, AR),  (ADDCrrr16 GR16:$rn, GR16:$rs)>;
def : Pat<(CPU74subc GR16:$rn, GR16:$rs, AR),  (SUBCrrr16 GR16:$rn, GR16:$rs)>;

// --------------------------------------------------------------------
// Load/store with register offset
// --------------------------------------------------------------------

class T5nrmov_c<string opcStr, string altOpcStr, bits<4> opcode>: Type5
                <opcode,
                (outs GR16:$rd), (ins GR16:$rn, GR16:$rs),
                AsmStr< opcStr, altOpcStr, "\t[$rn, $rs], $rd">.n,
                []>
                {let isReMaterializable = 1;}

class T5rnmov_c<string opcStr, string altOpcStr, bits<4> opcode>: Type5
                <opcode,
                (outs), (ins GR16:$rd, GR16:$rn, GR16:$rs),
                AsmStr< opcStr, altOpcStr, "\t$rd, [$rn, $rs]">.n,
                []>;

def MOVnr16 : T5nrmov_c< "movnr.w",  "ld.w", 0b1000 >;
def MOVnr8z : T5nrmov_c< "movnr.zb", "ld.zb", 0b1010 >;
def MOVnr8s : T5nrmov_c< "movnr.sb", "ld.sb", 0b1011 >;

def MOVrn16 : T5rnmov_c< "movrn.w", "st.w", 0b1100 >;
def MOVrn8  : T5rnmov_c< "movrn.b", "st.b", 0b1110 >;

// loads
def : Pat<(load (add GR16:$rn, GR16:$rs)),        (MOVnr16 GR16:$rn, GR16:$rs)>;
def : Pat<(zextloadi8 (add GR16:$rn, GR16:$rs)),  (MOVnr8z GR16:$rn, GR16:$rs)>;
def : Pat<(sextloadi8 (add GR16:$rn, GR16:$rs)),  (MOVnr8s GR16:$rn, GR16:$rs)>;

// AnyExt loads are translated into sext loads
def : Pat<(extloadi8 (add GR16:$rn, GR16:$rs)),  (MOVnr8s GR16:$rn, GR16:$rs)>;

// stores
def : Pat<(store GR16:$rd, (add GR16:$rn, GR16:$rs)),       (MOVrn16 GR16:$rd, GR16:$rn, GR16:$rs)>;
def : Pat<(truncstorei8 GR16:$rd, (add GR16:$rn, GR16:$rs)), (MOVrn8 GR16:$rd, GR16:$rn, GR16:$rs)>;

// --------------------------------------------------------------------
// Conditional select
// --------------------------------------------------------------------

class T6ccrrrsel<string opcStr, string altOpcStr>: Type6
                <
                (outs GR16:$rd), (ins GR16:$rn, GR16:$rs, CC:$cc),
                AsmStr< opcStr, altOpcStr, "$cc\t$rn, $rs, $rd">.n,
                []>
                {let isAsCheapAsAMove = 1; let isReMaterializable = 1;}

let Uses = [SR] in
{
  def SELCC : T6ccrrrsel< "sel", "sel">;
}

def : Pat<(CPU74selcc GR16:$rn, GR16:$rs, imm:$cc, SR),  (SELCC GR16:$rn, GR16:$rs, imm:$cc)>;

// --------------------------------------------------------------------
// Conditional set
// --------------------------------------------------------------------

class T7ccrset<string opcStr, string altOpcStr>: Type7
                <
                (outs GR16:$rd), (ins CC:$cc),
                AsmStr< opcStr, altOpcStr, "$cc\t$rd">.n,
                []>
                {let isAsCheapAsAMove = 1; let isReMaterializable = 1;}

let Uses = [SR] in
{
  def SETCC : T7ccrset< "set", "set">;
}

def : Pat<(CPU74setcc imm:$cc, SR), (SETCC imm:$cc)>;

// --------------------------------------------------------------------
// Zero operand instructions
// --------------------------------------------------------------------

class T8basic<string opcStr, string altOpcStr, bits<3> opcode>: Type8
                <opcode,
                (outs), (ins),
                AsmStr< opcStr, altOpcStr, "">.n,
                []>;

class T8call<string opcStr, string altOpcStr, bits<3> opcode>: Type8a
                <opcode,
                (outs), (ins callabstarget:$a),
                AsmStr< opcStr, altOpcStr, "\t$a">.n,
                []>;

let isReturn = 1, isTerminator = 1, isBarrier = 1 in
{
  def RET  : T8basic< "ret",  "ret",  0b000>;
  def RETI : T8basic< "reti", "reti", 0b001>;
}

def : Pat<(CPU74retflag), (RET)>;
def : Pat<(CPU74retiflag), (RETI)>;

let Defs = CallRegs.r, Uses = [SP], isCall = 1 in
{
  def CALLABS : T8call< "callabs", "call", 0b111 >;
}

def : Pat<(CPU74call tglobaladdr:$a),  (CALLABS tglobaladdr:$a)>;
def : Pat<(CPU74call texternalsym:$a), (CALLABS texternalsym:$a)>;

// --------------------------------------------------------------------
// Branch/Call indirect
// --------------------------------------------------------------------

class T9JumpReg<string opcStr, string altOpcStr, bits<3> opcode, bits<1> mode>: Type9
                <opcode, mode,
                (outs), (ins GR16:$rd),
                AsmStr< opcStr, altOpcStr, "\t$rd">.n,
                []>
                {let isBranch = 1; let isTerminator = 1; let isBarrier = 1; let isIndirectBranch = 1;}

class T9CallReg<string opcStr, string altOpcStr, bits<3> opcode, bits<1> mode>: Type9
                <opcode, mode,
                (outs), (ins GR16:$rd),
                AsmStr< opcStr, altOpcStr, "\t$rd">.n,
                []>
                {let isCall = 1;}

def JMPreg  :  T9JumpReg< "jumpreg", "jmp", 0b000, 0b0 >;

let Defs = CallRegs.r, Uses = [SP] in
{
  def CALLreg : T9CallReg< "callreg", "call", 0b001, 0b0 >;
}

def : Pat<(brind GR16:$rd),      (JMPreg GR16:$rd)>;
def : Pat<(CPU74call GR16:$rd),  (CALLreg GR16:$rd)>;

// --------------------------------------------------------------------
// Push/Pop
// --------------------------------------------------------------------

class T9push16r<string opcStr, string altOpcStr, bits<3> opcode, bits<1> mode> : Type9
                <opcode, mode,
                (outs), (ins GR16:$rd),
                AsmStr< opcStr, altOpcStr, "\t$rd">.n,
                []>
                {let mayStore = 1; let hasSideEffects = 0;}

class T9pop16r<string opcStr, string altOpcStr, bits<3> opcode, bits<1> mode> : Type9
                <opcode, mode,
                (outs GR16:$rd), (ins),
                AsmStr< opcStr, altOpcStr, "\t$rd">.n,
                []>
                {let mayLoad = 1; let hasSideEffects = 0;}

let Defs = [SP], Uses = [SP] in
{
  def PUSH16r : T9push16r< "push", "push", 0b010, 0b0>;
  def POP16r  : T9pop16r<  "pop",  "pop",  0b011, 0b0>;
}

// --------------------------------------------------------------------
// Move Immediate, Load/store with absolute address
// [note: for correct instruction selection this must be after all imm6 and imm8 operand instances]
// --------------------------------------------------------------------

class T9arlea_k<string opcStr, string altOpcStr, bits<3> opcode, bits<1> mode>: Type9a
                <opcode, mode,
                (outs GR16:$rd), (ins immLarge:$K),
                AsmStr< opcStr, altOpcStr, "\t$K, $rd">.n,
                [(set GR16:$rd, immWord:$K)]>
                {let isMoveImm = 1; let isReMaterializable = 1;}

class T9arlea<string opcStr, string altOpcStr, bits<3> opcode, bits<1> mode>: Type9a
                <opcode, mode,
                (outs GR16:$rd), (ins immLarge:$a),
                AsmStr< opcStr, altOpcStr, "\t$a, $rd">.n,
                [(set GR16:$rd, immWord:$a)]>
                {let isMoveImm = 1; let isReMaterializable = 1;}

class T9armov_c<string opcStr, string altOpcStr, bits<3> opcode, bits<1> mode>: Type9a
                <opcode, mode,
                (outs GR16:$rd), (ins memAddr:$a),
                AsmStr< opcStr, altOpcStr, "\t$a, $rd">.n,
                []>
                {let canFoldAsLoad = 1; let isReMaterializable = 1;}

class T9ramov_c<string opcStr, string altOpcStr, bits<3> opcode, bits<1> mode>: Type9a
                <opcode, mode,
                (outs), (ins GR16:$rd, memAddr:$a),       // $a must be the second argument to correctly generate the bitcode
                AsmStr< opcStr, altOpcStr, "\t$rd, $a">.n,
                []>;

def LEAKr16 : T9arlea_k< "movKr", "mov", 0b000, 0b1 >;
def LEAar16 : T9arlea<   "leaar", "mov", 0b000, 0b1 >;

def MOVar16 : T9armov_c< "movar.w",  "ld.w",  0b001, 0b1 >;
def MOVsar8 : T9armov_c< "movar.sb", "ld.sb", 0b010, 0b1 >;
def MOVzar8 : T9armov_c< "movar.zb", "ld.zb", 0b011, 0b1 >;
def MOVra16 : T9ramov_c< "movra.w",  "st.w",  0b100, 0b1 >;
def MOVra8  : T9ramov_c< "movra.b",  "st.b",  0b101, 0b1 >;

// loads
def : Pat<(load memAddr:$a),         (MOVar16 memAddr:$a)>;
//def : Pat<(load (CPU74AggregateWrapper tglobaladdr:$a)),         (MOVar16 i16imm:$a)>;

def : Pat<(sextloadi8 memAddr:$a),   (MOVsar8 memAddr:$a)>;
//def : Pat<(sextloadi8 (CPU74AggregateWrapper tglobaladdr:$a)),   (MOVsar8 i16imm:$a)>;

def : Pat<(zextloadi8 memAddr:$a),   (MOVzar8 memAddr:$a)>;
//def : Pat<(zextloadi8 (CPU74AggregateWrapper tglobaladdr:$a)),   (MOVzar8 i16imm:$a)>;

// AnyExt loads are converted to sextloads
def : Pat<(extloadi8 memAddr:$a),   (MOVsar8 memAddr:$a)>;
//def : Pat<(extloadi8 (CPU74AggregateWrapper tglobaladdr:$a)),   (MOVsar8 i16imm:$a)>;

// stores
def : Pat<(store GR16:$rd, memAddr:$a), (MOVra16 GR16:$rd, memAddr:$a)>;
def : Pat<(truncstorei8 GR16:$rd, memAddr:$a), (MOVra8 GR16:$rd, memAddr:$a)>;

// Patterns for moving global adresses directly into registers
def : Pat<(CPU74AggregateWrapper tglobaladdr:$a), (LEAar16 tglobaladdr:$a)>;
def : Pat<(CPU74AggregateWrapper texternalsym:$a), (LEAar16 texternalsym:$a)>;
def : Pat<(CPU74AggregateWrapper tblockaddress:$a), (LEAar16 tblockaddress:$a)>;
def : Pat<(CPU74AggregateWrapper tjumptable:$a), (LEAar16 tjumptable:$a)>;
//
//def : Pat<(CPU74SingleValWrapper tglobaladdr:$a), (LEAar16 tglobaladdr:$a)>;
//def : Pat<(CPU74SingleValWrapper texternalsym:$a), (LEAar16 texternalsym:$a)>;
//def : Pat<(CPU74SingleValWrapper tblockaddress:$a), (LEAar16 tblockaddress:$a)>;
//def : Pat<(CPU74SingleValWrapper tjumptable:$a), (LEAar16 tjumptable:$a)>;


/* Legacy
 ---------------------------------------------------------------------
 Load/store with large immediate offset
 ---------------------------------------------------------------------

class T10Mrlea_k<string opcStr, string altOpcStr, bits<3> opcode, bits<2> mode >: Type10a
                <opcode, mode,
                (outs GR16:$rd), (ins GR16:$rs, immLarge:$K),
                AsmStr< opcStr, altOpcStr, "\t$rs, $K, $rd">.n,
                [(set GR16:$rd, (add GR16:$rs, immWord:$K))]>;

class T10Mrlea<string opcStr, string altOpcStr, bits<3> opcode, bits<2> mode >: Type10a
                <opcode, mode,
                (outs GR16:$rd), (ins leaFIImm:$src),
                AsmStr< opcStr, altOpcStr, "\t$src, $rd">.n,
                [(set GR16:$rd, leaFIImm:$src)]>;

class T10Mrmov_c<string opcStr, string altOpcStr, bits<3> opcode, bits<2> mode >: Type10a
                <opcode, mode,
                (outs GR16:$rd), (ins memWordImm:$src),
                AsmStr< opcStr, altOpcStr, "\t$src, $rd">.n,
                []>
                ;//{let canFoldAsLoad = 1; let isReMaterializable = 1;}


class T10rMmov_c<string opcStr, string altOpcStr, bits<3> opcode, bits<2> mode>: Type10a
                <opcode, mode,
                (outs), (ins GR16:$rd, memWordImm:$dst),
                AsmStr< opcStr, altOpcStr, "\t$rd, $dst">.n,
                []>;

def LEArKr16 : T10Mrlea_k< "learKr", "add",    0b000, 0b10 >;
def LEAMr16  : T10Mrlea<   "leaMr",  "add",    0b000, 0b10 >;

def MOVMr16  : T10Mrmov_c< "movMr.w",  "ld.w",   0b001, 0b10 >;
def MOVMr8s  : T10Mrmov_c< "movMr.sb", "ld.sb",  0b010, 0b10 >;
def MOVMr8z  : T10Mrmov_c< "movMr.zb", "ld.zb",  0b011, 0b10 >;
def MOVrM16  : T10rMmov_c< "movrM.w",  "st.w",   0b100, 0b10 >;
def MOVrM8   : T10rMmov_c< "movrM.b",  "st.b",   0b101, 0b10 >;

// lea
//def : Pat<(add GR16:$rs, immWord:$K),            (LEArKr16 GR16:$rs, immWord:$K)>;
//def : Pat<(set leaFIImm:$src),                   (LEAMr16 leaFIImm:$src)>;
//def : Pat<(add tframeindex:$idx, imm:$k),        (LEArKr16 tframeindex:$idx, imm:$k)>;

// loads
def : Pat<(load memWordImm:$src),        (MOVMr16 memWordImm:$src)>;
def : Pat<(sextloadi8 memWordImm:$src),  (MOVMr8s memWordImm:$src)>;
def : Pat<(zextloadi8 memWordImm:$src),  (MOVMr8z memWordImm:$src)>;

// AnyExt loads are converted to sextloads
def : Pat<(extloadi8 memWordImm:$src),   (MOVMr8s memWordImm:$src)>;

// stores
def : Pat<(store GR16:$rd, memWordImm:$dst),  (MOVrM16 GR16:$rd, memWordImm:$dst)>;
def : Pat<(truncstorei8 GR16:$rd, memWordImm:$dst),  (MOVrM8  GR16:$rd, memWordImm:$dst)>;
*/

// --------------------------------------------------------------------
// no operation pseudo instruction
// --------------------------------------------------------------------

let hasSideEffects = 0 in
{
  def NOP : Pseudo<(outs), (ins), "nop", []>;
}




