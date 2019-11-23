.PHONY: all clean run

all: MOUNT/K.B BIN/DISK.B
	@echo "=== Dismounting files...         ==="
	python3 py/mnt_tfs.py -d BIN/DISK.B MOUNT

BIN/BOOT.B: BOOT/BOOT.S
	@echo "=== Building bootloader...       ==="
	nasm BOOT/BOOT.S -o BIN/BOOT.B

MOUNT/K.B: KRNL/MAIN.S KRNL/DEBUG.S KRNL/INC.S KRNL/TFS.S KRNL/STRING.S KRNL/MEMORY.S
	@echo "=== Building kernel...           ==="
	nasm KRNL/MAIN.S -Xgnu -o MOUNT/K.B
	ndisasm MOUNT/K.B -b16 -o0x0800 > DISASM/KERNEL.S

BIN/DISK.B: BIN/BOOT.B
	@echo "=== Making TFS on disk...        ==="
	python3 py/mkfs_tfs.py BIN/DISK.B BIN/BOOT.B 4294967295 1

clean:
	@echo "=== Removing all output files... ==="
	rm -rf MOUNT/K.B BIN/BOOT.B BIN/DISK.B

run: all
	@echo "=== Running emulator...          ==="
	qemu-system-i386 BIN/DISK.B
