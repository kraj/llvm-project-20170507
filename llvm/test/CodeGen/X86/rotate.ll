; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=i686-unknown-linux | FileCheck %s --check-prefixes=X86
; RUN: llc < %s -mtriple=x86_64-unknown-linux | FileCheck %s --check-prefixes=X64

define i64 @rotl64(i64 %A, i8 %Amt) nounwind {
; X86-LABEL: rotl64:
; X86:       # %bb.0:
; X86-NEXT:    pushl %ebx
; X86-NEXT:    pushl %edi
; X86-NEXT:    pushl %esi
; X86-NEXT:    movb {{[0-9]+}}(%esp), %cl
; X86-NEXT:    movl {{[0-9]+}}(%esp), %esi
; X86-NEXT:    movl {{[0-9]+}}(%esp), %edi
; X86-NEXT:    movl %esi, %eax
; X86-NEXT:    shll %cl, %eax
; X86-NEXT:    movl %edi, %edx
; X86-NEXT:    shldl %cl, %esi, %edx
; X86-NEXT:    testb $32, %cl
; X86-NEXT:    je .LBB0_2
; X86-NEXT:  # %bb.1:
; X86-NEXT:    movl %eax, %edx
; X86-NEXT:    xorl %eax, %eax
; X86-NEXT:  .LBB0_2:
; X86-NEXT:    movb $64, %ch
; X86-NEXT:    subb %cl, %ch
; X86-NEXT:    movl %edi, %ebx
; X86-NEXT:    movb %ch, %cl
; X86-NEXT:    shrl %cl, %ebx
; X86-NEXT:    shrdl %cl, %edi, %esi
; X86-NEXT:    testb $32, %ch
; X86-NEXT:    je .LBB0_4
; X86-NEXT:  # %bb.3:
; X86-NEXT:    movl %ebx, %esi
; X86-NEXT:    xorl %ebx, %ebx
; X86-NEXT:  .LBB0_4:
; X86-NEXT:    orl %ebx, %edx
; X86-NEXT:    orl %esi, %eax
; X86-NEXT:    popl %esi
; X86-NEXT:    popl %edi
; X86-NEXT:    popl %ebx
; X86-NEXT:    retl
;
; X64-LABEL: rotl64:
; X64:       # %bb.0:
; X64-NEXT:    movl %esi, %ecx
; X64-NEXT:    movq %rdi, %rax
; X64-NEXT:    # kill: def $cl killed $cl killed $ecx
; X64-NEXT:    rolq %cl, %rax
; X64-NEXT:    retq
	%shift.upgrd.1 = zext i8 %Amt to i64
	%B = shl i64 %A, %shift.upgrd.1
	%Amt2 = sub i8 64, %Amt
	%shift.upgrd.2 = zext i8 %Amt2 to i64
	%C = lshr i64 %A, %shift.upgrd.2
	%D = or i64 %B, %C
	ret i64 %D
}

