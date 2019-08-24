//
//  MachineInfo.swift
//  c74-as
//
//  Created by Joan on 28/06/19.
//  Copyright © 2019 Joan. All rights reserved.
//

import Foundation

//-------------------------------------------------------------------------------
// Machine instruction formats and encoding patterns
//-------------------------------------------------------------------------------

// Base class to represent machine instruction encodings. Objects have a
// single property which is the machine instruction encoding.
class MachineInstr
{
  var encoding:UInt16
  
  // Designated initializer, just sets the encoding to zero
  init() {
    encoding = 0
  }
  
  // Overridable convenience initializer that must be implemented by subclases
  required convenience init(op:UInt16, ops:[Operand])
  {
    self.init()
  }
}

// Abstract protocol to represent instructions with PC relative offsets
// that must be resolved at link time
protocol InstPCRelative
{
   func setRelative( a:UInt16 ) // required
}

// Abstract protocol to represent objects referring Data Memory adresses
// that must be resolved at link time
protocol InstDTAbsolute
{
   func setAbsolute( a:UInt16 ) // required
}

// Relative call/jump
class Type1:MachineInstr,InstPCRelative
{
  init( op:UInt16, a:UInt16 )
  {
    super.init()
    encoding |= (0b111)              << 13
    encoding |= (0b1 & op)           << 12
    encoding |= (0b1111_1111_1111 & a) << 0
  }
  
  required convenience init(op:UInt16, ops:[Operand]) {
    self.init( op:op, a:ops[0].u16value )
  }
  
  func setRelative( a:UInt16 )
  {
    let mask:UInt16 = 0b1111_1111_1111
    encoding &= ~mask
    encoding |= (mask & a)
  }
}

// Conditional branch
class Type2:MachineInstr,InstPCRelative
{
  init( cc:UInt16, a:UInt16 )
  {
    super.init()
    encoding |= (0b110)            << 13
    encoding |= (0b111 & cc)       << 10
    encoding |= (0b11_1111_1111 & a )  << 0
  }
  
  required convenience init(op:UInt16, ops:[Operand]) {
    self.init( cc:ops[0].u16value, a:ops[1].u16value )
  }
  
  func setRelative( a:UInt16 )
  {
    let mask:UInt16 = 0b11_1111_1111
    encoding &= ~mask
    encoding |= (mask & a)
  }
}

// Move, Compare, ALU immediate
class Type3:MachineInstr
{
  init( op:UInt16, rd:UInt16, k:UInt16 )
  {
    super.init()
    encoding |= (0b10)            << 14
    encoding |= (0b111  & op)     << 11
    encoding |= (0b1111_1111 & k)  << 3
    encoding |= (0b111 & rd)      << 0
  }
  
  required convenience init(op:UInt16, ops:[Operand]) {
    self.init( op:op, rd:ops[0].u16value, k:ops[1].u16value )
  }
}

// Same as Type3, but the assembly operands
// are in swaped order
class Type3b:Type3
{
  required convenience init( op:UInt16, ops:[Operand] ) {
    self.init( op:op, rd:ops[1].u16value, k:ops[0].u16value )
  }
}

// Load/store with immediate offset
class Type4:MachineInstr
{
  init( op:UInt16, rn:UInt16, rd:UInt16, k:UInt16 )
  {
    super.init()
    encoding |= (0b01)          << 14
    encoding |= (0b11 & op)     << 12
    encoding |= (0b11_1111 & k)  << 6
    encoding |= (0b111 & rn)    << 3
    encoding |= (0b111 & rd)    << 0
  }
  
  required convenience init(op:UInt16, ops:[Operand]) {
    self.init( op:op, rn:ops[0].u16value, rd:ops[2].u16value, k:ops[1].u16value )
  }
}

// Same as Type4, but the assembly operands
// are in swaped order
class Type4b:Type4
{
  required convenience init( op:UInt16, ops:[Operand] ) {
    self.init( op:op, rn:ops[1].u16value, rd:ops[0].u16value, k:ops[2].u16value )
  }
}

