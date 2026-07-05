extends Area2D

@export_file("*.tscn") var target_scene: String
@export var spawn_position: Vector2 = Vector2.ZERO

func _on_body_entered(body):
	if body.name == "Player":
		if target_scene != "":
			TransitionLayer.transition_to(target_scene, spawn_position)
		else:
			print("Target scene not set for door!")
