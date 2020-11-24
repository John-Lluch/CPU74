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
// C74_as
//
// Main class for the assembler
// Assembling is performed in two steps.
// - First step is a single pass source file parsing with generation
// of an internal representation of Sources including symbol table generation
// - Second step is the generation of the actual machine code by visiting and
// combining the internal representation into actual machine code
//-------------------------------------------------------------------------------------------

class C74_as
{
  // Assembler object instance
  let assembler = Assembler()
  
  //-------------------------------------------------------------------------------------------
  // Process a single source
  func parseSource(data:Data) -> Bool
  {
    // Create a Source instance and
    let source = Source()
    
    // Add the Source to the assembler
    assembler.addSource( source )
    
    // Pass the source along with the assembler object to a
    // new SourceParser instance for immediate parsing
    let sourceParser = SourceParser(withData:data, source:source, assembler:assembler)

    // Did it parse correctly?
    if sourceParser.parse()
    {
      // Add the Source to the assembler
      //assembler.addSource( source )
      out.logln()
      return true
    }
    return false
  }

  //-------------------------------------------------------------------------------------------
  // Process a single source file
  func parseSources() -> Bool
  {
  
    // Create the init code
    let initCode = assembler.getInitCode()
    if !parseSource(data:initCode) {
      out.printError( "Errors parsing init code" )
      return false
    }
    
    // Iterate all source files for individual processing
    for sourceURL in console.sources
    {
      out.logln( "-----" )
      out.logln( "\(sourceURL.absoluteString)" )
      
      // Read source file bytes into a Data object
      if let data:Data = out.read(url: sourceURL) {
        if parseSource(data:data) { continue }
      }

      out.printError( "Source file not found: \(sourceURL)" )
      break
    }
    
    // Create the setup code
    let dataCount = assembler.getDataValueCount()
    let setup = dataCount > 0 ? assembler.getSetupCode() : assembler.getSimpleSetupCode()
    if !parseSource(data:setup) {
      out.printError( "Errors parsing setup source" )
      return false
    }
    
    // If we get here something went wrong
    return true
  }
  

  
  //-------------------------------------------------------------------------------------------
  // Designated initializer
  init()
  {
    // Parse all source files for individual processing
    _ = parseSources()
    
    // Did we process all sources?
    if  assembler.sources.count == console.sources.count + 2
    {
      // Assemble all sources together
      //assembleSources()
      assembler.assemble()
      
      // Write out the machine code to the destination file
      out.write(data: assembler.programMemory, url: console.destination)
			
			// Write logisim data
      out.write(data:assembler.getLogisimData(), url:console.logisimDestination)
    }
    else { out.printError( "Number of sources mismatch" ) }
    
    // Output log file
    out.logln()
    out.logln( "Assembly completed" )
    out.writeLog()
    out.writeLogisimLog()
  }

} // class C74


//-------------------------------------------------------------------------------------------
// Main
//-------------------------------------------------------------------------------------------

let console = Console()
let c74_as = C74_as();






