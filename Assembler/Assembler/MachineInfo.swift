//
//  MachineInfo.swift
//  c74-as
//
//  Created by Joan on 28/06/19.
//  Copyright © 2019 Joan. All rights reserved.
//

import Foundation

// Machine Instruction attribute flags
struct ReferenceKind: OptionSet
{
  let rawValue:Int
  static let relative = ReferenceKind(rawValue: 1 << 1)      // Indirect memory addressing
  static let absolute = ReferenceKind(rawValue: 1 << 2)      // Indirect program addressing
  static let shifted  = ReferenceKind(rawValue: 1 << 3)      // Has shifted immediate or register
}

//-------------------------------------------------------------------------------
// Machine instruction formats and encoding patterns
//-------------------------------------------------------------------------------

// Base class to represent machine instruction encodings. Objects have a
// single property which is the machine instruction encoding.
class MachineInstr
{
  let refKind:ReferenceKind
  var encoding:UInt16 = 0
  
  // Designated initializer, just sets the encoding to zero
  init( _ rk:ReferenceKind )
  {
    refKind = rk
  }
  
  // Overridable convenience initializer that must be implemented by subclases
  required convenience init(op:UInt16, ops:[Operand], rk:ReferenceKind = [])
  {
    self.init( rk )
    encoding = 0
  }
}

// Abstract protocol to represent objects referring Data Memory adresses
// that must be resolved at link time
class InstWithImmediate:MachineInstr
{
	let bitSiz:Int
	let hiShift:Int = 4
  let loMask:UInt16 = 0b1111
  let loOffs:Int = 7
	let hiMask:UInt16
  let hiOffs:Int = 0
  let sOffs:Int = 6
	
  
  init( bitSiz siz:Int, rk:ReferenceKind )
  {
  	bitSiz = siz
    hiMask = UInt16( (1<<(bitSiz-5)) - 1 )
    super.init( rk )
  }
  
  required convenience init(op:UInt16, ops:[Operand], rk:ReferenceKind = [])
  {
    self.init(bitSiz:5, rk:rk)
  }
  
  func setRawValue( v:UInt16 )
  {
    let mask:UInt16 = (1<<bitSiz)-1
    encoding &= ~(mask)
    encoding |= (mask & v)
  }
  
//  func setRawValue( v:UInt16 )
//  {
//    encoding &= ~(loMask << loOffs)
//    encoding |= (loMask & v) << loOffs
//
//    encoding &= ~(hiMask << hiOffs)
//    encoding |= (hiMask & (v>>hiShift)) << hiOffs
//
//    encoding &= ~(1 << sOffs)
//    encoding |= (1 & (v>>(bitSiz-1)) ) << sOffs
//  }
  
  func getShiftedValue( _ a:Int) -> Int
  {
    let shifted = refKind.contains(.shifted)
    if shifted && (a&1) != 0  { out.exitWithError( "Shifted value must be even" ) }
    return shifted ? a>>1 : a
  }
  
  func setValue( a:UInt16 )
  {
    let shifted = refKind.contains(.shifted)
    if shifted && (a&1) != 0  { out.exitWithError( "Shifted value must be even" ) }
    setRawValue( v: shifted ? a>>1 : a )
  }
  
  func setCoreValue( a:Int )
  {
    let v = getShiftedValue( a )
    setRawValue( v: UInt16(truncatingIfNeeded: v) )
  }
  
  func setPrefixedValue( a:Int )
  {
    let v = getShiftedValue( a )
    setRawValue( v: UInt16(truncatingIfNeeded: v & 0b1_1111) )
  }
  
  func inRange( _ a:Int ) -> Bool
  {
    // This tests true only for positive values that fit in the mask size
    // Might be overriden to test sign extended immediates
    let v = getShiftedValue( a )
    let mask = (1<<bitSiz)-1
    return (v & mask) == v
    
//    let mask = (1<<bitSiz)-1
//    return v >= 0 && v <= mask
    
  }
  
  func inSignExtendedRange( _ a:Int ) -> Bool
  {
    // This tests true only for positive or negative values
    // that fit in the mask size
    let v = getShiftedValue( a )
    let mask = (1<<bitSiz)-1
    let half = (mask+1)/2
    return v >= -half && v < half
  }
}

// Type P

