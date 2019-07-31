//
//  SourceParser.swift
//  c74-as
//
//  Created by Joan on 28/06/19.
//  Copyright © 2019 Joan. All rights reserved.
//

import Foundation

extension String
{
  var d:Data
  {
    get { return self.data(using:.ascii)! }
  }
}

extension Data
{
  var s:String
  {
    get { return String(data:self, encoding:.ascii)! }
  }
}


//-------------------------------------------------------------------------------------------
// SourceParser
//-------------------------------------------------------------------------------------------

class SourceParser:PrimitiveParser
{
  enum Bank {
    case program
    case constant
    case variable
  }

  let src:Source
  let asm:Assembler
  var currBank:Bank = .program
  var currInst:Instruction?

  //-------------------------------------------------------------------------------------------
  init( withData:Data, source:Source, assembler:Assembler)
  {
    src = source
    asm = assembler
    super.init(withData:withData)
  }
  
  //-------------------------------------------------------------------------------------------
  func printError( _ message:String )
  {
//    out.print( message, true )
//    out.println( ", line:\(line)", true )
    
    out.printError( "\(message), line:\(line)" )
//    exit(1)
  }
  
  //-------------------------------------------------------------------------------------------
  func parseRegister() -> Int?
  {
    if parseChar(UInt8(ascii:"r")) || parseChar(UInt8(ascii:"R"))
    {
      if let value = parseInteger()
      {
        return value
      }
    }
    return nil
  }
  
  //-------------------------------------------------------------------------------------------
  func parseAddressToken() -> Data?
  {
    if let token = parseToken() { return token }
    if let token = parsePrefixedToken( prefix: ".L".d )
    {
      var mangled = src.shortName;
      mangled.append(token)
      return mangled
    }
    return nil
  }
  
  //-------------------------------------------------------------------------------------------
  func parseDataAddress() -> Data?
  {
    let svc = c
    if parseChar(UInt8(ascii:"&"))
    {
      if let addr = parseAddressToken()
      {
        return addr
      }
    }
    c = svc
    return nil
  }
  
//  //-------------------------------------------------------------------------------------------
//  func parseDataAddress() -> Data?
//  {
//    let svc = c
//    if parseChar(UInt8(ascii:"&"))
//    {
//      if let addr = parseToken() c
//      {
//        return addr
//      }
//    }
//    c = svc
//    return nil
//  }
  
  //-------------------------------------------------------------------------------------------
  func parseImmediate() -> Int?
  {
    if let value = parseInteger()
    {
      return value
    }
    return nil
  }
  
//  //-------------------------------------------------------------------------------------------
//  func parsePrivateAddress() -> Data?
//  {
//    if let addr = parsePrefixedToken( prefix: ".L".d )
//    {
//        return addr
//    }
//    return nil
//  }
//
//  //-------------------------------------------------------------------------------------------
//  func parsePublicAddress() -> Data?
//  {
//    if let addr = parseToken()
//    {
//      return addr
//    }
//    return nil
//  }
  
  func parseStrOperand() -> Data?
  {
    if let str = parseEscapedString()
    {
      return str
    }
    return nil
  }
  
  //-------------------------------------------------------------------------------------------
  func parseOperand( ind:Bool ) -> Bool
  {
    if parseIndirectOperand()
    {
      return true;
    }
    
    if let value = parseRegister()
    {
      currInst?.ops.append( OpReg(value, ind:ind) )
      return true;
    }
    
    if parseConcreteToken(cStr: "SP".d)
    {
      currInst?.ops.append( OpRSP(8, ind:ind) )
      return true;
    }
    
    if let addr = parseDataAddress()
    {
      currInst?.ops.append( OpSym(addr, ind:ind, ext:true) )
      return true;
    }
    
    if let value = parseImmediate()
    {
      let ext = currInst?.needsExOp
      currInst?.ops.append( OpImm(value, ind:ind, ext:ext!) )
      return true;
    }
    
    if let addr = parseAddressToken()
    {
      currInst?.ops.append( OpSym(addr, ind:ind) )
      return true
    }

//    if let addr = parsePrivateAddress()
//    {
//      currInst?.ops.append( OpSym(addr, ind:ind) )
//      return true
//    }
//
//    if let addr = parsePublicAddress()
//    {
//      currInst?.ops.append( OpSym(addr, ind:ind) )
//      return true;
//    }
    
    return false
  }
  
  //-------------------------------------------------------------------------------------------
  func parseDataOperand() -> Operand?
  {
    if let value = parseImmediate()
    {
      return OpImm( value )
    }
    
    if let addr = parseAddressToken()
    {
      return OpSym( addr )
    }
    
    return nil
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
          else { printError( "Expecting operator" ) }
        }
        break
      }
    }
    
    return true // zero operands are allowed so return always true
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

