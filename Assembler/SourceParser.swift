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
   func dump()
  {
    out.println( String(data:self, encoding:.ascii)! )
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
    let svc = c
    if let addr = parseDotToken()
    {
      let prefix = ".L".d
      if addr.count > prefix.count
        && prefix == addr[addr.startIndex..<addr.startIndex+prefix.count]
      {
        return addr
      }
    }
    c = svc;
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
  func parseOperand(ind:Bool) -> Bool
  {
    if parseIndirectOperand()
    {
      return true;
    }
    
    if let value = parseRegister()
    {
      currInst?.ops.append( OpReg(value, ind) )
      return true;
    }
    
    if let addr = parseDataAddress()
    {
      currInst?.ops.append( OpSym(addr, ind) )
      return true;
    }
    
    if let value = parseImmediate()
    {
      currInst?.ops.append( OpImm(value, ind) )
      return true;
    }

    if let addr = parsePrivateAddress()
    {
      currInst?.isBranch = true;
      currInst?.ops.append( OpSym(addr, ind) )
      return true
    }
    
    if let addr = parsePublicAddress()
    {
      currInst?.ops.append( OpSym(addr, ind) )
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
  func parseInstruction() -> Bool
  {
    let svc = c
    if parseChar( _tab )
    {
      currInst = nil;
      skipSpTab()
      if let name = parseToken()
      {
        currInst = Instruction( name )
        skipSpTab()
        if parseOperators(ind:false)
        {
          currFn?.instructions.append(currInst!)
          out.println( currInst!.description )
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
    if let token = parseDotToken()
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
  func parseFunctionHeader() -> Bool
  {
    skip()
    if parseConcreteToken(cStr: "\t.globl".d )
    {
      skipSpTab()
      if let name = parseToken()
      {
        skip()
        if let fname = parsePublicLabel()
        {
          if ( fname == name )
          {
            currFn = Function( name, currOffs)
            src.progSyms[fname] = currOffs
            return true;
          }
        }
        else { printError( "Function entry label mismatch" ) }
      }
    }
    return false;
  }
  
  //-------------------------------------------------------------------------------------------
  func parseFunction() -> Bool
  {
    if parseFunctionHeader()
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
          continue
        }
        break
      }
      
      src.functions.append(currFn!)
      currOffs = currFn!.getEnd()
      return true;
    }
    return false;
  }
  
  //-------------------------------------------------------------------------------------------
  func parseGlob() -> Bool
  {
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
        if parseGlob() { continue }
        break
      }
      
      return true;
    }
    return false;
  }

} // SourceParser

