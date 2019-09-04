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
  let alu = ALU()
  
  // Decoder registers
  var ir:UInt16 = 0    // Instruction register
  var mir:UInt16 = 0   // Microinstruction register
  
  // Buses, Intermediate values
  var rd:UInt16 = 0
  var rs:UInt16 = 0
  var rn:UInt16 = 0
  var imm:UInt16 = 0
  //var imml:UInt16 = 0
  var cc:UInt16 = 0
  
  // Control
  var control:((Machine)->()->(), MCExt) = (wait, .me_end)
  var br_inhibit = false
  var pc_inhibit = false
  var mc_halt = false
  
  // Instruction Definitions
  
  // Type 1
  func jmp_k()     { pc_inhibit=true ; prg.pc = alu.adda( prg.pc, imm ) }
  func call_k()    { pc_inhibit=true ; (reg.sp, mem.mar) = (alu.deca2( reg.sp ), alu.deca2( reg.sp )) ; mem.mdr = prg.pc }
  
  // Type 2
  func br_ck()     { if alu.hasCC(cc) { prg.pc = alu.adda( prg.pc, imm) ; br_inhibit=true } }
  
  // Type 3
  func mov_kr()    { reg[rd] = imm }
  func cmp_rk()    { alu.cmp( reg[rd], imm ) }
  func add_kr()    { reg[rd] = alu.add( reg[rd], imm ) }
  func sub_kr()    { reg[rd] = alu.sub( reg[rd], imm ) }
  func and_kr()    { reg[rd] = alu.and( reg[rd], imm ) }
  func or_kr()     { reg[rd] = alu.or ( reg[rd], imm ) }
  func xor_kr()    { reg[rd] = alu.xor( reg[rd], imm ) }
  
  // Type 4
  func movw_mr()   { pc_inhibit=true ; mem.mar = alu.add( imm, reg[rs] ) }
  func movsb_mr()  { pc_inhibit=true ; mem.mar = alu.add( imm, reg[rs] ) }
  func movw_rm()   { pc_inhibit=true ; (mem.mar, mem.mdr) = (alu.add( imm, reg[rs] ), reg[rd]) }
  func movb_rm()   { pc_inhibit=true ; (mem.mar, mem.mdr) = (alu.add( imm, reg[rs] ), reg[rd]) }
  
  // Type 5
  func add_rrr()   { reg[rd] = alu.add ( reg[rn], reg[rs] ) }
  func addc_rrr()  { reg[rd] = alu.addc( reg[rn], reg[rs] ) }
  func sub_rrr()   { reg[rd] = alu.sub ( reg[rn], reg[rs] ) }
  func subc_rrr()  { reg[rd] = alu.subc( reg[rn], reg[rs] ) }
  func or_rrr()    { reg[rd] = alu.or  ( reg[rn], reg[rs] ) }
  func and_rrr()   { reg[rd] = alu.and ( reg[rn], reg[rs] ) }
  func xor_rrr()   { reg[rd] = alu.xor ( reg[rn], reg[rs] ) }
  func movw_nr()   { pc_inhibit=true ; mem.mar = alu.add( reg[rn], reg[rs] ) }
  func movzb_nr()  { pc_inhibit=true ; mem.mar = alu.add( reg[rn], reg[rs] ) }
  func movsb_nr()  { pc_inhibit=true ; mem.mar = alu.add( reg[rn], reg[rs] ) }
  func movw_rn()   { pc_inhibit=true ; (mem.mar, mem.mdr) = (alu.add( reg[rn], reg[rs] ), reg[rd]) }
  func movb_rn()   { pc_inhibit=true ; (mem.mar, mem.mdr) = (alu.add( reg[rn], reg[rs] ), reg[rd]) }
  
  // Type 6
  func sel_crrr()  { reg[rd] = alu.hasCC(cc) ? reg[rn] : reg[rs] }
  
  // Type 7
  func set_cr()    { reg[rd] = alu.hasCC(cc) ? 1 : 0 }
  
  // Type 8
  //func ret()       { pc_inhibit=true ; mem.mar = reg.sp ; reg.sp = alu.inca2( reg.sp ) }
  func ret()       { pc_inhibit=true ; (reg.sp, mem.mar) = (alu.inca2( reg.sp ), reg.sp) }
  func reti()      { }
  func dint()      { }
  func eint()      { }
  func halt()      { mc_halt=true }
  func call_a()    { pc_inhibit=true ; (reg.sp, mem.mar) = (alu.deca2( reg.sp ), alu.deca2( reg.sp )) ; mem.mdr = alu.adda( prg.pc, 1 ) }
  
  // Type 9
  func jmp_r()     { pc_inhibit=true ; prg.pc = reg[rd] }
  func call_r()    { pc_inhibit=true ; (reg.sp, mem.mar) = (alu.deca2( reg.sp ), alu.deca2( reg.sp )) ; mem.mdr = prg.pc }
  func push_r()    { pc_inhibit=true ; (reg.sp, mem.mar) = (alu.deca2( reg.sp ), alu.deca2( reg.sp )) ; mem.mdr = reg[rd] }
  //func pop_r()     { pc_inhibit=true ; mem.mar = reg.sp ; reg.sp = alu.inca2( reg.sp ) }
  func pop_r()     { pc_inhibit=true ; (reg.sp, mem.mar) = (alu.inca2( reg.sp ), reg.sp) }
  func mov_sr()    { }
  func mov_rs()    { }
  func mov_lr()    { reg[rd] = prg.value }
  func movw_ar()   { mem.mar = prg.value /*; reg[rd] = mem.value*/ }
  func movzb_ar()  { mem.mar = prg.value /*; reg[rd] = mem.zb*/ }
  func movsb_ar()  { mem.mar = prg.value /*; reg[rd] = mem.sb*/ }
  func movw_ra()   { (mem.mar, mem.mdr) = (prg.value, reg[rd]) }
  func movb_ra()   { (mem.mar, mem.mdr) = (prg.value, reg[rd]) }
  
  // Type 10
  func mov_rr()    { reg[rd] = reg[rs] }
  func cmp_rr()    { alu.cmp( reg[rd], reg[rs] ) } // <- FIX ME: In order to keep rs on the Right, operands must be swapped by the compiler
  func zext_rr()   { reg[rd] = alu.zext( reg[rs] ) }
  func sext_rr()   { reg[rd] = alu.sext( reg[rs] ) }
  func bswap_rr()  { reg[rd] = alu.bswap( reg[rs] ) }
  func sextw_rr()  { reg[rd] = alu.sextw( reg[rs] ) }
  
  func movw_pr()   { pc_inhibit=true ; prg.par = reg[rs] }
  func movw_pr_1() { pc_inhibit=true ; prg.parsel = true ; reg[rd] = prg.value }
  
  func lsr_rr()    { reg[rd] = alu.lsr( reg[rs] ) }
  func lsl_rr()    { reg[rd] = alu.lsl( reg[rs] ) }
  func asr_rr()    { reg[rd] = alu.asr( reg[rs] ) }
  func neg_rr()    { reg[rd] = alu.neg( reg[rs] ) }
  func not_rr()    { reg[rd] = alu.not( reg[rs] ) }
