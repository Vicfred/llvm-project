// Immediate operand of arbitrary bit width
class BitWidthImmOperand<int width>
  : ImmAsmOperand<0, !add(!shl(1, width), -1)> {
  let Name = "Imm"#width#"b";
}

class BitWidthImm<int width>
  : Operand<i32>,
    ImmLeaf<i32, "{ return Imm >= 0 && Imm < (1 << "#width#"); }"> {
  let ParserMatchClass = BitWidthImmOperand<width>;
}

def CDEDualRegOp : RegisterOperand<GPRPairnosp, "printGPRPairOperand">;

// Used by VCX3 FP
def imm_3b : BitWidthImm<3>;

// Used by VCX3 vector
def imm_4b : BitWidthImm<4>;

// Used by VCX2 FP and CX3
def imm_6b :  BitWidthImm<6>;

// Used by VCX2 vector
def imm_7b :  BitWidthImm<7>;

// Used by CX2
def imm_9b :  BitWidthImm<9>;

// Used by VCX1 FP
def imm_11b : BitWidthImm<11>;

// Used by VCX1 vector
def imm_12b : BitWidthImm<12>;

// Used by CX1
def imm_13b : BitWidthImm<13>;

// Base class for all CDE instructions
class CDE_Instr<bit acc, dag oops, dag iops, string asm, string cstr>
  : Thumb2XI<oops, !con((ins p_imm:$coproc), iops),
             AddrModeNone, /*sz=*/4, NoItinerary,
             asm, cstr, /*pattern=*/[]>,
    Sched<[]> {
  bits<3> coproc;

  let Inst{31-29} = 0b111;  // 15:13
  let Inst{28} = acc;
  let Inst{27-26} = 0b11;
  let Inst{11} = 0b0;
  let Inst{10-8} = coproc{2-0};

  let isPredicable = 0;
  let DecoderNamespace = "Thumb2CDE";
}

// Base class for CX* CDE instructions
class CDE_GPR_Instr<bit dual, bit acc, dag oops, dag iops,
                    string asm, string cstr>
  : CDE_Instr<acc, oops, iops, asm, cstr>,
    Requires<[HasCDE]> {

  let Inst{25-24} = 0b10;
  let Inst{6} = dual;
  let isPredicable = acc;
}

// Set of registers used by the CDE instructions.
class CDE_RegisterOperands {
  dag Rd;
  dag Rd_src;
  dag Rn;
  dag Rm;
}

// CX* CDE instruction parameter set
class CX_Params {
  dag Oops;      // Output operands for CX* instructions
  dag Iops1;     // Input operands for CX1* instructions
  dag Iops2;     // Input operands for CX2* instructions
  dag Iops3;     // Input operands for CX3* instructions
  dag PredOp;    // Input predicate operand
  string PAsm;   // Predicate assembly string
  string Cstr;   // asm constraint string
  bit Dual;      // "dual" field for encoding
  bit Acc;       // "acc" field for encoding
}

// VCX* CDE instruction parameter set
class VCX_Params {
  dag Oops;      // Output operands for VCX* instructions
  dag Iops1;     // Input operands for VCX1* instructions
  dag Iops2;     // Input operands for VCX2* instructions
  dag Iops3;     // Input operands for VCX3* instructions
  string Cstr;   // asm constraint string
  bit Acc;       // "acc" field for encoding
  vpred_ops Vpred; // Predication type for VCX* vector instructions
}

// CX1, CX1A, CX1D, CX1DA
class CDE_CX1_Instr<string iname, CX_Params params>
  : CDE_GPR_Instr<params.Dual, params.Acc, params.Oops,
                  !con(params.Iops1, (ins imm_13b:$imm), params.PredOp),
                  !strconcat(iname, params.PAsm, "\t$coproc, $Rd, $imm"),
                  params.Cstr> {
  bits<13> imm;
  bits<4> Rd;

  let Inst{23-22} = 0b00;
  let Inst{21-16} = imm{12-7};
  let Inst{15-12} = Rd{3-0};
  let Inst{7} = imm{6};
  let Inst{5-0} = imm{5-0};
}