define i64 @rotr64(i64 %A, i8 %Amt) nounwind {
; X86-LABEL: rotr64:
; X86:       # %bb.0:
; X86-NEXT:    pushl %ebx
; X86-NEXT:    pushl %edi
; X86-NEXT:    pushl %esi
; X86-NEXT:    movb {{[0-9]+}}(%esp), %cl
; X86-NEXT:    movl {{[0-9]+}}(%esp), %edi
; X86-NEXT:    movl {{[0-9]+}}(%esp), %esi
; X86-NEXT:    movl %esi, %edx
; X86-NEXT:    shrl %cl, %edx
; X86-NEXT:    movl %edi, %eax
; X86-NEXT:    shrdl %cl, %esi, %eax
; X86-NEXT:    testb $32, %cl
; X86-NEXT:    je .LBB1_2
; X86-NEXT:  # %bb.1:
; X86-NEXT:    movl %edx, %eax
; X86-NEXT:    xorl %edx, %edx
; X86-NEXT:  .LBB1_2:
; X86-NEXT:    movb $64, %ch
; X86-NEXT:    subb %cl, %ch
; X86-NEXT:    movl %edi, %ebx
; X86-NEXT:    movb %ch, %cl
; X86-NEXT:    shll %cl, %ebx
; X86-NEXT:    shldl %cl, %edi, %esi
; X86-NEXT:    testb $32, %ch
; X86-NEXT:    je .LBB1_4
; X86-NEXT:  # %bb.3:
; X86-NEXT:    movl %ebx, %esi
; X86-NEXT:    xorl %ebx, %ebx
; X86-NEXT:  .LBB1_4:
; X86-NEXT:    orl %esi, %edx
; X86-NEXT:    orl %ebx, %eax
; X86-NEXT:    popl %esi
; X86-NEXT:    popl %edi
; X86-NEXT:    popl %ebx
; X86-NEXT:    retl
;
; X64-LABEL: rotr64:
; X64:       # %bb.0:
; X64-NEXT:    movl %esi, %ecx
; X64-NEXT:    movq %rdi, %rax
; X64-NEXT:    # kill: def $cl killed $cl killed $ecx
; X64-NEXT:    rorq %cl, %rax
; X64-NEXT:    retq
	%shift.upgrd.3 = zext i8 %Amt to i64
	%B = lshr i64 %A, %shift.upgrd.3
	%Amt2 = sub i8 64, %Amt
	%shift.upgrd.4 = zext i8 %Amt2 to i64
	%C = shl i64 %A, %shift.upgrd.4
	%D = or i64 %B, %C
	ret i64 %D
}

define i64 @rotli64(i64 %A) nounwind {
; X86-LABEL: rotli64:
; X86:       # %bb.0:
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-NEXT:    movl %ecx, %edx
; X86-NEXT:    shldl $5, %eax, %edx
; X86-NEXT:    shldl $5, %ecx, %eax
; X86-NEXT:    retl
;
; X64-LABEL: rotli64:
; X64:       # %bb.0:
; X64-NEXT:    movq %rdi, %rax
; X64-NEXT:    rolq $5, %rax
; X64-NEXT:    retq
	%B = shl i64 %A, 5
	%C = lshr i64 %A, 59
	%D = or i64 %B, %C
	ret i64 %D
}

define i64 @rotri64(i64 %A) nounwind {
; X86-LABEL: rotri64:
; X86:       # %bb.0:
; X86-NEXT:    movl {{[0-9]+}}(%esp), %edx
; X86-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-NEXT:    movl %ecx, %eax
; X86-NEXT:    shldl $27, %edx, %eax
; X86-NEXT:    shldl $27, %ecx, %edx
; X86-NEXT:    retl
;
; X64-LABEL: rotri64:
; X64:       # %bb.0:
; X64-NEXT:    movq %rdi, %rax
; X64-NEXT:    rolq $59, %rax
; X64-NEXT:    retq
	%B = lshr i64 %A, 5
	%C = shl i64 %A, 59
	%D = or i64 %B, %C
	ret i64 %D
}

define i64 @rotl1_64(i64 %A) nounwind {
; X86-LABEL: rotl1_64:
; X86:       # %bb.0:
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-NEXT:    movl %ecx, %edx
; X86-NEXT:    shldl $1, %eax, %edx
; X86-NEXT:    shldl $1, %ecx, %eax
; X86-NEXT:    retl
;
; X64-LABEL: rotl1_64:
; X64:       # %bb.0:
; X64-NEXT:    movq %rdi, %rax
; X64-NEXT:    rolq %rax
; X64-NEXT:    retq
	%B = shl i64 %A, 1
	%C = lshr i64 %A, 63
	%D = or i64 %B, %C
	ret i64 %D
}

