extends CanvasLayer
## Simple pause menu for saving and loading the game.
## Listens for the "ui_cancel" (Escape/X) action to toggle visibility.

var panel: PanelContainer
var center: CenterContainer
var resume_btn: Button
var save_btn: Button
var load_btn: Button
var party_btn: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Run even when game is paused
	layer = 100 # Draw above everything else
	visible = false
	_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()


func _build_ui() -> void:
	# --- Background Overlay ---
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.5)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# --- Centering Container ---
	center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	# --- Panel ---
	panel = PanelContainer.new()
	# Ensure pivoting around center for scale animations
	panel.pivot_offset = Vector2(60, 70) 
	center.add_child(panel)

	# Style the panel
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.15, 0.95)
	style.border_width_left = 2; style.border_width_top = 2
	style.border_width_right = 2; style.border_width_bottom = 2
	style.border_color = Color(0.85, 0.85, 0.80)
	style.corner_radius_top_left = 6; style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6; style.corner_radius_bottom_left = 6
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	title.add_theme_color_override("font_shadow_color", Color(0,0,0,0.8))
	title.add_theme_constant_override("shadow_offset_x", 1)
	title.add_theme_constant_override("shadow_offset_y", 1)
	vbox.add_child(title)

	# --- Buttons ---
	resume_btn = _make_btn("Resume", _on_resume_pressed)
	vbox.add_child(resume_btn)
	
	party_btn = _make_btn("Party", _on_party_pressed)
	vbox.add_child(party_btn)
	
	save_btn = _make_btn("Save Game", _on_save_pressed)
	vbox.add_child(save_btn)
	
	load_btn = _make_btn("Load Game", _on_load_pressed)
	vbox.add_child(load_btn)


func _make_btn(text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 10)
	btn.pressed.connect(callback)
	
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.2, 0.2, 0.25)
	sb.border_width_bottom = 2
	sb.border_color = Color(0.1, 0.1, 0.15)
	sb.corner_radius_top_left = 3; sb.corner_radius_bottom_right = 3
	sb.corner_radius_top_right = 3; sb.corner_radius_bottom_left = 3
	btn.add_theme_stylebox_override("normal", sb)
	
	var hover := sb.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.3, 0.3, 0.35)
	btn.add_theme_stylebox_override("hover", hover)
	
	var pressed := sb.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.15, 0.15, 0.2)
	pressed.border_width_bottom = 0
	pressed.border_width_top = 2
	btn.add_theme_stylebox_override("pressed", pressed)
	
	return btn


func _toggle_pause() -> void:
	load_btn.disabled = not FileAccess.file_exists("user://savegame.json")
	
	if not visible:
		visible = true
		get_tree().paused = true
		
		# Animate in
		panel.scale = Vector2(0.5, 0.5)
		panel.modulate.a = 0.0
		var t := create_tween().set_parallel(true)
		t.tween_property(panel, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		t.tween_property(panel, "modulate:a", 1.0, 0.15)
	else:
		# Animate out
		var t := create_tween().set_parallel(true)
		t.tween_property(panel, "scale", Vector2(0.8, 0.8), 0.15).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
		t.tween_property(panel, "modulate:a", 0.0, 0.15)
		t.chain().tween_callback(func():
			visible = false
			get_tree().paused = false
		)


func _on_resume_pressed() -> void:
	_toggle_pause()


func _on_party_pressed() -> void:
	visible = false
	PartyMenu.open()


func _on_save_pressed() -> void:
	GameState.save_game()
	var original_text = save_btn.text
	save_btn.text = "Saved!"
	save_btn.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	await get_tree().create_timer(1.0).timeout
	save_btn.text = original_text
	save_btn.remove_theme_color_override("font_color")


func _on_load_pressed() -> void:
	GameState.load_game()
	visible = false
