WINDOW_START_Y:		equ 17		; where on screen map is displayed
WINDOW_START_X:		equ 37

; backdrop_flags use to indicated scroll direction
; bit 0 = y direction 	0 = y++
; bit 1 = y active
; bit 2 = x direction 	0 = x++
; bit 3 = x active
MAP_START_FLAGS: equ %1010

VBL_ON_LINE_INTERRUPT: equ 1

MAP_HEIGHT_PIXELS 	equ 768		; height in pixels
MAP_WIDTH_PIXELS 	equ 4096		; width in pixels
WINDOW_WIDTH:		equ +(30+1)	; how may HW tiles high - * 2  for 16 pixel height tiles +1 extra
WINDOW_HEIGHT:     	equ +(26+1)	; y HW tiles high * 2  for 16 pixel height tiles+ 1 extra
HW_WIDTH:      		equ 40*2		; hw is 40 tiles *2 bytes

MAP_CELL_PIXELS	 equ 128

MAP_CELL_NUMBER: equ (MAP_CELL_PIXELS/8)

MAP_CELL_WIDE: equ MAP_WIDTH_PIXELS/MAP_CELL_PIXELS
MAP_CELL_HIGH: equ MAP_HEIGHT_PIXELS/MAP_CELL_PIXELS

MAP_CELL_VOLUME: equ MAP_CELL_NUMBER*MAP_CELL_NUMBER*2
MAP_CELLS_PER_8K: equ (8*1024)/(MAP_CELL_VOLUME)


HW_MAP 				equ $e000		; location in memory for hw map
WINDOW_PIXEL_HEIGHT equ (WINDOW_HEIGHT-1)*8	; this is height what is seen on screen
WINDOW_PIXEL_WIDTH	equ (WINDOW_WIDTH-1)*8

;MAX_MAP_X: equ 8+MAP_WIDTH_PIXELS-440 +(40-WINDOW_WIDTH)*8
MAX_MAP_X: equ MAP_WIDTH_PIXELS-WINDOW_PIXEL_WIDTH
MAX_MAP_Y: equ MAP_HEIGHT_PIXELS-WINDOW_PIXEL_HEIGHT


MAP_START_X		equ 128
MAP_START_Y		equ 0



LINE_INT_LSB		 	equ $23
LAYER3_SCROLL_X_MSB	 	equ $2f
LAYER3_SCROLL_X_LSB	 	equ $30
LAYER3_SCROLL_Y		 	equ $31
PAL_INDEX            	equ $40
PAL_VALUE_8BIT       	equ $41
PAL_CTRL			 	equ $43
TILE_TRANS_INDEX: 	 	equ $4c
MMU_0					equ $50
MMU_7					equ $57
LAYER_3_CTRL		 	equ $6b
TILE_DEF_ATTR		 	equ $6c
LAYER3_MAP_HI		 	equ $6e
LAYER3_TILE_HI		 	equ $6f

LAYER3_BANK7			equ $80

NEXTREG_OUT			 	equ $243b


border macro
		push af
        ld a,\0
        out ($fe),a
		pop af
		endm

MY_BREAK	macro
        db $fd,00
		endm


	OPT Z80
	OPT ZXNEXTREG    

CODE_PAGE equ 2*2

YTABLE_PAGE equ 9*2
MAP_PAGE equ 10*2
MAP_PAGE_ADDR equ $a000

TILES_PAGE equ 5*2

    seg     CODE_SEG, 			 	CODE_PAGE:$0000,$8000
	seg 	MAP_SEG,				MAP_PAGE:$0000,MAP_PAGE_ADDR
	seg 	TILES_SEG,				TILES_PAGE:$0000,$4000
	seg		YTABLE_SEG,				YTABLE_PAGE:$0000,$e000

    seg     CODE_SEG
start:
	ld sp , StackStart

	call backdrop_start

	call video_setup

	call init_vbl

	ld a, 6
	call ReadNextReg
	and %01011111 
	Nextreg 6,a

	nextreg 7,%11 ; 28mhz


frame_loop:

	call backdrop_update

	call wait_vbl

	jp frame_loop

video_setup:
;      nextreg $68,%10000000   ;ula disable
       nextreg $15,%00000100 ; no low rez , LSU ,  sprites lo priority , no sprites
       ret

 ReadNextReg:
       push bc
       ld bc,NEXTREG_OUT
       out (c),a
       inc b
       in a,(c)
       pop bc
       ret




StackEnd:
	ds	128*3
StackStart:
	ds  2

include "irq.s"

include "backdrop.s"

THE_END:

 	savenex "mapscroll5.nex",start

