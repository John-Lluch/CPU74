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

// Operand attribute flags
struct OpOption: OptionSet
{
  let rawValue:Int
  static let indirect = OpOption(rawValue: 1 << 0)      // Indirect memory addressing
  static let prgIndirect = OpOption(rawValue: 1 << 1)   // Indirect program addressing
  //static let isSP = OpOption(rawValue: 1 << 2)          // SP flag for register operands
  //static let isCC = OpOption(rawValue: 1 << 3)          // flag for condition codes
}

// Base class for assembly instruction operands
class Operand : CustomDebugStringConvertible
{
  let value:Int       // Immediate values or register numbers
  let sym:Data?       // Symbolic addresses or raw string bytes
  var opt:OpOption
  
  // Description string for logging purposes subclases should implement
  var debugDescription: String { return "(no description)" }

  // Other convenience accessors
  var u8value:UInt8 { return UInt8(truncatingIfNeeded:value) }
  var u16value:UInt16 { return UInt16(truncatingIfNeeded:value) }
  var u32value:UInt32 { return UInt32(truncatingIfNeeded:value) }
  
  // Designated initializer
  init ( _ v:Int, _ s:Data?, opt o:OpOption)
  {
    value = v
    sym = s
    opt = o
  }
  
  // Convenience initializers
  
  convenience init () {
    self.init( 0, nil, opt:[] )
  }

  convenience init ( _ o:OpOption ) {
    self.init( 0, nil, opt:o )
  }
  
  convenience init ( _ s:Data?, _ o:OpOption=[] ) {
    self.init( 0, s, opt:o )
  }
  
  convenience init ( _ v:Int, _ o:OpOption=[]) {
    self.init( v, nil, opt:o )
  }
}

// Register operand
class OpReg : Operand
{
  // Description string for logging purposes
  //override var debugDescription: String { return value == 11 ? "SP" : "r\(value)" }
  override var debugDescription: String { return "r\(value)" }
}

class OpSP : OpReg
{
  // Description string for logging purposes
  override var debugDescription: String { return "SP" }
}

// Immediate value operand
class OpImm : Operand
{
  // Description string for logging purposes
  override var debugDescription: String
  {
    return "\(value)"
  }
}

class OpCC : OpImm
{
  // Description string for logging purposes
  override var debugDescription: String
  {
    return [ 0: "eq", 1: "ne", 2: "uge",
               3: "ult", 4: "ge", 5: "lt",
               6: "ugt", 7: "gt" ][value]!
  }
}

// Zero value operand
class OpZero : OpImm
{
}

