extends SceneTree

func _init():
	var scene = load("res://maps/world_map.tscn")
	var root = scene.instantiate()
	
	root.set_script(load("res://maps/world_map.gd"))
	
	var new_scene = PackedScene.new()
	new_scene.pack(root)
	ResourceSaver.save(new_scene, "res://maps/world_map.tscn")
	print("Attached script to test map.")
	quit(0)
