//
//  CPU74TargetTransformInfo.h
//  LLVM
//
//  Created by Joan on 05/06/19.
//

#ifndef CPU74TargetTransformInfo_h
#define CPU74TargetTransformInfo_h

#include "CPU74.h"
#include "CPU74Subtarget.h"
#include "CPU74TargetMachine.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/Analysis/TargetTransformInfo.h"
#include "llvm/CodeGen/BasicTTIImpl.h"
#include "llvm/IR/Constant.h"
#include "llvm/IR/Function.h"
#include "llvm/MC/SubtargetFeature.h"

namespace llvm
{
class CPU74TTIImpl : public BasicTTIImplBase<CPU74TTIImpl>
{
  using BaseT = BasicTTIImplBase<CPU74TTIImpl>;
  using TTI = TargetTransformInfo;

  //friend class BasicTTIImplBase<BasicTTIImpl>;
  friend BaseT;

  const CPU74Subtarget *ST;
  const CPU74TargetLowering *TLI;

  const CPU74Subtarget *getST() const { return ST; }
  const CPU74TargetLowering *getTLI() const { return TLI; }

public:
  explicit CPU74TTIImpl(const CPU74TargetMachine *TM, const Function &F)
      : BaseT(TM, F.getParent()->getDataLayout()), ST(TM->getSubtargetImpl(F)),
        TLI(ST->getTargetLowering()) {}
  
  bool isLSRCostLess(TargetTransformInfo::LSRCost &C1,
                     TargetTransformInfo::LSRCost &C2);
  
  unsigned getNumberOfRegisters(bool Vector) const {
    return Vector ? 0 : 8;
  }
  
  unsigned getRegisterBitWidth(bool Vector) const {
    return Vector ? 0 : 16;
  }
  
};


} // end namespace llvm
























#endif /* CPU74TargetTransformInfo_h */
