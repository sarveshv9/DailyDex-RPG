class_name Door
extends Area2D

@export var next_scene_path: String = ""
@export var is_invisible: bool = false
@export var spawn_location: Vector2i = Vector2i(0, 0)
@export var spawn_direction: int = 0

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer

var player_inside: bool = false
var player: Node2D = null

func _ready() -> void:
	if is_invisible:
		sprite.texture = null
	sprite.visible = false
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_inside = true
		player = body
		if not player.is_connected("player_entering_door_signal", _enter_door):
			player.player_entering_door_signal.connect(_enter_door)
		if not player.is_connected("player_entered_door_signal", _close_door):
			player.player_entered_door_signal.connect(_close_door)

func _on_body_exited(body: Node2D) -> void:
	if body == player:
		player_inside = false
		if player.is_connected("player_entering_door_signal", _enter_door):
			player.player_entering_door_signal.disconnect(_enter_door)
		if player.is_connected("player_entered_door_signal", _close_door):
			player.player_entered_door_signal.disconnect(_close_door)
		player = null

func _enter_door() -> void:
	if player_inside:
		sprite.visible = true
		if anim_player.has_animation("OpenDoor"):
			anim_player.play("OpenDoor")

func _close_door() -> void:
	if player_inside:
		if anim_player.has_animation("CloseDoor"):
			anim_player.play("CloseDoor")
			await anim_player.animation_finished
		_door_closed()

func _door_closed() -> void:
	if player_inside:
		# Warp the player
		GameState.warp_to(next_scene_path, spawn_location)
		
		# Reset player visibility and state after warp finishes
		await TransitionLayer.fade_finished
		if is_instance_valid(player):
			player.anim_sprite.visible = true
			player.door_entered = false
			player.is_moving = false
			player.facing_dir = spawn_direction
			player._play_idle()
