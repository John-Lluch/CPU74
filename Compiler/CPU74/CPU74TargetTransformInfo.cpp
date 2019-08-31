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
  
    return value;
  
//    return std::tie(C1.NumRegs, C1.AddRecCost, C1.NumIVMuls, C1.NumBaseAdds,
//                    C1.ScaleCost, C1.ImmCost, C1.SetupCost) <
//           std::tie(C2.NumRegs, C2.AddRecCost, C2.NumIVMuls, C2.NumBaseAdds,
//                    C2.ScaleCost, C2.ImmCost, C2.SetupCost);
}
