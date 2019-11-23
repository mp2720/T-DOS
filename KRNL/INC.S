%define	DEBUG 1

%macro	BREAK 0
%ifdef	DEBUG
	db	0xCC
%endif
%endmacro

%define TOO_MANY_TOKS_ERR		0x10
%define TOO_LONG_TOK_ERR		0x11
%define NOT_DIR_ERR			0x12
%define FILE_NOT_FOUND_ERR		0x13
%define TOO_MANY_FILES_OPENED_ERR	0x14
%define DISK_ERR			0x15
%define INVALID_DESC_ERR		0x16
%define END_OF_FILE_ERR			0x17
%define SEEK_OVERFLOW_ERR		0x18
%define NO_FREE_SEGS			0x20

%define KERNEL				0x800
%define KERNEL_SIZE			0x4000
%define	SEGS_TAB_SIZE			9
%define FILE_NAME_SIZE			8
%define MAX_TOKS_IN_PATH		8
%define FILE_PATH_TOKENS_SIZE		64
%define FILES_IN_DIR			31
%define SECT_SIZE			512
%define DISK_BUF			0x600
%define MAX_OPENED_FILES		8
%define FILES_TAB_SIZE			(FILE_STRUCT_SIZE*MAX_OPENED_FILES)
%define FILE_STRUCT_SIZE		32
%define	SEEK_CUR			0
%define	SEEK_START			1