class TypeP:InstWithImmediate
{
  init( op:UInt16, a:UInt16, rk:ReferenceKind )
  {
    super.init(bitSiz:11, rk:rk)
		encoding |= (0b11111 & op)  << 11
    setValue(a: a)
  }
  
  required convenience init(op:UInt16, ops:[Operand], rk:ReferenceKind = []) {
    self.init( op:op, a:ops[0].u16value, rk:rk ) }
  
  func setPrefixValue( a:Int )
  {
    let v = getShiftedValue( a )
    setRawValue( v: UInt16(truncatingIfNeeded: v>>5) )
  }
}

class TypeP_call:TypeP
{
  override func inRange( _ v:Int ) -> Bool {
    return inSignExtendedRange( v ) }                        // FIX ME : Aixo no es; korrecte, els calls son absoluts!
}

// Type I2

class TypeI2:InstWithImmediate
{
  init( op:UInt16, rs:UInt16, k:UInt16, rd:UInt16, rk:ReferenceKind )
  {
    super.init(bitSiz:5, rk:rk)
    encoding |= (0b11111 & op)  << 11
    encoding |= (0b111 & rs)    << 5
    encoding |= (0b111 & rd)    << 8
    setValue(a: k)
  }

//  init( op:UInt16, rs:UInt16, k:UInt16, rd:UInt16, rk:ReferenceKind )
//  {
//    super.init(bitSiz:5, rk:rk)
//    encoding |= (0b11111 & op)  << 11
//    encoding |= (0b111 & rs)    << 0
//    encoding |= (0b111 & rd)    << 3
//    setValue(a: k)
//  }
  
  required convenience init(op:UInt16, ops:[Operand], rk:ReferenceKind = []) {
    self.init( op:op, rs:ops[0].u16value, k:ops[1].u16value, rd:ops[2].u16value,  rk:rk )
  }
}

// Same as TypeI2, but the assembly operands
// are in swaped order
class TypeI2b:TypeI2
{
  required convenience init( op:UInt16, ops:[Operand], rk:ReferenceKind = [] ) {
    self.init( op:op, rs:ops[1].u16value, k:ops[2].u16value, rd:ops[0].u16value,  rk:rk )
  }
}

// Same as TypeI2b but overrides the inRange function for sign extended ranges
class TypeI2b_s:TypeI2
{
  override func inRange( _ v:Int ) -> Bool {
    return inSignExtendedRange( v ) }
  
  required convenience init(op:UInt16, ops:[Operand], rk:ReferenceKind = []) {
    self.init( op:op, rs:ops[1].u16value, k:ops[2].u16value, rd:ops[0].u16value,  rk:rk )
  }
}

// Type I1

class TypeI1:InstWithImmediate
{
  init( op:UInt16, k:UInt16, rd:UInt16,  rk:ReferenceKind )
  {
    super.init(bitSiz:8, rk:rk)
    encoding |= (0b11111 & op)    << 11
    encoding |= (0b111 & rd)       << 8
    setValue(a: k)
  }

//  init( op:UInt16, k:UInt16, rd:UInt16,  rk:ReferenceKind )
//  {
//    super.init(bitSiz:8, rk:rk)
//    encoding |= (0b11111 & op)    << 11
//    encoding |= (0b111 & rd)       << 3
//    setValue(a: k)
//  }
  
  required convenience init(op:UInt16, ops:[Operand], rk:ReferenceKind = []) {
    self.init( op:op, k:ops[0].u16value, rd:ops[1].u16value,  rk:rk ) }
}

// Same as TypeI1, but the assembly operands
// are in reversed order
class TypeI1b:TypeI1
{
  required convenience init( op:UInt16, ops:[Operand], rk:ReferenceKind = [] ) {
    self.init( op:op, k:ops[1].u16value, rd:ops[0].u16value,  rk:rk ) }
}

// Same as Type1Ib but overrides the inRange function for sign extended ranges
class TypeI1_s:TypeI1
{
  override func inRange( _ v:Int ) -> Bool {
    return inSignExtendedRange( v ) }
  
  required convenience init( op:UInt16, ops:[Operand], rk:ReferenceKind = [] ) {
    self.init( op:op, k:ops[0].u16value, rd:ops[1].u16value,  rk:rk ) }
}

