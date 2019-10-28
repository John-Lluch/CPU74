//
//  Machine.swift
//  c74-sim
//
//  Created by Joan on 17/08/19.
//  Copyright © 2019 Joan. All rights reserved.
//

import Foundation



func nand(_ a:Bool, _ b:Bool) -> Bool { return !(a && b) }
func nand(_ a:Bool, _ b:Bool, _ c:Bool) -> Bool { return !(a && b && c) }
func nor(_ a:Bool, _ b:Bool) -> Bool { return !(a || b) }
func nor(_ a:Bool, _ b:Bool, _ c:Bool) -> Bool { return !(a || b || c) }
func and(_ a:Bool, _ b:Bool) -> Bool { return (a && b) }
func and(_ a:Bool, _ b:Bool, _ c:Bool) -> Bool { return (a && b && c) }
func or(_ a:Bool, _ b:Bool) -> Bool { return (a || b) }
func or(_ a:Bool, _ b:Bool, _ c:Bool) -> Bool { return (a || b || c) }

// Describes a machine with all its components
class Machine
{
  // Registers, Program memory, Data memory, ALU
  let reg = Registers()
  let prg = ProgramMemory()
  let mem = DataMemory()
  let rk = PrefixRegister()
  let alu = ALU()
  
  // Decoder registers
  var ir:UInt16 = 0    // Instruction register
  var mir:UInt16 = 0   // Microinstruction register
  
  // Buses, Intermediate values
  var rd:UInt16 = 0
  var rs:UInt16 = 0
  var rn:UInt16 = 0
  var imm:UInt16 = 0
  var cc:UInt16 = 0
  
  // Control
  var control:((Machine)->()->(), MCExt) = (wait, .me_end)
  var br_inhibit = false
  var pc_inhibit = false
  var mc_halt = false
  
  // Instruction Definitions
  

  
  // Type I1
  
  func mov_kr()    { reg[rd] = imm }
  func add_kr()    { reg[rd] = alu.add( reg[rd], imm ) }
  func sub_kr()    { reg[rd] = alu.sub( reg[rd], imm ) }
  
  func movw_ar()   { pc_inhibit=true ; mem.mar = imm }
  func movsb_ar()  { pc_inhibit=true ; mem.mar = imm }
  func movw_ra()   { pc_inhibit=true ; (mem.mar, mem.mdr) = (imm, reg[rd]) }
  func movb_ra()   { pc_inhibit=true ; (mem.mar, mem.mdr) = (imm, reg[rd]) }
  
  func lea_qr()    { reg[rd] = alu.adda( reg.sp, imm ) }
  func movw_qr()   { pc_inhibit=true ; mem.mar = alu.adda( imm, reg.sp ) }
  func movsb_qr()  { pc_inhibit=true ; mem.mar = alu.adda( imm, reg.sp ) }
  func movw_rq()   { pc_inhibit=true ; (mem.mar, mem.mdr) = (alu.adda( imm, reg.sp ), reg[rd]) }
  func movb_rq()   { pc_inhibit=true ; (mem.mar, mem.mdr) = (alu.adda( imm, reg.sp ), reg[rd]) }
  
  // Type I2
  
  func lea_mr()    { reg[rd] = alu.adda( reg[rs], imm ) }
  func movw_mr()   { pc_inhibit=true ; mem.mar = alu.adda( reg[rs], imm ) }
  func movzb_mr()  { pc_inhibit=true ; mem.mar = alu.adda( reg[rs], imm ) }
  func movsb_mr()  { pc_inhibit=true ; mem.mar = alu.adda( reg[rs], imm ) }
  func movw_rm()   { pc_inhibit=true ; (mem.mar, mem.mdr) = (alu.adda( reg[rs], imm ), reg[rd]) }
  func movb_rm()   { pc_inhibit=true ; (mem.mar, mem.mdr) = (alu.adda( reg[rs], imm ), reg[rd]) }
  
  
  func and_kr()    { reg[rd] = alu.and( reg[rs], imm ) }
  func cmp_crk()   { alu.cmp( cc, reg[rs], imm ) }
  func cmpc_crk()  { alu.cmpc( cc, reg[rs], imm ) }
  
