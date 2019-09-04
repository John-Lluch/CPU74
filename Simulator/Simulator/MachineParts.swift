//
//  MachineParts.swift
//  c74-sim
//
//  Created by Joan on 17/08/19.
//  Copyright © 2019 Joan. All rights reserved.
//

import Foundation

private let ProgramMemorySize = 0x10000*2     // 128 kb program memory
private let DataMemorySize    = 0x10000       // 64 kb data memory

//-------------------------------------------------------------------------------------------
extension UInt16
{
  var i16:Int16    { return Int16(truncatingIfNeeded:self) }
  var lo:UInt8     { return UInt8(self & 0xff) }
  var hi:UInt8     { return UInt8(self >> 8) }
  var i:Int        { return Int(self) }
  var b:Bool       { return (self != 0) }
  var s:Bool       { return (self & 0x8000) != 0 }
  subscript( end:UInt16, beg:UInt16 ) -> UInt16 { get { return (self << (15-end)) >> (15-end+beg) } }
  subscript( bit:UInt16 ) -> Bool { get { return (self & (1<<bit)) != 0 } }
  func sext( _ end:UInt16, _ beg:UInt16 ) -> UInt16 { return ((self.i16 << (15-end)) >> (15-end+beg)).u16 }
  var zext:UInt16  { return self[7,0] }
  var sext:UInt16  { return sext(7,0) }
  init(lo:UInt8, hi:UInt8) { self = UInt16(hi)<<8 | UInt16(lo) }
}

extension Int16 {
  var u16:UInt16  { return UInt16(truncatingIfNeeded:self) }
}

extension Int {
  var u16:UInt16 { return UInt16(truncatingIfNeeded:self) }
}

extension Bool {
  var u16:UInt16  { return UInt16(self ? 1 : 0 ) }
}

extension UInt8 {
  var u16:UInt16  { return UInt16(truncatingIfNeeded:self) }
}

//-------------------------------------------------------------------------------------------
class ProgramMemory
{
  // Program counter, memory output
  var pc:UInt16 = 0        // program counter register
  var par:UInt16 = 0       // programm address register
  var parsel:Bool = false  // address register select

  // Memory value at current address
  var value:UInt16 { return self[parsel ? par:pc] }

  // Memory size
  var size:UInt16 { return (memory.count/2).u16 }   // size in words

  // Memory, private
  private var memory = Data(count:ProgramMemorySize)
  private subscript (address: UInt16) -> UInt16 {
    get { return UInt16(lo:memory[address.i*2], hi:memory[address.i*2+1]) }
  }

  // Store program utility
  func storeProgram(atAddress address:UInt16, withData data:Data )
  {
    if ( data.count > address.i*2 + memory.count) { out.exitWithError( "Program exceeds program memory size" ) }
    if ( data.count % 2 != 0 ) { out.exitWithError( "Program must have an even number of bytes" ) }
    memory.replaceSubrange( address.i*2..<data.count , with:data )
  }
}

//-------------------------------------------------------------------------------------------
class DataMemory
{
  // Memory address register and data register (write only)
  var mar:UInt16 = 0
  var mdr:UInt16 = 0
  
  // Memory value at current address // (get/set)
  var value:UInt16 {return self[mar]}
//  {
//    get {return self[mar]}
//    //set(v) {self[mar] = v}
//  }
  
  // Memory write
  func writew() { self[mar] = mdr }
  func writeb() { if (mar & 1) != 0 { memoryHi[mar.i/2] = mdr.lo } else { memoryLo[mar.i/2] = mdr.lo } }

  // Memory size
  var size:UInt16 { return (memoryLo.count + memoryHi.count).u16 }   // size in bytes
  
  // Memory, private
  private var memoryLo = Data(count:DataMemorySize/2)
  private var memoryHi = Data(count:DataMemorySize/2)
  private subscript (address:UInt16) -> UInt16
  {
    get
    {
      if ( address % 2 != 0 ) { out.exitWithError( "Unaligned word access to memory" ) }
      return UInt16(lo:memoryLo[address.i/2], hi:memoryHi[address.i/2])
    }
    set (v)
    {
      if ( address % 2 != 0 ) { out.exitWithError( "Unaligned word access to memory" ) }
      memoryLo[address.i/2]  = v.lo
      memoryHi[address.i/2] = v.hi
    }
  }
  
  // Sign extended byte at current address (get)
  var sb:UInt16 {
    get { return ( (mar & 1) != 0 ? memoryHi[mar.i/2] : memoryLo[mar.i/2] ).u16.sext }
  }
  
