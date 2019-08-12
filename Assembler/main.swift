//
//  main.swift
//  CPU74Assembler
//
//  Created by Joan on 19/05/19.
//  Copyright © 2019 Joan. All rights reserved.
//

import Foundation

//-------------------------------------------------------------------------------------------
// Global objects
//-------------------------------------------------------------------------------------------

let out = ConsoleIO()

//-------------------------------------------------------------------------------------------
// C74
//
// Main class for the assembler
// Assembling is performed in two steps.
// - First step is a single pass source file parsing with generation
// of an internal representation of Sources including symbol table generation
// - Second step is the generation of the actual machine code by visiting and
// combining the internal representation into actual machine code
//-------------------------------------------------------------------------------------------

class C74
{
  // Assembler object instance
  let assembler = Assembler()

  //-------------------------------------------------------------------------------------------
  // Process a single source file
  func processSourceFile( _ sourceURL:URL ) -> Bool
  {
    // Read source file bytes into s Data object
    if let data:Data = out.read(url: sourceURL)
    {
      out.logln( "-----" )
      out.logln( "\(sourceURL.absoluteString)" )
      
      // Create a Source instance and
      let source = Source()
      
      // Pass the source along with the assembler object to a
      // new SourceParser instance for immediate parsing
      let sourceParser = SourceParser(withData:data, source:source, assembler:assembler)

      // Did it parse correctly?
      if sourceParser.parse()
      {
        // Add the Source to the assembler
        assembler.addSource( source )
        out.logln()
        return true
      }
    }
    
    // If we get here something went wrong
    out.printError( "Source file not found: \(sourceURL)" )
    return false
  }
  
  
  //-------------------------------------------------------------------------------------------
  // Assemble all sources
  func assembleSources()
  {
    out.logln( "-----" )
    out.logln( "\(console.destination!.absoluteString)" )
    
    // Just invoque the assembler to do it
    assembler.assembleAll()
  }
  
  //-------------------------------------------------------------------------------------------
  // Designated initializer
  init()
  {
    // Iterate all source files for individual processing
    for sourceURL in console.sources
    {
      if !processSourceFile( sourceURL ) { break }
    }
    
    // Did we process all sources?
    if console.sources.count == assembler.sources.count
    {
      // Assemble all sources together
      assembleSources()
      
// TO DO :
// The CPU74 is a pure Harvard processor. As such it has no random access to program memory.
// This means that some strategy must be implemented to get constants
// and initialized variables ready in program memory before program execution begins
      
      // Write out the machine code to the destination file
      out.write(data: assembler.programMemory, url: console.destination)

      out.writeLog()
    }
  }

} // class C74


//-------------------------------------------------------------------------------------------
// Main
//-------------------------------------------------------------------------------------------

let console = Console()
let c74 = C74();






