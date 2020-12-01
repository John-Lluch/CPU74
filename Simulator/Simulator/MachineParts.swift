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
  var pmar:UInt16 = 0       // programm address register
  var pmarsel:Bool = false  // address register select

  // Memory value at current address
  var value:UInt16 { return self[pmarsel ? pmar : pc] }

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
enum MEMOp : UInt16 { case word, byte, sbyte }

class DataMemory
{
  // Memory address register and data register (write only)
  private var _mar:UInt16 = 0
  //var mdr:UInt16 = 0
  private var _op:MEMOp = .word;
  
  // Memory value at current address // (get/set)
  //var value:UInt16 {return self[mar]}
  
  
  var mar:(UInt16, MEMOp)
  {
    get { return (_mar, _op) }
    set( v ) { (_mar, _op ) = v }
  }
  
  func write( _ v:UInt16 )
  {
    switch _op
    {
      case .word : self[_mar] = v
      case .byte, .sbyte :
        if (_mar & 1) != 0 { memoryHi[_mar.i/2] = v.lo } else { memoryLo[_mar.i/2] = v.lo }
        if ( _mar == 0xffff ) { fputc(Int32(v.lo), stdout) }
    }
  }
  
  var read:UInt16
  {
    get
    {
      switch _op
      {
        case .word : return self[_mar]
        case .byte : return ( (_mar & 1) != 0 ? memoryHi[_mar.i/2] : memoryLo[_mar.i/2] ).u16
        case .sbyte : return ( (_mar & 1) != 0 ? memoryHi[_mar.i/2] : memoryLo[_mar.i/2] ).u16.sext
      }
    }
  }
  
  // Memory write
//  func writew() { self[mar] = mdr }
//  func writeb()
//  {
//    if (mar & 1) != 0 { memoryHi[mar.i/2] = mdr.lo } else { memoryLo[mar.i/2] = mdr.lo }
//    if ( mar == 0xffff ) { fputc(Int32(mdr.lo), stdout) }
//  }
 
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
  
//  // Sign extended byte at current address (get)
//  var sb:UInt16 {
//    get { return ( (mar & 1) != 0 ? memoryHi[mar.i/2] : memoryLo[mar.i/2] ).u16.sext }
//  }
//
//  // Byte at current address (get/set)
//  var zb:UInt16 {
//    get { return ( (mar & 1) != 0 ? memoryHi[mar.i/2] : memoryLo[mar.i/2] ).u16 }
//    //set(v) { if (mar & 1) != 0 { memoryHi[mar.i/2] = v.lo } else { memoryLo[mar.i/2] = v.lo } }
//  }
}

//-------------------------------------------------------------------------------------------
class Registers : CustomDebugStringConvertible
{
  var regs = [UInt16](repeating:0, count:8)
  var sp = UInt16(0)
  subscript(r:UInt16) -> UInt16 { get { return regs[r.i] } set(v) { regs[r.i] = v } }
  
  var debugDescription: String
  {
    var str = String()
    for i in 0..<8
    {
      str += String(format:"\tr%d=%d", i, regs[i].i16)
      //str += String(format:"\tr%d=%4X", i, regs[i].i16)
      str += ", "
    }
  
    str += String(format:"sp=%d", sp)
    
//    str += "\n\t\t\t\t\t\t\t\t\t"
//    for i in stride(from:0, to:8, by:2)
//    {
//      if ( i != 0 ) { str += ", " }
//      str += String(format:"\tr%d:r%d=%d", i, i+1, Int(regs[i]) | Int(regs[i+1])<<16 )
//    }
		
    return str
  }
  
}

//-------------------------------------------------------------------------------------------
class PrefixRegister
{
  private var _value:UInt16 = 0
  var enable = false
  var value:UInt16
  {
    get { return _value }
    set(v) { _value = v  }
  }
}

//-------------------------------------------------------------------------------------------
class Condition
{
  var z:Bool = false
  var c:Bool = false
  var s:Bool = false
  var v:Bool = false
}

class Status
{
  var z:Bool = false
  var c:Bool = false
  var t:Bool = false
}

enum CC : UInt16 { case eq = 0, ne, uge, ult, ge, lt, ugt, gt }

//-------------------------------------------------------------------------------------------

enum ALUOp2 : UInt16 { case adda, add, addc, suba, sub, subc, or, and, xor, cmp }
enum ALUOp1 : UInt16 { case lsr, lsl, asr, neg, not, inca, deca, zext, sext, bswap, sextw }

class ALU
{
  var sr = Status()
  
  // Adder, returns result and flags
  func adder( _ a:UInt16, _ b:UInt16, c:Bool, z:Bool=true) -> (res:UInt16, ct:Condition)
  {
    let ct = Condition()
    let res32 = UInt32(a) + UInt32(b) + UInt32(c.u16)
    let res = UInt16(truncatingIfNeeded:res32)
    ct.z = z && (res == 0)
    ct.c = res32 > 0xffff
    ct.s = res.s
    ct.v = (!a.s && !b.s && res.s) || (a.s && b.s && !res.s )
    return ( res, ct )
  }
  
  // Set the status register based on passed in flags
//  func seta( _ ct:Status /*, ar:Bool=true*/ )
//  {
//    sr.z = st.z
//    sr.c = st.c
//    sr.s = st.s
//    sr.v = st.v
//  }
  
  // Set logical operation flags
  private func setz( z:Bool )
  {
    sr.z = z
    sr.c = false
    sr.t = z
  }
  
  // Set shift operation flags
  private func setzc( z:Bool, c:Bool )
  {
    sr.z = z
    sr.c = c
    sr.t = c
  }
  
  // Set arithmetic operation flags based on condition
  private func setsr( _ cc:CC, _ ct:Condition )
  {
    sr.z = ct.z
    sr.c = ct.c
    switch cc
    {
      case .eq : sr.t = ct.z
      case .ne : sr.t = !ct.z
      case .uge: sr.t = ct.c   // ATENCIO BUG !!
      case .ult: sr.t = !ct.c  // ATENCIO BUG !!
      case .ge : sr.t = ct.s == ct.v
      case .lt : sr.t = ct.s != ct.v
      case .ugt: sr.t = ct.c && !ct.z
      case .gt : sr.t = (ct.s == ct.v) && !ct.z
    }
  }
  
  func setsr( _ cc:UInt16, _ ct:Condition ) {
    setsr( CC(rawValue:cc)!, ct )
  }
  
  // Operations
  
  func cmp   ( _ cc:UInt16, _ a:UInt16, _ b:UInt16 ) { let res = adder(a,~b, c:true) ; setsr(cc, res.ct) }
  func cmpc  ( _ cc:UInt16, _ a:UInt16, _ b:UInt16 ) { let res = adder(a,~b, c:sr.c, z:sr.z) ; setsr(cc, res.ct) }
  
  func sub   ( _ a:UInt16, _ b:UInt16 ) -> UInt16 { let res = adder(a,~b, c:true); setsr(.eq, res.ct) ; return res.res }
  func subc  ( _ a:UInt16, _ b:UInt16 ) -> UInt16 { let res = adder(a,~b, c:sr.c, z:sr.z); setsr(.eq, res.ct) ; return res.res }
  
  func add   ( _ a:UInt16, _ b:UInt16 ) -> UInt16 { let res = adder(a,b, c:false); setsr(.eq, res.ct) ; return res.res }
  func addc  ( _ a:UInt16, _ b:UInt16 ) -> UInt16 { let res = adder(a,b, c:sr.c, z:sr.z); setsr(.eq, res.ct) ; return res.res }
  
  func adda  ( _ a:UInt16, _ b:UInt16 ) -> UInt16 { let res = adder(a,b, c:false); return res.res }
  func suba  ( _ a:UInt16, _ b:UInt16 ) -> UInt16 { let res = adder(a,~b, c:true); return res.res }
  
  func or    ( _ a:UInt16, _ b:UInt16 ) -> UInt16 { let res = a | b ; setz(z:res==0) ; return res }
  func and   ( _ a:UInt16, _ b:UInt16 ) -> UInt16 { let res = a & b ; setz(z:res==0) ; return res }
  func xor   ( _ a:UInt16, _ b:UInt16 ) -> UInt16 { let res = a ^ b ; setz(z:res==0) ; return res }
  
  func lsr   ( _ a:UInt16 ) -> UInt16 { let res = a >> 1 ; setzc(z:res==0, c:a[0]); sr.c = a[0]; return res }
  func lsrc  ( _ a:UInt16 ) -> UInt16 { var res = a >> 1 ; res[15] = sr.c; setzc(z:res==0, c:a[0]); return res }
  func asr   ( _ a:UInt16 ) -> UInt16 { var res = a >> 1 ; res[15] = a[15]; setzc(z:res==0, c:a[0]); return res }
  func neg   ( _ a:UInt16 ) -> UInt16 { let res = sub( 0, a ) ; return res }
  func not   ( _ a:UInt16 ) -> UInt16 { let res = ~a ; setz(z:res==0) ; return res }
  func inca2 ( _ a:UInt16 ) -> UInt16 { let res = adda( a, 2 ) ; return res }
  func deca2 ( _ a:UInt16 ) -> UInt16 { let res = suba( a, 2 ) ; return res }
  func zext  ( _ a:UInt16 ) -> UInt16 { let res = a.zext ; return res }
  func sext  ( _ a:UInt16 ) -> UInt16 { let res = a.sext ; return res }
  func bswap ( _ a:UInt16 ) -> UInt16 { let res = UInt16(lo:a.hi, hi:a.lo) ; return res }
  func lsrb  ( _ a:UInt16 ) -> UInt16 { let res = UInt16(lo:a.hi, hi:0) ; return res }
  func asrb  ( _ a:UInt16 ) -> UInt16 { let res = UInt16(lo:a.hi, hi:(a[15] ? 255 : 0)) ; return res }
  func lslb  ( _ a:UInt16 ) -> UInt16 { let res = UInt16(lo:0, hi:a.lo) ; return res }
  func sextw ( _ a:UInt16 ) -> UInt16 { let res = (a.i16>>15).u16 ; return res }
}


