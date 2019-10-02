//===-- CPU74TargetMachine.cpp - Define TargetMachine for CPU74 ---------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// Top-level implementation for the CPU74 target.
//
//===----------------------------------------------------------------------===//

#include "CPU74TargetMachine.h"
#include "CPU74.h"
#include "CPU74TargetTransformInfo.h"
#include "llvm/CodeGen/Passes.h"
#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"
#include "llvm/CodeGen/TargetPassConfig.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/Support/TargetRegistry.h"
using namespace llvm;

extern "C" void LLVMInitializeCPU74Target() {
  // Register the target.
  RegisterTargetMachine<CPU74TargetMachine> X(getTheCPU74Target());
}

static Reloc::Model getEffectiveRelocModel(Optional<Reloc::Model> RM) {
  if (!RM.hasValue())
    return Reloc::Static;
  return *RM;
}

static CodeModel::Model getEffectiveCodeModel(Optional<CodeModel::Model> CM) {
  if (CM)
    return *CM;
  return CodeModel::Small;
}

static std::string computeDataLayout(const Triple &TT, StringRef CPU,
                                     const TargetOptions &Options) {
  //return "e-m:e-p:16:16-i32:16-i64:16-f32:16-f64:16-a:8-n8:16-S16";
  //return "e-m:o-p:16:16-i1:8-i8:8-i16:16-i32:16-i64:16-f32:16-f64:16-a:8:16-n16-S16";
  return "e-m:e-p:16:16-i1:8-i8:8-i16:16-i32:16-i64:16-f32:16-f64:16-a:8:16-n16-S16";
  //return   "e-p:16:16-i1:8-i8:8-i16:16-i32:16-i64:16-f32:16-f64:16-a:8:16-n16-S16-P1";
}

/**
@brief Creates a CPU74 machine architecture.
** The data layout is described as below:
*
*  Meaning of symbols:
*  Symbol    | Definition                                       |
*  :-------- | :--:                                             |
*   e        | little endian                                    |
*   p:16:16  | pointer size: pointer ABI alignment              |
*   i1:32:16  | integer data type : size of type : ABI alignment |
*   n8:16      | all 32 bit registers are available               |
*
*/

CPU74TargetMachine::CPU74TargetMachine(const Target &T, const Triple &TT,
                                         StringRef CPU, StringRef FS,
                                         const TargetOptions &Options,
                                         Optional<Reloc::Model> RM,
                                         Optional<CodeModel::Model> CM,
                                         CodeGenOpt::Level OL, bool JIT)
    : LLVMTargetMachine(T, computeDataLayout(TT, CPU, Options), TT, CPU, FS,
                        Options, getEffectiveRelocModel(RM),
                        getEffectiveCodeModel(CM, CodeModel::Small), OL),
                        TLOF(make_unique<TargetLoweringObjectFileELF>()),
                        //TLOF(make_unique<TargetLoweringObjectFileMachO>()),  // aixo fa petar el AsmPrinter perque no troba seccions
                        Subtarget(TT, CPU, FS, *this)
{
  initAsmInfo();
}

// --------------- Pass configurator -----------------------

CPU74TargetMachine::~CPU74TargetMachine() {}

namespace
{
/// CPU74 Code Generator Pass Configuration Options.
class CPU74PassConfig : public TargetPassConfig {
public:
  CPU74PassConfig(CPU74TargetMachine &TM, PassManagerBase &PM)
    : TargetPassConfig(TM, PM) {}

  CPU74TargetMachine &getCPU74TargetMachine() const {
    return getTM<CPU74TargetMachine>();
  }

  void addIRPasses() override;
  void addCodeGenPrepare() override;
  void addISelPrepare() override;
  bool addInstSelector() override;
  void addPreEmitPass() override;
};
} // namespace

TargetPassConfig *CPU74TargetMachine::createPassConfig(PassManagerBase &PM) {
  return new CPU74PassConfig(*this, PM);
}

TargetTransformInfo CPU74TargetMachine::getTargetTransformInfo(const Function &F)
{
  return TargetTransformInfo(CPU74TTIImpl(this, F));
}

void CPU74PassConfig::addIRPasses()
{
  addPass( createAlignVisitPass() );
  TargetPassConfig::addIRPasses();
}

void CPU74PassConfig::addCodeGenPrepare()
{
  TargetPassConfig::addCodeGenPrepare();
}

void CPU74PassConfig::addISelPrepare()
{
  TargetPassConfig::addISelPrepare();
}

bool CPU74PassConfig::addInstSelector()
{
  // Install an instruction selector.
  addPass(createCPU74ISelDag(getCPU74TargetMachine(), getOptLevel()));
  
  // Add the frame amalyzer pass that is required by PEI pass
//  addPass( createCPU74FrameAnalyzerPass());
  return false;
}

void CPU74PassConfig::addPreEmitPass() {
  // Must run branch selection immediately preceding the asm printer.
  addPass(createCPU74BranchSelectionPass(), false);
}




