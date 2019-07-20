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
  let src:Source
  var currOffs:Int = 0
  var currFn:Function?
  var currInst:Instruction?

  //-------------------------------------------------------------------------------------------
  init( withData:Data, source:Source)
  {
    src = source;
    super.init(withData:withData);
  }
  
  //-------------------------------------------------------------------------------------------
  func printError( _ message:String )
  {
    out.print( message, true )
    out.println( ", line:\(line)", true )
    exit(0)
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
  func parseDataAddress() -> Data?
  {
    let svc = c
    if parseChar(UInt8(ascii:"&"))
    {
      if let addr = parseToken()
      {
        return addr
      }
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
  func parsePrivateAddress() -> Data?
  {
    if let addr = parsePrefixedToken( prefix: ".L".d )
    {
        return addr
    }
    return nil
  }
  
  //-------------------------------------------------------------------------------------------
  func parsePublicAddress() -> Data?
  {
    if let addr = parseToken()
    {
      return addr
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

    if let addr = parsePrivateAddress()
    {
      currInst?.ops.append( OpSym(addr, ind:ind) )
      return true
    }
    
    if let addr = parsePublicAddress()
    {
      currInst?.ops.append( OpSym(addr, ind:ind) )
      return true;
    }
    
    return false
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
  
  //-------------------------------------------------------------------------------------------
  func parseInstruction() -> Bool
  {
    let svc = c
    if parseChar( _tab )
    {
      currInst = nil;
      skipSpTab()
      if parseInstructionName()
      {
        skipSpTab()
        if parseOperators(ind:false)
        {
          return true
        }
      }
    }
    c = svc
    return false
  }
  
  //-------------------------------------------------------------------------------------------
  func parsePublicLabel() -> Data?
  {
    let svc = c
    if let token = parseToken()
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
  func parsePrivateLabel() -> Data?
  {
    let svc = c
    if let token = parsePrefixedToken( prefix: ".".d )
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
        if parseChar( UInt8(ascii:","))
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
  func parseFunctionBody() -> Bool
  {
    while true
    {
      skip();
      if let addr = parsePrivateLabel()
      {
        src.privSyms[addr] = currFn!.getEnd()
        continue
      }
        
      if parseInstruction()
      {
        currFn?.instructions.append( currInst! )
        #if DEBUG
        out.println( currInst!.description )
        #endif
          
        if let op = currInst?.exOperand
        {
          let inst = Instruction( "_imm".d, [op] )
          currFn?.instructions.append( inst )
          #if DEBUG
          out.println( inst.description )
          #endif
        }
        continue
      }
      break
    }

    src.functions.append(currFn!)
    currOffs = currFn!.getEnd()
    return true;
  }
  
  //-------------------------------------------------------------------------------------------
  func parseFunction() -> Bool
  {
    // check for .glob directive
    if parseConcreteToken(cStr: "\t.globl".d )
    {
      skipSpTab()
      
      // must be followed by a token
      if let name = parseToken()
      {
        src.progSyms[name] = currOffs
        
        // the line after .glob may contain a .set directire
        skip()
        if parseConcreteToken(cStr: ".set".d )
        {
          skipSpTab()
          if let tokens = parseTokenList()
          {
            if tokens.count == 2
            {
              let offs = src.progSyms[tokens[1]]
              src.progSyms[tokens[0]] = offs
              return true
            }
            else { printError( "Expecting exactly 2 tokens after .set directive" ) }
          }
          else { printError( "Expecting symbol after .set directive" ) }
        }
        
        // or it may contain a public label, which indicates it is a function entry
        else if let fname = parsePublicLabel()
        {
          if ( fname == name )
          {
            currFn = Function( name, currOffs)  // tentativelly set as the current function
            return parseFunctionBody()  // this always retuns true
          }
          else { printError( "Function entry label mismatch" ) }
        }
        else { printError( "Unrecognized pattern for function entry" ) }
      }
    }
    return false;
  }
  

  
  //-------------------------------------------------------------------------------------------
  func parseGlobData() -> Bool
  {
    // TO DO
    return false;
  }
  
  //-------------------------------------------------------------------------------------------
  func parseSourceHeader() -> Bool
  {
    if parseConcreteToken(cStr: "\t.text".d)
    {
      while true
      {
        skip()
        if parseConcreteToken(cStr: "\t.file".d)
        {
          skipSpTab()
          if let name = parseEscapedString()
          {
            src.name = name;
            continue
          }
          else { printError( "Expecting file name string" ) }
        }
        else { break }
      }
    }
    else { printError( "Unrecognized file format" ) }
    return true
  }
  
  //-------------------------------------------------------------------------------------------
  func parseAll() -> Bool
  {
    beg = s.startIndex;
    end = s.endIndex;
    c = beg;
    
    skip()
    if parseSourceHeader()
    {
      while true
      {
        skip();
        if parseFunction() { continue }
        break
      }
      
      while true
      {
        skip();
        if parseGlobData() { continue }
        break
      }
      
      return true;
    }
    return false;
  }

} // SourceParser

