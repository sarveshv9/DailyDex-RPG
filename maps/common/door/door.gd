extends Area2D

@export_file("*.tscn") var target_scene: String
@export var target_spawn_position: Vector2 = Vector2.ZERO
@export var texture: Texture2D

func _ready():
	if texture:
		$Sprite2D.texture = texture
		$Sprite2D.vframes = 3
		$Sprite2D.frame = 0
		$Sprite2D.visible = false
	else:
		$Sprite2D.visible = false

func _on_body_entered(body):
	if body.name == "Player":
		if target_scene != "":
			if texture and $AnimationPlayer.has_animation("open"):
				$Sprite2D.visible = true
				$AnimationPlayer.play("open")
				await $AnimationPlayer.animation_finished
			TransitionLayer.transition_to(target_scene, target_spawn_position)
		else:
			print("Target scene not set for door!")