// CX2, CX2A, CX2D, CX2DA
class CDE_CX2_Instr<string iname, CX_Params params>
  : CDE_GPR_Instr<params.Dual, params.Acc, params.Oops,
                  !con(params.Iops2, (ins imm_9b:$imm), params.PredOp),
                  !strconcat(iname, params.PAsm, "\t$coproc, $Rd, $Rn, $imm"),
                  params.Cstr> {
  bits<9> imm;
  bits<4> Rd;
  bits<4> Rn;

  let Inst{23-22} = 0b01;
  let Inst{21-20} = imm{8-7};
  let Inst{19-16} = Rn{3-0};
  let Inst{15-12} = Rd{3-0};
  let Inst{7} = imm{6};
  let Inst{5-0} = imm{5-0};
}

// CX3, CX3A, CX3D, CX3DA
class CDE_CX3_Instr<string iname, CX_Params params>
  : CDE_GPR_Instr<params.Dual, params.Acc, params.Oops,
                  !con(params.Iops3, (ins imm_6b:$imm), params.PredOp),
                  !strconcat(iname, params.PAsm, "\t$coproc, $Rd, $Rn, $Rm, $imm"),
                  params.Cstr> {
  bits<6> imm;
  bits<4> Rd;
  bits<4> Rn;
  bits<4> Rm;

  let Inst{23} = 0b1;
  let Inst{22-20} = imm{5-3};
  let Inst{19-16} = Rn{3-0};
  let Inst{15-12} = Rm{3-0};
  let Inst{7} = imm{2};
  let Inst{5-4} = imm{1-0};
  let Inst{3-0} = Rd{3-0};
}

// Registers for single-register variants of CX* instructions
def cde_cx_single_regs : CDE_RegisterOperands {
  let Rd = (outs GPRwithAPSR_NZCVnosp:$Rd);
  let Rd_src = (ins GPRwithAPSR_NZCVnosp:$Rd_src);
  let Rn = (ins GPRwithAPSR_NZCVnosp:$Rn);
  let Rm = (ins GPRwithAPSR_NZCVnosp:$Rm);
}

// Registers for single-register variants of CX* instructions
def cde_cx_dual_regs : CDE_RegisterOperands {
  let Rd = (outs CDEDualRegOp:$Rd);
  let Rd_src = (ins CDEDualRegOp:$Rd_src);
  let Rn = (ins GPRwithAPSR_NZCVnosp:$Rn);
  let Rm = (ins GPRwithAPSR_NZCVnosp:$Rm);
}

class CDE_CX_ParamsTemplate<bit dual, bit acc, CDE_RegisterOperands ops>
  : CX_Params {

  dag IOpsPrefix = !if(acc, ops.Rd_src, (ins));

  let Oops = ops.Rd;
  let Iops1 = IOpsPrefix;
  let Iops2 = !con(IOpsPrefix, ops.Rn);
  let Iops3 = !con(IOpsPrefix, ops.Rn, ops.Rm);
  let PredOp = !if(acc, (ins pred:$p), (ins));
  let PAsm = !if(acc, "${p}", "");
  let Cstr = !if(acc, "$Rd = $Rd_src", "");
  let Dual = dual;
  let Acc = acc;
}

def cde_cx_params_single_noacc : CDE_CX_ParamsTemplate<0b0, 0b0, cde_cx_single_regs>;
def cde_cx_params_single_acc   : CDE_CX_ParamsTemplate<0b0, 0b1, cde_cx_single_regs>;
def cde_cx_params_dual_noacc   : CDE_CX_ParamsTemplate<0b1, 0b0, cde_cx_dual_regs>;
def cde_cx_params_dual_acc     : CDE_CX_ParamsTemplate<0b1, 0b1, cde_cx_dual_regs>;

