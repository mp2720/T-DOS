; TLF info (size of segments, number of segments, source filename, etc).
SECTION	TLF_INFO
	db	0, "TLF"
	db	"TEST.S", 0, 0
	dd	0
	dd	0
	db	"c"
	dw	__TLF_CODE_START__
	dw	__TLF_CODE_END__-__TLF_CODE_START__
	db	"d"
	dw	__TLF_DATA_START__
	dw	__TLF_DATA_END__-__TLF_DATA_START__

SECTION	TLF_CODE
__TLF_CODE_START__:
	dw	0x55AA
__TLF_CODE_END__:

SECTION	TLF_DATA
__TLF_DATA_START__:
hello_world:
	dw	0x44AA
__TLF_DATA_END__:

SECTION	TLF_SYMB
__TLF_SYMB_START__:
	dw	0x
__TLF_SYMB_END__:
