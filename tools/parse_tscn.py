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
    # unpack atlas_x and atlas_y
    atlas_x = val & 0xFFFF
    atlas_y = (val >> 16) & 0xFFFF
    
    # Handle negative coordinates just in case, though atlas shouldn't be negative
    if atlas_x >= 32768: atlas_x -= 65536
    if atlas_y >= 32768: atlas_y -= 65536
    
    atlas_coords.append((atlas_x, atlas_y))

counter = Counter(atlas_coords)
print("Most frequent tiles used in room_03_duplicate.tscn:")
for coord, count in counter.most_common(20):
    print(f"Tile {coord}: {count} times")