def CDE_CX1   : CDE_CX1_Instr<"cx1",    cde_cx_params_single_noacc>;
def CDE_CX1A  : CDE_CX1_Instr<"cx1a",   cde_cx_params_single_acc>;
def CDE_CX1D  : CDE_CX1_Instr<"cx1d",   cde_cx_params_dual_noacc>;
def CDE_CX1DA : CDE_CX1_Instr<"cx1da",  cde_cx_params_dual_acc>;

def CDE_CX2   : CDE_CX2_Instr<"cx2",    cde_cx_params_single_noacc>;
def CDE_CX2A  : CDE_CX2_Instr<"cx2a",   cde_cx_params_single_acc>;
def CDE_CX2D  : CDE_CX2_Instr<"cx2d",   cde_cx_params_dual_noacc>;
def CDE_CX2DA : CDE_CX2_Instr<"cx2da",  cde_cx_params_dual_acc>;

def CDE_CX3   : CDE_CX3_Instr<"cx3",    cde_cx_params_single_noacc>;
def CDE_CX3A  : CDE_CX3_Instr<"cx3a",   cde_cx_params_single_acc>;
def CDE_CX3D  : CDE_CX3_Instr<"cx3d",   cde_cx_params_dual_noacc>;
def CDE_CX3DA : CDE_CX3_Instr<"cx3da",  cde_cx_params_dual_acc>;

class CDE_RequiresSReg : Requires<[HasCDE, HasFPRegs]>;
class CDE_RequiresDReg : Requires<[HasCDE, HasFPRegs]>;
class CDE_RequiresQReg : Requires<[HasCDE, HasMVEInt]>;

// Base class for CDE VCX* instructions
class CDE_FP_Vec_Instr<bit vec, bit acc, dag oops, dag iops, string asm, string cstr>
  : CDE_Instr<acc, oops, iops, asm, cstr> {
  let Inst{25} = 0b0;
  let Inst{6} = vec;
}

// Base class for floating-point variants of CDE VCX* intructions
class CDE_FP_Instr<bit acc, bit sz, dag oops, dag iops, string asm, string cstr>
  : CDE_FP_Vec_Instr<0b0, acc, oops, iops, asm, cstr> {
  let Inst{24} = sz;
}

// Base class for vector variants of CDE VCX* instruction
class CDE_Vec_Instr<bit acc, dag oops, dag iops, string asm, string cstr,
                    vpred_ops vpred>
  : CDE_FP_Vec_Instr<0b1, acc, oops,
                     !con(iops, (ins vpred:$vp)), asm,
                     !strconcat(cstr, vpred.vpred_constraint)>,
    CDE_RequiresQReg {
}


// VCX1/VCX1A, vector variant
class CDE_VCX1_Vec_Instr<string iname, VCX_Params params>
  : CDE_Vec_Instr<params.Acc, params.Oops,
                 !con(params.Iops1, (ins imm_12b:$imm)),
                 iname#"${vp}\t$coproc, $Qd, $imm", params.Cstr, params.Vpred> {
  bits<12> imm;
  bits<3> Qd;

  let Inst{24} = imm{11};
  let Inst{23} = 0b0;
  let Inst{22} = 0b0;
  let Inst{21-20} = 0b10;
  let Inst{19-16} = imm{10-7};
  let Inst{15-13} = Qd{2-0};
  let Inst{12} = 0b0;
  let Inst{7} = imm{6};
  let Inst{5-0} = imm{5-0};

  let Unpredictable{22} = 0b1;
}

// VCX1/VCX1A, base class for FP variants
class CDE_VCX1_FP_Instr<bit sz, string iname, VCX_Params params>
  : CDE_FP_Instr<params.Acc, sz, params.Oops,
                 !con(params.Iops1, (ins imm_11b:$imm)),
                 iname#"\t$coproc, $Vd, $imm", params.Cstr> {
  bits<11> imm;

  let Inst{23} = 0b0;
  let Inst{21-20} = 0b10;
  let Inst{19-16} = imm{10-7};
  let Inst{7} = imm{6};
  let Inst{5-0} = imm{5-0};
}

