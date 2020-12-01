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
let _program_memory_prefix = "Program"    // We prefix program memory addresses with this
let _data_memory_prefix = "Data"       // We prefix data memory addresses with this
let _immediate_prefix = "Value"       // We prefix data memory addresses with this

// We consider the following memory banks
enum Bank
{
  case program   // Program memory
  case constant  // Constant datas memory
  case variable  // Initialized variables memory
  case common    // Uninitialized variables memory
  case imm       // Immediate value (internal use)
  
  // Return a prefix suitable for log purposes
  var prefix:String
  {
    switch self
    {
      case .program:  return _program_memory_prefix   // Program memory
      case .constant: return _data_memory_prefix     // Data memory
      case .variable: return _data_memory_prefix     // Data memory
      case .common:   return _data_memory_prefix       // Data memory
      case .imm:    return ""
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
    source.instructionsOffset = getInstructionsEnd()
    source.constantDatasOffset = getConstantDataEnd()
    source.initializedVarsOffset = getInitializedVarsEnd()
    source.uninitializedVarsOffset = getUninitializedVarsEnd()
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
  
  // Byte count of constant and initialized variables in data memory
  func getDataValueCount() -> Int
  {
    return getConstantDataEnd() + getInitializedVarsEnd()
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
      case .program:  break //value += setupDataLength
      case .constant: break
      case .variable: value += getConstantDataEnd()
      case .common: value += getConstantDataEnd() + getInitializedVarsEnd()
      case .imm: break
    }
    return SymTableInfo( bank:bank, value:value )
  }
  
  //-------------------------------------------------------------------------------------------
  // Insert setup code
  func getInitCode() -> Data
  {
    let code =
    """
      \t.text
      init:
      \t.file "init"
      \tjmp @$setup
    """
    return code.d
  }

  //-------------------------------------------------------------------------------------------
  // Insert setup code
  func getSetupCode() -> Data
  {
    let code =
    """
      \t.text
      \t.file "$setup"
      \t.globl $setup
      $setup:
      \tmov &initialSP, r0
      \tmov r0, SP
      \tmov @setupAddr, r1    # program memory
      \tmov &dataAddr, r2     # data memory
      \tmov &wordLength, r0   # counter
      .LL0:
      \tcmp.eq r0, 0
      \tbrcc .LL1
      \tld.w {r1}, r3
      \tst.w r3, [r2, 0]
      \tadd r1, 1, r1
      \tadd r2, 2, r2
      \tsub r0, 1, r0
      \tjmp .LL0
      .LL1:
      \tcall @main
      \thalt
    """
    return code.d
  }
  
  //-------------------------------------------------------------------------------------------
  // Insert setup code
  func getSimpleSetupCode() -> Data
  {
    let code =
    """
      \t.text
      \t.file "$setup"
      \t.globl $setup
      $setup:
      \tmov &initialSP, r0
      \tmov r0, SP
      \tcall @main
      \thalt
    """
    return code.d
  }

  //-------------------------------------------------------------------------------------------
  // Initialize symbols for the setup code
  func insertSetupSymbols()
  {
    //let setup = sources[0]
    let setup = sources.last!
    
    setup.localSymTable["initialSP".d] = SymTableInfo(bank:.imm, value:-256)
    setup.localSymTable["setupAddr".d] = SymTableInfo(bank:.imm, value:0)
    setup.localSymTable["dataAddr".d] = SymTableInfo(bank:.imm, value:0)
    setup.localSymTable["wordLength".d] = SymTableInfo(bank:.imm, value:0)
  }
  
  
  //-------------------------------------------------------------------------------------------
  // Optimize immediates by expanding or shringking into the minimal possible instruction
  func optimizeImmediates() -> Bool
  {
    //let setup = sources[0]
    let setup = sources.last!
    setup.localSymTable["setupAddr".d]?.value = getInstructionsEnd()
    setup.localSymTable["dataAddr".d]?.value = 0
    setup.localSymTable["wordLength".d]?.value = getDataValueCount()/2 //  (getConstantDataEnd() + getInitializedVarsEnd()) / 2
  
    // Replace instructions that must be optimized
    
    var madeChange = false
    for j in 0..<sources.count
    {
      let source = sources[j]
      var memIdx = 0
      for inst in source.instructions
      {
        //var aa = 0
        let instSize = inst.size
        let theInst = inst.mcInst as? InstWithImmediate
        
        // We are only interested on intructions with
        // relative offsets or absolute values/addresses
        // Use the `isDisjoint(with:)` method to test whether a set has any elements
        ///   in common with another set
        if ( theInst != nil && theInst!.refKind.isDisjoint(with:[.relative, .absolute]) == false )
        {
          var here = 0;
          if theInst!.refKind.contains(.relative) {
            here =  source.instructionsOffset + memIdx + instSize } // add instSize because the PC always points to the next instruction
          
          var inCoreRange = false
          if let op = inst.immOp
          {
            let aa = op.value
            inCoreRange = theInst!.inRange(op.value)
            out.log( "Optimizing: \(op.value), Value: \(aa)" )
          }
          else
          {
            // Compute the destination address
            assert( inst.symOp != nil, "Instruction should have a symOp" )
          
            var aa = 0
            let op = inst.symOp!
            if let symInfo = getMemoryAddress(sym: op.sym!, src:source) {
              aa = symInfo.value + op.value - here }
            // Get the acceptable range for this instruction
            inCoreRange = theInst!.inRange(aa)
            out.log( "Optimizing: \((op.sym?.s)!), Value: \(aa)")
          }
          
          // Replace the instruction if appropiate
          
          if ( inst.hasPfix && inCoreRange ) { inst.hasPfix = false }
          else if ( !inst.hasPfix && !inCoreRange ) {inst.hasPfix = true }
          let instSizeDif = inst.size - instSize

          out.logln( ", \(instSizeDif != 0 ? "" : "(no change)" ) " )

          // Did we replace the instruction?
          if instSizeDif != 0
          {
            // The size of a new instruction is different from the old one, so we need
            // to update this source size and correct all following source offsets.
            // This is not perfect because it won't acount for absolute references
            // whithin the same source, but it will reduce the total
            // number of replacement iterations
            madeChange = true
            source.instructionsEnd += instSizeDif
            for k in stride(from:j+1, to:sources.count, by:1) {
              sources[k].instructionsOffset += instSizeDif }
          }
        }
        
        memIdx += instSize
      }
    }
    
    // Return early if we did not make changes
    if ( !madeChange ) {
      return false }
    
   // Compute symbol values
   
    /* FIX ME:
    This is quite an uneficient way of doing it. It would be better to maintain
    a sequential array of SymInfos, with the symbol tables only pointing
    to element indexes in the array. This way we could quickly update
    the symInfo values without having to touch the symboltables at all
    */
    for j in 0..<sources.count
    {
      let source = sources[j]
      var memIdx = 0
      
      for inst in source.instructions
      {
        if inst.labels != nil
        {
          for label in inst.labels!
          //if let label = inst.label
          {
            var symInfo = source.localSymTable[label]
            if symInfo == nil { symInfo = globalSymTable[label] }
          
            if symInfo == nil {
              out.exitWithError( "\(source.shortName.s).s Unresolved symbol: " + label.s ) }
          
            out.log( "Replacing: \(label.s), Value: \(symInfo!.value)" )
          
            switch symInfo!.bank
            {
              case .program  : symInfo!.value = memIdx + source.instructionsOffset
              default : out.exitWithError( "Unsuported bank (5)" )
            }
          
            out.logln( "...New Value: \(symInfo!.value)" )
          }
        }
        memIdx += inst.size
      }
      
      //source.instructionsEnd = memIdx
    }
    return true
  }
  
  //-------------------------------------------------------------------------------------------
  // Append setup data as the final source
  func appendSetupData()
  {
    assert( getConstantDataEnd() + getInitializedVarsEnd() == dataMemory.count, "Data Memory size mismatch" )
    
    let setupSrc = Source()
    addSource(setupSrc)
    
    setupSrc.name = "setupData".d
    setupSrc.shortName = "setupData".d
    
    // Insert data to copy
    for i in stride(from:0, to:dataMemory.count, by:2)
    {
      let value:Int = Int(dataMemory[i]) | Int(dataMemory[i+1]) << 8
      
      let inst = Instruction( "_imm".d, [OpImm(value)] )
      setupSrc.addInstruction( inst )
      
      if ( inst.mcInst == nil ) {
        out.exitWithError( "\(setupSrc.shortName.s) Unrecognised Instruction Pattern: " + String(reflecting:inst) ) }
    }
  }
  
  //-------------------------------------------------------------------------------------------
  // Assemble a single Source object
  func assembleProgram(source:Source) -> Bool
  {
    // Iterate the Instructions array
    out.log( "\nSource: " )
    out.logln( source.name.s )
    out.logisimLog( "\nSource: " )
    out.logisimLogln( source.name.s )
    
    // Memory index
    var memIdx = 0;

    // Iterate all instructions
    for inst in source.instructions
    {
      // Get an unique match of the Instruction as a MachineInstruction
      let mcInst = inst.mcInst;

      // Bail out entirelly it no suitable match was found
      if ( mcInst == nil ) {
        out.exitWithError( "\(source.shortName.s).s Very very bad, still here with unrecognised Instruction Pattern: " + String(reflecting:inst) )
        return false
      }
      
      // Get the instruction as an InstWithImmediate,
      // so we can replace references or prefixed immediates
      let theInst = mcInst as? InstWithImmediate
      
      // Account for possible prefixed instruction
      var thePrefix:TypeP? = nil
      if let op = inst.exOperand
      {
        thePrefix = TypeP( op:0b11111, ops:[op], rk:[] )
        thePrefix!.setPrefixValue(a:op.value, inst:theInst)   // Set the prefix address bits
        theInst?.setPrefixedValue(a:op.value)   // Update the prefixed immediate
      }
      
      // Initialize some variables.
      // These are used only for log purposes
      var isRelative = false
      var isImmediate = false
      var aa:Int? = nil
      var bankStr = ""
      
      // If we have references we need to replace them by actual values
      if ( theInst != nil && theInst!.refKind.isDisjoint(with:[.relative, .absolute]) == false )
      {
        var here = 0;
        var a16:UInt16 = 0
        
        // Compute the base address for relative references
        if theInst!.refKind.contains(.relative)
        {
          isRelative = true
          here = source.instructionsOffset + memIdx + /*pfixOffs + 1*/ inst.size // add inst.size because the PC always points to the next instruction
        }
        
        if let op = inst.immOp
        {
          aa = op.value
          isImmediate = true
        }
        else
        {
          assert( inst.symOp != nil, "Instruction should have a symOp" )
          // Compute the destination address
          let op = inst.symOp!
          if let symInfo = getMemoryAddress(sym: op.sym!, src:source)
          {
            bankStr = symInfo.bank.prefix
            aa = symInfo.value + op.value - here
          }
          else
          {
            out.exitWithError( "\(source.shortName.s).s Unresolved symbol: " + op.sym!.s )
            return false
          }
        }
        
        // If we have a prefix update its value now
        if ( thePrefix != nil )
        {
          assert( inst.hasPfix, "Too bad, the current instruction should not be prefixed!" )
          thePrefix!.setPrefixValue(a:aa!, inst:theInst)   // Set the prefix address bits
          theInst!.setPrefixedValue(a:aa!)   // Set the instrucion address bits
        }
        else
        {
          assert( !inst.hasPfix, "Too bad, the current instruction should follow a prefix!" )
          theInst!.setCoreValue(a:aa!)  // Set the instrucion address bits
        }
      }
      
      // Get the resulting machine instruction encoding
      let prefixEncoding = thePrefix?.encoding
      let encoding = mcInst!.encoding
      
      func appendToMemory( encoding:UInt16 )
      {
        let loByte = UInt8(truncatingIfNeeded:(encoding & 0xff))
        let hiByte = UInt8(truncatingIfNeeded:(encoding >> 8))
        programMemory.append(loByte)
        programMemory.append(hiByte)
        memIdx += 1
      }
      
      if (prefixEncoding != nil ) { appendToMemory(encoding: prefixEncoding!) }
      appendToMemory(encoding: encoding)
    
      // Debug log stuff...
      if out.logEnabled
      {
        func logStuff( inst:Instruction?, encoding:UInt16,  addr:Int)
        {
          let str = String(encoding, radix:2) //binary base
          let padd = String(repeating:"0", count:(16 - str.count))
          
          let prStrHead = String(format:"%05d: %@%@ (%04X) ", addr, padd, str, encoding)
          //let prStrHead = String(format:"%05d (%04X) : %@%@ (%04X) ", addr, addr, padd, str, encoding)
          let prStrLogisimHead = String(format:"%04X: %05d: (%04X) ", addr, addr, encoding)
          var prStrInst = (inst != nil ? String(reflecting:inst!) : String(format:"_pfix %d", aa!))
          
          if ( aa != nil && isRelative)  { prStrInst += String(format:"  %@:%+d", bankStr, aa!) }
          if ( aa != nil && !isRelative && !isImmediate ) { prStrInst += String(format:"  %@:%05d", bankStr, aa!) }
          out.log( prStrHead ); out.logln( prStrInst )
          out.logisimLog( prStrLogisimHead ); out.logisimLogln( prStrInst )
        }
        
        if ( prefixEncoding != nil ) { logStuff( inst:nil, encoding:prefixEncoding!, addr:programMemory.count/2-2 ) }
        logStuff( inst:inst, encoding:encoding, addr:programMemory.count/2-1 )
      }
    }
    
    // We are done
    return true
  }

  //-------------------------------------------------------------------------------------------
  // Assemble a single DataValue
  func assembleSingleDataValue(datav:DataValue, source:Source) -> Bool
  {
    // Find the unique match of the DataValue to a MachineData
    let mcData:MachineData? = MachineDataList.newMachineData(datav)
    if ( mcData == nil ) {
      out.exitWithError( "Unrecognised Data Value Pattern: " + String(reflecting:datav) )
      return false
    }
  
    // Initialize some state variables
    var aa:Int? = nil
    var bankStr = ""
    
    // Check whether the data value needs a symbol replacement
    if let mcDataAbs = mcData as? TypeAddr
    {
      let op = datav.symOp!
      if let symInfo = getMemoryAddress(sym: op.sym!, src:source)
      {
        bankStr = symInfo.bank.prefix
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
      var prStr = String(format:"%05d (%04X) : ", dataMemory.count, dataMemory.count)
      for i in 0..<bytes.count
      {
        let byte:UInt8 = bytes[i]
        if i > 0 { prStr.append(",") }
        prStr += String(format:"0x%02x", byte)
      }
      prStr.append( "  " /*+ bankStr*/ + String(reflecting:datav) )
      if mcData!.value != nil { prStr += String(format:"  %@:%d", bankStr, mcData!.value!) }
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
      if !assembleSingleDataValue(datav:datav, source:source) { break } }
    
    return true
  }
 
  //-------------------------------------------------------------------------------------------
  // Assemble all iniitalized DataValues
  func assembleVariableData(source:Source) -> Bool
  {
    // Iterate all initialized DataValues
    for datav in source.initializedVars {
      if !assembleSingleDataValue(datav:datav, source:source) { break } }
    
    return true
  }
 
  //-------------------------------------------------------------------------------------------
  // Assemble all available DataValues
  func assembleData()
  {
    // Generate constant data
    
    out.logln( "\nConstant Data:" )
    for source in sources {
      if !assembleConstantData(source:source) { break }
    }
    
    if out.logEnabled && getConstantDataEnd() == 0
    {
      let prStr = String(format:"%05d : %d bytes", 0, 0)
      out.logln( prStr )
    }
  
    assert( dataMemory.count == getConstantDataEnd(),
            "Data memory length should be equal to constant data end" )

    // Generate initialized vars
    
    out.logln( "\nInitialised Variables:" )
    for source in sources {
      if !assembleVariableData(source:source) { break }
    }
    
    if out.logEnabled && getInitializedVarsEnd() == 0
    {
      let prStr = String(format:"%05d : %d bytes", 0, 0)
      out.logln( prStr )
    }
  
    assert( dataMemory.count == getConstantDataEnd() + getInitializedVarsEnd(),
            "Data memory length should be equal to initialized vars end" )
  
    // Unitialized variables do not require any machine code, so only some log for them
    out.logln( "\nUnitialised Variables:" )
    if out.logEnabled
    {
      let prStr = String(format:"%05d : %d bytes", getConstantDataEnd()+getInitializedVarsEnd(), getUninitializedVarsEnd() )
      out.logln( prStr )
    }
    
    out.logln()
  }

  //-------------------------------------------------------------------------------------------
  // Assemble all available Sources
  func assembleProgram()
  {
    for source in sources {
      if !assembleProgram(source:source) { break }
    }
  }
  
  //-------------------------------------------------------------------------------------------
  // Assemble all sources
  func assemble()
  {
    insertSetupSymbols()
    while optimizeImmediates() == true { }
  
    out.logln( "-----" )
    out.logln( "Upon machine reset this will be moved to data memory, see setup code below" )
  
    // Invoke the assembler
    assembleData()
    
    appendSetupData()
    
    out.logln( "-----" )
    out.logln( "\(console.destination!.absoluteString)" )
    
    // Invoke the assembler
    assembleProgram()
  }
	
	//-------------------------------------------------------------------------------------------
  // Assemble all sources
  func getLogisimData() -> Data
  {
    var logisimData = Data()
    logisimData.append( "v2.0 raw".d )
		
    for i in stride(from:0, to:programMemory.count, by:2)
    {
      let encoding:Int = Int(programMemory[i]) | Int(programMemory[i+1]) << 8
      logisimData.append( (i % 16 == 0 ? "\n" : " " ).d )
      logisimData.append( String(format:"%x", encoding ).d )
    }
    return logisimData
  }

} // End class Assembler


