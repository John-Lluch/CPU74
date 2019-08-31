//===-- CPU74ISelLowering.h - CPU74 DAG Lowering Interface ----*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines the interfaces that CPU74 uses to lower LLVM code into a
// selection DAG.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_CPU74_CPU74ISELLOWERING_H
#define LLVM_LIB_TARGET_CPU74_CPU74ISELLOWERING_H

#include "CPU74.h"
#include "llvm/CodeGen/SelectionDAG.h"
#include "llvm/CodeGen/TargetLowering.h"

namespace llvm
{
  namespace CPU74ISD
  {
    enum NodeType : unsigned
    {
      FIRST_NUMBER = ISD::BUILTIN_OP_END,

      /// Return with a flag operand. Operand 0 is the chain operand.
      RET_FLAG,

      /// Same as RET_FLAG, but used for returning from ISRs.
      RETI_FLAG,

//      /// Y = R{R,L}A X, rotate right (left) arithmetically
//      ASR, ASL,
//
//      /// Y = RRC X, rotate right via carry
//      LSRC,
      
      /// One bit shift
      LSL, LSR, ASR,
//      LSLO, LSRO, ASRO,
//      LSLC, LSRC, ASRC,
      
      /// 15 bit ASR
      SEXTW,
      
      // N bits shift Pseudo
      //LSLN, LSRN, ASRN,
      
      // Y = SWAP X, swap high and lower bytes
      //SWAP,

      // Location of passed argument on the stack
      //CallArgLoc,
      
      /// CALL - These operations represent an abstract call
      /// instruction, which includes a bunch of information.
      CALL,

      /// Wrapper - A wrapper node for TargetConstantPool, TargetExternalSymbol,
      /// and TargetGlobalAddress.
      //SingleValWrapper,
      AggregateWrapper,

      /// CMP - Compare instruction.
      CMP,
      
      // ADD, SUB tests
      ADD, SUB,
      
      // AND, OR, XOR tests
      AND, OR, XOR,
      
      /// ADDO, SUBO, ADDC, SUBC
      ADDO, SUBO, ADDC, SUBC,

      /// SetCC - Operand 0 is condition code, and operand 1 is the flag
      /// operand produced by a CMP instruction.
      //SETCC,

      /// CPU74 conditional branches. Operand 0 is the chain operand, operand 1
      /// is the block to branch if condition is true, operand 2 is the
      /// condition code, and operand 3 is the flag operand produced by a CMP
      /// instruction.
      BR_CC,

      /// SELECT_CC - Operand 0 and operand 1 are selection variable, operand 3
      /// is condition code and operand 4 is flag operand.
      //SELECT_CC,
      
      /// SET_CC - operand 1
      /// is condition code
      SET_CC,
      
      /// SEL_CC - Operand 0 and operand 1 are selection variable, operand 3
      /// is condition code
      SEL_CC,

      /// SHL, SRA, SRL - Non-constant shifts.
      //SHL, SRA, SRL,

    };
  }

  //class CPU74Subtarget;
  class CPU74TargetLowering : public TargetLowering {
  public:
    explicit CPU74TargetLowering(const CPU74TargetMachine &TM );

//    MVT getScalarShiftAmountTy(const DataLayout &, EVT) const override {
//      return MVT::i8;
//    }


//    bool allowsMisalignedMemoryAccesses(EVT VT, unsigned AddrSpace,
//                                        unsigned Align,
//                                        bool *Fast) const override;

    bool allowsMisalignedMemoryAccesses(EVT VT, unsigned AddrSpace,
                                        unsigned Align,
                                        MachineMemOperand::Flags Flags,
                                        bool *Fast) const override;

//    EVT getOptimalMemOpType(uint64_t Size,
//                            unsigned DstAlign, unsigned SrcAlign,
//                            bool IsMemset, bool ZeroMemset,
//                            bool MemcpyStrSrc, MachineFunction &MF) const override;
    