// VCX1/VCX1A, S registers
class CDE_VCX1_FP_Instr_S<string iname, VCX_Params params>
  : CDE_VCX1_FP_Instr<0b0, iname, params>,
    CDE_RequiresSReg {
  bits<5> Vd;

  let Inst{22} = Vd{0};
  let Inst{15-12} = Vd{4-1};
}

// VCX1/VCX1A, D registers
class CDE_VCX1_FP_Instr_D<string iname, VCX_Params params>
  : CDE_VCX1_FP_Instr<0b1, iname, params>,
    CDE_RequiresDReg {
  bits<5> Vd;

  let Inst{22} = Vd{4};
  let Inst{15-12} = Vd{3-0};
}

// VCX2/VCX2A, vector variant
class CDE_VCX2_Vec_Instr<string iname, VCX_Params params>
  : CDE_Vec_Instr<params.Acc, params.Oops,
                 !con(params.Iops2, (ins imm_7b:$imm)),
                 iname#"${vp}\t$coproc, $Qd, $Qm, $imm", params.Cstr,
                 params.Vpred> {
  bits<7> imm;
  bits<3> Qd;
  bits<3> Qm;

  let Inst{24} = imm{6};
  let Inst{23} = 0b0;
  let Inst{22} = 0b0;
  let Inst{21-20} = 0b11;
  let Inst{19-16} = imm{5-2};
  let Inst{15-13} = Qd{2-0};
  let Inst{12} = 0b0;
  let Inst{7} = imm{1};
  let Inst{5} = 0b0;
  let Inst{4} = imm{0};
  let Inst{3-1} = Qm{2-0};
  let Inst{0} = 0b0;

  let Unpredictable{22} = 0b1;
  let Unpredictable{5} = 0b1;
}

// VCX2/VCX2A, base class for FP variants
class CDE_VCX2_FP_Instr<bit sz, string iname, VCX_Params params>
  : CDE_FP_Instr<params.Acc, sz, params.Oops,
                 !con(params.Iops2, (ins imm_6b:$imm)),
                 iname#"\t$coproc, $Vd, $Vm, $imm", params.Cstr> {
  bits<6> imm;

  let Inst{23} = 0b0;
  let Inst{21-20} = 0b11;
  let Inst{19-16} = imm{5-2};
  let Inst{7} = imm{1};
  let Inst{4} = imm{0};
}

// VCX2/VCX2A, S registers
class CDE_VCX2_FP_Instr_S<string iname, VCX_Params params>
  : CDE_VCX2_FP_Instr<0b0, iname, params>,
    CDE_RequiresSReg {
  bits<5> Vd;
  bits<5> Vm;

  let Inst{15-12} = Vd{4-1};
  let Inst{22} = Vd{0};
  let Inst{3-0} = Vm{4-1};
  let Inst{5} = Vm{0};
}

// VCX2/VCX2A, D registers
class CDE_VCX2_FP_Instr_D<string iname, VCX_Params params>
  : CDE_VCX2_FP_Instr<0b1, iname, params>,
    CDE_RequiresDReg {
  bits<5> Vd;
  bits<5> Vm;

  let Inst{15-12} = Vd{3-0};
  let Inst{22} = Vd{4};
  let Inst{3-0} = Vm{3-0};
  let Inst{5} = Vm{4};
}

