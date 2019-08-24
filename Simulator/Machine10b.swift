//
//  Machine.swift
//  c74-sim
//
//  Created by Joan on 17/08/19.
//  Copyright © 2019 Joan. All rights reserved.
//
/*
import Foundation

// Describes a machine with all its components
class Machine
{
  // Registers, Program memory, Data memory, ALU
  let reg = Registers()
  let prg = ProgramMemory()
  let mem = DataMemory()
  let alu = ALU()
  
  // Decoder registers
  var ir:UInt16 = 0    // Instruction register
  var mir:UInt16 = 0   // Microinstruction register
  
  // Buses, Intermediate values
  var rd:UInt16 = 0
  var rs:UInt16 = 0
  var rn:UInt16 = 0
  var imm:UInt16 = 0
  var imml:UInt16 = 0
  var cc:UInt16 = 0
  var exe = nop
  var j = false
  var k:UInt16 = 0
  
  // Instruction Definitions
  
  // Type 1
  func jmp_k()     { prg.pc = alu.adda( prg.pc, imm ) ; k=0b000_00_11 ; j=true}
  func call_k()    { reg.sp = alu.deca2( reg.sp ) ; mem[reg.sp] = prg.pc ; prg.pc = alu.adda( prg.pc, imm ); k=0b000_00_11 ; j=true }
  
  // Type 2
  func br_ck()     { if alu.hasCC(cc) { prg.pc = alu.adda( prg.pc, imm) ; k=0b000_00_11 ; j=true} }
  
  // Type 3
  func mov_kr()    { reg[rd] = imm }
  func cmp_rk()    { alu.cmp( reg[rd], imm ) }
  func add_kr()    { reg[rd] = alu.add( reg[rd], imm ) }
  func sub_kr()    { reg[rd] = alu.sub( reg[rd], imm ) }
  func and_kr()    { reg[rd] = alu.and( reg[rd], imm ) }
  func or_kr()     { reg[rd] = alu.or ( reg[rd], imm ) }
  func xor_kr()    { reg[rd] = alu.xor( reg[rd], imm ) }
  
  // Type 4
  func movw_mr()   { reg[rd] = mem[ alu.add( imm, reg[rs] ) ] }
  func movsb_mr()  { reg[rd] = mem.sb( alu.add( imm, reg[rs] ) ) }
  func movw_rm()   { mem[ alu.add( imm, reg[rs] ) ] = reg[rd] }
  func movb_rm()   { mem.b( alu.add( imm, reg[rs] ), reg[rd] ) }
  
  // Type 5
  func add_rrr()   { reg[rd] = alu.add ( reg[rn], reg[rs] ) }
  func addc_rrr()  { reg[rd] = alu.addc( reg[rn], reg[rs] ) }
  func sub_rrr()   { reg[rd] = alu.sub ( reg[rn], reg[rs] ) }
  func subc_rrr()  { reg[rd] = alu.subc( reg[rn], reg[rs] ) }
  func or_rrr()    { reg[rd] = alu.or  ( reg[rn], reg[rs] ) }
  func and_rrr()   { reg[rd] = alu.and ( reg[rn], reg[rs] ) }
  func xor_rrr()   { reg[rd] = alu.xor ( reg[rn], reg[rs] ) }
  func movw_nr()   { reg[rd] = mem[ alu.add( reg[rn], reg[rs] ) ] }
  func movzb_nr()  { reg[rd] = mem.zb( alu.add( reg[rn], reg[rs] ) ) }
  func movsb_nr()  { reg[rd] = mem.sb( alu.add( reg[rn], reg[rs] ) ) }
  func movw_rn()   { mem[ alu.add( reg[rn], reg[rs] ) ] = reg[rd] }
  func movb_rn()   { mem.b( alu.add( reg[rn], reg[rs] ), reg[rd] ) }
  
  // Type 6
  func sel_crrr()  { reg[rd] = alu.hasCC(cc) ? reg[rn] : reg[rs] }
  
  // Type 7
  func set_cr()    { reg[rd] = alu.hasCC(cc) ? 1 : 0 }
  
  // Type 8
  func ret()      { prg.pc = mem[reg.sp] ; reg.sp = alu.inca2( reg.sp ) ; k=0b000_00_11 ; j=true }
  func reti()     { }
  func dint()     { }
  func eint()     { }
  func call_a()   { reg.sp = alu.deca2( reg.sp ) ; mem[reg.sp] = prg.pc ; prg.pc = imml ; k=0b000_00_11 ; j=true }
  
  // Type 9
  func jmp_r()    { prg.pc = reg[rd] ; j=true}
  func call_r()   { reg.sp = alu.deca2( reg.sp ) ; mem[reg.sp] = prg.pc; prg.pc = reg[rd] ; k=0b000_00_11 ; j=true }
  func push_r()   { reg.sp = alu.deca2( reg.sp ) ; mem[reg.sp] = reg[rd] }
  func pop_r()    { reg[rd] = mem[reg.sp] ; reg.sp = alu.inca2( reg.sp ) }
  func mov_sr()   { }
  func mov_rs()   { }
  func mov_lr()   { reg[rd] = imml ; k=0b000_00_11 }
  func movw_ar()  { reg[rd] = mem[imml] }
  func movzb_ar() { reg[rd] = mem.zb(imml) }
  func movsb_ar() { reg[rd] = mem.sb(imml) }
  func movw_ra()  { mem[imml] = reg[rd] }
  func movb_ra()  { mem.b(imml, reg[rd]) }
  
  // Type 10
  func mov_rr()   { reg[rd] = reg[rs] }
  func cmp_rr()   { alu.cmp( reg[rd], reg[rs] ) } // <- FIX ME: In order to keep rs on the Right, operands must be swapped by the compiler
  func zext_rr()  { reg[rd] = alu.zext( reg[rs] ) }
  func sext_rr()  { reg[rd] = alu.sext( reg[rs] ) }
  func bswap_rr() { reg[rd] = alu.bswap( reg[rs] ) }
  func sextw_rr() { reg[rd] = alu.sextw( reg[rs] ) }
  func movw_pr()  { reg.sp = alu.deca2( reg.sp ); mem[reg.sp] = prg.pc ; prg.pc = reg[rs] ; reg[rd] = prg.value ; prg.pc = mem[reg.sp] ; reg.sp = alu.inca2( reg.sp ) }
  func lsr_rr()   { reg[rd] = alu.lsr( reg[rs] ) }
  func lsl_rr()   { reg[rd] = alu.lsl( reg[rs] ) }
  func asr_rr()   { reg[rd] = alu.asr( reg[rs] ) }
  func neg_rr()   { reg[rd] = alu.neg( reg[rs] ) }
  func not_rr()   { reg[rd] = alu.not( reg[rs] ) }
  func add_rlr()  { reg[rd] = alu.adda( imml, reg[rs] ) }
  func movw_qr()  { reg[rd] = mem[ alu.add( imml, reg[rs] ) ] }
  func movzb_qr() { reg[rd] = mem.zb( alu.add( imml, reg[rs] ) ) }
  func movsb_qr() { reg[rd] = mem.sb( alu.add( imml, reg[rs] ) ) }
  func movw_rq()  { mem[ alu.add( imm, reg[rs] ) ] = reg[rd] }
  func movb_rq()  { mem.b( alu.add( imm, reg[rs] ), reg[rd] )}
  func nop()      { }
  
  // Micro
  func micro0()   { }
  func micro1()   { }
  func micro2()   { }
  func micro3()   { }
  func micro4()   { }
  func micro5()   { }
  func micro6()   { }
  func micro7()   { }

  // Instruction Encodings
  
  // Pattern P1
  let instrP1:Dictionary<UInt16, (Machine)->()->() > =
  [
    // Type 1
    0b111_0_000000 : jmp_k,
    0b111_1_000000 : call_k,
    
    // Type 4
    0b01_00_000000 : movw_mr,
    0b01_01_000000 : movsb_mr,
    0b01_10_000000 : movw_rm,
    0b01_11_000000 : movb_rm,
  ]

  // Pattern P2
  let instrP2:Dictionary<UInt16, (Machine)->()->() > =
  [
    // Type 2
    0b110_0000000 :  br_ck,
  ]
  
  // Pattern P3
  let instrP3:Dictionary<UInt16, (Machine)->()->() > =
  [
    // Type 3
    0b10_000_00000 : mov_kr,
    0b10_001_00000 : cmp_rk,
    0b10_010_00000 : add_kr,
    0b10_011_00000 : sub_kr,
    0b10_100_00000 : and_kr,
    0b10_101_00000 : or_kr,
    0b10_110_00000 : xor_kr,
    0b10_111_00000 : nop,
  ]
  
  // Pattern P4
  let instrP4:Dictionary<UInt16, (Machine)->()->() > =
  [
    // Type 5
    0b001_0000_000 : add_rrr,
    0b001_0001_000 : addc_rrr,
    0b001_0010_000 : sub_rrr,
    0b001_0011_000 : subc_rrr,
    0b001_0100_000 : or_rrr,
    0b001_0101_000 : and_rrr,
    0b001_0110_000 : xor_rrr,
    0b001_0111_000 : nop,

    0b001_1000_000 : nop,
    0b001_1001_000 : movw_nr,
    0b001_1010_000 : movzb_nr,
    0b001_1011_000 : movsb_nr,
    0b001_1100_000 : movw_rn,
    0b001_1101_000 : movb_rn,
    0b001_1110_000 : nop,
    0b001_1111_000 : nop,
  ]
  
  // Pattern P5
  let instrP5:Dictionary<UInt16, (Machine)->()->() > =
  [
    // Type 6
    0b0000001000 : sel_crrr,
  ]

  // Pattern P6
  let instrP6:Dictionary<UInt16, (Machine)->()->() > =
  [
    // Type 7
    0b0000000111 : set_cr,
  ]

  // Pattern P7
  let instrP7:Dictionary<UInt16, (Machine)->()->() > =
  [
    // Type 8
    0b000_000_0110 : ret,
    0b000_001_0110 : reti,
    0b000_010_0110 : dint,
    0b000_011_0110 : eint,
    0b000_100_0110 : nop,
    0b000_101_0110 : nop,
    0b000_110_0110 : nop,
    0b000_111_0110 : call_a,

    // Type 9
    0b000_000_010_0 : jmp_r,
    0b000_001_010_0 : call_r,
    0b000_010_010_0 : push_r,
    0b000_011_010_0 : pop_r,
    0b000_100_010_0 : nop,
    0b000_101_010_0 : nop,
    0b000_110_010_0 : mov_sr,
    0b000_111_010_0 : mov_rs,

    0b000_000_010_1 : mov_lr,
    0b000_001_010_1 : movw_ar,
    0b000_010_010_1 : movzb_ar,
    0b000_011_010_1 : movsb_ar,
    0b000_100_010_1 : movw_ra,
    0b000_101_010_1 : movb_ra,
    0b000_110_010_1 : nop,
    0b000_111_010_1 : nop,

    // type 10
    0b000_000_00_00 : mov_rr,
    0b000_001_00_00 : cmp_rr,
    0b000_010_00_00 : zext_rr,
    0b000_011_00_00 : sext_rr,
    0b000_100_00_00 : bswap_rr,
    0b000_101_00_00 : sextw_rr,
    0b000_110_00_00 : nop,
    0b000_111_00_00 : movw_pr,

    0b000_000_00_01 : lsr_rr,
    0b000_001_00_01 : lsl_rr,
    0b000_010_00_01 : asr_rr,
    0b000_011_00_01 : nop,
    0b000_100_00_01 : nop,
    0b000_101_00_01 : neg_rr,
    0b000_110_00_01 : not_rr,
    0b000_111_00_01 : nop,

    0b000_000_00_10 : add_rlr,
    0b000_001_00_10 : movw_qr,
    0b000_010_00_10 : movzb_qr,
    0b000_011_00_10 : movsb_qr,
    0b000_100_00_10 : movw_rq,
    0b000_101_00_10 : movb_rq,
    0b000_110_00_10 : nop,
    0b000_111_00_10 : nop,

    0b000_000_00_11 : micro0,
    0b000_001_00_11 : micro1,
    0b000_010_00_11 : micro2,
    0b000_011_00_11 : micro3,
    0b000_100_00_11 : micro4,
    0b000_101_00_11 : micro5,
    0b000_110_00_11 : micro6,
    0b000_111_00_11 : micro7,
  ]
  
  //-------------------------------------------------------------------------------------------
  func loadProgram( source:Data )
  {
    prg.storeProgram(atAddress:0, withData:source)
  }
  
//-------------------------------------------------------------------------------------------
  func reset()
  {
    ir = 0
    mir = 0
    prg.pc = 0
    reg.sp = mem.size  // FIX ME: Should this be automatically done by the machine setup code ??
  }
  
  //-------------------------------------------------------------------------------------------
  // create control signals
  func decode()
  {
  
    // Decode register and condition code operands
    rd = ir[2,0]
    rs = ir[5,3]
    rn = ir[8,6]
    cc = ir[12,10]
    
    // Decode embeeded immediate fields
    if      ir[15,13] == 0b111 { imm = ir.sext(11,0) } // Type T1: sign extended 12 bit
    else if ir[15,13] == 0b110 { imm = ir.sext(9,0) }  // Type T2: sign extended 10 bit
    else if ir[15,14] == 0b01 { imm = ir[11,6] }       // Type T4: zero extended 6 bit
    else if ir[15,14] == 0b10 {                        // Type T3: sign extend mov, cmp
      imm = ( ir[13,11] == 0b000 || ir[13,11] == 0b001 ) ? ir.sext(10,3) : ir[10,3]
    }
  
    // Decode long immediate
    imml = prg.value

    // Get the instruction opcode
    let op = mir[1,0] == 0b11 ? mir : ir[15,6]
    
    // Decode the instruction
    if      let f = instrP1[op & 0b1111000000] { exe = f }  // O1 Pattern
    else if let f = instrP2[op & 0b1110000000] { exe = f }  // O2 Pattern
    else if let f = instrP3[op & 0b1111100000] { exe = f }  // O3 Pattern
    else if let f = instrP4[op & 0b1111111000] { exe = f }  // O4 Pattern
    else if let f = instrP5[op & 0b1110001000] { exe = f }  // O5 Pattern
    else if let f = instrP6[op & 0b1110001111] { exe = f }  // O6 Pattern
    else if let f = instrP7[op & 0b1111111111] { exe = f }  // O7 Pattern
    else { out.exitWithError( "Unrecognized instruction opcode" ) }
    
    // Log
    if out.logEnabled { logDecode() }
  }
 
  //-------------------------------------------------------------------------------------------
  // execute control signals
  func execute()
  {
    j = false
    k = 0
    exe(self)()
    mir = k
    
    ir = prg.value
    if !j  { prg.pc = prg.pc &+ 1 }
    
    // Log
    if out.logEnabled { logExecute() }
  }
 
  //-------------------------------------------------------------------------------------------
  // run
  func run() -> Bool
  {
    for _ in 0..<50  // execute 50 instructions
    {
      decode()
      execute()
    }
    return true
  }

  //-------------------------------------------------------------------------------------------
  // Log functions
  func logDecode()
  {
    var str_ir = String(ir[15,6], radix:2) //binary base
    str_ir = String(repeating:"0", count:(10 - str_ir.count)) + str_ir
    
    var str_mir = String(mir, radix:2) //binary base
    str_mir = String(repeating:"0", count:(10 - str_mir.count)) + str_mir
    
    let prStr = String(format:"%05d : %@ %@", prg.pc &- 1, str_ir, str_mir )
    out.log( prStr )
  }

  func logExecute()
  {
    out.log( " " )
    out.logln( String(reflecting:reg) )
  }
}

*/
