//
//  Asm.swift
//  c74-as
//
//  Created by Joan on 28/06/19.
//  Copyright © 2019 Joan. All rights reserved.
//

import Foundation


/////////////////////////////////////////////////////////////////
// Operand
/////////////////////////////////////////////////////////////////
class Operand : CustomStringConvertible
{
  let value:Int
  let sym:Data?
  let indirect:Bool
  
  var description: String { return "(none)" }
  
  init ( _ v:Int, _ s:Data?, _ b:Bool )
  {
    value = v
    sym = s
    indirect = b
  }
  
  convenience init ( _ v:Int, _ b:Bool )
  {
    self.init( v, nil, b )
  }
  
  convenience init ( _ b:Bool )
  {
    self.init( 0, nil, b )
  }
  
  convenience init ( _ s:Data?, _ b:Bool )
  {
    self.init( 0, s, b )
  }
}

class OpReg : Operand
{
  override var description: String { return "r\(value)" }
}

class OpImm : Operand
{
  override var description: String { return "\(value)" }
}

class OpSym : Operand
{
  override var description: String
  {
    if sym != nil { return String(data:sym!, encoding:.ascii)! }
    return "nil"
  }
}


/////////////////////////////////////////////////////////////////
// Instruction
/////////////////////////////////////////////////////////////////
class Instruction : Hashable, CustomStringConvertible
{
  let name:Data
  //let altName:Data
  var isBranch:Bool
  var ops:[Operand]
  
  var hashValue: Int
  {
      return name.hashValue //^ altName.hashValue
  }

  static func == (lhs: Instruction, rhs: Instruction) -> Bool
  {
    if !(lhs.name == rhs.name /*|| lhs.altName == rhs.altName*/) { return false }
    if !(lhs.ops.count == rhs.ops.count) { return false }
    
    for i in 0..<lhs.ops.count
    {
      if !( type(of:lhs.ops[i]) == type(of:rhs.ops[i]) ) { return false }
      if !( lhs.ops[i].indirect == rhs.ops[i].indirect ) { return false }
    }
    
    return true
  }
  
  var description: String
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
      str.append( String(describing:ops[i]) )
      indirect = isIndirect
    }
    
    if indirect { str.append( "]" ) }
    return str
  }
  
  init( _ n:Data /*, _ an:Data*/ )
  {
    name = n
    //altName = an
    isBranch = false
    ops = []
  }
  
  init( _ n:Data /*, _ an:Data*/, _ b:Bool, _ o:[Operand] )
  {
    name = n
    //altName = an
    isBranch = b
    ops = o
  }
}

/////////////////////////////////////////////////////////////////
// Function
/////////////////////////////////////////////////////////////////
class Function
{
  var name:Data
  var offset:Int
  var instructions:[Instruction] = []
  //var instrs:[MachineInstr] = []
  
  init( _ n:Data, _ o:Int)
  {
    name = n
    offset = o
  }
  
  func getCount() -> Int
  {
    return instructions.count
  }
  
  func getEnd() -> Int
  {
    return offset + instructions.count
  }
}

/////////////////////////////////////////////////////////////////
// Label
/////////////////////////////////////////////////////////////////
class DataValue
{
  var name:Data
  var offset:Int
  var size:Int
  //var instrs:[MachineInstr] = []
  
  init( _ n:Data, _ o:Int)
  {
    name = n
    offset = o
    size = 0
  }
}


/////////////////////////////////////////////////////////////////
// Source
/////////////////////////////////////////////////////////////////
class Source
{
  var name = Data();            // Source name
  var functions:[Function] = [] // Functions
                                // Global vars
  //var prLabels:[Label] = []     // Private labels pointing to program memory
  //var progSyms:[Label] = []     // Public labels pointing to addresses in program memory
  //var dataSyms:[Label] = []     // Public labels pointing to addresses in data memory
  
  
  var privSyms:Dictionary<Data,Int> = [:]  // Private symbols pointing to program memory
  var progSyms:Dictionary<Data,Int> = [:]  // Public symbols pointing to addresses in program memory
  var dataSyms:Dictionary<Data,Int> = [:]  // Public symbols pointing to addresses in data memory
  
  func assemble()
  {
      for fun in functions
      {
        out.print( "function: " )
        fun.name.dump()
        for ins in fun.instructions
        {
          out.println( ins.description )
        }
      }
  }
}