// Three register ALU operation,
// Load/store with register offset
class Type5:MachineInstr
{
  init( op:UInt16, rn:UInt16, rs:UInt16, rd:UInt16 )
  {
    super.init()
    encoding |= (0b001)        << 13
    encoding |= (0b1111 & op)  << 9
    encoding |= (0b111 & rn)   << 6
    encoding |= (0b111 & rs)   << 3
    encoding |= (0b111 & rd)   << 0
  }
  
  required convenience init( op:UInt16, ops:[Operand] ) {
    self.init( op:op, rn:ops[0].u16value, rs:ops[1].u16value, rd:ops[2].u16value )
  }
}

// Same as Type5, but the assembly operands
// come in swaped order
class Type5b:Type5
{
  required convenience init( op:UInt16, ops:[Operand] ) {
    self.init( op:op, rn:ops[2].u16value, rs:ops[0].u16value, rd:ops[1].u16value )
  }
}

// Conditional select
class Type6:MachineInstr
{
  init( cc:UInt16, rn:UInt16, rs:UInt16, rd:UInt16 )
  {
    super.init()
    encoding |= (0b000)       << 12
    encoding |= (0b111 & cc)  << 10
    encoding |= (0b1)         << 9
    encoding |= (0b111 & rn)  << 6
    encoding |= (0b111 & rs)  << 3
    encoding |= (0b111 & rd)  << 0
  }
  
  required convenience init(op:UInt16, ops:[Operand]) {
    self.init( cc:ops[0].u16value, rn:ops[1].u16value, rs:ops[2].u16value, rd:ops[3].u16value )
  }
}

// Conditional set
class Type7:MachineInstr
{
  init( cc:UInt16, rd:UInt16 )
  {
    super.init()
    encoding |= (0b000)       << 13
    encoding |= (0b111 & cc)  << 10
    encoding |= (0b0)         << 9
    encoding |= (0b111)       << 6
    encoding |= (0b000)       << 3
    encoding |= (0b111 & rd)  << 0
  }
  
  required convenience init(op:UInt16, ops:[Operand]) {
    self.init( cc:ops[0].u16value, rd:ops[1].u16value )
  }
}

// Zero Operand Instructions
class Type8:MachineInstr
{
  init( op:UInt16 )
  {
    //super.init(str, alt);
    super.init()
    encoding |= (0b000)       << 13
    encoding |= (0b111 & op)  << 10
    encoding |= (0b0)         << 9
    encoding |= (0b110)       << 6
    encoding |= (0b000)       << 3
    encoding |= (0b000)       << 0
  }
  
  required convenience init(op:UInt16, ops:[Operand]) {
    self.init( op:op )
  }
}

// Push/Pop, move SP Register, Branch/Call Indirect
class Type9:MachineInstr
{
  init( op:UInt16, rd:UInt16 )
  {
    super.init()
    encoding |= (0b000)            << 13
    encoding |= (0b111 & (op>>1))  << 10
    encoding |= (0b0)              << 9
    encoding |= (0b10)             << 7
    encoding |= (0b1 & op)         << 6
    encoding |= (0b000)            << 3
    encoding |= (0b111 & rd)       << 0
  }
  
  required convenience init(op:UInt16, ops:[Operand]) {
    self.init( op:op, rd:ops[0].u16value )
  }
}

// Same as Type9, but the interesting operand
// is in the second place
class Type9b:Type9
{
  required convenience init(op:UInt16, ops:[Operand]) {
    self.init( op:op, rd:ops[1].u16value )
  }
}

// Two register Move, Compare, ALU operation
class Type10:MachineInstr
{
  init( op:UInt16, rs:UInt16, rd:UInt16 )
  {
    //super.init(str, alt);
    super.init()
    encoding |= (0b000)            << 13
    encoding |= (0b111 & (op>>2))  << 10
    encoding |= (0b00)             << 8
    encoding |= (0b11  & op)       << 6
    encoding |= (0b111 & rs)       << 3
    encoding |= (0b111 & rd)       << 0
  }
  
  required convenience init( op:UInt16, ops:[Operand] ) {
    self.init( op:op, rs:ops[0].u16value, rd:ops[1].u16value )
  }
}

