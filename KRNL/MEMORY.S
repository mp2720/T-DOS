SECTION CODE


;Allocate segment for memory.
;IN:
;	AL - ID of task that called this function.
;OUT:
;	AX - allocated segment.
mem_seg_alloc:
	mov	di, segs_tab
	mov	cx, SEGS_TAB_SIZE

 .lp:
	cs	lodsb
	cmp	al, 0
	je	.free_found

	loop	.lp

	mov	ah, NO_FREE_SEGS
	stc
	ret

 .free_found:
	sub	di, segs_tab
	
	clc
	ret
;==== ==== ====


SECTION DATA
segs_tab:
