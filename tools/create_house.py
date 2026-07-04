import os

scene_content = """[gd_scene load_steps=8 format=3 uid="uid://house_interior_uid"]

[ext_resource type="Texture2D" path="res://assets/tilesets/levels/house.png" id="1_house"]
[ext_resource type="PackedScene" path="res://scenes/player/player.tscn" id="2_fngo5"]
[ext_resource type="Script" path="res://scripts/player.gd" id="3_ocnoe"]
[ext_resource type="PackedScene" path="res://scenes/world/door.tscn" id="4_qs184"]
[ext_resource type="Script" path="res://scripts/world/door.gd" id="5_vahb2"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_wall_top"]
size = Vector2(215, 48)

[sub_resource type="RectangleShape2D" id="RectangleShape2D_wall_side"]
size = Vector2(16, 166)

[sub_resource type="RectangleShape2D" id="RectangleShape2D_wall_bot"]
size = Vector2(100, 32)

[sub_resource type="RectangleShape2D" id="RectangleShape2D_center_obj"]
size = Vector2(64, 48)

[node name="HouseInterior" type="Node2D"]

[node name="Background" type="Sprite2D" parent="."]
position = Vector2(107, 83)
texture = ExtResource("1_house")

[node name="StaticBody2D" type="StaticBody2D" parent="."]
collision_layer = 1
collision_mask = 0

[node name="TopWall" type="CollisionShape2D" parent="StaticBody2D"]
position = Vector2(107, 24)
shape = SubResource("RectangleShape2D_wall_top")

[node name="LeftWall" type="CollisionShape2D" parent="StaticBody2D"]
position = Vector2(8, 83)
shape = SubResource("RectangleShape2D_wall_side")

[node name="RightWall" type="CollisionShape2D" parent="StaticBody2D"]
position = Vector2(207, 83)
shape = SubResource("RectangleShape2D_wall_side")

[node name="BotWallLeft" type="CollisionShape2D" parent="StaticBody2D"]
position = Vector2(24, 150)
shape = SubResource("RectangleShape2D_wall_bot")

[node name="BotWallRight" type="CollisionShape2D" parent="StaticBody2D"]
position = Vector2(150, 150)
shape = SubResource("RectangleShape2D_wall_bot")

[node name="CenterObject" type="CollisionShape2D" parent="StaticBody2D"]
position = Vector2(107, 83)
shape = SubResource("RectangleShape2D_center_obj")

[node name="Player" parent="." instance=ExtResource("2_fngo5")]
position = Vector2(64, 120)
collision_layer = 2
script = ExtResource("3_ocnoe")

[node name="Door" parent="." instance=ExtResource("4_qs184")]
position = Vector2(64, 156)
collision_mask = 2
script = ExtResource("5_vahb2")
target_scene_path = "res://scenes/world/test_map.tscn"
target_spawn_position = Vector2(176, 144)
"""

with open('scenes/world/test_interior.tscn', 'w') as f:
    f.write(scene_content)

print("test_interior.tscn updated with house.png.")