define i64 @rotr1_64(i64 %A) nounwind {
; X86-LABEL: rotr1_64:
; X86:       # %bb.0:
; X86-NEXT:    movl {{[0-9]+}}(%esp), %edx
; X86-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-NEXT:    movl %ecx, %eax
; X86-NEXT:    shldl $31, %edx, %eax
; X86-NEXT:    shldl $31, %ecx, %edx
; X86-NEXT:    retl
;
; X64-LABEL: rotr1_64:
; X64:       # %bb.0:
; X64-NEXT:    movq %rdi, %rax
; X64-NEXT:    rorq %rax
; X64-NEXT:    retq
	%B = shl i64 %A, 63
	%C = lshr i64 %A, 1
	%D = or i64 %B, %C
	ret i64 %D
}

define i32 @rotl32(i32 %A, i8 %Amt) nounwind {
; X86-LABEL: rotl32:
; X86:       # %bb.0:
; X86-NEXT:    movb {{[0-9]+}}(%esp), %cl
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    roll %cl, %eax
; X86-NEXT:    retl
;
; X64-LABEL: rotl32:
; X64:       # %bb.0:
; X64-NEXT:    movl %esi, %ecx
; X64-NEXT:    movl %edi, %eax
; X64-NEXT:    # kill: def $cl killed $cl killed $ecx
; X64-NEXT:    roll %cl, %eax
; X64-NEXT:    retq
	%shift.upgrd.1 = zext i8 %Amt to i32
	%B = shl i32 %A, %shift.upgrd.1
	%Amt2 = sub i8 32, %Amt
	%shift.upgrd.2 = zext i8 %Amt2 to i32
	%C = lshr i32 %A, %shift.upgrd.2
	%D = or i32 %B, %C
	ret i32 %D
}

define i32 @rotr32(i32 %A, i8 %Amt) nounwind {
; X86-LABEL: rotr32:
; X86:       # %bb.0:
; X86-NEXT:    movb {{[0-9]+}}(%esp), %cl
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    rorl %cl, %eax
; X86-NEXT:    retl
;
; X64-LABEL: rotr32:
; X64:       # %bb.0:
; X64-NEXT:    movl %esi, %ecx
; X64-NEXT:    movl %edi, %eax
; X64-NEXT:    # kill: def $cl killed $cl killed $ecx
; X64-NEXT:    rorl %cl, %eax
; X64-NEXT:    retq
	%shift.upgrd.3 = zext i8 %Amt to i32
	%B = lshr i32 %A, %shift.upgrd.3
	%Amt2 = sub i8 32, %Amt
	%shift.upgrd.4 = zext i8 %Amt2 to i32
	%C = shl i32 %A, %shift.upgrd.4
	%D = or i32 %B, %C
	ret i32 %D
}

define i32 @rotli32(i32 %A) nounwind {
; X86-LABEL: rotli32:
; X86:       # %bb.0:
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    roll $5, %eax
; X86-NEXT:    retl
;
; X64-LABEL: rotli32:
; X64:       # %bb.0:
; X64-NEXT:    movl %edi, %eax
; X64-NEXT:    roll $5, %eax
; X64-NEXT:    retq
	%B = shl i32 %A, 5
	%C = lshr i32 %A, 27
	%D = or i32 %B, %C
	ret i32 %D
}

define i32 @rotri32(i32 %A) nounwind {
; X86-LABEL: rotri32:
; X86:       # %bb.0:
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    roll $27, %eax
; X86-NEXT:    retl
;
; X64-LABEL: rotri32:
; X64:       # %bb.0:
; X64-NEXT:    movl %edi, %eax
; X64-NEXT:    roll $27, %eax
; X64-NEXT:    retq
	%B = lshr i32 %A, 5
	%C = shl i32 %A, 27
	%D = or i32 %B, %C
	ret i32 %D
}

define i32 @rotl1_32(i32 %A) nounwind {
; X86-LABEL: rotl1_32:
; X86:       # %bb.0:
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    roll %eax
; X86-NEXT:    retl
;
; X64-LABEL: rotl1_32:
; X64:       # %bb.0:
; X64-NEXT:    movl %edi, %eax
; X64-NEXT:    roll %eax
; X64-NEXT:    retq
	%B = shl i32 %A, 1
	%C = lshr i32 %A, 31
	%D = or i32 %B, %C
	ret i32 %D
}

