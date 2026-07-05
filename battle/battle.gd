extends CanvasLayer

func _ready():
	print("Battle skeleton loaded!")

func _input(event):
	if event.is_action_pressed("interact"):
		# Placeholder: Pressing interact in battle returns to the overworld
		print("Fled the battle!")
		get_tree().change_scene_to_file("res://maps/starter_village.tscn")