// Same as TypeI2, but the interesting operands
// are in third and second place
class TypeI1c:TypeI1
{
  required convenience init(op:UInt16, ops:[Operand], rk:ReferenceKind = []) {
    self.init( op:op, k:ops[1].u16value, rd:ops[2].u16value,  rk:rk ) }
}

// Same as TypeI2, but the interesting operands
// are in first and thrid place
class TypeI1d:TypeI1
{
  required convenience init(op:UInt16, ops:[Operand], rk:ReferenceKind = []) {
    self.init( op:op, k:ops[2].u16value, rd:ops[0].u16value,  rk:rk ) }
}

// Type J

class TypeJ:InstWithImmediate
{
  init( op:UInt16, a:UInt16, rk:ReferenceKind )
  {
    super.init(bitSiz:9, rk:rk)
    encoding |= 0b00                  << 14
    encoding |= (0b11111 & op)        << 9
    setValue(a: a)
  }
  
//  init( op:UInt16, a:UInt16, rk:ReferenceKind )
//  {
//    super.init(bitSiz:9, rk:rk)
//    encoding |= 0b00                  << 14
//    encoding |= (0b111 & (op>>2))     << 11
//    encoding |= (0b11 & op)            << 4
//    setValue(a: a)
//  }
  
  required convenience init(op:UInt16, ops:[Operand], rk:ReferenceKind = []) {
    self.init( op:op, a:ops[0].u16value, rk:rk ) }
  
  override func inRange( _ v:Int ) -> Bool {
    return inSignExtendedRange( v ) }
}

class TypeJ_kq:TypeJ
{
  required convenience init(op:UInt16, ops:[Operand], rk:ReferenceKind = []) {
    self.init( op:op, a:ops[1].u16value, rk:rk ) }
}

// Type R3

class TypeR3:MachineInstr
{
  init( op:UInt16, rs:UInt16, rn:UInt16, rd:UInt16, rk:ReferenceKind )
  {
    super.init(rk)
    encoding |= 0b00                << 14
    encoding |= (0b111 & (op>>2))   << 11
    encoding |= (0b11 & op)         << 3
    encoding |= (0b111 & rd)        << 8
    encoding |= (0b111 & rs)        << 5
    encoding |= (0b111 & rn)        << 0
  }

//  init( op:UInt16, rs:UInt16, rn:UInt16, rd:UInt16, rk:ReferenceKind )
//  {
//    super.init(rk)
//    encoding |= 0b00            << 14
//    encoding |= (0b11111 & op)  << 9
//    encoding |= (0b111 & rn)    << 6
//    encoding |= (0b111 & rd)    << 3
//    encoding |= (0b111 & rs)    << 0
//  }
  
  required convenience init( op:UInt16, ops:[Operand], rk:ReferenceKind = [] ) {
    self.init( op:op, rs:ops[0].u16value, rn:ops[1].u16value, rd:ops[2].u16value, rk:rk ) }
}

// Same as TypeR3, but the assembly operands
// come in swaped order
class TypeR3b:TypeR3
{
  required convenience init( op:UInt16, ops:[Operand], rk:ReferenceKind = [] ) {
    self.init( op:op, rs:ops[1].u16value, rn:ops[2].u16value, rd:ops[0].u16value, rk:rk ) }
}

class TypeR2_0:MachineInstr
{
  init( op:UInt16, rk:ReferenceKind )
  {
    super.init(rk)
    encoding |= (0b0000)          << 12
    encoding |= (0b0)             << 11
    encoding |= (0b11111 & op)    << 0
    encoding |= (0b000)           << 8
    encoding |= (0b000)           << 5
  }
  
//  init( op:UInt16, rk:ReferenceKind )
//  {
//    super.init(rk)
//    encoding |= (0b0000)          << 12
//    encoding |= (0b11111 & op)    << 7
//    encoding |= (0b0)             << 6
//    encoding |= (0b000)           << 3
//    encoding |= (0b000)           << 0
//  }
  
  required convenience init(op:UInt16, ops:[Operand], rk:ReferenceKind = []) {
    self.init( op:op, rk:rk ) }
}

class TypeR2_1rd:MachineInstr
{
  init( op:UInt16, rd:UInt16, rk:ReferenceKind )
  {
    super.init(rk)
    encoding |= (0b0000)          << 12
    encoding |= (0b0)             << 11
    encoding |= (0b11111 & op)    << 0
    encoding |= (0b111 & rd)      << 8
    encoding |= (0b000)           << 5
  }

//  init( op:UInt16, rd:UInt16, rk:ReferenceKind )
//  {
//    super.init(rk)
//    encoding |= (0b0000)          << 12
//    encoding |= (0b11111 & op)    << 7
//    encoding |= (0b0)             << 6
//    encoding |= (0b111 & rd)      << 3
//    encoding |= (0b000)           << 0
//  }

