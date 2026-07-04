import re

def render_layer(file_path, layer_name):
    with open(file_path, 'r') as f:
        content = f.read()

    match = re.search(f'layer_{layer_name}/tile_data = PackedInt32Array\((.*?)\)', content, re.DOTALL)
    if not match:
        print(f"Layer {layer_name} not found")
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
        grid[(x,y)] = data[i+2] # atlas coords
        
    if not grid:
        return
        
    min_x = min(x for x, y in grid.keys())
    max_x = max(x for x, y in grid.keys())
    min_y = min(y for x, y in grid.keys())
    max_y = max(y for x, y in grid.keys())

    print(f"--- Layer {layer_name} ---")
    header = "    | "
    for x in range(min_x, max_x + 1):
        header += f"{x:5} "
    print(header)
    for y in range(min_y, max_y + 1):
        row = []
        for x in range(min_x, max_x + 1):
            if (x, y) in grid:
                val = grid[(x, y)]
                ax = val & 0xFFFF
                ay = (val >> 16) & 0xFFFF
                row.append(f"{ax:2},{ay:2}")
            else:
                row.append("     ")
        print(f"{y:3} | " + " ".join(row))

render_layer('scenes/world/test_interior.tscn', '0')
render_layer('scenes/world/test_interior.tscn', '1')
render_layer('scenes/world/test_interior.tscn', '2')
