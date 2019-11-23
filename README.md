Unfinished OS for x86-16.

Implemented:

* Custom filesystem with nested directories, mkfs and mount python scripts
* Bootloading from file on a disk
* Opening files in kernel
* Primitive kernel debugger
* Reading from keyboard and printing on screen
* Kernel memory allocation

To run it install `nasm`, `qemu-system-i386`, `python3` and `make`. Then

```bash
make run
```
