Before making the .nex file you need to run the bat files in the gfx folder. This will cut the map into 128x128 or 256x256 tiles and then convert them down to 8x8 hardware tiles. Gfx2Next is needed to convert the map

In mapscroll.5 you can configure some aspects

WINDOW_START_X and WINDOW_START_Y set the window into which the map is displayed

VBL_ON_LINE_INTERRUPT if set to 1 will use the line interrupt to time everything from. If not it uses the noramal VBL which is off the end of the screen

MAP_START_FLAGS automatically bound around the map\
 backdrop_flags use to indicated scroll direction\
bit 0 = y direction 	0 = y++\
bit 1 = y active\
bit 2 = x direction 	0 = x++\
bit 3 = x active\
MAP_START_FLAGS: equ %1010

MAP_HEIGHT_PIXELS 	equ 768		; height in pixels\
MAP_WIDTH_PIXELS 	equ 4096		; width in pixels\
WINDOW_WIDTH:		equ +(30+1)	; how may HW tiles high - * 2  for 16 pixel height tiles +1 extra\
WINDOW_HEIGHT:     	equ +(26+1)	; y HW tiles high * 2  for 16 pixel height tiles+ 1 extra\

MAP_CELL_PIXELS	 equ 128\
This determines which set of meta tiles to use. ( 128 or 256)

MAP_START_X and MAP_START_Y is the start point of the map
