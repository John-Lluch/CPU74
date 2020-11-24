//
//  ConsoleIO.swift
//  CPU74Assembler
//
//  Created by Joan on 13/06/19.
//  Copyright © 2019 Joan. All rights reserved.
//

import Foundation

//-------------------------------------------------------------------------------
// ConsoleIO
//
// Provides basic infrastructure for displaying error messages, debug loging
// reading and writting data objects to files
//-------------------------------------------------------------------------------

enum OutputType
{
  case error
  case standard
}

class ConsoleIO
{
  func println(_ message:String="", _ isError:Bool=false) {
    fputs("\(message)\n", isError ? stderr : stdout);
  }
  
  func print(_ message:String, _ isError:Bool=false) {
    fputs("\(message)", isError ? stderr : stdout);
  }
  
  func printError( _ message:String )
  {
    let s = "ERROR: \(message)"
    logln( s )
    
    println( s, false )
    println( "Execution aborted. \(s)", true )
  }
  
  func exitWithError( _ message:String )
  {
    printError( message )
    writeLog()
    exit(1)
  }
  
  var logFile:URL?
  var logisimLogFile:URL?
  var logData:String?
  var logisimLogData:String?
  
  func enableLog( _ url:URL?, _ logisimUrl:URL?)
  {
    logFile = url
    logisimLogFile = logisimUrl
    logData = url != nil ? String() : nil
    logisimLogData = logisimUrl != nil ? String() : nil
  }
  
  var logEnabled:Bool { return logData != nil }
  
  func log( _ s:String )
  {
    if logData == nil { return }
    
    print( s );
    logData!.append( s )
  }
  
  func logln( _ s:String = "" )
  {
    log( s )
    log( "\n" )
  }
  
  func logisimLog( _ s:String )
  {
    if logisimLogData == nil { return }
    
    logisimLogData!.append( s )
  }
  
  func logisimLogln( _ s:String = "" )
  {
    logisimLog( s )
    logisimLog( "\n" )
  }
  
  func writeLog()
  {
    if logData != nil {
      try! logData!.write(to:logFile!, atomically:false, encoding:.utf8)
    }
  }
  
  func writeLogisimLog()
  {
    if logisimLogData != nil {
      try! logisimLogData!.write(to:logisimLogFile!, atomically:false, encoding:.utf8)
    }
  }
  
  
  func write( data:Data?, url:URL? )
  {
    if url != nil && data != nil {
      try! data!.write(to:url!)
    }
  }
  
  func read( url:URL? ) -> Data?
  {
    if url != nil {
      return try? Data(contentsOf:url!)
    }
    return nil
  }
}

//-------------------------------------------------------------------------------
// Console
//
// Reads the console command line to identify source files, the output file and a few
// more options. The command line is immediatelly read and the class properties updated
// upon initializing of an object instance, so that's the only thing it needs to be done
// See printUsage() implementation for a summary on the available command options
//-------------------------------------------------------------------------------

class Console
{
  var command:String = ""              // Contains the entire command line
  var executableName:String = ""       // This project executable file name
  var path:String = ""                 // The current path
  let DefaultExtension = "c74"         // The default destination extension
  var sources:[URL] = []               // Source files url array
  var destination:URL?                 // Destination file url
  var logisimDestination:URL?          // Logisim Destination file url
  var logFile:URL?                     // Log file url
  var logisimLogFile:URL?            // Logisim Source Destination file url
  
  //-------------------------------------------------------------------------------
  // Exit executable with an error
  func exitWithErr(_ message:String, withHint:Bool=false)
  {
    out.print("Error: \(message)", true);
    if withHint {out.print(". Try \(executableName) -h", true)}
    out.println();
    exit(1);
  }
  
  //-------------------------------------------------------------------------------
  // Helper function for debug purposes
  func dump()
  { 
      out.println( command );
      out.print( "Destination: ");
      out.println( destination!.absoluteString );
    
      for source in sources
      {
        out.print( "Source: ");
        out.println( source.absoluteString );
      }
  }
  
