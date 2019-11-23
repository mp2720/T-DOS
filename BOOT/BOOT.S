;T-DOS bootloader.

;Error codes:
; 01 - Extended BIOS functions not supported.
; 02 -  


;NASM directives.
[ORG 0x7C00]
[BITS 16]
[CPU 8086]
;==== ==== ====


;
times 8 db 0
;==== ==== ====


;Bootloader.
;IN:
;	%DL = boot device number.
;OUT:
;	[0x800-?] = kernel file.
;	%PC = 0x800
;	%DL = boot device number.
boot:
 .init_regs:
	cli
	xor	ax, ax
        mov	ds, ax
        mov	es, ax
	mov	ax, 0x8FC0
        mov	ss, ax
        mov	sp, 0xFFF
        sti

	mov	[drive_number], dl

 .check_lba_support:
	mov	ah, 0x41
	mov	bx, 0x55AA
	mov	dl, 0x80
	int	0x13

	jnc	.load_tfs_params

	mov	ax, "01"
	jmp	error

 .load_tfs_params:
	call	ld_sect
	mov	ax, [0x600 + 2]
	mov	[version], ax
	mov	ax, [0x600 + 4]
	mov	dx, [0x600 + 6]
	mov	[sects_num], ax
	mov	[sects_num + 2], dx

 .load_root_dir:
	mov	byte [DAP.sect_addr], 1
	call	ld_sect

 .load_kernel_file:
	call	get_kernel_file_entry
	call	load_kernel_data

 .start_kernel:
	mov	cl, [drive_number]
	mov	ax, [sects_num]
	mov	dx, [sects_num + 2]
	mov	bx, [version]
	jmp	0:0x800	
;==== ==== ====


;Print error message.
;IN:
;	%AX = error code in 2-ASCII characters.
;NOTE:
;	Infinity loop.
error:
	mov	[.err_code], ax
	mov	si, .err_msg
	mov	ah, 0x0E

 .lp:
	cmp	byte [si], 0
	je	.end
	mov	al, [si]

	int	0x10
	inc	si
	jmp	.lp

 .end:
	jmp	$

 .err_msg:
	db	"Error code: "
 .err_code:
	db	"00", 0
;==== ==== ====


;Load 512-byte sector from disk.
ld_sect:
	mov	si, DAP
	mov	ah, 0x42
	mov 	dl, [drive_number]
	int	0x13
	jc	.err

	ret

 .err:
	mov	ax, "05"
	jmp	error
;==== ==== ====


;Find kernel entry in root directory and load it's data.
;IN:
;	[0x600-0x800] - root directory sector.
;OUT:
;	%CX:BX = number of first kernel file sector.
;	%DX:AX = size of kernel file. 
get_kernel_file_entry:
	mov	bx, 0x601
	xor	dx, dx

 .lp:
	inc	dx
	cmp	dx, 31
	je	.err

	mov	cx, 8
	xor	ah, ah
	mov	si, .kfname
	
 .cmp_name:
	mov 	al, [si]
	cmp	al, [bx]
	je	.cont

	inc	ah

 .cont:
	inc	si
	inc	bx
	loop	.cmp_name

	cmp	ah, 0
	je	.end

	add	bx, 8
	jmp	.lp

 .err:
	mov	ax, "03"
	jmp	error

 .end:
	mov	cx, [bx + 2]
	mov	ax, [bx + 4]
	mov	dx, [bx + 6]
	mov	bx, [bx]
	ret

 .kfname:
	db	"K.B", 0, 0, 0, 0, 0 

 .found_flag:
	db	0
;==== ==== ====


;Load kernel file data.
;IN:
;	%CX:BX = number of first kernel file sector.
;	%DX:AX = size of kernel file. 
;OUT:
;	[0x800-?] = kernel file.
load_kernel_data:
	push	bx

	mov	bx, 512 - 5
	div	bx
	test	dx, dx
	jne	.cnt

	mov	dx, 512 - 5

 .cnt:
	mov	[.bytes_in_last_sect], dx
	pop	bx

	mov	ax, bx
	mov	dx, cx
	
	push	ax
	mov	ax, 0x80
	mov	es, ax
	pop	ax

	xor	bp, bp

 .lp:
	mov	[DAP.sect_addr], ax
	mov	[DAP.sect_addr + 2], dx

	push	ax
	push	dx
	call	ld_sect
	pop	dx
	pop	ax

	cmp	byte [0x600], '&'
	jne	.err

	mov	ax, [0x600 + 512 - 4]
	mov	dx, [0x600 + 512 - 2]

	mov	cx, 512 - 5
	mov	si, 0x601
	xor	di, di

	test	ax, ax
	jnz	.cnt2
	test	dx, dx
	jnz	.cnt2

	mov	cx, [.bytes_in_last_sect]
	inc	di

 .cnt2:
	push	ax

 .transf_data:
	mov	al, [si]
	inc	si
	mov	[es:bp], al
	inc	bp
	loop	.transf_data

	pop	ax

	cmp	di, 1
	je	.end
	jmp	.lp

 .err:
	mov	ax, "04"
	jmp	error
	
 .end:
	ret

 .bytes_in_last_sect:
	dw 	0
;==== ==== ====


;Disk Addres Packet.
DAP:
 .size:
	db	16
 .niu:
	db	0
 .sects_to_transf:
	dw	1
 .buf_addr:
	dd	0x600
 .sect_addr:
	dd	0
 .niu2:
	dd	0
; ==== ==== ====


;Boot drive number.
drive_number:
	db	0
;==== ==== ====


;Version of TFS.
version:
	dw	0
;==== ==== ====


sects_num:
	dq	0
;==== ==== ====