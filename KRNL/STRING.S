SECTION CODE


;Convert all character in string to upper case.
;IN:
;	DS:SI - address of string.
;OUT:
;	[DS:SI] - string that was converted to upper case. 
string_to_up:
 .lp:
	lodsb
	cmp	al, 0
	je	.end

	;Checking that char is lower-case letter.
	cmp	al, 'a'
	jl	.cont
	cmp	al, 'z'
	jg	.cont
	;====

	sub	al, 0x20

 .cont:
	mov	[si-1], al

	jmp	.lp

 .end:
	ret