define i32 @rotr1_32(i32 %A) nounwind {
; X86-LABEL: rotr1_32:
; X86:       # %bb.0:
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    rorl %eax
; X86-NEXT:    retl
;
; X64-LABEL: rotr1_32:
; X64:       # %bb.0:
; X64-NEXT:    movl %edi, %eax
; X64-NEXT:    rorl %eax
; X64-NEXT:    retq
	%B = shl i32 %A, 31
	%C = lshr i32 %A, 1
	%D = or i32 %B, %C
	ret i32 %D
}

define i16 @rotl16(i16 %A, i8 %Amt) nounwind {
; X86-LABEL: rotl16:
; X86:       # %bb.0:
; X86-NEXT:    movb {{[0-9]+}}(%esp), %cl
; X86-NEXT:    movzwl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    rolw %cl, %ax
; X86-NEXT:    retl
;
; X64-LABEL: rotl16:
; X64:       # %bb.0:
; X64-NEXT:    movl %esi, %ecx
; X64-NEXT:    movl %edi, %eax
; X64-NEXT:    # kill: def $cl killed $cl killed $ecx
; X64-NEXT:    rolw %cl, %ax
; X64-NEXT:    # kill: def $ax killed $ax killed $eax
; X64-NEXT:    retq
	%shift.upgrd.5 = zext i8 %Amt to i16
	%B = shl i16 %A, %shift.upgrd.5
	%Amt2 = sub i8 16, %Amt
	%shift.upgrd.6 = zext i8 %Amt2 to i16
	%C = lshr i16 %A, %shift.upgrd.6
	%D = or i16 %B, %C
	ret i16 %D
}

define i16 @rotr16(i16 %A, i8 %Amt) nounwind {
; X86-LABEL: rotr16:
; X86:       # %bb.0:
; X86-NEXT:    movb {{[0-9]+}}(%esp), %cl
; X86-NEXT:    movzwl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    rorw %cl, %ax
; X86-NEXT:    retl
;
; X64-LABEL: rotr16:
; X64:       # %bb.0:
; X64-NEXT:    movl %esi, %ecx
; X64-NEXT:    movl %edi, %eax
; X64-NEXT:    # kill: def $cl killed $cl killed $ecx
; X64-NEXT:    rorw %cl, %ax
; X64-NEXT:    # kill: def $ax killed $ax killed $eax
; X64-NEXT:    retq
	%shift.upgrd.7 = zext i8 %Amt to i16
	%B = lshr i16 %A, %shift.upgrd.7
	%Amt2 = sub i8 16, %Amt
	%shift.upgrd.8 = zext i8 %Amt2 to i16
	%C = shl i16 %A, %shift.upgrd.8
	%D = or i16 %B, %C
	ret i16 %D
}

define i16 @rotli16(i16 %A) nounwind {
; X86-LABEL: rotli16:
; X86:       # %bb.0:
; X86-NEXT:    movzwl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    rolw $5, %ax
; X86-NEXT:    retl
;
; X64-LABEL: rotli16:
; X64:       # %bb.0:
; X64-NEXT:    movl %edi, %eax
; X64-NEXT:    rolw $5, %ax
; X64-NEXT:    # kill: def $ax killed $ax killed $eax
; X64-NEXT:    retq
	%B = shl i16 %A, 5
	%C = lshr i16 %A, 11
	%D = or i16 %B, %C
	ret i16 %D
}

