;==== ==== ====	==== ==== ==== ==== ==== ==== ==== ====;
;	T-DOS Kernel.				       ;
;						       ;
;	Functions that working with TFS files.	       ;
;	By Tim Mahin.				       ;
;	See README.T and LICENSE for more information. ;
;==== ==== ====	==== ==== ==== ==== ==== ==== ==== ====;


;FSTRUCT structure:
;   Name | Size | Offset | Description
; -------+------+--------+-----------------------------------------------
;  NAME  | 8    | 0      | Name of opened entry.                    
;  SADDR | 4    | 8      | Address of entry's first sector on disk.
;  SIZE  | 4    | 12     | Size of entry (0 if directory).
;  TID   | 1    | 16     | ID of task that opened that file.
;  CSEC  | 4    | 17     | Current sector that was selected by `fseek`.
; -------+------+--------+-----------------------------------------------
;==== ==== ====


SECTION CODE


;Parse TFS path
;IN:
;	SI - address of path string.
;OUT:
;	[file_path_tokens...file_path_tokens+FILE_PATH_TOKENS_SIZE] -
;		array of parsed tokens.
parse_path:
	;Filling tokens array with `0`
	xor	ax, ax
	mov	cx, FILE_PATH_TOKENS_SIZE/2
	mov	di, file_path_tokens
	rep	cs stosw

	;BP is used as token pointer.
	;DI is used as char pointer.
	mov	bp, file_path_tokens

 .tok_lp:
	;If tokens number is too big
	cmp	bp, file_path_tokens+FILE_PATH_TOKENS_SIZE
	je	.too_many_toks_err
	;====

	xor	di, di

 .ch_lp:
	mov	al, [cs:si]

	inc	si

	;Checking that AL is file path splitter.
	cmp	al, '/'
	je	.cont
	;====

	;Checking that AL is end of string.
	cmp	al, 0
	clc
	je	.end
	;====

	mov	[cs:bp+di], al

	inc	di
	
	;If token is too long.
	cmp	di, FILE_NAME_SIZE+1
	je	.too_long_tok_err
	;====

	jmp	.ch_lp

 .cont:
	add	bp, FILE_NAME_SIZE
	jmp	.tok_lp

 .end:
	ret

 .too_many_toks_err:
	stc
	mov	ax, TOO_MANY_TOKS_ERR
	jmp	.end

 .too_long_tok_err:
	stc
	mov	ax, TOO_LONG_TOK_ERR
	jmp	.end
;==== ==== ====


