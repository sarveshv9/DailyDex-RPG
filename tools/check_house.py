from PIL import Image
import sys

img = Image.open('assets/tilesets/levels/house.png').convert('RGB')
w, h = img.size
print(f"Size: {w}x{h}")

ascii_chars = " .:-=+*#%@"
out = ""
for y in range(0, h, 8):
    for x in range(0, w, 4):
        r, g, b = img.getpixel((x, y))
        brightness = int(0.299*r + 0.587*g + 0.114*b)
        idx = int(brightness / 255 * (len(ascii_chars)-1))
        out += ascii_chars[idx]
    out += "\n"
print(out)
