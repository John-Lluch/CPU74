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
  let mask:UInt16
  let offs:Int
  
  init( mask m:UInt16, offs o:Int, rk:ReferenceKind )
  {
    mask = m
    offs = o
    super.init( rk )
  }
  
  required convenience init(op:UInt16, ops:[Operand], rk:ReferenceKind = [])
  {
    self.init(mask:0, offs:0, rk:rk)
  }
  
  func setValue( a:UInt16 )
  {
    encoding &= ~mask << offs
    encoding |= (mask & a) << offs
  }
  
  func setPrefixedValue( a:UInt16 )
  {
    setValue( a: a & 0b1_1111 )
  }
  
  func inRange( _ v:Int ) -> Bool
  {
    // This tests true only for positive values that fit in the mask size
    // Might be overrided to test sign extended immediates
    return v & Int(mask) == v
  }
  
  func signExtendRange( _ v:Int ) -> Bool
  {
    let half = (Int(mask)+1)/2
    return v >= -half && v < half
  }
}

// Type P

class TypeP:InstWithImmediate
{
  init( op:UInt16, a:UInt16, rk:ReferenceKind )
  {
    super.init(mask:0b111_1111_1111, offs:0, rk:rk )
    encoding |= (0b1111)      << 12
    encoding |= (0b1 & op)    << 11
    encoding |= (mask & a)    << offs
  }
  
  required convenience init(op:UInt16, ops:[Operand], rk:ReferenceKind = []) {
    self.init( op:op, a:ops[0].u16value, rk:rk ) }
  
  func setPrefixValue( a:UInt16 )
  {
    // Note that this works because mask is 11 bit and shift is 5 bit
    encoding &= ~mask
    encoding |= (mask & (a>>5))
  }
}

class TypeP_call:TypeP
{
  override func inRange( _ v:Int ) -> Bool {
    return signExtendRange( v ) }
}

// Type I1

class TypeI1:InstWithImmediate
{
  init( op:UInt16, rs:UInt16, rd:UInt16, k:UInt16, rk:ReferenceKind )
  {
    super.init(mask:0b1_1111, offs:6, rk:rk)
    encoding |= (0b11)          << 14
    encoding |= (0b111 & op)    << 11
    encoding |= (mask & k)      << offs
    encoding |= (0b111 & rs)    << 3
    encoding |= (0b111 & rd)    << 0
  }
  
  required convenience init(op:UInt16, ops:[Operand], rk:ReferenceKind = []) {
    self.init( op:op, rs:ops[0].u16value, rd:ops[2].u16value, k:ops[1].u16value, rk:rk )
  }
}

// Same as TypeI1, but the assembly operands
// are in swaped order
class TypeI1b:TypeI1
{
  required convenience init( op:UInt16, ops:[Operand], rk:ReferenceKind = [] ) {
    self.init( op:op, rs:ops[1].u16value, rd:ops[0].u16value, k:ops[2].u16value, rk:rk )
  }
}

// Type I2

class TypeI2:InstWithImmediate
{
  init( op:UInt16, rd:UInt16, k:UInt16, rk:ReferenceKind )
  {
    super.init(mask:0b1111_1111, offs:3, rk:rk)
    encoding |= (0b111_11 & op)    << 11
    encoding |= (mask & k)         << offs
    encoding |= (0b111 & rd)       << 0
  }
  
  required convenience init(op:UInt16, ops:[Operand], rk:ReferenceKind = []) {
    self.init( op:op, rd:ops[0].u16value, k:ops[1].u16value, rk:rk ) }
}

// Same as TypeI2, but the assembly operands
// are in reversed order
class TypeI2b:TypeI2
{
  required convenience init( op:UInt16, ops:[Operand], rk:ReferenceKind = [] ) {
    self.init( op:op, rd:ops[1].u16value, k:ops[0].u16value, rk:rk ) }
}

// Same as Type2Ib but overrides the inRange function for sign extended ranges
class TypeI2b_s:TypeI2
{
  override func inRange( _ v:Int ) -> Bool {
    return signExtendRange( v ) }
  
  required convenience init( op:UInt16, ops:[Operand], rk:ReferenceKind = [] ) {
    self.init( op:op, rd:ops[1].u16value, k:ops[0].u16value, rk:rk ) }
}

