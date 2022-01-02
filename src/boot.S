#include "include/elf.inc"
.intel_syntax noprefix
.globl start
start:
.code16
    cli
    cld
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax

    # Enable A20
seta20_1:
    in al, 0x64
    test al, 0x2
    jnz seta20_1

    mov al, 0xd1
    out 0x64, al

seta20_2:
    in al, 0x64
    test al, 0x2
    jnz seta20_2

    mov al, 0xdf
    out 0x60, al

    # Switch from REAL mode to PROTECTED mode and setup the temp gdt.
    lgdt [gdtdesc]
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax

    jmp 0x08:protcseg

# We are now in 32 bit mode.
.code32
protcseg:
    # Set the segment registers to 16.
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    # Use a temporary stack beneath the boot data and code.
    mov esp, offset start

    mov eax, 0x0001
    call log

    # Load the elf kernel executable.
    call bootmain

    # Loop infinitly if we somehow return from the kernel.
    jmp $

.globl waitdisk
waitdisk:
    mov dx, 0x1f7
waitloop:
    in al, dx
	and al, 0xc0
    cmp al, 0x40
    jne waitloop
	ret

# void readsect(edi, eax)
# void readsect(dst, offset)
.globl readsect
readsect:
    push edi
    push eax
    push eax
    call waitdisk
    
    mov al, 0x1
    mov dx, 0x1f2
    out dx, al

    mov ecx, 3
    pop eax
outoffset:
    inc dx
    out dx, al
    shr eax, 8
    loop outoffset
    or eax, 0xE0
    inc dx
    out dx, al

    mov al, 0x20
    inc dx
    out dx, al

    call waitdisk

    mov ecx, 128
    mov dx, 0x1F0
    repnz insd
    pop eax
    pop edi
    ret

# void readseg(edi, edx, eax)
# void readseg(pa, count, offset)
.globl readseg
readseg:
    push edi
    push edx
    push eax
    add edx, edi
    and edi, -512
    shr eax, 9
    inc eax

sections:
    cmp edi, edx
    jae endsections
    call readsect
    add edi, 512
    inc eax
    jmp sections
endsections:
    pop eax
    pop edx
    pop edi
    ret


.set ELFHDR, 0x10000
# void bootmain()
.globl bootmain
bootmain:
    mov edi, ELFHDR
    mov edx, 4096
    xor eax, eax
    call readseg

    mov eax, 0x0002
    call log

    cmp dword ptr [ELFHDR + Elf.e_magic], ELF_MAGIC
    jne badelf

    mov eax, 0x0003
    call log

    mov ebx, edi
    add ebx, dword ptr [ELFHDR + Elf.e_phoff]
    movzx ebp, word ptr [ELFHDR + Elf.e_phnum]
    shl ebp, 5
    add ebp, ebx
segments:
    cmp ebx, ebp
    jae endsegments

    mov edi, [ebx + Proghdr.p_pa]
    mov edx, [ebx + Proghdr.p_memsz]
    mov eax, [ebx + Proghdr.p_offset]
    call readseg

    mov eax, dword ptr [ebx + Proghdr.p_filesz]
    mov ecx, dword ptr [ebx + Proghdr.p_memsz]
    add edi, eax
    sub ecx, eax
    xor eax, eax
    rep stosb
    
    add ebx, sizeof.Proghdr
    jmp segments
endsegments:
    mov ax, 0x0004
    call log
    call [ELFHDR + Elf.e_entry]

badelf:
    mov dx, 0x8A00
    mov ax, 0x8A00
    out dx, ax
    mov ax, 0x8E00
    out dx, ax
    mov ax, 0xF001
    call log
    jmp $


# void log(ax)
# void log(code)
.globl log
log:
    push esi
    push ecx
    push eax
    mov ecx, 4
    mov esi, 0xb8006
    add esi, dword ptr [vgaoffset]
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

    add dword ptr [vgaoffset], 160

    pop eax
    pop ecx
    pop esi
    ret

# Create a temp GDT that performs a 1 to 1 mapping of linear to physical addresses.
.p2align 2
gdt_v: 
    .word 0, 0
    .byte 0, 0, 0, 0
    .word 0xFFFF, 0
    .byte 0, 0x9A, 0xCF, 0
    .word 0xFFFF, 0
    .byte 0, 0x92, 0xCF, 0

# A description of the temp GDT.
gdtdesc:
    .word 0x17
    .long offset gdt_v

vgaoffset:
    .long 0
