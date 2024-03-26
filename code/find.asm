BITS 64

SECTION .text

errors_handler:
    push RBX
    push RDI
    push RSI

    mov RBX, RDI ;pathname (input)

    ;open syscall
    mov RAX, 2
    mov RSI, 0
    syscall

    cmp RAX, -2 ;No such file or directory
    jne .next
    
    ;print error message
    mov RSI, error_beg
    mov R12, 0
    call print

    push RBX
    mov RSI, RBX
    call print
    pop RBX

    mov RSI, error_end_1
    mov R12, 1
    call print

    mov RAX, 1
    jmp .fin

    .next:
    cmp RAX, -20 ;Not a directory
    jne .neext
    
    ;print error message
    mov RSI, error_beg
    mov R12, 0
    call print

    push RBX
    mov RSI, RBX
    call print
    pop RBX

    mov RSI, error_end_2
    mov R12, 1
    call print

    mov RAX, 1
    jmp .fin

    .neext:
    mov RAX, 0

    .fin:

    pop RSI
    pop RDI
    pop RBX
    ret

slash_remove:
    push RDX
    push RDI

    mov RDX, 0
    .len:
        cmp byte [RDI + RDX], 0x00
        je .done
        inc RDX
        jmp .len
    
    .done:
    dec RDX
    cmp byte [RDI + RDX], 0x2F
    jne .fin
    mov byte [RDI + RDX], 0x00

    .fin:
    pop RDI
    pop RDX

    ret

current_dir:
    push RAX
    push RDX
    push RDI
    push RSI
    push R11

    ;make new path in R11 containing [RDI] + [RSI] + '/'

    ;move [RDI] to R11
    mov RDX, 0
    .looop:
        cmp byte [RDI + RDX], 0x00
        je .fin_1

        mov al, [RDI + RDX]
        mov [R11 + RDX], al
        inc RDX
        jmp .looop
    .fin_1:

    ;append [RSI] to R11
    add R11, RDX
    mov RDX, 0
    .looop2:
        cmp byte [RSI + RDX], 0x00
        je .fin_2

        mov al, [RSI + RDX]
        mov [R11 + RDX], al
        inc RDX
        jmp .looop2
    .fin_2:

    ;append '/\0' at the end
    mov byte [R11 + RDX], 0x2F
    inc RDX
    mov byte [R11 + RDX], 0x00

    pop R11
    pop RSI
    pop RDI
    pop RDX
    pop RAX

    ret

check_dots:   
    push RDX
    push RSI
    push RCX

    mov RDX, 0
    .len:
        cmp byte [RSI + RDX], 0x00
        je .done
        inc RDX
        jmp .len
    
    .done:
        cmp RDX, 2
        jg .fin_1

        mov RCX, 0
        .looop:
            cmp RCX, RDX
            jge .fin_2
            cmp byte [RSI + RCX], 0x2E ; 0x2E = 46 in hex -> '.'
            jne .fin_1
            inc RCX
            jmp .looop
        
    .fin_1:
    mov RAX, 1
    jmp .fin

    .fin_2:
    mov RAX, 0
    jmp .fin

    .fin:
    pop RCX
    pop RSI
    pop RDX
    ret
    
print:
    push RAX
    push RBX
    push RCX
    push RDX
    push RDI
    push RSI
    push R8
    push R9
    push R10
    push R11
    push R12

    ;calculate length of string in RSI
    mov RDX, 0
    .len:
        cmp byte [RSI + RDX], 0x00 ;check for end of string
        je .done
        inc RDX
        jmp .len
    
    ;write string (already in RSI, len in rdx)  
    .done:
        mov RAX, 1
        mov RDI, 1
        syscall

        ;write newline
        cmp R12, 0 ;R12 = 0 -> endl
        je .fin
        mov RAX, 1
        mov RDI, 1
        mov RSI, newline
        mov RDX, 1
        syscall
    
    .fin:
    pop R12
    pop R11
    pop R10
    pop R9
    pop R8
    pop RSI
    pop RDI
    pop RDX
    pop RCX
    pop RBX
    pop RAX

    ret

find:
    push RAX
    push RBX
    push RCX
    push RDX
    push RDI
    push RSI
    push R8
    push R9
    push R10
    push R11

    sub RSP, 8192 ;8K
    mov R8, RSP ;buf
    mov R11, RSP ;path
    add R11, 4096 ;4096 = MAX_PATH_LENGTH

    call current_dir ;R11 = current directory

    ;open syscall (name already in rdi)
    push R11

    mov RAX, 2
    mov RDI, R11
    mov RSI, 196608 ;O_RDONLY | O_DIRECTORY | O_NOFOLLOW
    syscall
    mov EBX, EAX ;ebx := file desctiptor

    pop R11

    .looop:

        ;getdents64 syscall
        push R11

        mov RAX, 217
        mov EDI, EBX  ;fd
        mov RSI, R8   ;buf    
        mov RDX, 4096 ;buf size 4K
        syscall

        pop R11

        cmp RAX, 0 ;if number of read bytes == 0 -> fin
        jle .fin_1

        mov RCX, RAX ;nread

        mov RDX, 0 ;buffer position
        .looop2:
            cmp RDX, RCX ;if buf_pos >= nread -> fin2
            jge .fin_2
            
            mov R9W, [R8 + RDX + 16] ;d_reclen (size of current struct)

            mov RSI, R8
            add RSI, RDX
            add RSI, 19 ;RSI = buf + buf_pos + 19 = start of name string in struct

            call check_dots ;check if name is equal to . or ..
            cmp RAX, 0
            je .dots
            
            ;print current directory
            push RSI
            mov RSI, R11 ;RSI <-- path
            mov R12, 0 ;without newline
            call print
            pop RSI

            ;print name from current struct
            mov R12, 1 ;with newline
            call print

            mov R10B, [R8 + RDX + 18] ;d_type
            cmp byte R10B, 0x4 ;d_type ?= DT_DIR
            jne .dots

            mov RDI, R11
            call find ;recursive call on a directory, RDI = curr path, RSI = name of dir

            .dots:
            add RDX, R9 ;buf_pos += d_reclen
            jmp .looop2
        .fin_2:
        jmp .looop
    .fin_1:

    add RSP, 8192

    pop R11
    pop R10
    pop R9
    pop R8
    pop RSI
    pop RDI
    pop RDX
    pop RCX
    pop RBX
    pop RAX
    
    ret

GLOBAL _start

_start:
    mov RDI, [RSP + 16] ;argv[1]

    call errors_handler

    cmp RAX, 0
    jne .fin

    ;print argv[1]
    mov RSI, RDI
    mov R12, 1
    call print

    ;remove extra slash if needed
    call slash_remove

    mov RSI, null
    call find    

    .fin:
    mov RAX, 60
    mov RDI, 0
    syscall

SECTION .data

error_beg:
        db 'find: ‘', 0
error_end_1:
        db '’: No such file or directory', 0
error_end_2:
        db '’: Not a directory', 0
newline:
        db 0x0A
null:
        db 0x00
