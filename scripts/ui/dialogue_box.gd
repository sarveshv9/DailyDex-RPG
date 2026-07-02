extends CanvasLayer
## A reusable dialogue box that displays lines of text one at a time.
## Press ui_accept (Enter) to advance. Emits `dialogue_finished` when done.

signal dialogue_finished

var panel: PanelContainer
var label: Label
var lines: Array = []
var current_line: int = 0
var is_active: bool = false


func _ready() -> void:
	_build_ui()
	panel.visible = false


func _build_ui() -> void:
	panel = PanelContainer.new()
	# Anchor to bottom of viewport, 50 px tall, 8 px margin on sides
	panel.anchor_left = 0.0
	panel.anchor_top = 1.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_top = -50.0
	panel.offset_left = 8.0
	panel.offset_right = -8.0
	panel.offset_bottom = -4.0
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 4)
	# Use container layout inside PanelContainer
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(margin)

	label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 10)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(label)


func start(dialogue_lines: Array) -> void:
	lines = dialogue_lines
	current_line = 0
	is_active = true
	panel.visible = true
	_show_line()


func _show_line() -> void:
	if current_line < lines.size():
		label.text = lines[current_line]
	else:
		_close()


func _close() -> void:
	is_active = false
	panel.visible = false
	dialogue_finished.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	if event.is_action_pressed("ui_accept"):
		current_line += 1
		_show_line()
		get_viewport().set_input_as_handled()