  // Type P
  
  func _pfix()     { rk.value = imm }
  func call_k()    { pc_inhibit=true ; (reg.sp, mem.mar) = (alu.deca2( reg.sp ), alu.deca2( reg.sp )) ; mem.mdr = prg.pc }
  
  // Type R3
  
  func cmp_crr()   { alu.cmp( cc, reg[rs], reg[rn] ) }
  func cmpc_crr()  { alu.cmpc( cc, reg[rs], reg[rn] ) }
  func sub_rrr()   { reg[rd] = alu.sub ( reg[rs], reg[rn] ) }
  func subc_rrr()  { reg[rd] = alu.subc( reg[rs], reg[rn] ) }
  func or_rrr()    { reg[rd] = alu.or  ( reg[rs], reg[rn] ) }
  func and_rrr()   { reg[rd] = alu.and ( reg[rs], reg[rn] ) }
  func xor_rrr()   { reg[rd] = alu.xor ( reg[rs], reg[rn] ) }
  func addc_rrr()  { reg[rd] = alu.addc( reg[rs], reg[rn] ) }
  
  func add_rrr()   { reg[rd] = alu.add ( reg[rs], reg[rn] ) }
  func movw_nr()   { pc_inhibit=true ; mem.mar = alu.adda( reg[rs], reg[rn] ) }
  func movzb_nr()  { pc_inhibit=true ; mem.mar = alu.adda( reg[rs], reg[rn] ) }
  func movsb_nr()  { pc_inhibit=true ; mem.mar = alu.adda( reg[rs], reg[rn] ) }
  func movw_rn()   { pc_inhibit=true ; (mem.mar, mem.mdr) = (alu.adda( reg[rs], reg[rn] ), reg[rd]) }
  func movb_rn()   { pc_inhibit=true ; (mem.mar, mem.mdr) = (alu.adda( reg[rs], reg[rn] ), reg[rd]) }
  
  func sel_crrr()  { reg[rd] = alu.sr.t ? reg[rs] : reg[rn] }

  // Type J
  
  func br_nt()     { if !alu.sr.t { prg.pc = alu.adda( prg.pc, imm) ; br_inhibit=true } }
  func br_t()      { if alu.sr.t { prg.pc = alu.adda( prg.pc, imm) ; br_inhibit=true } }
  func jmp_k()     { pc_inhibit=true ; prg.pc = alu.adda( prg.pc, imm ) }
  func add_kq()    { reg.sp = alu.adda( reg.sp, imm ) }
  
  // Type R2
  
  func mov_rr()    { reg[rd] = reg[rs] }
  func mov_rq()    { reg.sp = reg[rs] }
  func zext_rr()   { reg[rd] = alu.zext( reg[rs] ) }
  func sext_rr()   { reg[rd] = alu.sext( reg[rs] ) }
  func bswap_rr()  { reg[rd] = alu.bswap( reg[rs] ) }
  func sextw_rr()  { reg[rd] = alu.sextw( reg[rs] ) }
  
  func movw_pr()   { pc_inhibit=true ; prg.par = reg[rs] }
  func movw_pr_1() { pc_inhibit=true ; prg.parsel = true ; reg[rd] = prg.value }
  
  func lsr_rr()    { reg[rd] = alu.lsr( reg[rs] ) }
  func lsrc_rr()   { reg[rd] = alu.lsrc( reg[rs] ) }
  func asr_rr()    { reg[rd] = alu.asr( reg[rs] ) }
  
  func sel_0rr()   { reg[rd] = alu.sr.t ? 0 : reg[rs] }
  func sel_r0r()   { reg[rd] = alu.sr.t ? reg[rs] : 0 }
  
  func neg_rr()    { reg[rd] = alu.neg( reg[rs] ) }
  func not_rr()    { reg[rd] = alu.not( reg[rs] ) }
  
