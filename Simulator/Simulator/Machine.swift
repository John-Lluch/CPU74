//
//  Machine.swift
//  c74-sim
//
//  Created by Joan on 17/08/19.
//  Copyright © 2019 Joan. All rights reserved.
//

import Foundation

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
  
  // Type P
  
  func _pfix()     { rk.value = imm } 
  func call_k()    { pc_inhibit=true ; (reg.sp, mem.mar) = (alu.deca2( reg.sp ), alu.deca2( reg.sp )) ; mem.mdr = prg.pc }
  
  // Type I1
  
  func lea_mr()    { reg[rd] = alu.adda( reg[rs], imm ) }
  func movw_mr()   { pc_inhibit=true ; mem.mar = alu.adda( reg[rs], imm ) }
  func movzb_mr()  { pc_inhibit=true ; mem.mar = alu.adda( reg[rs], imm ) }
  func movsb_mr()  { pc_inhibit=true ; mem.mar = alu.adda( reg[rs], imm ) }
  func movw_rm()   { pc_inhibit=true ; (mem.mar, mem.mdr) = (alu.adda( reg[rs], imm ), reg[rd]) }
  func movb_rm()   { pc_inhibit=true ; (mem.mar, mem.mdr) = (alu.adda( reg[rs], imm ), reg[rd]) }
  
  // Type I2
  
  func mov_kr()    { reg[rd] = imm }
  func cmp_rk()    { alu.cmp( reg[rd], imm ) }
  func add_kr()    { reg[rd] = alu.add( reg[rd], imm ) }
  func sub_kr()    { reg[rd] = alu.sub( reg[rd], imm ) }
  func and_kr()    { reg[rd] = alu.and( reg[rd], imm ) }
  
  func movw_ar()   { pc_inhibit=true ; mem.mar = imm }
  func movsb_ar()  { pc_inhibit=true ; mem.mar = imm }
  func movw_ra()   { pc_inhibit=true ; (mem.mar, mem.mdr) = (imm, reg[rd]) }
  func movb_ra()   { pc_inhibit=true ; (mem.mar, mem.mdr) = (imm, reg[rd]) }
  
  func lea_qr()    { reg[rd] = alu.adda( reg.sp, imm ) }
  func movw_qr()   { pc_inhibit=true ; mem.mar = alu.adda( imm, reg.sp ) }
  func movsb_qr()  { pc_inhibit=true ; mem.mar = alu.adda( imm, reg.sp ) }
  func movw_rq()   { pc_inhibit=true ; (mem.mar, mem.mdr) = (alu.adda( imm, reg.sp ), reg[rd]) }
  func movb_rq()   { pc_inhibit=true ; (mem.mar, mem.mdr) = (alu.adda( imm, reg.sp ), reg[rd]) }
  
  // Type J
  
  func br_ck()     { if alu.hasCC(cc) { prg.pc = alu.adda( prg.pc, imm) ; br_inhibit=true } }
  func jmp_k()     { pc_inhibit=true ; prg.pc = alu.adda( prg.pc, imm ) }
  func add_kq()    { reg.sp = alu.adda( reg.sp, imm ) }
  
  // Type R1
  
  func cmp_rr()    { alu.cmp( reg[rs], reg[rn] ) }
  func cmpc_rr()   { alu.cmpc( reg[rs], reg[rn] ) }
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
  
  func sel_crrr()  { reg[rd] = alu.hasCC(cc) ? reg[rs] : reg[rn]  }

  // Type R2
  
  func set_cr()    { reg[rd] = alu.hasCC(cc) ? 1 : 0 }
  
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
  func neg_rr()    { reg[rd] = alu.neg( reg[rs] ) }
  func not_rr()    { reg[rd] = alu.not( reg[rs] ) }
  
  func jmp_r()     { pc_inhibit=true ; prg.pc = reg[rd] }
  func call_r()    { pc_inhibit=true ; (reg.sp, mem.mar) = (alu.deca2( reg.sp ), alu.deca2( reg.sp )) ; mem.mdr = prg.pc }
  
  func push_r()    { pc_inhibit=true ; (reg.sp, mem.mar) = (alu.deca2( reg.sp ), alu.deca2( reg.sp )) ; mem.mdr = reg[rd] }
  func pop_r()     { pc_inhibit=true ; (reg.sp, mem.mar) = (alu.inca2( reg.sp ), reg.sp) }
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
    case me_wait     = 0b111_0000
    case me_load_w   = 0b111_0001
    case me_load_zb  = 0b111_0010
    case me_load_sb  = 0b111_0011
    case me_store_w  = 0b111_0100
    case me_store_b  = 0b111_0101
    case me_call_k1  = 0b111_0110
    //case me_call_a1  = 0b111_0111
    case me_call_r1  = 0b111_1000
    case me_ret1     = 0b111_1001
    
    case me_movw_pr1 = 0b111_1010
  }
  
  // Microcode table
  let instrP0:Dictionary<UInt16, ((Machine)->()->(), MCExt) > =
  [
    // E7 111_oooo
    MCExt.me_wait.rawValue      : (wait,      .me_end),
    MCExt.me_movw_pr1.rawValue  : (movw_pr_1, .me_wait),
    MCExt.me_load_w.rawValue    : (load_w,    .me_end),
    MCExt.me_load_zb.rawValue   : (load_zb,   .me_end),
    MCExt.me_load_sb.rawValue   : (load_sb,   .me_end),
    MCExt.me_store_w.rawValue   : (store_w,   .me_end),
    MCExt.me_store_b.rawValue   : (store_b,   .me_end),
    MCExt.me_call_k1.rawValue   : (call_k1,   .me_wait),
   // MCExt.me_call_a1.rawValue   : (call_a1,   .me_wait),
    MCExt.me_call_r1.rawValue   : (call_r1,   .me_wait),
    MCExt.me_ret1.rawValue      : (ret1,      .me_wait),
    
    // Types R2
    0b000_0000  :  (mov_rr,    .me_end),
    0b000_0001  :  (mov_rq,    .me_end),
    0b000_0010  :  (zext_rr,   .me_end),
    0b000_0011  :  (sext_rr,   .me_end),
    0b000_0100  :  (bswap_rr,  .me_end),
    0b000_0101  :  (sextw_rr,  .me_end),
    0b000_0110  :  (nop,       .me_end),
    0b000_0111  :  (movw_pr,   .me_movw_pr1),
    0b000_1000  :  (lsr_rr,    .me_end),
    0b000_1001  :  (lsrc_rr,    .me_end),
    0b000_1010  :  (asr_rr,    .me_end),
    0b000_1011  :  (nop,       .me_end),
    0b000_1100  :  (nop,       .me_end),
    0b000_1101  :  (neg_rr,    .me_end),
    0b000_1110  :  (not_rr,    .me_end),
    0b000_1111  :  (nop,       .me_end),
    
    // Types R2
    0b001_0000  :  (jmp_r,     .me_wait),
    0b001_0001  :  (call_r,    .me_call_r1),
    0b001_0010  :  (push_r,    .me_store_w),
    0b001_0011  :  (pop_r,     .me_load_w),
    0b001_0100  :  (nop,       .me_end),
    0b001_0101  :  (nop,       .me_end),
    0b001_0110  :  (mov_sr,    .me_end),
    0b001_0111  :  (mov_rs,    .me_end),
    0b001_1000  :  (ret,       .me_ret1),
    0b001_1001  :  (reti,      .me_wait), // revisar
    0b001_1010  :  (dint,      .me_end),
    0b001_1011  :  (eint,      .me_end),
    0b001_1100  :  (halt,      .me_end),
    0b001_1101  :  (nop,       .me_end),
    0b001_1110  :  (nop,       .me_end),
    0b001_1111  :  (nop,       .me_end),
    
    // Types J, R1
    0b010_0000  :  (cmp_rr,    .me_end),
    0b010_0001  :  (cmpc_rr,   .me_end),
    0b010_0010  :  (sub_rrr,   .me_end),
    0b010_0011  :  (subc_rrr,  .me_end),
    0b010_0100  :  (or_rrr,    .me_end),
    0b010_0101  :  (and_rrr,   .me_end),
    0b010_0110  :  (xor_rrr,   .me_end),
    0b010_0111  :  (addc_rrr,  .me_end),
    0b010_1000  :  (add_rrr,   .me_end),
    0b010_1001  :  (movw_nr,   .me_load_w),
    0b010_1010  :  (movzb_nr,  .me_load_zb),
    0b010_1011  :  (movsb_nr,  .me_load_sb),
    0b010_1100  :  (movw_rn,   .me_store_w),
    0b010_1101  :  (movb_rn,   .me_store_b),
    0b010_1110  :  (add_kq,    .me_end),
    0b010_1111  :  (jmp_k,     .me_wait),
    
    // Types I2, R2, R1, J
    0b011_0000  :  (set_cr,    .me_end),
    0b011_0001  :  (sel_crrr,  .me_end),
    0b011_0010  :  (br_ck,     .me_end),
    0b011_0011  :  (nop,       .me_end),
    0b011_0100  :  (nop,       .me_end),
    0b011_0101  :  (nop,       .me_end),
    0b011_0110  :  (nop,       .me_end),
    0b011_0111  :  (nop,       .me_end),
    0b011_1000  :  (nop,       .me_end),
    0b011_1001  :  (nop,       .me_end),
    0b011_1010  :  (mov_kr,    .me_end),
    0b011_1011  :  (cmp_rk,    .me_end),
    0b011_1100  :  (add_kr,    .me_end),
    0b011_1101  :  (sub_kr,    .me_end),
    0b011_1110  :  (and_kr,    .me_end),
    0b011_1111  :  (movw_ar,   .me_load_w),
    
    // Types P, I1, I2
    0b100_0000  :  (movsb_ar,  .me_load_sb),
    0b100_0001  :  (movw_ra,   .me_store_w),
    0b100_0010  :  (movb_ra,   .me_store_b),
    0b100_0011  :  (lea_qr,    .me_end),
    0b100_0100  :  (movw_qr,   .me_load_w),
    0b100_0101  :  (movsb_qr,  .me_load_sb),
    0b100_0110  :  (movw_rq,   .me_store_w),
    0b100_0111  :  (movb_rq,   .me_store_b),
    0b100_1000  :  (lea_mr,    .me_end),
    0b100_1001  :  (movw_mr,   .me_load_w),
    0b100_1010  :  (movzb_mr,  .me_load_zb),
    0b100_1011  :  (movsb_mr,  .me_load_sb),
    0b100_1100  :  (movw_rm,   .me_store_w),
    0b100_1101  :  (movb_rm,   .me_store_b),
    0b100_1110  :  (call_k,    .me_call_k1),
    0b100_1111  :  (_pfix,     .me_end),
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
    reg.sp = mem.size  // FIX ME: Should this be automatically done by the machine setup code ??
  }
  
  func decode()
  {
  
    // Decoding bits (level 1)
    
    let a0 = !ir[15] && !ir[14] && !ir[13]  // 000_xx_xx_xx_x
    let a1 = !ir[15] && !ir[14] &&  ir[13]  // 001_xx_xx_xx_x
    let a2 = !ir[15] &&  ir[14] && !ir[13]  // 010_xx_xx_xx_x
    let a3 = !ir[15] &&  ir[14] &&  ir[13]  // 011_xx_xx_xx_x
    let a4 =  ir[15] && !ir[14] && !ir[13]  // 100_xx_xx_xx_x
    let a5 =  ir[15] && !ir[14] &&  ir[13]  // 101_xx_xx_xx_x
    let a6 =  ir[15] &&  ir[14] && !ir[13]  // 110_xx_xx_xx_x
    let a7 =  ir[15] &&  ir[14] &&  ir[13]  // 111_xx_xx_xx_x
    
    let b3 =  ir[12] &&  ir[11]             // xxx_11_xx_xx_x
    
    let c3 =  ir[10]                        // xxx_xx_1_xxx_x
    
    let d0 =  !ir[8] && !ir[7]              // xxx_xx_xx_00_x
    let d1 =  !ir[8] &&  ir[7]              // xxx_xx_xx_01_x
    let d3 =   ir[8] &&  ir[7]              // xxx_xx_xx_11_x
    
    let i0 =  !ir[12]                       // xxx_0x_xx_xx_x
    let i1 =   ir[12]                       // xxx_1x_xx_xx_x
    
    // Decoding bits (level 2)
    
    let n0 =  a0 && i0    // 0000_xxxxxx
    let n1 =  a0 && i1    // 0001_xxxxxx
    let n4 =  a2 && i0    // 0100_xxxxxx
    let n5 =  a2 && i1    // 0101_xxxxxx
    let n6 =  a3 && i0    // 0110_xxxxxx
    let n7 =  a3 && i1    // 0111_xxxxxx
    let n14 = a7 && i0    // 1110_xxxxxx
    let n15 = a7 && i1    // 1111_xxxxxx
  
    // Decode register and condition code operands
    
    rd = ir[2,0]
    rs = ir[5,3]
    rn = ir[8,6]
    cc = ir[11,9]
    
    // Decode embeeded immediate fields
    
    if n15 {
      imm = ir[10,0] }       // Type P, zero extended 11 bit
    
    if a6 || n14 {
      imm = ir[10,6] }       // Type I1, zero extended 5 bit
    
    if n5 {
      imm = ir.sext(10,3) }  // Type I2, sign extended 8 bit
    
    if a3 || a4 || a5 {
      imm = ir[10,3] }       // Type I2, zero extended 8 bit
    
    if n4 || (a1 && b3 && c3) {
      imm = ir.sext(8,0) }   // Type J, sign extended 9 bit
    
    imm = imm | (rk.value<<5)
    
    // Instruction decode
    
    var oh:UInt16 = 0     // xxx
    var ol:UInt16 = 0     // yyyy
    
    if ir[15]                        { oh = 4 }   // Types P, I1, I2  with 1oooo
    if (n0 && d3) || n1 || a2 || a3  { oh = 3 }   // Types J, R1, R2  with 0100ccc, 0001ccc, 0000ccc11x,
                                                  // Types I2         with 0101o, 0110o, 0111o
    
    if a1                            { oh = 2 }   // Types J, R1      with 001oooo
    if n0 && d1                      { oh = 1 }   // type R2          with 0000ooo01o
    if n0 && d0                      { oh = 0 }   // Type R2          with 0000ooo00o
  
    if ir[15]                   { ol = ir[14,11] }                 // Types P, I1, I2  with 1oooo
    if n5 || n6 || n7           { ol = ir[14,11] }                 // Types I2    with 0101o, 0110o, 0111o
    if n4                       { ol = 2 }                         // Type J      with 0100ccc
    if n1                       { ol = 1 }                         // Type R1     with 0001ccc
    if n0 && d3                 { ol = 0 }                         // Type R2     with 0000ccc11x
    if a1                       { ol = ir[12,9] }                  // Type J, R1  with 001oooo
    if n0 && (d0 || d1)         { ol = (ir[6,6]<<3) | ir[11,9] }   // Type R2     with 0000ooo00o, 0000ooo01o
    
    // Get the instruction opcode
    let op =  br_inhibit ? 0b111_0000 :
              control.1 != .me_end ? mir : (oh<<4) | ol
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
    prg.parsel = false
    br_inhibit = false
    pc_inhibit = false
    
  }
 
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


