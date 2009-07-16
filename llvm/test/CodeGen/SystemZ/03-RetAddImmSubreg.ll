; RUN: llvm-as < %s | llc -march=systemz | grep ahi       | count 3
; RUN: llvm-as < %s | llc -march=systemz | grep afi       | count 3
; RUN: llvm-as < %s | llc -march=systemz | grep lgfr      | count 6
; RUN: llvm-as < %s | llc -march=systemz | grep llgfr     | count 4


define i32 @foo1(i32 %a, i32 %b) {
entry:
    %c = add i32 %a, 1
    ret i32 %c
}

define i32 @foo2(i32 %a, i32 %b) {
entry:
    %c = add i32 %a, 131072
    ret i32 %c
}

define i32 @foo3(i32 %a, i32 %b) zeroext {
entry:
    %c = add i32 %a, 1
    ret i32 %c
}

define i32 @foo4(i32 %a, i32 %b) zeroext {
entry:
    %c = add i32 %a, 131072
    ret i32 %c
}

define i32 @foo5(i32 %a, i32 %b) signext {
entry:
    %c = add i32 %a, 1
    ret i32 %c
}

define i32 @foo6(i32 %a, i32 %b) signext {
entry:
    %c = add i32 %a, 131072
    ret i32 %c
}