  func jmp_r()     { pc_inhibit=true ; prg.pc = reg[rd] }
  func call_r()    { pc_inhibit=true ; (reg.sp, mem.mar) = (alu.deca2( reg.sp ), alu.deca2( reg.sp )) ; mem.mdr = prg.pc }
  
  func set_nt()    { reg[rd] = alu.sr.t ? 0 : 1 }
  func set_t()     { reg[rd] = alu.sr.t ? 1 : 0 }
  
  
  func mov_sr()    { }
  func mov_rs()    { }
  
  func ret()       { pc_inhibit=true ; (reg.sp, mem.mar) = (alu.inca2( reg.sp ), reg.sp) }
  func reti()      { }
  func dint()      { }
  func eint()      { }
  func halt()      { mc_halt=true }
  
  func nop()       { }
  
  // Micro
  
  func wait()      { }
  func load_w()    { reg[rd] = mem.value }
  func load_zb()   { reg[rd] = mem.zb }
  func load_sb()   { reg[rd] = mem.sb }
  func store_w()   { mem.writew() }
  func store_b()   { mem.writeb() }
  func call_k1()   { pc_inhibit=true ; mem.writew() ; prg.pc = imm }
  func call_r1()   { pc_inhibit=true ; mem.writew() ; prg.pc = reg[rd] }
  func ret1()      { pc_inhibit=true ; prg.pc = mem.value }
 
  // Instruction Encodings
  
  // Microcode extension codes (codes that correspond to execution of additional cycles)
  enum MCExt:UInt16
  {
    case me_end      = 0
    case me_wait     = 0b11_00000
    case me_load_w   = 0b11_00001
    case me_load_zb  = 0b11_00010
    case me_load_sb  = 0b11_00011
    case me_store_w  = 0b11_00100
    case me_store_b  = 0b11_00101
    case me_call_k1  = 0b11_00110
    case me_call_r1  = 0b11_01000
    case me_ret1     = 0b11_01001
    case me_movw_pr1 = 0b11_01010
  }
  
