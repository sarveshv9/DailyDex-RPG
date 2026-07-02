extends Node2D
## Player controller — grid-based movement, encounter checks, NPC interaction.

const TILE_SIZE := 16
const MOVE_DURATION := 0.15
const ENCOUNTER_CHANCE := 0.10

var grid_pos: Vector2i = Vector2i(3, 3)
var is_moving: bool = false
var input_locked: bool = false

signal interact_with_npc


func _ready() -> void:
	position = Vector2(grid_pos.x * TILE_SIZE, grid_pos.y * TILE_SIZE)


func _process(_delta: float) -> void:
	if is_moving or input_locked:
		return

	var direction := Vector2i.ZERO
	if Input.is_action_pressed("move_up"):
		direction = Vector2i(0, -1)
	elif Input.is_action_pressed("move_down"):
		direction = Vector2i(0, 1)
	elif Input.is_action_pressed("move_left"):
		direction = Vector2i(-1, 0)
	elif Input.is_action_pressed("move_right"):
		direction = Vector2i(1, 0)

	if direction != Vector2i.ZERO:
		_try_move(direction)


func _try_move(direction: Vector2i) -> void:
	var target := grid_pos + direction
	var overworld := get_parent()

	# NPC blocks movement and triggers dialogue
	if overworld.is_npc_at(target.x, target.y):
		interact_with_npc.emit()
		return

	# Obstacles / map edge
	if not overworld.is_tile_walkable(target.x, target.y):
		return

	# Commit to the move
	grid_pos = target
	is_moving = true

	var tween := create_tween()
	tween.tween_property(
		self, "position",
		Vector2(target.x * TILE_SIZE, target.y * TILE_SIZE),
		MOVE_DURATION
	)
	tween.tween_callback(_on_move_finished)


func _on_move_finished() -> void:
	is_moving = false
	# Persist position so we can restore it after battle
	GameState.overworld_player_grid_pos = grid_pos

	var overworld := get_parent()

	# Map transition check
	if overworld.has_method("is_warp_tile") and overworld.is_warp_tile(grid_pos.x, grid_pos.y):
		var warp_data: Dictionary = overworld.get_warp_data(grid_pos.x, grid_pos.y)
		if warp_data.has("scene") and warp_data.has("pos"):
			GameState.warp_to(warp_data["scene"], warp_data["pos"])
		return

	# Random encounter check on grass tiles
	if overworld.is_grass_tile(grid_pos.x, grid_pos.y):
		if randf() < ENCOUNTER_CHANCE:
			_trigger_encounter()


func _trigger_encounter() -> void:
	input_locked = true
	# Pick a random wild creature (duplicated so each battle is independent)
	var wild_pool: Array = [
		load("res://data/creatures/flamelet.tres"),
		load("res://data/creatures/aquapup.tres"),
		load("res://data/creatures/leafling.tres"),
	]
	var wild: CreatureData = wild_pool[randi() % wild_pool.size()].duplicate()
	GameState.start_battle(wild)


func lock_input() -> void:
	input_locked = true


func unlock_input() -> void:
	input_locked = false
