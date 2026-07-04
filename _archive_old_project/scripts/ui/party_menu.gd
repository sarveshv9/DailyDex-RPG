extends CanvasLayer
## UI to view party and swap creatures.
## Selected creature becomes the new lead (index 0).

var panel: PanelContainer
var vbox: VBoxContainer
var selected_index: int = -1
var buttons: Array[Button] = []
var CreatureSprites := preload("res://scripts/battle/creature_sprites.gd")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 101 # Above pause menu
	visible = false
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	panel = PanelContainer.new()
	panel.pivot_offset = Vector2(90, 80)
	center.add_child(panel)

	var style := StyleBoxTexture.new()
	style.texture = load("res://assets/ui/pokemon_party/party_background.png")
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "PARTY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	title.add_theme_color_override("font_shadow_color", Color(0,0,0,0.8))
	title.add_theme_constant_override("shadow_offset_x", 1)
	title.add_theme_constant_override("shadow_offset_y", 1)
	vbox.add_child(title)


func open() -> void:
	selected_index = -1
	_refresh_list()
	
	if not visible:
		visible = true
		
		# Animate in
		panel.scale = Vector2(0.5, 0.5)
		panel.modulate.a = 0.0
		var t := create_tween().set_parallel(true)
		t.tween_property(panel, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		t.tween_property(panel, "modulate:a", 1.0, 0.15)


func _refresh_list() -> void:
	# Clear old children except title
	for i in range(vbox.get_child_count() - 1, 0, -1):
		vbox.get_child(i).queue_free()
	buttons.clear()

	# Create new buttons for current party
	for i in range(GameState.party.size()):
		var creature: CreatureData = GameState.party[i]
		var hp: int = GameState.party_hp[i]
		
		var btn := TextureButton.new()
		btn.custom_minimum_size = Vector2(240, 50)
		btn.pressed.connect(_on_slot_pressed.bind(i))
		
		# Load textures
		var tex_normal: Texture2D
		if i == 0:
			tex_normal = load("res://assets/ui/pokemon_party/main_pokemon_background.png")
		else:
			tex_normal = load("res://assets/ui/pokemon_party/standby_pokemon_background.png")
			
		btn.texture_normal = tex_normal
		if i == selected_index:
			btn.modulate = Color(1.5, 1.5, 1.5) # Highlight selected
		
		# Inner Layout
		var hbox := HBoxContainer.new()
		hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		hbox.add_theme_constant_override("separation", 8)
		
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 20 if i == 0 else 10)
		margin.add_theme_constant_override("margin_top", 10)
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(hbox)
		btn.add_child(margin)
		
		# Mini sprite
		var tex_rect := TextureRect.new()
		var c_tex = null
		if "front_sprite" in creature:
			c_tex = creature.front_sprite
		tex_rect.texture = CreatureSprites.generate_creature_sprite(creature.element_type, creature.color, c_tex)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.custom_minimum_size = Vector2(32, 32)
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(tex_rect)
		
		# Info VBox
		var info := VBoxContainer.new()
		info.alignment = BoxContainer.ALIGNMENT_CENTER
		info.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(info)
		
		var name_lbl := Label.new()
		name_lbl.text = creature.creature_name
		name_lbl.add_theme_font_size_override("font_size", 10)
		name_lbl.add_theme_color_override("font_color", Color.WHITE)
		name_lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
		info.add_child(name_lbl)
		
		var hp_bar := TextureProgressBar.new()
		hp_bar.texture_under = load("res://assets/ui/pokemon_party/healthbar.png")
		hp_bar.texture_progress = load("res://assets/ui/pokemon_party/healthbar.png")
		hp_bar.tint_under = Color(0.2, 0.2, 0.2)
		hp_bar.max_value = creature.max_hp
		hp_bar.value = hp
		hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var pct := float(hp) / float(creature.max_hp)
		if pct > 0.5: hp_bar.tint_progress = Color(0.2, 0.8, 0.2)
		elif pct > 0.2: hp_bar.tint_progress = Color(0.8, 0.8, 0.2)
		else: hp_bar.tint_progress = Color(0.8, 0.2, 0.2)
		
		info.add_child(hp_bar)
		
		vbox.add_child(btn)
		# buttons.append(btn) - not needed since we clear dynamically

	# Close button
	var close_btn := TextureButton.new()
	close_btn.texture_normal = load("res://assets/ui/pokemon_party/exit_background_button.png")
	close_btn.pressed.connect(_on_close_pressed)
	vbox.add_child(close_btn)


func _on_slot_pressed(index: int) -> void:
	if selected_index == -1:
		selected_index = index
		_refresh_list()
	else:
		if selected_index != index:
			# Swap
			var temp_c = GameState.party[selected_index]
			var temp_hp = GameState.party_hp[selected_index]
			
			GameState.party[selected_index] = GameState.party[index]
			GameState.party_hp[selected_index] = GameState.party_hp[index]
			
			GameState.party[index] = temp_c
			GameState.party_hp[index] = temp_hp
			
		selected_index = -1
		_refresh_list()


func _on_close_pressed() -> void:
	var t := create_tween().set_parallel(true)
	t.tween_property(panel, "scale", Vector2(0.8, 0.8), 0.15).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	t.tween_property(panel, "modulate:a", 0.0, 0.15)
	t.chain().tween_callback(func():
		visible = false
		get_tree().paused = false
	)
