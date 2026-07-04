extends Node2D

func _ready():
	var player = get_node_or_null("Player")
	if player:
		player.connect("encounter_triggered", _on_encounter_triggered)

func _on_encounter_triggered():
	# Simulate a brief pause/flash before transitioning
	var tween = create_tween()
	tween.tween_interval(0.5)
	await tween.finished
	get_tree().change_scene_to_file("res://battle/battle.tscn")
