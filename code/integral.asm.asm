BITS        64
SECTION     .text

GLOBAL      _Z2sid
_Z2sid:

    ; xmm0: <x, x>
    movlhps XMM0, XMM0

    ; xmm1: <x^4, x^4>
    movups XMM1, XMM0
    mulpd XMM1, XMM1
    mulpd XMM1, XMM1

    ; xmm2 <x, x^3>
    movups XMM2, XMM0
    mulsd XMM2, XMM0
    mulsd XMM2, XMM0

    ; xmm3 <x^5, x^7>
    movups XMM3, XMM2
    mulpd XMM3, XMM1

    ; xmm4 <x^9, x^11>
    movups XMM4, XMM3
    mulpd XMM4, XMM1

    ; xmm5 <x^13, x^15>
    movups XMM5, XMM4
    mulpd XMM5, XMM1

    ; dividing by constants
    mulsd XMM2, [rel first]

    movhps XMM6, [rel second]
    movlps XMM6, [rel third]
    mulpd XMM3, XMM6

    movhps XMM6, [rel fourth]
    movlps XMM6, [rel fifth]
    mulpd XMM4, XMM6

    movhps XMM6, [rel sixth]
    movlps XMM6, [rel seventh]
    mulpd XMM5, XMM6

    ;obliczanie wyniku
    addpd XMM2, XMM3
    addpd XMM2, XMM4
    addpd XMM2, XMM5
    movhlps XMM0, XMM2
    subsd XMM0, XMM2
    ret

SECTION .data:
align 16
first: DQ 0.05555555555555555555555555555555555555555
second: DQ 0.0016666666666666666666666666666666666666
third: DQ 0.00002834467120181405895691609977324263038
fourth: DQ 0.0000003061924358220654516950813247109543
fifth: DQ 0.00000000227746439867651988864110076231288
sixth: DQ 0.00000000001235311064370893430722490551550
seventh: DQ 0.000000000000050981091545465443172674213