  required convenience init(op:UInt16, ops:[Operand], rk:ReferenceKind = []) {
    self.init( op:op, rd:ops[0].u16value, rk:rk ) }
}

class TypeR2_1rs:MachineInstr
{
  init( op:UInt16, rs:UInt16, rk:ReferenceKind )
  {
    super.init(rk)
    encoding |= (0b0000)          << 12
    encoding |= (0b0)             << 11
    encoding |= (0b11111 & op)    << 0
    encoding |= (0b000)           << 8
    encoding |= (0b111 & rs)      << 5
  }

//  init( op:UInt16, rs:UInt16, rk:ReferenceKind )
//  {
//    super.init(rk)
//    encoding |= (0b0000)          << 12
//    encoding |= (0b11111 & op)    << 7
//    encoding |= (0b0)             << 6
//    encoding |= (0b000)           << 3
//    encoding |= (0b111 & rs)      << 0
//  }
  
  required convenience init(op:UInt16, ops:[Operand], rk:ReferenceKind = []) {
    self.init( op:op, rs:ops[0].u16value, rk:rk ) }
}

class TypeR2_2:MachineInstr
{
  init( op:UInt16, rs:UInt16, rd:UInt16, rk:ReferenceKind )
  {
    super.init(rk)
    encoding |= (0b0000)          << 12
    encoding |= (0b0)             << 11
    encoding |= (0b11111 & op)    << 0
    encoding |= (0b111 & rd)      << 8
    encoding |= (0b111 & rs)      << 5
  }

//  init( op:UInt16, rs:UInt16, rd:UInt16, rk:ReferenceKind )
//  {
//    super.init(rk)
//    encoding |= (0b0000)          << 12
//    encoding |= (0b11111 & op)    << 7
//    encoding |= (0b0)             << 6
//    encoding |= (0b111 & rd)      << 3
//    encoding |= (0b111 & rs)      << 0
//  }
  
  required convenience init( op:UInt16, ops:[Operand], rk:ReferenceKind = [] ) {
    self.init( op:op, rs:ops[0].u16value, rd:ops[1].u16value, rk:rk ) }
}

// Same as TypeR2_2, but the interesting operands
// are in third and second place
class TypeR2_2c:TypeR2_2
{
  required convenience init(op:UInt16, ops:[Operand], rk:ReferenceKind = []) {
    self.init( op:op, rs:ops[1].u16value, rd:ops[2].u16value, rk:rk ) }
}

// Same as TypeI2, but the interesting operands
// are in first and thrid place
class TypeR2_2d:TypeR2_2
{
  required convenience init(op:UInt16, ops:[Operand], rk:ReferenceKind = []) {
    self.init( op:op, rs:ops[0].u16value, rd:ops[2].u16value,  rk:rk ) }
}

// Immediate value in program memory

class TypeK:InstWithImmediate
{
  init( k:UInt16, rk:ReferenceKind )
  {
    super.init(bitSiz:16, rk:rk)
    //super.init(mask:0xffff, offs:0, rk:rk)
    encoding = k
  }
  
  override func setRawValue( v:UInt16 )
  {
    encoding = v
  }

  required convenience init( op:UInt16, ops:[Operand], rk:ReferenceKind = [] ) {
    self.init( k:ops[0].u16value, rk:rk  ) }
}


//-------------------------------------------------------------------------------
// Machine instruction list
//-------------------------------------------------------------------------------

