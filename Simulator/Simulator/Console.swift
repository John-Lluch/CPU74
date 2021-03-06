//
//  Console.swift
//  c74-sim
//
//  Created by Joan on 17/08/19.
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
    println( message, false )
    let s = "ERROR: \(message)"
    logln( s )
  }
  
  func exitWithError( _ message:String )
  {
    printError( message )
    writeLog()
    
    println( "Execution aborted. \(message)", true )
    exit(1)
  }
  
  var logFile:URL?
  var logData:String?
  
  func enableLog( _ url:URL? )
  {
    logFile = url
    logData = url != nil ? String() : nil
  }
  
  var logEnabled:Bool { return logData != nil }
  
  func log( _ s:String )
  {
    if logData == nil { return }
    logData!.append( s )
    print( s )  // aqui
  }
  
  func logln( _ s:String = "" )
  {
    log( s )
    log( "\n" )
  }
  
  func writeLog()
  {
    if logData != nil {
      try! logData!.write(to:logFile!, atomically:false, encoding:.utf8)
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
  
  func getKeyPress() -> Int
  {
    var key: Int = 0
    let c: cc_t = 0
    let cct = (c, c, c, c, c, c, c, c, c, c, c, c, c, c, c, c, c, c, c, c) // Set of 20 Special Characters
    var oldt: termios = termios(c_iflag: 0, c_oflag: 0, c_cflag: 0, c_lflag: 0, c_cc: cct, c_ispeed: 0, c_ospeed: 0)

    tcgetattr(STDIN_FILENO, &oldt) // 1473
    var newt = oldt
    newt.c_lflag = 1217  // Reset ICANON and Echo off
    tcsetattr( STDIN_FILENO, TCSANOW, &newt)
    key = Int(getchar())  // works like "getch()"
    tcsetattr( STDIN_FILENO, TCSANOW, &oldt)
    return key
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
  var source:URL?               // Source files url array
  var logFile:URL?                     // Log file url
  
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
    out.print( "Source: ");
    out.println( source != nil ? source!.absoluteString : "(nil)" );
  }
  
  //-------------------------------------------------------------------------------
  // This actually executes the -h command option
  func printUsage()
  {
    let executableName = (CommandLine.arguments[0] as NSString).lastPathComponent
    out.println("Usage: \(executableName) [-x] [executable] [-l [log]]")
    out.println("Type \(executableName) -h to show usage information")
  }
  
  //-------------------------------------------------------------------------------
  // Helper function to create a suitable URL object from a suitable argument
  func newURLfromArgument( _ arg:String, isSource:Bool, useExtension:String? = nil ) -> URL
  {
      var url:URL = URL.init(fileURLWithPath:arg);
    
      if isSource && url.pathExtension != "c74" {
          exitWithErr( "Source file must have 'c74' extension", withHint:true );
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
    var currOpt:Character = "x"
    
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
          case "x": break
          
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
          case "x":
            if source != nil { exitWithErr( "Only one source allowed" ) }
            source = newURLfromArgument(arg, isSource:true )
        
          case "l":
            if logFile != nil { exitWithErr( "Only one log file allowed" ) }
            logFile = newURLfromArgument(arg, isSource:false, useExtension:"log")
            currOpt = "\0"
      
          default: break
        }
      }
    } // end for
    
    // No more arguments...
    // Perfom some late checks and update default properties where needed
    
    if source == nil
    {
      exitWithErr( "No sources", withHint:true )
    }
    
    if wantsLog
    {
      if logFile == nil
      {
        let log = source!.deletingPathExtension();
        logFile = newURLfromArgument( log.absoluteString, isSource:false, useExtension:"slog");
      }
      out.enableLog( logFile )
    }
  }

}



