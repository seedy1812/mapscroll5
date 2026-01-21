
set_layer3pal:
        ld b,16
        nextreg PAL_INDEX ,a
.loop:
        ld a,(hl)
        inc hl
        Nextreg PAL_VALUE_8BIT,a
        djnz .loop
        ret


backdrop_start:
	nextreg $1c,%00001000	; reset tilemapclipping

;       layer 3 clipping
	nextreg $1b,+(WINDOW_START_X)/2
	nextreg $1b,-1+(WINDOW_START_X+WINDOW_PIXEL_WIDTH)/2
	nextreg $1b,WINDOW_START_Y
	nextreg $1b,-1+(WINDOW_START_Y+WINDOW_PIXEL_HEIGHT)

; set where the map should be

        ld hl,backdrop_flags  
        ld (hl),MAP_START_FLAGS

        ld de,MAP_START_X
        ld (MAP_X),de
        ld (MAP_PREV_X),de
        ld de,MAP_START_Y
        ld (MAP_Y),de
        ld (MAP_PREV_Y),de

	nextreg TILE_TRANS_INDEX,15 ; set transparent colour for tilemap

        ; layer 3 pal 1 to edit
        nextreg PAL_CTRL,%00110000
        ld a,0
        ld hl,bg1_pal
        call set_layer3pal

        ;On , 40x32, 16 bit values , pal0 , no text,0 , 512 tile ,on top of ula
        nextreg LAYER_3_CTRL,%10000011


        ; point to the where map will be store
        ld a,LAYER3_BANK7|(HI(HW_MAP)& $3f)
        nextreg LAYER3_MAP_HI,a

        ; now the tiles offset
        ld a, HI(bg1_tiles)& $3f
        nextreg LAYER3_TILE_HI,a

        call backdrop_display


 ;     call test_map
        ret

backdrop_flags: db 0

;de = Y
calc_layer3_offset:
        ld de,(work_y)
        ld b,3
        ld d,0
        bsra de,b       ; (y&256) /8 - 0 -> 31

        ld a,e
        ld (HW_TILE_Y),a

        ld d, HW_WIDTH
        mul

        push de
        call get_mode_40
        pop de

        ld (HW_TILE_X),a
        add a,a
        add de,a
        ret



; de = y
calc_map_offset:
; now figure out which 8k page
if MAP_CELL_NUMBER == 16
        ld b,7                 ; divide by 128
else
        ld b,8                 ; divide by 256
endif
        ld de,(work_Y)          ; Y/256
        bsra de,b
        ld d,MAP_CELL_WIDE
        mul
        ex de,hl
        ld de,(work_X)          ;X/256
        bsra de,b
        add hl,de
        add hl,bg256_map


        ld a,(hl)
        ld (CURRENT_TILE_PTR),hl

        call backdrop_set_mmu           ; page set
        ld d,0
        ld b,4
        bsla de,b
        push de

        ; convert to xxxxyyyy weher 
        ld b,3                          ; x/8  = x = %0001 1111
        ld de, (work_X)
        bsra de,b
        ld a,e
        and +(MAP_CELL_NUMBER-1)

        add a,a                          ; (x/8)*2 = x = %0011 1110

        ld l,a

        ld de,(work_Y)                   ; y /8= y = %0001 1111
        bsra de,b
        ld a,+(MAP_CELL_NUMBER-1)
        and e
        ld e,a
if MAP_CELL_NUMBER == 16
        ld b,5                          ;  (y/8)*16 y = 111 1110 0000
else
        ld b,6                          ;  (y/8)*32 y = 111 1100 0000
endif
        bsla de,b
        ld h,0
        add hl,de
        pop de
        add hl,de
        add hl,de

;        my_break

        ret

backdrop_copy_x

        ld b,3
        ld de,(MAP_X)
        bsra de,b
        ex de,hl

        ld de,(MAP_PREV_X)
        bsra de,b

        or a
        sbc hl,de

        ret z

        ld de,(MAP_y)
        ld (work_y),de

        ld de,(MAP_X)
        ld (MAP_PREV_X),de

        jp  c,.scrolling_left
.scrolling_right:
        add de, +(WINDOW_WIDTH-1)*8
.scrolling_left:
        ld (work_x),de
        border 7
        call backdrop_store_MMU
        call backdrop_copy_column       
        call backdrop_restore_MMU
        border 0

        ret

backdrop_copy_y:
        ld b,3
        ld de,(MAP_Y)
        bsra de,b
        ex de,hl

        ld de,(MAP_PREV_Y)
        bsra de,b

        or a
        sbc hl,de

        ret z

        ld de,(MAP_Y)
        ld (MAP_PREV_Y),de

        jp  c,.scrolling_down
; if moving the map up the screen then we fill next at the bottom not the top
.scrolling_up:
        add de,WINDOW_PIXEL_HEIGHT
.scrolling_down:
        ld b,3
        ld (work_Y),de
        bsra de,b

        ld de,(MAP_X)
        ld (work_x),de

        border 5
        call backdrop_store_MMU
        call backdrop_copy_line       
        call backdrop_restore_MMU
        border 0

        ret



