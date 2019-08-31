//===-- CPU74ISelLowering.cpp - CPU74 DAG Lowering Implementation  ------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements the CPU74TargetLowering class.
//
//===----------------------------------------------------------------------===//

#include "CPU74ISelLowering.h"

#include "CPU74InstrInfo.h"
#include "CPU74MachineFunctionInfo.h"
//#include "CPU74Subtarget.h"
#include "CPU74TargetMachine.h"
#include "llvm/CodeGen/CallingConvLower.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/SelectionDAGISel.h"
#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"
#include "llvm/CodeGen/ValueTypes.h"
#include "llvm/IR/CallingConv.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"

//#include "llvm/IR/ConstantRange.h"
using namespace llvm;

#define DEBUG_TYPE "cpu74-lower"

CPU74TargetLowering::CPU74TargetLowering(const CPU74TargetMachine &TM /*jlz, const CPU74Subtarget &STI*/)
    : TargetLowering(TM) {

  // Set up the register classes.
  addRegisterClass(MVT::i16, &CPU74::GR16RegClass);
  setStackPointerRegisterToSaveRestore(CPU74::SP);

  // Provide all sorts of operation actions
  setBooleanContents(ZeroOrOneBooleanContent);
  setBooleanVectorContents(ZeroOrOneBooleanContent); // FIXME: Is this correct?

  // We have post-incremented loads / stores.
//  setIndexedLoadAction(ISD::POST_INC, MVT::i8, Legal);   // JLZ
//  setIndexedLoadAction(ISD::POST_INC, MVT::i16, Legal);

  for (MVT VT : MVT::integer_valuetypes())
  {
    setLoadExtAction(ISD::EXTLOAD,  VT, MVT::i1,  Promote);
    setLoadExtAction(ISD::SEXTLOAD, VT, MVT::i1,  Promote);
    setLoadExtAction(ISD::ZEXTLOAD, VT, MVT::i1,  Promote);
    // JLZ setLoadExtAction(ISD::SEXTLOAD, VT, MVT::i8,  Expand);
    // JLZ setLoadExtAction(ISD::SEXTLOAD, VT, MVT::i16, Expand);
    
    //setLoadExtAction(ISD::NON_EXTLOAD, VT, MVT::i16, Promote);
    //setLoadExtAction(ISD::NON_EXTLOAD, VT, MVT::i8, Promote);
  }

  // We don't have any truncstores
  //JLZ setTruncStoreAction(MVT::i16, MVT::i8, Expand);
  
  
  setOperationAction(ISD::SHL_PARTS,        MVT::i16,   Expand);
  //setOperationAction(ISD::SHL_PARTS,        MVT::i32,   Expand);
  setOperationAction(ISD::SRL_PARTS,        MVT::i16,   Expand);
  //setOperationAction(ISD::SRL_PARTS,        MVT::i32,   Expand);
  setOperationAction(ISD::SRA_PARTS,        MVT::i16,   Expand);
  //setOperationAction(ISD::SRA_PARTS,        MVT::i32,   Expand);

  setOperationAction(ISD::SRA,              MVT::i16,   Custom);
  setOperationAction(ISD::SHL,              MVT::i16,   Custom);
  setOperationAction(ISD::SRL,              MVT::i16,   Custom);
  //setOperationAction(ISD::SRA,              MVT::i32,   Expand); // aqui
  //setOperationAction(ISD::SHL,              MVT::i32,   Expand); // aqui
  //setOperationAction(ISD::SRL,              MVT::i32,   Expand); // aqui
  
//  setOperationAction(ISD::SRA,              MVT::i16,   LibCall);
//  setOperationAction(ISD::SHL,              MVT::i16,   LibCall);
//  setOperationAction(ISD::SRL,              MVT::i16,   LibCall);
  
  setOperationAction(ISD::ROTL,             MVT::i16,   Expand);
  setOperationAction(ISD::ROTR,             MVT::i16,   Expand);
  

  
  
  setOperationAction(ISD::CTTZ,             MVT::i16,   Custom);
  //setOperationAction(ISD::CTTZ,             MVT::i16,   LibCall);
  setOperationAction(ISD::CTLZ,             MVT::i16,   Custom);
  //setOperationAction(ISD::CTLZ,             MVT::i16,   LibCall);
  setOperationAction(ISD::CTPOP,            MVT::i16,   Expand);
  //setOperationAction(ISD::CTPOP,            MVT::i16,   LibCall);
  
  //setOperationAction(ISD::Constant,         MVT::i16,   Legal);      // JLZ

  setOperationAction(ISD::GlobalAddress,    MVT::i16,   Custom);
  setOperationAction(ISD::ExternalSymbol,   MVT::i16,   Custom);
  setOperationAction(ISD::BlockAddress,     MVT::i16,   Custom);
  setOperationAction(ISD::JumpTable,        MVT::i16,   Custom);
  
// JLZ afegit
    setOperationAction(ISD::SELECT,           MVT::i16,   Expand);
    setOperationAction(ISD::BRCOND,           MVT::Other, Expand);
    
    setOperationAction(ISD::SETCC,            MVT::i16,   Custom);
    setOperationAction(ISD::SELECT_CC,        MVT::i16,   Custom);
    setOperationAction(ISD::BR_CC,            MVT::i16,   Custom);
    
    setOperationAction(ISD::BR_JT,            MVT::Other, Expand);

  //setOperationAction(ISD::SIGN_EXTEND,      MVT::i16,   Custom);
  //setOperationAction(ISD::DYNAMIC_STACKALLOC, MVT::i16, Expand);
  setOperationAction(ISD::DYNAMIC_STACKALLOC, MVT::i16, Custom);
  setOperationAction(ISD::STACKSAVE, MVT::Other, Expand);
  setOperationAction(ISD::STACKRESTORE, MVT::Other, Expand);

  setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::i1,   Expand);
  
  setOperationAction(ISD::UADDO,             MVT::i16, Custom);
  setOperationAction(ISD::USUBO,             MVT::i16, Custom);
  setOperationAction(ISD::ADDCARRY,          MVT::i16, Custom);
  setOperationAction(ISD::SUBCARRY,          MVT::i16, Custom);
  
  setOperationAction(ISD::MUL,              MVT::i16,   LibCall);
  setOperationAction(ISD::MULHS,            MVT::i16,   Expand);
  setOperationAction(ISD::MULHU,            MVT::i16,   Expand);
  setOperationAction(ISD::SMUL_LOHI,        MVT::i16,   Expand);
  setOperationAction(ISD::UMUL_LOHI,        MVT::i16,   Expand);

  setOperationAction(ISD::UDIV,             MVT::i16,   LibCall);
  setOperationAction(ISD::UREM,             MVT::i16,   LibCall);
  setOperationAction(ISD::UDIVREM,          MVT::i16,   Expand);
  setOperationAction(ISD::SDIV,             MVT::i16,   LibCall);
  setOperationAction(ISD::SREM,             MVT::i16,   LibCall);
  setOperationAction(ISD::SDIVREM,          MVT::i16,   Expand);

  // varargs support
  setOperationAction(ISD::VASTART,          MVT::Other, Custom);
  setOperationAction(ISD::VAARG,            MVT::Other, Expand);
  setOperationAction(ISD::VAEND,            MVT::Other, Expand);
  setOperationAction(ISD::VACOPY,           MVT::Other, Expand);


  // Compute derived properties from the register classes
  // This is tells LLVM the native/allowed data types for this target
  const CPU74Subtarget &STI = *TM.getSubtargetImpl();
  computeRegisterProperties(STI.getRegisterInfo());
  
  
  struct LibCallsStruct
  {
    const RTLIB::Libcall Op;
    const char * const Name;
    unsigned CallingConv;
  };
  
  const LibCallsStruct LibraryCalls[] =
  {
  
    { RTLIB::MEMSET, NULL /* "_memset"*/, CallingConv::CPU74_RTLIB },    // memset
    { RTLIB::MEMCPY, NULL /* "_memcpy"*/, CallingConv::CPU74_RTLIB },    // memcpy
    { RTLIB::MEMMOVE, NULL /* "_memmove"*/, CallingConv::CPU74_RTLIB },    // memmove
  
    // TO DO : Implement RTLIB::BZERO
  
    // Integer multiply
    { RTLIB::MUL_I16, NULL /* "_mul16"*/, CallingConv::CPU74_RTLIB },  // __mulhi3
    { RTLIB::MUL_I32, NULL /* "_mul32"*/, CallingConv::CPU74_RTLIB },   // __mulsi3
    
    // Signed integer divide
    { RTLIB::SDIV_I16, NULL /* "__div16"*/, CallingConv::CPU74_RTLIB },     // __divhi3
    { RTLIB::SDIV_I32, NULL  /*"__div32"*/, CallingConv::CPU74_RTLIB },     // __divsi3
      
    // Unsigned integer divide
    { RTLIB::UDIV_I16, NULL  /*"__cpu74_divui"*/, CallingConv::CPU74_RTLIB },     // __udivhi3
    { RTLIB::UDIV_I32, NULL  /*"__mspabi_divul"*/, CallingConv::CPU74_RTLIB },     // __udivsi3
    
    { RTLIB::SDIVREM_I16, "__cpu74_sdivrem16", CallingConv::CPU74_RTLIB },     //
    { RTLIB::SDIVREM_I32, "__cpu74_sdivrem32", CallingConv::CPU74_RTLIB },     //
    
    { RTLIB::UDIVREM_I16, "__cpu74_udivrem16", CallingConv::CPU74_RTLIB },     //
    { RTLIB::UDIVREM_I32, "__cpu74_udivrem32", CallingConv::CPU74_RTLIB },     //
      
    // Signed integer remainder
    { RTLIB::SREM_I16, NULL  /*"__cpu74_remi"*/, CallingConv::CPU74_RTLIB },     // __modhi3
    { RTLIB::SREM_I32, NULL  /*"__mspabi_reml"*/, CallingConv::CPU74_RTLIB },     // __modsi3
      
    // Unsigned integer remainder
    { RTLIB::UREM_I16, NULL  /*"__cpu74_remui"*/, CallingConv::CPU74_RTLIB },     // __umodhi3
    { RTLIB::UREM_I32, NULL  /*"__mspabi_remul"*/, CallingConv::CPU74_RTLIB },     // __umodsi3
    
    // TO DO implement RTLIB::SDIVREM_I16, RTLIB::SDIVREM_I32
    
    // Logical shift left
    { RTLIB::SHL_I16, NULL  /*"__cpu74_lsli"*/, CallingConv::CPU74_RTLIB  },     // __ashlhi3
    { RTLIB::SHL_I32, NULL  /*"__cpu74_lsll"*/, CallingConv::CPU74_RTLIB  },     // __ashlsi3
    
    // Logical shift right
    { RTLIB::SRL_I16, NULL  /*"__lsr16"*/, CallingConv::CPU74_RTLIB  },      // __lshrhi3
    { RTLIB::SRL_I32, NULL  /*"__lsr32"*/, CallingConv::CPU74_RTLIB  },      // __lshrsi3
    
    // Arithmetic shift right
    { RTLIB::SRA_I16, NULL  /*"__asr16"*/, CallingConv::CPU74_RTLIB  },      // __ashrhi3
    { RTLIB::SRA_I32, NULL  /*"__asr32"*/, CallingConv::CPU74_RTLIB  },      // __ashrsi3
  };
    
  for (const auto &LC : LibraryCalls)
  {
      if ( LC.Name )
        setLibcallName( LC.Op, LC.Name );
    
      if ( LC.CallingConv )
        setLibcallCallingConv(LC.Op, LC.CallingConv );
  }
  
//  setLibcallCallingConv(RTLIB::MEMSET, CallingConv::CPU74_RTLIB);
//  setLibcallCallingConv(RTLIB::MEMCPY, CallingConv::CPU74_RTLIB);
//
//  setLibcallCallingConv(RTLIB::MUL_I32, CallingConv::CPU74_RTLIB);
//  setLibcallCallingConv(RTLIB::MUL_I64, CallingConv::CPU74_RTLIB);
//
//  // Several of the runtime library functions use a special calling conv
//  setLibcallCallingConv(RTLIB::UDIV_I64, CallingConv::CPU74_RTLIB);
//  setLibcallCallingConv(RTLIB::UREM_I64, CallingConv::CPU74_RTLIB);
//  setLibcallCallingConv(RTLIB::SDIV_I64, CallingConv::CPU74_RTLIB);
//  setLibcallCallingConv(RTLIB::SREM_I64, CallingConv::CPU74_RTLIB);
//  setLibcallCallingConv(RTLIB::ADD_F64, CallingConv::CPU74_RTLIB);
//  setLibcallCallingConv(RTLIB::SUB_F64, CallingConv::CPU74_RTLIB);
//  setLibcallCallingConv(RTLIB::MUL_F64, CallingConv::CPU74_RTLIB);
//  setLibcallCallingConv(RTLIB::DIV_F64, CallingConv::CPU74_RTLIB);
//  setLibcallCallingConv(RTLIB::OEQ_F64, CallingConv::CPU74_RTLIB);
//  setLibcallCallingConv(RTLIB::UNE_F64, CallingConv::CPU74_RTLIB);
//  setLibcallCallingConv(RTLIB::OGE_F64, CallingConv::CPU74_RTLIB);
//  setLibcallCallingConv(RTLIB::OLT_F64, CallingConv::CPU74_RTLIB);
//  setLibcallCallingConv(RTLIB::OLE_F64, CallingConv::CPU74_RTLIB);
//  setLibcallCallingConv(RTLIB::OGT_F64, CallingConv::CPU74_RTLIB);
  // TODO: __mspabi_srall, __mspabi_srlll, __mspabi_sllll


  // We have target-specific dag combine patterns for the following nodes:
