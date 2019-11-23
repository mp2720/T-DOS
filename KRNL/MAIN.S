[bits 16]
[org 0x800]
[cpu 8086]

SECTION CODE

jmp	kernel_main

%include "KRNL/DEBUG.S"
%include "KRNL/TFS.S" 
%include "KRNL/MEMORY.S"
%include "KRNL/STRING.S"

SECTION CODE


;Kernel's entry point.
kernel_main:
	mov	[drive_code], cl

	mov	ax, 2
	int	0x10

	;Kernel uses videopage 1, debugger uses page 0.
	mov	ah, 5
	mov	al, 1
	int	0x10
	;====

%ifdef	DEBUG
	; 
	mov	word [3*4], debug_handler
	mov	word [3*4+2], cs
	mov	word [1*4], debug_handler
	mov	word [1*4+2], cs
	;====
%endif
	mov	si, test
	call	file_open

	mov	bp, 0
	mov	si, 2
	mov	bl, al
	mov	cl, 0

	call	file_seek_sect


	BREAK
	jmp	$
;====


;Print hex-number.
;IN:
;	BX - Hex number.
print_hex:
	mov	dx, 4
	mov	cl, 12
	mov	ah, 0xE
	mov	di, 0xF000

 .lp:
	push	bx
	and	bx, di
	shr	bx, cl

	mov	al, [cs:bx+hex_nums]
	int	0x10

	push	cx
	mov	cl, 4
	shr	di, cl
	pop	cx
	
	sub	cl, 4

	dec	dx
	test	dx, dx
	pop	bx
	jnz	.lp

	ret
; ==== ==== ====


;Print message.
;IN:
;	SI - offset (from start of DS) of message to print.
print:
	push	si
	mov	ah, 0x0E
 .lp:
	mov	al, [cs:si]
	inc	si

	test	al, al
	jz	.end

	cmp	al, 0xA
	je	.newline
	
	int	0x10
	jmp	.lp

 .newline:
	int	0x10
	mov	al, 0xd
	int	0x10
	jmp	.lp

 .end:
	pop	si
	ret
; ==== ==== ====


;Read hex-num from keyboard.
;OUT:
;	AX - hex number scanned from keyboard.
;	CF - set to 1 if hex number is invalid.
scan_hex:
	mov	dx, 3
	xor	bx, bx
	mov	cl, 12

 .lp:
	;Read char from keyboard.
	xor	ax, ax
	int	0x16
	mov	ah, 0xE
	int	0x10
	;====

	xor	ah, ah

	cmp	al, '0'
	jl	.err

	cmp	al, '9'
	jg	.cont 

	sub	al, '0'
	jmp	.cont2

 .cont:
	cmp	al, 'a'
	jl	.err

	cmp	al, 'f'
	jg	.err

	sub	al, 'a'-10

 .cont2:
	shl	ax, cl
	or	bx, ax
	
	test	dx, dx
	jz	.end

	dec	dx
	sub	cl, 4
	jmp	.lp

 .err:
	stc

 .end:
	ret
;==== ==== ====


SECTION	DATA
hex_nums:
	db	"0123456789ABCDEF"
tmp:
	dq	0
end_msg:
	db	"Kernel stopped, ready for shuting down.", 0
newline:
	db	0xA, 0
test:
	db	"k.b", 0