//  //-------------------------------------------------------------------------------------------
//  func parseConditionalInstructionPrefix() -> Data?
//  {
//    if parseRawToken( cStr:"br".d ) { return "brcc".d  }
//    if parseRawToken( cStr:"set".d ) { return "setcc".d }
//    if parseRawToken( cStr:"sel".d ) { return "selcc".d }
//    return nil
//  }
  
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
      else { printError( "Unrecognized condition code for conditional instruction" ) }
    }
    
    return false
  }
  
  //-------------------------------------------------------------------------------------------
  func parseMovWordInstruction() -> Bool
  {
    if parseConcreteToken(cStr: "mov.w".d )
    {
      currInst = Instruction( "mov.w".d )
      currInst?.needsExOp = true
      return true
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
    if parseMovWordInstruction() { return true }
    if parseConditionalInstruction() { return true }
    if parseAnyInstruction() { return true }
    return false
  }
  
//  //-------------------------------------------------------------------------------------------
//  func parseInstructionVell() -> Bool
//  {
//    let svc = c
//    if parseChar( _tab )
//    {
//      currInst = nil;
//      skipSpTab()
//      if parseInstructionName()
//      {
//        skipSpTab()
//        if parseOperators(ind:false)
//        {
//          return true
//        }
//      }
//    }
//    c = svc
//    return false
//  }

  
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

//  //-------------------------------------------------------------------------------------------
//  func parsePublicLabel() -> Data?
//  {
//    let svc = c
//    if let token = parseToken()
//    {
//      if parseChar( UInt8(ascii:":") )
//      {
//        return token
//      }
//    }
//    c = svc;
//    return nil;
//  }
//
//  //-------------------------------------------------------------------------------------------
//  func parsePrivateLabel() -> Data?
//  {
//    let svc = c
//    if let token = parsePrefixedToken( prefix: ".".d )
//    {
//      if parseChar( UInt8(ascii:":") )
//      {
//        return token
//      }
//    }
//    c = svc;
//    return nil;
//  }
  
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
  
//  //-------------------------------------------------------------------------------------------
//  func parseGlobData() -> Bool
//  {
//    // TO DO
//    return false;
//  }
  
//  //-------------------------------------------------------------------------------------------
//  func parseSourceHeader() -> Bool
//  {
//    if parseConcreteToken(cStr: "\t.text".d)
//    {
//      while true
//      {
//        skip()
//        if parseConcreteToken(cStr: "\t.file".d)
//        {
//          skipSpTab()
//          if let name = parseEscapedString()
//          {
//            let shortName = name.prefix(while:{$0 != self._dot} )
//            src.name = shortName;
//            continue
//          }
//          else { printError( "Expecting file name string" ) }
//        }
//        else { break }
//      }
//    }
//    else { printError( "Unrecognized file format" ) }
//    return true
//  }
//

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
      else { printError( "Expecting file name string" ) }
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
        return true
      }
      else { printError( "Expecting section name after .section directive" ) }
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
  func restParseData( _ size:Int ) -> Bool
  {
    if let op = parseDataOperand()
    {
      if currBank == .constant { asm.addConstantData( DataValue( size, op ) ) }
      else if currBank == .variable { asm.addInitializedVar( DataValue( size, op ) ) }
      #if DEBUG
      out.println( "\t" + String(reflecting:op) )
      #endif
      return true
    }
    return false
  }
  
  //-------------------------------------------------------------------------------------------
  func restParseStr(addZeroByte:Bool=false) -> Bool
  {
    if var str = parseStrOperand()
    {
      if addZeroByte { str.append(0) }
      if currBank == .constant { asm.addConstantData( DataValue( str.count, OpStr(str) ) ) }
      else if currBank == .variable { asm.addInitializedVar( DataValue( str.count, OpStr(str) ) ) }
      #if DEBUG
      out.println( "\t" + String(reflecting:str.s) )
      #endif
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
        //currSection = 1
        return true
      }
      else { printError( "Expecting section name after .section directive" ) }
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
    }
    return false
  }

  //-------------------------------------------------------------------------------------------
  func parseInstruction() -> Bool
  {
    currInst = nil;
    
    let appendInstr = { ( inst:Instruction ) in
      self.src.instructions.append( inst )
      #if DEBUG
      out.println( "\t" + String(reflecting:inst) )
      #endif
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
      }
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
      #if DEBUG
      out.println( sym.s + ":" )
      #endif
      return true
    }
    return false
  }
  
//  //-------------------------------------------------------------------------------------------
//  func parseLabel() -> Bool
//  {
//    if let sym = parsePublicLabel()
//    {
//      if currBank == .program { asm.progSyms[sym] = src.getEnd() }
//      else if currBank == .constant { asm.constantDataSyms[sym] = asm.constantDataEnd }
//      else if currBank == .variable { asm.initializedVarsSyms[sym] = asm.initializedVarsEnd }
//      #if DEBUG
//      out.println( "\(sym.s):" )
//      #endif
//      return true
//    }
//    else if let addr = parsePrivateLabel()
//    {
//      if currBank == .program  { src.privSyms[addr] = src.getEnd() }
//      else if currBank == .constant { asm.constantDataSyms[addr] = asm.constantDataEnd }
//      else { /* Error? */ }
//      #if DEBUG
//      out.println( "\(addr.s):" )
//      #endif
//      return true
//    }
//    return false
//  }
  
  
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
          else { printError( ".set directive issued in non program area" ) }
        }
        else { printError( "Expecting exactly 2 tokens after .set directive" ) }
      }
      else { printError( "Expecting symbol after .set directive" ) }
    }
    return false
  }
  
  
  //-------------------------------------------------------------------------------------------
  func parseAll() -> Bool
  {
    beg = s.startIndex;
    end = s.endIndex;
    c = beg;
    
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
          printError( "Unknown assembler directive" )
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
    
    asm.p2AlignConstantData(1)
    asm.p2AlignInitializedVar(1)
    return true
  }

} // SourceParser

