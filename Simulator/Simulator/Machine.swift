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
  let pfr = PrefixRegister()
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
  var br_taken = false
  //var pc_inhibit = false
  var mc_halt = false
  //var mir_enable = false
	
  // Statistics
  var instCount:Int = 0
  var cycleCount:Int = 0
  
  // Instruction Definitions
  

  
  // Type I1
  
  func mov_kr()    { reg[rd] = imm }
  func add_kr()    { reg[rd] = alu.add( reg[rd], imm ) }
  func sub_kr()    { reg[rd] = alu.sub( reg[rd], imm ) }
  
  func movw_ar()   { mem.mar = imm<<1 }
  func movsb_ar()  { mem.mar = imm }
  func movw_ra()   { (mem.mar, mem.mdr) = (imm<<1, reg[rd]) }
  func movb_ra()   { (mem.mar, mem.mdr) = (imm, reg[rd]) }
  
  func lea_qr()    { reg[rd] = alu.adda( reg.sp, imm ) }
  func movw_qr()   { mem.mar = alu.adda( imm<<1, reg.sp ) }
  func movsb_qr()  { mem.mar = alu.adda( imm, reg.sp ) }
  func movw_rq()   { (mem.mar, mem.mdr) = (alu.adda( imm<<1, reg.sp ), reg[rd]) }
  func movb_rq()   { (mem.mar, mem.mdr) = (alu.adda( imm, reg.sp ), reg[rd]) }
  
  // Type I2
  
  func lea_mr()    { reg[rd] = alu.adda( reg[rs], imm ) }
  func movw_mr()   { mem.mar = alu.adda( reg[rs], imm<<1 ) }
  //func movzb_mr()  { pc_inhibit=true ; mem.mar = alu.adda( reg[rs], imm ) }
  func movsb_mr()  { mem.mar = alu.adda( reg[rs], imm ) }
  func movw_rm()   { (mem.mar, mem.mdr) = (alu.adda( reg[rs], imm<<1 ), reg[rd]) }
  func movb_rm()   { (mem.mar, mem.mdr) = (alu.adda( reg[rs], imm ), reg[rd]) }
  
  
  func and_kr()    { reg[rd] = alu.and( reg[rs], imm ) }
  func cmp_crk()   { alu.cmp( cc, reg[rs], imm ) }
  func cmpc_crk()  { alu.cmpc( cc, reg[rs], imm ) }
  
  // Type P
  
  func _pfix()     { /*pfr.value = imm*/ }
  func call_k()    { (reg.sp, mem.mar) = (alu.deca2( reg.sp ), alu.deca2( reg.sp )) ; mem.mdr = prg.pc }
  
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
  func movw_nr()   { mem.mar = alu.adda( reg[rs], reg[rn]<<1 ) } //
  func movzb_nr()  { mem.mar = alu.adda( reg[rs], reg[rn] ) }
  func movsb_nr()  { mem.mar = alu.adda( reg[rs], reg[rn] ) }
  func movw_rn()   { (mem.mar, mem.mdr) = (alu.adda( reg[rs], reg[rn]<<1 ), reg[rd]) } //
  func movb_rn()   { (mem.mar, mem.mdr) = (alu.adda( reg[rs], reg[rn] ), reg[rd]) }
  
  func sel_crrr()  { reg[rd] = alu.sr.t ? reg[rs] : reg[rn] }

  // Type J
  
  func br_nt()     { if !alu.sr.t { prg.pc = alu.adda( prg.pc, imm) ; br_taken=true } }
  func br_t()      { if alu.sr.t { prg.pc = alu.adda( prg.pc, imm) ; br_taken=true } }
  func jmp_k()     { prg.pc = alu.adda( prg.pc, imm ) }
  func add_kq()    { reg.sp = alu.adda( reg.sp, imm ) }
  
  // Type R2
  
  func mov_rr()    { reg[rd] = reg[rs] }
  func mov_rq()    { reg.sp = reg[rs] }
  func zext_rr()   { reg[rd] = alu.zext( reg[rs] ) }
  func sext_rr()   { reg[rd] = alu.sext( reg[rs] ) }
  func lsrb_rr()   { reg[rd] = alu.lsrb( reg[rs] ) }
  func asrb_rr()   { reg[rd] = alu.asrb( reg[rs] ) }
  func lslb_rr()   { reg[rd] = alu.lslb( reg[rs] ) }
  func sextw_rr()  { reg[rd] = alu.sextw( reg[rs] ) }
  
  func lsr_rr()    { reg[rd] = alu.lsr( reg[rs] ) }
  func lsrc_rr()   { reg[rd] = alu.lsrc( reg[rs] ) }
  func asr_rr()    { reg[rd] = alu.asr( reg[rs] ) }
  
  func movw_pr()   { prg.pmar = reg[rs] }
  func movw_pr_1() { prg.parsel = true ; reg[rd] = prg.value }
  
  func sel_0rr()   { reg[rd] = alu.sr.t ? 0 : reg[rs] }
  func sel_r0r()   { reg[rd] = alu.sr.t ? reg[rs] : 0 }
  
  func neg_rr()    { reg[rd] = alu.neg( reg[rs] ) }
  func not_rr()    { reg[rd] = alu.not( reg[rs] ) }
  
  func jmp_r()     { prg.pc = reg[rs] }
  func call_r()    { (reg.sp, mem.mar) = (alu.deca2( reg.sp ), alu.deca2( reg.sp )) ; mem.mdr = prg.pc }
  
  func set_nt()    { reg[rd] = alu.sr.t ? 0 : 1 }
  func set_t()     { reg[rd] = alu.sr.t ? 1 : 0 }
  
  
  func mov_sr()    { }
  func mov_rs()    { }
  
  func ret()       { (reg.sp, mem.mar) = (alu.inca2( reg.sp ), reg.sp) }
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
  func call_k1()   { mem.writew() ; prg.pc = imm }
  func call_r1()   { mem.writew() ; prg.pc = reg[rd] }
  func ret1()      { prg.pc = mem.value }
 
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
    MCExt.me_load_w.rawValue    : (load_w,    .me_end),
    MCExt.me_load_zb.rawValue   : (load_zb,   .me_end),
    MCExt.me_load_sb.rawValue   : (load_sb,   .me_end),
    MCExt.me_store_w.rawValue   : (store_w,   .me_end),
    MCExt.me_store_b.rawValue   : (store_b,   .me_end),
    MCExt.me_call_k1.rawValue   : (call_k1,   .me_wait),
    MCExt.me_call_r1.rawValue   : (call_r1,   .me_wait),
    MCExt.me_ret1.rawValue      : (ret1,      .me_wait),
    MCExt.me_movw_pr1.rawValue  : (movw_pr_1, .me_wait),
    
    // I1, I2, P
    0b10_01_000  :  (movw_ar,   .me_load_w),
    0b10_01_001  :  (movsb_ar,  .me_load_sb),
    0b10_01_010  :  (movw_ra,   .me_store_w),
    0b10_01_011  :  (movb_ra,   .me_store_b),
    0b10_01_100  :  (mov_kr,    .me_end),
    0b10_01_101  :  (sub_kr,    .me_end),
    0b10_01_110  :  (add_kr,    .me_end),
    0b10_01_111  :  (lea_qr,    .me_end),
    
    0b10_10_000  :  (movw_qr,   .me_load_w),
    0b10_10_001  :  (movsb_qr,  .me_load_sb),
    0b10_10_010  :  (movw_rq,   .me_store_w),
    0b10_10_011  :  (movb_rq,   .me_store_b),
    0b10_10_100  :  (cmp_crk,   .me_end),
    0b10_10_101  :  (cmpc_crk,  .me_end),
    0b10_10_110  :  (and_kr,    .me_end),
    0b10_10_111  :  (lea_mr,    .me_end),
    
    0b10_11_000  :  (movw_mr,   .me_load_w),
    0b10_11_001  :  (movsb_mr,  .me_load_sb),
    0b10_11_010  :  (movw_rm,   .me_store_w),
    0b10_11_011  :  (movb_rm,   .me_store_b),
    0b10_11_100  :  (nop,       .me_end),
    0b10_11_101  :  (nop,       .me_end),
    0b10_11_110  :  (call_k,    .me_call_k1),
    0b10_11_111  :  (_pfix,     .me_end),
    
    // R3, J
    0b01_01_000  :  (cmp_crr,   .me_end),
    0b01_01_001  :  (cmpc_crr,  .me_end),
    0b01_01_010  :  (subc_rrr,  .me_end),
    0b01_01_011  :  (sub_rrr,   .me_end),
    0b01_01_100  :  (and_rrr,   .me_end),
    0b01_01_101  :  (or_rrr,    .me_end),
    0b01_01_110  :  (sel_crrr,  .me_end),
    0b01_01_111  :  (nop,       .me_end),
    
    0b01_10_000  :  (xor_rrr,   .me_end),
    0b01_10_001  :  (addc_rrr,  .me_end),
    0b01_10_010  :  (add_rrr,   .me_end),
    0b01_10_011  :  (movw_nr,   .me_load_w),
    0b01_10_100  :  (movzb_nr,  .me_load_zb),
    0b01_10_101  :  (movsb_nr,  .me_load_sb),
    0b01_10_110  :  (movw_rn,   .me_store_w),
    0b01_10_111  :  (movb_rn,   .me_store_b),
    
    0b01_11_000  :  (nop,       .me_end),
    0b01_11_001  :  (nop,       .me_end),
    0b01_11_010  :  (nop,       .me_end),
    0b01_11_011  :  (nop,       .me_end),
    0b01_11_100  :  (br_nt,     .me_end),
    0b01_11_101  :  (br_t,      .me_end),
    0b01_11_110  :  (add_kq,    .me_end),
    0b01_11_111  :  (jmp_k,     .me_wait),
    
    // R2
    0b00_00_000  :  (mov_rr,    .me_end),
    0b00_00_001  :  (mov_rq,    .me_end),
    0b00_00_010  :  (zext_rr,   .me_end),
    0b00_00_011  :  (sext_rr,   .me_end),
    0b00_00_100  :  (lsrb_rr,   .me_end),
    0b00_00_101  :  (asrb_rr,   .me_end),
    0b00_00_110  :  (lslb_rr,   .me_end),
    0b00_00_111  :  (sextw_rr,  .me_end),
    
    0b00_01_000  :  (lsr_rr,    .me_end),
    0b00_01_001  :  (lsrc_rr,   .me_end),
    0b00_01_010  :  (asr_rr,    .me_end),
    0b00_01_011  :  (movw_pr,   .me_movw_pr1),
    0b00_01_100  :  (sel_0rr,   .me_end),
    0b00_01_101  :  (sel_r0r,   .me_end),
    0b00_01_110  :  (neg_rr,    .me_end),
    0b00_01_111  :  (not_rr,    .me_end),
    
    0b00_10_000  :  (jmp_r,     .me_wait),
    0b00_10_001  :  (call_r,    .me_call_r1),
    0b00_10_010  :  (nop,       .me_end),
    0b00_10_011  :  (nop,       .me_end),
    0b00_10_100  :  (mov_sr,    .me_end),
    0b00_10_101  :  (mov_rs,    .me_end),
    0b00_10_110  :  (set_nt,    .me_end),
    0b00_10_111  :  (set_t,     .me_end),
    
    0b00_11_000  :  (ret,       .me_ret1),
    0b00_11_001  :  (reti,      .me_wait), // revisar
    0b00_11_010  :  (dint,      .me_end),
    0b00_11_011  :  (eint,      .me_end),
    0b00_11_100  :  (halt,      .me_end),
    0b00_11_101  :  (nop,       .me_end),
    0b00_11_110  :  (nop,       .me_end),
    0b00_11_111  :  (nop,       .me_end),
  ]
  
  //-------------------------------------------------------------------------------------------
  func loadProgram( source:Data )
  {
    prg.storeProgram(atAddress:0, withData:source)
  }
  
  //-------------------------------------------------------------------------------------------
  func reset()
  {
    //br_taken = false
    ir = 0
    mir = MCExt.me_end.rawValue
    prg.pc = 0
    //reg.sp = mem.size  // FIX ME: Should this be automatically done by the machine setup code ??
  }
  
  //-------------------------------------------------------------------------------------------
  func decode()
  {
    // Decode register and condition code operands
    
    rs = ir[2,0]
    rd = ir[5,3]
    rn = ir[8,6]
    cc = rd

    // Decode embeeded immediate fields
    
    let ir15_13 = ir[15,13]
    var im:UInt16
    
    // P
    if ir15_13 == 0b111
    {
      im = ir[10,7] | (ir[6,0]<<4)  // Type P, zero extended 11 bit
    }

    // I2
    else if ir15_13 >= 0b101 && ir15_13 <= 0b110
    {
      im = ir[10,7] | (ir[6,6]<<4)        // Type I2, zero extended 5 bit
      if ir[15,12] == 0b1010 { im = im.sext(4,0) }  // Type I2, sign extended 5 bit
    }

    // I1
    else if ir15_13 >= 0b010 && ir15_13 <= 0b100
    {
      im =  ir[10,7] | (ir[2,0]<<4) | (ir[6,6]<<7)  // Type I1, zero extended 8 bit
      if ir[15,11] == 0b01100 { im = im.sext(7,0) } // Type I1, sign extended 8 bit
    }
    
    // J
    else
    {
      im = ir[10,7] | (ir[3,0]<<4) | (ir[6,6]<<8)
      im = im.sext(8,0)   // Type J, sign extended 9 bit
    }

    // Prefix
    imm = pfr.enable ? im[4,0] | (pfr.value<<5) : im
    
    // The pfix register is updated on every cycle
    pfr.value = im[10,0]
    pfr.enable = (ir[15,11] == 0b11111) // valid for the next cycle

    // Instruction decode

    let ir15_12 = ir[15,12]
    
    var oh:UInt16 = 0     // xx
    var ol:UInt16 = 0     // yyyyy
    
    if ir15_12 == 0b0000 { oh = 0 ; ol = ir[11,7] }    // Type R2
    else if ir15_12 >= 0b0001 && ir15_12 <= 0b0010 { oh = 1 ; ol = ir[13,9] }  // Type R3
    else if ir15_12 == 0b0011 { oh = 1 ; ol = ir[5,4] | (ir[13,11]<<2) }  // Type J
    else { oh = 2 ; ol = ir[15,11] } // Types P, I1, I2
    
    // Get the instruction opcode
    let op = br_taken ? MCExt.me_wait.rawValue /*0b11_00000*/ :
        mir != MCExt.me_end.rawValue ? mir : (oh<<5) | ol

    // Get the instruction opcode
//    let op =  br_taken ? 0b11_00000 :
//          control.1 != .me_end ? mir : (oh<<5) | ol

    // Log
    if out.logEnabled { logDecode() }
    
    // Statistics
//    if !(pc_inhibit || br_taken) { instCount += 1 }
//    cycleCount += 1

    if (prg.pc == 8 )
    {
      let stop = 1
    }

    // Decode the instruction (get the instruction control bits)
    if let f = instrP0[op] { control = f }  // Decoder Pattern
    else { out.exitWithError( "Unrecognized instruction opcode" ) }

    // These can only be set to true by the exec code, so we clear it first
    //pfr.enable = false
    prg.parsel = false
    br_taken = false
  }


  //-------------------------------------------------------------------------------------------
  // This represents the execution of control signals
  func process() -> Bool
  {
    // Prefetch next instruction, either update mir or ir
    if control.1 != .me_end { mir = control.1.rawValue }
    else { ir = prg.value ; mir = MCExt.me_end.rawValue }
    
    // Execute control lines
    control.0(self)()    // process the instruction
    
    // Only increment PC if we have to
    if ( !br_taken && control.1 == .me_end )
    {
      prg.pc = prg.pc &+ 1
      instCount += 1
    }
    cycleCount += 1
    
    // Only increment PC if we have to
   // if !(pc_inhibit || br_inhibit)  { prg.pc = prg.pc &+ 1 }
    
    // Log
    if out.logEnabled { logExecute() }
    
    return mc_halt
  }
 
  //-------------------------------------------------------------------------------------------
  // run
  func run() -> Bool
  {
    var done = false
		let start = DispatchTime.now() // <<<<<<<<<< Start time
		
    while !done  // execute until 'halt' instruction
    {
//      let pep = out.getKeyPress();
//      out.logln( "keyPress : \(pep)" )
      
      decode()
      done = process()
    }
		
		// Log
		
    let end = DispatchTime.now()   // <<<<<<<<<<   end time
    let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
    let timeInterval = Double(nanoTime) / 1_000_000_000 // Technically could overflow for long running test
    logStatistics( time:timeInterval )
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
    
    
    
    let addr = (br_taken || control.1 != .me_end) ? "-----" : String(format:"%05d", prg.pc &- 1)
    //let addr = (pc_inhibit || br_taken) ? "-----" : String(format:"%05d", prg.pc &- 1)
    let prStr = String(format:"%@ : %@%@ %@%@", addr, ir_prefix,str_ir, mir_prefix,str_mir )
    out.log( prStr )
  }

  func logExecute()
  {
    out.log( " " )
    out.logln( String(reflecting:reg) )
  }
	
  func logStatistics( time:Double )
  {
		out.print( String( format:"Executed instruction count: %i\n", instCount) )
		out.print( String( format:"Total cycle count: %i\n", cycleCount) )
		out.print( String( format:"Elapsed simulation time: %g seconds\n", time) )
		out.print( String( format:"Calculated execution time at 1MHz : %g seconds\n", Double(cycleCount)/1e6) )
		out.print( String( format:"Calculated execution time at 8MHz : %g seconds\n", Double(cycleCount)/8e6) )
		out.print( String( format:"Calculated execution time at 16MHz: %g seconds\n", Double(cycleCount)/16e6) )
  }
}


