import re
from collections import Counter

with open('_unused_assets/pokemon_emerald_godot-main/rooms/room_03_duplicate.tscn', 'r') as f:
    content = f.read()

# Get solid tiles
solid_tiles = set()
for line in content.split('\n'):
    if 'physics_layer_0/polygon_0/points' in line:
        # e.g. 0:1/0/physics_layer_0/polygon_0/points
        match = re.match(r'(\d+):(\d+)/0/physics', line)
        if match:
            solid_tiles.add((int(match.group(1)), int(match.group(2))))

# Get frequencies
matches = re.findall(r'tile_data = PackedInt32Array\(([\d\s,-]+)\)', content)
data = []
for m in matches:
    data.extend([int(x.strip()) for x in m.split(',')])

atlas_coords = []
for i in range(2, len(data), 3):
    val = data[i]
    if val < 0: val = val & 0xFFFFFFFF
    x = val & 0xFFFF
    y = (val >> 16) & 0xFFFF
    if x >= 32768: x -= 65536
    if y >= 32768: y -= 65536
    atlas_coords.append((x, y))

counter = Counter(atlas_coords)

solid_usage = []
for coord, count in counter.items():
    if coord in solid_tiles:
        solid_usage.append((coord, count))

solid_usage.sort(key=lambda x: x[1], reverse=True)
print("Most frequent solid tiles:")
for coord, count in solid_usage[:10]:
    print(f"Tile {coord}: {count} times")
    
# What are the non-solid tiles?
nonsolid_usage = []
for coord, count in counter.items():
    if coord not in solid_tiles:
        nonsolid_usage.append((coord, count))
        
nonsolid_usage.sort(key=lambda x: x[1], reverse=True)
print("\nMost frequent non-solid tiles:")
for coord, count in nonsolid_usage[:10]:
    print(f"Tile {coord}: {count} times")
