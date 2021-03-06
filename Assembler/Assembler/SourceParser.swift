//
//  SourceParser.swift
//  c74-as
//
//  Created by Joan on 28/06/19.
//  Copyright © 2019 Joan. All rights reserved.
//

import Foundation

//-------------------------------------------------------------------------------------------
// Custom class extensions to convert Data objects into Strings and vice-versa
//-------------------------------------------------------------------------------------------

extension String {
  var d:Data { return self.data(using:.utf8)! } }

extension Data {
  var s:String { return String(data:self, encoding:.utf8)! } }

//-------------------------------------------------------------------------------------------
// SourceParser
//-------------------------------------------------------------------------------------------

// Parse a single source file into a Source object
// Update Assembler object symbol tables
class SourceParser:PrimitiveParser
{
  let src:Source           // Destination Source object
  let asm:Assembler        // Destination Assembler object
  var currBank:Bank = .program    // Current memory bank
  var currInst:Instruction?       // Current instruction
  var currLabels:[Data]?          // Current label list

  //-------------------------------------------------------------------------------------------
  // Designated initializer, withData contains the actual source file
  init( withData:Data, source:Source, assembler:Assembler)
  {
    src = source
    asm = assembler
    super.init(withData:withData)
  }
  
  //-------------------------------------------------------------------------------------------
  // Errors just exit the program for now
  func error( _ message:String )
  {
    out.exitWithError( "\(message), file:\(src.shortName.s).s line:\(line)" )
  }
  
  
  //-------------------------------------------------------------------------------------------
  // The following code is a top-down (not particularly recursive) descendant parser
  // implemented by hand. The entry funcion is 'parse()'
  
  //-------------------------------------------------------------------------------------------
  func parseGlobalToken() -> Data?
  {
    if let token = parsePrefixedToken( prefix: "$".d ) { return token }
    if let token = parseToken() { return token }
    return nil
  }
  
  //-------------------------------------------------------------------------------------------
  func parseAddressToken() -> Data?
  {
    if let token = parsePrefixedToken( prefix: ".L".d ) { return token }
    if let token = parsePrefixedToken( prefix: ".L.".d ) { return token }
    if let token = parseGlobalToken() { return token }
    return nil
  }

  //-------------------------------------------------------------------------------------------
  func parseEfectiveAddress() -> (Data,Int)?
  {
    let svc = c
    if let addr = parseAddressToken()
    {
      let data = addr;
      var offset = 0;
      if parseChar( _plus ) {
        if let value = parseAnyInteger() { offset = value } }
      
      return (data,offset)
    }
    
    c = svc
    return nil
  }
  
  //-------------------------------------------------------------------------------------------
  func parseImmediate() -> Int?
  {
    if let value = parseAnyInteger() {
      return value }
    
    return nil
  }
  
  //-------------------------------------------------------------------------------------------
  func parseRegisterOperand( opt:OpOption ) -> Int?
  {
   // Register
   let svsc = c
    if parseChar(UInt8(ascii:"r")) || parseChar(UInt8(ascii:"R"))
    {
      if let value = parseInteger() { return value }
      else { c = svsc }
      //else { error( "Expecting register number" ) }
    }
    
    // Stack pointer
    if parseConcreteToken(cStr: "sp".d) || parseConcreteToken(cStr: "SP".d)
    {
      return 11
    }
    
    return nil
  }
 
