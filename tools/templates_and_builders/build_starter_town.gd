extends SceneTree

func _init():
	print("Building starter_town...")
	
	# Load resources
	var tileset = load("res://maps/tilesets/level.tres")
	if tileset == null:
		printerr("Failed to load level.tres")
		quit(1)
		return
		
	var player_scene = load("res://characters/player/player.tscn")
	
	# Create map root
	var map_root = Node2D.new()
	map_root.name = "StarterTown"
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
		
	# Save the scene
	var final_scene = PackedScene.new()
	final_scene.pack(map_root)
	var err = ResourceSaver.save(final_scene, "res://maps/towns/town_01/town_01.tscn")
	
	if err != OK:
		printerr("Failed to save starter_town.tscn")
		quit(1)
		return
		
	print("Starter town built successfully.")
	quit(0)