//  setTargetDAGCombine(ISD::LOAD);
//  setTargetDAGCombine(ISD::STORE);
  setTargetDAGCombine(ISD::SELECT_CC);
  
  //Memset memcpy memcmp behaviour
  MaxStoresPerMemset = 4;
  MaxStoresPerMemsetOptSize = 4;
  MaxStoresPerMemcpy = 4; // For @llvm.memcpy -> sequence of stores
  MaxStoresPerMemcpyOptSize = 4;
  MaxStoresPerMemmove = 4; // For @llvm.memmove -> sequence of stores
  MaxStoresPerMemmoveOptSize = 4;
  MaxLoadsPerMemcmp = 4;
  MaxLoadsPerMemcmpOptSize = 4;

  // On CPU74 arguments smaller than 2 bytes are extended, so all arguments
  // are at least 2 bytes aligned.
  setMinStackArgumentAlignment(2);
  setMinFunctionAlignment(2);
  setPrefFunctionAlignment(2);
}


bool CPU74TargetLowering::allowsMisalignedMemoryAccesses(EVT VT, unsigned AddrSpace,
                                        unsigned Align,
                                        MachineMemOperand::Flags Flags,
                                        bool *Fast) const
{
  // Depends what it gets converted into if the type is weird.
  if (!VT.isSimple())
    return false;

//  MVT type = VT.getSimpleVT().SimpleTy;
//  if ( type == MVT::i8 )
//  {
//    return true;
//  }
  return false;
}


EVT CPU74TargetLowering::getOptimalMemOpType(uint64_t Size, unsigned DstAlign, unsigned SrcAlign,
                          bool IsMemset, bool ZeroMemset, bool MemcpyStrSrc,
                          const AttributeList &FuncAttributes) const
{
//    if ( DstAlign == 0 && !IsMemset )
//    {
//        // Return the EVT of the source
//        DstAlign = SrcAlign;
//        EVT VT = MVT::i64;
//        while (DstAlign && DstAlign < VT.getSizeInBits() / 8)
//          VT = (MVT::SimpleValueType)(VT.getSimpleVT().SimpleTy - 1);
//
//      return VT;
//    }
//    return MVT::Other;

    if ( SrcAlign < 2 && DstAlign == 0 && !IsMemset )
          return MVT::i8;
    return MVT::Other;
}



bool CPU74TargetLowering::isLegalAddImmediate(int64_t Immed) const
{
  // account for both add and subs
  bool valid = CPU74Imm::isImm8u(Immed) || CPU74Imm::isImm8u(-Immed);
  return valid;
}

bool CPU74TargetLowering::isLegalICmpImmediate(int64_t Immed) const
{
  bool valid = CPU74Imm::isImm8s(Immed);
  return valid;
}


//bool CPU74TargetLowering::isLegalAddressingMode(const DataLayout &DL,
//                                              const AddrMode &AM, Type *Ty,
//                                              unsigned AS, Instruction *I) const
//{
////  if ( !CPU74Imm::isImm6_d( AM.BaseOffs ) || !CPU74Imm::isImm8u( AM.BaseOffs ))
////    return false;
//
//  return TargetLoweringBase::isLegalAddressingMode(DL, AM, Ty, AS, I);
//}



bool CPU74TargetLowering::isLegalAddressingMode(const DataLayout &DL,
                                              const AddrMode &AM, Type *Ty,
                                              unsigned AS, Instruction *I) const
{

  // Allows immediate fields
  if ( !CPU74Imm::isImm6_d( AM.BaseOffs ) || !CPU74Imm::isImm8u( AM.BaseOffs ))
    return false;

  // Global vars as allowed provided no immediates or registers.
  if (AM.BaseGV)
    return ( !AM.HasBaseReg && !AM.BaseOffs && !AM.Scale);

  // Only support r+r,
  switch (AM.Scale)
  {
    case 0:  // "r+i" or just "i", depending on HasBaseReg.
      break;
    case 1:
      if (AM.HasBaseReg && AM.BaseOffs)  // "r+r+i" is not allowed.
        return false;
        // Otherwise we have r+r or r+i.
      break;
    case 2:
      if (AM.HasBaseReg || AM.BaseOffs)  // 2*r+r  or  2*r+i is not allowed.
        return false;
      // Allow 2*r as r+r.
      break;
    default: // Don't allow n * r
      return false;
  }

  return true;
}


//===----------------------------------------------------------------------===//
//                       CPU74 Inline Assembly Support
//===----------------------------------------------------------------------===//

/// getConstraintType - Given a constraint letter, return the type of
/// constraint it is for this target.
TargetLowering::ConstraintType
CPU74TargetLowering::getConstraintType(StringRef Constraint) const {
  if (Constraint.size() == 1) {
    switch (Constraint[0]) {
    case 'r':
      return C_RegisterClass;
    default:
      break;
    }
  }
  return TargetLowering::getConstraintType(Constraint);
}

std::pair<unsigned, const TargetRegisterClass *>
CPU74TargetLowering::getRegForInlineAsmConstraint(
    const TargetRegisterInfo *TRI, StringRef Constraint, MVT VT) const {
  if (Constraint.size() == 1) {
    // GCC Constraint Letters
    switch (Constraint[0]) {
    default: break;
    case 'r':   // GENERAL_REGS
//JLZ      if (VT == MVT::i8)
//JLZ        return std::make_pair(0U, &CPU74::GR8RegClass);

      return std::make_pair(0U, &CPU74::GR16RegClass);
    }
  }

  return TargetLowering::getRegForInlineAsmConstraint(TRI, Constraint, VT);
}


//===----------------------------------------------------------------------===//
//                      32 bit
//===----------------------------------------------------------------------===//


//void CPU74TargetLowering::ReplaceNodeResults(SDNode *N,
//                                              SmallVectorImpl<SDValue> &Results,
//                                              SelectionDAG &DAG) const
//{
//  EVT VT = N->getValueType(0);
//  if ( VT != MVT::i32 )
//    return;
//
//  unsigned Opc = N->getOpcode();
//
//  switch (Opc)
//  {
//    case ISD::ADD:
//      SDValue Op = SDValue(N, 0);
//      SDValue RES = LowerADD(Op, DAG);
//      Results.push_back(RES);
//      break;
//  }
//  return;
//}

//SDValue CPU74TargetLowering::LowerADDSUBCARRY(SDValue Op, SelectionDAG &DAG) const
//{
//  const SDLoc &dl(Op);
//  unsigned Opc = Op.getOpcode();
//}

SDValue CPU74TargetLowering::LowerUALUO(SDValue Op, SelectionDAG &DAG) const
{
  MVT VT = Op.getSimpleValueType();
  SDLoc dl(Op);
  
  unsigned Opc = 0;
  switch ( Op.getOpcode() )
  {
    default : llvm_unreachable("Invalid UADDSUBO Opcode");
    case ISD::UADDO : Opc = CPU74ISD::ADDO ; break;
    case ISD::USUBO : Opc = CPU74ISD::SUBO ; break;
  }
  
  SDVTList VTs = DAG.getVTList(VT, MVT::i16);
  SDValue Result = DAG.getNode(Opc, dl, VTs, Op.getOperand(0), Op.getOperand(1) );
  SDValue Carry = Result.getValue(1); 

  return DAG.getNode(ISD::MERGE_VALUES, dl, Op.getNode()->getVTList(), Result, Carry);
}

SDValue CPU74TargetLowering::LowerADDSUBCARRY(SDValue Op, SelectionDAG &DAG) const
{
  MVT VT = Op.getSimpleValueType();
  SDLoc dl(Op);

  unsigned Opc = 0;
  switch ( Op.getOpcode() )
  {
    default : llvm_unreachable("Invalid ADDSUBCARRY Opcode");
    case ISD::ADDCARRY : Opc = CPU74ISD::ADDC ; break;
    case ISD::SUBCARRY : Opc = CPU74ISD::SUBC ; break;
  }

  SDValue Carry = Op.getOperand(2);
  
  SDVTList VTs = DAG.getVTList(VT, MVT::i16);
  SDValue Result = DAG.getNode(Opc, dl, VTs, Op.getOperand(0), Op.getOperand(1), Carry);
  Carry = Result.getValue(1);

  return DAG.getNode(ISD::MERGE_VALUES, dl, Op.getNode()->getVTList(), Result, Carry);
}

//===----------------------------------------------------------------------===//
//                      Calling Convention Implementation
//===----------------------------------------------------------------------===//

#include "CPU74GenCallingConv.inc"


//transform physical registers into virtual registers and
/// generate load operations for arguments places on the stack.
// FIXME: struct return stuff

SDValue CPU74TargetLowering::LowerFormalArguments(
    SDValue Chain, CallingConv::ID CallConv, bool isVarArg,
    const SmallVectorImpl<ISD::InputArg> &Ins, const SDLoc &dl,
    SelectionDAG &DAG, SmallVectorImpl<SDValue> &InVals) const
{

  bool (*fn)(unsigned,MVT,MVT,CCValAssign::LocInfo,ISD::ArgFlagsTy,CCState&);

  switch (CallConv)
  {
    default:
      report_fatal_error("Unsupported this calling convention");
    case CallingConv::CPU74_INTR:
      if (Ins.empty())
        return Chain;
      report_fatal_error("ISRs cannot have arguments");
    
    case CallingConv::CPU74_RTLIB:
      fn = CC_CPU74_Rtlib;
      break;
    
    case CallingConv::C:
    case CallingConv::Fast:
      fn = isVarArg ? CC_CPU74_VaArgStack : CC_CPU74_AssignStack;
      break; //
    //return LowerCCCArguments(Chain, CallConv, isVarArg, Ins, dl, DAG, InVals);
  }
  
  MachineFunction &MF = DAG.getMachineFunction();
  MachineFrameInfo &MFI = MF.getFrameInfo();
  MachineRegisterInfo &RegInfo = MF.getRegInfo();
  CPU74MachineFunctionInfo *FuncInfo = MF.getInfo<CPU74MachineFunctionInfo>();

  // Assign locations to all of the incoming arguments.
  SmallVector<CCValAssign, 16> ArgLocs;
  CCState CCInfo(CallConv, isVarArg, DAG.getMachineFunction(), ArgLocs, *DAG.getContext());
  //AnalyzeArguments(CCInfo, /*ArgLocs,*/ Ins);
  CCInfo.AnalyzeFormalArguments(Ins, fn);

  // Create fixed object for the start of the first vararg value
  if (isVarArg)
  {
    unsigned Offset = CCInfo.getNextStackOffset();
    int FI = MFI.CreateFixedObject(1, Offset, true);
    FuncInfo->setVarArgsFrameIndex(FI);  // this will be used by LowerVASTART
  }

  for (unsigned i = 0, e = ArgLocs.size(); i != e; ++i)
  {
    CCValAssign &VA = ArgLocs[i];
    if (VA.isRegLoc())
    {
      // Arguments passed in registers
      EVT RegVT = VA.getLocVT();
//      switch (RegVT.getSimpleVT().SimpleTy)
//      {
//        default:
//        {
//          #ifndef NDEBUG
//          errs() << "LowerFormalArguments Unhandled argument type: "
//               << RegVT.getEVTString() << "\n";
//          #endif
//          llvm_unreachable(nullptr);
//        }
//        case MVT::i16:
          unsigned VReg = RegInfo.createVirtualRegister(&CPU74::GR16RegClass);
          RegInfo.addLiveIn(VA.getLocReg(), VReg);
          SDValue ArgValue = DAG.getCopyFromReg(Chain, dl, VReg, RegVT);
          
//          // If this is an 8-bit value, it is really passed promoted to 16
//          // bits. Insert an assert[sz]ext to capture this, then truncate to the
//          // right size.
//          MVT ValVT = VA.getValVT();
//          if (VA.getLocInfo() == CCValAssign::SExt)
//            ArgValue = DAG.getNode(ISD::AssertSext, dl, RegVT, ArgValue, DAG.getValueType(ValVT));
//          else if (VA.getLocInfo() == CCValAssign::ZExt)
//            ArgValue = DAG.getNode(ISD::AssertZext, dl, RegVT, ArgValue, DAG.getValueType(ValVT));
//
//          if (VA.getLocInfo() != CCValAssign::Full)
//            ArgValue = DAG.getNode(ISD::TRUNCATE, dl, ValVT, ArgValue);

          InVals.push_back(ArgValue);
//      }
    }
    else
    {
      // Sanity check
      assert(VA.isMemLoc());

      SDValue InVal;
      ISD::ArgFlagsTy Flags = Ins[i].Flags;

      if (Flags.isByVal())
      {
        int FI = MFI.CreateFixedObject(Flags.getByValSize(), VA.getLocMemOffset(), true);
        InVal = DAG.getFrameIndex(FI, getPointerTy(DAG.getDataLayout()));
      }
      else
      {
        // Load the argument to a virtual register
        unsigned ObjSize = VA.getLocVT().getSizeInBits()/8;
        if (ObjSize > 2)
        {
            errs() << "LowerFormalArguments Unhandled argument type: "
                << EVT(VA.getLocVT()).getEVTString()
                << "\n";
        }
        // Create the frame index object for this incoming parameter...
        int FI = MFI.CreateFixedObject(ObjSize, VA.getLocMemOffset(), true);

        // Create the SelectionDAG nodes corresponding to a load
        //from this parameter
        SDValue FIN = DAG.getFrameIndex(FI, MVT::i16);                      // jlc aqui
        InVal = DAG.getLoad(
            VA.getLocVT(), dl, Chain, FIN,
            MachinePointerInfo::getFixedStack(DAG.getMachineFunction(), FI));
      }

      InVals.push_back(InVal);
    }
  }

  for (unsigned i = 0, e = ArgLocs.size(); i != e; ++i)
  {
    if (Ins[i].Flags.isSRet())
    {
      unsigned Reg = FuncInfo->getSRetReturnReg();
      if (!Reg)
      {
        Reg = MF.getRegInfo().createVirtualRegister( getRegClassFor(MVT::i16));
        FuncInfo->setSRetReturnReg(Reg); // Used above and in LowerRETURN
      }
      SDValue Copy = DAG.getCopyToReg(DAG.getEntryNode(), dl, Reg, InVals[i]);
      Chain = DAG.getNode(ISD::TokenFactor, dl, MVT::Other, Copy, Chain);
    }
  }

  return Chain;
  
}



/// LowerCallResult - Lower the result values of a call into the
/// appropriate copies out of appropriate physical registers.

static SDValue LowerCallResult(
    SDValue Chain, SDValue InFlag, CallingConv::ID CallConv, bool isVarArg,
    const SmallVectorImpl<ISD::InputArg> &Ins, const SDLoc &dl,
    SelectionDAG &DAG, SmallVectorImpl<SDValue> &InVals)
{

  // Assign locations to each value returned by this call.
  SmallVector<CCValAssign, 16> RVLocs;
  CCState CCInfo(CallConv, isVarArg, DAG.getMachineFunction(), RVLocs,
                 *DAG.getContext());

  //AnalyzeReturnValues(CCInfo, RVLocs, Ins); gf
  CCInfo.AnalyzeCallResult( Ins, CC_CPU74_Return);

  // Copy all of the result registers out of their specified physreg.
  for (unsigned i = 0; i != RVLocs.size(); ++i) {
    Chain = DAG.getCopyFromReg(Chain, dl, RVLocs[i].getLocReg(),
                               RVLocs[i].getValVT(), InFlag).getValue(1);
    InFlag = Chain.getValue(2);
    InVals.push_back(Chain.getValue(0));
  }

  return Chain;
}


unsigned CPU74TargetLowering::AnalyzeCommutableLibCallRecurse( SDValue Op ) const
{
    TargetLowering::LegalizeAction Action =
        getOperationAction(Op.getOpcode(), Op.getSimpleValueType());
  
    if ( Action == TargetLowering::LibCall)
      return 0;

    if ( Op.getOpcode() == ISD::CopyFromReg )
    {
        RegisterSDNode *Reg = dyn_cast<RegisterSDNode>(Op.getNode()->getOperand(1));
        return Reg->getReg();
    }
  
    unsigned Candidate = (unsigned)-1;
  
    unsigned nOps = Op.getNumOperands();
    for ( unsigned i=0 ; i<nOps ; i++)
    {
      unsigned C = AnalyzeCommutableLibCallRecurse( Op.getNode()->getOperand(i) );
      if ( C < Candidate )
        Candidate = C;
    }

    return Candidate;
}


void CPU74TargetLowering::AnalyzeCommutableLibCall(
            SmallVectorImpl<ISD::OutputArg> *Outs, SmallVectorImpl<SDValue> *OutVals ) const
{

  unsigned Size = Outs->size();
  unsigned Gap = Size/2;
  if ( Size != Gap*2 )
    return;
  
  unsigned RegNum0 = AnalyzeCommutableLibCallRecurse( (*OutVals)[0] );
  unsigned RegNum1 = AnalyzeCommutableLibCallRecurse( (*OutVals)[Gap] );
  
  if ( RegNum0 > RegNum1  )
  {
    for ( unsigned i = 0 ; i<Gap ; ++i )
    {
      SDValue tmp = (*OutVals)[i];
      (*OutVals)[i] = (*OutVals)[i+Gap];
      (*OutVals)[i+Gap] = tmp;
              
      ISD::OutputArg tmp1 = (*Outs)[i];
      (*Outs)[i] = (*Outs)[i+Gap];
      (*Outs)[i+Gap] = tmp1;
    }
  }
}


SDValue CPU74TargetLowering::LowerCall(TargetLowering::CallLoweringInfo &CLI,
                                SmallVectorImpl<SDValue> &InVals) const
{
  SelectionDAG &DAG                     = CLI.DAG;
  SDLoc &dl                             = CLI.DL;
  SmallVectorImpl<ISD::OutputArg> &Outs = CLI.Outs;
  SmallVectorImpl<SDValue> &OutVals     = CLI.OutVals;
  SmallVectorImpl<ISD::InputArg> &Ins   = CLI.Ins;
  SDValue Chain                         = CLI.Chain;
  SDValue Callee                        = CLI.Callee;
  bool &isTailCall                      = CLI.IsTailCall;
  CallingConv::ID CallConv              = CLI.CallConv;
  bool isVarArg                         = CLI.IsVarArg;
  //unsigned numFixedArgs                 = CLI.NumFixedArgs;

  // CPU74 target does not yet support tail call optimization.
  isTailCall = false;
  
  EVT PtrVT = getPointerTy(DAG.getDataLayout());
  bool (*fn)(unsigned,MVT,MVT,CCValAssign::LocInfo,ISD::ArgFlagsTy,CCState&);

  switch (CallConv)
  {
    default:
      report_fatal_error("Unsupported this calling convention");
      break;
    
    case CallingConv::CPU74_INTR:
      report_fatal_error("ISRs cannot be called directly");
      break;
    
    case CallingConv::CPU74_RTLIB:
    {
      fn = CC_CPU74_Rtlib;
      break;
    }
    case CallingConv::Fast:
    case CallingConv::C:
      fn = isVarArg ? CC_CPU74_VaArgStack : CC_CPU74_AssignStack;
      break;
  }
  
  // Analyze Lib Calls
  if ( 1 && CallConv == CallingConv::CPU74_RTLIB )
  {
      ExternalSymbolSDNode *E = dyn_cast<ExternalSymbolSDNode>(CLI.Callee);
      if ( E && (
            !std::strcmp( E->getSymbol(), getLibcallName(RTLIB::MUL_I16) ) ||
            !std::strcmp( E->getSymbol(), getLibcallName(RTLIB::MUL_I32) ) ) )   // <- TODO Estudiar aquest cas
      {
        AnalyzeCommutableLibCall(&Outs, &OutVals);
      }
  }
 
  // Analyze operands of the call, assigning locations to each operand.
  SmallVector<CCValAssign, 16> ArgLocs;
  CCState CCInfo(CallConv, isVarArg, DAG.getMachineFunction(), ArgLocs, *DAG.getContext());
  CCInfo.AnalyzeCallOperands(Outs, fn);

  // Get a count of how many bytes are to be pushed on the stack
  // and create a CALLSEQ_START node with it
  unsigned NumBytes = CCInfo.getNextStackOffset();
  Chain = DAG.getCALLSEQ_START(Chain, NumBytes, 0, dl);

  // Walk the register/memloc assignments, inserting copies/loads.
  SDValue StackPtr;
  SmallVector<std::pair<unsigned, SDValue>, 4> RegsToPass;
  SmallVector<SDValue, 12> MemOpChains;
  for (unsigned i = 0, e = ArgLocs.size(); i != e; ++i)
  {
    CCValAssign &VA = ArgLocs[i];
    //MVT LocVT = VA.getLocVT();
    SDValue Arg = OutVals[i];

    // Promote the value if needed.
//    switch (VA.getLocInfo())
//    {
//      default: llvm_unreachable("Unknown loc info!");
//      case CCValAssign::Full: break;
//      case CCValAssign::SExt:
//        Arg = DAG.getNode(ISD::SIGN_EXTEND, dl, LocVT, Arg);
//        break;
//      case CCValAssign::ZExt:
//        Arg = DAG.getNode(ISD::ZERO_EXTEND, dl, LocVT, Arg);
//        break;
//      case CCValAssign::AExt:
//        Arg = DAG.getNode(ISD::ANY_EXTEND, dl, LocVT, Arg);
//        break;
//    }

    // Arguments that can be passed on register
    // must be kept at RegsToPass vector
    if (VA.isRegLoc())
    {
      RegsToPass.push_back(std::make_pair(VA.getLocReg(), Arg));
    }
    
    // For arguments passed on the stack we use
    // a special CPU74ISD::CallArgLoc that will be replaced later
    else
    {
      assert(VA.isMemLoc());
      
      if (!StackPtr.getNode())
        StackPtr = DAG.getCopyFromReg(Chain, dl, CPU74::SP, PtrVT);    // aqui aqui

      SDValue PtrOff = DAG.getNode(ISD::ADD, dl, PtrVT, StackPtr,
              DAG.getIntPtrConstant(VA.getLocMemOffset(), dl));
      
      
//      SDValue ArgLoc = DAG.getNode( CPU74ISD::CallArgLoc, dl, PtrVT );
//
//      SDValue PtrOff = DAG.getNode(ISD::ADD, dl, PtrVT, ArgLoc,
//              DAG.getIntPtrConstant(VA.getLocMemOffset(), dl));
      
      ISD::ArgFlagsTy Flags = Outs[i].Flags;
      
      // For byVal arguments create a memcpy (this may be optimised later)
      if (Flags.isByVal())
      {
        uint64_t size = Flags.getByValSize();
        unsigned align = Flags.getByValAlign();
        SDValue SizeNode = DAG.getConstant(size, dl, MVT::i16);
        
        SDValue MemOp = DAG.getMemcpy(Chain, dl,
                              /*dest,source,sizeNode*/PtrOff, Arg, SizeNode,
                              /*align*/align,
                              /*isVolatile*/false,
                              /*AlwaysInline=*/false,     // JLZ el original tenia true
                              /*isTailCall=*/false,
                              MachinePointerInfo(),
                              MachinePointerInfo());
        MemOpChains.push_back(MemOp);
      }
      
      // Otherwise this requires just a store
      else
      {
        SDValue MemOp = DAG.getStore(Chain, dl, Arg, PtrOff, MachinePointerInfo());
        MemOpChains.push_back(MemOp);
      }
    }
  } // End for

  // Transform all store nodes into one single node because all store nodes are
  // independent of each other.
  if (!MemOpChains.empty())
    Chain = DAG.getNode(ISD::TokenFactor, dl, MVT::Other, MemOpChains);

  // Build a sequence of copy-to-reg nodes chained together with token chain and
  // flag operands which copy the outgoing args into registers.  The InFlag in
  // necessary since all emitted instructions must be stuck together.
  SDValue InFlag;
  for (unsigned i = 0, e = RegsToPass.size(); i != e; ++i)
  {
    unsigned theReg = RegsToPass[i].first;
    SDValue theValue = RegsToPass[i].second;
  
  
    Chain = DAG.getCopyToReg(Chain, dl, RegsToPass[i].first, RegsToPass[i].second, InFlag);
    InFlag = Chain.getValue(1);
  }

  // If the callee is a GlobalAddress node (quite common, every direct call is)
  // turn it into a TargetGlobalAddress node so that legalize doesn't hack it.
  // Likewise ExternalSymbol -> TargetExternalSymbol.
  if (GlobalAddressSDNode *G = dyn_cast<GlobalAddressSDNode>(Callee))
    Callee = DAG.getTargetGlobalAddress(G->getGlobal(), dl, MVT::i16);
  
  else if (ExternalSymbolSDNode *E = dyn_cast<ExternalSymbolSDNode>(Callee))
    Callee = DAG.getTargetExternalSymbol(E->getSymbol(), MVT::i16);

  // Returns a chain & a flag for retval copy to use.
  SDVTList VTList = DAG.getVTList(MVT::Other, MVT::Glue);
  SmallVector<SDValue, 8> Ops;
  Ops.push_back(Chain);
  Ops.push_back(Callee);

  // Add argument registers to the end of the list so that they are
  // known live into the call.
  for (unsigned i = 0, e = RegsToPass.size(); i != e; ++i)
    Ops.push_back(DAG.getRegister(RegsToPass[i].first,
                                  RegsToPass[i].second.getValueType()));

  if (InFlag.getNode())
    Ops.push_back(InFlag);

  Chain = DAG.getNode(CPU74ISD::CALL, dl, VTList, Ops);
  InFlag = Chain.getValue(1);

  // Create the CALLSEQ_END node.
  Chain = DAG.getCALLSEQ_END(Chain, DAG.getConstant(NumBytes, dl, PtrVT, true),
                             DAG.getConstant(0, dl, PtrVT, true), InFlag, dl);
  InFlag = Chain.getValue(1);

  // Handle result values, copying them out of physregs into vregs that we
  // return.
  return LowerCallResult(Chain, InFlag, CallConv, isVarArg, Ins, dl,
                         DAG, InVals);
}


bool CPU74TargetLowering::CanLowerReturn(CallingConv::ID CallConv,
                                     MachineFunction &MF,
                                     bool IsVarArg,
                                     const SmallVectorImpl<ISD::OutputArg> &Outs,
                                     LLVMContext &Context) const {
  SmallVector<CCValAssign, 16> RVLocs;
  CCState CCInfo(CallConv, IsVarArg, MF, RVLocs, Context);
  return CCInfo.CheckReturn(Outs, CC_CPU74_Return);
}

