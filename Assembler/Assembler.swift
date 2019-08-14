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

// Convenience constants
let _program_memory_prefix = "@"    // We prefix program memory addresses with this
let _data_memory_prefix = "&"       // We prefix data memory addresses with this

// We consider the following memory banks
enum Bank
{
  case program   // Program memory
  case constant  // Constant datas memory
  case variable  // Initialized variables memory
  case common    // Uninitialized variables memory
  
  // Return a prefix suitable for log purposes
  var prefix:String
  {
    switch self
    {
      case .program: return _program_memory_prefix   // Program memory
      case .constant: return _data_memory_prefix     // Data memory
      case .variable: return _data_memory_prefix     // Data memory
      case .common: return _data_memory_prefix       // Data memory
    }
  }
}

// Symbol table stored information. Note that it's declared as a class,
// because we need reference semantics
class SymTableInfo
{
  var bank:Bank
  var value:Int
  
  init( bank b:Bank, value v:Int=0 )
  {
    bank = b
    value = v
  }
}

// Assemble an array of Source objects into memory
class Assembler
{
  // Global symbol table
  var globalSymTable:Dictionary<Data,SymTableInfo> = [:]

  // Convenience constants
  let _program_memory_prefix = "@"    // We prefix program memory addresses with this
  let _data_memory_prefix = "&"       // We prefix data memory addresses with this

  // Source input instances array
  var sources = [Source]()
  
  // Resulting assembly code
  var programMemory = Data()
  var dataMemory = Data()
  
  // Add an input Source object
  func addSource( _ source:Source)
  {
    sources.append(source)
  }
  
  // Absolute address just past the last instruction in program memory
  func getInstructionsEnd() -> Int
  {
    if sources.count > 0 { return sources.last!.getInstructionsEnd() }
    else { return 0 }
  }
  
  // Absolute address just past the last constant data value in data memory
  func getConstantDataEnd() -> Int
  {
    if sources.count > 0 { return sources.last!.getConstantDataEnd() }
    else { return 0 }
  }
  
  // Absolute address just past the last initialized variable in data memory
  func getInitializedVarsEnd() -> Int
  {
    if sources.count > 0 { return sources.last!.getInitializedVarsEnd() }
    else { return 0 }
  }

  // Absolute address just past the last uninitialized variable in data memory
  func getUninitializedVarsEnd() -> Int
  {
    if sources.count > 0 { return sources.last!.getUninitializedVarsEnd() }
    else { return 0 }
  }

  //-------------------------------------------------------------------------------------------
  // Returns a SymTableInfo object with the updated memory address of a symbol in the form of a tuple pair that
  // also includes the suitable memory prefix string for the symbol
  func getMemoryAddress( sym:Data, src:Source ) -> SymTableInfo?
  {
    var symInfo = src.localSymTable[sym]
    if symInfo == nil { symInfo = globalSymTable[sym] }
    if symInfo == nil { return nil }
    
    var value = symInfo!.value
    let bank = symInfo!.bank
    
    switch bank
    {
      case .program: break
      case .constant: break
      case .variable: value += getConstantDataEnd()
      case .common: value += getConstantDataEnd() + getInitializedVarsEnd()
    }
    return SymTableInfo( bank:bank, value:value )
  }

  //-------------------------------------------------------------------------------------------
  // Assemble a single Source object
  func assembleProgram(source:Source) -> Bool
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
        out.exitWithError( "\(source.shortName.s).s Unrecognised Instruction Pattern: " + String(reflecting:inst) )
        return false
      }
      
      // Initialize some state variables
      let here =  source.instructionsOffset + i
      var ra:Int? = nil
      var aa:Int? = nil
      var prefix = ""
      
      // Check whether the instruction needs a relative address symbol replacement
      if let mcrInst = mcInst as? InstPCRelative
      {
        let op = inst.symOp!
        if let symInfo = getMemoryAddress(sym: op.sym!, src:source)
        {
          prefix = symInfo.bank.prefix
          ra = symInfo.value + op.value - here
          mcrInst.setRelative(a:UInt16(truncatingIfNeeded:ra!))
        }
        else
        {
          out.exitWithError( "\(source.shortName.s).s Unresolved relative symbol: " + op.sym!.s )
          return false
        }
      }
        
      // Check whether the instruction needs an absolute address symbol replacement
      else if let mcaInst = mcInst as? InstDTAbsolute
      {
        let op = inst.symOp!
        if let symInfo = getMemoryAddress(sym: op.sym!, src:source)
        {
          prefix = symInfo.bank.prefix
          aa = symInfo.value + op.value
          mcaInst.setAbsolute(a:UInt16(truncatingIfNeeded:aa!))
        }
        else
        {
          out.exitWithError( "\(source.shortName.s).s Unresolved absolute symbol: " + op.sym!.s )
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
  // Assemble a single DataValue
  func assembleSingleDatav(datav:DataValue, source:Source) -> Bool
  {
    // Find the unique match of the DataValue to a MachineData
    let mcData:MachineData? = MachineDataList.newMachineData(datav)
    if ( mcData == nil ) {
      out.exitWithError( "Unrecognised Data Value Pattern: " + String(reflecting:datav) )
      return false
    }
  
    // Initialize some state variables
    var aa:Int? = nil
    var prefix = ""
    
    // Check whether the data value needs a symbol replacement
    if let mcDataAbs = mcData as? InstDTAbsolute
    {
      let op = datav.symOp!
      if let symInfo = getMemoryAddress(sym: op.sym!, src:source)
      {
        prefix = symInfo.bank.prefix
        aa = symInfo.value + op.value
        mcDataAbs.setAbsolute(a:UInt16(truncatingIfNeeded:aa!))
      }
      else
      {
        out.exitWithError( "Unresolved symbol: " + op.sym!.s )
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
  // Assemble all constant DataValues
  func assembleConstantData(source:Source) -> Bool
  {
    // Iterate all constant DataValues
    for datav in source.constantDatas {
      if !assembleSingleDatav(datav:datav, source:source) { break }
    }
    
    return true
 }
 
  //-------------------------------------------------------------------------------------------
  // Assemble all iniitalized DataValues
  func assembleVariableData(source:Source) -> Bool
  {
    // Iterate all initialized DataValues
    for datav in source.initializedVars {
      if !assembleSingleDatav(datav:datav, source:source) { break }
    }
    
    return true
 }

  //-------------------------------------------------------------------------------------------
  // Assemble all available Sources and DataValues
  func assembleAll()
  {
    out.logln( "\nProgram Code:" )
    
    for source in sources {
      if !assembleProgram(source:source) { break }
    }
    
    out.logln( "\nConstant Data:" )
    for source in sources {
      if !assembleConstantData(source:source) { break }
    }

    out.logln( "\nInitialized Variables:" )
    for source in sources {
      if !assembleVariableData(source:source) { break }
    }
    
    // Unitialized variables do not require any machine code
    
    // Debug log stuff...
    if out.logEnabled
    {
      out.logln( "\nUnitialized Variables:" )
      let prStr = String(format:"%05d : %d bytes", getConstantDataEnd()+getInitializedVarsEnd(), getUninitializedVarsEnd() )
      out.logln( prStr )
    }
  }
}


