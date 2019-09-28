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
// Extension utilities
extension UInt16
{
  var i16:Int16    { return Int16(truncatingIfNeeded:self) }
  var lo:UInt8     { return UInt8(self & 0xff) }
  var hi:UInt8     { return UInt8(self >> 8) }
  var i:Int        { return Int(self) }
  var b:Bool       { return (self != 0) }
  var s:Bool       { return (self & 0x8000) != 0 }
  
  subscript( end:UInt16, beg:UInt16 ) -> UInt16 {
    get { return (self << (15-end)) >> (15-end+beg) } }
  
  subscript( bit:UInt16 ) -> Bool {
    get { return (self & (1<<bit)) != 0 }
    set(v) { self = ( self & ~(1<<bit)) | (v.u16<<bit) } }

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

//-------------------------------------------------------------------------------------------
class Registers : CustomDebugStringConvertible
{
  var regs = [UInt16](repeating:0, count:8)
  var sp = UInt16(0)
  subscript(r:UInt16) -> UInt16 { get { return regs[r.i] } set(v) { regs[r.i] = v } }
  //var sp:UInt16 { get { return regs[7] } set(v) { regs[7] = v } }
  
  var debugDescription: String
  {
    var str = String()
    for i in 0..<8
    {
      str += String(format:"\tr%d=%d", i, regs[i].i16)
      str += ", "
    }
  
    str += String(format:"sp=%d", sp)
    
    str += "\n\t\t\t\t\t\t\t\t\t"
    for i in stride(from:0, to:8, by:2)
    {
      if ( i != 0 ) { str += ", " }
      str += String(format:"\tr%d:r%d=%d", i, i+1, Int(regs[i]) | Int(regs[i+1])<<16 )
    }
    
    return str
  }
  
}

//-------------------------------------------------------------------------------------------
class PrefixRegister
{
  private var _value:UInt16 = 0
  private var _enable = false
  var value:UInt16
  {
    get { let v = _enable ? _value : 0 ; _enable = false ; return v }
    set(v) { _value = v ; _enable = true }
  }
}

//-------------------------------------------------------------------------------------------
class Status
{
//  var az:Bool = false
//  var ac:Bool = false
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
  
  // Adder, returns result and flags
  func adder( _ a:UInt16, _ b:UInt16, c:Bool, z:Bool=true) -> (res:UInt16, st:Status)
  {
    let st = Status()
    let res32 = UInt32(a) + UInt32(b) + UInt32(c.u16)
    let res = UInt16(truncatingIfNeeded:res32)
    st.z = z && (res == 0)
    st.c = res32 > 0xffff
    st.s = res.s
    st.v = (!a.s && !b.s && res.s) || (a.s && b.s && !res.s )
    return ( res, st )
  }
  
  // Set the status register based on passed in flags
  func seta( _ st:Status /*, ar:Bool=true*/ )
  {
    sr.z = st.z
    sr.c = st.c
    sr.s = st.s
    sr.v = st.v
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
  
  func cmp   ( _ a:UInt16, _ b:UInt16 ) { let res = adder(a,~b, c:true) ; seta(res.st) }
  func cmpc  ( _ a:UInt16, _ b:UInt16 ) { let res = adder(a,~b, c:sr.c, z:sr.z) ; seta(res.st) }
  
  func sub   ( _ a:UInt16, _ b:UInt16 ) -> UInt16 { let res = adder(a,~b, c:true); seta(res.st) ; return res.res }
  func subc  ( _ a:UInt16, _ b:UInt16 ) -> UInt16 { let res = adder(a,~b, c:sr.c, z:sr.z); seta(res.st) ; return res.res }
  
  func add   ( _ a:UInt16, _ b:UInt16 ) -> UInt16 { let res = adder(a,b, c:false); seta(res.st) ; return res.res }
  func addc  ( _ a:UInt16, _ b:UInt16 ) -> UInt16 { let res = adder(a,b, c:sr.c, z:sr.z); seta(res.st) ; return res.res }
  
  func adda  ( _ a:UInt16, _ b:UInt16 ) -> UInt16 { let res = adder(a,b, c:false); return res.res }
  func suba  ( _ a:UInt16, _ b:UInt16 ) -> UInt16 { let res = adder(a,~b, c:true); return res.res }
  
  func or    ( _ a:UInt16, _ b:UInt16 ) -> UInt16 { let res = a | b ; setl(res) ; return res }
  func and   ( _ a:UInt16, _ b:UInt16 ) -> UInt16 { let res = a & b ; setl(res) ; return res }
  func xor   ( _ a:UInt16, _ b:UInt16 ) -> UInt16 { let res = a ^ b ; setl(res) ; return res }
  
  func lsr   ( _ a:UInt16 ) -> UInt16 { let res = a >> 1 ; setl(res); sr.c = a[0]; return res }
  func lsrc  ( _ a:UInt16 ) -> UInt16 { var res = a >> 1 ; res[15] = sr.c; setl(res); sr.c = a[0]; return res }
  func asr   ( _ a:UInt16 ) -> UInt16 { var res = a >> 1 ; res[15] = a[15]; setl(res); sr.c = a[0]; return res }
  func neg   ( _ a:UInt16 ) -> UInt16 { let res = sub( 0, a ) ; return res }
  func not   ( _ a:UInt16 ) -> UInt16 { let res = ~a ; setl(res) ; return res }
  func inca2 ( _ a:UInt16 ) -> UInt16 { let res = adda( a, 2 ) ; return res }
  func deca2 ( _ a:UInt16 ) -> UInt16 { let res = suba( a, 2 ) ; return res }
  func zext  ( _ a:UInt16 ) -> UInt16 { let res = a.zext ; return res }
  func sext  ( _ a:UInt16 ) -> UInt16 { let res = a.sext ; return res }
  func bswap ( _ a:UInt16 ) -> UInt16 { let res = UInt16(lo:a.hi, hi:a.lo) ; return res }
  func sextw ( _ a:UInt16 ) -> UInt16 { let res = (a.i16>>15).u16 ; return res }
  
}


