import os

scene_content = """[gd_scene load_steps=10 format=3 uid="uid://b6314mpbb31q2"]

[ext_resource type="Texture2D" uid="uid://hnhs6kpc17t6" path="res://assets/tilesets/levels/pokemoncenter.png" id="1_pc"]
[ext_resource type="PackedScene" path="res://scenes/player/player.tscn" id="2_fngo5"]
[ext_resource type="Script" path="res://scripts/player.gd" id="3_ocnoe"]
[ext_resource type="PackedScene" path="res://scenes/characters/nurse_joy.tscn" id="4_nlnfn"]
[ext_resource type="Script" path="res://scripts/npc.gd" id="5_3kvmx"]
[ext_resource type="PackedScene" path="res://scenes/world/door.tscn" id="6_qs184"]
[ext_resource type="Script" path="res://scripts/world/door.gd" id="7_vahb2"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_wall_top"]
size = Vector2(256, 48)

[sub_resource type="RectangleShape2D" id="RectangleShape2D_wall_side"]
size = Vector2(16, 192)

[sub_resource type="RectangleShape2D" id="RectangleShape2D_desk"]
size = Vector2(80, 32)

[sub_resource type="RectangleShape2D" id="RectangleShape2D_pc"]
size = Vector2(32, 32)

[sub_resource type="RectangleShape2D" id="RectangleShape2D_wall_bot"]
size = Vector2(100, 32)

[node name="PokemonCenter" type="Node2D"]

[node name="Background" type="Sprite2D" parent="."]
position = Vector2(128, 96)
texture = ExtResource("1_pc")

[node name="StaticBody2D" type="StaticBody2D" parent="."]
collision_layer = 1
collision_mask = 0

[node name="TopWall" type="CollisionShape2D" parent="StaticBody2D"]
position = Vector2(128, 24)
shape = SubResource("RectangleShape2D_wall_top")

[node name="LeftWall" type="CollisionShape2D" parent="StaticBody2D"]
position = Vector2(8, 96)
shape = SubResource("RectangleShape2D_wall_side")

[node name="RightWall" type="CollisionShape2D" parent="StaticBody2D"]
position = Vector2(248, 96)
shape = SubResource("RectangleShape2D_wall_side")

[node name="Desk" type="CollisionShape2D" parent="StaticBody2D"]
position = Vector2(128, 80)
shape = SubResource("RectangleShape2D_desk")

[node name="PC" type="CollisionShape2D" parent="StaticBody2D"]
position = Vector2(216, 48)
shape = SubResource("RectangleShape2D_pc")

[node name="BotWallLeft" type="CollisionShape2D" parent="StaticBody2D"]
position = Vector2(50, 180)
shape = SubResource("RectangleShape2D_wall_bot")

[node name="BotWallRight" type="CollisionShape2D" parent="StaticBody2D"]
position = Vector2(206, 180)
shape = SubResource("RectangleShape2D_wall_bot")

[node name="Player" parent="." instance=ExtResource("2_fngo5")]
position = Vector2(128, 144)
collision_layer = 2
script = ExtResource("3_ocnoe")

[node name="NurseJoy" parent="." instance=ExtResource("4_nlnfn")]
position = Vector2(128, 48)
collision_layer = 2
collision_mask = 0
script = ExtResource("5_3kvmx")
dialogue_text = "Welcome to our Pokemon Center! We heal your Pokemon back to perfect health!"

[node name="Door" parent="." instance=ExtResource("6_qs184")]
position = Vector2(128, 184)
collision_mask = 2
script = ExtResource("7_vahb2")
target_scene_path = "res://scenes/world/test_map.tscn"
target_spawn_position = Vector2(208, 144)
"""

with open('scenes/world/test_interior.tscn', 'w') as f:
    f.write(scene_content)

print("test_interior.tscn updated.")