    EVT getOptimalMemOpType(uint64_t Size, unsigned DstAlign, unsigned SrcAlign,
                          bool IsMemset, bool ZeroMemset, bool MemcpyStrSrc,
                          const AttributeList &FuncAttributes) const override;
    
    bool isLegalAddressingMode(const DataLayout &DL,
                               const AddrMode &AM, Type *Ty,
                               unsigned AS, Instruction *I) const override;
    
    bool isLegalAddImmediate(int64_t Immed) const override;
    bool isLegalICmpImmediate(int64_t Immed) const override;

    /// LowerOperation - Provide custom lowering hooks for some operations.
    SDValue LowerOperation(SDValue Op, SelectionDAG &DAG) const override;
    void finalizeLowering(MachineFunction &MF) const override;

    /// getTargetNodeName - This method returns the name of a target specific
    /// DAG node.
    const char *getTargetNodeName(unsigned Opcode) const override;

  private:
    SDValue LowerShifts(SDValue Op, SelectionDAG &DAG) const;
    SDValue LowerUDIVREM(SDValue Op, SelectionDAG &DAG) const;
    SDValue LowerCLZ(SDValue Op, SelectionDAG &DAG) const;

    SDValue LowerGlobalAddress(SDValue Op, SelectionDAG &DAG) const;
    SDValue LowerBlockAddress(SDValue Op, SelectionDAG &DAG) const;
    SDValue LowerExternalSymbol(SDValue Op, SelectionDAG &DAG) const;
    SDValue LowerJumpTable(SDValue Op, SelectionDAG &DAG) const;
    SDValue LowerSETCC(SDValue Op, SelectionDAG &DAG) const;
    SDValue LowerSELECT_CC(SDValue Op, SelectionDAG &DAG) const;
    SDValue LowerBR_CC(SDValue Op, SelectionDAG &DAG) const;
    
    //SDValue LowerSHL_PARTS(SDValue Op, SelectionDAG &DAG) const;
    //SDValue LowerSELECT(SDValue Op, SelectionDAG &DAG) const;
    
    
    //SDValue LowerSIGN_EXTEND(SDValue Op, SelectionDAG &DAG) const;
    SDValue LowerDYNAMIC_STACKALLOC(SDValue Op, SelectionDAG &DAG) const;
    SDValue LowerRETURNADDR(SDValue Op, SelectionDAG &DAG) const;
    SDValue LowerFRAMEADDR(SDValue Op, SelectionDAG &DAG) const;
    SDValue LowerVASTART(SDValue Op, SelectionDAG &DAG) const;
    //SDValue LowerLoad(SDValue Op, SelectionDAG &DAG) const;
    SDValue LowerUALUO(SDValue Op, SelectionDAG &DAG) const;
    SDValue LowerADDSUBCARRY(SDValue Op, SelectionDAG &DAG) const;
    
//    SDValue getReturnAddressFrameIndex(SelectionDAG &DAG) const;

//    void ReplaceNodeResults(SDNode *N, SmallVectorImpl<SDValue> &Results,
//                            SelectionDAG &DAG) const override;

    TargetLowering::ConstraintType
    getConstraintType(StringRef Constraint) const override;
    
    std::pair<unsigned, const TargetRegisterClass *>
    getRegForInlineAsmConstraint(const TargetRegisterInfo *TRI,
                                 StringRef Constraint, MVT VT) const override;
    
