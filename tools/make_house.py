import os

with open('scenes/test_interior_base.tscn', 'r') as f:
    lines = f.readlines()

out_lines = []
ext_resources = [
    '[ext_resource type="PackedScene" path="res://scenes/player/player.tscn" id="2_fngo5"]\n',
    '[ext_resource type="Script" path="res://scripts/player.gd" id="3_ocnoe"]\n',
    '[ext_resource type="PackedScene" path="res://scenes/world/door.tscn" id="6_qs184"]\n',
    '[ext_resource type="Script" path="res://scripts/world/door.gd" id="7_vahb2"]\n'
]

inserted = False
for line in lines:
    if line.startswith('[sub_resource') and not inserted:
        out_lines.extend(ext_resources)
        out_lines.append('\n')
        inserted = True
    out_lines.append(line)

append_nodes = """
[node name="Player" type="CharacterBody2D" parent="." instance=ExtResource("2_fngo5")]
position = Vector2(72, 64)
collision_layer = 2
script = ExtResource("3_ocnoe")

[node name="Door" type="Area2D" parent="." instance=ExtResource("6_qs184")]
position = Vector2(72, 112)
collision_mask = 2
script = ExtResource("7_vahb2")
target_scene_path = "res://scenes/world/test_map.tscn"
target_spawn_position = Vector2(176, 144)
"""

out_lines.append(append_nodes)

with open('scenes/world/test_interior.tscn', 'w') as f:
    f.writelines(out_lines)

print("test_interior.tscn regenerated as a house.")
