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

  var instructionsOffset = 0            // Offset of this object in program memory
  var instructions = [Instruction]()    // Instructions array
  
  var constantDatasOffset = 0           // Offset of this object's constant data values in memory
  var constantDatasEnd = 0              // Contant data memory size
  var constantDatas = [DataValue]()     // Constant datas array
  
  var initializedVarsOffset = 0         // Offset of this object's initialized vars in memory
  var initializedVarsEnd = 0            // Initialized vars memory size
  var initializedVars = [DataValue]()   // Initialized vars array
  
  var uninitializedVarsOffset = 0       // Offset of this object's uninitialized vars in memory
  var uninitializedVarsEnd = 0          // Uninitialized vars memory size
  
  var localSymTable:Dictionary<Data,SymTableInfo> = [:]    // Local symbol table
  
  // Absolute address just past the last instruction in program memory
  func getInstructionsEnd() -> Int {
    return instructionsOffset + instructions.count
  }
  
  // Absolute address just past the last constant data value in data memory
  func getConstantDataEnd() -> Int {
    return constantDatasOffset + constantDatasEnd
  }
  
  // Absolute address just past the last initialized variable in data memory
  func getInitializedVarsEnd() -> Int {
    return initializedVarsOffset + initializedVarsEnd
  }
  
  // Absolute address just past the last uninitialized variable in data memory
  func getUninitializedVarsEnd() -> Int {
    return uninitializedVarsOffset + uninitializedVarsEnd
  }
  
  // Appends a DataValue at the end of the constant datas array
  func addConstantData( _ value:DataValue )
  {
    constantDatas.append(value)
    constantDatasEnd += value.byteSize
  }
  
  // Adds padding to account for an aligment requirement on constant data
  func p2AlignConstantData( _ value:Int )
  {
    while constantDatasEnd & ~(~0<<value) != 0 {
      addConstantData( DataValue( 1, OpImm(0) ) )
    }
  }
  
  // Appends a DataValue at the end of the initialized variables array
  func addInitializedVar( _ value:DataValue )
  {
    initializedVars.append(value)
    initializedVarsEnd += value.byteSize
  }
  
  // Adds padding to account for an aligment requirement on initialized variables
  func p2AlignInitializedVar( _ value:Int )
  {
    while initializedVarsEnd & ~(~0<<value) != 0 {
      addInitializedVar( DataValue( 1, OpImm(0) ) )
    }
  }
  
  // Adds a memory slot for an unitialized variable
  func addUninitializedVar( size:Int, align:Int  )
  {
    uninitializedVarsEnd += uninitializedVarsEnd % align
    uninitializedVarsEnd += size
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
