#!/usr/bin/python3

import struct
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("disk_bin", help="path to disk binary file.")
parser.add_argument("boot_bin", help="path to boot binary image.")
parser.add_argument("sectors", help="number of sectors on disk.")
parser.add_argument("version", help="version of TFS. Use version from 'readme.md'.")
args = parser.parse_args()

disk_bin = open(args.disk_bin, "wb")
boot_bin = open(args.boot_bin, "rb")
sectors = int(args.sectors)
if sectors >= 4294967296 or sectors <= 1:
    ValueError("Invalid sectors num.")
    
version = int(args.version)
if version >= 65536 or version <= 0:
    ValueError("Invalid version.")

boot_bin.seek(8)

buf = boot_bin.read(502)
buf = bytes(list(list(buf) + [b'\0'[0]] * (502 - len(buf))))

disk_bin.write(struct.pack("<2sHI502sH", bytes([0xeB, 0x6]), version, sectors, buf, 0xaa55))

disk_bin.write(b'>')
disk_bin.seek(sectors * 512 - 1)
disk_bin.write(b'\0')
print(str(sectors * 512) + " bytes wrote.")
