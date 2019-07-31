//
//  InstInfo.swift
//  c74-as
//
//  Created by Joan on 28/06/19.
//  Copyright © 2019 Joan. All rights reserved.
//

import Foundation

// Base class to represent machine encodings
class MachineInstr
{
  var encoding:UInt16
  init() {
    encoding = 0
  }
  
  required convenience init(op:UInt16, ops:[Operand]) {
    self.init()
  }
}

// Abstract protocol to represent instructions with PC relative offsets
// that must be resolved at link time
protocol InstPCRelative
{
   func setRelative( a:UInt16 ) // required
}

// Abstract protocol to represent instructions referring Data Memory adresses
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
    encoding |= (0b111)       << 13
    encoding |= (0b1 & op)    << 12
    encoding |= (0b11111111111 & a)
  }
  
  required convenience init(op:UInt16, ops:[Operand]) {
    self.init( op:op, a:ops[0].u16value )
  }
  
  func setRelative( a:UInt16 )
  {
    let mask:UInt16 = 0b11111111111
    encoding = ~mask
    encoding |= (mask & a)
  }
}

// Conditional branch
class Type2:MachineInstr,InstPCRelative
{
  init( cc:UInt16, a:UInt16 )
  {
    super.init()
    encoding |= (0b1101)       << 12
    encoding |= (0b111 & cc)   << 9
    encoding |= (0b11111111 & a )
  }
  
  required convenience init(op:UInt16, ops:[Operand]) {
    self.init( cc:ops[0].u16value, a:ops[1].u16value )
  }
  
  func setRelative( a:UInt16 )
  {
    let mask:UInt16 = 0b11111111
    encoding = ~mask
    encoding |= (mask & a)
  }
}

// Conditional set
class Type3:MachineInstr
{
  init( cc:UInt16, rd:UInt16 )
  {
    super.init()
    encoding |= (0b0000)     << 12
    encoding |= (0b111 & cc) << 9
    encoding |= (0b11)       << 7
    encoding |= (0b0000)     << 3
    encoding |= (0b111 & rd) << 0
  }
  
  required convenience init(op:UInt16, ops:[Operand]) {
    self.init( cc:ops[0].u16value, rd:ops[1].u16value )
  }
}

// Conditional select
class Type4:MachineInstr
{
  init( cc:UInt16, rn:UInt16, rs:UInt16, rd:UInt16 )
  {
    super.init()
    encoding |= (0b0001)      << 12
    encoding |= (0b111 & cc)  << 9
    encoding |= (0b111 & rn)  << 6
    encoding |= (0b111 & rs)  << 3
    encoding |= (0b111 & rd)  << 0
  }
  
