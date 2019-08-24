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
  var imml:UInt16 = 0
  var cc:UInt16 = 0
  
  // Control
  var control:((Machine)->()->(),UInt16) = (wait, 0)
  var br_inhibit = false
  var mc_halt = false
  
  // Instruction Definitions
  
  // Type 1
  func jmp_k()     { prg.pc = alu.adda( prg.pc, imm ) ; br_inhibit=true}
  func call_k()    { reg.sp = alu.deca2( reg.sp ) ; mem[reg.sp] = prg.pc ; prg.pc = alu.adda( prg.pc, imm ) ; br_inhibit=true }
  
  // Type 2
  func br_ck()     { if alu.hasCC(cc) { prg.pc = alu.adda( prg.pc, imm) ; br_inhibit=true} }
  
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
  func ret()      { prg.pc = mem[reg.sp] ; reg.sp = alu.inca2( reg.sp ) ; br_inhibit=true }
  func reti()     { }
  func dint()     { }
  func eint()     { }
  func halt()     { mc_halt = true }
  func call_a()   { reg.sp = alu.deca2( reg.sp ) ; mem[reg.sp] = prg.pc ; prg.pc = imml ; br_inhibit=true }
  
  // Type 9
  func jmp_r()    { prg.pc = reg[rd] ; br_inhibit=true}
  func call_r()   { reg.sp = alu.deca2( reg.sp ) ; mem[reg.sp] = prg.pc; prg.pc = reg[rd] ; br_inhibit=true }
  func push_r()   { reg.sp = alu.deca2( reg.sp ) ; mem[reg.sp] = reg[rd] }
  func pop_r()    { reg[rd] = mem[reg.sp] ; reg.sp = alu.inca2( reg.sp ) }
  func mov_sr()   { }
  func mov_rs()   { }
  func mov_lr()   { reg[rd] = imml }
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
  func wait()     { }
  func micro1()   { }
  func micro2()   { }
  func micro3()   { }
  func micro4()   { }
  func micro5()   { }
  func micro6()   { }
  func micro7()   { }

  // Instruction Encodings

  // Pattern P7
  let instrP0:Dictionary<UInt16, ((Machine)->()->(),UInt16) > =
  [
    // E7 111_oooo
    0b111_0000  : (wait,      0),
    0b111_0001  : (micro1,    0),
    0b111_0010  : (micro2,    0),
    0b111_0011  : (micro3,    0),
    0b111_0100  : (micro4,    0),
    0b111_0101  : (micro5,    0),
    0b111_0110  : (micro6,    0),
    0b111_0111  : (micro7,    0),

    // E6b 110_xxxxxxx
    0b110_0010  : (br_ck,     0),

    // E6a 000_xxx_1_xxx
    0b110_0001  : (sel_crrr,  0),

    // E6 000_xxx_0111
    0b110_0000  : (set_cr,    0),

    // E5a  10_ooo_xxxxx
    0b101_1_000 : (mov_kr,    0),
    0b101_1_001 : (cmp_rk,    0),
    0b101_1_010 : (add_kr,    0),
    0b101_1_011 : (sub_kr,    0),
    0b101_1_100 : (and_kr,    0),
    0b101_1_101 : (or_kr,     0),
    0b101_1_110 : (xor_kr,    0),
    0b101_1_111 : (nop,       0),

    // E5  01_oo_xxxxxx
    0b101_00_00 : (movw_mr,   0),
    0b101_00_01 : (movsb_mr,  0),
    0b101_00_10 : (movw_rm,   0),
    0b101_00_11 : (movb_rm,   0),

    // E4  001_oooo_xxx
    0b100_0000  : (add_rrr,   0),
    0b100_0001  : (addc_rrr,  0),
    0b100_0010  : (sub_rrr,   0),
    0b100_0011  : (subc_rrr,  0),
    0b100_0100  : (or_rrr,    0),
    0b100_0101  : (and_rrr,   0),
    0b100_0110  : (xor_rrr,   0),
    0b100_0111  : (nop,       0),

    0b100_1000  : (nop,       0),
    0b100_1001  : (movw_nr,   0),
    0b100_1010  : (movzb_nr,  0),
    0b100_1011  : (movsb_nr,  0),
    0b100_1100  : (movw_rn,   0),
    0b100_1101  : (movb_rn,   0),
    0b100_1110  : (nop,       0),
    0b100_1111  : (nop,       0),

    // E3a  111_o_xxxxxx
    0b011_100_0 : (jmp_k,     0),
    0b011_100_1 : (call_k,    0),

    // E3   000_ooo_0110
    0b011_0_000 : (ret,       0),
    0b011_0_001 : (reti,      0),
    0b011_0_010 : (dint,      0),
    0b011_0_011 : (eint,      0),
    0b011_0_100 : (halt,      0),
    0b011_0_101 : (nop,       0),
    0b011_0_110 : (nop,       0),
    0b011_0_111 : (call_a,    0),

    // E2  000_ooo_010_o
    0b010_000_0 : (jmp_r,     0),
    0b010_001_0 : (call_r,    0),
    0b010_010_0 : (push_r,    0),
    0b010_011_0 : (pop_r,     0),
    0b010_100_0 : (nop,       0),
    0b010_101_0 : (nop,       0),
    0b010_110_0 : (mov_sr,    0),
    0b010_111_0 : (mov_rs,    0),

    0b010_000_1 : (mov_lr,    0b111_0000),
    0b010_001_1 : (movw_ar,   0b111_0000),
    0b010_010_1 : (movzb_ar,  0b111_0000),
    0b010_011_1 : (movsb_ar,  0b111_0000),
    0b010_100_1 : (movw_ra,   0b111_0000),
    0b010_101_1 : (movb_ra,   0b111_0000),
    0b010_110_1 : (nop,       0),
    0b010_111_1 : (nop,       0),

    // E0  000_ooo_000_o
    0b000_000_0 : (mov_rr,    0),
    0b000_001_0 : (cmp_rr,    0),
    0b000_010_0 : (zext_rr,   0),
    0b000_011_0 : (sext_rr,   0),
    0b000_100_0 : (bswap_rr,  0),
    0b000_101_0 : (sextw_rr,  0),
    0b000_110_0 : (nop,       0),
    0b000_111_0 : (movw_pr,   0),

    0b000_000_1 : (lsr_rr,    0),
    0b000_001_1 : (lsl_rr,    0),
    0b000_010_1 : (asr_rr,    0),
    0b000_011_1 : (nop,       0),
    0b000_100_1 : (nop,       0),
    0b000_101_1 : (neg_rr,    0),
    0b000_110_1 : (not_rr,    0),
    0b000_111_1 : (nop,       0),

    // E1 000_ooo_001_o
    0b001_000_0 : (add_rlr,   0b111_0000),
    0b001_001_0 : (movw_qr,   0b111_0000),
    0b001_010_0 : (movzb_qr,  0b111_0000),
    0b001_011_0 : (movsb_qr,  0b111_0000),
    0b001_100_0 : (movw_rq,   0b111_0000),
    0b001_101_0 : (movb_rq,   0b111_0000),
    0b001_110_0 : (nop,       0),
    0b001_111_0 : (nop,       0),

    0b001_000_1 : (nop,       0),
    0b001_001_1 : (nop,       0),
    0b001_010_1 : (nop,       0),
    0b001_011_1 : (nop,       0),
    0b001_100_1 : (nop,       0),
    0b001_101_1 : (nop,       0),
    0b001_110_1 : (nop,       0),
    0b001_111_1 : (nop,       0),
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
    imml = prg.value
    
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
              mir != 0 ? mir : (oh<<4) | ol
  
    // Decode the instruction (get the instruction control bits)
    if let f = instrP0[op] { control = f }  // Decoder Pattern
    else { out.exitWithError( "Unrecognized instruction opcode" ) }
    
    // Log
    if out.logEnabled { logDecode() }
  }
 
  //-------------------------------------------------------------------------------------------
  // This represents the execution of control signals
  func process() -> Bool
  {
    // Next instruction is always pre-fetched
    ir = prg.value
    mir = control.1
    
    // Execute control lines
    br_inhibit = false   // this can only be set to true, so we clear it first
    control.0(self)()    // process the instruction
    
    // Only increment PC if we have to
    if !br_inhibit  { prg.pc = prg.pc &+ 1 }
    
    // Log
    if out.logEnabled { logExecute() }
    
    return mc_halt
  }
 
  //-------------------------------------------------------------------------------------------
  // run
  func run() -> Bool
  {
    var done = false
    while !done  // execute 50 instructions
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
    var str_ir = String(ir, radix:2) //binary base
    str_ir = String(repeating:"0", count:(16 - str_ir.count)) + str_ir
    
    var str_mir = String(mir, radix:2) //binary base
    str_mir = String(repeating:"0", count:(10 - str_mir.count)) + str_mir
    
    let addr = br_inhibit ? "-----" : String(format:"%05d", prg.pc &- 1)
    let prStr = String(format:"%@ : %@ %@", addr, str_ir, str_mir )
    out.log( prStr )
  }

  func logExecute()
  {
    out.log( " " )
    out.logln( String(reflecting:reg) )
  }
}


