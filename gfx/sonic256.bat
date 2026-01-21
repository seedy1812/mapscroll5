gfx2next -tile-size=256x256 -tile-norepeat -preview -tiled-width=256  sonic.png  sonic256
rem rename sonic256_tileset_preview.png sonic256_tiles.png
gfx2next -tile-size=8x8 -tile-norepeat -map-16bit -colors-4bit -pal-rgb332 sonic256_tileset_preview.png sonic256_tiles
