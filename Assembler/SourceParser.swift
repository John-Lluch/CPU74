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
  var d:Data { return self.data(using:.utf8)! }
}

extension Data {
  var s:String { return String(data:self, encoding:.utf8)! }
}

//-------------------------------------------------------------------------------------------
// SourceParser
//-------------------------------------------------------------------------------------------

// Parse a single source file into a Source object
// Update Assembler object symbol tables
class SourceParser:PrimitiveParser
{
  // We consider the following memory banks
  enum Bank {
    case program
    case constant
    case variable
  }

  let src:Source           // Destination Source object
  let asm:Assembler        // Destination Assembler object
  var currBank:Bank = .program    // Current memory bank
  var currInst:Instruction?       // Current instruction

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
    out.exitWithError( "\(message), file:\(src.shortName).s line:\(line)" )
  }
  
  //-------------------------------------------------------------------------------------------
  // The following code is just a top-down (not particularly recursive) descendant parser
  // implemented by hand. The entry funcion is 'parse()'
  
  //-------------------------------------------------------------------------------------------
  func parseAddressToken() -> Data?
  {
    if let token = parseToken() { return token }
    if let token = parsePrefixedToken( prefix: ".L".d )
    {
      var mangled = src.shortName; // Local simbols get prefixed with the current file name
      mangled.append(token)
      return mangled
    }
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
        if let value = parseInteger() { offset = value } }
      
      return (data,offset)
    }
    
    c = svc
    return nil
  }
  
  //-------------------------------------------------------------------------------------------
  func parseImmediate() -> Int?
  {
    if let value = parseInteger()
    {
      return value
    }
    return nil
  }
 
  //-------------------------------------------------------------------------------------------
  func parsePrimitiveOperand( ind:Bool ) -> Operand?
  {
    // Register
    if parseChar(UInt8(ascii:"r")) || parseChar(UInt8(ascii:"R"))
    {
      if let value = parseInteger() { return OpReg(value, ind:ind) }
      else { error( "Expecting register number" ) }
    }
    
    // Stack pointer
    if parseConcreteToken(cStr: "sp".d) || parseConcreteToken(cStr: "SP".d)
    {
      return OpReg(7, ind:ind)
    }
    
    // Absolute address symbol in data memory
    if parseChar( UInt8(ascii:"&") )
    {
      if let (addr, offset) = parseEfectiveAddress() { return OpSym(offset, addr, ind:ind, ext:true) }
      else { error( "Expecting efective address" ) }
    }
    
    // Absolute address in program memory (NOT WORKING)
    if parseChar(UInt8(ascii:"@"))
    {
      if let addr = parseAddressToken() { return OpSym(addr, ind:ind, ext:true) }
      else { error( "Expecting address token" ) }
    }
    
    // Immediate constant
    if let value = parseImmediate()
    {
      let ext:Bool = parseChar( UInt8(ascii:"L") ) // Set 'ext' flag if it's a large immediate
      return OpImm(value, ind:ind, ext:ext)
    }
    
    // Instruction embeeded address symbol that may correspond
    // to a program memory label or jump table address
    if let addr = parseAddressToken()
    {
      return OpSym(addr, ind:ind)
    }
    
    return nil
  }
  
  //-------------------------------------------------------------------------------------------
  func parseOperand( ind:Bool ) -> Bool
  {
    if parseIndirectOperand() {
      return true }
    
    if let op = parsePrimitiveOperand(ind: ind)
    {
      currInst?.ops.append( op )
      return true
    }
    return false
  }
  
  //-------------------------------------------------------------------------------------------
  func parseOperators(ind:Bool) -> Bool
  {
    if parseOperand(ind:ind)
    {
      while true
      {
        skipSpTab()
        if parseChar( UInt8(ascii:",") )
        {
          skipSpTab()
          if parseOperand(ind:ind) { continue }
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
      if parseOperators(ind:true)
      {
        skipSpTab()
        if parseChar( UInt8(ascii:"]") ) { return true }
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
          "ult".d: 3, "lt".d: 4, "ge".d: 5,
          "ugt".d: 6, "gt".d: 7 ][token]
      {
        currInst?.ops.append( OpImm(value, ind:false) )
        return true
      }
    }
    return false
  }

  //-------------------------------------------------------------------------------------------
  func parseConditionalInstruction() -> Bool
  {
    if let name:Data? = { if self.parseRawToken( cStr:"br".d ) { return "brcc".d  }
                          if self.parseRawToken( cStr:"set".d ) { return "setcc".d }
                          if self.parseRawToken( cStr:"sel".d ) { return "selcc".d }
                          return nil }()
    {
      currInst = Instruction( name! )
      if parseConditionCode() { return true }
      else { error( "Unrecognized condition code for conditional instruction" ) }
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
    //if parseMovWordInstruction() { return true }
    if parseConditionalInstruction() { return true }
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
      if let name = parseToken()
      {
        if currBank == .program { asm.progSyms[name] = src.getEnd() }
        else if currBank == .constant { asm.constantDataSyms[name] = asm.constantDataEnd }
        else if currBank == .variable { asm.initializedVarsSyms[name] = asm.initializedVarsEnd }
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
        if parseChar( UInt8(ascii:",") )
        {
          skipSpTab()
          if nil != parseEscapedString()
          {
            skipSpTab()
            if parseChar( UInt8(ascii:",") )
            {
              skipSpTab()
              if nil != parsePrefixedToken(prefix:"@".d)
              {
                // nothing to do at this time
              }
            }
          }
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
        if currBank == .constant { asm.p2AlignConstantData(align) }
        else if currBank == .variable { asm.p2AlignInitializedVar(align) }
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
    
    if let (addr, offset) = parseEfectiveAddress()
    {
      return OpSym(offset, addr, ind:false, ext:false)
    }
    
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
      if currBank == .constant { asm.addConstantData( DataValue( size, op ) ) }
      else if currBank == .variable { asm.addInitializedVar( DataValue( size, op ) ) }

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
      if currBank == .constant { asm.addConstantData( DataValue( size, op ) ) }
      else if currBank == .variable { asm.addInitializedVar( DataValue( size, op ) ) }

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
        var length = 0
        var align = 1
        skipSpTab()
        if parseChar( UInt8(ascii:",") )
        {
          skipSpTab()
          if let len = parseInteger()
          {
            length = len
            skipSpTab()
            if parseChar( UInt8(ascii:",") )
            {
              skipSpTab()
              if let algn = parseInteger()
              {
                align = algn
              }
            }
          }
        }
      
        asm.addUninitializedVar( name:name, size:length, align:align)
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
    
    let appendInstr = { ( inst:Instruction ) in
      self.src.instructions.append( inst )
      out.logln( "\t" + String(reflecting:inst) )
    }
    
    if parseInstructionName()
    {
      skipSpTab()
      if parseOperators(ind:false)
      {
        appendInstr( currInst! )
        if let op = currInst?.exOperand
        {
          let inst = Instruction( "_imm".d, [op] )
          appendInstr( inst )
        }
        return true
      } // <- zero operand instructions are legal, so no errors here
    }
    return false
  }
  
  //-------------------------------------------------------------------------------------------
  func parseLabel() -> Bool
  {
    if let sym = parseAddressLabel()
    {
      if currBank == .program { asm.progSyms[sym] = src.getEnd() }
      else if currBank == .constant { asm.constantDataSyms[sym] = asm.constantDataEnd }
      else if currBank == .variable { asm.initializedVarsSyms[sym] = asm.initializedVarsEnd }
 
      out.logln( sym.s + ":" )
 
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
            let offs = asm.progSyms[tokens[1]]
            asm.progSyms[tokens[0]] = offs
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
  // Entry function for the parser
  func parse() -> Bool
  {
    src.offset = asm.getProgEnd()
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
        break;
      }
      else
      {
        if parseLabel() { continue }
        if parseSet() { continue }
        break
      }
    }
    
    if c != end { error( "Extra characters before end of file" ) }
    
    asm.p2AlignConstantData(1)
    asm.p2AlignInitializedVar(1)
    return true
  }

} // SourceParser

