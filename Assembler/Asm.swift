//
//  Asm.swift
//  c74-as
//
//  Created by Joan on 28/06/19.
//  Copyright © 2019 Joan. All rights reserved.
//

import Foundation

//-------------------------------------------------------------------------------------------
// Operand
//-------------------------------------------------------------------------------------------

class Operand : CustomStringConvertible
{
  let value:Int
  let sym:Data?
  let indirect:Bool
  var extern:Bool
  
  var description: String { return "(none)" }
  var u16value:UInt16 { return UInt16(truncatingIfNeeded:value) }
  
  init ( _ v:Int, _ s:Data?, ind b:Bool, ext e:Bool )
  {
    value = v
    sym = s
    indirect = b
    extern = e
  }
  
  convenience init ( )
  {
    self.init( 0, nil, ind:false, ext:false )
  }
  
  convenience init ( ind b:Bool )
  {
    self.init( 0, nil, ind:b, ext:false )
  }
  
  convenience init ( _ v:Int, ind b:Bool )
  {
    self.init( v, nil, ind:b, ext:false )
  }
  
  convenience init ( _ s:Data?, ind b:Bool )
  {
    self.init( 0, s, ind:b, ext:false )
  }
  
  convenience init ( _ v:Int, ind b:Bool, ext e:Bool)
  {
    self.init( v, nil, ind:b, ext:e )
  }
  
  convenience init ( _ s:Data?, ind b:Bool, ext e:Bool )
  {
    self.init( 0, s, ind:b, ext:e )
  }
}

class OpReg : Operand
{
  override var description: String { return "r\(value)" }
}

class OpRSP : OpReg
{
  override var description: String { return "SP" }
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

//-------------------------------------------------------------------------------------------
// Instruction
//-------------------------------------------------------------------------------------------

class Instruction : Hashable, CustomStringConvertible
{
  let name:Data
  var needsExOp:Bool
  var ops:[Operand]
  
  var hashValue: Int
  {
      return name.hashValue
  }

  static func == (lhs: Instruction, rhs: Instruction) -> Bool
  {
    if !(lhs.name == rhs.name ) { return false }
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
  
  var exOperand:Operand?
  {
    for op in ops {
      if op.extern { return op }
    }
    return nil
  }
  
  var sym:Data?
  {
    for op in ops {
      if op is OpSym { return op.sym }
    }
    return nil
  }
  
  init( _ n:Data )
  {
    name = n
    needsExOp = false;
    ops = []
  }
  
  convenience init( _ n:Data, _ o:[Operand] )
  {
    self.init( n )
    ops = o
  }
}

//-------------------------------------------------------------------------------------------
// Function
//-------------------------------------------------------------------------------------------

class Function
{
  var name:Data
  var offset:Int
  var instructions:[Instruction] = []
  
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

//-------------------------------------------------------------------------------------------
// Address Label
//-------------------------------------------------------------------------------------------

class DataValue
{
  var name:Data
  var offset:Int
  
  init( _ n:Data, _ o:Int)
  {
    name = n
    offset = o
  }
}

//-------------------------------------------------------------------------------------------
// Source
//-------------------------------------------------------------------------------------------

class Source
{
  var name = Data();            // Source name
  var functions:[Function] = [] // Functions
  var privSyms:Dictionary<Data,Int> = [:]  // Private symbols pointing to program memory
}

//-------------------------------------------------------------------------------------------
// Assembler
//-------------------------------------------------------------------------------------------

class Assembler
{
  var sources = [Source]()
  var progSyms:Dictionary<Data,Int> = [:]  // Public symbols pointing to addresses in program memory
  var dataSyms:Dictionary<Data,Int> = [:]  // Public symbols pointing to addresses in data memory
  
  //-------------------------------------------------------------------------------------------
  func addSource( _ source:Source)
  {
    sources.append(source)
  }

  //-------------------------------------------------------------------------------------------
  func assemble(source:Source) -> Bool
  {
    for fun in source.functions
    {
      #if DEBUG
      out.print( "function: " )
      out.println( fun.name.s )
      #endif
      for i in 0..<fun.instructions.count
      {
        let inst = fun.instructions[i]
        let mcInst = InstrList.getMachineInst(inst:inst)
        
        if ( mcInst == nil ) {
          out.printError( "Unrecognised Instruction Pattern: " + inst.description )
          return false
        }

        let here = fun.offset + i
        var ra:Int? = nil
        var aa:Int? = nil

        if let mcrInst = mcInst as? InstPCRelative
        {
          var a = source.privSyms[inst.sym!]
          if a == nil { a = progSyms[inst.sym!] }
          if ( a == nil ) {
            out.printError( "Unresolved symbol: " + inst.sym!.s )
            return false
          }
  
          ra = a! - here
          mcrInst.setRelative(a:UInt16(truncatingIfNeeded:ra!))
        }
        
        if let mcaInst = mcInst as? InstDTAbsolute
        {
          let a = dataSyms[inst.sym!]
          if ( a == nil ) {
            out.printError( "Unresolved symbol: " + inst.sym!.s )
            return false
          }

          aa = a!
          mcaInst.setAbsolute(a:UInt16(truncatingIfNeeded:aa!))
        }

        #if DEBUG
        let encoding = mcInst!.encoding
        
        let str = String(encoding, radix:2) //binary base
        let padd = String(repeating:"0", count:(16 - str.count))
        var prStr = String(format:"%05d : %@%@  %@", fun.offset+i, padd, str, inst.description )
        if ( ra != nil) { prStr += String(format:"(%+d)", ra!) }
        if ( aa != nil) { prStr += String(format:"(%05d)", aa!) }
        out.println( prStr )
        #endif
      }
    }
    return true
  }

//-------------------------------------------------------------------------------------------
  func assembleAll()
  {
    for source in sources
    {
      if !assemble(source:source) { break }
    }
  }
}



