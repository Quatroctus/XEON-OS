
SRCFILES := src/kern/kern_entry.S

OBJFILES := $(patsubst src/%.S, obj/%.o, $(SRCFILES))
OBJFILES := $(patsubst obj/lib/%, obj/kern/%, $(OBJFILES))

GCC_FLAGS := -O1 -fno-builtin -I. -MD -fno-omit-frame-pointer -std=gnu99 -static -fno-pie -fno-tree-ch
GCC_FLAGS += -Wall -Wno-format -Wno-unused -Werror -gstabs -m32
KERN_GCC_FLAGS := $(GCC_FLAGS) -DXEON_KERNEL -gstabs

LDFLAGS := -m elf_i386
KERN_LDFLAGS := $(LDFLAGS) -T ./src/kern/kernel.ld -nostdlib

obj/boot.o: src/boot.S
	@echo + cc $<
	@mkdir -p $(@D)
	gcc -nostdinc $(KERN_GCC_FLAGS) -c -o $@ $<

obj/kern/%.o: src/kern/%.S
	@echo + cc $<
	@mkdir -p $(@D)
	gcc -nostdinc $(KERN_GCC_FLAGS) -c -o $@ $<

sign_boot: ./sign_boot.c
	@echo + cc $<
	gcc -o ./sign_boot ./sign_boot.c -O2 -Wno-unused-result

bin/boot: obj/boot.o ./sign_boot
	@echo ld bin/boot
	ld $(LDFLAGS) -N -e start -Ttext 0x7C00 -o $@.out $<
	objdump -M intel -S $@.out > $@.asm
	objcopy -S -O binary -j .text $@.out $@
	./sign_boot

bin/kernel: $(OBJFILES) src/kern/kernel.ld
	@echo + ld $@
	ld -o $@ $(KERN_LDFLAGS) $(OBJFILES) -b binary
	objdump -M intel -S $@ > $@.asm
	nm -n $@ > $@.sym

bin/kernel.img: bin/kernel bin/boot
	@echo + mk $@
	rm -f bin/kernel.img
	dd if=/dev/zero of=bin/kernel.img~ count=10000 2>/dev/null
	dd if=bin/boot of=bin/kernel.img~ conv=notrunc 2>/dev/null
	dd if=bin/kernel of=bin/kernel.img~ seek=1 conv=notrunc 2>/dev/null
	mv bin/kernel.img~ bin/kernel.img

all: bin/kernel.img
