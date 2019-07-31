//
//  ConsoleIO.swift
//  CPU74Assembler
//
//  Created by Joan on 13/06/19.
//  Copyright © 2019 Joan. All rights reserved.
//

import Foundation

enum OutputType
{
  case error
  case standard
}

// -----------------------------------------------------------------
// ConsoleIO
// -----------------------------------------------------------------
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
    out.println( "ERROR: \(message)", false )
    out.println( "Execution aborted, ERROR: \(message)", true )
    exit(1)
  }
}

// -----------------------------------------------------------------
let out:ConsoleIO = ConsoleIO();


// -----------------------------------------------------------------
// Console
// -----------------------------------------------------------------
class Console
{
  var command:String = "";
  var executableName:String = "";
  var path:String = "";
  var sources:[URL] = [];
  var destination:URL?;
  
  // -----------------------------------------------------------------
  func exitWithErr(_ message:String, withHint:Bool=false)
  {
    out.print("Error: \(message)", true);
    if withHint {out.print(". Try \(executableName) -h", true)}
    out.println();
    exit(0);
  }
  
  // -----------------------------------------------------------------
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
  
  // -----------------------------------------------------------------
  func printUsage()
  {
    let executableName = (CommandLine.arguments[0] as NSString).lastPathComponent
    out.println("Usage: \(executableName) [-s] [sources list] [-o destination]")
    out.println("Type \(executableName) -h to show usage information")
  }
  
  // -----------------------------------------------------------------
  func getURLfromArgument( _ arg:String, isSource:Bool ) -> URL
  {
      var source:URL = URL.init(fileURLWithPath:arg);
    
      if isSource && source.pathExtension != "s" {
          exitWithErr( "Source files must have 's' extension", withHint:true );
      }
    
      if source.pathComponents.count == 1  {
          let fileManager = FileManager.default;
          let path = fileManager.currentDirectoryPath;
          source = URL.init(fileURLWithPath:path).appendingPathComponent(arg);
      }
    
      if !isSource && source.pathExtension.count == 0 {
          source.appendPathExtension("c74");
      }
  
      return source;
  }

  // -----------------------------------------------------------------
  init()
  {
    let numArgs = Int(CommandLine.argc);
    var currOpt:Character = "s";
    executableName.append( (CommandLine.arguments[0] as NSString).lastPathComponent );
    command.append( executableName );
    for i:Int in 1 ..< numArgs {
        command.append(" ")
        command.append( CommandLine.arguments[i] );
    }
    
    path = CommandLine.arguments[0];
    out.println( path );
    
    for i:Int in 1..<numArgs
    {
      let arg = CommandLine.arguments[i];
      
      if arg[arg.startIndex] == "-" && arg.count >= 2
      {
        currOpt = arg[arg.index(after:arg.startIndex)];
        continue;
      }
  
      switch currOpt
      {
        case "s":
          let source = getURLfromArgument(arg, isSource:true);
          sources.append(source);
        
        case "o":
          if ( destination != nil ) {
              exitWithErr( "More than one destination specified" );
          }
          let dest = getURLfromArgument(arg, isSource:false);
          destination = dest;
        
        default:
          exitWithErr( "Unknown command line argument '-\(currOpt)'", withHint:true);
      }
    }
    
    if currOpt == "h" {
      printUsage();
      return;
    }
    
    if sources.count == 0 {
        exitWithErr( "No sources", withHint:true )
    }
    
    if destination == nil {
        let dest = sources[0].deletingPathExtension();
        destination = getURLfromArgument( dest.absoluteString, isSource:false);
    }
  }

} // console
