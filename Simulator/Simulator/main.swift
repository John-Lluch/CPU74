//
//  main.swift
//  Simulator
//
//  Created by Joan on 17/08/19.
//  Copyright © 2019 Joan. All rights reserved.
//


import Foundation

//-------------------------------------------------------------------------------------------
// Global objects
//-------------------------------------------------------------------------------------------

let out = ConsoleIO()

//-------------------------------------------------------------------------------------------
// C74_sim
//
// Main class for the assembler
// Assembling is performed in two steps.
// - First step is a single pass source file parsing with generation
// of an internal representation of Sources including symbol table generation
// - Second step is the generation of the actual machine code by visiting and
// combining the internal representation into actual machine code
//-------------------------------------------------------------------------------------------

class C74_sim
{
  // Machine object instance
  let machine = Machine()

  //-------------------------------------------------------------------------------------------
  // Process a single source file
  func executeSourceFile( _ sourceURL:URL ) -> Bool
  {
    // Read source file bytes into a Data object
    if let data:Data = out.read(url: sourceURL)
    {
      out.logln( "-----" )
      out.logln( "\(sourceURL.absoluteString)" )
      
      // Pass the source to the simulator for immediate execution
      machine.loadProgram(source: data)
      machine.reset()

      // Did it parse correctly?
      if machine.run()
      {
        out.logln()
        return true
      }
    }
    
    // If we get here something went wrong
    out.printError( "Source file not found: \(sourceURL)" )
    return false
  }
  
  
  //-------------------------------------------------------------------------------------------
  // Designated initializer
  init()
  {
    // Iterate all source files for individual processing
    if let sourceURL = console.source
    {
      _ = executeSourceFile( sourceURL )
    }
    
    out.writeLog()
  }

} // class C74_sim


//-------------------------------------------------------------------------------------------
// Main
//-------------------------------------------------------------------------------------------

let console = Console()
let c74_sim = C74_sim()


