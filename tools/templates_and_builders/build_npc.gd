extends SceneTree

func _init():
	print("Building NPC scene...")
	var root = CharacterBody2D.new()
	root.name = "NPC"
	
	var script = load("res://characters/npc/npc.gd")
	root.set_script(script)
	
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = load("res://characters/npc/sprites/npc_01.png")
	# Using the selected 16x16 grid standard 192x20 strip or similar
	sprite.hframes = 12
	sprite.vframes = 1
	sprite.position = Vector2(0, -4)
	root.add_child(sprite)
	sprite.owner = root
	
	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape = RectangleShape2D.new()
	shape.size = Vector2(14, 14)
	collision.shape = shape
	root.add_child(collision)
	collision.owner = root
	
	# Layer 3 is NPC
	root.collision_layer = 4
	root.collision_mask = 1 # world_solid
	
	var scene = PackedScene.new()
	scene.pack(root)
	var err = ResourceSaver.save(scene, "res://characters/npc/npc.tscn")
	if err != OK:
		printerr("Failed to save NPC scene.")
		quit(1)
		return
	
	print("Injecting NPC into test map...")
	var map_scene = load("res://maps/world_map.tscn")
	var map_root = map_scene.instantiate()
	
	# Load from disk so it acts as a true scene instance!
	var saved_npc_scene = load("res://characters/npc/npc.tscn")
	var npc = saved_npc_scene.instantiate()
	# Place the NPC a few tiles to the right of the player (Player is at 15,10)
	npc.position = Vector2(16 * 18, 16 * 10)
	map_root.add_child(npc)
	npc.owner = map_root
	
	var new_map = PackedScene.new()
	new_map.pack(map_root)
	ResourceSaver.save(new_map, "res://maps/world_map.tscn")
	
	print("NPC built and injected successfully.")
	quit(0)