// Same as TypeI2, but the interesting operands
// are in third and second place
class TypeI2c:TypeI2
{
  required convenience init(op:UInt16, ops:[Operand], rk:ReferenceKind = []) {
    self.init( op:op, rd:ops[2].u16value, k:ops[1].u16value, rk:rk ) }
}

// Same as TypeI2, but the interesting operands
// are in first and thrid place
class TypeI2d:TypeI2
{
  required convenience init(op:UInt16, ops:[Operand], rk:ReferenceKind = []) {
    self.init( op:op, rd:ops[0].u16value, k:ops[2].u16value, rk:rk ) }
}

// Type J

class TypeJ_cc:InstWithImmediate
{
  init( cc:UInt16, a:UInt16, rk:ReferenceKind )
  {
    super.init(mask:0b1_1111_1111, offs:0, rk:rk)
    encoding |= (0b0100)             << 12
    encoding |= (0b111 & cc)         << 9
    encoding |= (mask & a )          << offs
  }
  
  required convenience init(op:UInt16, ops:[Operand], rk:ReferenceKind = []) {
    self.init( cc:ops[0].u16value, a:ops[1].u16value, rk:rk ) }
  
  override func inRange( _ v:Int ) -> Bool {
    return signExtendRange( v ) }
}

class TypeJ:InstWithImmediate
{
  init( op:UInt16, a:UInt16, rk:ReferenceKind )
  {
    super.init(mask:0b1_1111_1111, offs:0, rk:rk)
    encoding |= (0b001_1111)         << 9
    encoding |= (mask & a)           << offs
  }
  
  required convenience init(op:UInt16, ops:[Operand], rk:ReferenceKind = []) {
    self.init( op:op, a:ops[0].u16value, rk:rk ) }
  
  override func inRange( _ v:Int ) -> Bool {
    return signExtendRange( v ) }
}

// Type R1

class TypeR1:MachineInstr
{
  init( op:UInt16, rn:UInt16, rs:UInt16, rd:UInt16, rk:ReferenceKind )
  {
    super.init(rk)
    encoding |= (0b001)        << 13
    encoding |= (0b1111 & op)  << 9
    encoding |= (0b111 & rn)   << 6
    encoding |= (0b111 & rs)   << 3
    encoding |= (0b111 & rd)   << 0
  }
  
  required convenience init( op:UInt16, ops:[Operand], rk:ReferenceKind = [] ) {
    self.init( op:op, rn:ops[0].u16value, rs:ops[1].u16value, rd:ops[2].u16value, rk:rk ) }
}

// Same as TypeR1, but the assembly operands
// come in swaped order
class TypeR1b:TypeR1
{
  required convenience init( op:UInt16, ops:[Operand], rk:ReferenceKind = [] ) {
    self.init( op:op, rn:ops[2].u16value, rs:ops[0].u16value, rd:ops[1].u16value, rk:rk ) }
}

// Same as TypeR1, but ignores rd
class TypeR1c:TypeR1
{
  required convenience init( op:UInt16, ops:[Operand], rk:ReferenceKind = [] ) {
    self.init( op:op, rn:ops[0].u16value, rs:ops[1].u16value, rd:0, rk:rk ) }
}

class TypeR1_cc:MachineInstr
{
  init( cc:UInt16, rn:UInt16, rs:UInt16, rd:UInt16, rk:ReferenceKind )
  {
    super.init(rk)
    encoding |= (0b0001)      << 12
    encoding |= (0b111 & cc)  << 9
    encoding |= (0b111 & rn)  << 6
    encoding |= (0b111 & rs)  << 3
    encoding |= (0b111 & rd)  << 0
  }
  
  required convenience init(op:UInt16, ops:[Operand], rk:ReferenceKind = []) {
    self.init( cc:ops[0].u16value, rn:ops[1].u16value, rs:ops[2].u16value, rd:ops[3].u16value, rk:rk ) }
}

// Type R2

class TypeR2_cc:MachineInstr
{
  init( cc:UInt16, rd:UInt16, rk:ReferenceKind = [] )
  {
    super.init(rk)
    encoding |= (0b0000)      << 12
    encoding |= (0b111 & cc)  << 9
    encoding |= (0b111)       << 6
    encoding |= (0b000)       << 3
    encoding |= (0b111 & rd)  << 0
  }
  
  required convenience init(op:UInt16, ops:[Operand], rk:ReferenceKind = []) {
    self.init( cc:ops[0].u16value, rd:ops[1].u16value, rk:rk )
  }
}

