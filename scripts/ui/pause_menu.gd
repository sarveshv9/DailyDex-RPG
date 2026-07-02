extends CanvasLayer
## Simple pause menu for saving and loading the game.
## Listens for the "ui_cancel" (Escape/X) action to toggle visibility.

var panel: PanelContainer
var resume_btn: Button
var save_btn: Button
var load_btn: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Run even when game is paused
	layer = 100 # Draw above everything else
	visible = false
	_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	# Only allow pausing in the overworld (where game isn't already paused manually)
	# Wait, battle scene doesn't pause, but we only want pause menu in overworld.
	# Simplest approach: just toggle if Escape is pressed.
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()


func _build_ui() -> void:
	# --- Background Overlay ---
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.5)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# --- Centering Container ---
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	# --- Panel ---
	panel = PanelContainer.new()
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 12)
	vbox.add_child(title)

	# --- Buttons ---
	resume_btn = Button.new()
	resume_btn.text = "Resume"
	resume_btn.add_theme_font_size_override("font_size", 10)
	resume_btn.pressed.connect(_on_resume_pressed)
	vbox.add_child(resume_btn)

	save_btn = Button.new()
	save_btn.text = "Save Game"
	save_btn.add_theme_font_size_override("font_size", 10)
	save_btn.pressed.connect(_on_save_pressed)
	vbox.add_child(save_btn)

	load_btn = Button.new()
	load_btn.text = "Load Game"
	load_btn.add_theme_font_size_override("font_size", 10)
	load_btn.pressed.connect(_on_load_pressed)
	vbox.add_child(load_btn)


func _toggle_pause() -> void:
	# Update load button state based on save file existence
	load_btn.disabled = not FileAccess.file_exists("user://savegame.json")
	
	visible = not visible
	get_tree().paused = visible


func _on_resume_pressed() -> void:
	_toggle_pause()


func _on_save_pressed() -> void:
	GameState.save_game()
	var original_text = save_btn.text
	save_btn.text = "Saved!"
	await get_tree().create_timer(1.0).timeout
	save_btn.text = original_text


func _on_load_pressed() -> void:
	GameState.load_game()
	# load_game unpauses the tree and changes the scene, so just hide the menu
	visible = false
