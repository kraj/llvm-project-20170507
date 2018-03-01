; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt < %s -instcombine -S | FileCheck %s

; testing-case "float fold(float a) { return 1.2f * a * 2.3f; }"
; 1.2f and 2.3f is supposed to be fold.
define float @fold(float %a) {
; CHECK-LABEL: @fold(
; CHECK-NEXT:    [[MUL1:%.*]] = fmul fast float [[A:%.*]], 0x4006147AE0000000
; CHECK-NEXT:    ret float [[MUL1]]
;
  %mul = fmul fast float %a, 0x3FF3333340000000
  %mul1 = fmul fast float %mul, 0x4002666660000000
  ret float %mul1
}

; Same testing-case as the one used in fold() except that the operators have
; fixed FP mode.
define float @notfold(float %a) {
; CHECK-LABEL: @notfold(
; CHECK-NEXT:    [[MUL:%.*]] = fmul fast float [[A:%.*]], 0x3FF3333340000000
; CHECK-NEXT:    [[MUL1:%.*]] = fmul float [[MUL]], 0x4002666660000000
; CHECK-NEXT:    ret float [[MUL1]]
;
  %mul = fmul fast float %a, 0x3FF3333340000000
  %mul1 = fmul float %mul, 0x4002666660000000
  ret float %mul1
}

define float @fold2(float %a) {
; CHECK-LABEL: @fold2(
; CHECK-NEXT:    [[MUL1:%.*]] = fmul fast float [[A:%.*]], 0x4006147AE0000000
; CHECK-NEXT:    ret float [[MUL1]]
;
  %mul = fmul float %a, 0x3FF3333340000000
  %mul1 = fmul fast float %mul, 0x4002666660000000
  ret float %mul1
}

; C * f1 + f1 = (C+1) * f1
define double @fold3(double %f1) {
; CHECK-LABEL: @fold3(
; CHECK-NEXT:    [[TMP1:%.*]] = fmul fast double [[F1:%.*]], 3.000000e+00
; CHECK-NEXT:    ret double [[TMP1]]
;
  %t1 = fmul fast double 2.000000e+00, %f1
  %t2 = fadd fast double %f1, %t1
  ret double %t2
}

; (C1 - X) + (C2 - Y) => (C1+C2) - (X + Y)
define float @fold4(float %f1, float %f2) {
; CHECK-LABEL: @fold4(
; CHECK-NEXT:    [[TMP1:%.*]] = fadd fast float [[F1:%.*]], [[F2:%.*]]
; CHECK-NEXT:    [[TMP2:%.*]] = fsub fast float 9.000000e+00, [[TMP1]]
; CHECK-NEXT:    ret float [[TMP2]]
;
  %sub = fsub float 4.000000e+00, %f1
  %sub1 = fsub float 5.000000e+00, %f2
  %add = fadd fast float %sub, %sub1
  ret float %add
}

; (X + C1) + C2 => X + (C1 + C2)
define float @fold5(float %f1, float %f2) {
; CHECK-LABEL: @fold5(
; CHECK-NEXT:    [[ADD1:%.*]] = fadd fast float [[F1:%.*]], 9.000000e+00
; CHECK-NEXT:    ret float [[ADD1]]
;
  %add = fadd float %f1, 4.000000e+00
  %add1 = fadd fast float %add, 5.000000e+00
  ret float %add1
}

; (X + X) + X => 3.0 * X
define float @fold6(float %f1) {
; CHECK-LABEL: @fold6(
; CHECK-NEXT:    [[TMP1:%.*]] = fmul fast float [[F1:%.*]], 3.000000e+00
; CHECK-NEXT:    ret float [[TMP1]]
;
  %t1 = fadd fast float %f1, %f1
  %t2 = fadd fast float %f1, %t1
  ret float %t2
}

; C1 * X + (X + X) = (C1 + 2) * X
define float @fold7(float %f1) {
; CHECK-LABEL: @fold7(
; CHECK-NEXT:    [[TMP1:%.*]] = fmul fast float [[F1:%.*]], 7.000000e+00
; CHECK-NEXT:    ret float [[TMP1]]
;
  %t1 = fmul fast float %f1, 5.000000e+00
  %t2 = fadd fast float %f1, %f1
  %t3 = fadd fast float %t1, %t2
  ret float %t3
}

; (X + X) + (X + X) => 4.0 * X
define float @fold8(float %f1) {
; CHECK-LABEL: @fold8(
; CHECK-NEXT:    [[TMP1:%.*]] = fmul fast float [[F1:%.*]], 4.000000e+00
; CHECK-NEXT:    ret float [[TMP1]]
;
  %t1 = fadd fast float %f1, %f1
  %t2 = fadd fast float %f1, %f1
  %t3 = fadd fast float %t1, %t2
  ret float %t3
}

; X - (X + Y) => 0 - Y
define float @fold9(float %f1, float %f2) {
; CHECK-LABEL: @fold9(
; CHECK-NEXT:    [[TMP1:%.*]] = fsub fast float -0.000000e+00, [[F2:%.*]]
; CHECK-NEXT:    ret float [[TMP1]]
;
  %t1 = fadd float %f1, %f2
  %t3 = fsub fast float %f1, %t1
  ret float %t3
}

; Let C3 = C1 + C2. (f1 + C1) + (f2 + C2) => (f1 + f2) + C3 instead of
; "(f1 + C3) + f2" or "(f2 + C3) + f1". Placing constant-addend at the
; top of resulting simplified expression tree may potentially reveal some
; optimization opportunities in the super-expression trees.
;
define float @fold10(float %f1, float %f2) {
; CHECK-LABEL: @fold10(
; CHECK-NEXT:    [[T2:%.*]] = fadd fast float [[F1:%.*]], [[F2:%.*]]
; CHECK-NEXT:    [[T3:%.*]] = fadd fast float [[T2]], -1.000000e+00
; CHECK-NEXT:    ret float [[T3]]
;
  %t1 = fadd fast float 2.000000e+00, %f1
  %t2 = fsub fast float %f2, 3.000000e+00
  %t3 = fadd fast float %t1, %t2
  ret float %t3
}

; once cause Crash/miscompilation
define float @fail1(float %f1, float %f2) {
; CHECK-LABEL: @fail1(
; CHECK-NEXT:    [[CONV3:%.*]] = fadd fast float [[F1:%.*]], -1.000000e+00
; CHECK-NEXT:    [[TMP1:%.*]] = fmul fast float [[CONV3]], 3.000000e+00
; CHECK-NEXT:    ret float [[TMP1]]
;
  %conv3 = fadd fast float %f1, -1.000000e+00
  %add = fadd fast float %conv3, %conv3
  %add2 = fadd fast float %add, %conv3
  ret float %add2
}

define double @fail2(double %f1, double %f2) {
; CHECK-LABEL: @fail2(
; CHECK-NEXT:    [[TMP1:%.*]] = fadd fast double [[F2:%.*]], [[F2]]
; CHECK-NEXT:    [[TMP2:%.*]] = fsub fast double -0.000000e+00, [[TMP1]]
; CHECK-NEXT:    ret double [[TMP2]]
;
  %t1 = fsub fast double %f1, %f2
  %t2 = fadd fast double %f1, %f2
  %t3 = fsub fast double %t1, %t2
  ret double %t3
}

; c1 * x - x => (c1 - 1.0) * x
define float @fold13(float %x) {
; CHECK-LABEL: @fold13(
; CHECK-NEXT:    [[TMP1:%.*]] = fmul fast float [[X:%.*]], 6.000000e+00
; CHECK-NEXT:    ret float [[TMP1]]
;
  %mul = fmul fast float %x, 7.000000e+00
  %sub = fsub fast float %mul, %x
  ret float %sub
}

; -x + y => y - x
define float @fold14(float %x, float %y) {
; CHECK-LABEL: @fold14(
; CHECK-NEXT:    [[ADD:%.*]] = fsub fast float [[Y:%.*]], [[X:%.*]]
; CHECK-NEXT:    ret float [[ADD]]
;
  %neg = fsub fast float -0.0, %x
  %add = fadd fast float %neg, %y
  ret float %add
}

; x + -y => x - y
define float @fold15(float %x, float %y) {
; CHECK-LABEL: @fold15(
; CHECK-NEXT:    [[ADD:%.*]] = fsub fast float [[X:%.*]], [[Y:%.*]]
; CHECK-NEXT:    ret float [[ADD]]
;
  %neg = fsub fast float -0.0, %y
  %add = fadd fast float %x, %neg
  ret float %add
}

; (select X+Y, X-Y) => X + (select Y, -Y)
define float @fold16(float %x, float %y) {
; CHECK-LABEL: @fold16(
; CHECK-NEXT:    [[CMP:%.*]] = fcmp ogt float [[X:%.*]], [[Y:%.*]]
; CHECK-NEXT:    [[TMP1:%.*]] = fsub fast float -0.000000e+00, [[Y]]
; CHECK-NEXT:    [[R_P:%.*]] = select i1 [[CMP]], float [[Y]], float [[TMP1]]
; CHECK-NEXT:    [[R:%.*]] = fadd fast float [[R_P]], [[X]]
; CHECK-NEXT:    ret float [[R]]
;
  %cmp = fcmp ogt float %x, %y
  %plus = fadd fast float %x, %y
  %minus = fsub fast float %x, %y
  %r = select i1 %cmp, float %plus, float %minus
  ret float %r
}


; =========================================================================
;
;   Testing-cases about fmul begin
;
; =========================================================================

; ((X*C1) + C2) * C3 => (X * (C1*C3)) + (C2*C3) (i.e. distribution)
define float @fmul_distribute1(float %f1) {
; CHECK-LABEL: @fmul_distribute1(
; CHECK-NEXT:    [[TMP1:%.*]] = fmul fast float [[F1:%.*]], 3.000000e+07
; CHECK-NEXT:    [[T3:%.*]] = fadd fast float [[TMP1]], 1.000000e+07
; CHECK-NEXT:    ret float [[T3]]
;
  %t1 = fmul float %f1, 6.0e+3
  %t2 = fadd float %t1, 2.0e+3
  %t3 = fmul fast float %t2, 5.0e+3
  ret float %t3
}

; (X/C1 + C2) * C3 => X/(C1/C3) + C2*C3
; TODO: We don't convert the fast fdiv to fmul because that would be multiplication
; by a denormal, but we could do better when we know that denormals are not a problem.

define double @fmul_distribute2(double %f1, double %f2) {
; CHECK-LABEL: @fmul_distribute2(
; CHECK-NEXT:    [[TMP1:%.*]] = fdiv fast double [[F1:%.*]], 0x7FE8000000000000
; CHECK-NEXT:    [[T3:%.*]] = fadd fast double [[TMP1]], 0x69000000000000
; CHECK-NEXT:    ret double [[T3]]
;
  %t1 = fdiv double %f1, 3.0e+0
  %t2 = fadd double %t1, 5.0e+1
  ; 0x10000000000000 = DBL_MIN
  %t3 = fmul fast double %t2, 0x10000000000000
  ret double %t3
}

; 5.0e-1 * DBL_MIN yields denormal, so "(f1*3.0 + 5.0e-1) * DBL_MIN" cannot
; be simplified into f1 * (3.0*DBL_MIN) + (5.0e-1*DBL_MIN)
define double @fmul_distribute3(double %f1) {
; CHECK-LABEL: @fmul_distribute3(
; CHECK-NEXT:    [[T1:%.*]] = fdiv double [[F1:%.*]], 3.000000e+00
; CHECK-NEXT:    [[T2:%.*]] = fadd double [[T1]], 5.000000e-01
; CHECK-NEXT:    [[T3:%.*]] = fmul fast double [[T2]], 0x10000000000000
; CHECK-NEXT:    ret double [[T3]]
;
  %t1 = fdiv double %f1, 3.0e+0
  %t2 = fadd double %t1, 5.0e-1
  %t3 = fmul fast double %t2, 0x10000000000000
  ret double %t3
}

; ((X*C1) + C2) * C3 => (X * (C1*C3)) + (C2*C3) (i.e. distribution)
define float @fmul_distribute4(float %f1) {
; CHECK-LABEL: @fmul_distribute4(
; CHECK-NEXT:    [[TMP1:%.*]] = fmul fast float [[F1:%.*]], 3.000000e+07
; CHECK-NEXT:    [[T3:%.*]] = fsub fast float 1.000000e+07, [[TMP1]]
; CHECK-NEXT:    ret float [[T3]]
;
  %t1 = fmul float %f1, 6.0e+3
  %t2 = fsub float 2.0e+3, %t1
  %t3 = fmul fast float %t2, 5.0e+3
  ret float %t3
}

; C1/X * C2 => (C1*C2) / X
define float @fmul2(float %f1) {
; CHECK-LABEL: @fmul2(
; CHECK-NEXT:    [[TMP1:%.*]] = fdiv fast float 1.200000e+07, [[F1:%.*]]
; CHECK-NEXT:    ret float [[TMP1]]
;
  %t1 = fdiv float 2.0e+3, %f1
  %t3 = fmul fast float %t1, 6.0e+3
  ret float %t3
}

; X/C1 * C2 => X * (C2/C1) is disabled if X/C1 has multiple uses
@fmul2_external = external global float
define float @fmul2_disable(float %f1) {
; CHECK-LABEL: @fmul2_disable(
; CHECK-NEXT:    [[DIV:%.*]] = fdiv fast float 1.000000e+00, [[F1:%.*]]
; CHECK-NEXT:    store float [[DIV]], float* @fmul2_external, align 4
; CHECK-NEXT:    [[MUL:%.*]] = fmul fast float [[DIV]], 2.000000e+00
; CHECK-NEXT:    ret float [[MUL]]
;
  %div = fdiv fast float 1.000000e+00, %f1
  store float %div, float* @fmul2_external
  %mul = fmul fast float %div, 2.000000e+00
  ret float %mul
}

; X/C1 * C2 => X * (C2/C1) (if C2/C1 is normal Fp)
define float @fmul3(float %f1, float %f2) {
; CHECK-LABEL: @fmul3(
; CHECK-NEXT:    [[TMP1:%.*]] = fmul fast float [[F1:%.*]], 3.000000e+00
; CHECK-NEXT:    ret float [[TMP1]]
;
  %t1 = fdiv float %f1, 2.0e+3
  %t3 = fmul fast float %t1, 6.0e+3
  ret float %t3
}

define <4 x float> @fmul3_vec(<4 x float> %f1, <4 x float> %f2) {
; CHECK-LABEL: @fmul3_vec(
; CHECK-NEXT:    [[TMP1:%.*]] = fmul fast <4 x float> [[F1:%.*]], <float 3.000000e+00, float 2.000000e+00, float 1.000000e+00, float 1.000000e+00>
; CHECK-NEXT:    ret <4 x float> [[TMP1]]
;
  %t1 = fdiv <4 x float> %f1, <float 2.0e+3, float 3.0e+3, float 2.0e+3, float 1.0e+3>
  %t3 = fmul fast <4 x float> %t1, <float 6.0e+3, float 6.0e+3, float 2.0e+3, float 1.0e+3>
  ret <4 x float> %t3
}

; Make sure fmul with constant expression doesn't assert.
define <4 x float> @fmul3_vec_constexpr(<4 x float> %f1, <4 x float> %f2) {
; CHECK-LABEL: @fmul3_vec_constexpr(
; CHECK-NEXT:    [[TMP1:%.*]] = fmul fast <4 x float> [[F1:%.*]], <float 3.000000e+00, float 2.000000e+00, float 1.000000e+00, float 1.000000e+00>
; CHECK-NEXT:    ret <4 x float> [[TMP1]]
;
  %constExprMul = bitcast i128 trunc (i160 bitcast (<5 x float> <float 6.0e+3, float 6.0e+3, float 2.0e+3, float 1.0e+3, float undef> to i160) to i128) to <4 x float>
  %t1 = fdiv <4 x float> %f1, <float 2.0e+3, float 3.0e+3, float 2.0e+3, float 1.0e+3>
  %t3 = fmul fast <4 x float> %t1, %constExprMul
  ret <4 x float> %t3
}

; Rule "X/C1 * C2 => X * (C2/C1) is not applicable if C2/C1 is either a special
; value of a denormal. The 0x3810000000000000 here take value FLT_MIN
;
define float @fmul4(float %f1, float %f2) {
; CHECK-LABEL: @fmul4(
; CHECK-NEXT:    [[T1:%.*]] = fdiv float [[F1:%.*]], 2.000000e+03
; CHECK-NEXT:    [[T3:%.*]] = fmul fast float [[T1]], 0x3810000000000000
; CHECK-NEXT:    ret float [[T3]]
;
  %t1 = fdiv float %f1, 2.0e+3
  %t3 = fmul fast float %t1, 0x3810000000000000
  ret float %t3
}

; X / C1 * C2 => X / (C2/C1) if  C1/C2 is either a special value of a denormal,
;  and C2/C1 is a normal value.
; TODO: We don't convert the fast fdiv to fmul because that would be multiplication
; by a denormal, but we could do better when we know that denormals are not a problem.

define float @fmul5(float %f1, float %f2) {
; CHECK-LABEL: @fmul5(
; CHECK-NEXT:    [[TMP1:%.*]] = fdiv fast float [[F1:%.*]], 0x47E8000000000000
; CHECK-NEXT:    ret float [[TMP1]]
;
  %t1 = fdiv float %f1, 3.0e+0
  %t3 = fmul fast float %t1, 0x3810000000000000
  ret float %t3
}

; "(X*Y) * X => (X*X) * Y" is disabled if "X*Y" has multiple uses
define float @fmul7(float %f1, float %f2) {
; CHECK-LABEL: @fmul7(
; CHECK-NEXT:    [[MUL:%.*]] = fmul float [[F1:%.*]], [[F2:%.*]]
; CHECK-NEXT:    [[MUL1:%.*]] = fmul fast float [[MUL]], [[F1]]
; CHECK-NEXT:    [[ADD:%.*]] = fadd float [[MUL1]], [[MUL]]
; CHECK-NEXT:    ret float [[ADD]]
;
  %mul = fmul float %f1, %f2
  %mul1 = fmul fast float %mul, %f1
  %add = fadd float %mul1, %mul
  ret float %add
}

; =========================================================================
;
;   Testing-cases about negation
;
; =========================================================================
define float @fneg1(float %f1, float %f2) {
; CHECK-LABEL: @fneg1(
; CHECK-NEXT:    [[MUL:%.*]] = fmul float [[F1:%.*]], [[F2:%.*]]
; CHECK-NEXT:    ret float [[MUL]]
;
  %sub = fsub float -0.000000e+00, %f1
  %sub1 = fsub nsz float 0.000000e+00, %f2
  %mul = fmul float %sub, %sub1
  ret float %mul
}

define float @fneg2(float %x) {
; CHECK-LABEL: @fneg2(
; CHECK-NEXT:    [[SUB:%.*]] = fsub nsz float -0.000000e+00, [[X:%.*]]
; CHECK-NEXT:    ret float [[SUB]]
;
  %sub = fsub nsz float 0.0, %x
  ret float %sub
}

; =========================================================================
;
;   Testing-cases about div
;
; =========================================================================

; X/C1 / C2 => X * (1/(C2*C1))
define float @fdiv1(float %x) {
; CHECK-LABEL: @fdiv1(
; CHECK-NEXT:    [[DIV1:%.*]] = fmul fast float [[X:%.*]], 0x3FD7303B60000000
; CHECK-NEXT:    ret float [[DIV1]]
;
  %div = fdiv float %x, 0x3FF3333340000000
  %div1 = fdiv fast float %div, 0x4002666660000000
  ret float %div1
; 0x3FF3333340000000 = 1.2f
; 0x4002666660000000 = 2.3f
; 0x3FD7303B60000000 = 0.36231884057971014492
}

; X*C1 / C2 => X * (C1/C2)
define float @fdiv2(float %x) {
; CHECK-LABEL: @fdiv2(
; CHECK-NEXT:    [[DIV1:%.*]] = fmul fast float [[X:%.*]], 0x3FE0B21660000000
; CHECK-NEXT:    ret float [[DIV1]]
;
  %mul = fmul float %x, 0x3FF3333340000000
  %div1 = fdiv fast float %mul, 0x4002666660000000
  ret float %div1

; 0x3FF3333340000000 = 1.2f
; 0x4002666660000000 = 2.3f
; 0x3FE0B21660000000 = 0.52173918485641479492
}

define <2 x float> @fdiv2_vec(<2 x float> %x) {
; CHECK-LABEL: @fdiv2_vec(
; CHECK-NEXT:    [[DIV1:%.*]] = fmul fast <2 x float> [[X:%.*]], <float 3.000000e+00, float 3.000000e+00>
; CHECK-NEXT:    ret <2 x float> [[DIV1]]
;
  %mul = fmul <2 x float> %x, <float 6.0, float 9.0>
  %div1 = fdiv fast <2 x float> %mul, <float 2.0, float 3.0>
  ret <2 x float> %div1
}

; "X/C1 / C2 => X * (1/(C2*C1))" is disabled (for now) is C2/C1 is a denormal
;
define float @fdiv3(float %x) {
; CHECK-LABEL: @fdiv3(
; CHECK-NEXT:    [[DIV:%.*]] = fdiv float [[X:%.*]], 0x47EFFFFFE0000000
; CHECK-NEXT:    [[DIV1:%.*]] = fmul fast float [[DIV]], 0x3FDBD37A80000000
; CHECK-NEXT:    ret float [[DIV1]]
;
  %div = fdiv float %x, 0x47EFFFFFE0000000
  %div1 = fdiv fast float %div, 0x4002666660000000
  ret float %div1
}

; "X*C1 / C2 => X * (C1/C2)" is disabled if C1/C2 is a denormal
define float @fdiv4(float %x) {
; CHECK-LABEL: @fdiv4(
; CHECK-NEXT:    [[MUL:%.*]] = fmul float [[X:%.*]], 0x47EFFFFFE0000000
; CHECK-NEXT:    [[DIV:%.*]] = fdiv float [[MUL]], 0x3FC99999A0000000
; CHECK-NEXT:    ret float [[DIV]]
;
  %mul = fmul float %x, 0x47EFFFFFE0000000
  %div = fdiv float %mul, 0x3FC99999A0000000
  ret float %div
}

; =========================================================================
;
;   Testing-cases about factorization
;
; =========================================================================
; x*z + y*z => (x+y) * z
define float @fact_mul1(float %x, float %y, float %z) {
; CHECK-LABEL: @fact_mul1(
; CHECK-NEXT:    [[TMP1:%.*]] = fadd fast float [[X:%.*]], [[Y:%.*]]
; CHECK-NEXT:    [[TMP2:%.*]] = fmul fast float [[TMP1]], [[Z:%.*]]
; CHECK-NEXT:    ret float [[TMP2]]
;
  %t1 = fmul fast float %x, %z
  %t2 = fmul fast float %y, %z
  %t3 = fadd fast float %t1, %t2
  ret float %t3
}

; z*x + y*z => (x+y) * z
define float @fact_mul2(float %x, float %y, float %z) {
; CHECK-LABEL: @fact_mul2(
; CHECK-NEXT:    [[TMP1:%.*]] = fsub fast float [[X:%.*]], [[Y:%.*]]
; CHECK-NEXT:    [[TMP2:%.*]] = fmul fast float [[TMP1]], [[Z:%.*]]
; CHECK-NEXT:    ret float [[TMP2]]
;
  %t1 = fmul fast float %z, %x
  %t2 = fmul fast float %y, %z
  %t3 = fsub fast float %t1, %t2
  ret float %t3
}

; z*x - z*y => (x-y) * z
define float @fact_mul3(float %x, float %y, float %z) {
; CHECK-LABEL: @fact_mul3(
; CHECK-NEXT:    [[TMP1:%.*]] = fsub fast float [[X:%.*]], [[Y:%.*]]
; CHECK-NEXT:    [[TMP2:%.*]] = fmul fast float [[TMP1]], [[Z:%.*]]
; CHECK-NEXT:    ret float [[TMP2]]
;
  %t2 = fmul fast float %z, %y
  %t1 = fmul fast float %z, %x
  %t3 = fsub fast float %t1, %t2
  ret float %t3
}

; x*z - z*y => (x-y) * z
define float @fact_mul4(float %x, float %y, float %z) {
; CHECK-LABEL: @fact_mul4(
; CHECK-NEXT:    [[TMP1:%.*]] = fsub fast float [[X:%.*]], [[Y:%.*]]
; CHECK-NEXT:    [[TMP2:%.*]] = fmul fast float [[TMP1]], [[Z:%.*]]
; CHECK-NEXT:    ret float [[TMP2]]
;
  %t1 = fmul fast float %x, %z
  %t2 = fmul fast float %z, %y
  %t3 = fsub fast float %t1, %t2
  ret float %t3
}

; x/y + x/z, no xform
define float @fact_div1(float %x, float %y, float %z) {
; CHECK-LABEL: @fact_div1(
; CHECK-NEXT:    [[T1:%.*]] = fdiv fast float [[X:%.*]], [[Y:%.*]]
; CHECK-NEXT:    [[T2:%.*]] = fdiv fast float [[X]], [[Z:%.*]]
; CHECK-NEXT:    [[T3:%.*]] = fadd fast float [[T1]], [[T2]]
; CHECK-NEXT:    ret float [[T3]]
;
  %t1 = fdiv fast float %x, %y
  %t2 = fdiv fast float %x, %z
  %t3 = fadd fast float %t1, %t2
  ret float %t3
}

; x/y + z/x; no xform
define float @fact_div2(float %x, float %y, float %z) {
; CHECK-LABEL: @fact_div2(
; CHECK-NEXT:    [[T1:%.*]] = fdiv fast float [[X:%.*]], [[Y:%.*]]
; CHECK-NEXT:    [[T2:%.*]] = fdiv fast float [[Z:%.*]], [[X]]
; CHECK-NEXT:    [[T3:%.*]] = fadd fast float [[T1]], [[T2]]
; CHECK-NEXT:    ret float [[T3]]
;
  %t1 = fdiv fast float %x, %y
  %t2 = fdiv fast float %z, %x
  %t3 = fadd fast float %t1, %t2
  ret float %t3
}

; y/x + z/x => (y+z)/x
define float @fact_div3(float %x, float %y, float %z) {
; CHECK-LABEL: @fact_div3(
; CHECK-NEXT:    [[TMP1:%.*]] = fadd fast float [[Y:%.*]], [[Z:%.*]]
; CHECK-NEXT:    [[TMP2:%.*]] = fdiv fast float [[TMP1]], [[X:%.*]]
; CHECK-NEXT:    ret float [[TMP2]]
;
  %t1 = fdiv fast float %y, %x
  %t2 = fdiv fast float %z, %x
  %t3 = fadd fast float %t1, %t2
  ret float %t3
}

; y/x - z/x => (y-z)/x
define float @fact_div4(float %x, float %y, float %z) {
; CHECK-LABEL: @fact_div4(
; CHECK-NEXT:    [[TMP1:%.*]] = fsub fast float [[Y:%.*]], [[Z:%.*]]
; CHECK-NEXT:    [[TMP2:%.*]] = fdiv fast float [[TMP1]], [[X:%.*]]
; CHECK-NEXT:    ret float [[TMP2]]
;
  %t1 = fdiv fast float %y, %x
  %t2 = fdiv fast float %z, %x
  %t3 = fsub fast float %t1, %t2
  ret float %t3
}

; y/x - z/x => (y-z)/x is disabled if y-z is denormal.
define float @fact_div5(float %x) {
; CHECK-LABEL: @fact_div5(
; CHECK-NEXT:    [[TMP1:%.*]] = fdiv fast float 0x3818000000000000, [[X:%.*]]
; CHECK-NEXT:    ret float [[TMP1]]
;
  %t1 = fdiv fast float 0x3810000000000000, %x
  %t2 = fdiv fast float 0x3800000000000000, %x
  %t3 = fadd fast float %t1, %t2
  ret float %t3
}

; y/x - z/x => (y-z)/x is disabled if y-z is denormal.
define float @fact_div6(float %x) {
; CHECK-LABEL: @fact_div6(
; CHECK-NEXT:    [[T1:%.*]] = fdiv fast float 0x3810000000000000, [[X:%.*]]
; CHECK-NEXT:    [[T2:%.*]] = fdiv fast float 0x3800000000000000, [[X]]
; CHECK-NEXT:    [[T3:%.*]] = fsub fast float [[T1]], [[T2]]
; CHECK-NEXT:    ret float [[T3]]
;
  %t1 = fdiv fast float 0x3810000000000000, %x
  %t2 = fdiv fast float 0x3800000000000000, %x
  %t3 = fsub fast float %t1, %t2
  ret float %t3
}

; =========================================================================
;
;   Test-cases for square root
;
; =========================================================================

; A squared factor fed into a square root intrinsic should be hoisted out
; as a fabs() value.

declare double @llvm.sqrt.f64(double)

define double @sqrt_intrinsic_arg_squared(double %x) {
; CHECK-LABEL: @sqrt_intrinsic_arg_squared(
; CHECK-NEXT:    [[FABS:%.*]] = call fast double @llvm.fabs.f64(double [[X:%.*]])
; CHECK-NEXT:    ret double [[FABS]]
;
  %mul = fmul fast double %x, %x
  %sqrt = call fast double @llvm.sqrt.f64(double %mul)
  ret double %sqrt
}

; Check all 6 combinations of a 3-way multiplication tree where
; one factor is repeated.

define double @sqrt_intrinsic_three_args1(double %x, double %y) {
; CHECK-LABEL: @sqrt_intrinsic_three_args1(
; CHECK-NEXT:    [[FABS:%.*]] = call fast double @llvm.fabs.f64(double [[X:%.*]])
; CHECK-NEXT:    [[SQRT1:%.*]] = call fast double @llvm.sqrt.f64(double [[Y:%.*]])
; CHECK-NEXT:    [[TMP1:%.*]] = fmul fast double [[FABS]], [[SQRT1]]
; CHECK-NEXT:    ret double [[TMP1]]
;
  %mul = fmul fast double %y, %x
  %mul2 = fmul fast double %mul, %x
  %sqrt = call fast double @llvm.sqrt.f64(double %mul2)
  ret double %sqrt
}

define double @sqrt_intrinsic_three_args2(double %x, double %y) {
; CHECK-LABEL: @sqrt_intrinsic_three_args2(
; CHECK-NEXT:    [[FABS:%.*]] = call fast double @llvm.fabs.f64(double [[X:%.*]])
; CHECK-NEXT:    [[SQRT1:%.*]] = call fast double @llvm.sqrt.f64(double [[Y:%.*]])
; CHECK-NEXT:    [[TMP1:%.*]] = fmul fast double [[FABS]], [[SQRT1]]
; CHECK-NEXT:    ret double [[TMP1]]
;
  %mul = fmul fast double %x, %y
  %mul2 = fmul fast double %mul, %x
  %sqrt = call fast double @llvm.sqrt.f64(double %mul2)
  ret double %sqrt
}

define double @sqrt_intrinsic_three_args3(double %x, double %y) {
; CHECK-LABEL: @sqrt_intrinsic_three_args3(
; CHECK-NEXT:    [[FABS:%.*]] = call fast double @llvm.fabs.f64(double [[X:%.*]])
; CHECK-NEXT:    [[SQRT1:%.*]] = call fast double @llvm.sqrt.f64(double [[Y:%.*]])
; CHECK-NEXT:    [[TMP1:%.*]] = fmul fast double [[FABS]], [[SQRT1]]
; CHECK-NEXT:    ret double [[TMP1]]
;
  %mul = fmul fast double %x, %x
  %mul2 = fmul fast double %mul, %y
  %sqrt = call fast double @llvm.sqrt.f64(double %mul2)
  ret double %sqrt
}

define double @sqrt_intrinsic_three_args4(double %x, double %y) {
; CHECK-LABEL: @sqrt_intrinsic_three_args4(
; CHECK-NEXT:    [[FABS:%.*]] = call fast double @llvm.fabs.f64(double [[X:%.*]])
; CHECK-NEXT:    [[SQRT1:%.*]] = call fast double @llvm.sqrt.f64(double [[Y:%.*]])
; CHECK-NEXT:    [[TMP1:%.*]] = fmul fast double [[FABS]], [[SQRT1]]
; CHECK-NEXT:    ret double [[TMP1]]
;
  %mul = fmul fast double %y, %x
  %mul2 = fmul fast double %x, %mul
  %sqrt = call fast double @llvm.sqrt.f64(double %mul2)
  ret double %sqrt
}

define double @sqrt_intrinsic_three_args5(double %x, double %y) {
; CHECK-LABEL: @sqrt_intrinsic_three_args5(
; CHECK-NEXT:    [[FABS:%.*]] = call fast double @llvm.fabs.f64(double [[X:%.*]])
; CHECK-NEXT:    [[SQRT1:%.*]] = call fast double @llvm.sqrt.f64(double [[Y:%.*]])
; CHECK-NEXT:    [[TMP1:%.*]] = fmul fast double [[FABS]], [[SQRT1]]
; CHECK-NEXT:    ret double [[TMP1]]
;
  %mul = fmul fast double %x, %y
  %mul2 = fmul fast double %x, %mul
  %sqrt = call fast double @llvm.sqrt.f64(double %mul2)
  ret double %sqrt
}

define double @sqrt_intrinsic_three_args6(double %x, double %y) {
; CHECK-LABEL: @sqrt_intrinsic_three_args6(
; CHECK-NEXT:    [[FABS:%.*]] = call fast double @llvm.fabs.f64(double [[X:%.*]])
; CHECK-NEXT:    [[SQRT1:%.*]] = call fast double @llvm.sqrt.f64(double [[Y:%.*]])
; CHECK-NEXT:    [[TMP1:%.*]] = fmul fast double [[FABS]], [[SQRT1]]
; CHECK-NEXT:    ret double [[TMP1]]
;
  %mul = fmul fast double %x, %x
  %mul2 = fmul fast double %y, %mul
  %sqrt = call fast double @llvm.sqrt.f64(double %mul2)
  ret double %sqrt
}

; If any operation is not 'fast', we can't simplify.

define double @sqrt_intrinsic_not_so_fast(double %x, double %y) {
; CHECK-LABEL: @sqrt_intrinsic_not_so_fast(
; CHECK-NEXT:    [[MUL:%.*]] = fmul double [[X:%.*]], [[X]]
; CHECK-NEXT:    [[MUL2:%.*]] = fmul fast double [[MUL]], [[Y:%.*]]
; CHECK-NEXT:    [[SQRT:%.*]] = call fast double @llvm.sqrt.f64(double [[MUL2]])
; CHECK-NEXT:    ret double [[SQRT]]
;
  %mul = fmul double %x, %x
  %mul2 = fmul fast double %mul, %y
  %sqrt = call fast double @llvm.sqrt.f64(double %mul2)
  ret double %sqrt
}

define double @sqrt_intrinsic_arg_4th(double %x) {
; CHECK-LABEL: @sqrt_intrinsic_arg_4th(
; CHECK-NEXT:    [[MUL:%.*]] = fmul fast double [[X:%.*]], [[X]]
; CHECK-NEXT:    ret double [[MUL]]
;
  %mul = fmul fast double %x, %x
  %mul2 = fmul fast double %mul, %mul
  %sqrt = call fast double @llvm.sqrt.f64(double %mul2)
  ret double %sqrt
}

define double @sqrt_intrinsic_arg_5th(double %x) {
; CHECK-LABEL: @sqrt_intrinsic_arg_5th(
; CHECK-NEXT:    [[MUL:%.*]] = fmul fast double [[X:%.*]], [[X]]
; CHECK-NEXT:    [[SQRT1:%.*]] = call fast double @llvm.sqrt.f64(double [[X]])
; CHECK-NEXT:    [[TMP1:%.*]] = fmul fast double [[MUL]], [[SQRT1]]
; CHECK-NEXT:    ret double [[TMP1]]
;
  %mul = fmul fast double %x, %x
  %mul2 = fmul fast double %mul, %x
  %mul3 = fmul fast double %mul2, %mul
  %sqrt = call fast double @llvm.sqrt.f64(double %mul3)
  ret double %sqrt
}

; Check that square root calls have the same behavior.

declare float @sqrtf(float)
declare double @sqrt(double)
declare fp128 @sqrtl(fp128)

define float @sqrt_call_squared_f32(float %x) {
; CHECK-LABEL: @sqrt_call_squared_f32(
; CHECK-NEXT:    [[FABS:%.*]] = call fast float @llvm.fabs.f32(float [[X:%.*]])
; CHECK-NEXT:    ret float [[FABS]]
;
  %mul = fmul fast float %x, %x
  %sqrt = call fast float @sqrtf(float %mul)
  ret float %sqrt
}

define double @sqrt_call_squared_f64(double %x) {
; CHECK-LABEL: @sqrt_call_squared_f64(
; CHECK-NEXT:    [[FABS:%.*]] = call fast double @llvm.fabs.f64(double [[X:%.*]])
; CHECK-NEXT:    ret double [[FABS]]
;
  %mul = fmul fast double %x, %x
  %sqrt = call fast double @sqrt(double %mul)
  ret double %sqrt
}

define fp128 @sqrt_call_squared_f128(fp128 %x) {
; CHECK-LABEL: @sqrt_call_squared_f128(
; CHECK-NEXT:    [[FABS:%.*]] = call fast fp128 @llvm.fabs.f128(fp128 [[X:%.*]])
; CHECK-NEXT:    ret fp128 [[FABS]]
;
  %mul = fmul fast fp128 %x, %x
  %sqrt = call fast fp128 @sqrtl(fp128 %mul)
  ret fp128 %sqrt
}

; =========================================================================
;
;   Test-cases for fmin / fmax
;
; =========================================================================

declare double @fmax(double, double)
declare double @fmin(double, double)
declare float @fmaxf(float, float)
declare float @fminf(float, float)
declare fp128 @fmaxl(fp128, fp128)
declare fp128 @fminl(fp128, fp128)

; No NaNs is the minimum requirement to replace these calls.
; This should always be set when unsafe-fp-math is true, but
; alternate the attributes for additional test coverage.
; 'nsz' is implied by the definition of fmax or fmin itself.

; Shrink and remove the call.
define float @max1(float %a, float %b) {
; CHECK-LABEL: @max1(
; CHECK-NEXT:    [[TMP1:%.*]] = fcmp fast ogt float [[A:%.*]], [[B:%.*]]
; CHECK-NEXT:    [[TMP2:%.*]] = select i1 [[TMP1]], float [[A]], float [[B]]
; CHECK-NEXT:    ret float [[TMP2]]
;
  %c = fpext float %a to double
  %d = fpext float %b to double
  %e = call fast double @fmax(double %c, double %d)
  %f = fptrunc double %e to float
  ret float %f
}

define float @max2(float %a, float %b) {
; CHECK-LABEL: @max2(
; CHECK-NEXT:    [[TMP1:%.*]] = fcmp nnan nsz ogt float [[A:%.*]], [[B:%.*]]
; CHECK-NEXT:    [[TMP2:%.*]] = select i1 [[TMP1]], float [[A]], float [[B]]
; CHECK-NEXT:    ret float [[TMP2]]
;
  %c = call nnan float @fmaxf(float %a, float %b)
  ret float %c
}


define double @max3(double %a, double %b) {
; CHECK-LABEL: @max3(
; CHECK-NEXT:    [[TMP1:%.*]] = fcmp fast ogt double [[A:%.*]], [[B:%.*]]
; CHECK-NEXT:    [[TMP2:%.*]] = select i1 [[TMP1]], double [[A]], double [[B]]
; CHECK-NEXT:    ret double [[TMP2]]
;
  %c = call fast double @fmax(double %a, double %b)
  ret double %c
}

define fp128 @max4(fp128 %a, fp128 %b) {
; CHECK-LABEL: @max4(
; CHECK-NEXT:    [[TMP1:%.*]] = fcmp nnan nsz ogt fp128 [[A:%.*]], [[B:%.*]]
; CHECK-NEXT:    [[TMP2:%.*]] = select i1 [[TMP1]], fp128 [[A]], fp128 [[B]]
; CHECK-NEXT:    ret fp128 [[TMP2]]
;
  %c = call nnan fp128 @fmaxl(fp128 %a, fp128 %b)
  ret fp128 %c
}

; Shrink and remove the call.
define float @min1(float %a, float %b) {
; CHECK-LABEL: @min1(
; CHECK-NEXT:    [[TMP1:%.*]] = fcmp nnan nsz olt float [[A:%.*]], [[B:%.*]]
; CHECK-NEXT:    [[TMP2:%.*]] = select i1 [[TMP1]], float [[A]], float [[B]]
; CHECK-NEXT:    ret float [[TMP2]]
;
  %c = fpext float %a to double
  %d = fpext float %b to double
  %e = call nnan double @fmin(double %c, double %d)
  %f = fptrunc double %e to float
  ret float %f
}

define float @min2(float %a, float %b) {
; CHECK-LABEL: @min2(
; CHECK-NEXT:    [[TMP1:%.*]] = fcmp fast olt float [[A:%.*]], [[B:%.*]]
; CHECK-NEXT:    [[TMP2:%.*]] = select i1 [[TMP1]], float [[A]], float [[B]]
; CHECK-NEXT:    ret float [[TMP2]]
;
  %c = call fast float @fminf(float %a, float %b)
  ret float %c
}

define double @min3(double %a, double %b) {
; CHECK-LABEL: @min3(
; CHECK-NEXT:    [[TMP1:%.*]] = fcmp nnan nsz olt double [[A:%.*]], [[B:%.*]]
; CHECK-NEXT:    [[TMP2:%.*]] = select i1 [[TMP1]], double [[A]], double [[B]]
; CHECK-NEXT:    ret double [[TMP2]]
;
  %c = call nnan double @fmin(double %a, double %b)
  ret double %c
}

define fp128 @min4(fp128 %a, fp128 %b) {
; CHECK-LABEL: @min4(
; CHECK-NEXT:    [[TMP1:%.*]] = fcmp fast olt fp128 [[A:%.*]], [[B:%.*]]
; CHECK-NEXT:    [[TMP2:%.*]] = select i1 [[TMP1]], fp128 [[A]], fp128 [[B]]
; CHECK-NEXT:    ret fp128 [[TMP2]]
;
  %c = call fast fp128 @fminl(fp128 %a, fp128 %b)
  ret fp128 %c
}

define float @test55(i1 %which, float %a) {
; CHECK-LABEL: @test55(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br i1 [[WHICH:%.*]], label [[FINAL:%.*]], label [[DELAY:%.*]]
; CHECK:       delay:
; CHECK-NEXT:    [[PHITMP:%.*]] = fadd fast float [[A:%.*]], 1.000000e+00
; CHECK-NEXT:    br label [[FINAL]]
; CHECK:       final:
; CHECK-NEXT:    [[A:%.*]] = phi float [ 3.000000e+00, [[ENTRY:%.*]] ], [ [[PHITMP]], [[DELAY]] ]
; CHECK-NEXT:    ret float [[A]]
;
entry:
  br i1 %which, label %final, label %delay

delay:
  br label %final

final:
  %A = phi float [ 2.0, %entry ], [ %a, %delay ]
  %value = fadd fast float %A, 1.0
  ret float %value
}

