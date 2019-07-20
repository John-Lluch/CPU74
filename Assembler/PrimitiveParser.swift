//
//  PrimitiveParser.swift
//  c74-as
//
//  Created by Joan on 28/06/19.
//  Copyright © 2019 Joan. All rights reserved.
//

import Foundation





//-------------------------------------------------------------------------------------------
// Primitive Parser
//-------------------------------------------------------------------------------------------
class PrimitiveParser
{
  var line:Int = 1;
  var s:Data;
  var c:Data.Index;
  var beg:Data.Index;
  var end:Data.Index;
  
  init( withData:Data )
  {
    s = withData;
    beg = s.startIndex;
    end = s.endIndex;
    c = beg;
  }
  
  func removeAll()
  {
    s.removeAll();
    beg = s.startIndex;
    end = s.endIndex;
    c = beg;
  }
  
  //-------------------------------------------------------------------------------------------
  // Convenience constants
  let _space = UInt8(ascii:" ");
  let _tab = UInt8(ascii:"\t");
  let _newline = UInt8(ascii:"\n");
  let _return = UInt8(ascii:"\r");
  let _underscore = UInt8(ascii:"_");
  let _dollar = UInt8(ascii:"$");
  let _a = UInt8(ascii:"a");
  let _A = UInt8(ascii:"A");
  let _z = UInt8(ascii:"z");
  let _Z = UInt8(ascii:"Z");
  let _0 = UInt8(ascii:"0");
  let _9 = UInt8(ascii:"9");
  let _dot = UInt8(ascii:".");
  let _minus = UInt8(ascii:"-");
  let _quote = UInt8(ascii:"\"");
  let _backSlash = UInt8(ascii:"\\");
  let _pillow = UInt8(ascii:"#");
  
  
  //-------------------------------------------------------------------------------------------
  func dump()
  {
    let l = min(80, end-c)
    out.println( String(data:s[c..<c+l], encoding:.utf8)! )
  }
  
  //-------------------------------------------------------------------------------------------
  // Skip spaces
  @inline(__always)
  func skipSp()
  {
    while c < end && (s[c] == _space) {
      c += 1
    }
  }
  
  //-------------------------------------------------------------------------------------------
  // Skip spaces and tabs
  @inline(__always)
  func skipSpTab()
  {
    while c < end && ((s[c] == _space) || (s[c] == _tab)) {
      c += 1
    }
  }
  
  //-------------------------------------------------------------------------------------------
  // Skips to any char in the argument list.
  // Returns true if the char was actually found before the end of file
  // Updates the staring index and skipped length
  func skipToChar( cstr:inout Data.Index, length:inout size_t, _ chars:UInt8... ) -> Bool
  {
    cstr = c;
    if c < end
    {
      var cc = 0;
      let ccLen = chars.count;
      while s[c] != chars[cc]
      {
        cc += 1 ; if cc != ccLen { continue }
        cc = 0 ; c += 1 ; if ( c == end ) { break }
      }
    }
    length = c-cstr
    return c < end;
  }
  
  //-------------------------------------------------------------------------------------------
  // Skips to the given char
  @inline(__always)
  func skipToChar( _ ch:UInt8 )
  {
    while c < end && ( s[c] != ch ) {
        c += 1
    }
  }
  
  //-------------------------------------------------------------------------------------------
  // Skip spaces, returs, newlines and comments but not tabs
  func skip()
  {
    while c < end
    {
      if s[c] == _space || /*s[c] == _tab ||*/ s[c] == _return { c+=1; continue }
      if s[c] == _newline { c += 1; line += 1 ; continue }
      if s[c] == _pillow {
        c += 1;
        skipToChar( _newline );
        continue
      }
      break;
    }
  }
  
  //-------------------------------------------------------------------------------------------
  // Parse single character
  @inline(__always)
  func parseChar( _ ch:UInt8 ) -> Bool
  {
    if c < end && s[c] == ch {
      c += 1;
      return true
    }
    return false
  }

