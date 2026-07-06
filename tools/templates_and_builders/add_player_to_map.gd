extends SceneTree

func _init():
	print("Injecting player into test map...")
	var scene = load("res://maps/world_map.tscn")
	var root = scene.instantiate()
	
	var player_scene = load("res://characters/player/player.tscn")
	var player = player_scene.instantiate()
	player.position = Vector2(16 * 15, 16 * 10) # Roughly center of the 30x20 map
	
	root.add_child(player)
	player.owner = root
	
	var new_scene = PackedScene.new()
	new_scene.pack(root)
	var err = ResourceSaver.save(new_scene, "res://maps/world_map.tscn")
	if err != OK:
		printerr("Failed to save map with player.")
		quit(1)
		return
		
	print("Added player to test map successfully.")
	quit(0)