  //-------------------------------------------------------------------------------------------
  func parsePrimitiveOperand( opt:OpOption ) -> (Operand, Bool)?
  {
    // Register
    if let regNum = parseRegisterOperand( opt:opt )
    {
       //return (regNum == 11 ? OpReg(regNum, opt.union(.isSP)) : OpReg(regNum, opt) , false)
       return (regNum == 11 ? OpSP(regNum, opt) : OpReg(regNum, opt) , false)
    }
    
    // Absolute address symbol in data memory
    if parseChar( UInt8(ascii:"&") )
    {
      if let (addr, offset) = parseEfectiveAddress() { return (OpSym(offset, addr, opt:opt) , true) }
      else { error( "Expecting efective address" ) }
    }
    
    // Absolute address in program memory (NOT WORKING?)
    if parseChar(UInt8(ascii:"@"))
    {
      if let addr = parseAddressToken() { return (OpSym(addr, opt) , true) }
      else { error( "Expecting address token" ) }
    }
    
    // Immediate constant
    if let value = parseImmediate()
    {
      // Set 'extern' flag if it's a large immediate
      if parseChar( UInt8(ascii:"L") ) { return (OpImm(value, opt) , true) }
      else { return (OpImm(value, opt) , false) }
    }
    
    // Instruction embeeded address symbol that may correspond
    // to a program memory label or jump table address
    if let addr = parsePrefixedToken( prefix: ".L".d )
    {
      return (OpSym(addr, opt) , false)
    }
    
    // Symbol that may correspond to a register def
    let svsc = c
    if let tokenDef = parseToken()
    {
      if let regNum = src.defsTable[tokenDef] {
        //return (regNum == 11 ? OpReg(regNum, opt.union(.isSP)) : OpReg(regNum, opt) , false) }
        return (regNum == 11 ? OpSP(regNum, opt) : OpReg(regNum, opt) , false) }
      
      else { error( "Expecting register or register def" ) }
      c = svsc
    }
    
    return nil
  }
  
  //-------------------------------------------------------------------------------------------
  func parseOperand( opt:OpOption ) -> Bool
  {
    if parseIndirectOperand() {
      return true }
    
    if parsePrgIndirectOperand() {
      return true }
    
    if let (op, hasPrefix) = parsePrimitiveOperand(opt:opt)
    {
      currInst?.ops.append( op )
      if hasPrefix { currInst?.hasPfix = true }
      return true
    }
    return false
  }
  
  //-------------------------------------------------------------------------------------------
  func parseOperators(opt:OpOption) -> Bool
  {
    if parseOperand(opt:opt)
    {
      while true
      {
        skipSpTab()
        if parseChar( UInt8(ascii:",") )
        {
          skipSpTab()
          if parseOperand(opt:opt) { continue }
          else { error( "Expecting operator" ) }
        }
        break
      }
    }
    
    return true // zero operands are allowed so return always true
  }
  
  //-------------------------------------------------------------------------------------------
  func parseIndirectOperand() -> Bool
  {
    if parseChar( UInt8(ascii:"[") )
    {
      skipSpTab()
      if parseOperators(opt:.indirect)
      {
        skipSpTab()
        if parseChar( UInt8(ascii:"]") ) { return true }
      }
    }
    return false
  }
  
  //-------------------------------------------------------------------------------------------
  func parsePrgIndirectOperand() -> Bool
  {
    if parseChar( UInt8(ascii:"{") )
    {
      skipSpTab()
      if parseOperators(opt:.prgIndirect)
      {
        skipSpTab()
        if parseChar( UInt8(ascii:"}") ) { return true }
      }
    }
    return false
  }
  
  //-------------------------------------------------------------------------------------------
  func parseConditionCode() -> Bool
  {
    if let token = parseToken()
    {
      if let value =
        [ "eq".d : 0, "ne".d : 1, "uge".d : 2,
          "ult".d: 3, "ge".d: 4, "lt".d: 5,
          "ugt".d: 6, "gt".d: 7 ][token]
      {
        currInst?.ops.append( OpCC(value) /*OpImm(value, .isCC)*/ )
        return true
      }
    }
    return false
  }
  
    //-------------------------------------------------------------------------------------------
  func parseCompareInstruction() -> Bool
  {
    if let name:Data? = { if self.parseConcreteToken( cStr:"cmp".d ) { return "cmp".d  }
                          if self.parseConcreteToken( cStr:"cmpc".d ) { return "cmpc".d }
                          return nil }()
    {
      currInst = Instruction( name! )
      if parseChar( _dot )
      {
        if parseConditionCode() { return true }
        else { error( "Unrecognized condition code for conditional instruction" ) }
      }
      else { error( "Expected 'dot' after compare instruction" ) }
    }
    
    return false
  }
  
  //-------------------------------------------------------------------------------------------
  func parseAnyInstruction() -> Bool
  {
    if let name = parseToken()
    {
      currInst = Instruction( name )
      return true
    }
    return false
  }
  
  //-------------------------------------------------------------------------------------------
  func parseInstructionName() -> Bool
  {
    //if parseConditionalInstruction() { return true }
    if parseCompareInstruction() { return true }
    if parseAnyInstruction() { return true }
    return false
  }
  
