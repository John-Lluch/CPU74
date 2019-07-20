//
//  main.swift
//  CPU74Assembler
//
//  Created by Joan on 19/05/19.
//  Copyright © 2019 Joan. All rights reserved.
//

import Foundation


//-------------------------------------------------------------------------------------------
// C74
//-------------------------------------------------------------------------------------------

class C74
{
  var assembler = Assembler()

  //-------------------------------------------------------------------------------------------
  func processSourceFile( _ sourceURL:URL ) -> Bool
  {
    let data = try! Data(contentsOf:sourceURL)
    let source = Source()
    let sourceParser = SourceParser(withData:data, source:source, assembler:assembler)
    if sourceParser.parseAll()
    {
      assembler.addSource( source )
      return true
    }
    return false
  }
  
  //-------------------------------------------------------------------------------------------
  init()
  {
    for sourceURL in console.sources
    {
      if !processSourceFile(sourceURL) { break }
    }
    
    if console.sources.count == assembler.sources.count
    {
      assembler.assembleAll()
    }
  }

} // class C74


//-------------------------------------------------------------------------------------------
// Main
//-------------------------------------------------------------------------------------------
let console = Console()
let c74 = C74();