  required convenience init(op:UInt16, ops:[Operand]) {
    self.init( cc:ops[0].u16value, rn:ops[1].u16value, rs:ops[2].u16value, rd:ops[3].u16value )
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
    encoding |= (0b111  & rn)  << 6
    encoding |= (0b111  & rs)  << 3
    encoding |= (0b111  & rd)  << 0
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

// And/or immediate
class Type6:MachineInstr
{
  init( op:UInt16, rd:UInt16, k:UInt16 )
  {
    super.init()
    encoding |= (0b1100)       << 12
    encoding |= (0b111 & rd)   << 9
    encoding |= (0b1)          << 8
    encoding |= (0b11  & op)   << 6
    encoding |= (0b111111 & k) << 0
  }
  
  required convenience init(op:UInt16, ops:[Operand]) {
    self.init( op:op, rd:ops[0].u16value, k:ops[1].u16value )
  }
}

// Load/store with immediate offset
class Type7:MachineInstr
{
  init( op:UInt16, rn:UInt16, rd:UInt16, k:UInt16 )
  {
    super.init()
    encoding |= (0b10)         << 14
    encoding |= (0b11   & op)  << 12
    encoding |= (0b111  & rd)  << 9
    encoding |= (0b111  & rn)  << 6
    encoding |= (0b111111 & k) << 0
  }
  
  required convenience init(op:UInt16, ops:[Operand]) {
    self.init( op:op, rn:ops[0].u16value, rd:ops[2].u16value, k:ops[1].u16value )
  }
}

// Same as Type7, but the assembly operands
// come in swaped order
class Type7b:Type7
{
  required convenience init( op:UInt16, ops:[Operand] ) {
    self.init( op:op, rn:ops[1].u16value, rd:ops[0].u16value, k:ops[2].u16value )
  }
}

// Move, Compare, Add, Subtract immediate
class Type8:MachineInstr
{
  init( op:UInt16, rd:UInt16, k:UInt16 )
  {
    super.init()
    encoding |= (0b01)            << 14
    encoding |= (0b11  & op)      << 12
    encoding |= (0b111 & rd)      << 9
    encoding |= (0b1)             << 8
    encoding |= (0b11111111 & k)  << 0
  }
  
  required convenience init(op:UInt16, ops:[Operand]) {
    self.init( op:op, rd:ops[0].u16value, k:ops[1].u16value )
  }
}

// Same as Type8, but the assembly operands
// come in swaped order
class Type8b:Type8
{
  required convenience init( op:UInt16, ops:[Operand] ) {
    self.init( op:op, rd:ops[1].u16value, k:ops[0].u16value )
  }
}

// SP relative load/store
class Type9:MachineInstr
{
  init( op:UInt16, rd:UInt16, k:UInt16 )
  {
    super.init()
    encoding |= (0b01)            << 14
    encoding |= (0b11  & op)      << 12
    encoding |= (0b111 & rd)      << 9
    encoding |= (0b0)             << 8
    encoding |= (0b11111111 & k)  << 0
  }
  
  required convenience init(op:UInt16, ops:[Operand]) {
    self.init( op:op, rd:ops[2].u16value, k:ops[1].u16value )
  }
}

// Same as Type9, but the assembly operands
// come in swaped order
class Type9b:Type9
{
  required convenience init( op:UInt16, ops:[Operand] ) {
    self.init( op:op, rd:ops[0].u16value, k:ops[2].u16value )
  }
}

// Add/Subtract offset to SP
class Type10:MachineInstr
{
  init( op:UInt16, k:UInt16 )
  {
    super.init()
    encoding |= (0b1100)          << 12
    encoding |= (0b1  & op)       << 11
    encoding |= (0b00)            << 9
    encoding |= (0b0)             << 8
    encoding |= (0b11111111 & k)  << 0
  }
  
  required convenience init(op:UInt16, ops:[Operand]) {
    self.init( op:op, k:ops[1].u16value )
  }
}

// Push/Pop, Move SP Register, Add SP Register, Branch/Call Indirect,
// Move immediate, Load/store with absolute address, ALU operation
class Type11:MachineInstr
{
  init( op:UInt16, rd:UInt16 )
  {
    super.init()
    let o = op&0b111
    let m = (op>>3)&0b11
    encoding |= (0b0000)          << 12
    encoding |= (0b111 & o)       << 9
    encoding |= (0b10)            << 7
    encoding |= (0b11 & m)        << 5
    encoding |= (0b00)            << 3
    encoding |= (0b111 & rd)      << 0
  }
  
  required convenience init(op:UInt16, ops:[Operand]) {
    self.init( op:op, rd:ops[0].u16value )
  }
}

// Same as Type11, but the interesting assembly operand
// comes second
class Type11b:Type11
{
  required convenience init( op:UInt16, ops:[Operand] ) {
    self.init( op:op, rd:ops[1].u16value  )
  }
}

// Immediate extern operand used by some Type11 instructions
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

// Zero Operand Instructions
class Type12:MachineInstr
{
  init( op:UInt16 )
  {
    //super.init(str, alt);
    super.init()
    encoding |= (0b0000)        << 12
    encoding |= (0b111 & op)    << 9
    encoding |= (0b01)          << 7
    encoding |= (0b00)          << 5
    encoding |= (0b00)          << 3
    encoding |= (0b000)         << 0
  }
  
  required convenience init(op:UInt16, ops:[Operand]) {
    self.init( op:op )
  }
}

// Two register Move, Compare, ALU operation
class Type13:MachineInstr
{
  init( op:UInt16, rs:UInt16, rd:UInt16 )
  {
    //super.init(str, alt);
    super.init()
    encoding |= (0b0000)       << 12
    encoding |= (0b111 & op)   << 9
    encoding |= (0b000)        << 6
    encoding |= (0b111 & rs)   << 3
    encoding |= (0b111 & rd)   << 0
  }
  
  required convenience init( op:UInt16, ops:[Operand] ) {
    self.init( op:op, rs:ops[0].u16value, rd:ops[1].u16value )
  }
}

// Machine instruction list
class MachineInstrList
{
  static let allInstr:Dictionary<Instruction, (ty:MachineInstr.Type, op:UInt16)> =
  [
    // Type 1
    Instruction( "jmp".d,    [OpSym()] )                  : (ty:Type1.self, op:0b0),
    Instruction( "call".d,   [OpSym()] )                  : (ty:Type1.self, op:0b1),
    
    // Type 2
    Instruction( "brcc".d,   [OpImm(), OpSym()] )         : (ty:Type2.self, op:0),
    
    // Type 3
    Instruction( "setcc".d,  [OpImm(), OpReg()] )         : (ty:Type3.self, op:0),
    
    // Type 4
    Instruction( "selcc".d,  [OpImm(), OpReg(), OpReg(), OpReg()] )           : (ty:Type4.self, op:0),
    
    // Type 5
    Instruction( "add".d,    [OpReg(), OpReg(), OpReg()] )                    : (ty:Type5.self,  op:0b0000),
    Instruction( "addc".d,   [OpReg(), OpReg(), OpReg()] )                    : (ty:Type5.self,  op:0b0001),
    Instruction( "sub".d,    [OpReg(), OpReg(), OpReg()] )                    : (ty:Type5.self,  op:0b0010),
    Instruction( "subc".d,   [OpReg(), OpReg(), OpReg()] )                    : (ty:Type5.self,  op:0b0011),
    Instruction( "or".d,     [OpReg(), OpReg(), OpReg()] )                    : (ty:Type5.self,  op:0b0100),
    Instruction( "and".d,    [OpReg(), OpReg(), OpReg()] )                    : (ty:Type5.self,  op:0b0101),
    Instruction( "xor".d,    [OpReg(), OpReg(), OpReg()] )                    : (ty:Type5.self,  op:0b0110),
    Instruction( "ld.w".d,   [OpReg(ind:true), OpReg(ind:true), OpReg()] )    : (ty:Type5.self,  op:0b1000),
    Instruction( "ld.zb".d,  [OpReg(ind:true), OpReg(ind:true), OpReg()] )    : (ty:Type5.self,  op:0b1010),
    Instruction( "ld.sb".d,  [OpReg(ind:true), OpReg(ind:true), OpReg()] )    : (ty:Type5.self,  op:0b1011),
    Instruction( "st.w".d,   [OpReg(), OpReg(ind:true), OpReg(ind:true)] )    : (ty:Type5b.self, op:0b1100),
    Instruction( "st.b".d,   [OpReg(), OpReg(ind:true), OpReg(ind:true)] )    : (ty:Type5b.self, op:0b1110),
    
    // Type 6
    Instruction( "and".d,    [OpReg(), OpImm(), OpReg()] )                    : (ty:Type6.self,  op:0b00),
    Instruction( "or".d,     [OpReg(), OpImm(), OpReg()] )                    : (ty:Type6.self,  op:0b01),
    
    // Type 7
    Instruction( "ld.w".d,   [OpReg(ind:true), OpImm(ind:true), OpReg()] )    : (ty:Type7.self,  op:0b00),
    Instruction( "ld.sb".d,  [OpReg(ind:true), OpImm(ind:true), OpReg()] )    : (ty:Type7.self,  op:0b01),
    Instruction( "st.w".d,   [OpReg(), OpReg(ind:true), OpImm(ind:true)] )    : (ty:Type7b.self, op:0b10),
    Instruction( "st.b".d,   [OpReg(), OpReg(ind:true), OpImm(ind:true)] )    : (ty:Type7b.self, op:0b11),

    // Type 8
    Instruction( "mov".d,    [OpImm(), OpReg()] )                             : (ty:Type8b.self, op:0b00),
    Instruction( "cmp".d,    [OpReg(), OpImm()] )                             : (ty:Type8.self,  op:0b01),
    Instruction( "add".d,    [OpReg(), OpImm(), OpReg()] )                    : (ty:Type8.self,  op:0b10),
    Instruction( "sub".d,    [OpReg(), OpImm(), OpReg()] )                    : (ty:Type8.self,  op:0b11),

    // Type 9
    Instruction( "ld.w".d,   [OpRSP(ind:true), OpImm(ind:true), OpReg()] )    : (ty:Type9.self,  op:0b00),
    Instruction( "ld.sb".d,  [OpRSP(ind:true), OpImm(ind:true), OpReg()] )    : (ty:Type9.self,  op:0b01),
    Instruction( "st.w".d,   [OpReg(), OpRSP(ind:true), OpImm(ind:true)] )    : (ty:Type9b.self, op:0b10),
    Instruction( "st.b".d,   [OpReg(), OpRSP(ind:true), OpImm(ind:true)] )    : (ty:Type9b.self, op:0b11),

    // Type 10
    Instruction( "add".d,    [OpRSP(), OpImm(), OpRSP()] )    : (ty:Type10.self,  op:0b0),
    Instruction( "sub".d,    [OpRSP(), OpImm(), OpRSP()] )    : (ty:Type10.self,  op:0b1),

    // Type 11
    Instruction( "push".d,   [OpReg()] )                      : (ty:Type11.self,  op:0b00000),
    Instruction( "pop".d,    [OpReg()] )                      : (ty:Type11.self,  op:0b00001),
    Instruction( "mov".d,    [OpRSP(), OpReg()] )             : (ty:Type11b.self, op:0b00010),
    Instruction( "mov".d,    [OpReg(), OpRSP()] )             : (ty:Type11.self,  op:0b00011),
    Instruction( "add".d,    [OpRSP(), OpReg(), OpRSP()] )    : (ty:Type11b.self, op:0b00100),
    Instruction( "sub".d,    [OpRSP(), OpReg(), OpRSP()] )    : (ty:Type11b.self, op:0b00101),
    Instruction( "add".d,    [OpRSP(), OpReg(), OpReg()] )    : (ty:Type11b.self, op:0b00110),
    Instruction( "sub".d,    [OpRSP(), OpReg(), OpReg()] )    : (ty:Type11b.self, op:0b00111),

    Instruction( "jmp".d,    [OpReg()] )                      : (ty:Type11.self,  op:0b01000),
    Instruction( "call".d,   [OpReg()] )                      : (ty:Type11.self,  op:0b01001),
    
    Instruction( "lsr".d,    [OpReg()] )                      : (ty:Type11.self,  op:0b10000),
    Instruction( "lsl".d,    [OpReg()] )                      : (ty:Type11.self,  op:0b10001),
    Instruction( "asr".d,    [OpReg()] )                      : (ty:Type11.self,  op:0b10010),
    
    Instruction( "neg".d,   [OpReg()] )                       : (ty:Type11.self,  op:0b10101),
    Instruction( "not".d,   [OpReg()] )                       : (ty:Type11.self,  op:0b10110),

    Instruction( "mov.w".d,  [OpImm(), OpReg()] )             : (ty:Type11b.self, op:0b11000),
    Instruction( "mov.w".d,  [OpSym(), OpReg()] )             : (ty:Type11b.self, op:0b11000),
    Instruction( "ld.w".d,   [OpSym(ind:true), OpReg()] )     : (ty:Type11b.self, op:0b11001),
    Instruction( "ld.zb".d,  [OpSym(ind:true), OpReg()] )     : (ty:Type11b.self, op:0b11010),
    Instruction( "ld.sb".d,  [OpSym(ind:true), OpReg()] )     : (ty:Type11b.self, op:0b11011),
    Instruction( "st.w".d,   [OpReg(), OpSym(ind:true)] )     : (ty:Type11.self,  op:0b11100),
    Instruction( "st.b".d,   [OpReg(), OpSym(ind:true)] )     : (ty:Type11.self,  op:0b11101),

    // Type Immediate
    Instruction( "_imm".d,  [OpImm()] )                       : (ty:TypeK.self,   op:0),
    Instruction( "_imm".d,  [OpSym()] )                       : (ty:TypeS.self,   op:0),
    Instruction( "_imm".d,  [OpSym(ind:true)] )               : (ty:TypeS.self,   op:0),
    
    // Type 12
    Instruction( "ret".d,    [] )          : (ty:Type12.self,  op:0b000),
    Instruction( "reti".d,   [] )          : (ty:Type12.self,  op:0b001),
    Instruction( "dint".d,   [] )          : (ty:Type12.self,  op:0b010),
    Instruction( "eint".d,   [] )          : (ty:Type12.self,  op:0b011),
    
    // Type 13
    Instruction( "mov".d,    [OpReg(), OpReg()] )             : (ty:Type13.self, op:0b000),
    Instruction( "cmp".d,    [OpReg(), OpReg()] )             : (ty:Type13.self, op:0b001),
    Instruction( "zext".d,   [OpReg(), OpReg()] )             : (ty:Type13.self, op:0b010),
    Instruction( "sext".d,   [OpReg(), OpReg()] )             : (ty:Type13.self, op:0b011),
    Instruction( "bswap".d,  [OpReg(), OpReg()] )             : (ty:Type13.self, op:0b100),
    Instruction( "sextw".d,  [OpReg(), OpReg()] )             : (ty:Type13.self, op:0b101),
    
  ]
  
  static func getMachineInst( _ inst:Instruction ) -> MachineInstr?
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

// Abstract protocol to represent raw data bytes expressed as a string
protocol RawDataString
{
}

// Machine data formats
class MachineData
{
  //var value:Int
  var bytes:Data
  init() {
    //value = 0
    bytes = Data()
  }
  
  func appendBytes( size:Int, k:Int )
  {
    var val = k
    for _ in 0..<size
    {
      let byte = UInt8(truncatingIfNeeded:(val & 0xff))
      bytes.append(byte)
      val = val >> 8
    }
  }

  init( size:Int, k:Int )
  {
    bytes = Data()
    appendBytes(size:size, k:k)
  }
  
  init( data:Data )
  {
    bytes = data
  }
  
  required convenience init( size:Int, op:Operand ) {
    self.init()
  }
}

class TypeImm:MachineData
{
  required convenience init( size:Int, op:Operand ) {
    self.init( size:size, k:Int(op.u16value) )
  }
}

class TypeAddr:MachineData, InstDTAbsolute
{
  required convenience init( size:Int, op:Operand ) {
    self.init( size:size, k:Int(op.u16value) )
  }
  
  func setAbsolute( a:UInt16 )
  {
    bytes.removeAll(keepingCapacity:true)
    appendBytes(size:2, k:Int(a))
  }
}

class TypeString:MachineData
{
  required convenience init( size:Int, op:Operand ) {
    self.init( data:op.sym! )
  }
}



// Data list
class MachineDataList
{
  static let allData:Dictionary<DataValue, MachineData.Type> =
  [
    DataValue( 0, OpImm() )  : TypeImm.self,
    DataValue( 0, OpSym() )  : TypeAddr.self,
    DataValue( 0, OpStr() )  : TypeString.self
  ]
  
  static func getMachineData( _ dv:DataValue ) -> MachineData?
  {
    if let machineDataType = allData[dv]
    {
      let machineData = machineDataType.init( size:dv.byteSize, op:dv.oper )
      return machineData
    }
    return nil
  }
  
}