  //-------------------------------------------------------------------------------------------
  func parseAddressLabel() -> Data?
  {
    let svc = c
    if let token = parseAddressToken()
    {
      if parseChar( UInt8(ascii:":") )
      {
        return token
      }
    }
    c = svc;
    return nil;
  }
  
  //-------------------------------------------------------------------------------------------
  func parseTokenList() -> [Data]?
  {
    var list:[Data]? = nil
    if let token = parseToken()
    {
      list = [token]
      while true
      {
        let svc = c
        skipSpTab()
        if parseChar( UInt8(ascii:",") )
        {
          skipSpTab()
          if let token = parseToken()
          {
            list!.append(token)
            continue
          }
          c = svc
        }
        break
      }
    }
    return list
  }

  //-------------------------------------------------------------------------------------------
  func parseText() -> Bool
  {
    if parseConcreteToken(cStr: "text".d)
    {
      currBank = .program
      return true
    }
    return false
  }
  
  //-------------------------------------------------------------------------------------------
  func parseFile() -> Bool
  {
    if parseConcreteToken(cStr: "file".d)
    {
      skipSpTab()
      if let name = parseEscapedString()
      {
        var pos = 0 ;
        while pos < name.count && name[pos] != _dot { pos = pos + 1 }
        src.name = name
        src.shortName = name.prefix(pos)
        return true
      }
      else { error( "Expecting file name string" ) }
    }
    return false
  }
  
  //-------------------------------------------------------------------------------------------
  func parseGlobl() -> Bool
  {
    if parseConcreteToken(cStr: "globl".d )
    {
      skipSpTab()
      if let name = parseGlobalToken()
      {
        // We do not allow duplicates of global symbols
        if asm.globalSymTable[name] == nil
        {
          let symInfo = SymTableInfo(bank:currBank)
          asm.globalSymTable[name] = symInfo
          out.logln()
          return true
        }
        else { error( "Duplicated global symbol \"\(name.s)\"" ) }
      }
    }
    return false
  }

  //-------------------------------------------------------------------------------------------
  func parseLocal() -> Bool
  {
    if parseConcreteToken(cStr: "local".d )
    {
      skipSpTab()
      if let name = parseToken()
      {
        let symInfo = SymTableInfo(bank:currBank)
        src.localSymTable[name] = symInfo
        out.logln()
        return true
      }
    }
    return false
  }
  
//-------------------------------------------------------------------------------------------
  func parseSection() -> Bool
  {
    if parseConcreteToken(cStr: "section".d )
    {
      skipSpTab()
      if nil != parsePrefixedToken(prefix:".".d) || nil != parseToken()
      {
        skipSpTab()
        while parseChar( UInt8(ascii:",") )
        {
          skipSpTab()
          if nil != parseEscapedString() ||
             nil != parsePrefixedToken(prefix:"@".d) ||
             nil != parseInteger() { skipSpTab(); continue }
          else { error( "Bad formed .section directive" ) }
        }
        currBank = .constant
        out.logln()
        return true
      }
      else { error( "Expecting section name after .section directive" ) }
    }
    return false
  }
  
  //-------------------------------------------------------------------------------------------
  func parseP2Align() -> Bool
  {
    if parseConcreteToken(cStr: "p2align".d )
    {
      skipSpTab()
      if let align = parseInteger()
      {
        if currBank == .constant { src.p2AlignConstantData(align) }
        else if currBank == .variable { src.p2AlignInitializedVar(align) }
        else { error( "Unsuported bank (1)" ) }
        return true
      }
    }
    return false
  }
  
  //-------------------------------------------------------------------------------------------
  func parseDataOperand() -> Operand?
  {
    if let value = parseImmediate() {
      return OpImm( value ) }
    
    if let (addr, offset) = parseEfectiveAddress() {
      return OpSym(offset, addr, opt:[]) }
    
    return nil
  }
  
  //-------------------------------------------------------------------------------------------
  func parseStrOperand(addZeroByte:Bool) -> Operand?
  {
    if var str = parseEscapedString()
    {
      if addZeroByte { str.append(0) }
      return OpStr(str)
    }
    return nil
  }
  
  //-------------------------------------------------------------------------------------------
  func restParseData( _ size:Int ) -> Bool
  {
    if let op = parseDataOperand()
    {
      if currBank == .constant { src.addConstantData( DataValue( size, op ) ) }
      else if currBank == .variable { src.addInitializedVar( DataValue( size, op ) ) }
      else { error( "Unsuported bank (2)" ) }

      out.logln( "\t" + String(reflecting:op) )

      return true
    }
    return false
  }
  
