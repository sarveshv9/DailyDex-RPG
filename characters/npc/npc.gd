extends CharacterBody2D

signal dialogue_requested(text)

@export var dialogue_text: String = "Hello! I am a placeholder NPC."

@export_group("Sprite Frames")
@export var frame_down: int = 1
@export var frame_up: int = 4
@export var frame_left: int = 7
@export var frame_right: int = 10
@export var flip_right: bool = false

func interact(player):
	print("NPC interacted with!")
	
	if has_node("Sprite2D"):
		var sprite = $Sprite2D
		var p_facing = player.facing
		sprite.flip_h = false
		if p_facing == Vector2.UP:
			sprite.frame = frame_down
		elif p_facing == Vector2.DOWN:
			sprite.frame = frame_up
		elif p_facing == Vector2.RIGHT:
			sprite.frame = frame_left
		elif p_facing == Vector2.LEFT:
			if flip_right:
				sprite.frame = frame_left
				sprite.flip_h = true
			else:
				sprite.frame = frame_right
	
	dialogue_requested.emit(dialogue_text)
	if get_node_or_null("/root/DialogueUI"):
		get_node("/root/DialogueUI").show_dialogue(dialogue_text)