define i16 @rotri16(i16 %A) nounwind {
; X86-LABEL: rotri16:
; X86:       # %bb.0:
; X86-NEXT:    movzwl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    rolw $11, %ax
; X86-NEXT:    retl
;
; X64-LABEL: rotri16:
; X64:       # %bb.0:
; X64-NEXT:    movl %edi, %eax
; X64-NEXT:    rolw $11, %ax
; X64-NEXT:    # kill: def $ax killed $ax killed $eax
; X64-NEXT:    retq
	%B = lshr i16 %A, 5
	%C = shl i16 %A, 11
	%D = or i16 %B, %C
	ret i16 %D
}

define i16 @rotl1_16(i16 %A) nounwind {
; X86-LABEL: rotl1_16:
; X86:       # %bb.0:
; X86-NEXT:    movzwl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    rolw %ax
; X86-NEXT:    retl
;
; X64-LABEL: rotl1_16:
; X64:       # %bb.0:
; X64-NEXT:    movl %edi, %eax
; X64-NEXT:    rolw %ax
; X64-NEXT:    # kill: def $ax killed $ax killed $eax
; X64-NEXT:    retq
	%B = shl i16 %A, 1
	%C = lshr i16 %A, 15
	%D = or i16 %B, %C
	ret i16 %D
}

define i16 @rotr1_16(i16 %A) nounwind {
; X86-LABEL: rotr1_16:
; X86:       # %bb.0:
; X86-NEXT:    movzwl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    rorw %ax
; X86-NEXT:    retl
;
; X64-LABEL: rotr1_16:
; X64:       # %bb.0:
; X64-NEXT:    movl %edi, %eax
; X64-NEXT:    rorw %ax
; X64-NEXT:    # kill: def $ax killed $ax killed $eax
; X64-NEXT:    retq
	%B = lshr i16 %A, 1
	%C = shl i16 %A, 15
	%D = or i16 %B, %C
	ret i16 %D
}

define i8 @rotl8(i8 %A, i8 %Amt) nounwind {
; X86-LABEL: rotl8:
; X86:       # %bb.0:
; X86-NEXT:    movb {{[0-9]+}}(%esp), %cl
; X86-NEXT:    movb {{[0-9]+}}(%esp), %al
; X86-NEXT:    rolb %cl, %al
; X86-NEXT:    retl
;
; X64-LABEL: rotl8:
; X64:       # %bb.0:
; X64-NEXT:    movl %esi, %ecx
; X64-NEXT:    movl %edi, %eax
; X64-NEXT:    # kill: def $cl killed $cl killed $ecx
; X64-NEXT:    rolb %cl, %al
; X64-NEXT:    # kill: def $al killed $al killed $eax
; X64-NEXT:    retq
	%B = shl i8 %A, %Amt
	%Amt2 = sub i8 8, %Amt
	%C = lshr i8 %A, %Amt2
	%D = or i8 %B, %C
	ret i8 %D
}

define i8 @rotr8(i8 %A, i8 %Amt) nounwind {
; X86-LABEL: rotr8:
; X86:       # %bb.0:
; X86-NEXT:    movb {{[0-9]+}}(%esp), %cl
; X86-NEXT:    movb {{[0-9]+}}(%esp), %al
; X86-NEXT:    rorb %cl, %al
; X86-NEXT:    retl
;
; X64-LABEL: rotr8:
; X64:       # %bb.0:
; X64-NEXT:    movl %esi, %ecx
; X64-NEXT:    movl %edi, %eax
; X64-NEXT:    # kill: def $cl killed $cl killed $ecx
; X64-NEXT:    rorb %cl, %al
; X64-NEXT:    # kill: def $al killed $al killed $eax
; X64-NEXT:    retq
	%B = lshr i8 %A, %Amt
	%Amt2 = sub i8 8, %Amt
	%C = shl i8 %A, %Amt2
	%D = or i8 %B, %C
	ret i8 %D
}