  //-------------------------------------------------------------------------------------------
  func restParseStr(addZeroByte:Bool=false) -> Bool
  {
    if let op = parseStrOperand(addZeroByte:addZeroByte)
    {
      let size = op.sym!.count
      if currBank == .constant { src.addConstantData( DataValue( size, op ) ) }
      else if currBank == .variable { src.addInitializedVar( DataValue( size, op ) ) }
      else { error( "Unsuported bank (3)" ) }

      out.logln( "\t" + String(reflecting:op) )
      return true
    }
    
    return false
  }
  
  //-------------------------------------------------------------------------------------------
  func parseByte() -> Bool
  {
    if parseConcreteToken(cStr: "byte".d )
    {
      skipSpTab()
      if restParseData( 1 ) { return true }
      else { error("Expecting data value") }
    }
    return false
  }
  
  //-------------------------------------------------------------------------------------------
  func parseShort() -> Bool
  {
    if parseConcreteToken(cStr: "short".d )
    {
      skipSpTab()
      if restParseData( 2 ) { return true }
      else { error("Expecting data value") }
    }
    return false
  }
  
  //-------------------------------------------------------------------------------------------
  func parseLong() -> Bool
  {
    if parseConcreteToken(cStr: "long".d )
    {
      skipSpTab()
      if restParseData( 4 ) { return true }
      else { error("Expecting data value") }
    }
    return false
  }

 //-------------------------------------------------------------------------------------------
  func parseAscii() -> Bool
  {
    if parseConcreteToken(cStr: "ascii".d )
    {
      skipSpTab()
      if restParseStr() { return true }
      else { error("Expecting ascii string") }
    }
    return false
  }
  
  //-------------------------------------------------------------------------------------------
  func parseAsciz() -> Bool
  {
    if parseConcreteToken(cStr: "asciz".d )
    {
      skipSpTab()
      if restParseStr(addZeroByte:true) { return true }
      else { error("Expecting ascii string") }
    }
    return false
  }

  //-------------------------------------------------------------------------------------------
  func parseData() -> Bool
  {
    if parseConcreteToken(cStr: "data".d )
    {
      currBank = .variable
      return true
    }
    return false
  }
  
 //-------------------------------------------------------------------------------------------
  func parseComm() -> Bool
  {
    if parseConcreteToken(cStr: "comm".d )
    {
      skipSpTab()
      if let name = parseToken()
      {
        var size = 0
        var align = 1
        skipSpTab()
        if parseChar( UInt8(ascii:",") )
        {
          skipSpTab()
          if let len = parseAnyInteger()
          {
            size = len
            skipSpTab()
            if parseChar( UInt8(ascii:",") )
            {
              skipSpTab()
              if let algn = parseAnyInteger()
              {
                align = algn
              }
            }
          }
        }
        
        if let symInfo = src.localSymTable[name]
        {
          // Locally defined symbols just need to be added
          // and updated
          src.addUninitializedVar( size:size, align:align)
          symInfo.bank = .common
          symInfo.value = src.getUninitializedVarsEnd()-size
        }
        else if let symInfo = asm.globalSymTable[name]
        {
          // For global comm symbols, only verify that
          // the symbol is already defined in the .common area
          // (See TO DO comment below)
          if symInfo.bank != .common { error( "Duplicated global symbol \"\(name.s)\"" ) }
        }
        else
        {
          // The symbol was not defined previously, so create it now
          // and initialize accordingly
          let symInfo = SymTableInfo(bank:.common)
          asm.globalSymTable[name] = symInfo
          src.addUninitializedVar( size:size, align:align)
          
          // value must be set after adding to take the align into accout
          symInfo.value = src.getUninitializedVarsEnd()-size
        }
        
        // TO DO:
        // Note that the code above is buggy because the .comm directive is supposed
        // to merge sizes of identically named symbols by using the largest size of them all.
        // The consequence of not doing this here is potential memory
        // overlaps if subsequent definitions are of a larger size. However, implementing
        // this requires some thought because we do not track size information of the
        // previously added comm symbols
        
        out.logln( name.s + ":" )
 
        return true
      }
      else { error( "Expecting section name after .section directive" ) }
    }
    return false
  }