// Singleton class for creating MachineInst from Instruction
class MachineInstrList
{
  // Dictionary returning a unique MachineInstr type and opcode for a given Instruction
  static let allInstr:Dictionary<Instruction, (ty:MachineInstr.Type, rk:ReferenceKind, op:UInt16)> =
  [
    // Type I2
    Instruction( "cmp".d,    [OpCC(), OpReg(), OpImm()] )                       : (ty:TypeI2b_s.self, rk:.absolute, op:0b10100),
    Instruction( "cmpc".d,   [OpCC(), OpReg(), OpImm()] )                       : (ty:TypeI2b_s.self, rk:.absolute, op:0b10101),
    Instruction( "and".d,    [OpReg(), OpImm(), OpReg()] )                      : (ty:TypeI2.self,  rk:.absolute, op:0b10110),
    
    Instruction( "cmp".d,    [OpCC(), OpReg(), OpSym()] )                       : (ty:TypeI2b_s.self, rk:.absolute, op:0b10100),
    Instruction( "cmpc".d,   [OpCC(), OpReg(), OpSym()] )                       : (ty:TypeI2b_s.self, rk:.absolute, op:0b10101),
    Instruction( "and".d,    [OpReg(), OpSym(), OpReg()] )                      : (ty:TypeI2.self,  rk:.absolute, op:0b10110),

    Instruction( "addx".d,   [OpReg(), OpImm(), OpReg()] )                      : (ty:TypeI2.self,  rk:.absolute, op:0b10111),
    Instruction( "ld.w".d,   [OpReg(.indirect), OpImm(.indirect), OpReg()] )    : (ty:TypeI2.self,  rk:[.absolute, .shifted], op:0b11000),
    //Instruction( "ld.zb".d,  [OpReg(.indirect), OpImm(.indirect), OpReg()] )    : (ty:TypeI2.self,  rk:.absolute, op:0b10110),
    Instruction( "ld.sb".d,  [OpReg(.indirect), OpImm(.indirect), OpReg()] )    : (ty:TypeI2.self,  rk:.absolute, op:0b11001),
    Instruction( "st.w".d,   [OpReg(), OpReg(.indirect), OpImm(.indirect)] )    : (ty:TypeI2b.self, rk:[.absolute, .shifted], op:0b11010),
    Instruction( "st.b".d,   [OpReg(), OpReg(.indirect), OpImm(.indirect)] )    : (ty:TypeI2b.self, rk:.absolute, op:0b11011),
    
    Instruction( "addx".d,   [OpReg(), OpSym(), OpReg()] )                      : (ty:TypeI2.self,  rk:.absolute, op:0b10111),
    Instruction( "ld.w".d,   [OpReg(.indirect), OpSym(.indirect), OpReg()] )    : (ty:TypeI2.self,  rk:[.absolute, .shifted], op:0b11000),
    //Instruction( "ld.zb".d,  [OpReg(.indirect), OpSym(.indirect), OpReg()] )    : (ty:TypeI2.self,  rk:.absolute, op:0b10110),
    Instruction( "ld.sb".d,  [OpReg(.indirect), OpSym(.indirect), OpReg()] )    : (ty:TypeI2.self,  rk:.absolute, op:0b11001),
    Instruction( "st.w".d,   [OpReg(), OpReg(.indirect), OpSym(.indirect)] )    : (ty:TypeI2b.self, rk:[.absolute, .shifted], op:0b11010),
    Instruction( "st.b".d,   [OpReg(), OpReg(.indirect), OpSym(.indirect)] )    : (ty:TypeI2b.self, rk:.absolute, op:0b11011),
    
    // Type P
    Instruction( "call".d,   [OpSym()] )                                        : (ty:TypeP_call.self, rk:.absolute, op:0b11110),
    Instruction( "_pfix".d,  [OpImm()] )                                        : (ty:TypeP.self,      rk:[], op:0b11111),
    
    // Type I1
    Instruction( "ld.w".d,   [OpImm(.indirect), OpReg()] )                      : (ty:TypeI1.self,  rk:[.absolute, .shifted], op:0b01000),
    Instruction( "ld.sb".d,  [OpImm(.indirect), OpReg()] )                      : (ty:TypeI1.self,  rk:.absolute, op:0b01001),
    Instruction( "st.w".d,   [OpReg(), OpImm(.indirect)] )                      : (ty:TypeI1b.self,   rk:[.absolute, .shifted], op:0b01010),
    Instruction( "st.b".d,   [OpReg(), OpImm(.indirect)] )                      : (ty:TypeI1b.self,   rk:.absolute, op:0b01011),
    
    Instruction( "ld.w".d,   [OpSym(.indirect), OpReg()] )                      : (ty:TypeI1.self,  rk:[.absolute, .shifted], op:0b01000),
    Instruction( "ld.sb".d,  [OpSym(.indirect), OpReg()] )                      : (ty:TypeI1.self,  rk:.absolute, op:0b01001),
    Instruction( "st.w".d,   [OpReg(), OpSym(.indirect)] )                      : (ty:TypeI1b.self,   rk:[.absolute, .shifted], op:0b01010),
    Instruction( "st.b".d,   [OpReg(), OpSym(.indirect)] )                      : (ty:TypeI1b.self,   rk:.absolute, op:0b01011),
    
    Instruction( "mov".d,    [OpImm(), OpReg()] )                               : (ty:TypeI1_s.self, rk:.absolute, op:0b01100),
    Instruction( "mov".d,    [OpSym(), OpReg()] )                               : (ty:TypeI1_s.self, rk:.absolute, op:0b01100),
    Instruction( "sub".d,    [OpReg(), OpImm(), OpReg()] )                      : (ty:TypeI1c.self,  rk:.absolute, op:0b01101),
    Instruction( "add".d,    [OpReg(), OpImm(), OpReg()] )                      : (ty:TypeI1c.self,  rk:.absolute, op:0b01110),
    
    Instruction( "sub".d,    [OpReg(), OpSym(), OpReg()] )                      : (ty:TypeI1c.self,  rk:.absolute, op:0b01101),

    Instruction( "addx".d,   [OpSP(), OpImm(), OpReg()] )                       : (ty:TypeI1c.self, rk:[.absolute, .shifted], op:0b01111),
    Instruction( "ld.w".d,   [OpSP(.indirect), OpImm(.indirect), OpReg()] )     : (ty:TypeI1c.self, rk:[.absolute, .shifted], op:0b10000),
    Instruction( "ld.sb".d,  [OpSP(.indirect), OpImm(.indirect), OpReg()] )     : (ty:TypeI1c.self, rk:.absolute, op:0b10001),
    Instruction( "st.w".d,   [OpReg(), OpSP(.indirect), OpImm(.indirect)] )     : (ty:TypeI1d.self, rk:[.absolute, .shifted], op:0b10010),
    Instruction( "st.b".d,   [OpReg(), OpSP(.indirect), OpImm(.indirect)] )     : (ty:TypeI1d.self, rk:.absolute, op:0b10011),


    // Type R3
    Instruction( "cmp".d,    [OpCC(), OpReg(), OpReg()] )                       : (ty:TypeR3b.self, rk:[], op:0b01000),
    Instruction( "cmpc".d,   [OpCC(), OpReg(), OpReg()] )                       : (ty:TypeR3b.self, rk:[], op:0b01001),
    Instruction( "subc".d,   [OpReg(), OpReg(), OpReg()] )                      : (ty:TypeR3.self,  rk:[], op:0b01010),
    Instruction( "sub".d,    [OpReg(), OpReg(), OpReg()] )                      : (ty:TypeR3.self,  rk:[], op:0b01011),
    Instruction( "and".d,    [OpReg(), OpReg(), OpReg()] )                      : (ty:TypeR3.self,  rk:[], op:0b01100),
    Instruction( "or".d,     [OpReg(), OpReg(), OpReg()] )                      : (ty:TypeR3.self,  rk:[], op:0b01101),
    Instruction( "selcc".d,  [OpReg(), OpReg(), OpReg()] )                      : (ty:TypeR3.self,  rk:[], op:0b01110),
    
    Instruction( "xor".d,    [OpReg(), OpReg(), OpReg()] )                      : (ty:TypeR3.self,  rk:[], op:0b10000),
    Instruction( "addc".d,   [OpReg(), OpReg(), OpReg()] )                      : (ty:TypeR3.self,  rk:[], op:0b10001),
    Instruction( "add".d,    [OpReg(), OpReg(), OpReg()] )                      : (ty:TypeR3.self,  rk:[], op:0b10010),
    Instruction( "ld.w".d,   [OpReg(.indirect), OpReg(.indirect), OpReg()] )    : (ty:TypeR3.self,  rk:.shifted, op:0b10011),
    Instruction( "ld.zb".d,  [OpReg(.indirect), OpReg(.indirect), OpReg()] )    : (ty:TypeR3.self,  rk:[], op:0b10100),
    Instruction( "ld.sb".d,  [OpReg(.indirect), OpReg(.indirect), OpReg()] )    : (ty:TypeR3.self,  rk:[], op:0b10101),
    Instruction( "st.w".d,   [OpReg(), OpReg(.indirect), OpReg(.indirect)] )    : (ty:TypeR3b.self, rk:.shifted, op:0b10110),
    Instruction( "st.b".d,   [OpReg(), OpReg(.indirect), OpReg(.indirect)] )    : (ty:TypeR3b.self, rk:[], op:0b10111),
    
    
    // Type J_cc, Type J
    Instruction( "brncc".d,  [OpSym()] )                                        : (ty:TypeJ.self, rk:.relative, op:0b11100),
    Instruction( "brcc".d,   [OpSym()] )                                        : (ty:TypeJ.self, rk:.relative, op:0b11101),
    Instruction( "addx".d,   [OpSP(), OpImm(), OpSP()] )                        : (ty:TypeJ_kq.self, rk:[.absolute, .shifted],     op:0b11110),
    Instruction( "jmp".d,    [OpSym()] )                                        : (ty:TypeJ.self, rk:.relative, op:0b11111),

    Instruction( "brncc".d,  [OpImm()] )                                        : (ty:TypeJ.self, rk:.absolute, op:0b11100),
    Instruction( "brcc".d,   [OpImm()] )                                        : (ty:TypeJ.self, rk:.absolute, op:0b11101),

    // Type R2_2
    Instruction( "mov".d,    [OpReg(), OpReg()] )                               : (ty:TypeR2_2.self,  rk:[], op:0b00000),
    Instruction( "mov".d,    [OpReg(), OpSP()] )                                : (ty:TypeR2_1rs.self,  rk:[], op:0b00001),
    Instruction( "zext".d,   [OpReg(), OpReg()] )                               : (ty:TypeR2_2.self,  rk:[], op:0b00010),
    Instruction( "sext".d,   [OpReg(), OpReg()] )                               : (ty:TypeR2_2.self,  rk:[], op:0b00011),
    
    Instruction( "lsrb".d,  [OpReg(), OpReg()] )                                : (ty:TypeR2_2.self,  rk:[], op:0b00100),
    Instruction( "asrb".d,  [OpReg(), OpReg()] )                                : (ty:TypeR2_2.self,  rk:[], op:0b00101),
    Instruction( "lslb".d,  [OpReg(), OpReg()] )                                : (ty:TypeR2_2.self,  rk:[], op:0b00110),
    
    Instruction( "sextw".d,  [OpReg(), OpReg()] )                               : (ty:TypeR2_2.self,  rk:[], op:0b00111),
    
//    Instruction( "bswap".d,  [OpReg(), OpReg()] )                               : (ty:TypeR2_2.self,  rk:[], op:0b00100),

    Instruction( "lsr".d,    [OpReg(), OpReg()] )                               : (ty:TypeR2_2.self,  rk:[], op:0b01000),
    Instruction( "lsrc".d,   [OpReg(), OpReg()] )                               : (ty:TypeR2_2.self,  rk:[], op:0b01001),
    Instruction( "asr".d,    [OpReg(), OpReg()] )                               : (ty:TypeR2_2.self,  rk:[], op:0b01010),
    
    Instruction( "ld.w".d,   [OpReg(.prgIndirect), OpReg()] )                   : (ty:TypeR2_2.self,  rk:[], op:0b01011),

    Instruction( "selcc".d,  [OpZero(), OpReg(), OpReg()] )                     : (ty:TypeR2_2c.self, rk:[], op:0b01100),
    Instruction( "selcc".d,  [OpReg(), OpZero(), OpReg()] )                     : (ty:TypeR2_2d.self, rk:[], op:0b01101),

    Instruction( "neg".d,    [OpReg(), OpReg()] )                               : (ty:TypeR2_2.self,  rk:[], op:0b01110),
    Instruction( "not".d,    [OpReg(), OpReg()] )                               : (ty:TypeR2_2.self,  rk:[], op:0b01111),

    // Type R2_1
    Instruction( "jmp".d,    [OpReg()] )                                        : (ty:TypeR2_1rs.self,  rk:[], op:0b10000),
    Instruction( "call".d,   [OpReg()] )                                        : (ty:TypeR2_1rd.self,  rk:[], op:0b10001),  // Source in Rd !
    
    Instruction( "setncc".d,  [OpReg()] )                                       : (ty:TypeR2_1rd.self,  rk:[], op:0b10110),
    Instruction( "setcc".d,   [OpReg()] )                                       : (ty:TypeR2_1rd.self,  rk:[], op:0b10111),

    // Type R2_0
    Instruction( "nop".d,    [] )                                               : (ty:TypeR2_0.self,  rk:[], op:0b00000),
    Instruction( "ret".d,    [] )                                               : (ty:TypeR2_0.self,  rk:[], op:0b11000),
    Instruction( "reti".d,   [] )                                               : (ty:TypeR2_0.self,  rk:[], op:0b11001),
    Instruction( "dint".d,   [] )                                               : (ty:TypeR2_0.self,  rk:[], op:0b11010),
    Instruction( "eint".d,   [] )                                               : (ty:TypeR2_0.self,  rk:[], op:0b11011),
    Instruction( "halt".d,   [] )                                               : (ty:TypeR2_0.self,  rk:[], op:0b11100),

    // The following represent immediate words
    Instruction( "_imm".d,   [OpImm()] )                                        : (ty:TypeK.self,   rk:.absolute, op:0),
    Instruction( "_imm".d,   [OpSym()] )                                        : (ty:TypeK.self,   rk:.absolute, op:0),
  ]
  
