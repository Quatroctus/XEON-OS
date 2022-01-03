.intel_syntax noprefix

#include "../include/mmu.inc"

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
    mov esp, offset bootstacktop - 0xF0000000
    
    mov al, 'K'
    call log

    # Create the page table and directory.
    mov esi, (offset entry_pgtable - 0xF0000000)
    mov ecx, 1024
    mov eax, 3
page_entry:
    mov dword ptr [esi], eax
    add eax, 0x1000
    add esi, 4
    loop page_entry
    
    mov dword ptr [entry_pgdir - 0xF0000000], (offset entry_pgtable - 0xF0000000) + 1
    mov dword ptr [entry_pgdir - 0xF0000000 + 3840], (offset entry_pgtable - 0xF0000000) + 3

    mov eax, dword ptr [entry_pgdir - 0xF0000000]
    call logshort
    shr eax, 16
    call logshort


    mov al, 'E'
    call log

    # Put the page directory into the cr3 register and enable paging.
    mov eax, offset entry_pgdir - 0xF0000000
    mov cr3, eax
    mov eax, cr0
    or eax, (CR0_PE | CR0_PG | CR0_WP)
    mov cr0, eax

    jmp 0x08:relocated

relocated:
    xor ebp, ebp
    mov esp, offset bootstacktop
    
    mov al, 'P'
    call log
    
    # TODO: Call to init.

    jmp $

logshort:
    push esi
    push ecx
    push eax
    mov ecx, 4
    mov esi, 0xb8006 + 800
    add esi, dword ptr [vgaoffset - 0xF0000000]
writeloop:
    push eax
    and al, 0xF
    add al, '0'
    cmp al, '9'
    jbe write
    add al, 7
write:
    mov byte ptr [esi], al
    dec esi
    dec esi
    pop eax
    shr eax, 4
    loop writeloop

    add dword ptr [vgaoffset - 0xF0000000], 160

    pop eax
    pop ecx
    pop esi
    ret

log:
    mov dword ptr [0xb8000], 0x4f4F4f4C
    mov dword ptr [0xb8004], 0x4f3a4f47
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
entry_pgtable:
    .space 4096
entry_pgdir:
    .space 4096
vgaoffset:
    .space 4