// Symbolic address operand
class OpSym : Operand
{
  // Description string for logging purposes
  override var debugDescription: String
  {
    if sym != nil { return /*"&" +*/ sym!.s + (value != 0 ? "+\(value)" : "") }
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
  //var label:Data?       // Instruction entry label or nil
  var labels:[Data]?      // Instruction entry labels or nil
  var hasPfix:Bool        // Indicates that this instruction is two words
  var mcInst:MachineInstr?   // Machine Instruction or nil
  
  // Hash stuff for object use as a dictionary key
  var hashValue: Int {
      return name.hashValue }

  // Equal operator implementation for object use as a dictionary key
  static func == (lhs: Instruction, rhs: Instruction) -> Bool
  {
    if !(lhs.name == rhs.name ) { return false }
    if !(lhs.ops.count == rhs.ops.count) { return false }
    
    for i in 0..<lhs.ops.count
    {
      let lhsop = lhs.ops[i]
      let rhsop = rhs.ops[i]
      
      if lhsop.opt != rhsop.opt { return false }
      
      if lhsop is OpZero && rhsop is OpImm { if rhsop.value != 0 {return false} }
      else if lhsop is OpImm && rhsop is OpZero { if lhsop.value != 0 {return false} }
      else if type(of:lhsop) != type(of:rhsop) { return false }
    }
    
    return true
  }
  
  var size: Int
  {
    if hasPfix { return 2 }
    return 1
  }
  
  // Description string for logging purposes
  var debugDescription: String
  {
    var str = String(data:name, encoding:.ascii)!
    var indirect = false
    var prgIndirect = false
    for i in 0..<ops.count
    {
      if i == 0 {str.append(" ") }
      let isIndirect = ops[i].opt.contains(.indirect)
      let isPrgIndirect = ops[i].opt.contains(.prgIndirect)
      if indirect && !isIndirect { str.append( "]" ) }
      if prgIndirect && !isPrgIndirect { str.append( "}" ) }
      if i > 0 { str.append( ", " ) }
      if isIndirect && !indirect { str.append( "[" ) }
      if isPrgIndirect && !prgIndirect { str.append( "{" ) }
      str.append( String(reflecting:ops[i]) )
      indirect = isIndirect
      prgIndirect = isPrgIndirect
    }
    
    if indirect { str.append( "]" ) }
    if prgIndirect { str.append( "}" ) }
    return str
  }
  
  // Return an immediate or symbol operand, subjected to be prefixed, if any
  var exOperand:Operand?
  {
    if !hasPfix { return nil }
    
    for op in ops
    {
      if op is OpSym { return op }
      if op is OpImm && !(op is OpCC) { return op }
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
  
//  // Return the SP operand for this instruction if any
//  var opSP:OpReg?
//  {
//    for op in ops
//    {
//      if let opReg = op as? OpReg {
//        if opReg.opt.contains(.isSP) { return opReg } }
//    }
//    return nil
//  }
  
  // Return the SP operand for this instruction if any
  var opSP:OpReg?
  {
    for op in ops
    {
      if let opSP = op as? OpSP { return opSP }
    }
    return nil
  }
  
  // Designated initializer, zero operands
  init( _ n:Data )
  {
    name = n
    ops = []
    hasPfix = false
  }
  
  func append( label:Data? )
  {
    if label != nil
    {
      if labels != nil { labels!.append(label!) }
      else { labels = [label!] }
    }
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
  var instructionsEnd = 0               // Instructions memory size
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
  var defsTable:Dictionary<Data,Int> = [:] // Register defs table

  // Absolute address just past the last instruction in program memory
  func getInstructionsEnd() -> Int {
    return instructionsOffset + instructionsEnd }

  // Absolute address just past the last constant data value in data memory
  func getConstantDataEnd() -> Int {
    return constantDatasOffset + constantDatasEnd }
  
  // Absolute address just past the last initialized variable in data memory
  func getInitializedVarsEnd() -> Int {
    return initializedVarsOffset + initializedVarsEnd }
  
  // Absolute address just past the last uninitialized variable in data memory
  func getUninitializedVarsEnd() -> Int {
    return uninitializedVarsOffset + uninitializedVarsEnd }
  
  // Appends an Instruction at the end of the instructions array
  func addInstruction( _ instr:Instruction )
  {
    instr.mcInst = MachineInstrList.newMachineInst(instr)
    instructions.append(instr)
    instructionsEnd += instr.size //( instr.hasPfix ? 2 : 1 )
    //instructionsEnd += ( instr.hasExOperand ? 2 : 1 )
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
      addConstantData( DataValue( 1, OpImm(0) ) ) }
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
      addInitializedVar( DataValue( 1, OpImm(0) ) ) }
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
  var hashValue: Int {
      return ObjectIdentifier(type(of:oper)).hashValue }

  // Equal operator implementation for object use as a dictionary key
  static func == (lhs: DataValue, rhs: DataValue) -> Bool
  {
    if !( type(of:lhs.oper) == type(of:rhs.oper) ) { return false }
    if !( lhs.oper.opt == rhs.oper.opt ) { return false }
    
    return true
  }
  
  // Description string for logging purposes
  var debugDescription: String
  {
    var str = String()
    //let isIndirect = oper.indirect
    let isIndirect = oper.opt.contains(.indirect)
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
