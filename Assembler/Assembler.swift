//
//  Assembler.swift
//  c74-as
//
//  Created by Joan on 28/06/19.
//  Copyright © 2019 Joan. All rights reserved.
//

import Foundation

//-------------------------------------------------------------------------------------------
// Assembler
//-------------------------------------------------------------------------------------------

// Assemble an array of Source objects into memory
class Assembler
{
  // Convenience constants
  let _program_memory_prefix = "@"    // We prefix program memory addresses with this
  let _data_memory_prefix = "&"       // We prefix data memory addresses with this

  // Source input instances array
  var sources = [Source]()
  
  // Public symbols pointing to addresses in program memory
  var progSyms:Dictionary<Data,Int> = [:]
  
  // Constant data in data memory such as constant strings and jump tables
  var constantDatas = [DataValue]()
  var constantDataSyms:Dictionary<Data,Int> = [:]
  var constantDataEnd:Int = 0
  
  // Initialized global variables in data memory
  var initializedVars = [DataValue]()
  var initializedVarsSyms:Dictionary<Data,Int> = [:]  // Public symbols pointing to addresses in data memory
  var initializedVarsEnd:Int = 0

  // Uninitialized global variables in data memory
  var uninitializedVarsSyms:Dictionary<Data,Int> = [:]  // Public symbols pointing to addresses in data memory
  var uninitializedVarsEnd:Int = 0
  
  // Resulting assembly code
  var programMemory = Data()
  var dataMemory = Data()
  
  // Add an input Source object
  func addSource( _ source:Source)
  {
    sources.append(source)
  }
  
  // Returns the memory address of the next instruction in program memory
  func getProgEnd() -> Int
  {
    if sources.count > 0 { return sources.last!.getEnd() }
    else { return 0 }
  }
  
  // Appends a DataValue at the end of the constant datas array
  func addConstantData( _ value:DataValue )
  {
    constantDatas.append(value)
    constantDataEnd += value.byteSize
  }
  