;Find file/directory on TFS disk and open it.
;IN:
;	SI - file name.
;	AL - ID of task that opened this file.
;OUT:
;	AX - file descriptor.
file_open:
	mov	[cs:tmp], al

	push	si
	call	string_to_up
	pop	si

	;Parsing file path.
	call	parse_path
	jc	.parse_err
	;====

	mov	di, file_path_tokens

	;Current sector is root directory.
	xor	dx, dx
	mov	ax, 1
	;====

 .lp:
	;Reading one sector from disk (address in DX:AX).
	xor	cx, cx
	call	disk_io
	jc	.disk_err
	;====
	
	;Checking that directory contains valid marker ('>').
	cmp	byte [cs:DISK_BUF], '>'
	jne	.not_dir_err
	;====

	;Searching entry in loaded directory.
	mov	bx, DISK_BUF+1
	push	di
	call	find_ent_in_dir
	pop	di
	jc	.not_found_err
	;====

	;If end of file tokens then finishing search.
	add	di, FILE_NAME_SIZE
	cmp	byte [cs:di], 0
	je	.success
	;====

	;Selecting next sector.
	mov	ax, [cs:bp]
	mov	dx, [cs:bp+2]
	;====

	jmp	.lp

 .success:
	mov	di, files_tab
	mov	cx, MAX_OPENED_FILES

 ;Searching free buffer for found file.
 .lp2:
	cmp	byte [cs:di], 0
	je	.cont

	add	di, FILE_STRUCT_SIZE

	loop	.lp2

	jmp	.too_many_files_opened_err
 ;====

 .cont:
	mov	si, bp
	sub	si, FILE_NAME_SIZE
	mov	cx, FILE_STRUCT_SIZE/2
	push	di

	xor	ax, ax
	mov	es, ax

	;Storing ID of task that opened file.
	mov	al, [cs:tmp]
	mov	[cs:di+16], al
	;====

 .lp3:
	cs	lodsb
	cs	stosb
	loop	.lp3

	;Storing first sector of file in `FSTRUCT.CSEC`
	mov	ax, [cs:di-8]
	mov	word [cs:di+1], ax
	mov	ax, [cs:di-6]
	mov	word [cs:di+3], ax
	;====

	pop	ax

	sub	ax, files_tab
	mov	cl, FILE_STRUCT_SIZE
	div	cl

	clc

 .end:
	ret

 .not_found_err:
	stc
	mov	ah, FILE_NOT_FOUND_ERR
	jmp	.end

 .parse_err:
	stc
	jmp	.end

 .not_dir_err:
	stc
	mov	ah, NOT_DIR_ERR
	jmp	.end

 .too_many_files_opened_err:
	stc
	mov	ah, TOO_MANY_FILES_OPENED_ERR
	jmp	.end

 .disk_err:
	stc
	mov	ah, DISK_ERR
	jmp	.end
;==== ==== ====


;Disk IO.
;IN:
;	CL = mode (0 - read, 1 - write).
;	DX:AX = address of sector.
;	[[DAP.buf_addr]] = write buffer (only in write mode).
;OUT:
;	[[DAP.buf_addr]] = read buffer (only in read mode).
disk_io:
	push	ax
	push	si
	push	dx
	push	cx

	mov	[cs:DAP.sect_addr], ax
	mov	[cs:DAP.sect_addr + 2], dx

	mov	ah, 0x42

	;Check mode, if zero then select read mode.
	test	cl, cl
	jz	.cont
	;Else write mode

	inc	ah

 .cont:
	mov	si, DAP
	mov 	dl, [cs:drive_code]
	mov	cx, 5 ;Five attempts before error.

 .lp:
	int	0x13
	jnc	.cont2
	loop	.lp

 .cont2:
	pop	cx
	pop	dx
	pop	si
	pop	ax

	ret
;==== ==== ====


;Find entry in directory.
;IN:
;	DI = offset of entry name (8 bytes).
;	BX = address of directory sector.
;OUT:
;	BP = address of entry in dir.
find_ent_in_dir:
	;DX is used as files' entries counter.
	xor	dx, dx

 .lp:
	;Check if current enrty is end of directory.
	inc	dx
	cmp	dx, FILES_IN_DIR
	je	.err
	;====

	mov	cx, FILE_NAME_SIZE
	xor	ah, ah
	mov	si, di
	
 ;Compare name loop.
 .cmp_name:
	mov 	al, [cs:si]
	cmp	al, [cs:bx]
	je	.cont

	inc	ah

 .cont:
	inc	si
	inc	bx
	loop	.cmp_name
 ;====

	;Found file.
	cmp	ah, 0
	je	.end
	;====

	;Not found, new loop.
	add	bx, FILE_NAME_SIZE
	jmp	.lp
	;====

 .err:
	stc
	ret

 .end:
	clc
	mov	bp, bx
	ret
;==== ==== ====


;Get adress of file descriptor.
;IN:
;	BL - file descriptor.
file_get_desc_addr:
	cmp	bl, MAX_OPENED_FILES-1
	jnbe	.err

	mov	al, bl

	mov	bh, FILE_STRUCT_SIZE
	mul	bh

	xor	ah, ah
	add	ax, files_tab

	mov	bx, ax

 .success:
	clc
	ret

 .err:
	stc
	ret
;====


