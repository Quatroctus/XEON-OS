.intel_syntax noprefix

.text
.align 4
.long 0x1BADB002
.long 0
.long -0x1BADB002

.globl _start
_start = (entry - 0xF0000000)

.globl entry
entry:
    mov word ptr [0x472], 0x1234

    mov esp, bootstacktop
    mov al, 'K'
    call log
    jmp $

log:
    mov dword ptr [0xb8000], 0x4f524f45
    mov dword ptr [0xb8004], 0x4f3a4f52
    mov dword ptr [0xb8008], 0x4f204f20
    mov byte  ptr [0xb800a], al
    ret

.bss
.p2align 12
.globl bootstack
bootstack:
    .space 8*4096
.globl bootstacktop
bootstacktop:    
