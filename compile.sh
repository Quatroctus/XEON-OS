# Compile the boot sector.
# TODO: Rewrite this into a Makefile to simplify.
echo Compiling Boot Sector...
gcc -nostdinc -Os -I. -MD -fno-builtin -fno-omit-frame-pointer -std=gnu99 -static -fno-pie -Wall -Wno-format -Wno-unused -Werror -masm=intel -DXEON_KERNEL -gstabs -m32 -c -o ./obj/boot.o ./src/boot.S
ld -m elf_i386 -N -e start -Ttext 0x7C00 -o ./bin/boot.out ./obj/boot.o
objdump -M intel -S ./bin/boot.out > ./bin/boot.asm
objcopy -S -O binary -j .text ./bin/boot.out ./bin/boot
gcc -o ./sign_boot ./sign_boot.c -O2 -Wno-unused-result
./sign_boot
echo Boot Sector Compiled.

# Compile the actual kernel.
echo Compiling Kernel...
gcc -nostdinc -O1 -I -MD -fno-builtin -fno-omit-frame-pointer -std=gnu99 -static -fno-pie -Wall -Wno-format -Wno-unused -Werror -masm=intel -DXEON_KERNEL -gstabs -m32 -c -o ./obj/kern/kern.o ./src/kern/kern_init.S
ld -o ./bin/kern -m elf_i386 -T ./src/kern/kernel.ld -nostdlib ./obj/kern/kern.o -b binary

objdump -M intel -S ./bin/kern > ./bin/kern.asm
nm -n ./bin/kern > ./bin/kern.sym
echo Kernel Compiled.

# Combine the kernel and boot sector into one binary.
echo Combining Boot Sector and Kernel Binaries...
rm -f ./bin/kernel.img
dd if=/dev/zero of=./bin/kernel.img~ count=10000 2>/dev/null
dd if=./bin/boot of=./bin/kernel.img~ conv=notrunc 2>/dev/null
dd if=./bin/kern of=./bin/kernel.img~ seek=1 conv=notrunc 2>/dev/null
mv ./bin/kernel.img~ ./bin/kernel.img
echo Bootable Kernel completed.
