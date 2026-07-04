extends SceneTree

func _init():
	print("Building player scene...")
	var root = CharacterBody2D.new()
	root.name = "Player"
	
	# Attach script
	var script = load("res://characters/player/player.gd")
	root.set_script(script)
	
	# Add Sprite
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	var texture = load("res://characters/player/sprites/player.png")
	sprite.texture = texture
	# Assuming 12 frames horizontally (3 frames per 4 directions)
	sprite.hframes = 12
	# For Emerald 192x44, if vframes = 2 it makes it 16x22
	sprite.vframes = 2 
	sprite.position = Vector2(0, -4) # Offset slightly so feet are at origin
	root.add_child(sprite)
	sprite.owner = root
	
	# Add CollisionShape2D
	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape = RectangleShape2D.new()
	shape.size = Vector2(14, 14) # Slightly smaller than 16x16
	collision.shape = shape
	root.add_child(collision)
	collision.owner = root
	
	# Add RayCast2D
	var ray = RayCast2D.new()
	ray.name = "RayCast2D"
	ray.target_position = Vector2(0, 16)
	ray.collision_mask = 1 # layer 1 is world_solid
	root.add_child(ray)
	ray.owner = root
	
	# Add Camera2D
	var camera = Camera2D.new()
	camera.name = "Camera2D"
	# Zoom in to make it feel like a GBA game (original res was 240x160)
	camera.zoom = Vector2(3.0, 3.0) 
	camera.position_smoothing_enabled = true
	# Map is 30x20 tiles (480x320 pixels)
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 30 * 16
	camera.limit_bottom = 20 * 16
	root.add_child(camera)
	camera.owner = root
	
	# Add AnimationPlayer
	var anim_player = AnimationPlayer.new()
	anim_player.name = "AnimationPlayer"
	var library = AnimationLibrary.new()
	
	# Helper to create animation
	var create_anim = func(anim_name, frames, loop=true):
		var anim = Animation.new()
		var track_idx = anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(track_idx, "Sprite2D:frame")
		anim.length = frames.size() * 0.15 # matches move speed roughly
		if loop:
			anim.loop_mode = Animation.LOOP_LINEAR
		
		for i in range(frames.size()):
			anim.track_insert_key(track_idx, i * 0.15, frames[i])
		return anim

	# Actual spritesheet layout: Down(0-2), Right(3-5), Up(6-8), Left(9-11)
	library.add_animation("idle_down", create_anim.call("idle_down", [1], false))
	library.add_animation("idle_right", create_anim.call("idle_right", [4], false))
	library.add_animation("idle_up", create_anim.call("idle_up", [7], false))
	library.add_animation("idle_left", create_anim.call("idle_left", [10], false))
	
	library.add_animation("walk_down", create_anim.call("walk_down", [0, 1, 2, 1]))
	library.add_animation("walk_right", create_anim.call("walk_right", [3, 4, 5, 4]))
	library.add_animation("walk_up", create_anim.call("walk_up", [6, 7, 8, 7]))
	library.add_animation("walk_left", create_anim.call("walk_left", [9, 10, 11, 10]))

	anim_player.add_animation_library("", library)
	root.add_child(anim_player)
	anim_player.owner = root
	
	# Set layers
	root.collision_layer = 2 # player
	root.collision_mask = 1 # world_solid
	
	# Save the scene
	var scene = PackedScene.new()
	scene.pack(root)
	var err = ResourceSaver.save(scene, "res://characters/player/player.tscn")
	if err != OK:
		printerr("Failed to save player scene.")
		quit(1)
		return
		
	print("Player scene saved successfully.")
	quit(0)