  //-------------------------------------------------------------------------------
  // This actually executes the -h command option
  func printUsage()
  {
    let executableName = (CommandLine.arguments[0] as NSString).lastPathComponent
    out.println("Usage: \(executableName) [-s] [sources list] [-o [destination]] [-l [log]]")
    out.println("Type \(executableName) -h to show usage information")
  }
  
  //-------------------------------------------------------------------------------
  // Helper function to create a suitable URL object from a suitable argument
  func newURLfromArgument( _ arg:String, isSource:Bool, useExtension:String? = nil ) -> URL
  {
      var url:URL = URL.init(fileURLWithPath:arg);
    
      if isSource && url.pathExtension != "s" {
          exitWithErr( "Source files must have 's' extension", withHint:true );
      }
    
      if url.pathComponents.count == 1  {
          let fileManager = FileManager.default;
          let path = fileManager.currentDirectoryPath;
          url = URL.init(fileURLWithPath:path).appendingPathComponent(arg);
      }
    
      if !isSource && useExtension != nil && url.pathExtension.count == 0
      {
        url.appendPathExtension(useExtension!)
      }
      return url
  }
  
  //-------------------------------------------------------------------------------
  // Designated initializer. This actually scans the command line
  init()
  {
    let numArgs = Int(CommandLine.argc)
    var wantsLog = false
    var currOpt:Character = "s"
    
    executableName.append( (CommandLine.arguments[0] as NSString).lastPathComponent )
    command.append( executableName )
    for i:Int in 1 ..< numArgs
    {
        command.append(" ")
        command.append( CommandLine.arguments[i] )
    }
    
    path = CommandLine.arguments[0]
    out.println( path )
  
    for i:Int in 1..<numArgs
    {
      // Obtain new argument
      let arg = CommandLine.arguments[i]
    
      // Is this a new option arrive?
      if arg[arg.startIndex] == "-" && arg.count >= 2
      {
        // Process or store it as the current option for further processing
        currOpt = arg[arg.index(after:arg.startIndex)]
        switch currOpt
        {
          case "s": break
          case "o": break
          
          case "l":
            wantsLog = true
        
          case "h":
            printUsage()
            return
        
          default:
            exitWithErr( "Unknown command line argument '-\(currOpt)'", withHint:true);
        }
      }
    
      // Argument belongs to the stored option
      else
      {
        switch currOpt
        {
          case "s":
            let source = newURLfromArgument(arg, isSource:true)
            sources.append(source)
        
          case "o":
            if destination != nil { exitWithErr( "Only one destination allowed" ) }
            destination = newURLfromArgument(arg, isSource:false, useExtension:DefaultExtension)
        
          case "l":
            if logFile != nil { exitWithErr( "Only one log file allowed" ) }
            logFile = newURLfromArgument(arg, isSource:false, useExtension:"log")
      
          default: break
        }
      }
    } // end for
    
    // No more arguments...
    // Perfom some late checks and update default properties where needed
    
    if sources.count == 0
    {
      exitWithErr( "No sources", withHint:true )
    }
    
    if destination == nil
    {
      let dest = sources[0].deletingPathExtension();
      destination = newURLfromArgument( dest.absoluteString, isSource:false, useExtension:DefaultExtension);
    }
    
    if logisimDestination == nil
    {
      let dest = destination!.deletingPathExtension();
      logisimDestination = newURLfromArgument( dest.absoluteString, isSource:false, useExtension:"txt");
    }
    
    if wantsLog
    {
      if logFile == nil
      {
        let log = destination!.deletingPathExtension();
        logFile = newURLfromArgument( log.absoluteString, isSource:false, useExtension:"log");
        logisimLogFile = newURLfromArgument( log.absoluteString+"_log", isSource:false, useExtension:"txt");
      }
      out.enableLog( logFile, logisimLogFile )
    }
  }


} // End class Console
