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

class Operand : CustomDebugStringConvertible
{
  let value:Int
  let sym:Data?
  let indirect:Bool
  let extern:Bool
  
  var debugDescription: String { return "(no description)" }
  var u8value:UInt8 { return UInt8(truncatingIfNeeded:value) }
  var u16value:UInt16 { return UInt16(truncatingIfNeeded:value) }
  var u32value:UInt32 { return UInt32(truncatingIfNeeded:value) }
  
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
  
//  convenience init ( _ v:Int )
//  {
//    self.init( v, nil, ind:false, ext:false )
//  }
  
  convenience init ( ind b:Bool )
  {
    self.init( 0, nil, ind:b, ext:false )
  }
  
//  convenience init ( _ v:Int, ind b:Bool=false )
//  {
//    self.init( v, nil, ind:b, ext:false )
//  }
  
  convenience init ( _ s:Data?, ind b:Bool=false, ext e:Bool=false)
  {
    self.init( 0, s, ind:b, ext:e )
  }
  
  convenience init ( _ v:Int, ind b:Bool=false, ext e:Bool=false)
  {
    self.init( v, nil, ind:b, ext:e )
  }
  
//  convenience init ( _ s:Data?, ind b:Bool, ext e:Bool )
//  {
//    self.init( 0, s, ind:b, ext:e )
//  }
}

class OpReg : Operand
{
  override var debugDescription: String { return "r\(value)" }
}

class OpRSP : OpReg
{
  override var debugDescription: String { return "SP" }
}

class OpImm : Operand
{
  override var debugDescription: String { return "\(value)" }
}

class OpSym : Operand
{
  override var debugDescription: String
  {
    if sym != nil { return String(data:sym!, encoding:.ascii)! }
    return "nil"
  }
}

class OpStr : Operand
{
  override var debugDescription: String
  {
    //if sym != nil { return String(describing:sym!.s) }  //   { String(data:sym!, encoding:.ascii)! }
    if sym != nil { return String(reflecting:sym!.s) }  //   { String(data:sym!, encoding:.ascii)! }
    return "(null)"
  }
}

//-------------------------------------------------------------------------------------------
// Instruction
//-------------------------------------------------------------------------------------------

class Instruction : Hashable, CustomDebugStringConvertible
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

////-------------------------------------------------------------------------------------------
//// Function
////-------------------------------------------------------------------------------------------
//
//class FunctionNO
//{
//  var name:Data
//  var offset:Int
//  var instructions:[Instruction] = []
//  
//  init( _ n:Data, _ o:Int)
//  {
//    name = n
//    offset = o
//  }
//  
//  func getCount() -> Int
//  {
//    return instructions.count
//  }
//  
//  func getEnd() -> Int
//  {
//    return offset + instructions.count
//  }
//}


//-------------------------------------------------------------------------------------------
// Source
//-------------------------------------------------------------------------------------------

class Source
{
  var name = Data()            // Source name
  var shortName = Data()       // Source name with no extension
  var offset = 0
  var instructions:[Instruction] = []
  //var privSyms:Dictionary<Data,Int> = [:]  // Private symbols pointing to program memory
  
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
// DataValue
//-------------------------------------------------------------------------------------------

class DataValue : Hashable, CustomDebugStringConvertible
{
  let byteSize:Int
  var oper:Operand
  
  var hashValue: Int
  {
      return ObjectIdentifier(type(of:oper)).hashValue
      //return bitSize
     // return name.hashValue
  }

  static func == (lhs: DataValue, rhs: DataValue) -> Bool
  {
    //if !(lhs.name == rhs.name ) { return false }
    //if !( lhs.bitSize == rhs.bitSize ) { return false }
    if !( type(of:lhs.oper) == type(of:rhs.oper) ) { return false }
    if !( lhs.oper.indirect == rhs.oper.indirect ) { return false }
    
    return true
  }
  