  // Microcode table
  let instrP0:Dictionary<UInt16, ((Machine)->()->(), MCExt) > =
  [
    // E7 11_ooooo
    MCExt.me_wait.rawValue      : (wait,      .me_end),
    MCExt.me_movw_pr1.rawValue  : (movw_pr_1, .me_wait),
    MCExt.me_load_w.rawValue    : (load_w,    .me_end),
    MCExt.me_load_zb.rawValue   : (load_zb,   .me_end),
    MCExt.me_load_sb.rawValue   : (load_sb,   .me_end),
    MCExt.me_store_w.rawValue   : (store_w,   .me_end),
    MCExt.me_store_b.rawValue   : (store_b,   .me_end),
    MCExt.me_call_k1.rawValue   : (call_k1,   .me_wait),
    MCExt.me_call_r1.rawValue   : (call_r1,   .me_wait),
    MCExt.me_ret1.rawValue      : (ret1,      .me_wait),
    
    // I1, I2, P
    0b10_01000  :  (mov_kr,    .me_end),
    0b10_01001  :  (add_kr,    .me_end),
    0b10_01010  :  (sub_kr,    .me_end),
    0b10_01011  :  (movw_ar,   .me_load_w),
    0b10_01100  :  (movsb_ar,  .me_load_sb),
    0b10_01101  :  (movw_ra,   .me_store_w),
    0b10_01110  :  (movb_ra,   .me_store_b),
    0b10_01111  :  (lea_qr,    .me_end),
    0b10_10000  :  (movw_qr,   .me_load_w),
    0b10_10001  :  (movsb_qr,  .me_load_sb),
    0b10_10010  :  (movw_rq,   .me_store_w),
    0b10_10011  :  (movb_rq,   .me_store_b),
    0b10_10100  :  (lea_mr,    .me_end),
    0b10_10101  :  (movw_mr,   .me_load_w),
    0b10_10110  :  (movzb_mr,  .me_load_zb),
    0b10_10111  :  (movsb_mr,  .me_load_sb),
    0b10_11000  :  (movw_rm,   .me_store_w),
    0b10_11001  :  (movb_rm,   .me_store_b),
    0b10_11010  :  (nop,       .me_end),
    0b10_11011  :  (and_kr,    .me_end),
    0b10_11100  :  (cmp_crk,   .me_end),
    0b10_11101  :  (cmpc_crk,  .me_end),
    0b10_11110  :  (call_k,    .me_call_k1),
    0b10_11111  :  (_pfix,     .me_end),
    
    // R3, J
    0b01_01000  :  (cmp_crr,   .me_end),
    0b01_01001  :  (cmpc_crr,  .me_end),
    0b01_01010  :  (sub_rrr,   .me_end),
    0b01_01011  :  (subc_rrr,  .me_end),
    0b01_01100  :  (or_rrr,    .me_end),
    0b01_01101  :  (and_rrr,   .me_end),
    0b01_01110  :  (xor_rrr,   .me_end),
    0b01_01111  :  (addc_rrr,  .me_end),
    0b01_10000  :  (add_rrr,   .me_end),
    0b01_10001  :  (movw_nr,   .me_load_w),
    0b01_10010  :  (movzb_nr,  .me_load_zb),
    0b01_10011  :  (movsb_nr,  .me_load_sb),
    0b01_10100  :  (movw_rn,   .me_store_w),
    0b01_10101  :  (movb_rn,   .me_store_b),
    0b01_10110  :  (nop,       .me_end),
    0b01_10111  :  (nop,       .me_end),
    0b01_11000  :  (sel_crrr,  .me_end),
    0b01_11001  :  (nop,       .me_end),
    0b01_11010  :  (nop,       .me_end),
    0b01_11011  :  (nop,       .me_end),
    0b01_11100  :  (br_nt,     .me_end),
    0b01_11101  :  (br_t,      .me_end),
    0b01_11110  :  (jmp_k,     .me_wait),
    0b01_11111  :  (add_kq,    .me_end),
    
    // R2
    0b00_00000  :  (mov_rr,    .me_end),
    0b00_00001  :  (mov_rq,    .me_end),
    0b00_00010  :  (zext_rr,   .me_end),
    0b00_00011  :  (sext_rr,   .me_end),
    0b00_00100  :  (bswap_rr,  .me_end),
    0b00_00101  :  (sextw_rr,  .me_end),
    0b00_00110  :  (nop,       .me_end),
    0b00_00111  :  (movw_pr,   .me_movw_pr1),
    0b00_01000  :  (lsr_rr,    .me_end),
    0b00_01001  :  (lsrc_rr,   .me_end),
    0b00_01010  :  (asr_rr,    .me_end),
    0b00_01011  :  (nop,       .me_end),
    0b00_01100  :  (sel_0rr,   .me_end),
    0b00_01101  :  (sel_r0r,   .me_end),
    0b00_01110  :  (neg_rr,    .me_end),
    0b00_01111  :  (not_rr,    .me_end),
    0b00_10000  :  (jmp_r,     .me_wait),
    0b00_10001  :  (call_r,    .me_call_r1),
    0b00_10010  :  (nop,       .me_end),
    0b00_10011  :  (nop,       .me_end),
    0b00_10100  :  (set_nt,    .me_end),
    0b00_10101  :  (set_t,     .me_end),
    0b00_10110  :  (mov_sr,    .me_end),
    0b00_10111  :  (mov_rs,    .me_end),
    0b00_11000  :  (ret,       .me_ret1),
    0b00_11001  :  (reti,      .me_wait), // revisar
    0b00_11010  :  (dint,      .me_end),
    0b00_11011  :  (eint,      .me_end),
    0b00_11100  :  (halt,      .me_end),
    0b00_11101  :  (nop,       .me_end),
    0b00_11110  :  (nop,       .me_end),
    0b00_11111  :  (nop,       .me_end),
  ]
  
  //-------------------------------------------------------------------------------------------
  func loadProgram( source:Data )
  {
    prg.storeProgram(atAddress:0, withData:source)
  }
  
