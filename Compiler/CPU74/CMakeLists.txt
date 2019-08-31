set(LLVM_TARGET_DEFINITIONS CPU74.td)

tablegen(LLVM CPU74GenAsmWriter.inc -gen-asm-writer)
tablegen(LLVM CPU74GenCallingConv.inc -gen-callingconv)
tablegen(LLVM CPU74GenDAGISel.inc -gen-dag-isel)
tablegen(LLVM CPU74GenInstrInfo.inc -gen-instr-info)
tablegen(LLVM CPU74GenMCCodeEmitter.inc -gen-emitter)
tablegen(LLVM CPU74GenRegisterInfo.inc -gen-register-info)
tablegen(LLVM CPU74GenSubtargetInfo.inc -gen-subtarget)

add_public_tablegen_target(CPU74CommonTableGen)

add_llvm_target(CPU74CodeGen
  CPU74BranchSelector.cpp
  CPU74ISelDAGToDAG.cpp
  CPU74ISelLowering.cpp
  CPU74InstrInfo.cpp
  CPU74FrameLowering.cpp
  CPU74MachineFunctionInfo.cpp
  CPU74RegisterInfo.cpp
  CPU74Subtarget.cpp
  CPU74TargetMachine.cpp
  CPU74AsmPrinter.cpp
  CPU74MCInstLower.cpp
  CPU74TargetTransformInfo.cpp
  )

add_subdirectory(InstPrinter)
add_subdirectory(MCTargetDesc)
add_subdirectory(TargetInfo)
