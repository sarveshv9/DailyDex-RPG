extends Area2D
## Tall grass encounter zone — when the player walks over this tile,
## a random wild encounter may trigger.

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	# Start in "up" (undisturbed) state
	if anim_sprite:
		anim_sprite.play("up")


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("lock_input"):
		# Player stepped on tall grass — animate it
		if anim_sprite:
			anim_sprite.play("down")
		# Try to trigger an encounter through the level
		var level = _find_level()
		if level and level.has_method("trigger_encounter"):
			level.trigger_encounter()


func _on_body_exited(body: Node2D) -> void:
	if body.has_method("lock_input"):
		# Player left — restore grass
		if anim_sprite:
			anim_sprite.play("up")


func _find_level() -> Node:
	var parent = get_parent()
	while parent:
		if parent.has_method("trigger_encounter"):
			return parent
		parent = parent.get_parent()
	return null
