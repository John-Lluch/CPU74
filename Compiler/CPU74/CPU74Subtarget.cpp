//===-- CPU74Subtarget.cpp - CPU74 Subtarget Information ----------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements the CPU74 specific subclass of TargetSubtargetInfo.
//
//===----------------------------------------------------------------------===//


#include "CPU74.h"
#include "CPU74Subtarget.h"
#include "CPU74TargetMachine.h"
#include "llvm/Support/TargetRegistry.h"

using namespace llvm;

#define DEBUG_TYPE "cpu74-subtarget"


#define GET_SUBTARGETINFO_TARGET_DESC
#define GET_SUBTARGETINFO_CTOR
#include "CPU74GenSubtargetInfo.inc"


CPU74Subtarget::CPU74Subtarget(const Triple &TT, const std::string &CPU,
                               const std::string &FS, const CPU74TargetMachine &TM)
    : CPU74GenSubtargetInfo(TT, CPU, FS), InstrInfo(), FrameLowering(), TLInfo(TM), TSInfo()

{
    ParseSubtargetFeatures(CPU, FS);
}



