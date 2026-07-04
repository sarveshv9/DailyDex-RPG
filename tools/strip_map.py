import re

file_path = "scenes/test_map_base.tscn"

with open(file_path, "r") as f:
    lines = f.readlines()

new_lines = []
skip_node = False
for line in lines:
    # Fix the tileset path
    if 'path="res://resources/tilesets/level.tres"' in line:
        line = line.replace('path="res://resources/tilesets/level.tres"', 'path="res://assets/tilesets/level.tres"')
    
    # Strip broken dependencies we don't want
    if line.startswith('[ext_resource') and not 'level.tres' in line:
        continue
    if line.startswith('[node name="Level"'):
        # Remove the broken script from the root node
        line = line.replace(' type="Node2D"]', ' type="Node2D"]')
    if line.startswith('script = ExtResource'):
        continue
    if line.startswith('encounter_rate ='):
        continue
    if line.startswith('bottom ='):
        continue
    if line.startswith('right ='):
        continue
        
    # Start skipping nodes we don't want
    if line.startswith('[node name="Boundaries"'):
        skip_node = True
    if line.startswith('[node name="SceneTriggers"'):
        skip_node = True
    if line.startswith('[node name="SpawnPoints"'):
        skip_node = True
    if line.startswith('[node name="Signs"'):
        skip_node = True
    if line.startswith('[node name="TallGrass"'):
        skip_node = True
    if line.startswith('[node name="NPCs"'):
        skip_node = True
    if line.startswith('[node name="Player"'):
        skip_node = True
    if line.startswith('[node name="MessageManager"'):
        skip_node = True
        
    # We only want the root, the Tiles node, and TileMapLayers.
    if skip_node:
        if line.startswith('[node') and not 'parent="Boundaries"' in line and not 'parent="SceneTriggers"' in line and not 'parent="SpawnPoints"' in line and not 'parent="Signs"' in line and not 'parent="TallGrass"' in line and not 'parent="NPCs"' in line:
            # If it's a new top-level node or something we want, stop skipping.
            # Wait, since the ones we want to skip are all at the bottom of small_town.tscn, we can just stop writing.
            # Let's be safe. All the Tiles are at the top, then Boundaries and everything else are below.
            if '[node name="Tiles"' in line or 'parent="Tiles"' in line:
                skip_node = False
            elif line.startswith('['): 
                # keep skipping other nodes
                pass

    if not skip_node:
        new_lines.append(line)

with open(file_path, "w") as f:
    f.writelines(new_lines)

print("test_map_base.tscn has been stripped of broken dependencies.")
