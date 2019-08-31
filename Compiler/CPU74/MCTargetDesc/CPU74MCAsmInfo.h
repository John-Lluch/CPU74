//===-- CPU74MCAsmInfo.h - CPU74 asm properties --------------*- C++ -*--===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the declaration of the CPU74MCAsmInfo class.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_CPU74_MCTARGETDESC_CPU74MCASMINFO_H
#define LLVM_LIB_TARGET_CPU74_MCTARGETDESC_CPU74MCASMINFO_H

#include "llvm/MC/MCAsmInfoELF.h"

namespace llvm {
class Triple;

class CPU74MCAsmInfo : public MCAsmInfo /*ELF*/ {

public:
  explicit CPU74MCAsmInfo(const Triple &TT);
};

} // namespace llvm

#endif
