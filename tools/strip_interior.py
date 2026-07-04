import re

file_path = "scenes/test_interior_base.tscn"

with open(file_path, "r") as f:
    lines = f.readlines()

new_lines = []
in_wanted_section = True
for line in lines:
    if line.startswith('[node name="dialouge_object_3"'):
        in_wanted_section = False
    if line.startswith('[node name="collision_polygon_2d" type="CollisionPolygon2D" parent="event_2"]'):
        in_wanted_section = False
        
    if in_wanted_section:
        new_lines.append(line)

with open(file_path, "w") as f:
    f.writelines(new_lines)

print("test_interior_base.tscn cleaned completely.")