backdrop_store_MMU:
        ;use MMU 0+1 as the last line could go over the 8K page - so need both pages
        ld a,MMU_0
        call ReadNextReg
        ld a,(backdrop_MMU0)

        ld a,MMU_7
        call ReadNextReg
        ld a,(backdrop_MMU7)
        nextreg MMU_7,14
        ret

map_mmu_page: db 0

backdrop_set_mmu:
if MAP_CELL_NUMBER == 16
        ld b,4
else
        ld b,4-2  ; 2 extra bits 1 each for x and y 
endif
        ld d,a
        ld e,0
        bsrl de,b
        ld a,d
        add a, MAP_PAGE
        ld (map_mmu_page),a
        nextreg MMU_0,a
        ret

backdrop_inc_mmu:
        push af

        ld a,1
        jr backdrop_mmun_inc_cont

backdrop_inc_column_mmu:
        push af
        ld a,MAP_CELL_WIDE

backdrop_mmun_inc_cont:
        push hl
        ld hl,map_mmu_page
        add a,(hl)
        ld (hl),a

        ld hl,bg256_map
        add hl,a
        ld a,(hl)
        pop hl
  
        add a, MAP_PAGE
        nextreg MMU_0,a
        pop af
        ret

backdrop_restore_MMU:
        ld a,(backdrop_MMU7)
        nextreg MMU_7,a
        ld a,(backdrop_MMU0)
        nextreg MMU_0,a
        ret

backdrop_MMU0: db 0
backdrop_MMU7: db 0


backdrop_move_y
        ld hl,backdrop_flags
        bit 1,(hl)
        ret z

        bit 0,(hl)
        jr z,.otherway
        
        ld bc,(MAP_Y)
        ld a,b
        or c
        jr z, .go_down
        dec bc
        ld (MAP_Y),bc
        ret
.go_down:
        res 0,(hl)
        ret
.otherway:
        push hl
        ld bc,(MAP_Y)
        ld hl,MAX_MAP_Y
        sbc hl,bc
        ld a,h
        or l
        pop hl
        jr z,.go_up
        inc bc
        ld (MAP_Y),bc
        ret
.go_up:
        set 0,(hl)
        ret



backdrop_move_x
        ld hl,backdrop_flags

        bit 3,(hl)
        ret z


        bit 2,(hl)
        jr z,.otherway
        
        ld bc,(MAP_X)
        ld a,b
        or c
        jr z, .go_down
        dec bc
        ld (MAP_X),bc
        ret
.go_down:
        res 2,(hl)
        ret
.otherway:
        push hl
        ld bc,(MAP_X)
        ld hl, MAX_MAP_X
        or a
        sbc hl,bc
        pop hl
        jr z,.go_up
        inc bc
        ld (MAP_X),bc
        ret
.go_up:
        set 2,(hl)
        ret

backdrop_setHW:
        or a 
        ld de,WINDOW_START_X
        ld hl,(MAP_X)
        sbc hl,de

        jp p, .no
        add hl, 320
.no:
        ld de,320
 .again:       
        or a
        sbc hl,de
        jr nc, .again
        add hl,de
        ld a,h
        and 1
        nextreg LAYER3_SCROLL_X_MSB,a

        ld a, l
        nextreg LAYER3_SCROLL_X_LSB,a
        // set at top of the map - rember 8 pixel border at top
        ld a, (MAP_Y)
;        and 7
        sub WINDOW_START_Y
        nextreg LAYER3_SCROLL_Y,a
    ; point to the where map will be store
    ; top 2 bits are special
        ret


backdrop_update:
        call backdrop_setHW
        ld a,+(HI(HW_MAP)&$80)|(HI(HW_MAP)&$3f)
        nextreg LAYER3_MAP_HI,a

        ld a, HI(bg1_tiles)&$3f
        nextreg LAYER3_TILE_HI,a

        // get the map ready to show
        call backdrop_copy_y
        call backdrop_copy_x

        // update the x,y we show the map
        call backdrop_move_y
        call backdrop_move_x

        ret

backdrop_display:
        call backdrop_setHW
        call backdrop_store_MMU
 
        ld de,(MAP_X)
        ld (work_x),de
 
        ld de,(MAP_Y)
        ld (work_y),de
        ld b, WINDOW_HEIGHT
.loop:
        push bc
        call backdrop_copy_line
        pop bc

        ld de,(work_y)
        add de,8
        ld (work_y),de

        djnz .loop

        call backdrop_restore_MMU
        ret


backdrop_copy_column:

        ld b,3
        ld de,(work_Y)
        ld d,0
        bsra de,b


        ld a,+(MAP_CELL_NUMBER-1)
        and e
        neg
        add MAP_CELL_NUMBER

        ld ixl,a

        call calc_map_offset

        call calc_layer3_offset


        ex af,af'
        ld a,HI(HW_MAP)+$a
        ex af,af'

        ld a, WINDOW_HEIGHT

        add de, HW_MAP