SDValue CPU74TargetLowering::LowerReturn(SDValue Chain, CallingConv::ID CallConv,
                                  bool isVarArg,
                                  const SmallVectorImpl<ISD::OutputArg> &Outs,
                                  const SmallVectorImpl<SDValue> &OutVals,
                                  const SDLoc &dl, SelectionDAG &DAG) const {

  MachineFunction &MF = DAG.getMachineFunction();

  // CCValAssign - represent the assignment of the return value to a location
  SmallVector<CCValAssign, 16> RVLocs;

  // ISRs cannot return any value.
  if (CallConv == CallingConv::CPU74_INTR && !Outs.empty())
    report_fatal_error("ISRs cannot return any value");

  // CCState - Info about the registers and stack slot.
  CCState CCInfo(CallConv, isVarArg, DAG.getMachineFunction(), RVLocs,
                 *DAG.getContext());

  // Analize return values.
  //AnalyzeReturnValues(CCInfo, RVLocs, Outs);
  CCInfo.AnalyzeReturn( Outs, CC_CPU74_Return);

  SDValue Flag;
  SmallVector<SDValue, 4> RetOps(1, Chain);

  // Copy the result values into the output registers.
  for (unsigned i = 0; i != RVLocs.size(); ++i) {
    CCValAssign &VA = RVLocs[i];
    assert(VA.isRegLoc() && "Can only return in registers!");

    Chain = DAG.getCopyToReg(Chain, dl, VA.getLocReg(),
                             OutVals[i], Flag);

    // Guarantee that all emitted copies are stuck together,
    // avoiding something bad.
    Flag = Chain.getValue(1);
    RetOps.push_back(DAG.getRegister(VA.getLocReg(), VA.getLocVT()));
  }

  if (MF.getFunction().hasStructRetAttr()) {
    CPU74MachineFunctionInfo *FuncInfo = MF.getInfo<CPU74MachineFunctionInfo>();
    unsigned Reg = FuncInfo->getSRetReturnReg();

    if (!Reg)
      llvm_unreachable("sret virtual register not created in entry block");

    SDValue Val =
      DAG.getCopyFromReg(Chain, dl, Reg, getPointerTy(DAG.getDataLayout()));

//JLZ    unsigned R12 = CPU74::R12;
//JLZ    Chain = DAG.getCopyToReg(Chain, dl, R12, Val, Flag);
//JLZ    Flag = Chain.getValue(1);
//JLZ    RetOps.push_back(DAG.getRegister(R12, getPointerTy(DAG.getDataLayout())));
    unsigned R0 = CPU74::R0;
    Chain = DAG.getCopyToReg(Chain, dl, R0, Val, Flag);
    Flag = Chain.getValue(1);
    RetOps.push_back(DAG.getRegister(R0, getPointerTy(DAG.getDataLayout())));
  }

  unsigned Opc = (CallConv == CallingConv::CPU74_INTR ?
                  CPU74ISD::RETI_FLAG : CPU74ISD::RET_FLAG);

  RetOps[0] = Chain;  // Update chain.

  // Add the flag if we have it.
  if (Flag.getNode())
    RetOps.push_back(Flag);

  return DAG.getNode(Opc, dl, MVT::Other, RetOps);
}



// Expand a node into a call to a libcall.  If the result value
// does not fit into a register, return the lo part and set the hi part to the
// by-reg argument. If it does fit into a single register, return the result
// and leave the Hi part unset.

// He trobat una funcio similar a la clase SelectionDAGLegalize (fitxer LegalizeDAG.cpp)
// Es crida desde ExpandIntLibCall, que a la seva vegada es crida desde SelectionDAGLegalize::ConvertNodeToLibcall
// Que a la seva vegada es crida desde SelectionDAGLegalize::LegalizeOp
// Desgraciadament els RTLIB::SRA_I16 i els seus amics no estan suportats a ConvertNodeToLibcall. Suposo que es un bug
SDValue CPU74TargetLowering::ExpandLibCall(RTLIB::Libcall LC, SDNode *Node, SelectionDAG &DAG) const
{
  const char *name = getLibcallName(LC);
  CallingConv::ID callConv = getLibcallCallingConv(LC);
  return ExpandLibCall(name, callConv, Node, DAG);
}

SDValue CPU74TargetLowering::ExpandLibCall(const char *name, CallingConv::ID callConv, SDNode *Node, SelectionDAG &DAG) const
{
  TargetLowering::ArgListTy Args;
  TargetLowering::ArgListEntry Entry;
  for (const SDValue &Op : Node->op_values())
  {
    EVT ArgVT = Op.getValueType();
    Type *ArgTy = ArgVT.getTypeForEVT(*DAG.getContext());
    Entry.Node = Op;
    Entry.Ty = ArgTy;
    Entry.IsSExt = shouldSignExtendTypeInLibCall(ArgVT, false);
    Entry.IsZExt = !shouldSignExtendTypeInLibCall(ArgVT, false);
    Args.push_back(Entry);
  }
  SDValue Callee = DAG.getExternalSymbol(name, getPointerTy(DAG.getDataLayout()));

  EVT RetVT = Node->getValueType(0);
  Type *RetTy = RetVT.getTypeForEVT(*DAG.getContext());

  // By default, the input chain to this libcall is the entry node of the
  // function. If the libcall is going to be emitted as a tail call then
  // TLI.isUsedByReturnOnly will change it to the right chain if the return
  // node which is being folded has a non-entry input chain.
  SDValue InChain = DAG.getEntryNode();

  // isTailCall may be true since the callee does not reference caller stack
  // frame. Check if it's in the right position and that the return types match.
  SDValue TCChain = InChain;
  const Function &F = DAG.getMachineFunction().getFunction();
  bool isTailCall = isInTailCallPosition(DAG, Node, TCChain) &&
              (RetTy == F.getReturnType() || F.getReturnType()->isVoidTy());
  
  if (isTailCall)
    InChain = TCChain;

  TargetLowering::CallLoweringInfo CLI(DAG);
  bool signExtend = shouldSignExtendTypeInLibCall(RetVT, false);
  CLI.setDebugLoc(SDLoc(Node))
      .setChain(InChain)
      .setLibCallee(callConv, RetTy, Callee, std::move(Args))
      .setTailCall(isTailCall)
      .setSExtResult(signExtend)
      .setZExtResult(!signExtend)
      .setIsPostTypeLegalization(true);

  std::pair<SDValue, SDValue> CallInfo = LowerCallTo(CLI);

  if (!CallInfo.second.getNode()) {
    LLVM_DEBUG(dbgs() << "Created tailcall: "; DAG.getRoot().dump());
    // It's a tailcall, return the chain (which is the DAG root).
    return DAG.getRoot();
  }

  LLVM_DEBUG(dbgs() << "Created libcall: "; CallInfo.first.dump());
  return CallInfo.first;
}


SDValue CPU74TargetLowering::LowerGlobalAddress(SDValue Op, SelectionDAG &DAG) const
{
  const GlobalValue *GV = cast<GlobalAddressSDNode>(Op)->getGlobal();
  int64_t offset = cast<GlobalAddressSDNode>(Op)->getOffset();
  MVT PtrVT = getPointerTy(DAG.getDataLayout());
  Type *type = GV->getValueType();

  SDLoc dl(Op);

//  EVT evtvalue = Op.getValueType() ;
//  MVT mvtvalue = Op.getSimpleValueType();


  // For types than can be handled in registers
  // This could be restricted to type->isFloatingPointTy() || type->isIntegerTy()

//  if ( 0 && type->isSingleValueType() )  //
//  //if ( type->isSingleValueType() && Op.getNode()->hasOneUse() )  //
//  {
//    SDValue tgaN = DAG.getTargetGlobalAddress(GV, dl, PtrVT, offset);
//    SDValue wrapN = DAG.getNode(CPU74ISD::SingleValWrapper, dl, PtrVT, tgaN);
//    return wrapN;
//  }

  // Otherwise create an explicit addition for it.
  SDValue tgaN = DAG.getTargetGlobalAddress(GV, dl, PtrVT, 0);
  SDValue wrapN = DAG.getNode(CPU74ISD::AggregateWrapper, dl, PtrVT, tgaN);
  SDValue offsN = DAG.getConstant(offset, dl, MVT::i16);
  SDValue addN = DAG.getNode(ISD::ADD, dl, PtrVT, wrapN, offsN);  // ADD
  return addN;
}

SDValue CPU74TargetLowering::LowerJumpTable(SDValue Op, SelectionDAG &DAG) const
{
  SDLoc dl(Op);
  int index = cast<JumpTableSDNode>(Op)->getIndex();
  MVT PtrVT = getPointerTy(DAG.getDataLayout());
  SDValue tjtN = DAG.getTargetJumpTable(index, PtrVT);
  //return DAG.getNode(CPU74ISD::SingleValWrapper, dl, PtrVT, tjtN);
  return DAG.getNode(CPU74ISD::AggregateWrapper, dl, PtrVT, tjtN);
}

//SDValue CPU74TargetLowering::LowerGlobalAddress(SDValue Op,
//                                                 SelectionDAG &DAG) const {
//  const GlobalValue *GV = cast<GlobalAddressSDNode>(Op)->getGlobal();
//  int64_t Offset = cast<GlobalAddressSDNode>(Op)->getOffset();
//  auto PtrVT = getPointerTy(DAG.getDataLayout());
//
//  // Create the TargetGlobalAddress node, folding in the constant offset.
//  SDValue Result = DAG.getTargetGlobalAddress(GV, SDLoc(Op), PtrVT, Offset);
//  return DAG.getNode(CPU74ISD::Wrapper, SDLoc(Op), PtrVT, Result);
//}

SDValue CPU74TargetLowering::LowerExternalSymbol(SDValue Op,
                                                  SelectionDAG &DAG) const {
  SDLoc dl(Op);
  const char *Sym = cast<ExternalSymbolSDNode>(Op)->getSymbol();
  auto PtrVT = getPointerTy(DAG.getDataLayout());
  SDValue Result = DAG.getTargetExternalSymbol(Sym, PtrVT);

  //return DAG.getNode(CPU74ISD::SingleValWrapper, dl, PtrVT, Result);
  return DAG.getNode(CPU74ISD::AggregateWrapper, dl, PtrVT, Result);
}

SDValue CPU74TargetLowering::LowerBlockAddress(SDValue Op,
                                                SelectionDAG &DAG) const {
  SDLoc dl(Op);
  auto PtrVT = getPointerTy(DAG.getDataLayout());
  const BlockAddress *BA = cast<BlockAddressSDNode>(Op)->getBlockAddress();
  SDValue Result = DAG.getTargetBlockAddress(BA, PtrVT);

  //return DAG.getNode(CPU74ISD::SingleValWrapper, dl, PtrVT, Result);
  return DAG.getNode(CPU74ISD::AggregateWrapper, dl, PtrVT, Result);
}



static bool isSupportedCondition( CPU74CC::CondCodes CondCode )
{
    switch (CondCode)
    {
      default: llvm_unreachable("Unknown condition code");
      case CPU74CC::COND_EQ:
      case CPU74CC::COND_NE:
      case CPU74CC::COND_UGE:
      case CPU74CC::COND_ULT:
      case CPU74CC::COND_GE:
      case CPU74CC::COND_LT:
      
      case CPU74CC::COND_UGT:
      case CPU74CC::COND_GT:
        return true;

    // unsupported
    case CPU74CC::COND_ULE:
    case CPU74CC::COND_LE:
        return false;
  }
}



static bool isPreferredCondition( CPU74CC::CondCodes CondCode )
{
    switch (CondCode)
    {
      default: llvm_unreachable("Unknown condition code");
      case CPU74CC::COND_EQ:
      case CPU74CC::COND_NE:
      case CPU74CC::COND_UGE:
      case CPU74CC::COND_ULT:
      case CPU74CC::COND_GE:
      case CPU74CC::COND_LT:
        return true;
        
    // not preferred
    case CPU74CC::COND_UGT:
    case CPU74CC::COND_GT:
    case CPU74CC::COND_ULE:
    case CPU74CC::COND_LE:
        return false;
  }
}

// Returns CondCode if it's supported or an opposite condition in case it is not
static CPU74CC::CondCodes getSupportedCondition( CPU74CC::CondCodes CondCode )
{
  if ( isSupportedCondition(CondCode) )
      return CondCode;
  
  return CPU74CC::getOppositeCondition(CondCode);
  
//  switch (CondCode)
//  {
//    default: llvm_unreachable("Unknown condition code");
//    case CPU74CC::COND_ULE: return CPU74CC::COND_UGT;
//    case CPU74CC::COND_LE: return CPU74CC::COND_GT;
//  }
}

/// IntCCToARMCC - Convert a DAG integer condition code to an ARM CC
static CPU74CC::CondCodes ISDCCToCPU74CC(ISD::CondCode CC)
{
  switch (CC)
  {
    default: llvm_unreachable("Unknown condition code!");
    case ISD::SETNE:  return CPU74CC::COND_NE;
    case ISD::SETEQ:  return CPU74CC::COND_EQ;
    case ISD::SETGT:  return CPU74CC::COND_GT;
    case ISD::SETGE:  return CPU74CC::COND_GE;
    case ISD::SETLT:  return CPU74CC::COND_LT;
    case ISD::SETLE:  return CPU74CC::COND_LE;
    case ISD::SETUGT: return CPU74CC::COND_UGT;
    case ISD::SETUGE: return CPU74CC::COND_UGE;
    case ISD::SETULT: return CPU74CC::COND_ULT;
    case ISD::SETULE: return CPU74CC::COND_ULE;
  }
}


