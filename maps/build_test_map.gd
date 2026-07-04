extends SceneTree

func _init():
	print("Building test map from migrated test_map_base...")
	
	# Load the stripped base map
	var base_scene = load("res://maps/test_map_base.tscn")
	if base_scene == null:
		printerr("Failed to load test_map_base.tscn")
		quit(1)
		return
		
	var map_root = base_scene.instantiate()
	
	# Load our clean player
	var player_scene = load("res://characters/player/player.tscn")
	if player_scene == null:
		printerr("Failed to load player.tscn")
		quit(1)
		return
		
	var player = player_scene.instantiate()
	# Place the player somewhere reasonable on the map
	player.position = Vector2(224, 160)
	
	map_root.add_child(player)
	player.owner = map_root
	
	# Load the door scene
	var door_scene = load("res://maps/door/door.tscn")
	
	# Create exterior door to interior
	if door_scene != null:
		var ext_door = door_scene.instantiate()
		ext_door.position = Vector2(208, 128) # Near the player in exterior
		ext_door.target_scene_path = "res://maps/test_interior.tscn"
		ext_door.target_spawn_position = Vector2(72, 64) # Player spawns here inside
		map_root.add_child(ext_door)
		ext_door.owner = map_root
	
	
	# Load our clean Nurse Joy
	var joy_scene = load("res://characters/npc/nurse_joy.tscn")
	if joy_scene != null:
		var joy = joy_scene.instantiate()
		joy.position = Vector2(256, 160) # Placed right next to player
		map_root.add_child(joy)
		joy.owner = map_root
	
	# Save the final test map
	var final_scene = PackedScene.new()
	final_scene.pack(map_root)
	var err = ResourceSaver.save(final_scene, "res://maps/test_map.tscn")
	if err != OK:
		printerr("Failed to save final test_map.")
		quit(1)
		return
		
	print("Test map assembled and saved successfully.")
	
	# BUILD INTERIOR MAP
	print("Building test interior map from migrated test_interior_base...")
	var int_base = load("res://maps/test_interior_base.tscn")
	if int_base != null:
		var int_root = int_base.instantiate()
		var p2 = player_scene.instantiate()
		p2.position = Vector2(72, 64) # Typical indoor start position
		int_root.add_child(p2)
		p2.owner = int_root
		
		# Move Nurse Joy inside the interior map instead since it's a pokecenter!
		if joy_scene != null:
			var joy2 = joy_scene.instantiate()
			joy2.position = Vector2(72, 32)
			int_root.add_child(joy2)
			joy2.owner = int_root
			
		if door_scene != null:
			var int_door = door_scene.instantiate()
			int_door.position = Vector2(72, 112) # At the bottom of the interior room
			int_door.target_scene_path = "res://maps/test_map.tscn"
			int_door.target_spawn_position = Vector2(208, 144) # Spawns just below exterior door
			int_root.add_child(int_door)
			int_door.owner = int_root
			
		var int_final = PackedScene.new()
		int_final.pack(int_root)
		ResourceSaver.save(int_final, "res://maps/test_interior.tscn")
		print("Test interior map assembled and saved successfully.")

	quit(0)
