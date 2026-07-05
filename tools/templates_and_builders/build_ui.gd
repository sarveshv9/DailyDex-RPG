extends SceneTree

func _init():
	print("Building Dialogue UI...")
	var root = CanvasLayer.new()
	root.name = "DialogueUI"
	
	var script = load("res://ui/dialogue/dialogue_ui.gd")
	root.set_script(script)
	
	var bg = TextureRect.new()
	bg.name = "TextureRect"
	bg.texture = load("res://ui/assets/dialogue.png")
	# Viewport is 480x270. Box is 160x48. Scale by 3 to fit width 480, height 144
	bg.scale = Vector2(3, 3)
	bg.position = Vector2(0, 270 - 144) 
	root.add_child(bg)
	bg.owner = root
	
	var label = RichTextLabel.new()
	label.name = "RichTextLabel"
	# Because bg is scaled, local coordinates are unscaled! So size is 160x48
	label.position = Vector2(10, 10)
	label.size = Vector2(140, 28)
	label.scroll_active = false
	
	# Set font
	var font = load("res://assets/fonts/pokefont.ttf")
	label.add_theme_font_override("normal_font", font)
	label.add_theme_font_size_override("normal_font_size", 16)
	label.add_theme_color_override("default_color", Color.BLACK)
	
	bg.add_child(label)
	label.owner = root
	
	var timer = Timer.new()
	timer.name = "Timer"
	root.add_child(timer)
	timer.owner = root
	
	var scene = PackedScene.new()
	scene.pack(root)
	var err = ResourceSaver.save(scene, "res://ui/dialogue/dialogue_ui.tscn")
	if err != OK:
		printerr("Failed to save DialogueUI.")
		quit(1)
		return
	print("Dialogue UI built.")
	
	print("Injecting into test map...")
	var map_scene = load("res://maps/test_map.tscn")
	var map_root = map_scene.instantiate()
	
	# Load from disk so it acts as a true scene instance!
	var saved_ui_scene = load("res://ui/dialogue/dialogue_ui.tscn")
	var ui_instance = saved_ui_scene.instantiate()
	map_root.add_child(ui_instance)
	ui_instance.owner = map_root
	
	# Wire the NPC signal
	var npc = map_root.get_node("NPC")
	if npc:
		npc.connect("dialogue_requested", Callable(ui_instance, "show_dialogue"))
	
	var new_map = PackedScene.new()
	new_map.pack(map_root)
	ResourceSaver.save(new_map, "res://maps/test_map.tscn")
	
	print("Wired up and saved test map successfully.")
	quit(0)
