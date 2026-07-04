from PIL import Image
import os

img = Image.open('assets/tilesets/exterior_tileset.png')
img = img.convert('RGB')
w, h = img.size

print(f"Image size: {w}x{h}")
cols = w // 16
rows = h // 16

def avg_color(x, y):
    box = (x*16, y*16, x*16+16, y*16+16)
    region = img.crop(box)
    colors = region.getcolors(256)
    if not colors:
        return (0,0,0)
    # Get dominant color
    colors.sort(key=lambda t: t[0], reverse=True)
    return colors[0][1]

def is_transparent(x, y):
    img_rgba = Image.open('assets/tilesets/exterior_tileset.png').convert('RGBA')
    box = (x*16, y*16, x*16+16, y*16+16)
    region = img_rgba.crop(box)
    colors = region.getcolors(256)
    if colors:
        for count, color in colors:
            if color[3] == 0 and count > 100: # Mostly transparent
                return True
    return False

print("Top left tiles dominant colors:")
for y in range(min(5, rows)):
    row_str = []
    for x in range(min(10, cols)):
        if is_transparent(x, y):
            row_str.append("TRANS")
        else:
            r,g,b = avg_color(x, y)
            if g > r and g > b:
                row_str.append("GREEN")
            elif r > g and r > b:
                row_str.append("RED  ")
            elif b > g and b > r:
                row_str.append("BLUE ")
            else:
                row_str.append("GREY ")
    print(f"Row {y}: " + " | ".join(row_str))
