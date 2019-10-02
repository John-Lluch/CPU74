//
//  CPU74TargetTransformInfo.cpp
//  LLVM
//
//  Created by Joan on 05/06/19.
//

#include "CPU74TargetTransformInfo.h"
#include "llvm/Analysis/TargetTransformInfo.h"
//#include "llvm/CodeGen/BasicTTIImpl.h"

using namespace llvm;


bool CPU74TTIImpl::isLSRCostLess(TargetTransformInfo::LSRCost &C1,
                               TargetTransformInfo::LSRCost &C2)
{
    // CPU74 specific here are "instruction number 1st priority".
    bool value = std::tie(C1.Insns, C1.NumRegs, C1.AddRecCost,
                    C1.NumIVMuls, C1.NumBaseAdds,
                    C1.ScaleCost, C1.ImmCost, C1.SetupCost) <
           std::tie(C2.Insns, C2.NumRegs, C2.AddRecCost,
                    C2.NumIVMuls, C2.NumBaseAdds,
                    C2.ScaleCost, C2.ImmCost, C2.SetupCost);
  
//    bool value = std::tie(C1.NumRegs, C1.AddRecCost, C1.NumIVMuls, C1.NumBaseAdds,
//                    C1.ScaleCost, C1.ImmCost, C1.SetupCost) <
//           std::tie(C2.NumRegs, C2.AddRecCost, C2.NumIVMuls, C2.NumBaseAdds,
//                    C2.ScaleCost, C2.ImmCost, C2.SetupCost);
    return value;
}

//unsigned CPU74TTIImpl::getOperationCost(unsigned Opcode, Type *Ty, Type *OpTy)
//{
//  // Add some CPU74 expensive instructions that were not explicitly included
//  // in the default implementation.
//  // See getOperationCost in TargetTransformInfoImplBase.h
//  switch (Opcode)
//  {
//    //case Instruction::GetElementPtr:  // Mirar aixo
//    //case Instruction::Add:
//    case Instruction::Mul:
//    case Instruction::UDiv:
//    case Instruction::SDiv:
//    case Instruction::URem:
//    case Instruction::SRem:
//    //case Instruction::And:
//    //case Instruction::Or:
//    //case Instruction::Select:
//    case Instruction::Shl:
//    //case Instruction::Sub:
//    case Instruction::LShr:
//    case Instruction::AShr:
//    //case Instruction::Xor:
//    //case Instruction::ZExt:
//    //case Instruction::SExt:
//    //case Instruction::Call:
//    //case Instruction::BitCast:
//    //case Instruction::PtrToInt:
//    //case Instruction::IntToPtr:
//    //case Instruction::AddrSpaceCast:
//    case Instruction::FPToUI:
//    case Instruction::FPToSI:
//    case Instruction::UIToFP:
//    case Instruction::SIToFP:
//    case Instruction::FPExt:
//    case Instruction::FPTrunc:
//    case Instruction::FAdd:
//    case Instruction::FSub:
//    case Instruction::FMul:
//    case Instruction::FDiv:
//    case Instruction::FRem:
//    case Instruction::FNeg:
//    //case Instruction::ICmp:
//    case Instruction::FCmp:
//      return TTI::TCC_Expensive;
//  }
//
//  // Big operands are expensive
//  unsigned OpSize = Ty->getScalarSizeInBits();
//  if ( OpSize > 16 )
//    return TTI::TCC_Expensive;
//
//  return BaseT::getOperationCost(Opcode, Ty, OpTy);
//}

unsigned CPU74TTIImpl::getUserCost(const User *U, ArrayRef<const Value *> Operands)
{
  unsigned Opcode = Operator::getOpcode(U);
  Type *Ty = U->getType();
  
  // Add some CPU74 expensive instructions that were not explicitly included
  // in the default implementation.
  // See getOperationCost in TargetTransformInfoImplBase.h
  switch (Opcode)
  {
    //case Instruction::GetElementPtr:  // Mirar aixo
    case Instruction::Mul:
    case Instruction::UDiv:
    case Instruction::SDiv:
    case Instruction::URem:
    case Instruction::SRem:
    case Instruction::Shl:
    case Instruction::LShr:
    case Instruction::AShr:
    case Instruction::FPToUI:
    case Instruction::FPToSI:
    case Instruction::UIToFP:
    case Instruction::SIToFP:
    case Instruction::FPExt:
    case Instruction::FPTrunc:
    case Instruction::FAdd:
    case Instruction::FSub:
    case Instruction::FMul:
    case Instruction::FDiv:
    case Instruction::FRem:
    case Instruction::FNeg:
    case Instruction::FCmp:
      return TTI::TCC_Expensive;
  }

  // Big operands are expensive
  unsigned OpSize = Ty->getScalarSizeInBits();
  if ( OpSize > 16 )
    return TTI::TCC_Expensive;

  // Else return the default implementation
  return BaseT::getUserCost(U, Operands);
}