  // Byte at current address (get/set)
  var zb:UInt16 {
    get { return ( (mar & 1) != 0 ? memoryHi[mar.i/2] : memoryLo[mar.i/2] ).u16 }
    //set(v) { if (mar & 1) != 0 { memoryHi[mar.i/2] = v.lo } else { memoryLo[mar.i/2] = v.lo } }
  }
}

////-------------------------------------------------------------------------------------------
//class DataMemory
//{
//  // Memory address register
//  var mar:UInt16 = 0
//
//  // Memory value at current address (get/set)
//  var value:UInt16 { get {return self[mar]} set(v) {self[mar] = v} }
//
//  // Memory size
//  var size:UInt16 { return (memory.count).u16 }   // size in bytes
//
//  // Memory, private
//  private var memory = Data(count:DataMemorySize)
//  private subscript (address:UInt16) -> UInt16
//  {
//    get {
//      if ( address % 2 != 0 ) { out.exitWithError( "Unaligned word access to memory" ) }
//      return UInt16(lo:memory[address.i], hi:memory[address.i+1])
//    }
//    set (v) {
//      if ( address % 2 != 0 ) { out.exitWithError( "Unaligned word access to memory" ) }
//      memory[address.i]   = v.lo
//      memory[address.i+1] = v.hi
//    }
//  }
//
//  var sb:UInt16
//  {
//    get
//    {
////      let v = self[mar | ~1]
////      return ((mar & 1) != 0) ? v.sext(15,8) : v.sext(7,0)
//      return self[mar].sext
//    }
//  }
//
//  var zb:UInt16
//  {
//    get
//    {
//      return self[mar].zext
//    }
//    set(v)
//    {
//      self[mar] = v[7,0]
//    }
//  }
//
//
////  // Byte access functions
////  func sb( _ address:UInt16 ) -> UInt16 {
////    return UInt16(memory[address.i]).sext
////  }
////
////  func zb( _ address:UInt16 ) -> UInt16 {
////    return UInt16(memory[address.i]).zext
////  }
////
////  func b( _ address:UInt16, _ value:UInt16 ) {
////    memory[address.i] = value.lo
////  }
//}

//-------------------------------------------------------------------------------------------
class Registers : CustomDebugStringConvertible
{
  var regs = [UInt16](repeating:0, count:8)
  subscript(r:UInt16) -> UInt16 { get { return regs[r.i] } set(v) { regs[r.i] = v } }
  var sp:UInt16 { get { return regs[7] } set(v) { regs[7] = v } }
  
  var debugDescription: String
  {
    var str = String()
    for i in 0..<7
    {
      str += String(format:"r%d=%d", i, regs[i].i16)
      str += ", "
    }
  
    str += String(format:"sp=%d", regs[7])
    
//    str += "\n"
//    for i in stride(from:0, to:6, by:2)
//    {
//      if ( i != 0 ) { str += ", " }
//      str += String(format:"r%d:r%d=%d", i, i+1, Int(regs[i])<<16 | Int(regs[i+1]) )
//    }
    
    return str
  }
  
}

//-------------------------------------------------------------------------------------------
class Status
{
  var az:Bool = false
  var ac:Bool = false
  var z:Bool = false
  var c:Bool = false
  var s:Bool = false
  var v:Bool = false
}

//-------------------------------------------------------------------------------------------

enum ALUOp2 : UInt16 { case adda, add, addc, suba, sub, subc, or, and, xor, cmp }
enum ALUOp1 : UInt16 { case lsr, lsl, asr, neg, not, inca, deca, zext, sext, bswap, sextw }

class ALU
{
  var sr = Status()
  
  // Set arithmetic flags based on operands and result
  func seta( _ a:UInt16, _ b:UInt16, _ res:UInt16, ar:Bool=true )
  {
    sr.z = res == 0
    sr.c = (res < a) || (res < b)
    sr.s = res.s
    sr.v = (!a.s && !b.s && res.s) || (a.s && b.s && !res.s )
    if ar { sr.az = sr.z ; sr.ac = sr.c }
  }
  
  // Set logical operation flags based on result
  private func setl( _ res:UInt16 )
  {
    sr.z = res == 0
    sr.c = false
    sr.s = res.s
    sr.v = false
  }
  
  // Returns whether a given condition code matches the status register flags
  func hasCC( _ cc:UInt16 ) -> Bool
  {
    enum CC : UInt16 { case eq = 0, ne, uge, ult, ge, lt, ugt, gt }
    switch CC(rawValue:cc)!
    {
      case .eq : return sr.z
      case .ne : return !sr.z
      case .uge: return sr.c
      case .ult: return !sr.c
      case .ge : return sr.s == sr.v
      case .lt : return sr.s != sr.v
      case .ugt: return sr.c && !sr.z
      case .gt : return (sr.s == sr.v) && !sr.z
    }
  }
  