// VCX3/VCX3A, vector variant
class CDE_VCX3_Vec_Instr<string iname, VCX_Params params>
  : CDE_Vec_Instr<params.Acc, params.Oops,
                 !con(params.Iops3, (ins imm_4b:$imm)),
                 iname#"${vp}\t$coproc, $Qd, $Qn, $Qm, $imm", params.Cstr,
                 params.Vpred> {
  bits<4> imm;
  bits<3> Qd;
  bits<3> Qm;
  bits<3> Qn;

  let Inst{24} = imm{3};
  let Inst{23} = 0b1;
  let Inst{22} = 0b0;
  let Inst{21-20} = imm{2-1};
  let Inst{19-17} = Qn{2-0};
  let Inst{16} = 0b0;
  let Inst{15-13} = Qd{2-0};
  let Inst{12} = 0b0;
  let Inst{7} = 0b0;
  let Inst{5} = 0b0;
  let Inst{4} = imm{0};
  let Inst{3-1} = Qm{2-0};
  let Inst{0} = 0b0;

  let Unpredictable{22} = 0b1;
  let Unpredictable{7} = 0b1;
  let Unpredictable{5} = 0b1;
}

// VCX3/VCX3A, base class for FP variants
class CDE_VCX3_FP_Instr<bit sz, string iname, VCX_Params params>
  : CDE_FP_Instr<params.Acc, sz, params.Oops,
                 !con(params.Iops3, (ins imm_3b:$imm)),
                 iname#"\t$coproc, $Vd, $Vn, $Vm, $imm", params.Cstr> {
  bits<3> imm;

  let Inst{23} = 0b1;
  let Inst{21-20} = imm{2-1};
  let Inst{4} = imm{0};
}

// VCX3/VCX3A, S registers
class CDE_VCX3_FP_Instr_S<string iname, VCX_Params params>
  : CDE_VCX3_FP_Instr<0b0, iname, params>,
    CDE_RequiresSReg {
  bits<5> Vd;
  bits<5> Vm;
  bits<5> Vn;

  let Inst{22} = Vd{0};
  let Inst{19-16} = Vn{4-1};
  let Inst{15-12} = Vd{4-1};
  let Inst{7} = Vn{0};
  let Inst{5} = Vm{0};
  let Inst{3-0} = Vm{4-1};
}

// VCX3/VCX3A, D registers
class CDE_VCX3_FP_Instr_D<string iname, VCX_Params params>
  : CDE_VCX3_FP_Instr<0b1, iname, params>,
    CDE_RequiresDReg {
  bits<5> Vd;
  bits<5> Vm;
  bits<5> Vn;

  let Inst{22} = Vd{4};
  let Inst{19-16} = Vn{3-0};
  let Inst{15-12} = Vd{3-0};
  let Inst{7} = Vn{4};
  let Inst{5} = Vm{4};
  let Inst{3-0} = Vm{3-0};
}

// Register operands for VCX* instructions
class CDE_VCX_RegisterOperandsTemplate<RegisterClass regclass>
  : CDE_RegisterOperands {
  let Rd = (outs regclass:$Vd);
  let Rd_src = (ins regclass:$Vd_src);
  let Rn = (ins regclass:$Vn);
  let Rm = (ins regclass:$Vm);
}

class CDE_VCXQ_RegisterOperandsTemplate<RegisterClass regclass>
  : CDE_RegisterOperands {
  let Rd = (outs regclass:$Qd);
  let Rd_src = (ins regclass:$Qd_src);
  let Rn = (ins regclass:$Qn);
  let Rm = (ins regclass:$Qm);
}

def cde_vcx_s_regs : CDE_VCX_RegisterOperandsTemplate<SPR>;
def cde_vcx_d_regs : CDE_VCX_RegisterOperandsTemplate<DPR_VFP2>;
def cde_vcx_q_regs : CDE_VCXQ_RegisterOperandsTemplate<MQPR>;

class CDE_VCX_ParamsTemplate<bit acc, CDE_RegisterOperands ops>
  : VCX_Params {

  dag IOpsPrefix = !if(acc, ops.Rd_src, (ins));

  let Oops = ops.Rd;
  let Iops1 = IOpsPrefix;
  let Iops2 = !con(IOpsPrefix, ops.Rm);
  let Iops3 = !con(IOpsPrefix, ops.Rn, ops.Rm);
  let Cstr = !if(acc, "$Vd = $Vd_src", "");
  let Acc = acc;
}

