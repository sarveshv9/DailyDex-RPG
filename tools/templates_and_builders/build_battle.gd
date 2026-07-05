extends SceneTree

func _init():
	print("Building Battle Scene...")
	var root = CanvasLayer.new()
	root.name = "BattleScene"
	root.set_script(load("res://battle/battle.gd"))
	
	# Background
	var bg = TextureRect.new()
	bg.name = "Background"
	bg.texture = load("res://ui/assets/battle_bg.png")
	bg.scale = Vector2(2, 2)
	bg.position = Vector2(0, 0)
	root.add_child(bg)
	bg.owner = root
	
	# Menu UI
	var menu = TextureRect.new()
	menu.name = "Menu"
	menu.texture = load("res://ui/assets/battle_menu.png")
	menu.scale = Vector2(2, 2)
	menu.position = Vector2(0, 270 - (48 * 2))
	root.add_child(menu)
	menu.owner = root
	
	# Player Sprite Slot (bottom left)
	var player_sprite = Sprite2D.new()
	player_sprite.name = "PlayerSlot"
	player_sprite.texture = load("res://characters/player/sprites/player.png")
	player_sprite.hframes = 12
	player_sprite.vframes = 2
	player_sprite.frame = 4 # Face up
	player_sprite.scale = Vector2(4, 4)
	player_sprite.position = Vector2(100, 180)
	root.add_child(player_sprite)
	player_sprite.owner = root
	
	# Enemy Sprite Slot (top right)
	var enemy_sprite = Sprite2D.new()
	enemy_sprite.name = "EnemySlot"
	enemy_sprite.texture = load("res://characters/npc/sprites/npc_01.png")
	enemy_sprite.hframes = 12
	enemy_sprite.vframes = 1
	enemy_sprite.frame = 1 # Face down
	enemy_sprite.scale = Vector2(4, 4)
	enemy_sprite.position = Vector2(380, 80)
	root.add_child(enemy_sprite)
	enemy_sprite.owner = root
	
	var scene = PackedScene.new()
	scene.pack(root)
	var err = ResourceSaver.save(scene, "res://battle/battle.tscn")
	if err != OK:
		printerr("Failed to save battle scene.")
		quit(1)
		return
	print("Battle scene generated.")
	quit(0)
