extends CanvasLayer

var rect: ColorRect
signal fade_finished

func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	rect = ColorRect.new()
	rect.color = Color.BLACK
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.modulate.a = 0.0
	add_child(rect)

func fade_out(duration: float = 0.3) -> void:
	rect.color = Color.BLACK
	var t := create_tween()
	t.tween_property(rect, "modulate:a", 1.0, duration)
	await t.finished
	fade_finished.emit()

func fade_in(duration: float = 0.3) -> void:
	var t := create_tween()
	t.tween_property(rect, "modulate:a", 0.0, duration)
	await t.finished
	fade_finished.emit()

func battle_flash() -> void:
	# Flash white rapidly, then stay black
	rect.color = Color.WHITE
	rect.modulate.a = 1.0
	await get_tree().create_timer(0.05).timeout
	rect.modulate.a = 0.0
	await get_tree().create_timer(0.05).timeout
	rect.modulate.a = 1.0
	await get_tree().create_timer(0.05).timeout
	rect.modulate.a = 0.0
	await get_tree().create_timer(0.05).timeout
	
	rect.color = Color.BLACK
	rect.modulate.a = 1.0
	await get_tree().create_timer(0.1).timeout
	fade_finished.emit()
