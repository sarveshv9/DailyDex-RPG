extends SceneTree

func _init():
	print("Building starter_village...")
	
	# Load resources
	var tileset = load("res://maps/tilesets/level.tres")
	if tileset == null:
		printerr("Failed to load level.tres")
		quit(1)
		return
		
	var player_scene = load("res://characters/player/player.tscn")
	var joy_scene = load("res://characters/npc/nurse_joy.tscn")
	var door_scene = load("res://maps/door/door.tscn")
	
	# Create map root
	var map_root = Node2D.new()
	map_root.name = "StarterVillage"
	map_root.y_sort_enabled = true
	
	# Create standard TileMapLayers
	var layers = [
		{"name": "Ground", "z": 0},
		{"name": "Paths", "z": 0},
		{"name": "Ledges", "z": 0},
		{"name": "Objects", "z": 0},
		{"name": "Buildings", "z": 0},
		{"name": "Trees", "z": 0, "y_sort": true},
		{"name": "Top", "z": 10} # Draws above the player
	]
	
	for l in layers:
		var layer = TileMapLayer.new()
		layer.name = l["name"]
		layer.tile_set = tileset
		layer.z_index = l["z"]
		if l.has("y_sort"):
			layer.y_sort_enabled = l["y_sort"]
		map_root.add_child(layer)
		layer.owner = map_root
		
	# Place Player
	if player_scene:
		var p = player_scene.instantiate()
		p.position = Vector2(160, 160)
		map_root.add_child(p)
		p.owner = map_root
		
	# Place Nurse Joy nearby
	if joy_scene:
		var joy = joy_scene.instantiate()
		joy.position = Vector2(128, 160)
		map_root.add_child(joy)
		joy.owner = map_root
		
	# Place Door (points to the interior map we already made)
	if door_scene:
		var d = door_scene.instantiate()
		d.position = Vector2(192, 160)
		d.target_scene_path = "res://maps/villages/small_village/interiors/test_interior.tscn"
		d.target_spawn_position = Vector2(72, 64)
		map_root.add_child(d)
		d.owner = map_root
		
	# Save the scene
	var final_scene = PackedScene.new()
	final_scene.pack(map_root)
	var err = ResourceSaver.save(final_scene, "res://maps/villages/starter_village/starter_village.tscn")
	
	if err != OK:
		printerr("Failed to save starter_village.tscn")
		quit(1)
		return
		
	print("Custom map built successfully.")
	quit(0)
