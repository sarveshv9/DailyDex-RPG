extends Area2D
## Scene trigger — warps the player to a different level/scene when entered.

## Which level scene to load (index into a level list or a scene path)
@export var target_level_name: int = 0
## Which trigger in the target level to spawn at
@export var target_level_trigger: int = 0
## This trigger's ID within the current level
@export var current_level_trigger: int = 0
## Direction the player enters from
@export var entry_direction: Vector2 = Vector2(0, 1)
## Whether this trigger is locked (disabled)
@export var locked: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if locked:
		return
	if body.has_method("lock_input"):
		# Warp the player
		body.lock_input()
		# Use TransitionLayer if available
		if Engine.has_singleton("TransitionLayer") or has_node("/root/TransitionLayer"):
			var tl = get_node_or_null("/root/TransitionLayer")
			if tl and tl.has_method("fade_out"):
				tl.fade_out()
				await tl.fade_finished
		# For now, just print — level loading can be expanded later
		print("SceneTrigger: Would warp to level ", target_level_name,
			" trigger ", target_level_trigger)