//  func add_rlr()   { reg[rd] = alu.adda( prg.value, reg[rs] ) }
//  func movw_qr()   { mem.mar = alu.add( prg.value, reg[rs] ) /*; reg[rd] = mem.value*/ }
//  func movzb_qr()  { mem.mar = alu.add( prg.value, reg[rs] ) /*; reg[rd] = mem.zb*/ }
//  func movsb_qr()  { mem.mar = alu.add( prg.value, reg[rs] ) /*; reg[rd] = mem.sb*/ }
//  func movw_rq()   { mem.mar = alu.add( imm, reg[rs] ) /*; mem.value = reg[rd]*/ }
//  func movb_rq()   { mem.mar = alu.add( imm, reg[rs] ) /*; mem.zb = reg[rd]*/ }
  func nop()       { }
  
  // Micro
  func wait()      { }
  func load_w()    { reg[rd] = mem.value }
  func load_zb()   { reg[rd] = mem.zb }
  func load_sb()   { reg[rd] = mem.sb }
  func store_w()   { mem.writew() }
  func store_b()   { mem.writeb() }
  func call_k1()   { pc_inhibit=true ; mem.writew() ; prg.pc = alu.adda( prg.pc, imm ) }
  func call_a1()   { pc_inhibit=true ; mem.writew() ; prg.pc = prg.value }
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
    case me_call_a1  = 0b111_0111
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
    MCExt.me_call_a1.rawValue   : (call_a1,   .me_wait),
    MCExt.me_call_r1.rawValue   : (call_r1,   .me_wait),
    MCExt.me_ret1.rawValue      : (ret1,      .me_wait),

    // T2, E6b 110_xxxxxxx
    0b110_0010  :  (br_ck,     .me_end),

    // T6, E6a 000_xxx_1_xxx
    0b110_0001  :  (sel_crrr,  .me_end),

    // T7, E6 000_xxx_0111
    0b110_0000  :  (set_cr,    .me_end),

    // T3, E5a  10_ooo_xxxxx
    0b101_1_000 :  (mov_kr,    .me_end),
    0b101_1_001 :  (cmp_rk,    .me_end),
    0b101_1_010 :  (add_kr,    .me_end),
    0b101_1_011 :  (sub_kr,    .me_end),
    0b101_1_100 :  (and_kr,    .me_end),
    0b101_1_101 :  (or_kr,     .me_end),
    0b101_1_110 :  (xor_kr,    .me_end),
    0b101_1_111 :  (nop,       .me_end),

    // T4, E5  01_oo_xxxxxx
    0b101_00_00 :  (movw_mr,   .me_load_w),
    0b101_00_01 :  (movsb_mr,  .me_load_sb),
    0b101_00_10 :  (movw_rm,   .me_store_w),
    0b101_00_11 :  (movb_rm,   .me_store_b),

    // T5, E4  001_oooo_xxx
    0b100_0000  :  (add_rrr,   .me_end),
    0b100_0001  :  (addc_rrr,  .me_end),
    0b100_0010  :  (sub_rrr,   .me_end),
    0b100_0011  :  (subc_rrr,  .me_end),
    0b100_0100  :  (or_rrr,    .me_end),
    0b100_0101  :  (and_rrr,   .me_end),
    0b100_0110  :  (xor_rrr,   .me_end),
    0b100_0111  :  (nop,       .me_end),

    0b100_1000  :  (nop,       .me_end),
    0b100_1001  :  (movw_nr,   .me_load_w),
    0b100_1010  :  (movzb_nr,  .me_load_zb),
    0b100_1011  :  (movsb_nr,  .me_load_sb),
    0b100_1100  :  (movw_rn,   .me_store_w),
    0b100_1101  :  (movb_rn,   .me_store_b),
    0b100_1110  :  (nop,       .me_end),
    0b100_1111  :  (nop,       .me_end),

    // T1, E3a  111_o_xxxxxx
    0b011_100_0 :  (jmp_k,     .me_wait),
    0b011_100_1 :  (call_k,    .me_call_k1),

    // T8, E3   000_ooo_0110
    0b011_0_000 :  (ret,       .me_ret1),
    0b011_0_001 :  (reti,      .me_wait), // revisar
    0b011_0_010 :  (dint,      .me_end),
    0b011_0_011 :  (eint,      .me_end),
    0b011_0_100 :  (halt,      .me_end),
    0b011_0_101 :  (nop,       .me_end),
    0b011_0_110 :  (nop,       .me_end),
    0b011_0_111 :  (call_a,    .me_call_a1),

    // T9, E2  000_ooo_010_o
    0b010_000_0 :  (jmp_r,     .me_wait),
    0b010_001_0 :  (call_r,    .me_call_r1),
    0b010_010_0 :  (push_r,    .me_store_w),
    0b010_011_0 :  (pop_r,     .me_load_w),
    0b010_100_0 :  (nop,       .me_end),
    0b010_101_0 :  (nop,       .me_end),
    0b010_110_0 :  (mov_sr,    .me_end),
    0b010_111_0 :  (mov_rs,    .me_end),

    0b010_000_1 :  (mov_lr,    .me_wait),
    0b010_001_1 :  (movw_ar,   .me_load_w),
    0b010_010_1 :  (movzb_ar,  .me_load_zb),
    0b010_011_1 :  (movsb_ar,  .me_load_sb),
    0b010_100_1 :  (movw_ra,   .me_store_w),
    0b010_101_1 :  (movb_ra,   .me_store_b),
    0b010_110_1 :  (nop,       .me_end),
    0b010_111_1 :  (nop,       .me_end),

    // T10, E0  000_ooo_000_o
    0b000_000_0 :  (mov_rr,    .me_end),
    0b000_001_0 :  (cmp_rr,    .me_end),
    0b000_010_0 :  (zext_rr,   .me_end),
    0b000_011_0 :  (sext_rr,   .me_end),
    0b000_100_0 :  (bswap_rr,  .me_end),
    0b000_101_0 :  (sextw_rr,  .me_end),
    0b000_110_0 :  (nop,       .me_end),
    0b000_111_0 :  (movw_pr,   .me_movw_pr1),

    0b000_000_1 :  (lsr_rr,    .me_end),
    0b000_001_1 :  (lsl_rr,    .me_end),
    0b000_010_1 :  (asr_rr,    .me_end),
    0b000_011_1 :  (nop,       .me_end),
    0b000_100_1 :  (nop,       .me_end),
    0b000_101_1 :  (neg_rr,    .me_end),
    0b000_110_1 :  (not_rr,    .me_end),
    0b000_111_1 :  (nop,       .me_end),

    // T10, E1 000_ooo_001_o