define i8 @rotli8(i8 %A) nounwind {
; X86-LABEL: rotli8:
; X86:       # %bb.0:
; X86-NEXT:    movb {{[0-9]+}}(%esp), %al
; X86-NEXT:    rolb $5, %al
; X86-NEXT:    retl
;
; X64-LABEL: rotli8:
; X64:       # %bb.0:
; X64-NEXT:    movl %edi, %eax
; X64-NEXT:    rolb $5, %al
; X64-NEXT:    # kill: def $al killed $al killed $eax
; X64-NEXT:    retq
	%B = shl i8 %A, 5
	%C = lshr i8 %A, 3
	%D = or i8 %B, %C
	ret i8 %D
}

define i8 @rotri8(i8 %A) nounwind {
; X86-LABEL: rotri8:
; X86:       # %bb.0:
; X86-NEXT:    movb {{[0-9]+}}(%esp), %al
; X86-NEXT:    rolb $3, %al
; X86-NEXT:    retl
;
; X64-LABEL: rotri8:
; X64:       # %bb.0:
; X64-NEXT:    movl %edi, %eax
; X64-NEXT:    rolb $3, %al
; X64-NEXT:    # kill: def $al killed $al killed $eax
; X64-NEXT:    retq
	%B = lshr i8 %A, 5
	%C = shl i8 %A, 3
	%D = or i8 %B, %C
	ret i8 %D
}

define i8 @rotl1_8(i8 %A) nounwind {
; X86-LABEL: rotl1_8:
; X86:       # %bb.0:
; X86-NEXT:    movb {{[0-9]+}}(%esp), %al
; X86-NEXT:    rolb %al
; X86-NEXT:    retl
;
; X64-LABEL: rotl1_8:
; X64:       # %bb.0:
; X64-NEXT:    movl %edi, %eax
; X64-NEXT:    rolb %al
; X64-NEXT:    # kill: def $al killed $al killed $eax
; X64-NEXT:    retq
	%B = shl i8 %A, 1
	%C = lshr i8 %A, 7
	%D = or i8 %B, %C
	ret i8 %D
}

define i8 @rotr1_8(i8 %A) nounwind {
; X86-LABEL: rotr1_8:
; X86:       # %bb.0:
; X86-NEXT:    movb {{[0-9]+}}(%esp), %al
; X86-NEXT:    rorb %al
; X86-NEXT:    retl
;
; X64-LABEL: rotr1_8:
; X64:       # %bb.0:
; X64-NEXT:    movl %edi, %eax
; X64-NEXT:    rorb %al
; X64-NEXT:    # kill: def $al killed $al killed $eax
; X64-NEXT:    retq
	%B = lshr i8 %A, 1
	%C = shl i8 %A, 7
	%D = or i8 %B, %C
	ret i8 %D
}

define void @rotr1_64_mem(i64* %Aptr) nounwind {
; X86-LABEL: rotr1_64_mem:
; X86:       # %bb.0:
; X86-NEXT:    pushl %esi
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    movl (%eax), %ecx
; X86-NEXT:    movl 4(%eax), %edx
; X86-NEXT:    movl %edx, %esi
; X86-NEXT:    shldl $31, %ecx, %esi
; X86-NEXT:    shldl $31, %edx, %ecx
; X86-NEXT:    movl %ecx, 4(%eax)
; X86-NEXT:    movl %esi, (%eax)
; X86-NEXT:    popl %esi
; X86-NEXT:    retl
;
; X64-LABEL: rotr1_64_mem:
; X64:       # %bb.0:
; X64-NEXT:    rorq (%rdi)
; X64-NEXT:    retq

  %A = load i64, i64 *%Aptr
  %B = shl i64 %A, 63
  %C = lshr i64 %A, 1
  %D = or i64 %B, %C
  store i64 %D, i64* %Aptr
  ret void
}

define void @rotr1_32_mem(i32* %Aptr) nounwind {
; X86-LABEL: rotr1_32_mem:
; X86:       # %bb.0:
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    rorl (%eax)
; X86-NEXT:    retl
;
; X64-LABEL: rotr1_32_mem:
; X64:       # %bb.0:
; X64-NEXT:    rorl (%rdi)
; X64-NEXT:    retq
  %A = load i32, i32 *%Aptr
  %B = shl i32 %A, 31
  %C = lshr i32 %A, 1
  %D = or i32 %B, %C
  store i32 %D, i32* %Aptr
  ret void
}

