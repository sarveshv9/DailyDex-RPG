extends CanvasLayer

signal fade_finished

var player_spawn_pos: Vector2 = Vector2.ZERO

@onready var color_rect = $ColorRect

func _ready():
	# Make sure it's always drawn on top of everything
	layer = 100
	
	# Start completely transparent
	color_rect.color = Color(0, 0, 0, 0)
	color_rect.hide()

func transition_to(scene_path: String, spawn_pos: Vector2 = Vector2.ZERO):
	# Save the target position globally
	player_spawn_pos = spawn_pos
	
	# Fade out (screen goes black)
	color_rect.show()
	var t = create_tween()
	t.tween_property(color_rect, "color", Color(0, 0, 0, 1), 0.3)
	await t.finished
	
	# Change the scene!
	get_tree().change_scene_to_file(scene_path)
	
	# Fade back in
	var t2 = create_tween()
	t2.tween_property(color_rect, "color", Color(0, 0, 0, 0), 0.3)
	await t2.finished
	color_rect.hide()
	
	fade_finished.emit()
