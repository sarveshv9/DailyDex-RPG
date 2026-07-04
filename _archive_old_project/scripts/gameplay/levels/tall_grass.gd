extends Area2D
## Tall grass encounter zone with visual overlay and step effects

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
var grass_overlay: Sprite2D = null
var player_inside: bool = false
var player: Node2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if anim_sprite:
		anim_sprite.play("up")
		
func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.has_method("lock_input"):
		player = body
		player_inside = true
		if anim_sprite:
			anim_sprite.play("down")
			
		if not player.is_connected("player_moving_signal", _player_exiting_grass):
			player.player_moving_signal.connect(_player_exiting_grass)
		if not player.is_connected("player_stopped_signal", _player_in_grass):
			player.player_stopped_signal.connect(_player_in_grass)

func _on_body_exited(body: Node2D) -> void:
	if body == player:
		player_inside = false
		if anim_sprite:
			anim_sprite.play("up")
		
		if player.is_connected("player_moving_signal", _player_exiting_grass):
			player.player_moving_signal.disconnect(_player_exiting_grass)
		if player.is_connected("player_stopped_signal", _player_in_grass):
			player.player_stopped_signal.disconnect(_player_in_grass)
		
		_player_exiting_grass()

func _player_exiting_grass() -> void:
	if is_instance_valid(grass_overlay):
		grass_overlay.queue_free()
		grass_overlay = null

func _player_in_grass() -> void:
	if player_inside:
		var step_effect = load("res://scenes/effects/grass_step_effect.tscn").instantiate()
		step_effect.position = global_position
		get_tree().current_scene.add_child(step_effect)
		
		if not is_instance_valid(grass_overlay):
			grass_overlay = Sprite2D.new()
			grass_overlay.texture = load("res://assets/grass/stepped_tall_grass.png")
			grass_overlay.position = global_position
			grass_overlay.z_index = 10 # Draw over the player
			get_tree().current_scene.add_child(grass_overlay)

