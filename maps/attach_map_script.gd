extends SceneTree

func _init():
	var scene = load("res://maps/test_map.tscn")
	var root = scene.instantiate()
	
	root.set_script(load("res://maps/test_map.gd"))
	
	var new_scene = PackedScene.new()
	new_scene.pack(root)
	ResourceSaver.save(new_scene, "res://maps/test_map.tscn")
	print("Attached script to test map.")
	quit(0)
