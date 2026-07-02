extends CanvasLayer
## UI to view party and swap creatures.
## Selected creature becomes the new lead (index 0).

var panel: PanelContainer
var vbox: VBoxContainer
var selected_index: int = -1
var buttons: Array[Button] = []


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
	center.add_child(panel)

	vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "PARTY (Click to swap)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 10)
	vbox.add_child(title)
	
	# Close button
	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.add_theme_font_size_override("font_size", 9)
	close_btn.pressed.connect(_on_close_pressed)
	vbox.add_child(close_btn)


func open() -> void:
	selected_index = -1
	_refresh_list()
	visible = true


func _refresh_list() -> void:
	# Clear old buttons
	for btn in buttons:
		btn.queue_free()
	buttons.clear()

	# Create new buttons for current party
	for i in range(GameState.party.size()):
		var creature: CreatureData = GameState.party[i]
		var hp: int = GameState.party_hp[i]
		
		var btn := Button.new()
		
		# e.g., "0: Flamelet (Fire) - 15/40 HP"
		# Indicate lead with a star if i == 0
		var prefix = "⭐ " if i == 0 else "   "
		btn.text = "%s%s (%s) - %d/%d HP" % [prefix, creature.creature_name, creature.element_type, hp, creature.max_hp]
		
		btn.add_theme_font_size_override("font_size", 9)
		btn.pressed.connect(_on_slot_pressed.bind(i))
		
		# Move it above the close button
		vbox.add_child(btn)
		vbox.move_child(btn, i + 1) # title is 0
		buttons.append(btn)


func _on_slot_pressed(index: int) -> void:
	if selected_index == -1:
		# Select first slot
		selected_index = index
		buttons[index].text = ">> " + buttons[index].text
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
	visible = false
	get_tree().paused = false