//
//static SDValue EmitCMP(SDValue &LHS, SDValue &RHS, SDValue &TargetCC,
//                       ISD::CondCode CC, const SDLoc &dl, SelectionDAG &DAG) {
//  // FIXME: Handle bittests someday
//  assert(!LHS.getValueType().isFloatingPoint() && "We don't handle FP yet");
//
//  // FIXME: Handle jump negative someday
//  CPU74CC::CondCodes TCC = CPU74CC::COND_INVALID;
//  switch (CC) {
//  default: llvm_unreachable("Invalid integer condition!");
//  case ISD::SETEQ:
//    TCC = CPU74CC::COND_E;     // aka COND_Z
//    // Minor optimization: if LHS is a constant, swap operands, then the
//    // constant can be folded into comparison.
//    if (LHS.getOpcode() == ISD::Constant)
//      std::swap(LHS, RHS);
//    break;
//  case ISD::SETNE:
//    TCC = CPU74CC::COND_NE;    // aka COND_NZ
//    // Minor optimization: if LHS is a constant, swap operands, then the
//    // constant can be folded into comparison.
//    if (LHS.getOpcode() == ISD::Constant)
//      std::swap(LHS, RHS);
//    break;
//  case ISD::SETULE:
//    std::swap(LHS, RHS);
//    LLVM_FALLTHROUGH;
//  case ISD::SETUGE:
//    // Turn lhs u>= rhs with lhs constant into rhs u< lhs+1, this allows us to
//    // fold constant into instruction.
//    if (const ConstantSDNode * C = dyn_cast<ConstantSDNode>(LHS)) {
//      LHS = RHS;
//      RHS = DAG.getConstant(C->getSExtValue() + 1, dl, C->getValueType(0));
//      TCC = CPU74CC::COND_LO;
//      break;
//    }
//    TCC = CPU74CC::COND_HS;    // aka COND_C
//    break;
//  case ISD::SETUGT:
//    std::swap(LHS, RHS);
//    LLVM_FALLTHROUGH;
//  case ISD::SETULT:
//    // Turn lhs u< rhs with lhs constant into rhs u>= lhs+1, this allows us to
//    // fold constant into instruction.
//    if (const ConstantSDNode * C = dyn_cast<ConstantSDNode>(LHS)) {
//      LHS = RHS;
//      RHS = DAG.getConstant(C->getSExtValue() + 1, dl, C->getValueType(0));
//      TCC = CPU74CC::COND_HS;
//      break;
//    }
//    TCC = CPU74CC::COND_LO;    // aka COND_NC
//    break;
//  case ISD::SETLE:
//    std::swap(LHS, RHS);
//    LLVM_FALLTHROUGH;
//  case ISD::SETGE:
//    // Turn lhs >= rhs with lhs constant into rhs < lhs+1, this allows us to
//    // fold constant into instruction.
//    if (const ConstantSDNode * C = dyn_cast<ConstantSDNode>(LHS)) {
//      LHS = RHS;
//      RHS = DAG.getConstant(C->getSExtValue() + 1, dl, C->getValueType(0));
//      TCC = CPU74CC::COND_L;
//      break;
//    }
//    TCC = CPU74CC::COND_GE;
//    break;
//  case ISD::SETGT:
//    std::swap(LHS, RHS);
//    LLVM_FALLTHROUGH;
//  case ISD::SETLT:
//    // Turn lhs < rhs with lhs constant into rhs >= lhs+1, this allows us to
//    // fold constant into instruction.
//    if (const ConstantSDNode * C = dyn_cast<ConstantSDNode>(LHS)) {
//      LHS = RHS;
//      RHS = DAG.getConstant(C->getSExtValue() + 1, dl, C->getValueType(0));
//      TCC = CPU74CC::COND_GE;
//      break;
//    }
//    TCC = CPU74CC::COND_L;
//    break;
//  }
//
//  TargetCC = DAG.getConstant(TCC, dl, MVT::i8);
//  return DAG.getNode(CPU74ISD::CMP, dl, MVT::Glue, LHS, RHS);
//}
//
//


// Tweak operands and branch conditions to get a preferred
// branch chain that can be optimized later in CPU74InstrInfo::analyzeBranch
static void optimizeBranchOperands( SDValue &LHS, SDValue &RHS,
                                    ISD::CondCode &CC, SDValue &Dest,
                                    const SDLoc &dl, SelectionDAG &DAG,
                                    const SDValue Op)
{
  // Conditon is already a preferred one, return early with nothing to do
  if ( isPreferredCondition( ISDCCToCPU74CC(CC) )) {
    return ;
  }

  // Can't do anything with constants
  if ( dyn_cast<ConstantSDNode>(RHS.getNode())
       || dyn_cast<ConstantSDNode>(LHS.getNode()) ) {
    return ;
  }
  
  // We do not support more than one use
  if ( !Op.getNode()->hasOneUse()) {
    return ;
  }
  
  // If the following instruction is an unconditional branch,
  // exchange destinations with the following BR instruction
  SDNode *Use = *Op.getNode()->use_begin();
  if ( Use->getOpcode() == ISD::BR )
  {
    // Replace
    //    brcc Dest
    //    jmp Dest1
    // by
    //    brc1 Dest1
    //    jmp Dest
    // where c1 is a preferred condition

    SDValue Dest1 = Use->getOperand(1);

    SDValue JMP = DAG.getNode(ISD::BR, dl, MVT::Other, Op, Dest);
    DAG.ReplaceAllUsesWith(Use, JMP.getNode());

    std::swap(RHS, LHS);

    CC = ISD::getSetCCSwappedOperands(CC);
    CC = ISD::getSetCCInverse(CC, true);

    Dest = Dest1;
  }
}


// Get constant CC node.
// Makes changes to LHS or RHS to account for unsupported CCs
static SDValue getCCNode( SDValue &LHS, SDValue &RHS, const SDLoc &dl, SelectionDAG &DAG,
                                      ISD::CondCode CC, bool usePreferred=false )
{
  // Before anything, set any constant in the left hand node
  // to the right node. I guess this never happens
  if ( dyn_cast<ConstantSDNode>(LHS.getNode()) )
  {
    CC = ISD::getSetCCSwappedOperands(CC);
    std::swap(LHS, RHS);
  }
  
  // Get the target Condition Code
  CPU74CC::CondCodes CondCode = ISDCCToCPU74CC(CC);
  
  // For constant compares, replace non-preferred conditions
  // by supported, preferred ones
  if ( ConstantSDNode *RHSC = dyn_cast<ConstantSDNode>(RHS.getNode()) )
  {
      int64_t C = RHSC->getSExtValue();
      uint64_t UC = RHSC->getZExtValue();
    
      if ( (usePreferred && !isPreferredCondition( CondCode )) ||
           !isSupportedCondition(CondCode) )
      {
          switch ( CondCode )
          {
            default: llvm_unreachable("should be an unsupported CondCode");

            case CPU74CC::COND_UGT:   // supported, not preferred
                CondCode = CPU74CC::COND_UGE;
                RHS = DAG.getConstant(UC+1, dl, MVT::i16);
                break;
              
            case CPU74CC::COND_GT:    // supported, not preferred
                CondCode = CPU74CC::COND_GE;
                RHS = DAG.getConstant(C+1, dl, MVT::i16);
                break;

            case CPU74CC::COND_ULE:   // not supported
                CondCode = CPU74CC::COND_ULT;
                RHS = DAG.getConstant(UC+1, dl, MVT::i16);
                break;
              
            case CPU74CC::COND_LE:    // not supported
                CondCode = CPU74CC::COND_LT;
                RHS = DAG.getConstant(C+1, dl, MVT::i16);
                break;
          }
      }
  }
  
  // For non-constant compares we can only swap the operands and
  // the unsupported condition code
  else if ( !isSupportedCondition( CondCode ) )
  {
      CC = ISD::getSetCCSwappedOperands(CC);
      CondCode = ISDCCToCPU74CC(CC); // should be supported now
      assert( isSupportedCondition(CondCode) && "Should be a supported condition" );
      std::swap(LHS, RHS);
  }
  
  return DAG.getConstant(CondCode, dl, MVT::i16);
}

// Get a new CMP node or a replacement for an existing one
// that will produce comparision flags
static SDValue getCMPNode(SDValue &LHS, SDValue &RHS, const SDLoc &dl,
                          SelectionDAG &DAG, ISD::CondCode CC=ISD::CondCode::SETCC_INVALID)
{
  unsigned newOpcode = 0;
  
  // Check for equal or non equal comparisons with zero after an alu operation
  // in case they can be replaced by just the alu operation
  if ( ConstantSDNode *RHSC = dyn_cast<ConstantSDNode>(RHS.getNode()) )
    if ( 1 || LHS.hasOneUse() )
      if ( 1 && (CC == ISD::CondCode::SETEQ || CC == ISD::CondCode::SETNE)
           && RHSC->getZExtValue() == 0 )
    {
      unsigned OpCode = LHS.getOpcode();
      switch ( OpCode )
      {
        case ISD::ADD: newOpcode = CPU74ISD::ADD; break;
        case ISD::SUB: newOpcode = CPU74ISD::SUB; break;
        case ISD::AND: newOpcode = CPU74ISD::AND; break;
        case ISD::OR:  newOpcode = CPU74ISD::OR; break;
        case ISD::XOR: newOpcode = CPU74ISD::XOR; break;
        case CPU74ISD::ADD:
        case CPU74ISD::SUB:
        case CPU74ISD::AND:
        case CPU74ISD::OR:
        case CPU74ISD::XOR: newOpcode = OpCode; break;
      }
  }
  
  if ( newOpcode )
  {
    SDVTList VTs = DAG.getVTList(LHS.getValueType(), MVT::i16);
    SDValue Replacement = DAG.getNode(newOpcode, dl, VTs, LHS.getOperand(0), LHS.getOperand(1));
    DAG.ReplaceAllUsesOfValueWith( LHS, Replacement );
    return SDValue( Replacement.getNode(), 1);
  }
  return DAG.getNode(CPU74ISD::CMP, dl, MVT::i16, LHS, RHS);
}


SDValue CPU74TargetLowering::LowerSETCC(SDValue Op, SelectionDAG &DAG) const
{
  EVT VT = Op.getValueType();
  SDLoc dl(Op);

  SDValue LHS = Op.getOperand(0);
  SDValue RHS = Op.getOperand(1);
  ISD::CondCode CC = cast<CondCodeSDNode>(Op.getOperand(2))->get();

  SDValue TargetCC = getCCNode(LHS, RHS, dl, DAG, CC);
  SDValue CMPNode = getCMPNode(LHS, RHS, dl, DAG, CC);
  
//  MVT CMPNodeTy = CMPNode.getSimpleValueType();
//  unsigned opCode = (CMPNodeTy == MVT::Glue ? CPU74ISD::SET_CC_g : CPU74ISD::SET_CC_i);
  //unsigned opCode = CPU74ISD::SET_CC;
  
  return DAG.getNode(CPU74ISD::SET_CC, dl, VT, TargetCC, CMPNode);

//  SDVTList VTs = DAG.getVTList(VT, CMPNodeTy);
//  SDValue OPs[] = {TargetCC, CMPNode};
//
//  return DAG.getNode(opCode, dl, VTs, OPs);
  
//  return DAG.getNode(CPU74ISD::SET_CC, dl, VT, TargetCC, CMPNode);
}


// es bo, igual que el original !
//SDValue CPU74TargetLowering::LowerSELECT(SDValue Op,
//                                             SelectionDAG &DAG) const
//{
//  EVT VT = Op.getValueType();
//  SDValue Cond  = Op.getOperand(0);
//  SDValue TrueV = Op.getOperand(1);
//  SDValue FalseV = Op.getOperand(2);
//  SDLoc dl(Op);
//
//  SDValue Result;
//
//  unsigned condOpcode = Cond.getOpcode();
//
//  if ( condOpcode == ISD::SETCC )
//  {
//    SDValue LHS = Cond.getOperand(0);
//    SDValue RHS = Cond.getOperand(1);
//    SDValue SetCC = Cond.getOperand(2);
//
//    Result = DAG.getNode(ISD::SELECT_CC, dl, VT, LHS, RHS, TrueV, FalseV, SetCC);
//  }
//  else
//  {
//    SDValue Zero = DAG.getConstant(0, dl, Cond.getValueType());
//    SDValue CondNE = DAG.getCondCode(ISD::SETNE);
//    Result = DAG.getNode(ISD::SELECT_CC, dl, VT, Cond, Zero, TrueV, FalseV, CondNE);
//  }
//
//  return Result;
//}



SDValue CPU74TargetLowering::LowerSELECT_CC(SDValue Op,
                                             SelectionDAG &DAG) const
{
  EVT VT = Op.getValueType();
  SDLoc dl(Op);

  SDValue LHS    = Op.getOperand(0);
  SDValue RHS    = Op.getOperand(1);
  SDValue TrueV  = Op.getOperand(2);
  SDValue FalseV = Op.getOperand(3);
  ISD::CondCode CC = cast<CondCodeSDNode>(Op.getOperand(4))->get();

  if ( dyn_cast<ConstantSDNode>(LHS.getNode()) )
  {
    CC = ISD::getSetCCSwappedOperands(CC);
    std::swap(LHS, RHS);
  }

  CPU74CC::CondCodes RawCode = ISDCCToCPU74CC(CC);
  CPU74CC::CondCodes CondCode = getSupportedCondition( RawCode );

  // Instead of calling getCCNode route we just swap
  // the select instruction operands if the conditon was reversed
  if ( RawCode != CondCode )
      std::swap( TrueV, FalseV );

  SDValue TargetCC = DAG.getConstant(CondCode, dl, MVT::i16);
  SDValue CMPNode = getCMPNode(LHS, RHS, dl, DAG, CC);
  
//  MVT CMPNodeTy = CMPNode.getSimpleValueType();
//  unsigned opCode = (CMPNodeTy == MVT::Glue ? CPU74ISD::SEL_CC_g : CPU74ISD::SEL_CC_i);
//  unsigned opCode = CPU74ISD::SEL_CC;
  
  return DAG.getNode(CPU74ISD::SEL_CC, dl, VT, TrueV, FalseV, TargetCC, CMPNode );

//  SDVTList VTs = DAG.getVTList(VT, CMPNodeTy);
//  SDValue OPs[] = {TrueV, FalseV, TargetCC, CMPNode};
//
//  return DAG.getNode(opCode, dl, VTs, OPs  );
}



SDValue CPU74TargetLowering::LowerBR_CC(SDValue Op, SelectionDAG &DAG) const
{
  EVT VT = Op.getValueType();
  SDLoc dl(Op);

  SDValue Chain = Op.getOperand(0);
  ISD::CondCode CC = cast<CondCodeSDNode>(Op.getOperand(1))->get();
  SDValue LHS   = Op.getOperand(2);
  SDValue RHS   = Op.getOperand(3);
  SDValue Dest  = Op.getOperand(4);
  
  optimizeBranchOperands(LHS, RHS, CC, Dest, dl, DAG, Op );
  SDValue TargetCC = getCCNode(LHS, RHS, dl, DAG, CC, true);
  SDValue CMPNode = getCMPNode(LHS, RHS, dl, DAG, CC);

  return DAG.getNode(CPU74ISD::BR_CC, dl, VT, Chain, Dest, TargetCC, CMPNode);
}


