import re
from collections import Counter

with open('_unused_assets/pokemon_emerald_godot-main/rooms/routes/arr_00.tscn', 'r') as f:
    content = f.read()

# Find all PackedInt32Arrays
matches = re.findall(r'tile_data = PackedInt32Array\(([\d\s,-]+)\)', content)
if not matches:
    print("No tile data found")
    exit()

data = []
for m in matches:
    data.extend([int(x.strip()) for x in m.split(',')])

atlas_coords = []
for i in range(2, len(data), 3):
    val = data[i]
    if val < 0:
        val = val & 0xFFFFFFFF
    
    atlas_x = val & 0xFFFF
    atlas_y = (val >> 16) & 0xFFFF
    
    if atlas_x >= 32768: atlas_x -= 65536
    if atlas_y >= 32768: atlas_y -= 65536
    
    atlas_coords.append((atlas_x, atlas_y))

counter = Counter(atlas_coords)
print("Checking specific tiles...")
print(f"Tile (14, 5): {counter.get((14, 5), 0)} times")
print(f"Tile (0, 1): {counter.get((0, 1), 0)} times")
print(f"Tile (1, 1): {counter.get((1, 1), 0)} times")
print(f"Tile (2, 1): {counter.get((2, 1), 0)} times")
print(f"Tile (6, 0): {counter.get((6, 0), 0)} times")
print(f"Tile (16, 9): {counter.get((16, 9), 0)} times")