define void @rotr1_16_mem(i16* %Aptr) nounwind {
; X86-LABEL: rotr1_16_mem:
; X86:       # %bb.0:
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    rorw (%eax)
; X86-NEXT:    retl
;
; X64-LABEL: rotr1_16_mem:
; X64:       # %bb.0:
; X64-NEXT:    rorw (%rdi)
; X64-NEXT:    retq
  %A = load i16, i16 *%Aptr
  %B = shl i16 %A, 15
  %C = lshr i16 %A, 1
  %D = or i16 %B, %C
  store i16 %D, i16* %Aptr
  ret void
}

define void @rotr1_8_mem(i8* %Aptr) nounwind {
; X86-LABEL: rotr1_8_mem:
; X86:       # %bb.0:
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    rorb (%eax)
; X86-NEXT:    retl
;
; X64-LABEL: rotr1_8_mem:
; X64:       # %bb.0:
; X64-NEXT:    rorb (%rdi)
; X64-NEXT:    retq
  %A = load i8, i8 *%Aptr
  %B = shl i8 %A, 7
  %C = lshr i8 %A, 1
  %D = or i8 %B, %C
  store i8 %D, i8* %Aptr
  ret void
}

define i64 @truncated_rot(i64 %x, i32 %amt) nounwind {
; X86-LABEL: truncated_rot:
; X86:       # %bb.0: # %entry
; X86-NEXT:    pushl %ebx
; X86-NEXT:    pushl %edi
; X86-NEXT:    pushl %esi
; X86-NEXT:    movb {{[0-9]+}}(%esp), %cl
; X86-NEXT:    movl {{[0-9]+}}(%esp), %esi
; X86-NEXT:    movl {{[0-9]+}}(%esp), %ebx
; X86-NEXT:    movl %esi, %eax
; X86-NEXT:    shll %cl, %eax
; X86-NEXT:    testb $32, %cl
; X86-NEXT:    movl $0, %edi
; X86-NEXT:    jne .LBB28_2
; X86-NEXT:  # %bb.1: # %entry
; X86-NEXT:    movl %eax, %edi
; X86-NEXT:  .LBB28_2: # %entry
; X86-NEXT:    movb $64, %dl
; X86-NEXT:    subb %cl, %dl
; X86-NEXT:    movl %ebx, %eax
; X86-NEXT:    movl %edx, %ecx
; X86-NEXT:    shrl %cl, %eax
; X86-NEXT:    shrdl %cl, %ebx, %esi
; X86-NEXT:    testb $32, %dl
; X86-NEXT:    jne .LBB28_4
; X86-NEXT:  # %bb.3: # %entry
; X86-NEXT:    movl %esi, %eax
; X86-NEXT:  .LBB28_4: # %entry
; X86-NEXT:    orl %edi, %eax
; X86-NEXT:    xorl %edx, %edx
; X86-NEXT:    popl %esi
; X86-NEXT:    popl %edi
; X86-NEXT:    popl %ebx
; X86-NEXT:    retl
;
; X64-LABEL: truncated_rot:
; X64:       # %bb.0: # %entry
; X64-NEXT:    movl %esi, %ecx
; X64-NEXT:    # kill: def $cl killed $cl killed $ecx
; X64-NEXT:    rolq %cl, %rdi
; X64-NEXT:    movl %edi, %eax
; X64-NEXT:    retq
entry:
  %sh_prom = zext i32 %amt to i64
  %shl = shl i64 %x, %sh_prom
  %sub = sub nsw i32 64, %amt
  %sh_prom1 = zext i32 %sub to i64
  %shr = lshr i64 %x, %sh_prom1
  %or = or i64 %shr, %shl
  %and = and i64 %or, 4294967295
  ret i64 %and
}