  var debugDescription: String
  {
    //var str = String(data:name, encoding:.ascii)!

    var str = String(format:"i%0d ", byteSize*8 )
    let isIndirect = oper.indirect
    if isIndirect { str.append( "[" ) }
    //str.append( String(describing:oper) )
    str.append( String(reflecting:oper) )
    if isIndirect { str.append( "]" ) }
    return str
  }
  
  var sym:Data?
  {
    if oper is OpSym { return oper.sym }
    return nil
  }
  
  init( _ s:Int, _ op:Operand )
  {
    byteSize = s
    oper = op
  }
}


//-------------------------------------------------------------------------------------------
// Assembler
//-------------------------------------------------------------------------------------------

class Assembler
{
  var sources = [Source]()
  var progSyms:Dictionary<Data,Int> = [:]  // Public symbols pointing to addresses in program memory
  
  // Constant data such as constant strings and jump tables
  var constantDatas = [DataValue]()
  var constantDataSyms:Dictionary<Data,Int> = [:]
  var constantDataEnd:Int = 0
  
  // Initialized global variables
  var initializedVars = [DataValue]()
  var initializedVarsSyms:Dictionary<Data,Int> = [:]  // Public symbols pointing to addresses in data memory
  var initializedVarsEnd:Int = 0

  // Uninitialized global variables
  //var uninitializedVars = [DataValue]()
  var uninitializedVarsSyms:Dictionary<Data,Int> = [:]  // Public symbols pointing to addresses in data memory
  var uninitializedVarsEnd:Int = 0
  
  var programMemory = Data()
  var dataMemory = Data()
  
  //-------------------------------------------------------------------------------------------
  func addSource( _ source:Source)
  {
    sources.append(source)
  }
  
  //-------------------------------------------------------------------------------------------
  func getProgEnd() -> Int
  {
    if sources.count > 0 { return sources.last!.getEnd() }
    else { return 0 }
  }
  
  //-------------------------------------------------------------------------------------------
  func addConstantData( _ value:DataValue )
  {
    constantDatas.append(value)
    constantDataEnd += value.byteSize
  }
  
  //-------------------------------------------------------------------------------------------
  func p2AlignConstantData( _ value:Int )
  {
    while constantDataEnd & ~(~0<<value) != 0 {
      addConstantData( DataValue( 1, OpImm(0) ) )
    }
  }
  
  //-------------------------------------------------------------------------------------------
  func addInitializedVar( _ value:DataValue )
  {
    initializedVars.append(value)
    initializedVarsEnd += value.byteSize
  }
  
  //-------------------------------------------------------------------------------------------
  func p2AlignInitializedVar( _ value:Int )
  {
    while initializedVarsEnd & ~(~0<<value) != 0 {
      addInitializedVar( DataValue( 1, OpImm(0) ) )
    }
  }
  


  //-------------------------------------------------------------------------------------------
  func addUninitializedVar( name:Data, size:Int, align:Int  )
  {
    uninitializedVarsEnd += uninitializedVarsEnd % align
    uninitializedVarsSyms[name] = uninitializedVarsEnd
    uninitializedVarsEnd += size
  }
  
  //-------------------------------------------------------------------------------------------
  func getAddress( sym:Data ) -> Int?
  {
    if let a = constantDataSyms[sym] { return a }
    if let a = initializedVarsSyms[sym] { return constantDataEnd + a }
    if let a = uninitializedVarsSyms[sym] { return constantDataEnd + initializedVarsEnd + a }
    if let a = progSyms[sym] { return a }
    return nil
  }
  
