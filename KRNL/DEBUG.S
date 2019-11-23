;NASM directives.
%include "KRNL/INC.S"
;====


SECTION CODE


%ifdef	DEBUG
debug_handler:
	push	di
	push	si
	push	dx
	push	cx
	push	bx
	push	ax
	push	bp
	push	sp

	;Switching to videopage 0.
	mov	ah, 5
	mov	al, 0
	int	0x10
	;====

	mov	si, breakpoint_msg
	call	print

 .reg_dump:
	mov	si, newline
	call	print

 	mov	bp, sp

	;SP
	mov	si, preg_str+2
	mov	byte [cs:si], 'S'
	call	print
	mov	bx, [ss:bp]
	call	print_hex

	;BP
	mov	si, preg_str
	mov	byte [cs:si+2], 'B'
	call	print
	mov	bx, [ss:bp+2]
	call	print_hex

	;IP
	mov	si, preg_str
	mov	byte [cs:si+2], 'I'
	call	print
	mov	bx, [ss:bp+16]
	call	print_hex

	mov	si, newline
	call	print

	;AX
	mov	si, xreg_str+2
	mov	byte [cs:si], 'A'
	call	print
	mov	bx, [ss:bp+4]
	call	print_hex

	;BX
	mov	si, xreg_str
	mov	byte [cs:si+2], 'B'
	call	print
	mov	bx, [ss:bp+6]
	call	print_hex

	;CX
	mov	si, xreg_str
	mov	byte [cs:si+2], 'C'
	call	print
	mov	bx, [ss:bp+8]
	call	print_hex

	;DX
	mov	si, xreg_str
	mov	byte [cs:si+2], 'D'
	call	print
	mov	bx, [ss:bp+10]
	call	print_hex

	;SI
	mov	si, ireg_str
	mov	byte [cs:si+2], 'S'
	call	print
	mov	bx, [ss:bp+12]
	call	print_hex

	;DI
	mov	si, ireg_str
	mov	byte [cs:si+2], 'D'
	call	print
	mov	bx, [ss:bp+14]
	call	print_hex

	;Newline
	mov	si, newline
	call	print
	;====

	;ES
	mov	si, sreg_str+2
	mov	byte [cs:si], 'E'
	call	print
	mov	bx, es
	call	print_hex

	;DS
	mov	si, sreg_str
	mov	byte [cs:si+2], 'D'
	call	print
	mov	bx, ds
	call	print_hex
	
	;SS
	mov	si, sreg_str
	mov	byte [cs:si+2], 'S'
	call	print
	mov	bx, ss
	call	print_hex

	;CS
	mov	si, sreg_str
	mov	byte [cs:si+2], 'C'
	call	print
	mov	bx, [ss:bp+18]
	call	print_hex

	mov	si, ds_flags
	call	print
	pushf
	pop	bx
	call	print_hex

	mov	si, newline
	call	print

 .cmd_lp:
	mov	ax, 0x0E3E
	int	0x10

	;Reading command
	xor	ax, ax
	int	0x16
	;====

	mov	ah, 0xE
	int	0x10

	;`h` command - print help message.
	cmp	al, 'h'
	je	.help
	;====

	;`m` command - dump memory.
	cmp	al, 'm'
	je	.dump_mem
	;====

	;`q` command - quit command loop.
	cmp	al, 'q'
	je	.end
	;====

	;`s` command - show kernel screen.
	cmp	al, 's'
	je	.show
	;====

	;`r` command - dump registers.
	cmp	al, 'r'
	je	.reg_dump
	;====

	;Unknown command.
	mov	si, unknown_cmd_msg
	call	print
	;====

	jmp	.cmd_lp

 .help:
	mov	si, help_msg
	call	print
	jmp	.cmd_lp

 .dump_mem:
	push	es

	mov	si, dump_msg1
	call	print

	;Read offset.
	call	scan_hex
	mov	si, not_hex_msg
	pop	es
	jc	.err
	push	es
	mov	[tmp], bx
	;====

	mov	si, dump_msg2
	call	print


	;Read segment
	call	scan_hex
	mov	si, not_hex_msg
	pop	es
	jc	.err
	push	es
	mov	es, bx
	;====

	mov	si, newline
	call	print

	mov	cx, 256/2
	mov	di, [cs:tmp]
	mov	dl, 7

	mov	ax, 0x0E20
	int	0x10

 .dump_mem_lp:
	mov	bh, [es:di]
	mov	bl, [es:di+1]

	push	di
	push	cx
	push	dx
	call	print_hex
	pop	dx
	pop	cx
	pop	di

	add	di, 2

	test	dl, dl
	jnz	.dump_mem_cont
	
	mov	dl, 8
	mov	si, newline
	call	print

 .dump_mem_cont:
	mov	ax, 0x0E20
	int	0x10

	dec	dl
	loop	.dump_mem_lp

	mov	si, newline
	call	print
	
	pop	es
	jmp	.cmd_lp

 .err:
	call	print
	jmp	.cmd_lp

 .show:
	mov	ah, 5
	mov	al, 1
	int	0x10

	xor	ax, ax
	int	0x16

	mov	ah, 5
	mov	al, 0
	int	0x10

	mov	si, ret_to_deb_msg
	call	print

	jmp	.cmd_lp

 .end:
	;Switching back to kernel screen.
	mov	ah, 5
	mov	al, 1
	int	0x10
	;====

	pop	sp
	pop	bp
	pop	ax
	pop	bx
	pop	cx
	pop	dx
	pop	si
	pop	di

	iret
; ==== ==== ====


SECTION DATA
preg_str:
	db	", xP=", 0
xreg_str:
	db	", xX=", 0
sreg_str:
	db	", xS=", 0
ireg_str:
	db	", xI=", 0
ds_flags:
	db	0xA, "FLAGS: ", 0
breakpoint_msg:
	db	0xA, "===BPNT===", 0xA, 0
unknown_cmd_msg:
	db	0xA, "Unknown command, type 'h' to get help.", 0xA, 0
help_msg:
	db	0xA, "Availabel commands:", 0xA
	db	" h - print help message", 0xA
	db	" m - dump 256 bytes of memory", 0xA
	db	" q - quit from loop", 0xA
	db	" s - show kernel screen", 0xA
	db	" r - dump registers", 0xA, 0
dump_msg2:
	db	0xA, "Type segment to dump (4-hex number):", 0xA, 0
dump_msg1:
	db	0xA, "Type offset to dump (4-hex number):", 0xA, 0
not_hex_msg:
	db	0xA, "Number is not hex", 0xA, 0
ret_to_deb_msg:
	db	0xA, "Returned to debugger...", 0xA, 0

%endif