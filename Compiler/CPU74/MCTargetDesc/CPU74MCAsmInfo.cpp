//===-- CPU74MCAsmInfo.cpp - CPU74 asm properties -----------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the declarations of the CPU74MCAsmInfo properties.
//
//===----------------------------------------------------------------------===//

#include "CPU74MCAsmInfo.h"
using namespace llvm;

CPU74MCAsmInfo::CPU74MCAsmInfo(const Triple &TT)
{
  CodePointerSize = 2;
  CalleeSaveStackSlotSize = 2;
  MinInstAlignment = 2;
//
//  CommentString = ";";
//
  AlignmentIsInBytes = true;
  
  //UsesELFSectionDirectiveForBSS = true;
  HasDotTypeDotSizeDirective = false;

  HasFunctionAlignment = false;
  
  PrivateGlobalPrefix = ".G";
  PrivateLabelPrefix = ".L";
  
  InlineAsmStart = " InlineAsm Start";
  InlineAsmEnd = " InlineAsm End";

}