  //-------------------------------------------------------------------------------------------
  func reset()
  {
    br_inhibit = true
    prg.pc = 0
    //reg.sp = mem.size  // FIX ME: Should this be automatically done by the machine setup code ??
  }
  
  
    //-------------------------------------------------------------------------------------------
  func decode()
  {

    // Decoding bits (a)

//    let a0 = !ir[15] && !ir[14]  // 00_xxx
//    let a1 = !ir[15] &&  ir[14]  // 01_xxx
//    let a3 =  ir[15] && !ir[14]  // 10_xxx
//    let a4 =  ir[15] &&  ir[14]  // 11_xxx
    
    // Decoding bits (b)

    let b0 =  !ir[15] && !ir[14] && !ir[13]    // 000_xx
    let b1 =  !ir[15] && !ir[14] &&  ir[13]    // 001_xx
    let b2 =  !ir[15] &&  ir[14] && !ir[13]    // 010_xx
    let b3 =  !ir[15] &&  ir[14] &&  ir[13]    // 011_xx
    let b4 =   ir[15] && !ir[14] && !ir[13]    // 100_xx
    let b5 =   ir[15] && !ir[14] &&  ir[13]    // 101_xx
    let b6 =   ir[15] &&  ir[14] && !ir[13]    // 110_xx
    let b7 =   ir[15] &&  ir[14] &&  ir[13]    // 111_xx
    
    // Decoding bits (c)
    
    //let c0 = !ir[12] && !ir[11]  // xxx_00
    //let c1 = !ir[12] &&  ir[11]  // xxx_01
    //let c2 =  ir[12] && !ir[11]  // xxx_10
    //let c3 =  ir[12] &&  ir[11]  // xxx_11
    
    let c0 = nor( ir[12], ir[11] )
    let c3 = and( ir[12], ir[11] )
    
    // Decoding bits (d)
    
//    let d0 = !ir[13] && !ir[12]  // xx00x
//    let d1 = !ir[13] &&  ir[12]  // xx01x
//    let d2 =  ir[13] && !ir[12]  // xx10x
//    let d3 =  ir[13] &&  ir[12]  // xx11x

    // Decoding bits (n)

//    let n0 =  !ir[15] && !ir[14] && !ir[13] && !ir[12]    // 0000_xxxxxx
//    let n1 =  !ir[15] && !ir[14] && !ir[13] &&  ir[12]    // 0001_xxxxxx
//    let n2 =  !ir[15] && !ir[14] &&  ir[13] && !ir[12]    // 0010_xxxxxx
//    let n3 =  !ir[15] && !ir[14] &&  ir[13] &&  ir[12]    // 0011_xxxxxx
//    let n4 =  !ir[15] &&  ir[14] && !ir[13] && !ir[12]    // 0100_xxxxxx
//    let n5 =  !ir[15] &&  ir[14] && !ir[13] &&  ir[12]    // 0101_xxxxxx
//    let n6 =  !ir[15] &&  ir[14] &&  ir[13] && !ir[12]    // 0110_xxxxxx
//    let n7 =  !ir[15] &&  ir[14] &&  ir[13] &&  ir[12]    // 0111_xxxxxx
//    let n8 =   ir[15] && !ir[14] && !ir[13] && !ir[12]    // 1000_xxxxxx
//    let n9 =   ir[15] && !ir[14] && !ir[13] &&  ir[12]    // 1001_xxxxxx
//    let n10 =  ir[15] && !ir[14] &&  ir[13] && !ir[12]    // 1010_xxxxxx
//    let n11 =  ir[15] && !ir[14] &&  ir[13] &&  ir[12]    // 1011_xxxxxx
//    let n12 =  ir[15] &&  ir[14] && !ir[13] && !ir[12]    // 1100_xxxxxx
//    let n13 =  ir[15] &&  ir[14] && !ir[13] &&  ir[12]    // 1101_xxxxxx
//    let n14 =  ir[15] &&  ir[14] &&  ir[13] && !ir[12]    // 1110_xxxxxx
//    let n15 =  ir[15] &&  ir[14] &&  ir[13] &&  ir[12]    // 1111_xxxxxx


    let n1 = and( nor( ir[15], ir[14], ir[13] ), ir[12]);

    // Decode register and condition code operands
    
    rd = ir[2,0]
    rs = ir[5,3]
    rn = ir[8,6]
    cc = rd

    // Decode embeeded immediate fields
    
    // P
    //if /*n15*/ b7 && (c2 || c3) /*b7 && ir[12]*/ {
    //if !or( !b7, and(!c2,!c3) ) {
    //if !or( !b7, !d3 ) {
    if !or( !b7, !ir[12] ) {
      imm = ir[10,0] }       // Type P, zero extended 11 bit

    // I2
    //if b5 || b6 || /*n14*/  (b7 && (c0 || c1))  /*(b7 && !ir[12])*/
   // let t:Bool = or( !b7, and(!c0,!c1) )
   // let t:Bool = or( !b7, !d2 )
    let t:Bool = or( !b7, ir[12] )
    if !and( !b5, !b6, t)
    {
      imm = ir[10,6] // Type I2, zero extended 5 bit
      //if /*n14*/  (b7 && (c0 || c1)) /*(b7 && !ir[12])*/ { imm = ir.sext(10,6) }  // Type I2, sign extended 5 bit
      if !t { imm = ir.sext(10,6) }  // Type I2, sign extended 5 bit
    }

    // I1
    //if b2 || b3 || b4
    else if !and( !b2, !b3, !b4)
    {
      imm = ir[10,3] // Type I1, zero extended 8 bit
      //if b2 && c0 { imm = ir.sext(10,3) } // Type I1, sign extended 8 bit
      if nor( !b2, !c0 ) { imm = ir.sext(10,3) } // Type I1, sign extended 8 bit
    }
    
    // J
    //if b1 && c3 {
    else if !or( !b1, !c3) {
      imm = ir.sext(8,0) }   // Type J, sign extended 9 bit

    if rk.enable {
      imm = (imm & 0b1_1111) | (rk.value<<5) }

    // Instruction decode

    var oh:UInt16 = 0     // xx
    var ol:UInt16 = 0     // yyyyy

    if !nand(!b0, !b1)      { oh = 2 ; ol = ir[15,11] }   // Types P, I1, I2  with 01ooo, 10ooo, 11ooo
    else if !and( !n1, !b1)   { oh = 1 ; ol = ir[13,9] }    // types J, R3       with 00_01ooo, 00_10ooo, 00_11ooo
    else if !or(!b0, ir[12])               { oh = 0 ; ol = ir[11,7] }    // Types R2          with 0000_ooooo
    //else if !or(!b0, !d0)               { oh = 0 ; ol = ir[11,7] }    // Types R2          with 0000_ooooo
    //else if !(!n0)               { oh = 0 ; ol = ir[11,7] }    // Types R2          with 0000_ooooo
    
    
//    if !(b0 || b1)      { oh = 2 ; ol = ir[15,11] }   // Types P, I1, I2  with 01ooo, 10ooo, 11ooo
//    if n1 || n2 || n3   { oh = 1 ; ol = ir[13,9] }    // types J, R3       with 00_01ooo, 00_10ooo, 00_11ooo
//    if n0               { oh = 0 ; ol = ir[11,7] }    // Types R2          with 0000_ooooo


    // Get the instruction opcode
    let op =  br_inhibit ? 0b11_00000 :
              control.1 != .me_end ? mir : (oh<<5) | ol
    // Log
    if out.logEnabled { logDecode() }

//    if (prg.pc == 356 )
//    {
//      let stop = 1
//    }

    // Decode the instruction (get the instruction control bits)
    if let f = instrP0[op] { control = f }  // Decoder Pattern
    else { out.exitWithError( "Unrecognized instruction opcode" ) }

    // These can only be set to true by the exec code, so we clear it first
    rk.enable = false
    prg.parsel = false
    br_inhibit = false
    pc_inhibit = false

  }
  
//  //-------------------------------------------------------------------------------------------
//  func decode()
//  {
//
//    // Decoding bits (level 1)
//
//    //let a0 = !ir[15] && !ir[14] && !ir[13]  // 000_xx_xx_xx_x
//    let a1 = !ir[15] && !ir[14] &&  ir[13]  // 001_xx_xx_xx_x
//    let a2 = !ir[15] &&  ir[14] && !ir[13]  // 010_xx_xx_xx_x
//    let a3 = !ir[15] &&  ir[14] &&  ir[13]  // 011_xx_xx_xx_x
//    let a4 =  ir[15] && !ir[14] && !ir[13]  // 100_xx_xx_xx_x
//    let a5 =  ir[15] && !ir[14] &&  ir[13]  // 101_xx_xx_xx_x
//    let a6 =  ir[15] &&  ir[14] && !ir[13]  // 110_xx_xx_xx_x
//    //let a7 =  ir[15] &&  ir[14] &&  ir[13]  // 111_xx_xx_xx_x
//
//    let b3 =  ir[12] &&  ir[11]             // xxx_11_xx_xx_x
//
//    //let c3 =  ir[10]                        // xxx_xx_1_xxx_x
//
//    let d0 =  !ir[8] && !ir[7]              // xxx_xx_xx_00_x
//    let d1 =  !ir[8] &&  ir[7]              // xxx_xx_xx_01_x
//    let d3 =   ir[8] &&  ir[7]              // xxx_xx_xx_11_x
//
////    let i0 =  !ir[12]                       // xxx_0x_xx_xx_x
////    let i1 =   ir[12]                       // xxx_1x_xx_xx_x
//
//    // Decoding bits (level 2)
//
//    let n0 =  !ir[15] && !ir[14] && !ir[13] && !ir[12]    // 0000_xxxxxx
//    let n1 =  !ir[15] && !ir[14] && !ir[13] &&  ir[12]    // 0001_xxxxxx
//    let n4 =  !ir[15] &&  ir[14] && !ir[13] && !ir[12]    // 0100_xxxxxx
//    let n5 =  !ir[15] &&  ir[14] && !ir[13] &&  ir[12]    // 0101_xxxxxx
//    let n6 =  !ir[15] &&  ir[14] &&  ir[13] && !ir[12]    // 0110_xxxxxx
//    let n7 =  !ir[15] &&  ir[14] &&  ir[13] &&  ir[12]    // 0111_xxxxxx
//    let n14 =  ir[15] &&  ir[14] &&  ir[13] && !ir[12]    // 1110_xxxxxx
//    let n15 =  ir[15] &&  ir[14] &&  ir[13] &&  ir[12]    // 1111_xxxxxx
//
//
////    let n0 =  a0 && i0    // 0000_xxxxxx
////    let n1 =  a0 && i1    // 0001_xxxxxx
////    let n4 =  a2 && i0    // 0100_xxxxxx
////    let n5 =  a2 && i1    // 0101_xxxxxx
////    let n6 =  a3 && i0    // 0110_xxxxxx
////    let n7 =  a3 && i1    // 0111_xxxxxx
////    let n14 = a7 && i0    // 1110_xxxxxx
////    let n15 = a7 && i1    // 1111_xxxxxx
//
//    // Decode register and condition code operands
//
//    rd = ir[2,0]
//    rs = ir[5,3]
//    rn = ir[8,6]
//    cc = ir[11,9]
//
//    // Decode embeeded immediate fields
//
//    if n15 {
//      imm = ir[10,0] }       // Type P, zero extended 11 bit
//
//    if a6 || n14 {
//      imm = ir[10,6] }       // Type I1, zero extended 5 bit
//
//    if n5 {
//      imm = ir.sext(10,3) }  // Type I2, sign extended 8 bit
//
//    if a3 || a4 || a5 {
//      imm = ir[10,3] }       // Type I2, zero extended 8 bit
//
//    if n4 || (a1 && b3 && ir[10]) {
//      imm = ir.sext(8,0) }   // Type J, sign extended 9 bit
//
//    imm = imm | (rk.value<<5)
//
//    // Instruction decode
//
//    var oh:UInt16 = 0     // xxx
//    var ol:UInt16 = 0     // yyyy
//
//    //if (n0 && d3) || n1 || a2 || a3  { oh = 4 }   // Types J, R1, R2  with 0000ccc11x, 0001ccc, 010_0ccc,
//                                                  // Types I2         with 010_1o, 011_0o, 011_1o
//    oh = 4;
//    if ir[15]                        { oh = 3 }   // Types P, I1, I2  with 1oooo
//    if a1                            { oh = 2 }   // Types J, R1      with 001oooo
//    if n0 && d1                      { oh = 1 }   // type R2          with 0000ooo01o
//    if n0 && d0                      { oh = 0 }   // Type R2          with 0000ooo00o
//
//    if ir[15]                   { ol = ir[14,11] }                 // Types P, I1, I2  with 1oooo
//    if n5 || n6 || n7           { ol = ir[14,11] }                 // Types I2    with 0101o, 0110o, 0111o
//    if n4                       { ol = 2 }                         // Type J      with 0100ccc
//    if a1                       { ol = ir[12,9] }                  // Type J, R1  with 001oooo
//    if n1                       { ol = 1 }                         // Type R1     with 0001ccc
//    if n0 && d3                 { ol = 0 }                         // Type R2     with 0000ccc11x
//    if n0 && (d0 || d1)         { ol = (ir[6,6]<<3) | ir[11,9] }   // Type R2     with 0000ooo00o, 0000ooo01o
//
//    // Get the instruction opcode
//    let op =  br_inhibit ? 0b111_0000 :
//              control.1 != .me_end ? mir : (oh<<4) | ol
//    // Log
//    if out.logEnabled { logDecode() }
//
////    if (prg.pc == 356 )
////    {
////      let stop = 1
////    }
//
//    // Decode the instruction (get the instruction control bits)
//    if let f = instrP0[op] { control = f }  // Decoder Pattern
//    else { out.exitWithError( "Unrecognized instruction opcode" ) }
//
//    // These can only be set to true by the exec code, so we clear it first
//    prg.parsel = false
//    br_inhibit = false
//    pc_inhibit = false
//
//  }
//
  //-------------------------------------------------------------------------------------------
  // This represents the execution of control signals
  func process() -> Bool
  {
    // Prefetch next instruction
    if control.1 != .me_end { mir = control.1.rawValue }
    else { ir = prg.value }
    
    // Execute control lines
    control.0(self)()    // process the instruction
    
    // Only increment PC if we have to
    if !(pc_inhibit || br_inhibit)  { prg.pc = prg.pc &+ 1 }
    
    // Log
    if out.logEnabled { logExecute() }
    
    return mc_halt
  }
 
  //-------------------------------------------------------------------------------------------
  // run
  func run() -> Bool
  {
    var done = false
    while !done  // execute until 'halt' instruction
    {
      decode()
      done = process()
    }
    return true
  }

  //-------------------------------------------------------------------------------------------
  // Log functions
  func logDecode()
  {
    let ir_prefix = control.1 != .me_end ? " " : ">"
    var str_ir = String(ir, radix:2) //binary base
    str_ir = String(repeating:"0", count:(16 - str_ir.count)) + str_ir
    
    let mir_prefix = control.1 != .me_end ? ">" : " "
    var str_mir = String(mir, radix:2) //binary base
    str_mir = String(repeating:"0", count:(10 - str_mir.count)) + str_mir
    
    let addr = (pc_inhibit || br_inhibit) ? "-----" : String(format:"%05d", prg.pc &- 1)
    let prStr = String(format:"%@ : %@%@ %@%@", addr, ir_prefix,str_ir, mir_prefix,str_mir )
    out.log( prStr )
  }

  func logExecute()
  {
    out.log( " " )
    out.logln( String(reflecting:reg) )
  }
}