;Close file that was opened by `fopen`.
;IN:
;	BL - file descriptor.
file_close:
	call	file_get_desc_addr
	jc	.not_valid_desc_err

	mov	byte [cs:bx], 0
	ret

 .not_valid_desc_err:
	mov	ah, INVALID_DESC_ERR
	ret
;====


;Read current sector from file.
;IN:
;	BL - file descriptor.
;	ES:BP - adress of buffer to write data read from disk.
;OUT:
;	[ES:BP+1...ES:BP+507] - read sector from disk.
file_read_sect:
	call	file_get_desc_addr
	jc	.desc_err

	;Load address of current sector.
	mov	ax, [cs:bx+17]
	mov	dx, [cs:bx+19]
	;====

	;Check if current sector is zero.
	test	dx, dx
	jnz	.cont
	test	ax, ax
	jnz	.cont
	;====

	;Current sector is zero, end of file.
	mov	ah, END_OF_FILE_ERR
	jmp	.err
	;====

 .cont:
	;Load adress of new buffer,
	mov	[cs:DAP.buf_addr], bp
	mov	[cs:DAP.buf_addr+2], es
	;====

	;Load sector.
	call	disk_io
	mov	al, ah
	mov	ah, DISK_ERR
	jc	.err
	;====

	;Load next sector adress and write it to file struct.
	mov	ax, [cs:bp+SECT_SIZE-4]
	mov	[cs:bx+17], ax
	mov	ax, [cs:bp+SECT_SIZE-2]
	mov	[cs:bx+19], ax
	;====

	;Load default buffer address
	mov	word [cs:DAP.buf_addr], DISK_BUF
	mov	word [cs:DAP.buf_addr+2], 0
	;====

	clc
	jmp	.end

 .err:
	stc

 .end:
	ret

 .desc_err:
	mov	ah, INVALID_DESC_ERR
	ret
;==== ==== ====


;Select new sector.
;IN:
;	BL - file descriptor.
;	BP:SI - offset (if mode=SEEK_CUR then offset from current sector,
;			if mode=SEEK_START then offset from start of the file).
;	CL - mode.
file_seek_sect:
	call	file_get_desc_addr
	jc	.desc_err

	cmp	cl, SEEK_START
	je	.seek_start

 .seek_cur:
 	;Current sector.
	mov	ax, [cs:bx+17]
	mov	dx, [cs:bx+19]
	;====

	sub	si, ax
	sbb	bp, dx
	BREAK
	jo	.overflow_err

	jmp	.lp

 .seek_start:
	mov	ax, [cs:bx+8]
	mov	dx, [cs:bx+10]

 .lp:
	sub	si, 1
	sbb	bp, 0

	jo	.end

	mov	cl, 0
	call	disk_io

	mov	ax, [cs:DISK_BUF+508]
	mov	dx, [cs:DISK_BUF+510]

 	test	ax, ax
	jnz	.cont2

	test	dx, dx
	jnz	.cont2

	jmp	.lp

 .cont:
	

	ret
 .cont2:
 .end:
	clc
	ret

 .overflow_err:
	stc
	mov	ah, SEEK_OVERFLOW_ERR
	ret

 .desc_err:
	mov	ah, INVALID_DESC_ERR
	ret
;==== ==== ====


;Get file's current sector.
;IN:
;	BL - file descriptor.
;OUT:
;	DX:CX - 
;	BL - mode.
file_get_cur_sect:
	
	ret
;==== ==== ====


SECTION	DATA
file_path_tokens:
	times	(FILE_NAME_SIZE*MAX_TOKS_IN_PATH) db 0
files_tab:
	times	(FILES_TAB_SIZE) db 0
drive_code:
	db	0
sects_num:
	dd	0
DAP:
 .size:
	db	16
 .niu:
	db	0
 .sects_to_transf:
	dw	1
 .buf_addr:
	dd	DISK_BUF
 .sect_addr:
	dd	1
 .niu2:
	dd	0
