//===-- CPU74MCTargetDesc.h - CPU74 Target Descriptions -------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file provides CPU74 specific target descriptions.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_CPU74_MCTARGETDESC_CPU74MCTARGETDESC_H
#define LLVM_LIB_TARGET_CPU74_MCTARGETDESC_CPU74MCTARGETDESC_H

#include "llvm/Support/DataTypes.h"

namespace llvm
{

//class MCAsmBackend;
class MCCodeEmitter;
class MCContext;
class MCInstrInfo;
//class MCObjectTargetWriter;
class MCRegisterInfo;
//class MCSubtargetInfo;
//class MCTargetOptions;

class Target;

Target &getTheCPU74Target();

/// Creates a machine code emitter for CPU74.
MCCodeEmitter *createCPU74MCCodeEmitter(const MCInstrInfo &MCII,
                                        const MCRegisterInfo &MRI,
                                        MCContext &Ctx);
  
/// Creates an assembly backend for CPU74.
//MCAsmBackend *createCPU74AsmBackend(const Target &T, const MCSubtargetInfo &STI,
//                                    const MCRegisterInfo &MRI,
//                                    const MCTargetOptions &Options);

} // End llvm namespace

// Defines symbolic names for CPU74 registers.
// This defines a mapping from register name to register number.
#define GET_REGINFO_ENUM
#include "CPU74GenRegisterInfo.inc"

// Defines symbolic names for the CPU74 instructions.
#define GET_INSTRINFO_ENUM
#include "CPU74GenInstrInfo.inc"

#define GET_SUBTARGETINFO_ENUM
#include "CPU74GenSubtargetInfo.inc"

#endif