  //-------------------------------------------------------------------------------
  // Returs a new MachineInstr object initialized with a matching Instruction
  static func newMachineInst( _ inst:Instruction ) -> MachineInstr?
  {
    if let t = allInstr[inst]
    {
      let machineInst = t.ty.init(op:t.op, ops:inst.ops, rk:t.rk)
      return machineInst
    }
    return nil
  }
  
} // End Class MachineInstrList

//-------------------------------------------------------------------------------
// Machine data types and formats
//-------------------------------------------------------------------------------

// Base class to represent machine data values. Simple type objects keep two
// convenience representations of the same value as an Int value and raw Data bytes.
// Large type objects such as strings only use the raw Data bytes property.
class MachineData
{
  var bytes = Data()
  var value:Int?
  
  // Update both properties from an Int value of a given size
  func setBytes( size:Int, value k:Int )
  {
    value = k
    bytes.removeAll(keepingCapacity:true)
    var val = value!
    for _ in 0..<size
    {
      let byte = UInt8(truncatingIfNeeded:(val & 0xff))
      bytes.append(byte)  // appends in little endian way
      val = val >> 8
    }
  }

  // Designated initializer
  init( size:Int, value k:Int )
  {
    setBytes(size:size, value:k)
  }
  
  // Designated initializer
  init( data:Data )
  {
    value = nil
    bytes = data   // appends as provided
  }
  