  // Adds padding to account for an aligment requirement on constant data
  func p2AlignConstantData( _ value:Int )
  {
    while constantDataEnd & ~(~0<<value) != 0 {
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
  func addUninitializedVar( name:Data, size:Int, align:Int  )
  {
    uninitializedVarsEnd += uninitializedVarsEnd % align
    uninitializedVarsSyms[name] = uninitializedVarsEnd
    uninitializedVarsEnd += size
  }
  
  // Returns the program memory address of a symbol in the form of a tuple pair that
  // also includes the suitable memory prefix string for the symbol
  func getProgramAddress( sym:Data ) -> (String, Int)?
  {
    if let a = progSyms[sym] { return (_program_memory_prefix, a) }
    return nil
  }
  
  // Returns the memory address of a symbol in the form of a tuple pair that
  // also includes the suitable memory prefix string for the symbol
  func getMemoryAddress( sym:Data ) -> (String, Int)?
  {
    if let a = constantDataSyms[sym] { return (_data_memory_prefix, a) }
    if let a = initializedVarsSyms[sym] { return (_data_memory_prefix, constantDataEnd + a) }
    if let a = uninitializedVarsSyms[sym] { return (_data_memory_prefix, constantDataEnd + initializedVarsEnd + a) }
    if let a = progSyms[sym] { return (_program_memory_prefix, a) }
    return nil
  }
  
  //-------------------------------------------------------------------------------------------
  // Assemble a single Source object
  func assemble(source:Source) -> Bool
  {
    // Iterate the Instructions array
    out.log( "\nSource: " )
    out.logln( source.name.s )
    for i in 0..<source.instructions.count
    {
      // Find the unique match of the Instruction to a MachineInstruction
      let inst = source.instructions[i]
      let mcInst = MachineInstrList.newMachineInst(inst)
      if ( mcInst == nil ) {
        out.printError( "\(source.shortName.s).s Unrecognised Instruction Pattern: " + String(reflecting:inst) )
        return false
      }
      
      // Initialize some state variables
      let here =  source.offset + i
      var ra:Int? = nil
      var aa:Int? = nil
      var prefix = ""
      
      // Check whether the instruction needs a relative address symbol replacement
      if let mcrInst = mcInst as? InstPCRelative
      {
        let op = inst.symOp!
        if let (pf, a) = getProgramAddress(sym: op.sym!)
        {
          prefix = pf
          ra = a + op.value - here
          mcrInst.setRelative(a:UInt16(truncatingIfNeeded:ra!))
        }
        else
        {
          out.printError( "\(source.shortName.s).s Unresolved relative symbol: " + op.sym!.s )
          return false
        }
      }
        
      // Check whether the instruction needs an absolute address symbol replacement
      else if let mcaInst = mcInst as? InstDTAbsolute
      {
        let op = inst.symOp!
        if let (pf, a) = getMemoryAddress(sym: op.sym!)     // to do: implement absolute program syms
        {
          prefix = pf
          aa = a + op.value
          mcaInst.setAbsolute(a:UInt16(truncatingIfNeeded:aa!))
        }
        else
        {
          out.printError( "\(source.shortName.s).s Unresolved absolute symbol: " + op.sym!.s )
          return false
        }
      }

      // Get the resulting machine instruction encoding
      let encoding = mcInst!.encoding
      
      // Debug log stuff...
      if out.logEnabled
      {
        let str = String(encoding, radix:2) //binary base
        let padd = String(repeating:"0", count:(16 - str.count))
        var prStr = String(format:"%05d : %@%@  %@", programMemory.count/2, padd, str, String(reflecting:inst) )
        if ( ra != nil) { prStr += String(format:"  %@Value:%+d", prefix, ra!) }
        if ( aa != nil) { prStr += String(format:"  %@Value:%05d", prefix, aa!) }
        out.logln( prStr )
      }
      
      // Append the machine instruction encoding to program memory in a little endian format
      let loByte = UInt8(truncatingIfNeeded:(encoding & 0xff))
      let hiByte = UInt8(truncatingIfNeeded:(encoding >> 8))
      programMemory.append(loByte)
      programMemory.append(hiByte)
    }
  
    // We are done
    return true
  }
  
  //-------------------------------------------------------------------------------------------
  // Assemble a single DataValues
  func assemble(datav:DataValue) -> Bool
  {
    // Find the unique match of the DataValue to a MachineData
    let mcData:MachineData? = MachineDataList.newMachineData(datav)
    if ( mcData == nil ) {
      out.printError( "Unrecognised Data Value Pattern: " + String(reflecting:datav) )
      return false
    }
  
    // Initialize some state variables
    var aa:Int? = nil
    var prefix = ""
    
    // Check whether the data value needs a symbol replacement
    if let mcDataAbs = mcData as? InstDTAbsolute
    {
      let op = datav.symOp!
      if let (pf, a) = getMemoryAddress(sym: op.sym!)
      {
        prefix = pf
        aa = a + op.value
        mcDataAbs.setAbsolute(a:UInt16(truncatingIfNeeded:aa!))
      }
      else
      {
        out.printError( "Unresolved symbol: " + op.sym!.s )
        return false
      }
    }
    
    // Get the resulting data encoding
    let bytes:Data = mcData!.bytes
    
    // Debug log stuff...
    if out.logEnabled
    {
      var prStr = String(format:"%05d : ", dataMemory.count)
      for i in 0..<bytes.count
      {
        let byte:UInt8 = bytes[i]
        if i > 0 { prStr.append(",") }
        prStr += String(format:"0x%02x", byte)
      }
      prStr.append( "  " + prefix + String(reflecting:datav) )
      if mcData!.value != nil { prStr += String(format:"  %@Value:%d", prefix, mcData!.value!) }
      out.logln( prStr )
    }
    
    // Append the machine instruction encoding to data memory
    dataMemory.append(bytes)
    
    // We are done
    return true
  }

//-------------------------------------------------------------------------------------------
// Assemble all available Sources and DataValues
  func assembleAll()
  {
    // Iterate all Sources
    out.logln( "\nProgram Code:" )
    for source in sources {
      if !assemble(source:source) { break }
    }
    
    // Iterate all constant DataValues
    out.logln( "\nConstant Data:" )
    for datav in constantDatas {
      if !assemble(datav:datav) { break }
    }
    
    // Iterate all initialized DataValues
    out.logln( "\nInitialized Variables:" )
    for datav in initializedVars {
      if !assemble(datav:datav) { break }
    }
    
    // Unitialized variables do not require any machine code
    //
    
    // Debug log stuff...
    if out.logEnabled
    {
      out.logln( "\nUnitialized Variables:" )
      let prStr = String(format:"%05d : %d bytes", constantDataEnd+initializedVarsEnd, uninitializedVarsEnd )
      out.logln( prStr )
    }
  }
}