// Same as Type10, but the interesting operands
// are in first and third place
class Type10b:Type10
{
  required convenience init(op:UInt16, ops:[Operand]) {
    self.init( op:op, rs:ops[0].u16value, rd:ops[2].u16value )
  }
}

// Same as Type10, but the interesting operands
// are in third and first place
class Type10c:Type10
{
  required convenience init(op:UInt16, ops:[Operand]) {
    self.init( op:op, rs:ops[2].u16value, rd:ops[0].u16value )
  }
}

// Immediate second word operand
class TypeK:MachineInstr
{
  init( k:UInt16 )
  {
    super.init()
    encoding = k
  }
  
  required convenience init( op:UInt16, ops:[Operand] ) {
    self.init( k:ops[0].u16value  )
  }
}

// Same as TypeK but conforming to InstDTAbsolute
class TypeS:TypeK,InstDTAbsolute
{
  func setAbsolute( a:UInt16 ) {
    encoding = a
  }
}

//-------------------------------------------------------------------------------
// Machine instruction list
//-------------------------------------------------------------------------------

// Singleton class for creating MachineInst from Instruction
class MachineInstrList
{

// Dictionary returning a unique MachineInstr type and opcode for a given Instruction
  static let allInstr:Dictionary<Instruction, (ty:MachineInstr.Type, op:UInt16)> =
  [
    // Type 1
    Instruction( "jmp".d,    [OpSym()] )                       : (ty:Type1.self, op:0b0),
    Instruction( "jsr".d,    [OpSym()] )                       : (ty:Type1.self, op:0b1),
    
    // Type 2
    Instruction( "brcc".d,   [OpImm(), OpSym()] )              : (ty:Type2.self, op:0),
    
    // Type 3
    Instruction( "mov".d,    [OpImm(), OpReg()] )              : (ty:Type3b.self, op:0b000),
    Instruction( "cmp".d,    [OpReg(), OpImm()] )              : (ty:Type3.self,  op:0b001),
    Instruction( "add".d,    [OpReg(), OpImm(), OpReg()] )     : (ty:Type3.self,  op:0b010),
    Instruction( "sub".d,    [OpReg(), OpImm(), OpReg()] )     : (ty:Type3.self,  op:0b011),
    Instruction( "and".d,    [OpReg(), OpImm(), OpReg()] )     : (ty:Type3.self,  op:0b100),
    Instruction( "or".d,     [OpReg(), OpImm(), OpReg()] )     : (ty:Type3.self,  op:0b101),
    Instruction( "xor".d,    [OpReg(), OpImm(), OpReg()] )     : (ty:Type3.self,  op:0b110),
    
    // Type 4
    Instruction( "ld.w".d,   [OpReg(.indirect), OpImm(.indirect), OpReg()] )    : (ty:Type4.self,  op:0b00),
    Instruction( "ld.sb".d,  [OpReg(.indirect), OpImm(.indirect), OpReg()] )    : (ty:Type4.self,  op:0b01),
    Instruction( "st.w".d,   [OpReg(), OpReg(.indirect), OpImm(.indirect)] )    : (ty:Type4b.self, op:0b10),
    Instruction( "st.b".d,   [OpReg(), OpReg(.indirect), OpImm(.indirect)] )    : (ty:Type4b.self, op:0b11),
    
    // Type 5
    Instruction( "add".d,    [OpReg(), OpReg(), OpReg()] )                     : (ty:Type5.self,  op:0b0000),
    Instruction( "addc".d,   [OpReg(), OpReg(), OpReg()] )                     : (ty:Type5.self,  op:0b0001),
    Instruction( "sub".d,    [OpReg(), OpReg(), OpReg()] )                     : (ty:Type5.self,  op:0b0010),
    Instruction( "subc".d,   [OpReg(), OpReg(), OpReg()] )                     : (ty:Type5.self,  op:0b0011),
    Instruction( "or".d,     [OpReg(), OpReg(), OpReg()] )                     : (ty:Type5.self,  op:0b0100),
    Instruction( "and".d,    [OpReg(), OpReg(), OpReg()] )                     : (ty:Type5.self,  op:0b0101),
    Instruction( "xor".d,    [OpReg(), OpReg(), OpReg()] )                     : (ty:Type5.self,  op:0b0110),
    Instruction( "ld.w".d,   [OpReg(.indirect), OpReg(.indirect), OpReg()] )    : (ty:Type5.self,  op:0b1000),
    Instruction( "ld.zb".d,  [OpReg(.indirect), OpReg(.indirect), OpReg()] )    : (ty:Type5.self,  op:0b1010),
    Instruction( "ld.sb".d,  [OpReg(.indirect), OpReg(.indirect), OpReg()] )    : (ty:Type5.self,  op:0b1011),
    Instruction( "st.w".d,   [OpReg(), OpReg(.indirect), OpReg(.indirect)] )    : (ty:Type5b.self, op:0b1100),
    Instruction( "st.b".d,   [OpReg(), OpReg(.indirect), OpReg(.indirect)] )    : (ty:Type5b.self, op:0b1101),
    
    // Type 6
    Instruction( "selcc".d,  [OpImm(), OpReg(), OpReg(), OpReg()] )           : (ty:Type6.self, op:0),
    
    // Type 7
    Instruction( "setcc".d,  [OpImm(), OpReg()] )              : (ty:Type7.self, op:0),
    
    // Type 8
    Instruction( "ret".d,    [] )                    : (ty:Type8.self,  op:0b000),
    Instruction( "reti".d,   [] )                    : (ty:Type8.self,  op:0b001),
    Instruction( "dint".d,   [] )                    : (ty:Type8.self,  op:0b010),
    Instruction( "eint".d,   [] )                    : (ty:Type8.self,  op:0b011),
    Instruction( "halt".d,   [] )                    : (ty:Type8.self,  op:0b100),
    Instruction( "call".d,   [OpSym(.extern)] )     : (ty:Type8.self,  op:0b111),
    
    // Type 9
    Instruction( "jmp".d,    [OpReg()] )                              : (ty:Type9.self,  op:0b0000),
    Instruction( "call".d,   [OpReg()] )                              : (ty:Type9.self,  op:0b0010),
    Instruction( "push".d,   [OpReg()] )                              : (ty:Type9.self,  op:0b0100),
    Instruction( "pop".d,    [OpReg()] )                              : (ty:Type9.self,  op:0b0110),
    
    Instruction( "mov".d,    [OpImm(.extern), OpReg()] )              : (ty:Type9b.self, op:0b0001),
    Instruction( "mov".d,    [OpSym(.extern), OpReg()] )              : (ty:Type9b.self, op:0b0001),
    
    Instruction( "ld.w".d,   [OpSym([.indirect,.extern]), OpReg()] )    : (ty:Type9b.self, op:0b0011),
    Instruction( "ld.zb".d,  [OpSym([.indirect,.extern]), OpReg()] )    : (ty:Type9b.self, op:0b0101),
    Instruction( "ld.sb".d,  [OpSym([.indirect,.extern]), OpReg()] )    : (ty:Type9b.self, op:0b0111),
    Instruction( "st.w".d,   [OpReg(), OpSym([.indirect,.extern])] )    : (ty:Type9.self,  op:0b1001),
    Instruction( "st.b".d,   [OpReg(), OpSym([.indirect,.extern])] )    : (ty:Type9.self,  op:0b1011),

    // Type 10
    Instruction( "mov".d,    [OpReg(), OpReg()] )                              : (ty:Type10.self,  op:0b000_00),
    Instruction( "cmp".d,    [OpReg(), OpReg()] )                              : (ty:Type10.self,  op:0b001_00),
    Instruction( "zext".d,   [OpReg(), OpReg()] )                              : (ty:Type10.self,  op:0b010_00),
    Instruction( "sext".d,   [OpReg(), OpReg()] )                              : (ty:Type10.self,  op:0b011_00),
    Instruction( "bswap".d,  [OpReg(), OpReg()] )                              : (ty:Type10.self,  op:0b100_00),
    Instruction( "sextw".d,  [OpReg(), OpReg()] )                              : (ty:Type10.self,  op:0b101_00),
    Instruction( "ld.w".d,   [OpReg(.prgIndirect), OpReg()] )                  : (ty:Type10.self,  op:0b111_00),
    Instruction( "lsr".d,    [OpReg(), OpReg()] )                              : (ty:Type10.self,  op:0b000_01),
    Instruction( "lsl".d,    [OpReg(), OpReg()] )                              : (ty:Type10.self,  op:0b001_01),
    Instruction( "asr".d,    [OpReg(), OpReg()] )                              : (ty:Type10.self,  op:0b010_01),
    Instruction( "neg".d,    [OpReg(), OpReg()] )                              : (ty:Type10.self,  op:0b101_01),
    Instruction( "not".d,    [OpReg(), OpReg()] )                              : (ty:Type10.self,  op:0b110_01),
    
    Instruction( "add".d,    [OpReg(), OpImm(.extern), OpReg()] )                          : (ty:Type10b.self, op:0b000_10),
    Instruction( "ld.w".d,   [OpReg(.indirect), OpImm([.indirect,.extern]), OpReg()] )     : (ty:Type10b.self, op:0b00110),
    Instruction( "ld.zb".d,  [OpReg(.indirect), OpImm([.indirect,.extern]), OpReg()] )     : (ty:Type10b.self, op:0b01010),
    Instruction( "ld.sb".d,  [OpReg(.indirect), OpImm([.indirect,.extern]), OpReg()] )     : (ty:Type10b.self, op:0b01110),
    Instruction( "st.w".d,   [OpReg(), OpReg(.indirect), OpImm([.indirect,.extern])] )     : (ty:Type10c.self, op:0b10010),
    Instruction( "st.b".d,   [OpReg(), OpReg(.indirect), OpImm([.indirect,.extern])] )     : (ty:Type10c.self, op:0b10110),
    
    Instruction( "add".d,    [OpReg(), OpSym(.extern), OpReg()] )                          : (ty:Type10b.self, op:0b00010),
    Instruction( "ld.w".d,   [OpReg(.indirect), OpSym([.indirect,.extern]), OpReg()] )     : (ty:Type10b.self, op:0b00110),
    Instruction( "ld.zb".d,  [OpReg(.indirect), OpSym([.indirect,.extern]), OpReg()] )     : (ty:Type10b.self, op:0b01010),
    Instruction( "ld.sb".d,  [OpReg(.indirect), OpSym([.indirect,.extern]), OpReg()] )     : (ty:Type10b.self, op:0b01110),
    Instruction( "st.w".d,   [OpReg(), OpReg(.indirect), OpSym([.indirect,.extern])] )     : (ty:Type10c.self, op:0b10010),
    Instruction( "st.b".d,   [OpReg(), OpReg(.indirect), OpSym([.indirect,.extern])] )     : (ty:Type10c.self, op:0b10110),

    // The following represent immediate words that may follow some instructions
    Instruction( "_imm".d,   [OpImm(.extern)] )                  : (ty:TypeK.self,   op:0),
    Instruction( "_imm".d,   [OpImm([.indirect,.extern])] )      : (ty:TypeK.self,   op:0),
    Instruction( "_imm".d,   [OpSym(.extern)] )                  : (ty:TypeS.self,   op:0),
    Instruction( "_imm".d,   [OpSym([.indirect,.extern])] )      : (ty:TypeS.self,   op:0),
  ]
  
  // Returs a new MachineInstr object initialized with a matching Instruction
  static func newMachineInst( _ inst:Instruction ) -> MachineInstr?
  {
    if let t = allInstr[inst]
    {
      let machineInstType = t.ty
      let machineInst = machineInstType.init(op:t.op, ops:inst.ops)
      return machineInst
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
class TypeAddr:MachineData, InstDTAbsolute
{
  required convenience init( size:Int, op:Operand ) {
    self.init( size:size, value:Int(op.u16value) )
  }
  
  func setAbsolute( a:UInt16 ) {
    setBytes(size:2, value:Int(a))
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
