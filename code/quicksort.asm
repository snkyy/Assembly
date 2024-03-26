BITS        64
SECTION     .text

insertion_sort:
    mov R13, R8 ;i
    inc R13
    .looop:
        cmp R13, R9
        jg .fin

        mov RBX, [RDI + 8*R13] ; t[i]
        mov R14, R13
        dec R14 ; j = i-1
        .inner_loop:
            cmp R14, 0
            jl .inner_fin
            mov RCX, [RDI + 8*R14]
            cmp RCX, RBX ; a[i] a[j]
            jle .inner_fin

            mov [RDI + 8*R14 + 8], RCX
            
            dec R14
            jmp .inner_loop

        .inner_fin:
        mov [RDI + 8*R14 + 8], RBX
        inc R13
        jmp .looop

    .fin:
        ret

GLOBAL      sort

sort:
    ; adres tablicy w rdi, długość w rsi
    mov R8, 0 ; left-most index
    dec RSI
    mov R9, RSI ; right-most index
    
    .quicksort:
    cmp R8, R9
    jge .finish ; l >= r 

    ;partition
    mov RAX, R8
    add RAX, R9
    shr RAX, 1
    mov RAX, [RDI + 8*RAX] ; pivot
    
    mov RDX, R8 ; i
    mov R10, R8 ; j
    mov R11, R8 ; k
 
    .looop:
        mov RCX, [RDI + 8*R11] ; a[k]

        cmp RCX, RAX
        jg .fin
        je .equal

        ;swap a[j] a[k]
        mov R12, [RDI + 8*R10]
        mov [RDI + 8*R10], RCX
        mov [RDI + 8*R11], R12

        ;swap a[i] a[j]
        mov R12, [RDI + 8*RDX]
        mov [RDI + 8*rdx], RCX
        mov [RDI + 8*R10], R12 

        inc RDX ;i++
        inc R10 ;j++
        jmp .fin
    
    .equal:
        ;swap a[j], a[k]
        mov R12, [RDI + 8*R10]
        mov [RDI + 8*R10], RCX 
        mov [RDI + 8*R11], R12

        inc R10 ;j++

    .fin:
        inc R11; k++
        cmp R11, R9
        jle .looop

        ; quicksort(arrr, l, i-1)
        push R8
        push R9

        mov R9, RDX
        dec R9
        
        mov R15, R9
        sub R15, R8
        cmp R15, 10
        jg .q2
        call insertion_sort
        jmp .i2
        .q2:
        call .quicksort
        .i2:

        pop R9
        pop R8

        ; quicksort(arrr, j, r)
        mov R8, R10

        mov R15, R9
        sub R15, R8
        cmp R15, 10
        jg .q1
        call insertion_sort
        jmp .i1
        .q1:
        jmp .quicksort
        .i1:

        .finish:
            ret 
