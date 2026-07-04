import os

file_path = "assets/tilesets/level.tres"

with open(file_path, "r") as f:
    content = f.read()

# Replace the paths
content = content.replace("res://assets/levels/", "res://assets/tilesets/levels/")

with open(file_path, "w") as f:
    f.write(content)

print("Fixed paths in level.tres")