class TypeR2_0:MachineInstr
{
  init( op:UInt16, rk:ReferenceKind )
  {
    //super.init(str, alt);
    super.init(rk)
    encoding |= (0b0000)          << 12
    encoding |= (0b111_111 & op)  << 6
    encoding |= (0b000)           << 3
    encoding |= (0b000)           << 0
  }
  
  required convenience init(op:UInt16, ops:[Operand], rk:ReferenceKind = []) {
    self.init( op:op, rk:rk ) }
}

class TypeR2_1:MachineInstr
{
  init( op:UInt16, rd:UInt16, rk:ReferenceKind )
  {
    super.init(rk)
    encoding |= (0b0000)          << 12
    encoding |= (0b111_111 & op)  << 6
    encoding |= (0b000)           << 3
    encoding |= (0b111 & rd)      << 0
  }
  
  required convenience init(op:UInt16, ops:[Operand], rk:ReferenceKind = []) {
    self.init( op:op, rd:ops[0].u16value, rk:rk ) }
}

class TypeR2_2:MachineInstr
{
  init( op:UInt16, rs:UInt16, rd:UInt16, rk:ReferenceKind )
  {
    //super.init(str, alt);
    super.init(rk)
    encoding |= (0b0000)          << 12
    encoding |= (0b111_111 & op)  << 6
    encoding |= (0b111 & rs)      << 3
    encoding |= (0b111 & rd)      << 0
  }
  
  required convenience init( op:UInt16, ops:[Operand], rk:ReferenceKind = [] ) {
    self.init( op:op, rs:ops[0].u16value, rd:ops[1].u16value, rk:rk ) }
}

// Immediate value in program memory

