extends CanvasLayer
## A reusable dialogue box that displays lines of text one at a time.
## Press ui_accept (Enter) to advance. Emits `dialogue_finished` when done.

signal dialogue_finished

var panel: PanelContainer
var label: RichTextLabel
var arrow: Control
var lines: Array = []
var current_line: int = 0
var is_active: bool = false
var is_typing: bool = false
var text_tween: Tween
var chars_per_sec: float = 30.0
var arrow_time: float = 0.0


func _ready() -> void:
	_build_ui()
	panel.visible = false
	# Start off-screen
	panel.position.y += 60.0


func _process(delta: float) -> void:
	if not is_active: return
	if not is_typing and arrow.visible:
		arrow_time += delta
		arrow.position.y = panel.size.y - 8.0 + sin(arrow_time * 6.0) * 2.0
		arrow.queue_redraw()


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

	# Custom StyleBoxFlat for rounded corners and border
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.15, 0.9)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.85, 0.85, 0.80, 1.0)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)

	label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.scroll_active = false
	label.add_theme_font_size_override("normal_font_size", 10)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(label)
	
	# Arrow indicator (draws a small triangle)
	arrow = Control.new()
	arrow.draw.connect(_on_arrow_draw)
	panel.add_child(arrow)
	# Position will be updated in _process relative to panel bottom-right


func _on_arrow_draw() -> void:
	var pts := PackedVector2Array([
		Vector2(panel.size.x - 12, 0),
		Vector2(panel.size.x - 6, 0),
		Vector2(panel.size.x - 9, 3)
	])
	arrow.draw_polygon(pts, PackedColorArray([Color(0.9, 0.9, 0.85)]))


func start(dialogue_lines: Array) -> void:
	lines = dialogue_lines
	current_line = 0
	is_active = true
	panel.visible = true
	arrow.visible = false
	
	# Slide in from bottom
	var t := create_tween()
	t.tween_property(panel, "position:y", 180.0 - 50.0, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	_show_line()


func _show_line() -> void:
	if current_line < lines.size():
		label.text = lines[current_line]
		label.visible_ratio = 0.0
		is_typing = true
		arrow.visible = false
		
		var duration := float(label.text.length()) / chars_per_sec
		if text_tween:
			text_tween.kill()
		text_tween = create_tween()
		text_tween.tween_property(label, "visible_ratio", 1.0, duration)
		text_tween.tween_callback(func():
			is_typing = false
			arrow.visible = true
		)
	else:
		_close()


func _close() -> void:
	is_active = false
	if text_tween: text_tween.kill()
	arrow.visible = false
	
	# Slide out to bottom
	var t := create_tween()
	t.tween_property(panel, "position:y", 180.0 + 10.0, 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	t.tween_callback(func():
		panel.visible = false
		dialogue_finished.emit()
	)


func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	if event.is_action_pressed("ui_accept"):
		if is_typing:
			# Skip typing to full text
			if text_tween: text_tween.kill()
			label.visible_ratio = 1.0
			is_typing = false
			arrow.visible = true
		else:
			current_line += 1
			_show_line()
		get_viewport().set_input_as_handled()