  // Operations
  func cmp   ( _ a:UInt16, _ b:UInt16 ) { let res = a &+ ~b &+ 1 ; seta(a,b,res) }
  
  func adda  ( _ a:UInt16, _ b:UInt16 ) -> UInt16 { let res = a &+ b ; return res }
  func add   ( _ a:UInt16, _ b:UInt16 ) -> UInt16 { let res = a &+ b ; seta(a,b,res) ; return res }
  func addc  ( _ a:UInt16, _ b:UInt16 ) -> UInt16 { let res = a &+ b &+ sr.c.u16 ; seta(a,b,res) ; return res }
  func suba  ( _ a:UInt16, _ b:UInt16 ) -> UInt16 { let res = a &+ ~b &+ 1 ; return res }
  func sub   ( _ a:UInt16, _ b:UInt16 ) -> UInt16 { let res = a &+ ~b &+ 1 ; seta(a,b,res) ; return res }
  func subc  ( _ a:UInt16, _ b:UInt16 ) -> UInt16 { let res = a &+ ~b &+ sr.c.u16 ; seta(a,b,res) ; return res }
  func or    ( _ a:UInt16, _ b:UInt16 ) -> UInt16 { let res = a | b ; setl(res) ; return res }
  func and   ( _ a:UInt16, _ b:UInt16 ) -> UInt16 { let res = a & b ; setl(res) ; return res }
  func xor   ( _ a:UInt16, _ b:UInt16 ) -> UInt16 { let res = a ^ b ; setl(res) ; return res }
  
  func lsr   ( _ a:UInt16 ) -> UInt16 { let res = a >> 1 ; return res }
  func lsl   ( _ a:UInt16 ) -> UInt16 { let res = a << 1 ; return res }
  func asr   ( _ a:UInt16 ) -> UInt16 { let res = (a.i16>>1).u16 ; return res }
  func neg   ( _ a:UInt16 ) -> UInt16 { let res = sub( 0, a ) ; return res }
  func not   ( _ a:UInt16 ) -> UInt16 { let res = ~a ; setl(res) ; return res }
  func inca2 ( _ a:UInt16 ) -> UInt16 { let res = adda( a, 2 ) ; return res }
  func deca2 ( _ a:UInt16 ) -> UInt16 { let res = suba( a, 2 ) ; return res }
  func zext  ( _ a:UInt16 ) -> UInt16 { let res = a.zext ; return res }
  func sext  ( _ a:UInt16 ) -> UInt16 { let res = a.sext ; return res }
  func bswap ( _ a:UInt16 ) -> UInt16 { let res = UInt16(lo:a.hi, hi:a.lo) ; return res }
  func sextw ( _ a:UInt16 ) -> UInt16 { let res = (a.i16>>15).u16 ; return res }

//  func two( _ op:ALUOp2, _ a:UInt16, _ b:UInt16 ) -> UInt16
//  {
//    var res:UInt16
//    switch op
//    {
//      case .adda : res = a &+ b
//      case .add  : res = a &+ b ; seta(a,b,res)
//      case .addc : res = a &+ b &+ sr.c.u16 ; seta(a,b,res)
//      case .suba : res = a &+ ~b &+ 1
//      case .sub  : res = a &+ ~b &+ 1 ; seta(a,b,res)
//      case .subc : res = a &+ ~b &+ sr.c.u16 ; seta(a,b,res)
//      case .cmp  : res = a &+ ~b &+ 1 ; seta(a,b,res,ar:false)
//      case .or   : res = a | b ; setl(res)
//      case .and  : res = a & b ; setl(res)
//      case .xor  : res = a ^ b ; setl(res)
//    }
//    return res
//  }
//
//  func one( _ op:ALUOp1, _ a:UInt16 ) -> UInt16
//  {
//    var res:UInt16
//    switch op
//    {
//      case .lsr  : res = a >> 1
//      case .lsl  : res = a << 1
//      case .asr  : res = (a.i16>>1).u16
//      case .neg  : res = self.two(.sub, 0, a) ; seta(0,a,res)
//      case .not  : res = ~a ; setl(res)
//      case .inca : res = self.two(.adda, a, 1)
//      case .deca : res = self.two(.suba, a, 1)
//      case .zext : res = a.zext
//      case .sext : res = a.sext
//      case .bswap : res = UInt16(lo:a.hi, hi:a.lo)
//      case .sextw : res = (a.i16>>15).u16
//    }
//    return res
//  }
}