class TypeK:InstWithImmediate
{
  init( k:UInt16, rk:ReferenceKind )
  {
    super.init(mask:0xffff, offs:0, rk:rk)
    encoding = k
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
    // Type P
    Instruction( "_pfix".d,  [OpImm()] )                       : (ty:TypeP.self, rk:[], op:0b1),
    
    // Type P_call
    Instruction( "call".d,   [OpSym()] )                       : (ty:TypeP_call.self, rk:.absolute, op:0b0),
  
    // Type I1
    Instruction( "lea".d,    [OpReg(), OpImm(), OpReg()] )                      : (ty:TypeI1.self,  rk:[], op:0b000),
    Instruction( "ld.w".d,   [OpReg(.indirect), OpImm(.indirect), OpReg()] )    : (ty:TypeI1.self,  rk:[], op:0b001),
    Instruction( "ld.zb".d,  [OpReg(.indirect), OpImm(.indirect), OpReg()] )    : (ty:TypeI1.self,  rk:[], op:0b010),
    Instruction( "ld.sb".d,  [OpReg(.indirect), OpImm(.indirect), OpReg()] )    : (ty:TypeI1.self,  rk:[], op:0b011),
    Instruction( "st.w".d,   [OpReg(), OpReg(.indirect), OpImm(.indirect)] )    : (ty:TypeI1b.self, rk:[], op:0b100),
    Instruction( "st.b".d,   [OpReg(), OpReg(.indirect), OpImm(.indirect)] )    : (ty:TypeI1b.self, rk:[], op:0b101),
    
    Instruction( "lea".d,    [OpReg(), OpSym(), OpReg()] )                      : (ty:TypeI1.self,  rk:.absolute, op:0b000),
    Instruction( "ld.w".d,   [OpReg(.indirect), OpSym(.indirect), OpReg()] )    : (ty:TypeI1.self,  rk:.absolute, op:0b001),
    Instruction( "ld.zb".d,  [OpReg(.indirect), OpSym(.indirect), OpReg()] )    : (ty:TypeI1.self,  rk:.absolute, op:0b010),
    Instruction( "ld.sb".d,  [OpReg(.indirect), OpSym(.indirect), OpReg()] )    : (ty:TypeI1.self,  rk:.absolute, op:0b011),
    Instruction( "st.w".d,   [OpReg(), OpReg(.indirect), OpSym(.indirect)] )    : (ty:TypeI1b.self, rk:.absolute, op:0b100),
    Instruction( "st.b".d,   [OpReg(), OpReg(.indirect), OpSym(.indirect)] )    : (ty:TypeI1b.self, rk:.absolute, op:0b101),
    
    // Type I2
    Instruction( "mov".d,    [OpImm(), OpReg()] )              : (ty:TypeI2b.self, rk:[], op:0b01010),
    Instruction( "mov".d,    [OpSym(), OpReg()] )              : (ty:TypeI2b_s.self, rk:.absolute, op:0b01010),
    Instruction( "cmp".d,    [OpReg(), OpImm()] )              : (ty:TypeI2.self,  rk:[], op:0b01011),
    Instruction( "add".d,    [OpReg(), OpImm(), OpReg()] )     : (ty:TypeI2.self,  rk:[], op:0b01100),
    Instruction( "sub".d,    [OpReg(), OpImm(), OpReg()] )     : (ty:TypeI2.self,  rk:[], op:0b01101),
    Instruction( "and".d,    [OpReg(), OpImm(), OpReg()] )     : (ty:TypeI2.self,  rk:[], op:0b01110),
    
    Instruction( "ld.w".d,   [OpSym(.indirect), OpReg()] )     : (ty:TypeI2b.self,  rk:.absolute, op:0b01111),
    Instruction( "ld.zb".d,  [OpSym(.indirect), OpReg()] )     : (ty:TypeI2b.self,  rk:.absolute, op:0b10000),
    Instruction( "st.w".d,   [OpReg(), OpSym(.indirect)] )     : (ty:TypeI2.self,   rk:.absolute, op:0b10001),
    Instruction( "st.b".d,   [OpReg(), OpSym(.indirect)] )     : (ty:TypeI2.self,   rk:.absolute, op:0b10010),
    
    Instruction( "lea".d,    [OpReg(.isSP), OpImm(), OpReg()] )                         : (ty:TypeI2c.self, rk:[], op:0b10011),
    Instruction( "ld.w".d,   [OpReg([.isSP,.indirect]), OpImm(.indirect), OpReg()] )    : (ty:TypeI2c.self, rk:[], op:0b10100),
    Instruction( "ld.zb".d,  [OpReg([.isSP,.indirect]), OpImm(.indirect), OpReg()] )    : (ty:TypeI2c.self, rk:[], op:0b10101),
    Instruction( "st.w".d,   [OpReg(), OpReg([.isSP,.indirect]), OpImm(.indirect)] )    : (ty:TypeI2d.self, rk:[], op:0b10110),
    Instruction( "st.b".d,   [OpReg(), OpReg([.isSP,.indirect]), OpImm(.indirect)] )    : (ty:TypeI2d.self, rk:[], op:0b10111),

    // Type J_cc, Type J
    Instruction( "brcc".d,   [OpImm(), OpSym()] )              : (ty:TypeJ_cc.self, rk:.relative, op:0),
    Instruction( "jmp".d,    [OpSym()] )                       : (ty:TypeJ.self,    rk:.relative, op:0),
    
    // Type R1
    Instruction( "add".d,    [OpReg(), OpReg(), OpReg()] )                     : (ty:TypeR1.self,  rk:[], op:0b0000),
    Instruction( "addc".d,   [OpReg(), OpReg(), OpReg()] )                     : (ty:TypeR1.self,  rk:[], op:0b0001),
    Instruction( "sub".d,    [OpReg(), OpReg(), OpReg()] )                     : (ty:TypeR1.self,  rk:[], op:0b0010),
    Instruction( "subc".d,   [OpReg(), OpReg(), OpReg()] )                     : (ty:TypeR1.self,  rk:[], op:0b0011),
    Instruction( "or".d,     [OpReg(), OpReg(), OpReg()] )                     : (ty:TypeR1.self,  rk:[], op:0b0100),
    Instruction( "and".d,    [OpReg(), OpReg(), OpReg()] )                     : (ty:TypeR1.self,  rk:[], op:0b0101),
    Instruction( "xor".d,    [OpReg(), OpReg(), OpReg()] )                     : (ty:TypeR1.self,  rk:[], op:0b0110),
    Instruction( "cmp".d,    [OpReg(), OpReg()] )                              : (ty:TypeR1c.self, rk:[], op:0b0111),
    Instruction( "ld.w".d,   [OpReg(.indirect), OpReg(.indirect), OpReg()] )   : (ty:TypeR1.self,  rk:[], op:0b1001),
    Instruction( "ld.zb".d,  [OpReg(.indirect), OpReg(.indirect), OpReg()] )   : (ty:TypeR1.self,  rk:[], op:0b1010),
    Instruction( "ld.sb".d,  [OpReg(.indirect), OpReg(.indirect), OpReg()] )   : (ty:TypeR1.self,  rk:[], op:0b1011),
    Instruction( "st.w".d,   [OpReg(), OpReg(.indirect), OpReg(.indirect)] )   : (ty:TypeR1b.self, rk:[], op:0b1100),
    Instruction( "st.b".d,   [OpReg(), OpReg(.indirect), OpReg(.indirect)] )   : (ty:TypeR1b.self, rk:[], op:0b1101),
    
    // Type R1_cc
    Instruction( "selcc".d,  [OpImm(), OpReg(), OpReg(), OpReg()] )            : (ty:TypeR1_cc.self, rk:[], op:0),
    
    // Type R2_cc
    Instruction( "setcc".d,  [OpImm(), OpReg()] )              : (ty:TypeR2_cc.self, rk:[], op:0),
    
    // Type R2_0
    Instruction( "ret".d,    [] )                              : (ty:TypeR2_0.self,  rk:[], op:0b000_110),
    Instruction( "reti".d,   [] )                              : (ty:TypeR2_0.self,  rk:[], op:0b001_110),
    Instruction( "dint".d,   [] )                              : (ty:TypeR2_0.self,  rk:[], op:0b010_110),
    Instruction( "eint".d,   [] )                              : (ty:TypeR2_0.self,  rk:[], op:0b011_110),
    Instruction( "halt".d,   [] )                              : (ty:TypeR2_0.self,  rk:[], op:0b100_110),
    
    // Type R2_1
    Instruction( "jmp".d,    [OpReg()] )                       : (ty:TypeR2_1.self,  rk:[], op:0b000_100),
    Instruction( "call".d,   [OpReg()] )                       : (ty:TypeR2_1.self,  rk:[], op:0b001_100),
    Instruction( "push".d,   [OpReg()] )                       : (ty:TypeR2_1.self,  rk:[], op:0b010_100),
    Instruction( "pop".d,    [OpReg()] )                       : (ty:TypeR2_1.self,  rk:[], op:0b011_100),

    // Type R2_2
    Instruction( "mov".d,    [OpReg(), OpReg()] )                              : (ty:TypeR2_2.self,  rk:[], op:0b000_000),
    Instruction( "zext".d,   [OpReg(), OpReg()] )                              : (ty:TypeR2_2.self,  rk:[], op:0b010_000),
    Instruction( "sext".d,   [OpReg(), OpReg()] )                              : (ty:TypeR2_2.self,  rk:[], op:0b011_000),
    Instruction( "bswap".d,  [OpReg(), OpReg()] )                              : (ty:TypeR2_2.self,  rk:[], op:0b100_000),
    Instruction( "sextw".d,  [OpReg(), OpReg()] )                              : (ty:TypeR2_2.self,  rk:[], op:0b101_000),
    Instruction( "ld.w".d,   [OpReg(.prgIndirect), OpReg()] )                  : (ty:TypeR2_2.self,  rk:[], op:0b111_000),
    Instruction( "lsr".d,    [OpReg(), OpReg()] )                              : (ty:TypeR2_2.self,  rk:[], op:0b000_001),
    Instruction( "lsl".d,    [OpReg(), OpReg()] )                              : (ty:TypeR2_2.self,  rk:[], op:0b001_001),
    Instruction( "asr".d,    [OpReg(), OpReg()] )                              : (ty:TypeR2_2.self,  rk:[], op:0b010_001),
    Instruction( "neg".d,    [OpReg(), OpReg()] )                              : (ty:TypeR2_2.self,  rk:[], op:0b101_001),
    Instruction( "not".d,    [OpReg(), OpReg()] )                              : (ty:TypeR2_2.self,  rk:[], op:0b110_001),

    // The following represent immediate words
    Instruction( "_imm".d,   [OpImm()] )                       : (ty:TypeK.self,   rk:[], op:0),
    Instruction( "_imm".d,   [OpSym()] )                       : (ty:TypeK.self,   rk:.absolute, op:0),
  ]
  

  // Returs a new MachineInstr object initialized with a matching Instruction
  static func newMachineInst( _ inst:Instruction ) -> MachineInstr?
  {
    if let t = allInstr[inst]
    {
      let machineInst = t.ty.init(op:t.op, ops:inst.ops, rk:t.rk)
      return machineInst
    }
    else if let opReg = inst.opSP
    {
      opReg.opt.remove(.isSP)
      return newMachineInst( inst )
    }

    return nil
  }
}

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
}