  // Conveninence initializer that must be implemented by subclases
  required convenience init( size:Int, op:Operand )
  {
    self.init( size:2, value:0 )
  }
}

// Immediate value, a.k.a constant
class TypeImm:MachineData
{
  required convenience init( size:Int, op:Operand ) {
    self.init( size:size, value:Int(op.u16value) )
  }
}

// Sequence of bytes represented as a string
class TypeString:MachineData
{
  required convenience init( size:Int, op:Operand ) {
    self.init( data:op.sym! )
  }
}

// Absolute address
class TypeAddr:MachineData /*, InstDTAbsolute*/
{
  required convenience init( size:Int, op:Operand ) {
    self.init( size:size, value:Int(op.u16value) )
  }
  
  func setAbsolute( a:UInt16 ) {
    setBytes(size:2, value:Int(a))
  }
  
  func setPrefixedValue( a:UInt16 ) {
    setAbsolute( a: a )
  }
}

//-------------------------------------------------------------------------------
// Machine data list
//-------------------------------------------------------------------------------

// Singleton class for creating MachineData from DataValue
class MachineDataList
{
  // Dictionary returning a unique DataValue type for a given MachineData object
  static let allData:Dictionary<DataValue, MachineData.Type> =
  [
    DataValue( 0, OpImm() )    : TypeImm.self,
    DataValue( 0, OpStr() )    : TypeString.self,
    DataValue( 0, OpSym() )    : TypeAddr.self
  ]
  
  // Returs a new MachineData object initialized with a matching DataValue
  static func newMachineData( _ dv:DataValue ) -> MachineData?
  {
    if let machineDataType = allData[dv]
    {
      let machineData = machineDataType.init( size:dv.byteSize, op:dv.oper )
      return machineData
    }
    return nil
  }
  
}  // End class MachineData
