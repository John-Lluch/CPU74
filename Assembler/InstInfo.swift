//
//  InstInfo.swift
//  c74-as
//
//  Created by Joan on 28/06/19.
//  Copyright © 2019 Joan. All rights reserved.
//

import Foundation


class MachineInstr
{
//  var asmStr:Data;
//  var altStr:Data;
  
//  init( _ str:Data, _ alt:Data )
//  {
//    asmStr = str;
//    altStr = alt;
//  }
}

class Inst16:MachineInstr
{
  var encoding:UInt16 = 0
}

class Inst32:Inst16
{
  var immword:UInt16 = 0
}

// Relative call/jump
class Type1:Inst16
{
  required init( /*str:Data, alt:Data,*/ op:UInt16, a:UInt16 )
  {
    //super.init(str, alt);
    super.init()
    encoding |= (0b111)       << 13
    encoding |= (0b1 & op)    << 12
    encoding |= (0b11111111111 & a) << 0
  }
}

// Conditional branch
class Type2:Inst16
{
  init( /*str:Data, alt:Data,*/ cc:UInt16, a:UInt16 )
  {
    //super.init(str, alt);
    super.init()
    encoding |= (0b1101)       << 12
    encoding |= (0b111 & cc)   << 9
    encoding |= (0b11111111&a) << 0
  }
}

// Conditional set
class Type3:Inst16
{
  init( /*str:Data, alt:Data,*/ op:UInt16, cc:UInt16, rd:UInt16 )
  {
    //super.init(str, alt);
    super.init()
    encoding |= (0b0000)     << 12
    encoding |= (0b111 & cc) << 9
    encoding |= (0b11)       << 7
    encoding |= (0b1   & op) << 6
    encoding |= (0b000)      << 3
    encoding |= (0b111 & rd) << 0
  }
}

// Conditional select
class Type4:Inst16
{
  init( /*str:Data, alt:Data,*/ cc:UInt16, rn:UInt16, rs:UInt16, rd:UInt16 )
  {
    //super.init(str, alt);
    super.init()
    encoding |= (0b0001)      << 12
    encoding |= (0b111 & cc)  << 9
    encoding |= (0b111 & rn)  << 6
    encoding |= (0b111 & rs)  << 3
    encoding |= (0b111 & rd)  << 0
  }
}

// Three register ALU operation,
// Load/store with register offset
class Type5:Inst16
{
  init( /*str:Data, alt:Data,*/ op:UInt16, rn:UInt16, rs:UInt16, rd:UInt16 )
  {
    //super.init(str, alt);
    super.init()
    encoding |= (0b001)        << 13
    encoding |= (0b1111 & op)  << 9
    encoding |= (0b111  & rn)  << 6
    encoding |= (0b111  & rs)  << 3
    encoding |= (0b111  & rd)  << 0
  }
}

// And/or immediate
class Type6:Inst16
{
  init( /*str:Data, alt:Data,*/ op:UInt16, rd:UInt16, k:UInt16 )
  {
    //super.init(str, alt);
    super.init()
    encoding |= (0b1100)       << 12
    encoding |= (0b111 & rd)   << 9
    encoding |= (0b1)          << 8
    encoding |= (0b11  & op)   << 6
    encoding |= (0b111111 & k) << 0
  }
}

// Load/store with immediate offset
class Type7:Inst16
{
  init( /*str:Data, alt:Data,*/ op:UInt16, rn:UInt16, rd:UInt16, k:UInt16 )
  {
    //super.init(str, alt);
    super.init()
    encoding |= (0b10)         << 14
    encoding |= (0b11   & op)  << 12
    encoding |= (0b111  & rd)  << 9
    encoding |= (0b111  & rn)  << 6
    encoding |= (0b111111 & k) << 0
  }
}

// Move, Compare, Add, Subtract immediate
class Type8:Inst16
{
  init( /*str:Data, alt:Data,*/ op:UInt16, rd:UInt16, k:UInt16 )
  {
    //super.init(str, alt);
    super.init()
    encoding |= (0b01)            << 14
    encoding |= (0b11  & op)      << 12
    encoding |= (0b111 & rd)      << 9
    encoding |= (0b1)             << 8
    encoding |= (0b11111111 & k)  << 0
  }
}

// SP relative load/store
class Type9:Inst16
{
  init( /*str:Data, alt:Data,*/ op:UInt16, rd:UInt16, k:UInt16 )
  {
    //super.init(str, alt);
    super.init()
    encoding |= (0b01)            << 14
    encoding |= (0b11  & op)      << 12
    encoding |= (0b111 & rd)      << 9
    encoding |= (0b0)             << 8
    encoding |= (0b11111111 & k)  << 0
  }
}