.loop:
        ldi
        ldi

        add hl, MAP_CELL_NUMBER*2-2
        add de, HW_WIDTH-2

        dec ixl
        jr nz,.same_page

        push af 
        push de

        ld de,(current_tile_ptr)
        add de,MAP_CELL_WIDE
        ld (current_tile_ptr),de
        ld a,(de)

        call backdrop_set_mmu
        ld b,5
        ld d,0
        bsla de,b

if MAP_CELL_NUMBER == 16
        ld a,1
        and h
        res 0,d
        or d
        ld h,a
else
        ld a,%111
        and h
        ld h,a
        ld a,~%111
        and d
        or h
        ld h,a
endif

        ld ixl,MAP_CELL_NUMBER
        pop de
        pop af

.same_page:
        ex af,af'
        cp d
        jr nz ,.not_yet
        ld d,HI(HW_MAP)
.not_yet
        ex af,af'

        dec a
        jr nz,.loop

        ret

backdrop_copy_line:
        ld b,3
        ld de,(work_x) 
        ld d,0
        bsrl de,b
        ld a,+(MAP_CELL_NUMBER-1)
        and e
        neg
        add MAP_CELL_NUMBER
        jr nz,.ok
        my_break
.ok:
        add a,a
        ld ixl ,a               ; _d = (32 - (x/8))*2 ?????

        call calc_map_offset

        call calc_layer3_offset

        ld a,(HW_TILE_X)
        neg
        add 40
        add a,a
        ld ixh,a                  ;_e = (40 - (HW_TILE) *2)

        ld iyh,WINDOW_WIDTH*2      ;_c

        add de, HW_MAP

.loop:
        ; find min length , what left in 256 tile, length of the screen or how many to copy
        ld a,ixl
        cp ixh
        jr c,.oops1
        ld a,ixh
.oops1:
        cp iyh
        jr c,.oops2
        ld a,iyh
.oops2:   
        ld iyl,a                     ; _g = min ( _d,_e,_c_)


        cp 0
        jr nz,.safe
        my_break
.safe:
        ; now copy some bytes over

;        my_break

        ld b,0
        ld c,iyl

        ldir

        ; reduce how many bytes left to copy - of done return

        ld a,iyh
        sub iyl                      ; _c -=_g
        jr nz ,.some_left       
        ret

.some_left:
        ld iyh,a 

        ; if we have reaached the end of the map then wrap
        ld a,ixh
        sub iyl                      ; _e -=_g
        jr nz,.more_hw_tiles
        ld a,HW_WIDTH
        add de,-HW_WIDTH
 .more_hw_tiles:
        ld ixh,a


        ; have we reached theend of the 256 tile
;        my_break
        ld a,ixl
        sub iyl
        ld ixl,a
        jr nz , .loop



        ; need to move onto the next 256 pixel tile
        push de
        ld de,(current_tile_ptr)
        inc de
        ld (current_tile_ptr),de
        ld a,(de)
        call backdrop_set_mmu
        ld b,5
        ld d,0
        bsla de,b
        add hl,-MAP_CELL_NUMBER*2

if MAP_CELL_NUMBER == 16
        ld a,1
        and h
        res 0,d
        or d
        ld h,a
else
        ld a,%111
        and h
        ld h,a
        ld a,~%111
        and d
        or h
        ld h,a
endif
        ld ixl,MAP_CELL_NUMBER*2
;        dec ixl ; 0->255
        pop de

        jr .loop



get_mode_40:
        ld de, (work_x)
        ld b,3
        bsra de,b

        ld a,$0f
        and d
        swapnib
        ld b,a
        ld d,HI(table_mode_40)
        ld a,(de)
        add a,b
        ld e,a
        ld a,(de)

        ret

        ALIGN 256
table_mode_40:
        db 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39
        db 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39
        db 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39
        db 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39
        db 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39
        db 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39
        db 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
table_mode_40_end:
        db 0


CURRENT_TILE_PTR: dw 0

work_x: dw 0  ; used when updating maps
work_y: dw 0 


MAP_X: dw 0
MAP_Y: dw 0

MAP_PREV_Y: dw 0
MAP_PREV_X: dw 0

HW_TILE_X:      db 0        ; x = 0->39
HW_TILE_Y:      db 0        ; y = 0 to 31

bg256_map:
if MAP_CELL_NUMBER == 16
        incbin "gfx/sonic128.nxm"
else
        incbin "gfx/sonic256.nxm"
endif
        SEG MAP_SEG
bg_map: 
if MAP_CELL_NUMBER == 16
        incbin "gfx/sonic128_tiles.nxm"
else
        incbin "gfx/sonic256_tiles.nxm"
endif

        SEG TILES_SEG
bg1_tiles: 
if MAP_CELL_NUMBER == 16
        incbin "gfx/sonic128_tiles.nxt"
else
        incbin "gfx/sonic256_tiles.nxt"
endif

        SEG CODE_SEG
bg1_pal: 
if MAP_CELL_NUMBER == 16
        incbin "gfx/sonic128_tiles.nxp"
else
        incbin "gfx/sonic256_tiles.nxp"
endif
bg1_pal_length: equ *-bg1_pal

                