//    0b001_000_0 :  (add_rlr,   .me_wait),
//    0b001_001_0 :  (movw_qr,   .me_load_w),
//    0b001_010_0 :  (movzb_qr,  .me_load_zb),
//    0b001_011_0 :  (movsb_qr,  .me_load_sb),
//    0b001_100_0 :  (movw_rq,   .me_store_w),
//    0b001_101_0 :  (movb_rq,   .me_store_b),
//    0b001_110_0 :  (nop,       .me_end),
//    0b001_111_0 :  (nop,       .me_end),
//
//    0b001_000_1 :  (nop,       .me_end),
//    0b001_001_1 :  (nop,       .me_end),
//    0b001_010_1 :  (nop,       .me_end),
//    0b001_011_1 :  (nop,       .me_end),
//    0b001_100_1 :  (nop,       .me_end),
//    0b001_101_1 :  (nop,       .me_end),
//    0b001_110_1 :  (nop,       .me_end),
//    0b001_111_1 :  (nop,       .me_end),
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
    //imml = prg.value
    
    // Pre-decode the instruction
    var oh:UInt16 = 0
    var ol:UInt16 = 0
    
    let a0 = !ir[15] && !ir[14]
    let a1 = !ir[15] &&  ir[14]
    let a2 =  ir[15] && !ir[14]
    let a3 =  ir[15] &&  ir[14]
    
    let b0  =  a0 && !ir[13]
    let b1  =  a0 &&  ir[13]
    let b6  =  a3 && !ir[13]
    let b7  =  a3 &&  ir[13]
    
    let e0  =  b0 && !ir[9] && !ir[8] && !ir[7]
    let e1  =  b0 && !ir[9] && !ir[8] &&  ir[7]
    let e2  =  b0 && !ir[9] &&  ir[8] && !ir[7]
    let e3  =  b0 && !ir[9] &&  ir[8] &&  ir[7] && !ir[6]
    let e3a =  b7
    let e4  =  b1
    let e5  =  a1
    let e5a =  a2
    let e6  =  b0 && !ir[9] &&  ir[8] &&  ir[7] &&  ir[6]
    let e6a =  b0 &&  ir[9]
    let e6b =  b6
    
    if  e0                { oh = 0 }
    if  e1                { oh = 1 }
    if  e2                { oh = 2 }
    if  e3 || e3a         { oh = 3 }
    if  e4                { oh = 4 }
    if  e5 || e5a         { oh = 5 }
    if  e6 || e6a || e6b  { oh = 6 }
  
    if  e0 || e1 || e2    { ol = (ir[12,10]<<1) | ir[6,6] }
    if  e3                { ol = ir[12,10] }
    if  e3a               { ol = (1<<3) | ir[12,12] }
    if  e4                { ol = ir[12,9] }
    if  e5                { ol = ir[13,12] }
    if  e5a               { ol = (1<<3) | ir[13,11] }
    if  e6                { ol = 0 }
    if  e6a               { ol = 1 }
    if  e6b               { ol = 2 }
    
    // Get the instruction opcode
    let op =  br_inhibit ? 0b111_0000 :
              control.1 != .me_end ? mir : (oh<<4) | ol
    // Log
    if out.logEnabled { logDecode() }
  
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