  //-------------------------------------------------------------------------------------------
  func assemble(source:Source) -> Bool
  {
    #if DEBUG
    out.print( "\nSource: " )
    out.println( source.name.s )
    #endif
    for i in 0..<source.instructions.count
    {
      let inst = source.instructions[i]
      let mcInst = MachineInstrList.getMachineInst(inst)
      
      if ( mcInst == nil ) {
        out.printError( "\(source.name.s) Unrecognised Instruction Pattern: " + String(reflecting:inst) )
        return false
      }
      
      let here =  source.offset + i
      var ra:Int? = nil
      var aa:Int? = nil

      if let mcrInst = mcInst as? InstPCRelative
      {
//        var a = source.privSyms[inst.sym!]
//        if a == nil { a = progSyms[inst.sym!] }
      
        let a = progSyms[inst.sym!]
        if ( a == nil ) {
          out.printError( "\(source.name.s) Unresolved symbol: " + inst.sym!.s )
          return false
        }
  
        ra = a! - here
        mcrInst.setRelative(a:UInt16(truncatingIfNeeded:ra!))
      }
        
      if let mcaInst = mcInst as? InstDTAbsolute
      {
        let a = getAddress(sym: inst.sym!)     // to do: implement absolute program syms
        if ( a == nil ) {
          out.printError( "\(source.name.s) Unresolved symbol: " + inst.sym!.s )
          return false
        }

        aa = a!
        mcaInst.setAbsolute(a:UInt16(truncatingIfNeeded:aa!))
      }

      let encoding = mcInst!.encoding
      
      #if DEBUG
      let str = String(encoding, radix:2) //binary base
      let padd = String(repeating:"0", count:(16 - str.count))
      var prStr = String(format:"%05d : %@%@  %@", programMemory.count/2, padd, str, String(reflecting:inst) )
      if ( ra != nil) { prStr += String(format:"(%+d)", ra!) }
      if ( aa != nil) { prStr += String(format:"(%05d)", aa!) }
      out.println( prStr )
      #endif
      
      let loByte = UInt8(truncatingIfNeeded:(encoding & 0xff))
      let hiByte = UInt8(truncatingIfNeeded:(encoding >> 8))
      programMemory.append(loByte)
      programMemory.append(hiByte)
    }
    
    // todo output append encoding
  
    return true
  }
  
  //-------------------------------------------------------------------------------------------
  func assemble(data:DataValue) -> Bool
  {
    let mcData = MachineDataList.getMachineData(data)
    
    if ( mcData == nil ) {
      out.printError( "Unrecognised Data Value Pattern: " + String(reflecting:data) )
      return false
    }
  
    var aa:Int? = nil
    
    if let mcDataAbs = mcData as? InstDTAbsolute
    {
      let a = getAddress(sym: data.sym!)
      if ( a == nil ) {
        out.printError( "Unresolved symbol: " + data.sym!.s )
        return false
      }

      aa = a!
      mcDataAbs.setAbsolute(a:UInt16(truncatingIfNeeded:aa!))
    }
    
    let bytes = mcData!.bytes
    
    #if DEBUG
    var prStr = String(format:"%05d : %d bytes", dataMemory.count , bytes.count )
    prStr.append( " (" )
    #endif
  
    dataMemory.append(bytes)
    
    #if DEBUG
    for i in 0..<bytes.count
    {
      let byte:UInt8 = bytes[i]
      if i > 0 { prStr.append(", ") }
      prStr.append( String(format:"0x%02x", byte) )
    }
    prStr.append( ") " + String(reflecting:data) )
    out.println( prStr )
    #endif
    
    return true
  }


//-------------------------------------------------------------------------------------------
  func assembleAll()
  {
  
    #if DEBUG
    out.println( "\nProgram Code:" )
    #endif
    for source in sources
    {
      if !assemble(source:source) { break }
    }
    
    #if DEBUG
    out.println( "\nConstant Data:" )
    #endif
    
    for data in constantDatas
    {
      if !assemble(data:data) { break }
    }
    
    #if DEBUG
    out.println( "\nInitialized Variables:" )
    #endif
    
    for data in initializedVars
    {
      if !assemble(data:data) { break }
    }
    
    #if DEBUG
    out.println( "\nUnitialized Variables:" )
    let prStr = String(format:"%05d : %d bytes", constantDataEnd+initializedVarsEnd, uninitializedVarsEnd )
    out.println( prStr )
    #endif
    
  }
}



