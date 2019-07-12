//
//  main.swift
//  CPU74Assembler
//
//  Created by Joan on 19/05/19.
//  Copyright © 2019 Joan. All rights reserved.
//

import Foundation


/////////////////////////////////////////////////////////////////
// C74
/////////////////////////////////////////////////////////////////
class C74
{
  var sources = [Source]();
 
 
  //-------------------------------------------------------------------------------------------
  func processSources() -> Bool
  {
    for sourceURL in console.sources
    {
      let data = try! Data(contentsOf:sourceURL);
      let source = Source()
      let sourceParser = SourceParser(withData:data, source:source)
      if sourceParser.parseAll()
      {
        source.assemble()
        sources.append(source)
        continue
      }
      break
    }
    
    return sources.count == console.sources.count;
  }

  //-------------------------------------------------------------------------------------------
  func linkSources() -> Bool
  {
    return true
  }
  
  //-------------------------------------------------------------------------------------------
  init()
  {
    if console.sources.count == 0
    {
      return
    }
    
    if !processSources()
    {
      return
    }
  
    if !linkSources()
    {
      return
    }
  }

} // class C74


//-------------------------------------------------------------------------------------------
let console = Console()
let c74 = C74();

//if console.sources.count > 0
//{
//  if !c74.parseSources()
//  {
//    exit(0)
//  }
//
//  if !c74.linkSources()
//  {
//    exit(0)
//  }
//
//}