  //-------------------------------------------------------------------------------------------
  func parseInstruction() -> Bool
  {
    currInst = nil;

    func appendInstr( _ inst:Instruction )
    {
      // Log
      out.logln( "\t" + String(reflecting:inst) )
      
      // Get the machine instruction
      src.addInstruction( inst )

      // Bail out if no suitable match was found
      if ( inst.mcInst == nil ) {
        error( "Unrecognised Instruction Pattern: " + String(reflecting:inst) ) }
      
      // Set the current label to the instruction
      inst.labels = currLabels
      currLabels = nil
      //inst.label = currLabel
      //currLabel = nil
    }
    
    if parseInstructionName()
    {
      skipSpTab()
      if parseOperators(opt:[])
      {
        appendInstr( currInst! )
        return true
      } // <- zero operand instructions are legal, so no errors can't go here
    }
    return false
  }
  
  //-------------------------------------------------------------------------------------------
  func parseLabel() -> Bool
  {
    if let name = parseAddressLabel()
    {
      // It it's already in the global table use it,
      // otherwise create the symbol in the local table
      var symInfo = asm.globalSymTable[name]
      if symInfo == nil
      {
        symInfo = SymTableInfo(bank:currBank)
        src.localSymTable[name] = symInfo
      }
    
      // Set the address value
      switch currBank
      {
        case .program  : symInfo!.value = src.getInstructionsEnd()
        case .constant : symInfo!.value = src.getConstantDataEnd()
        case .variable : symInfo!.value = src.getInitializedVarsEnd()
        default : error( "Unsuported bank (4)" )
      }
      
      if currBank == .program
      {
        // There may be more than one label for the same instruction, so use an array
        if currLabels != nil { currLabels?.append(name) }
        else { currLabels = [name] }
      }
      out.logln( name.s + ":" )
 
      return true
    }
    return false
  }
  
  //-------------------------------------------------------------------------------------------
  func parseSet() -> Bool
  {
    if parseConcreteToken(cStr: ".set".d )
    {
      skipSpTab()
      if let tokens = parseTokenList()
      {
        if tokens.count == 2
        {
          if currBank == .program
          {
//            let offs = asm.progSyms[tokens[1]]
//            asm.progSyms[tokens[0]] = offs
            error ( "Dont Know what to do" )
            return true
          }
          else { error( ".set directive issued in non program area" ) }
        }
        else { error( "Expecting exactly 2 tokens after .set directive" ) }
      }
      else { error( "Expecting symbol after .set directive" ) }
    }
    return false
  }
  
  //-------------------------------------------------------------------------------------------
  func parseDef() -> Bool
  {
    if parseConcreteToken(cStr: ".def".d )
    {
      skipSpTab()
      if let token = parseToken()
      {
        skipSpTab()
        if parseChar( UInt8(ascii:"=") )
        {
          skipSpTab()
          if let regNum = parseRegisterOperand(opt:[])
          {
            src.defsTable[token] = regNum
            return true
          }
          else { error ( "Expected register operand" ) }
        }
        else { error( "Expected '=' after def token" ) }
      }
      else { error( "Expected def token") }
    }
    return false
  }
  
  //-------------------------------------------------------------------------------------------
  // Entry function for the parser
  func parse() -> Bool
  {
    // For debug purposes use 'print self.dump()'
    while true
    {
      skip()
      if parseChar( _tab )
      {
        skipSpTab()
        if parseChar( _dot )
        {
          if parseText() { continue }
          if parseFile() { continue }
          if parseGlobl() { continue }
          if parseLocal() { continue }
          if parseSection() { continue }
          if parseP2Align() { continue }
          if parseByte() { continue }
          if parseShort() { continue }
          if parseLong() { continue }
          if parseData() { continue }
          if parseComm() { continue }
          if parseAscii() { continue }
          if parseAsciz() { continue }
          error( "Unknown assembler directive" )
        }
        if parseInstruction() { continue }
        continue // allow empty lines after a tab
      }
      else
      {
        if parseLabel() { continue }
        if parseSet() { continue }
        if parseDef() { continue }
        break
      }
    }
    
    if c != end { error( "Extra characters before end of file" ) }
    
    src.p2AlignConstantData(1)
    src.p2AlignInitializedVar(1)
    return true
  }

} // End class SourceParser

