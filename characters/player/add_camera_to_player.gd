extends SceneTree

func _init():
	print("Adding Camera2D to player...")
	var scene = load("res://characters/player/player.tscn")
	var root = scene.instantiate()
	
	var camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.zoom = Vector2(2, 2) # Makes it feel like GBA 240x135 resolution
	
	# Map is 30x20 tiles (480x320 pixels)
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 480
	camera.limit_bottom = 320
	
	root.add_child(camera)
	camera.owner = root
	
	var new_scene = PackedScene.new()
	new_scene.pack(root)
	var err = ResourceSaver.save(new_scene, "res://characters/player/player.tscn")
	if err != OK:
		printerr("Failed to save player with camera.")
		quit(1)
		return
		
	print("Added camera to player successfully.")
	quit(0)