//SDValue CPU74TargetLowering::LowerSHL_PARTS(SDValue Op, SelectionDAG &DAG) const
//{
//  EVT VT = Op.getValueType();
//  SDLoc dl(Op);
//
//  SDValue Lo = Op.getOperand(0);
//  SDValue Hi = Op.getOperand(1);
//  SDValue Amt = Op.getOperand(2);
//  EVT AmtVT = Amt.getValueType();
//
//  SDValue LoShift = DAG.getNode( CPU74ISD::LSLO, dl, VT, Lo);
//  SDValue Result = DAG.getNode( CPU74ISD::LSLC, dl, VT, Hi, LoShift.getValue(1));
//
//  return  Result;
//}


SDValue CPU74TargetLowering::LowerShifts(SDValue Op, SelectionDAG &DAG) const
{
  EVT VT = Op.getValueType();
  SDLoc dl(Op);

  SDValue LHS = Op.getOperand(0);
  SDValue RHS = Op.getOperand(1);

  unsigned Opc = Op.getOpcode();

  // Expand non-constant shifts into libcall:
  
  if (!isa<ConstantSDNode>(RHS))
  {
    RTLIB::Libcall libCall;
    switch (Opc)
    {
      case ISD::SHL: libCall = RTLIB::SHL_I16; break;
      case ISD::SRL: libCall = RTLIB::SRL_I16; break;
      case ISD::SRA: libCall = RTLIB::SRA_I16; break;
      default: llvm_unreachable("Invalid shift opcode!");
    }
      return ExpandLibCall( libCall, Op.getNode(), DAG );
//      SDValue Ops[2] = {LHS, RHS};
//      return makeLibCall(DAG, libCall, VT, Ops, false, dl).first;
  }
  
  // Expand constant shifts into sequence of shifts.
  
  uint64_t ShiftAmount = cast<ConstantSDNode>(RHS)->getZExtValue();
  SDValue Victim = LHS;
  
  unsigned tOpc = 0;
  switch (Opc)
  {
    case ISD::SHL: tOpc = CPU74ISD::LSL; break;
    case ISD::SRL: tOpc = CPU74ISD::LSR; break;
    case ISD::SRA: tOpc = CPU74ISD::ASR; break;
    default: llvm_unreachable("Invalid shift opcode!");
  }
  
  // the front-end will not allow constant shifs above 16, but just in case...
  if ( ShiftAmount >= 16 )
    switch (tOpc)
    {
      default: llvm_unreachable("Invalid shift opcode!");
      case CPU74ISD::LSL:
      case CPU74ISD::LSR:
          // return zero
          return DAG.getNode( ISD::AND, dl, VT, Victim, DAG.getConstant( 0x0000, dl, VT));
        
      case CPU74ISD::ASR:
          // handle in >=15 code
          break;
    }
  
  
  if ( ShiftAmount >= 15 )
    switch (tOpc)
    {
      default: llvm_unreachable("Invalid shift opcode!");
      case CPU74ISD::LSL:
        {
          // handle in >=8 code
          //break;
          
          // AND Victim, 1, Rx
          // SELEQ 8000L, 0, Result
  
          SDValue Zero = DAG.getConstant(0, dl, MVT::i16);
          SDValue One = DAG.getConstant(1, dl, MVT::i16);
          SDValue Shift = DAG.getConstant(0x8000, dl, MVT::i16);
          SDVTList VTs = DAG.getVTList(VT, MVT::i16);
          SDValue And = DAG.getNode(CPU74ISD::AND, dl, VTs, Victim, One);
          SDValue CMPNode = SDValue( And.getNode(), 1);
          SDValue TargetCC = DAG.getConstant(CPU74CC::COND_EQ, dl, MVT::i16);
          return DAG.getNode(CPU74ISD::SEL_CC, dl, VT, Zero, Shift, TargetCC, CMPNode );
        
        }
      case CPU74ISD::LSR:
        {
          // if we are here ShiftAmount is exactly 15, expand to
          //    CMP Victim, 0
          //    SETLT Result
          SDValue Zero = DAG.getConstant(0, dl, VT);
          SDValue TargetCC = DAG.getConstant(CPU74CC::COND_LT, dl, MVT::i16);
          SDValue CMPNode = getCMPNode(Victim, Zero, dl, DAG);

          //SDValue SetCC = DAG.getNode(CPU74ISD::SET_CC_g, dl, VT, TargetCC, CMPNode );
          return DAG.getNode(CPU74ISD::SET_CC, dl, VT, TargetCC, CMPNode );
        }
        
      case CPU74ISD::ASR:
          // expand to
          //    SEXTW Victim, Result
          return DAG.getNode(CPU74ISD::SEXTW, dl, VT, Victim);
    }
  
  // Create Swap/extend combinations for shift amounts above 7
  
  if ( ShiftAmount >= 8 )
  {
    ShiftAmount -= 8;
    SDValue ExNode;
    switch (tOpc)
    {
      default: llvm_unreachable("Invalid shift opcode!");
      case CPU74ISD::LSL:
          // zero-extend then swap
          ExNode = DAG.getNode( ISD::AND, dl, VT, Victim, DAG.getConstant( 0x00ff, dl, VT));
          Victim = DAG.getNode( ISD::BSWAP, dl, VT, ExNode);
          break;
   
      case CPU74ISD::LSR:
          // swap then zero-extend
          ExNode = DAG.getNode( ISD::BSWAP, dl, VT, Victim);
          Victim = DAG.getNode( ISD::AND, dl, VT, ExNode, DAG.getConstant( 0x00ff, dl, VT));
          break;
        
      case CPU74ISD::ASR:
          // swap then sign-extend
          ExNode = DAG.getNode( ISD::BSWAP, dl, VT, Victim);
          Victim = DAG.getNode( ISD::SIGN_EXTEND_INREG, dl, VT, ExNode, DAG.getValueType(MVT::i8));
          break;
    }
  }
  
  // Expand the remaining shift amount into a series of single bit shifts

  while (ShiftAmount--)
    Victim = DAG.getNode(tOpc, dl, VT, Victim);
  
  return Victim;
}

//SDValue CPU74TargetLowering::LowerUDIVREM(SDValue Op, SelectionDAG &DAG) const
//{
//  EVT VT = Op.getValueType();
//  SDLoc dl(Op);
//
//  SDValue LHS = Op.getOperand(0);
//  SDValue RHS = Op.getOperand(1);
//
//  unsigned Opc = Op.getOpcode();
//
//  RTLIB::Libcall libCall;
//  switch (Opc)
//  {
//    case ISD::UDIVREM: libCall = VT == MVT::i16 ? RTLIB::UDIVREM_I16 : RTLIB::UDIVREM_I32; break;
//    case ISD::SDIVREM: libCall = VT == MVT::i16 ? RTLIB::SDIVREM_I16 : RTLIB::UDIVREM_I32; break;
//    default: llvm_unreachable("Invalid divrem opcode!");
//  }
//  const char *rtlCLZname = "_clzhi2sddfkhg";
//  CallingConv::ID callConv = CallingConv::CPU74_RTLIB;
//  return ExpandLibCall(rtlCLZname, callConv, Op.getNode(), DAG);
//  //return ExpandLibCall( libCall, Op.getNode(), DAG );
//  //SDValue Ops[2] = {LHS, RHS};
//  //return makeLibCall(DAG, libCall, VT, Ops, false, dl).first;
//}


SDValue CPU74TargetLowering::LowerCLZ(SDValue Op, SelectionDAG &DAG) const
{
  SDLoc dl(Op);
  const char *rtlCLZname = "_clzhi2";
  CallingConv::ID callConv = CallingConv::CPU74_RTLIB;
  return ExpandLibCall(rtlCLZname, callConv, Op.getNode(), DAG);
  
//  SDNode *Node = Op.getNode();
//  EVT RetVT = Node->getValueType(0);
//  return makeLibCall(DAG, RTLIB::CTLZ_I32 , RetVT, Node->op_values(), false, dl).first;
//     ^- atencio no es pot fer servir perque CTLZ_I16 no existeix
}


//SDValue
//CPU74TargetLowering::getReturnAddressFrameIndex(SelectionDAG &DAG) const

static SDValue getReturnAddressFrameIndex(EVT PtrVT, SelectionDAG &DAG)
{
  MachineFunction &MF = DAG.getMachineFunction();
  CPU74MachineFunctionInfo *FuncInfo = MF.getInfo<CPU74MachineFunctionInfo>();
  int ReturnAddrIndex = FuncInfo->getRAIndex();
  //auto PtrVT = getPointerTy(MF.getDataLayout());

  if (ReturnAddrIndex == 0) {
    // Set up a frame object for the return address.
    uint64_t SlotSize = MF.getDataLayout().getPointerSize();
    ReturnAddrIndex = MF.getFrameInfo().CreateFixedObject(SlotSize, -SlotSize,
                                                           true);
    FuncInfo->setRAIndex(ReturnAddrIndex);
  }

  return DAG.getFrameIndex(ReturnAddrIndex, PtrVT);
}

SDValue CPU74TargetLowering::LowerRETURNADDR(SDValue Op,
                                              SelectionDAG &DAG) const {
  MachineFrameInfo &MFI = DAG.getMachineFunction().getFrameInfo();
  MFI.setReturnAddressIsTaken(true);

  if (verifyReturnAddressArgumentIsConstant(Op, DAG))
    return SDValue();

  unsigned Depth = cast<ConstantSDNode>(Op.getOperand(0))->getZExtValue();
  SDLoc dl(Op);
  auto PtrVT = getPointerTy(DAG.getDataLayout());

  if (Depth > 0) {
    SDValue FrameAddr = LowerFRAMEADDR(Op, DAG);
    SDValue Offset =
        DAG.getConstant(DAG.getDataLayout().getPointerSize(), dl, MVT::i16);
    return DAG.getLoad(PtrVT, dl, DAG.getEntryNode(),
                       DAG.getNode(ISD::ADD, dl, PtrVT, FrameAddr, Offset),
                       MachinePointerInfo());
  }

  // Just load the return address.
  SDValue RetAddrFI = getReturnAddressFrameIndex(PtrVT, DAG);
  return DAG.getLoad(PtrVT, dl, DAG.getEntryNode(), RetAddrFI,
                     MachinePointerInfo());
}

// This is the stored frame address of VarArg functions ?
SDValue CPU74TargetLowering::LowerFRAMEADDR(SDValue Op, SelectionDAG &DAG) const
{
  MachineFrameInfo &MFI = DAG.getMachineFunction().getFrameInfo();
  MFI.setFrameAddressIsTaken(true);   // This will be used by TargetFrameLowering::hasFP()

  EVT VT = Op.getValueType();
  SDLoc dl(Op);
  unsigned Depth = cast<ConstantSDNode>(Op.getOperand(0))->getZExtValue();
  SDValue FrameAddr = DAG.getCopyFromReg(DAG.getEntryNode(), dl, CPU74::R6, VT);
  while (Depth--)
    FrameAddr = DAG.getLoad(VT, dl, DAG.getEntryNode(), FrameAddr, MachinePointerInfo());

  return FrameAddr;
}


// Dynamic stack allocation for variable sized objects
SDValue CPU74TargetLowering::LowerDYNAMIC_STACKALLOC(SDValue Op, SelectionDAG &DAG) const
{
  SDLoc dl(Op);
  EVT VT = getPointerTy(DAG.getDataLayout());
  
  // Get the inputs.
  SDValue Chain = Op.getOperand(0);
  SDValue Size  = Op.getOperand(1);
  unsigned align = cast<ConstantSDNode>(Op.getOperand(2))->getZExtValue();

  
  SDValue SP = DAG.getRegister(CPU74::SP, VT);
  
//  SDValue SP = DAG.getCopyFromReg(Chain, dl, CPU74::SP, VT);
//  Chain = SP.getValue(1);
  
  SP = DAG.getNode(ISD::SUB, dl, MVT::i16, SP, Size);
  if (align)
  {
    SDValue constN = DAG.getConstant(-(uint16_t)align, dl, VT);
    SP = DAG.getNode(ISD::AND, dl, VT, SP.getValue(0), constN);
  }

  Chain = DAG.getCopyToReg(Chain, dl, CPU74::SP, SP);
  
  SDValue Ops[2] = { SP, Chain };
  return DAG.getMergeValues(Ops, dl);
}


SDValue CPU74TargetLowering::LowerVASTART(SDValue Op, SelectionDAG &DAG) const
{
  MachineFunction &MF = DAG.getMachineFunction();
  CPU74MachineFunctionInfo *FuncInfo = MF.getInfo<CPU74MachineFunctionInfo>();

  // vastart just stores the address of the VarArgsFrameIndex slot into the
  // memory location argument.
  SDLoc dl(Op);
  EVT PtrVT = getPointerTy(DAG.getDataLayout());
  SDValue Addr = DAG.getFrameIndex(FuncInfo->getVarArgsFrameIndex(), PtrVT);
  const Value *SV = cast<SrcValueSDNode>(Op.getOperand(2))->getValue();
  return DAG.getStore(Op.getOperand(0), dl, Addr, Op.getOperand(1), MachinePointerInfo(SV));
}


