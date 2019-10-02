//===-- CPU74BranchSelector.cpp - Emit long conditional branches ---------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains a pass that scans a machine function to determine which
// conditional branches need more than 10 bits of displacement to reach their
// target basic block.  It does this in two passes; a calculation of basic block
// positions pass, and a branch pseudo op to machine branch opcode pass.  This
// pass should be run last, just before the assembly printer.
//
//===----------------------------------------------------------------------===//

#include "CPU74.h"
#include "CPU74InstrInfo.h"
#include "CPU74Subtarget.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/Support/MathExtras.h"
#include "llvm/Target/TargetMachine.h"
using namespace llvm;

#define DEBUG_TYPE "cpu74-branch-select"

static cl::opt<bool>
    BranchSelectEnabled("cpu74-branch-select", cl::Hidden, cl::init(true),
                        cl::desc("Expand out of range branches"));

STATISTIC(NumSplit, "Number of machine basic blocks split");
STATISTIC(NumExpanded, "Number of branches expanded to long format");

namespace {
class CPU74BSel : public MachineFunctionPass {

  typedef SmallVector<int, 16> OffsetVector;

  MachineFunction *MF;
  const CPU74InstrInfo *TII;

  unsigned measureFunction(OffsetVector &BlockOffsets,
                           MachineBasicBlock *FromBB = nullptr);
  bool expandBranches(OffsetVector &BlockOffsets);

public:
  static char ID;
  CPU74BSel() : MachineFunctionPass(ID) {}

  bool runOnMachineFunction(MachineFunction &MF) override;

  MachineFunctionProperties getRequiredProperties() const override {
    return MachineFunctionProperties().set(
        MachineFunctionProperties::Property::NoVRegs);
  }

  StringRef getPassName() const override { return "CPU74 Branch Selector"; }
};
char CPU74BSel::ID = 0;
}

/// Returns true if the specified Distance fits in a core branch instruction
static bool isInRage(int DistanceInBytes) {
  // CPU74 core branch
  // instructions have the signed 9-bit word offset field, so first we need to
  // convert the distance from bytes to words, then check if it fits in 9-bit
  // signed integer.
  const int WordSize = 2;

  assert((DistanceInBytes % WordSize == 0) &&
         "Branch offset should be word aligned!");

  int Words = DistanceInBytes / WordSize;
  return isInt<9>(Words);
}

/// Measure each basic block, fill the BlockOffsets, and return the size of
/// the function, starting with BB
unsigned CPU74BSel::measureFunction(OffsetVector &BlockOffsets,
                                     MachineBasicBlock *FromBB) {
  // Give the blocks of the function a dense, in-order, numbering.
  MF->RenumberBlocks(FromBB);

  MachineFunction::iterator Begin;
  if (FromBB == nullptr) {
    Begin = MF->begin();
  } else {
    Begin = FromBB->getIterator();
  }

  BlockOffsets.resize(MF->getNumBlockIDs());

  unsigned TotalSize = BlockOffsets[Begin->getNumber()];
  for (auto &MBB : make_range(Begin, MF->end())) {
    BlockOffsets[MBB.getNumber()] = TotalSize;
    for (MachineInstr &MI : MBB) {
      TotalSize += TII->getInstSizeInBytes(MI);
    }
  }
  return TotalSize;
}

/// Do expand branches and split the basic blocks if necessary.
/// Returns true if made any change.
bool CPU74BSel::expandBranches(OffsetVector &BlockOffsets)
{
  // For each conditional branch, if the offset to its destination is larger
  // than the offset field allows, transform it into a prefixed branch instruction
  bool MadeChange = false;
  for (auto MBB = MF->begin(), E = MF->end(); MBB != E; ++MBB)
  {
    unsigned MBBStartOffset = 0;
    for (auto MI = MBB->begin(), EE = MBB->end(); MI != EE; ++MI)
    {
      MBBStartOffset += TII->getInstSizeInBytes(*MI);

      // If this instruction is not a short branch then skip it.
      if (MI->getOpcode() != CPU74::BRCC_core && MI->getOpcode() != CPU74::JMP_core) {
        continue;
      }

      MachineBasicBlock *DestBB = MI->getOperand(0).getMBB();
      // Determine the distance from the current branch to the destination
      // block. MBBStartOffset already includes the size of the current branch
      // instruction.
      int BlockDistance = BlockOffsets[DestBB->getNumber()] - BlockOffsets[MBB->getNumber()];
      int BranchDistance = BlockDistance - MBBStartOffset;
      BranchDistance -= 2 ; // compensate for the PC pointing always to the next instruction

      // If this branch is in range, ignore it.
      if (isInRage(BranchDistance)) {
        continue;
      }

      LLVM_DEBUG(dbgs() << "  Found a branch that needs expanding, "
                        << printMBBReference(*DestBB) << ", Distance "
                        << BranchDistance << "\n");
      
      int InstrSizeDiff = -TII->getInstSizeInBytes(*MI);
      
      unsigned newOpCode = 0;
      switch ( MI->getOpcode() )
      {
        default: llvm_unreachable("Unsupported opcode entering expandBranches");
        case CPU74::BRCC_core : newOpCode = CPU74::BRCC_pfix; break;
        case CPU74::JMP_core : newOpCode = CPU74::JMP_pfix; break;
      }
      
      MI->setDesc(TII->get(newOpCode));
      
      InstrSizeDiff += TII->getInstSizeInBytes(*MI);
    
      // The size of a new instruction is different from the old one, so we need
      // to correct all block offsets.
      for (int i = MBB->getNumber() + 1, e = BlockOffsets.size(); i < e; ++i)
      {
        BlockOffsets[i] += InstrSizeDiff;
      }
      MBBStartOffset += InstrSizeDiff;

      ++NumExpanded;
      MadeChange = true;
    }
  }
  return MadeChange;
}

// Pass Entry point
bool CPU74BSel::runOnMachineFunction(MachineFunction &mf)
{
  MF = &mf;
  TII = static_cast<const CPU74InstrInfo *>(MF->getSubtarget().getInstrInfo());

  // If the pass is disabled, just bail early.
  if (!BranchSelectEnabled)
    return false;

  LLVM_DEBUG(dbgs() << "\n********** " << getPassName() << " **********\n");

  // BlockOffsets - Contains the distance from the beginning of the function to
  // the beginning of each basic block.
  OffsetVector BlockOffsets;

  unsigned FunctionSize = measureFunction(BlockOffsets);
  // If the entire function is smaller than the displacement of a branch field,
  // we know we don't need to expand any branches in this
  // function. This is a common case.
  if (isInRage(FunctionSize)) {
    return false;
  }

  // Iteratively expand branches until we reach a fixed point.
  bool MadeChange = false;
  while (expandBranches(BlockOffsets))
    MadeChange = true;

  return MadeChange;
}

/// Returns an instance of the Branch Selection Pass
FunctionPass *llvm::createCPU74BranchSelectionPass() {
  return new CPU74BSel();
}
