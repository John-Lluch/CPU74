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

static bool isInRage(int DistanceInBytes) {
  // According to CC430 Family User's Guide, Section 4.5.1.3, branch
  // instructions have the signed 10-bit word offset field, so first we need to
  // convert the distance from bytes to words, then check if it fits in 10-bit
  // signed integer.
  const int WordSize = 2;

  assert((DistanceInBytes % WordSize == 0) &&
         "Branch offset should be word aligned!");

  int Words = DistanceInBytes / WordSize;
  return isInt<10>(Words);
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
bool CPU74BSel::expandBranches(OffsetVector &BlockOffsets) {
  // For each conditional branch, if the offset to its destination is larger
  // than the offset field allows, transform it into a long branch sequence
  // like this:
  //   short branch:
  //     bCC MBB
  //   long branch:
  //     b!CC $PC+6
  //     b MBB
  //
  bool MadeChange = false;
  for (auto MBB = MF->begin(), E = MF->end(); MBB != E; ++MBB) {
    unsigned MBBStartOffset = 0;
    for (auto MI = MBB->begin(), EE = MBB->end(); MI != EE; ++MI) {
      MBBStartOffset += TII->getInstSizeInBytes(*MI);

      // If this instruction is not a short branch then skip it.
      if (MI->getOpcode() != CPU74::BRCC && MI->getOpcode() != CPU74::JMP) {
        continue;
      }

      MachineBasicBlock *DestBB = MI->getOperand(0).getMBB();
      // Determine the distance from the current branch to the destination
      // block. MBBStartOffset already includes the size of the current branch
      // instruction.
      int BlockDistance =
          BlockOffsets[DestBB->getNumber()] - BlockOffsets[MBB->getNumber()];
      int BranchDistance = BlockDistance - MBBStartOffset;

      // If this branch is in range, ignore it.
      if (isInRage(BranchDistance)) {
        continue;
      }

      LLVM_DEBUG(dbgs() << "  Found a branch that needs expanding, "
                        << printMBBReference(*DestBB) << ", Distance "
                        << BranchDistance << "\n");

      // If BRCC is not the last instruction we need to split the MBB.
      if (MI->getOpcode() == CPU74::BRCC && std::next(MI) != EE) {

        LLVM_DEBUG(dbgs() << "  Found a basic block that needs to be split, "
                          << printMBBReference(*MBB) << "\n");

        // Create a new basic block.
        MachineBasicBlock *NewBB =
            MF->CreateMachineBasicBlock(MBB->getBasicBlock());
        MF->insert(std::next(MBB), NewBB);

        // Splice the instructions following MI over to the NewBB.
        NewBB->splice(NewBB->end(), &*MBB, std::next(MI), MBB->end());

        // Update the successor lists.
        for (MachineBasicBlock *Succ : MBB->successors()) {
          if (Succ == DestBB) {
            continue;
          }
          MBB->replaceSuccessor(Succ, NewBB);
          NewBB->addSuccessor(Succ);
        }

        // We introduced a new MBB so all following blocks should be numbered
        // and measured again.
        measureFunction(BlockOffsets, &*MBB);

        ++NumSplit;

        // It may be not necessary to start all over at this point, but it's
        // safer do this anyway.
        return true;
      }

      MachineInstr &OldBranch = *MI;
      DebugLoc dl = OldBranch.getDebugLoc();
      int InstrSizeDiff = -TII->getInstSizeInBytes(OldBranch);

      if (MI->getOpcode() == CPU74::BRCC) {
        MachineBasicBlock *NextMBB = &*std::next(MBB);
        assert(MBB->isSuccessor(NextMBB) &&
               "This block must have a layout successor!");

        // The BCC operands are:
        // 0. Target MBB
        // 1. CPU74 branch predicate
        SmallVector<MachineOperand, 1> Cond;
        Cond.push_back(MI->getOperand(1));

        // Jump over the long branch on the opposite condition
        TII->reverseBranchCondition(Cond);
        MI = BuildMI(*MBB, MI, dl, TII->get(CPU74::BRCC))
                 .addMBB(NextMBB)
                 .add(Cond[0]);
        InstrSizeDiff += TII->getInstSizeInBytes(*MI);
        ++MI;
      }

      // Unconditional branch to the real destination.
      //JLZ Aqui hi avia aixo:  MI = BuildMI(*MBB, MI, dl, TII->get(CPU74::Bi)).addMBB(DestBB);
      //JLZ No en tinc ni idea del que fara aixo:
      MI = BuildMI(*MBB, MI, dl, TII->get(CPU74::JMP)).addMBB(DestBB);
      //JLZ O seria millor aixo?  MI = BuildMI(*MBB, MI, dl, TII->get(CPU74::JMPReg)).addMBB(DestBB);
      
      
      InstrSizeDiff += TII->getInstSizeInBytes(*MI);

      // Remove the old branch from the function.
      OldBranch.eraseFromParent();

      // The size of a new instruction is different from the old one, so we need
      // to correct all block offsets.
      for (int i = MBB->getNumber() + 1, e = BlockOffsets.size(); i < e; ++i) {
        BlockOffsets[i] += InstrSizeDiff;
      }
      MBBStartOffset += InstrSizeDiff;

      ++NumExpanded;
      MadeChange = true;
    }
  }
  return MadeChange;
}

bool CPU74BSel::runOnMachineFunction(MachineFunction &mf) {
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