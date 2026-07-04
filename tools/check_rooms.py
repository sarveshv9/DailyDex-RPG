import re
import glob

def check_room(file_path):
    with open(file_path, 'r') as f:
        content = f.read()
    
    match = re.search(f'layer_0/tile_data = PackedInt32Array\((.*?)\)', content, re.DOTALL)
    if not match:
        return
        
    data_str = match.group(1).replace('\n', '').replace(' ', '')
    data = [int(x) for x in data_str.split(',') if x]
    
    grid = {}
    for i in range(0, len(data), 3):
        pos = data[i]
        if pos < 0: pos = pos & 0xFFFFFFFF
        x = pos & 0xFFFF
        y = (pos >> 16) & 0xFFFF
        if x >= 32768: x -= 65536
        if y >= 32768: y -= 65536
        grid[(x,y)] = data[i+2]
    
    if not grid: return
    w = max(x for x,y in grid.keys()) - min(x for x,y in grid.keys()) + 1
    h = max(y for x,y in grid.keys()) - min(y for x,y in grid.keys()) + 1
    print(f"{file_path}: {w}x{h} tiles")

for f in sorted(glob.glob('_unused_assets/pokemon_emerald_godot-main/rooms/room_*.tscn')):
    check_room(f)
