gfx2next -tile-size=128x128 -tile-norepeat -preview -tiled-width=128  sonic.png  sonic128
copy sonic128_tileset_preview.png sonic128_tiles.png /y
gfx2next -tile-size=8x8 -tile-norepeat -map-16bit -colors-4bit -pal-rgb332 sonic128_tiles.png