    SDValue
    PerformDAGCombine(SDNode *N, DAGCombinerInfo &DCI) const override;

// comentat JLZ
//    /// isTruncateFree - Return true if it's free to truncate a value of type
//    /// Ty1 to type Ty2. e.g. On cpu74 it's free to truncate a i16 value in
//    /// register R15W to i8 by referencing its sub-register R15B.
//    bool isTruncateFree(Type *Ty1, Type *Ty2) const override;
//    bool isTruncateFree(EVT VT1, EVT VT2) const override;
//
//    /// isZExtFree - Return true if any actual instruction that defines a value
//    /// of type Ty1 implicit zero-extends the value to Ty2 in the result
//    /// register. This does not necessarily include registers defined in unknown
//    /// ways, such as incoming arguments, or copies from unknown virtual
//    /// registers. Also, if isTruncateFree(Ty2, Ty1) is true, this does not
//    /// necessarily apply to truncate instructions. e.g. on msp430, all
//    /// instructions that define 8-bit values implicit zero-extend the result
//    /// out to 16 bits.
//    bool isZExtFree(Type *Ty1, Type *Ty2) const override;
//    bool isZExtFree(EVT VT1, EVT VT2) const override;
//    bool isZExtFree(SDValue Val, EVT VT2) const override;

//    MachineBasicBlock *EmitInstrWithCustomInserter(MachineInstr &MI, MachineBasicBlock *BB) const override;
//    MachineBasicBlock *EmitSelectCC(MachineInstr &MI, MachineBasicBlock *BB) const;
//    MachineBasicBlock *EmitShiftInstr(MachineInstr &MI, MachineBasicBlock *BB) const;

  private:
//    SDValue LowerCCCCallTo(SDValue Chain, SDValue Callee,
//                           CallingConv::ID CallConv, bool isVarArg,
//                           bool isTailCall,
//                           const SmallVectorImpl<ISD::OutputArg> &Outs,
//                           const SmallVectorImpl<SDValue> &OutVals,
//                           const SmallVectorImpl<ISD::InputArg> &Ins,
//                           const SDLoc &dl, SelectionDAG &DAG,
//                           SmallVectorImpl<SDValue> &InVals) const;

//    SDValue LowerCCCArguments(SDValue Chain, CallingConv::ID CallConv,
//                              bool isVarArg,
//                              const SmallVectorImpl<ISD::InputArg> &Ins,
//                              const SDLoc &dl, SelectionDAG &DAG,
//                              SmallVectorImpl<SDValue> &InVals) const;

//    SDValue LowerCallResult(SDValue Chain, SDValue InFlag,
//                            CallingConv::ID CallConv, bool isVarArg,
//                            const SmallVectorImpl<ISD::InputArg> &Ins,
//                            const SDLoc &dl, SelectionDAG &DAG,
//                            SmallVectorImpl<SDValue> &InVals) const;

    SDValue LowerFormalArguments(SDValue Chain, CallingConv::ID CallConv, bool isVarArg,
                         const SmallVectorImpl<ISD::InputArg> &Ins,
                         const SDLoc &dl, SelectionDAG &DAG,
                         SmallVectorImpl<SDValue> &InVals) const override;
    
    SDValue LowerCall(TargetLowering::CallLoweringInfo &CLI,
                SmallVectorImpl<SDValue> &InVals) const override;

    bool CanLowerReturn(CallingConv::ID CallConv,
                        MachineFunction &MF,
                        bool IsVarArg,
                        const SmallVectorImpl<ISD::OutputArg> &Outs,
                        LLVMContext &Context) const override;

    SDValue LowerReturn(SDValue Chain, CallingConv::ID CallConv, bool isVarArg,
                        const SmallVectorImpl<ISD::OutputArg> &Outs,
                        const SmallVectorImpl<SDValue> &OutVals,
                        const SDLoc &dl, SelectionDAG &DAG) const override;

//    bool getPostIndexedAddressParts(SDNode *N, SDNode *Op,
//                                    SDValue &Base,
//                                    SDValue &Offset,
//                                    ISD::MemIndexedMode &AM,
//                                    SelectionDAG &DAG) const override;
    
    
    private:
      void AnalyzeCommutableLibCall(
          SmallVectorImpl<ISD::OutputArg> *Outs, SmallVectorImpl<SDValue> *OutVals ) const;
      unsigned AnalyzeCommutableLibCallRecurse( SDValue Op ) const;
      SDValue ExpandLibCall(RTLIB::Libcall LC, SDNode *Node, SelectionDAG &DAG) const;
      SDValue ExpandLibCall(const char *name, CallingConv::ID callConv, SDNode *Node, SelectionDAG &DAG) const;

    
  };
} // namespace llvm

#endif