  //-------------------------------------------------------------------------------------------
  // Helper function to parse arbitrary tokens
  private func parseToken() -> Bool
  {
    if c < end && (
          (s[c] >= _a && s[c] <= _z) || (s[c] >= _A && s[c] <= _Z) ||
          (s[c] == _underscore ) /*|| (s[c] == _dollar) */ ) {

      c += 1 ;
      while c < end && (
        (s[c] >= _a && s[c] <= _z) || (s[c] >= _A && s[c] <= _Z) ||
        (s[c] >= _0 && s[c] <= _9) || (s[c] == _underscore) || (s[c] == _dot) ) {
          c += 1
      }
      return true
    }
    return false ;
  }

  //-------------------------------------------------------------------------------------------
  // Parse a Token. Return a wrapped data if successful or nil otherwhise
  func parseToken() -> Data?
  {
    let svc = c
    if ( parseToken() )
    {
      return s[svc..<c]
    }
    return nil
  }
  
  //-------------------------------------------------------------------------------------------
  // Parse a token with a given raw prefix. Return a wrapped data if successful or nil otherwhise
  func parsePrefixedToken( prefix:Data ) -> Data?
  {
    let svc = c
    let len = prefix.count
    if ( c+len <= end && prefix == s[c..<c+len] )
    {
      c = c + len
      if ( parseToken() )
      {
        return s[svc..<c]
      }
      c = svc
    }
    return nil ;
  }

  //-------------------------------------------------------------------------------------------
  // Parse an int. Return a wrapped Int if successful or nil otherwhise
  func parseInteger() -> Int?
  {
    let svc = c
    var minus = false
    var result:Int = 0
    
    if c < end && (s[c] == _minus)
    {
      minus = true
      c += 1
    }
    
    if c < end && (s[c] >= _0 && s[c] <= _9)
    {
      result = Int(s[c] - _0)
      c += 1
      
      while c < end && (s[c] >= _0 && s[c] <= _9)
      {
          result = result*10 + Int(s[c] - _0)
          c += 1
      }
      
      return ( minus ? -result : result )
    }
    c = svc;
    return nil ;
  }
  
  //-------------------------------------------------------------------------------------------
  // Parse a raw string. Returns true if the string is immediatelly identified
  // regardless of what's next
  func parseRawToken( cStr:Data ) -> Bool
  {
    let len = cStr.count
    if ( c+len < end && cStr == s[c..<c+len] )
    {
      c = c + len;
      return true;
    }
    return false ;
  }
  
  //-------------------------------------------------------------------------------------------
  // Parse a concrete token. Returns true if the token is identified
  // and the character after the token is not a valid token character
  func parseConcreteToken( cStr:Data ) -> Bool
  {
    let len = cStr.count
    if ( c+len <= end && cStr == s[c..<c+len] )
    {
      let ce = c+len;
      if ( ce < end && (
        (s[ce] >= _a && s[ce] <= _z) || (s[ce] >= _A && s[ce] <= _Z) ||
        (s[ce] >= _0 && s[ce] <= _9) || (s[ce] == _underscore) ) )
        {
          return false;
        }
        c = ce;
        return true;
    }
    return false ;
  }

  //-------------------------------------------------------------------------------------------
  // Parse a C string with optional escape characters
  func parseEscapedString() -> Data?
  {
    if parseChar( _quote )
    {
      let svc = c;
      while true
      {
        var string:Data? = nil;
        var cstr:Data.Index = 0;
        var len:size_t = 0;
        if skipToChar(cstr: &cstr, length: &len, _quote, _backSlash)
        {
          if ( string == nil ) { string = Data(s[cstr..<cstr+len]) }
          else { string!.append(s[cstr..<cstr+len]) }
          
          if parseChar( _quote )
          {
            return string
          }
          
          if parseChar( _backSlash )
          {
            var char:UInt8 = 0;
            if parseChar( _quote ) { char = _quote }
            else if parseChar( _backSlash ) { char = _backSlash }
            else if parseChar( UInt8(ascii:"n") ) { char = _newline }
            else if parseChar( UInt8(ascii:"r") ) { char = _return }
            else if parseChar( UInt8(ascii:"t") ) { char = _tab }
            
            if ( char != 0 ) {
              string!.append(char)
            }
          }
          continue
        }
        c = svc
        break
      }
    }
    return nil
  }

} // end of class PrimitiveParser












