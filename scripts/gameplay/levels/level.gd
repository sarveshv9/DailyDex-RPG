extends Node2D
## Level script — manages encounter zones, spawn points, scene triggers,
## and NPC references. GDScript replacement for the original Level.cs.

## Encounter rate (percentage chance per step in tall grass)
@export var encounter_rate: int = 2

## Map boundaries (in pixels) for camera clamping
@export var bottom: int = 320
@export var right: int = 512

@onready var player: CharacterBody2D = null


func _ready() -> void:
	# Find the player node — it may be a direct child or spawned later
	player = _find_player()
	if player:
		_setup_camera()
		# Connect player movement for encounter checks
		if player.has_signal("move_finished_at"):
			player.move_finished_at.connect(_on_player_move_finished)


func _find_player() -> CharacterBody2D:
	# Look for player in the tree
	var p = get_node_or_null("Player")
	if p:
		return p
	# Try to find it as an autoload child or anywhere in the tree
	for child in get_children():
		if child is CharacterBody2D and child.has_method("lock_input"):
			return child
	return null


func _setup_camera() -> void:
	var cam: Camera2D = player.get_node_or_null("Camera2D")
	if cam:
		cam.limit_left = 0
		cam.limit_top = 0
		cam.limit_right = right
		cam.limit_bottom = bottom


func _on_player_move_finished(grid_x: int, grid_y: int) -> void:
	# Check if player is standing on tall grass (handled by TallGrass Area2D)
	pass


## Called by TallGrass areas when the player steps on them
func trigger_encounter() -> void:
	if player and randf() * 100.0 < encounter_rate:
		player._trigger_encounter()