// Comentat JLZ
///// getPostIndexedAddressParts - returns true by value, base pointer and
///// offset pointer and addressing mode by reference if this node can be
///// combined with a load / store to form a post-indexed load / store.
//bool CPU74TargetLowering::getPostIndexedAddressParts(SDNode *N, SDNode *Op,
//                                                      SDValue &Base,
//                                                      SDValue &Offset,
//                                                      ISD::MemIndexedMode &AM,
//                                                      SelectionDAG &DAG) const {
//
//  LoadSDNode *LD = cast<LoadSDNode>(N);
//  if (LD->getExtensionType() != ISD::NON_EXTLOAD)
//    return false;
//
//  EVT VT = LD->getMemoryVT();
//  if (VT != MVT::i8 && VT != MVT::i16)
//    return false;
//
//  if (Op->getOpcode() != ISD::ADD)
//    return false;
//
//  if (ConstantSDNode *RHS = dyn_cast<ConstantSDNode>(Op->getOperand(1))) {
//    uint64_t RHSC = RHS->getZExtValue();
//    if ((VT == MVT::i16 && RHSC != 2) ||
//        (VT == MVT::i8 && RHSC != 1))
//      return false;
//
//    Base = Op->getOperand(0);
//    Offset = DAG.getConstant(RHSC, SDLoc(N), VT);
//    AM = ISD::POST_INC;
//    return true;
//  }
//
//  return false;
//}


const char *CPU74TargetLowering::getTargetNodeName(unsigned Opcode) const
{
  switch ((CPU74ISD::NodeType)Opcode)
  {
  case CPU74ISD::FIRST_NUMBER:       break;
  case CPU74ISD::RET_FLAG:           return "CPU74ISD::RET_FLAG";
  case CPU74ISD::RETI_FLAG:          return "CPU74ISD::RETI_FLAG";
  case CPU74ISD::ASR:                return "CPU74ISD::ASR";
  case CPU74ISD::LSL:                return "CPU74ISD::LSL";
  case CPU74ISD::LSR:                return "CPU74ISD::LSR";
  case CPU74ISD::SEXTW:                return "CPU74ISD::SEXTW";
  //case CPU74ISD::CallArgLoc:          return "CPU74ISD::CallArgLoc";
  case CPU74ISD::CALL:               return "CPU74ISD::CALL";
  //case CPU74ISD::SingleValWrapper:    return "CPU74ISD::SingleValWrapper";
  case CPU74ISD::AggregateWrapper:    return "CPU74ISD::AggregateWrapper";
  case CPU74ISD::CMP:                return "CPU74ISD::CMP";
  case CPU74ISD::ADD:                return "CPU74ISD::ADD";
  case CPU74ISD::SUB:                return "CPU74ISD::SUB";
  case CPU74ISD::AND:                return "CPU74ISD::AND";
  case CPU74ISD::OR:                 return "CPU74ISD::OR";
  case CPU74ISD::XOR:                return "CPU74ISD::XOR";
  case CPU74ISD::ADDO:                return "CPU74ISD::ADDO";
  case CPU74ISD::SUBO:                return "CPU74ISD::SUBO";
  case CPU74ISD::ADDC:                return "CPU74ISD::ADDC";
  case CPU74ISD::SUBC:                return "CPU74ISD::SUBC";
  case CPU74ISD::BR_CC:              return "CPU74ISD::BR_CC";
  case CPU74ISD::SET_CC:             return "CPU74ISD::SET_CC";
  case CPU74ISD::SEL_CC:             return "CPU74ISD::SEL_CC";
//  case CPU74ISD::SWAP:               return "CPU74ISD::SWAP";
  }
  return nullptr;
}

// Comentat JLZ
//bool CPU74TargetLowering::isTruncateFree(Type *Ty1,
//                                          Type *Ty2) const {
//  if (!Ty1->isIntegerTy() || !Ty2->isIntegerTy())
//    return false;
//
//  return (Ty1->getPrimitiveSizeInBits() > Ty2->getPrimitiveSizeInBits());
//}
//
//bool CPU74TargetLowering::isTruncateFree(EVT VT1, EVT VT2) const {
//  if (!VT1.isInteger() || !VT2.isInteger())
//    return false;
//
//  return (VT1.getSizeInBits() > VT2.getSizeInBits());
//}
//
//bool CPU74TargetLowering::isZExtFree(Type *Ty1, Type *Ty2) const {
//  // CPU74 implicitly zero-extends 8-bit results in 16-bit registers.
//  return 0 && Ty1->isIntegerTy(8) && Ty2->isIntegerTy(16);
//}
//
//bool CPU74TargetLowering::isZExtFree(EVT VT1, EVT VT2) const {
//  // CPU74 implicitly zero-extends 8-bit results in 16-bit registers.
//  return 0 && VT1 == MVT::i8 && VT2 == MVT::i16;
//}
//
//bool CPU74TargetLowering::isZExtFree(SDValue Val, EVT VT2) const {
//  return isZExtFree(Val.getValueType(), VT2);
//}

//===----------------------------------------------------------------------===//
//  Other Lowering Code
//===----------------------------------------------------------------------===//


//MachineBasicBlock *
//CPU74TargetLowering::EmitSelectCC(MachineInstr &MI, MachineBasicBlock *BB) const
//{
//  const TargetInstrInfo &TII = *BB->getParent()->getSubtarget().getInstrInfo();
//  DebugLoc dl = MI.getDebugLoc();
//
// //JLZ assert((Opc == CPU74::Select16 || Opc == CPU74::Select8) && "Unexpected instr type to insert");
// // assert((Opc == CPU74::Select16 ) && "Unexpected instr type to insert");
//
//  // To "insert" a SELECT instruction, we actually have to insert the diamond
//  // control-flow pattern.  The incoming instruction knows the destination vreg
//  // to set, the condition code register to branch on, the true/false values to
//  // select between, and a branch opcode to use.
//  const BasicBlock *LLVM_BB = BB->getBasicBlock();
//  MachineFunction::iterator I = ++BB->getIterator();
//
//  //  thisMBB:
//  //  ...
//  //   TrueVal = ...
//  //   cmpTY ccX, r1, r2
//  //   jCC copy1MBB
//  //   fallthrough --> copy0MBB
//  MachineBasicBlock *thisMBB = BB;
//  MachineFunction *F = BB->getParent();
//  MachineBasicBlock *copy0MBB = F->CreateMachineBasicBlock(LLVM_BB);
//  MachineBasicBlock *copy1MBB = F->CreateMachineBasicBlock(LLVM_BB);
//  F->insert(I, copy0MBB);
//  F->insert(I, copy1MBB);
//  // Update machine-CFG edges by transferring all successors of the current
//  // block to the new block which will contain the Phi node for the select.
//  copy1MBB->splice(copy1MBB->begin(), BB,
//                   std::next(MachineBasicBlock::iterator(MI)), BB->end());
//  copy1MBB->transferSuccessorsAndUpdatePHIs(BB);
//  // Next, add the true and fallthrough blocks as its successors.
//  BB->addSuccessor(copy0MBB);
//  BB->addSuccessor(copy1MBB);
//
//  BuildMI(BB, dl, TII.get(CPU74::JCC))
//      .addMBB(copy1MBB)
//      .addImm(MI.getOperand(3).getImm());
//
//  //  copy0MBB:
//  //   %FalseValue = ...
//  //   # fallthrough to copy1MBB
//  BB = copy0MBB;
//
//  // Update machine-CFG edges
//  BB->addSuccessor(copy1MBB);
//
//  //  copy1MBB:
//  //   %Result = phi [ %FalseValue, copy0MBB ], [ %TrueValue, thisMBB ]
//  //  ...
//  BB = copy1MBB;
//  BuildMI(*BB, BB->begin(), dl, TII.get(CPU74::PHI), MI.getOperand(0).getReg())
//      .addReg(MI.getOperand(2).getReg())
//      .addMBB(copy0MBB)
//      .addReg(MI.getOperand(1).getReg())
//      .addMBB(thisMBB);
//
//  MI.eraseFromParent(); // The pseudo instruction is gone now.
//  return BB;
//}


// Comentat JLZ
//MachineBasicBlock *
//CPU74TargetLowering::EmitConstantShiftInstr(MachineInstr &MI,
//                                     MachineBasicBlock *BB) const
//
//{
//
//  unsigned Imm = MI.getOperand(1).getImm();
//  unsigned DstReg = MI.getOperand(0).getReg();
//
//  unsigned Opc;
//  const TargetRegisterClass * RC;
//  switch (MI.getOpcode())
//  {
//    default: llvm_unreachable("Invalid shift opcode!");
//    case CPU74::Shl16:
//        Opc = CPU74::LSLrr16;
//        RC = &CPU74::GR16RegClass;
//        break;
//    case CPU74::Sra16:
//        Opc = CPU74::ASRrr16;
//        RC = &CPU74::GR16RegClass;
//        break;
//    case CPU74::Srl16:
//   //Opc = CPU74::SAR16r1c;
//        Opc = CPU74::LSRCrr16;
//        RC = &CPU74::GR16RegClass;
//        break;
//  }
//  return BB;
//}




//MachineBasicBlock *
//CPU74TargetLowering::EmitShiftInstr(MachineInstr &MI,
//                                     MachineBasicBlock *BB) const {
//
////   if ( MI.getOperand(0).isImm() )
////   {
////      return EmitConstantShiftInstr( MI, BB );
////   }
//
//// Pseudo shift instructions with a non constant shift amount are expanded
//// into a loop.
//
//  MachineFunction *F = BB->getParent();
//  MachineRegisterInfo &RI = F->getRegInfo();
//  DebugLoc dl = MI.getDebugLoc();
//  const TargetInstrInfo &TII = *F->getSubtarget().getInstrInfo();
//
//  unsigned Opc;
//  const TargetRegisterClass * RC;
//  switch (MI.getOpcode()) {
//  default: llvm_unreachable("Invalid shift opcode!");
//  case CPU74::Shl16:
//   //Opc = CPU74::SHL16r1;
//   Opc = CPU74::LSLrr16;
//   RC = &CPU74::GR16RegClass;
//   break;
//  case CPU74::Sra16:
//   //Opc = CPU74::SAR16r1;
//   Opc = CPU74::ASRrr16;
//   RC = &CPU74::GR16RegClass;
//   break;
//  case CPU74::Srl16:
//   //Opc = CPU74::SAR16r1c;
//   Opc = CPU74::LSRCrr16;
//   RC = &CPU74::GR16RegClass;
//   break;
//  }
//
//  const BasicBlock *LLVM_BB = BB->getBasicBlock();
//  MachineFunction::iterator I = ++BB->getIterator();
//
//  // Create loop block
//  MachineBasicBlock *LoopBB = F->CreateMachineBasicBlock(LLVM_BB);
//  MachineBasicBlock *RemBB  = F->CreateMachineBasicBlock(LLVM_BB);
//
//  F->insert(I, LoopBB);
//  F->insert(I, RemBB);
//
//  // Update machine-CFG edges by transferring all successors of the current
//  // block to the block containing instructions after shift.
//  RemBB->splice(RemBB->begin(), BB, std::next(MachineBasicBlock::iterator(MI)),
//                BB->end());
//  RemBB->transferSuccessorsAndUpdatePHIs(BB);
//
//  // Add edges BB => LoopBB => RemBB, BB => RemBB, LoopBB => LoopBB
//  BB->addSuccessor(LoopBB);
//  BB->addSuccessor(RemBB);
//  LoopBB->addSuccessor(RemBB);
//  LoopBB->addSuccessor(LoopBB);
//
//  unsigned ShiftAmtReg = RI.createVirtualRegister(&CPU74::GR16RegClass);
//  unsigned ShiftAmtReg2 = RI.createVirtualRegister(&CPU74::GR16RegClass);
//  unsigned ShiftReg = RI.createVirtualRegister(RC);
//  unsigned ShiftReg2 = RI.createVirtualRegister(RC);
//  unsigned ShiftAmtSrcReg = MI.getOperand(2).getReg();
//  unsigned SrcReg = MI.getOperand(1).getReg();
//  unsigned DstReg = MI.getOperand(0).getReg();
//
//  // BB:
//  // cmp 0, N
//  // je RemBB
//  //BuildMI(BB, dl, TII.get(CPU74::CMP8ri))
//  BuildMI(BB, dl, TII.get(CPU74::CMPkr16))
//    .addReg(ShiftAmtSrcReg).addImm(0);
//  BuildMI(BB, dl, TII.get(CPU74::JCC))
//    .addMBB(RemBB)
//    .addImm(CPU74CC::COND_EQ);
//
//  // LoopBB:
//  // ShiftReg = phi [%SrcReg, BB], [%ShiftReg2, LoopBB]
//  // ShiftAmt = phi [%N, BB],      [%ShiftAmt2, LoopBB]
//  // ShiftReg2 = shift ShiftReg
//  // ShiftAmt2 = ShiftAmt - 1;
//  BuildMI(LoopBB, dl, TII.get(CPU74::PHI), ShiftReg)
//    .addReg(SrcReg).addMBB(BB)
//    .addReg(ShiftReg2).addMBB(LoopBB);
//  BuildMI(LoopBB, dl, TII.get(CPU74::PHI), ShiftAmtReg)
//    .addReg(ShiftAmtSrcReg).addMBB(BB)
//    .addReg(ShiftAmtReg2).addMBB(LoopBB);
//  BuildMI(LoopBB, dl, TII.get(Opc), ShiftReg2)
//    .addReg(ShiftReg);
//  //BuildMI(LoopBB, dl, TII.get(CPU74::SUB8ri), ShiftAmtReg2)
//  BuildMI(LoopBB, dl, TII.get(CPU74::SUBkr16), ShiftAmtReg2)
//    .addReg(ShiftAmtReg).addImm(1);
//  BuildMI(LoopBB, dl, TII.get(CPU74::JCC))
//    .addMBB(LoopBB)
//    .addImm(CPU74CC::COND_NE);
//
//  // RemBB:
//  // DestReg = phi [%SrcReg, BB], [%ShiftReg, LoopBB]
//  BuildMI(*RemBB, RemBB->begin(), dl, TII.get(CPU74::PHI), DstReg)
//    .addReg(SrcReg).addMBB(BB)
//    .addReg(ShiftReg2).addMBB(LoopBB);
//
//  MI.eraseFromParent(); // The pseudo instruction is gone now.
//  return RemBB;
//}
//


