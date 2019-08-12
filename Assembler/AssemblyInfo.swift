//
//  AssemblyInfo.swift
//  c74-as
//
//  Created by Joan on 28/06/19.
//  Copyright © 2019 Joan. All rights reserved.
//

import Foundation

//-------------------------------------------------------------------------------------------
// Operand
//-------------------------------------------------------------------------------------------

// Base class for assembly instruction operands
class Operand : CustomDebugStringConvertible
{
  let value:Int       // Immediate values or register numbers
  let sym:Data?       // Symbolic addresses or raw string bytes
  let indirect:Bool   // Indirect addressing flag
  let extern:Bool     // External operand flag. Means that it's in the next word rather
                      // than embeeded in the instruction
  
  // Description string for logging purposes subclases should implement
  var debugDescription: String { return "(no description)" }

  // Other convenience accessors
  var u8value:UInt8 { return UInt8(truncatingIfNeeded:value) }
  var u16value:UInt16 { return UInt16(truncatingIfNeeded:value) }
  var u32value:UInt32 { return UInt32(truncatingIfNeeded:value) }
  
  // Designated initializer
  init ( _ v:Int, _ s:Data?, ind b:Bool, ext e:Bool )
  {
    value = v
    sym = s
    indirect = b
    extern = e
  }
  
  // Convenience initializers
  
  convenience init () {
    self.init( 0, nil, ind:false, ext:false )
  }
  
  convenience init ( ind b:Bool ) {
    self.init( 0, nil, ind:b, ext:false )
  }
  
  convenience init ( ext e:Bool ) {
    self.init( 0, nil, ind:false, ext:e )
  }
  
  convenience init ( ind b:Bool, ext e:Bool ) {
    self.init( 0, nil, ind:b, ext:e )
  }
  
  convenience init ( _ s:Data?, ind b:Bool=false, ext e:Bool=false) {
    self.init( 0, s, ind:b, ext:e )
  }
  
  convenience init ( _ v:Int, ind b:Bool=false, ext e:Bool=false) {
    self.init( v, nil, ind:b, ext:e )
  }
  
}

// Register operand
class OpReg : Operand
{
  // Description string for logging purposes
  override var debugDescription: String { return value == 7 ? "sp" : "r\(value)" }
}

// Immediate value operand
class OpImm : Operand
{
  // Description string for logging purposes
  override var debugDescription: String { return extern ? "\(value)L" : "\(value)" }
}

// Symbolic address operand
class OpSym : Operand
{
  // Description string for logging purposes
  override var debugDescription: String
  {
    if sym != nil { return (extern ? "&" : "") + sym!.s + (value != 0 ? "+\(value)" : "") }
    return "(null)"
  }
}

// String operand
class OpStr : Operand
{
  // Description string for logging purposes
  override var debugDescription: String
  {
    if sym != nil { return String(reflecting:sym!.s) }
    return "(null)"
  }
}

//-------------------------------------------------------------------------------------------
// Instruction
//-------------------------------------------------------------------------------------------

// Assembly instruction represented by its name and operands
class Instruction : Hashable, CustomDebugStringConvertible
{
  let name:Data         // Instruction name represented in raw UTF8 bytes
  var ops:[Operand]     // Operands
  
  // Hash stuff for object use as a dictionary key
  var hashValue: Int
  {
      return name.hashValue
  }

  // Equal operator implementation for object use as a dictionary key
  static func == (lhs: Instruction, rhs: Instruction) -> Bool
  {
    if !(lhs.name == rhs.name ) { return false }
    if !(lhs.ops.count == rhs.ops.count) { return false }
    
    for i in 0..<lhs.ops.count
    {
      if !( type(of:lhs.ops[i]) == type(of:rhs.ops[i]) ) { return false }
      if !( lhs.ops[i].indirect == rhs.ops[i].indirect ) { return false }
      if !( lhs.ops[i].extern == rhs.ops[i].extern ) { return false }
    }
    
    return true
  }
  
  // Description string for logging purposes
  var debugDescription: String
  {
    var str = String(data:name, encoding:.ascii)!
    var indirect = false
    for i in 0..<ops.count
    {
      if i == 0 {str.append(" ") }
      let isIndirect = ops[i].indirect
      if indirect && !isIndirect { str.append( "]" ) }
      if i > 0 { str.append( ", " ) }
      if isIndirect && !indirect { str.append( "[" ) }
      str.append( String(reflecting:ops[i]) )
      indirect = isIndirect
    }
    
    if indirect { str.append( "]" ) }
    return str
  }
  
  // Return the external operand of this instruction if any
  var exOperand:Operand?
  {
    for op in ops
    {
      if op.extern { return op }
    }
    return nil
  }
  
  // Return the symbolic operand for this instruction if any
  var symOp:OpSym?
  {
    for op in ops
    {
      if let opSym = op as? OpSym { return opSym }
    }
    return nil
  }
  
  // Designated initializer, zero operands
  init( _ n:Data )
  {
    name = n
    ops = []
  }
  
  // Initialize with operands list
  convenience init( _ n:Data, _ o:[Operand] )
  {
    self.init( n )
    ops = o
  }
}


//-------------------------------------------------------------------------------------------
// Source
//-------------------------------------------------------------------------------------------

// Assembly single source represented by its name and list of instructions
// Instance objects are created and updated by the parser code
class Source
{
  var name = Data()                     // Source name as found by the parser
  var shortName = Data()                // Source name with the extension removed
  var offset = 0                        // Source code offset in program memory
  var instructions:[Instruction] = []   // Instructions array
  
  // Returns the current number of instructions in this source.
  // This essentially tells the memory offset of the next instruction relative to this source
  func getCount() -> Int
  {
    return instructions.count
  }
  
  // Returns the current number of instructions in this source plus the source memory offset
  // This essentially tells the memory address of the next instruction in program memory
  func getEnd() -> Int
  {
    return offset + instructions.count
  }
}


//-------------------------------------------------------------------------------------------
// DataValue
//-------------------------------------------------------------------------------------------

// Assembly data value represented by its size and a single operand
class DataValue : Hashable, CustomDebugStringConvertible
{
  let byteSize:Int             // Size in data memory bytes
  var oper:Operand             // Operand representation of the DataValue
  
  // Hash stuff for object use as a dictionary key
  var hashValue: Int
  {
      return ObjectIdentifier(type(of:oper)).hashValue
  }

  // Equal operator implementation for object use as a dictionary key
  static func == (lhs: DataValue, rhs: DataValue) -> Bool
  {
    if !( type(of:lhs.oper) == type(of:rhs.oper) ) { return false }
    if !( lhs.oper.indirect == rhs.oper.indirect ) { return false }
    
    return true
  }
  
  // Description string for logging purposes
  var debugDescription: String
  {
    var str = String()
    let isIndirect = oper.indirect
    if isIndirect { str.append( "[" ) }
    str.append( String(reflecting:oper) )
    if isIndirect { str.append( "]" ) }
    return str
  }
  
  // Return the symbolic operand for this instruction if any
  var symOp:OpSym?
  {
    if let opSym = oper as? OpSym { return opSym }
    return nil
  }
  
  // Return the single immediate operand for this instruction if any
  var immOp:OpImm?
  {
    if let opImm = oper as? OpImm { return opImm }
    return nil
  }
  
  // Designeated initializer
  init( _ s:Int, _ op:Operand )
  {
    byteSize = s
    oper = op
  }
}
