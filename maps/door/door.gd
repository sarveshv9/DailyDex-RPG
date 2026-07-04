extends Area2D
class_name Door

@export_file("*.tscn") var target_scene_path: String
@export var target_spawn_position: Vector2 = Vector2.ZERO

func _ready():
	# Ensure the door is listening on the correct mask
	# The player is on collision layer 2
	collision_mask = 2
	
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	if "Player" in body.name or body is CharacterBody2D:
		if target_scene_path != "":
			print("Door triggered! Moving to ", target_scene_path)
			var transition = get_node_or_null("/root/TransitionLayer")
			if transition:
				transition.transition_to(target_scene_path, target_spawn_position)
			else:
				get_tree().change_scene_to_file(target_scene_path)