class CDE_VCXQ_ParamsTemplate<bit acc, CDE_RegisterOperands ops>
  : VCX_Params {

  dag IOpsPrefix = !if(acc, ops.Rd_src, (ins));

  let Oops = ops.Rd;
  let Iops1 = IOpsPrefix;
  let Iops2 = !con(IOpsPrefix, ops.Rm);
  let Iops3 = !con(IOpsPrefix, ops.Rn, ops.Rm);
  let Cstr = !if(acc, "$Qd = $Qd_src", "");
  let Acc = acc;
  let Vpred = !if(acc, vpred_n, vpred_r);
}

def cde_vcx_params_s_noacc : CDE_VCX_ParamsTemplate<0b0, cde_vcx_s_regs>;
def cde_vcx_params_s_acc   : CDE_VCX_ParamsTemplate<0b1, cde_vcx_s_regs>;
def cde_vcx_params_d_noacc : CDE_VCX_ParamsTemplate<0b0, cde_vcx_d_regs>;
def cde_vcx_params_d_acc   : CDE_VCX_ParamsTemplate<0b1, cde_vcx_d_regs>;
def cde_vcx_params_q_noacc : CDE_VCXQ_ParamsTemplate<0b0, cde_vcx_q_regs>;
def cde_vcx_params_q_acc   : CDE_VCXQ_ParamsTemplate<0b1, cde_vcx_q_regs>;

def CDE_VCX1_fpsp   : CDE_VCX1_FP_Instr_S<"vcx1",  cde_vcx_params_s_noacc>;
def CDE_VCX1A_fpsp  : CDE_VCX1_FP_Instr_S<"vcx1a", cde_vcx_params_s_acc>;
def CDE_VCX1_fpdp   : CDE_VCX1_FP_Instr_D<"vcx1",  cde_vcx_params_d_noacc>;
def CDE_VCX1A_fpdp  : CDE_VCX1_FP_Instr_D<"vcx1a", cde_vcx_params_d_acc>;
def CDE_VCX1_vec    : CDE_VCX1_Vec_Instr<"vcx1",   cde_vcx_params_q_noacc>;
def CDE_VCX1A_vec   : CDE_VCX1_Vec_Instr<"vcx1a",  cde_vcx_params_q_acc>;

def CDE_VCX2_fpsp   : CDE_VCX2_FP_Instr_S<"vcx2",  cde_vcx_params_s_noacc>;
def CDE_VCX2A_fpsp  : CDE_VCX2_FP_Instr_S<"vcx2a", cde_vcx_params_s_acc>;
def CDE_VCX2_fpdp   : CDE_VCX2_FP_Instr_D<"vcx2",  cde_vcx_params_d_noacc>;
def CDE_VCX2A_fpdp  : CDE_VCX2_FP_Instr_D<"vcx2a", cde_vcx_params_d_acc>;
def CDE_VCX2_vec    : CDE_VCX2_Vec_Instr<"vcx2",   cde_vcx_params_q_noacc>;
def CDE_VCX2A_vec   : CDE_VCX2_Vec_Instr<"vcx2a",  cde_vcx_params_q_acc>;

def CDE_VCX3_fpsp   : CDE_VCX3_FP_Instr_S<"vcx3",  cde_vcx_params_s_noacc>;
def CDE_VCX3A_fpsp  : CDE_VCX3_FP_Instr_S<"vcx3a", cde_vcx_params_s_acc>;
def CDE_VCX3_fpdp   : CDE_VCX3_FP_Instr_D<"vcx3",  cde_vcx_params_d_noacc>;
def CDE_VCX3A_fpdp  : CDE_VCX3_FP_Instr_D<"vcx3a", cde_vcx_params_d_acc>;
def CDE_VCX3_vec    : CDE_VCX3_Vec_Instr<"vcx3",   cde_vcx_params_q_noacc>;
def CDE_VCX3A_vec   : CDE_VCX3_Vec_Instr<"vcx3a",  cde_vcx_params_q_acc>;