//
//
//
//MachineBasicBlock *
//CPU74TargetLowering::EmitShiftInstr(MachineInstr &MI,
//                                     MachineBasicBlock *BB) const {
//  MachineFunction *F = BB->getParent();
//  MachineRegisterInfo &RI = F->getRegInfo();
//  DebugLoc dl = MI.getDebugLoc();
//  const TargetInstrInfo &TII = *F->getSubtarget().getInstrInfo();
//
//  unsigned Opc;
//  const TargetRegisterClass * RC;
//  switch (MI.getOpcode()) {
//  default: llvm_unreachable("Invalid shift opcode!");
//  case CPU74::Shl8:
//   //Opc = CPU74::SHL8r1;
//   Opc = CPU74::LSLr8;
//   RC = &CPU74::GR8RegClass;
//   break;
//  case CPU74::Shl16:
//   //Opc = CPU74::SHL16r1;
//   Opc = CPU74::LSLr16;
//   RC = &CPU74::GR16RegClass;
//   break;
//  case CPU74::Sra8:
//   //Opc = CPU74::SAR8r1;
//   Opc = CPU74::ASRr8;
//   RC = &CPU74::GR8RegClass;
//   break;
//  case CPU74::Sra16:
//   //Opc = CPU74::SAR16r1;
//   Opc = CPU74::ASRr16;
//   RC = &CPU74::GR16RegClass;
//   break;
//  case CPU74::Srl8:
//   //Opc = CPU74::SAR8r1c;
//   Opc = CPU74::LSRCr8;
//   RC = &CPU74::GR8RegClass;
//   break;
//  case CPU74::Srl16:
//   //Opc = CPU74::SAR16r1c;
//   Opc = CPU74::LSRCr16;
//   RC = &CPU74::GR16RegClass;
//   break;
//  }
//
//  const BasicBlock *LLVM_BB = BB->getBasicBlock();
//  MachineFunction::iterator I = ++BB->getIterator();
//
//  // Create loop block
//  MachineBasicBlock *LoopBB = F->CreateMachineBasicBlock(LLVM_BB);
//  MachineBasicBlock *RemBB  = F->CreateMachineBasicBlock(LLVM_BB);
//
//  F->insert(I, LoopBB);
//  F->insert(I, RemBB);
//
//  // Update machine-CFG edges by transferring all successors of the current
//  // block to the block containing instructions after shift.
//  RemBB->splice(RemBB->begin(), BB, std::next(MachineBasicBlock::iterator(MI)),
//                BB->end());
//  RemBB->transferSuccessorsAndUpdatePHIs(BB);
//
//  // Add edges BB => LoopBB => RemBB, BB => RemBB, LoopBB => LoopBB
//  BB->addSuccessor(LoopBB);
//  BB->addSuccessor(RemBB);
//  LoopBB->addSuccessor(RemBB);
//  LoopBB->addSuccessor(LoopBB);
//
//  unsigned ShiftAmtReg = RI.createVirtualRegister(&CPU74::GR8RegClass);
//  unsigned ShiftAmtReg2 = RI.createVirtualRegister(&CPU74::GR8RegClass);
//  unsigned ShiftReg = RI.createVirtualRegister(RC);
//  unsigned ShiftReg2 = RI.createVirtualRegister(RC);
//  unsigned ShiftAmtSrcReg = MI.getOperand(2).getReg();
//  unsigned SrcReg = MI.getOperand(1).getReg();
//  unsigned DstReg = MI.getOperand(0).getReg();
//
//  // BB:
//  // cmp 0, N
//  // je RemBB
//  //BuildMI(BB, dl, TII.get(CPU74::CMP8ri))
//  BuildMI(BB, dl, TII.get(CPU74::CMPkr8))
//    .addReg(ShiftAmtSrcReg).addImm(0);
//  BuildMI(BB, dl, TII.get(CPU74::JCC))
//    .addMBB(RemBB)
//    .addImm(CPU74CC::COND_E);
//
//  // LoopBB:
//  // ShiftReg = phi [%SrcReg, BB], [%ShiftReg2, LoopBB]
//  // ShiftAmt = phi [%N, BB],      [%ShiftAmt2, LoopBB]
//  // ShiftReg2 = shift ShiftReg
//  // ShiftAmt2 = ShiftAmt - 1;
//  BuildMI(LoopBB, dl, TII.get(CPU74::PHI), ShiftReg)
//    .addReg(SrcReg).addMBB(BB)
//    .addReg(ShiftReg2).addMBB(LoopBB);
//  BuildMI(LoopBB, dl, TII.get(CPU74::PHI), ShiftAmtReg)
//    .addReg(ShiftAmtSrcReg).addMBB(BB)
//    .addReg(ShiftAmtReg2).addMBB(LoopBB);
//  BuildMI(LoopBB, dl, TII.get(Opc), ShiftReg2)
//    .addReg(ShiftReg);
//  //BuildMI(LoopBB, dl, TII.get(CPU74::SUB8ri), ShiftAmtReg2)
//  BuildMI(LoopBB, dl, TII.get(CPU74::SUBkr8), ShiftAmtReg2)
//    .addReg(ShiftAmtReg).addImm(1);
//  BuildMI(LoopBB, dl, TII.get(CPU74::JCC))
//    .addMBB(LoopBB)
//    .addImm(CPU74CC::COND_NE);
//
//  // RemBB:
//  // DestReg = phi [%SrcReg, BB], [%ShiftReg, LoopBB]
//  BuildMI(*RemBB, RemBB->begin(), dl, TII.get(CPU74::PHI), DstReg)
//    .addReg(SrcReg).addMBB(BB)
//    .addReg(ShiftReg2).addMBB(LoopBB);
//
//  MI.eraseFromParent(); // The pseudo instruction is gone now.
//  return RemBB;
//}
//
//
//


//MachineBasicBlock *
//CPU74TargetLowering::EmitInstrWithCustomInserter(MachineInstr &MI,
//                                                  MachineBasicBlock *BB) const {
//  unsigned Opc = MI.getOpcode();
//
////JLZ  if (Opc == CPU74::Shl8 || Opc == CPU74::Shl16 ||
////JLZ      Opc == CPU74::Sra8 || Opc == CPU74::Sra16 ||
////JLZ      Opc == CPU74::Srl8 || Opc == CPU74::Srl16)
//  
//  if (Opc == CPU74::Shl16 || Opc == CPU74::Sra16 || Opc == CPU74::Srl16)
//    return EmitShiftInstr(MI, BB);
//
////  if (Opc == CPU74::Select16)
////    return EmitSelectCC(MI, BB);
//  
//  assert( 0 && "Unexpected instr type to insert");
//  return 0;
//}



SDValue CPU74TargetLowering::PerformDAGCombine(SDNode *N, DAGCombinerInfo &DCI) const
{
//  SelectionDAG &DAG = DCI.DAG;
//  SDLoc dl(N);
//  switch ( N->getOpcode() )
//  {
//      case ISD::SELECT_CC:
//        N->dump();
//      break;
//  }
  
  return SDValue();
}





SDValue CPU74TargetLowering::LowerOperation(SDValue Op, SelectionDAG &DAG) const
{
  ISD::NodeType opCodeNT = (ISD::NodeType)Op.getOpcode();
  
  switch (opCodeNT)
  {
    case ISD::SHL: // FALLTHROUGH
    case ISD::SRL:
    case ISD::SRA:                return LowerShifts(Op, DAG);
    //case ISD::UDIVREM:            return LowerUDIVREM(Op, DAG);
    case ISD::CTLZ:               return LowerCLZ(Op,DAG);
    case ISD::GlobalAddress:      return LowerGlobalAddress(Op, DAG);
    case ISD::BlockAddress:       return LowerBlockAddress(Op, DAG);
    case ISD::ExternalSymbol:     return LowerExternalSymbol(Op, DAG);
    case ISD::JumpTable:          return LowerJumpTable(Op, DAG);
    case ISD::SETCC:              return LowerSETCC(Op, DAG);
    case ISD::SELECT_CC:          return LowerSELECT_CC(Op, DAG);
    case ISD::BR_CC:              return LowerBR_CC(Op, DAG);
    //case ISD::SHL_PARTS:        return LowerSHL_PARTS(Op, DAG);
    //case ISD::SELECT:           return LowerSELECT(Op, DAG);
    
    
    case ISD::DYNAMIC_STACKALLOC: return LowerDYNAMIC_STACKALLOC(Op,DAG);
    case ISD::RETURNADDR:         return LowerRETURNADDR(Op, DAG);
    case ISD::FRAMEADDR:          return LowerFRAMEADDR(Op, DAG);
    case ISD::VASTART:            return LowerVASTART(Op, DAG);
    case ISD::UADDO:
    case ISD::USUBO:              return LowerUALUO(Op, DAG);
    case ISD::ADDCARRY:
    case ISD::SUBCARRY:           return LowerADDSUBCARRY(Op, DAG);
    default:
      llvm_unreachable("unimplemented operand");
  }
}





// Estimate the size of the stack, including the incoming arguments. We need to
// account for push register spills, local objects, reserved call frame and incoming
// arguments. This is required to determine the largest possible positive offset
// from SP so that it can be determined if an  spill slot for stack
// addresses is required. See: MipsFrameLowering::estimateStackSize
static unsigned argumentsSize(const MachineFunction &MF)
{
  const MachineFrameInfo &MFI = MF.getFrameInfo();
  unsigned size = 0;

  // Iterate over fixed sized objects which are incoming arguments.
  int beg = MFI.getObjectIndexBegin();
  for (int i = beg; i < 0; i++)
      size += MFI.getObjectSize(i);

  // Get the size of the rest of the frame objects and any possible reserved
  // call frame, accounting for alignment.
  return size; // + MFI.estimateStackSize(MF);
}


// Figure out which registers should be reserved for stack access. Only after
// the function is legalized do we know all of the non-spill stack objects or if
// calls are present.
void CPU74TargetLowering::finalizeLowering(MachineFunction &MF) const
{
  MachineFrameInfo &MFI = MF.getFrameInfo();
  const TargetFrameLowering *TFI = MF.getSubtarget().getFrameLowering();
  CPU74MachineFunctionInfo *FuncInf = MF.getInfo<CPU74MachineFunctionInfo>();
  const TargetRegisterInfo *RegInfo = MF.getSubtarget().getRegisterInfo();

  MFI.computeMaxCallFrameSize(MF);
  
  unsigned argsSize = argumentsSize(MF);
  unsigned maxOffset = argsSize + MFI.estimateStackSize(MF);
  
  // Conservatively assume all callee-saved registers will be saved (*)
  // (*) Don't actually do this.
  // (*) We rather delay use of R6 until there's really big offsets into the arguments
  if ( 0 )
  {
    for (const MCPhysReg *reg = RegInfo->getCalleeSavedRegs(&MF); *reg != 0; ++reg)
    {
      unsigned RegSize = RegInfo->getSpillSize(  CPU74::GR16RegClass /* *(RegInfo->getMinimalPhysRegClass(*reg))*/ );
      maxOffset = alignTo(maxOffset + RegSize, RegSize);
    }
  }
  
  if ( MFI.getObjectIndexBegin() < 0 )
    maxOffset += 2; // account for PC

  FuncInf->setArgumentsSize( argsSize );
  FuncInf->setEstimatedFrameSize( maxOffset );
  
  //FuncInf->setHasBigOffsets( !(maxOffset <= CPU74Imm::MaxImm6) );
  
  // Physical register allocation will start just after this has finished
  TargetLoweringBase::finalizeLowering(MF);
}


//////////////////////////////////////////////////////////////////////////////
// Align Visit Pass
//////////////////////////////////////////////////////////////////////////////

namespace
{
    struct AlignVisitPass : public ModulePass
    {
        static char ID;
        AlignVisitPass() : ModulePass(ID) { }

        virtual bool runOnModule(Module &M) override;
    };
}

char AlignVisitPass::ID = 0;

#ifndef NDEBUG
static void globObjectPrint( raw_ostream &O, const char *prefix, const GlobalObject &g)
{
//      LLVM_DEBUG(dbgs() << "GlobalObject (" );
//      g.getValueType()->print( dbgs() );
//      LLVM_DEBUG(dbgs() << ") " << g.getName() << ", align " << g.getAlignment() << "\n" );
  
      O << prefix << " (";
      g.getValueType()->print( O );
      O << ") " << g.getName() << ", align " << g.getAlignment() << "\n";
}
#endif

bool AlignVisitPass::runOnModule(Module &M)
{
  LLVM_DEBUG(dbgs() << "\n********** Begin Align Visit pass **********\n" );
  
  const DataLayout &DL = M.getDataLayout();
  SymbolTableList<GlobalVariable> &stList = M.getGlobalList();
  
  for ( GlobalVariable &globVar : stList )
  {
    #ifndef NDEBUG
    globObjectPrint( dbgs(), "GlobalObject:", globVar );
    #endif
      
    // Early next
    Type *type = globVar.getValueType();
    if ( type->isSingleValueType() )
      continue;
    
    unsigned align = globVar.getAlignment();
    unsigned prefAlign = DL.getPrefTypeAlignment( type );
    
    // Make sure aggregate objects are at least aligned by the preferred alignment
    if ( type->isAggregateType() && align < prefAlign)
    {
      globVar.setAlignment( prefAlign );
        
      #ifndef NDEBUG
      globObjectPrint( dbgs(), "\tChanged object to:", globVar );
      #endif
    }
  }
  
  LLVM_DEBUG(dbgs() << "********** End Align Visit pass **********\n\n" );

  // We didn't actually modified the modude, so return false
  return false;
}

// Creates instance of the align visit pass.
ModulePass  *llvm::createAlignVisitPass() { return new AlignVisitPass(); }