// Add/Subtract offset to SP
class Type10:Inst16
{
  init( /*str:Data, alt:Data,*/ op:UInt16, k:UInt16 )
  {
    //super.init(str, alt);
    super.init()
    encoding |= (0b1100)          << 12
    encoding |= (0b1  & op)       << 11
    encoding |= (0b00)            << 9
    encoding |= (0b0)             << 8
    encoding |= (0b11111111 & k)  << 0
  }
}

// Push/Pop, move SP Register, Branch/Call Indirect,
class Type11:Inst16
{
  init( /*str:Data, alt:Data,*/ op:UInt16, mode:UInt16, rd:UInt16 )
  {
    //super.init(str, alt);
    super.init()
    encoding |= (0b0000)          << 12
    encoding |= (0b111 & op)      << 9
    encoding |= (0b00)            << 7
    encoding |= (0b11 & mode)     << 5
    encoding |= (0b00)            << 3
    encoding |= (0b111 & rd)      << 0
  }
}

// Move immediate, Load/store with absolute address
class Type11b:Inst32
{
  init( /*str:Data, alt:Data,*/ op:UInt16, mode:UInt16, rd:UInt16, a:UInt16 )
  {
    //super.init(str, alt);
    super.init()
    encoding |= (0b0000)        << 12
    encoding |= (0b111 & op)    << 9
    encoding |= (0b00)          << 7
    encoding |= (0b11  & mode)  << 5
    encoding |= (0b00)          << 3
    encoding |= (0b111 & rd)    << 0
    immword = a
  }
}

// Zero Operand Instructions
class Type12:Inst16
{
  init( /*str:Data, alt:Data,*/ op:UInt16, mode:UInt16, rd:UInt16 )
  {
    //super.init(str, alt);
    super.init()
    encoding |= (0b0000)        << 12
    encoding |= (0b111 & op)    << 9
    encoding |= (0b01)          << 7
    encoding |= (0b11  & mode)  << 5
    encoding |= (0b00)          << 3
    encoding |= (0b000)         << 0
  }
}

// Two register Move, Compare, ALU operation
class Type13:Inst16
{
  init( /*str:Data, alt:Data,*/ op:UInt16, rn:UInt16, rs:UInt16, rd:UInt16 )
  {
    //super.init(str, alt);
    super.init()
    encoding |= (0b0000)       << 12
    encoding |= (0b111 & op)   << 9
    encoding |= (0b00)         << 7
    encoding |= (0b111 & rs)   << 3
    encoding |= (0b111 & rd)   << 0
  }
}


class InstrList
{
  static let allInstr:Dictionary<Instruction, Any> =
  [
    Instruction( "call".d, false, [OpReg(false), OpSym(false)] )               : Type1.self,
    Instruction( "ld".d,   false, [OpReg(false), OpReg(false)] )               : Type1.self,
    Instruction( "add".d,  false, [OpReg(false), OpReg(false), OpReg(false)] ) : Type2.self,
  ]
  
  
  static func getMachineInst( inst:Instruction ) -> MachineInstr
  {
    let typ = allInstr[inst]
    switch typ
    {
      case is Type1.Type:
        return Type1( op:UInt16(inst.ops[0].value), a:0 )
    
      default: break
    }
  
    return Type1( op:UInt16(inst.ops[0].value), a:0 )
  }

//  func test()
//  {
//
//    let typ = allInstr[Instruction("mov".d, "ld".d,  Operand(), Operand(), Operand())];
//    let typ0 = Type1.self;
//    var i:Instr?
//
//    switch typ
//    {
//      case is Type1.Type:
//          let pp = typ0.init(str: <#T##Data#>, alt: <#T##Data#>, op: <#T##UInt16#>, a: <#T##UInt16#>)
//          i = Type1(str: <#T##Data#>, alt: <#T##Data#>, op: <#T##UInt16#>, a: <#T##UInt16#>)
//
//      case is Type2.Type: break
//      default: break
//    }
//
//    if typ is Type1.Type
//    {
//
//    }
  
  
//    let typ = Type1.self;
//    let per = Instr( "mov".data(using:.ascii)!, "ld".data(using:.ascii)! )
//    let pp = typ.init(str: <#T##Data#>, alt: <#T##Data#>, op: <#T##UInt16#>, a: <#T##UInt16#>)
//    if ( typ is Type2.Type )
//    {
//
//    }
//    pp.immword = 33;
//  }
}
