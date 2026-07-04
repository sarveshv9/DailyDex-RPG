from PIL import Image, ImageDraw
import random

TILE_SIZE = 16
IMG_W = 16 * 4
IMG_H = 16 * 8

img = Image.new("RGBA", (IMG_W, IMG_H), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

GRASS_COL = (80, 180, 110)
DIRT_COL = (210, 180, 120)
WATER_COL = (60, 120, 200)
TREE_COL = (40, 120, 60)

def draw_grass(dx, dy):
    for y in range(16):
        for x in range(16):
            c = GRASS_COL
            if random.random() > 0.8:
                c = (70, 160, 90) # darker
            draw.point((dx+x, dy+y), fill=c)
            
def draw_dirt(dx, dy):
    for y in range(16):
        for x in range(16):
            c = DIRT_COL
            if random.random() > 0.8:
                c = (190, 160, 100) # darker pebble
            draw.point((dx+x, dy+y), fill=c)

# Row 0: Grass, Flowers, Tree, Water
draw_grass(0, 0)
draw_grass(16, 0)
# draw flowers on 16,0
draw.rectangle([16+5, 5, 16+7, 7], fill=(240, 240, 100)) # yellow flower
draw.rectangle([16+10, 8, 16+12, 10], fill=(240, 100, 100)) # red flower

# Tree
for y in range(16):
    for x in range(16):
        draw.point((32+x, 0+y), fill=TREE_COL)
        if (x+y)%4 == 0:
            draw.point((32+x, 0+y), fill=(50, 140, 80))

# Water
for y in range(16):
    for x in range(16):
        c = WATER_COL
        if (x+y)%5 == 0:
            c = (80, 150, 220)
        draw.point((48+x, 0+y), fill=c)

# Rows 1-4: Dirt autotile (16 tiles)
# Bitmask mapping: Top=1, Bottom=2, Left=4, Right=8
# This covers all 16 states of "Match sides"
for i in range(16):
    tx = (i % 4) * 16
    ty = 16 + (i // 4) * 16
    draw_grass(tx, ty)
    
    top = (i & 1) != 0
    bottom = (i & 2) != 0
    left = (i & 4) != 0
    right = (i & 8) != 0
    
    for y in range(16):
        for x in range(16):
            is_dirt = True
            
            # Simple border
            if not left and x < 2: is_dirt = False
            if not right and x > 13: is_dirt = False
            if not top and y < 2: is_dirt = False
            if not bottom and y > 13: is_dirt = False
            
            # Corner rounding
            if not left and not top and x < 4 and y < 4:
                if (x-4)*(x-4) + (y-4)*(y-4) >= 16: is_dirt = False
            if not right and not top and x > 11 and y < 4:
                if (x-11)*(x-11) + (y-4)*(y-4) >= 16: is_dirt = False
            if not left and not bottom and x < 4 and y > 11:
                if (x-4)*(x-4) + (y-11)*(y-11) >= 16: is_dirt = False
            if not right and not bottom and x > 11 and y > 11:
                if (x-11)*(x-11) + (y-11)*(y-11) >= 16: is_dirt = False
                
            if is_dirt:
                c = DIRT_COL
                if random.random() > 0.9: c = (190, 160, 100)
                draw.point((tx+x, ty+y), fill=c)

# Add a dark shadow edge to dirt to make it pop like the GBA style
for i in range(16):
    tx = (i % 4) * 16
    ty = 16 + (i // 4) * 16
    for y in range(15):
        for x in range(16):
            c1 = img.getpixel((tx+x, ty+y))
            c2 = img.getpixel((tx+x, ty+y+1))
            # if transitioning from dirt to grass moving down
            if c1[0] > 150 and c2[0] < 100:
                draw.point((tx+x, ty+y+1), fill=(50, 120, 70)) # shadow

img.save("assets/tileset.png")
