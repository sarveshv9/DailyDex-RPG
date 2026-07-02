extends CharacterBody2D
## Player controller — grid-based movement with AnimatedSprite2D,
## encounter checks, NPC interaction, and warp support.

const TILE_SIZE := 16
const MOVE_DURATION := 0.15
const ENCOUNTER_CHANCE := 0.10

var grid_pos: Vector2i = Vector2i(3, 3)
var is_moving: bool = false
var input_locked: bool = false

## Direction names matching animation suffixes
var _dir_names: Array[String] = ["down", "left", "right", "up"]
## Current facing direction index (0=down, 1=left, 2=right, 3=up)
var facing_dir: int = 0

signal interact_with_npc
signal move_finished_at(grid_x: int, grid_y: int)

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	position = Vector2(grid_pos.x * TILE_SIZE, grid_pos.y * TILE_SIZE)
	_play_idle()


func _process(_delta: float) -> void:
	if is_moving or input_locked:
		return

	var direction := Vector2i.ZERO
	if Input.is_action_pressed("move_up"):
		direction = Vector2i(0, -1)
		facing_dir = 3
	elif Input.is_action_pressed("move_down"):
		direction = Vector2i(0, 1)
		facing_dir = 0
	elif Input.is_action_pressed("move_left"):
		direction = Vector2i(-1, 0)
		facing_dir = 1
	elif Input.is_action_pressed("move_right"):
		direction = Vector2i(1, 0)
		facing_dir = 2

	if direction != Vector2i.ZERO:
		_try_move(direction)
	else:
		_play_idle()


func _play_idle() -> void:
	var anim_name := "idle_" + _dir_names[facing_dir]
	if anim_sprite and anim_sprite.animation != anim_name:
		anim_sprite.play(anim_name)


func _play_walk() -> void:
	var anim_name := "walk_" + _dir_names[facing_dir]
	if anim_sprite and anim_sprite.animation != anim_name:
		anim_sprite.play(anim_name)


func _try_move(direction: Vector2i) -> void:
	var target := grid_pos + direction
	var overworld := get_parent()

	# NPC blocks movement and triggers dialogue
	if overworld.has_method("is_npc_at") and overworld.is_npc_at(target.x, target.y):
		interact_with_npc.emit()
		_bump_animation(direction)
		return

	# Obstacles / map edge
	if overworld.has_method("is_tile_walkable") and not overworld.is_tile_walkable(target.x, target.y):
		_bump_animation(direction)
		return

	# Commit to the move
	grid_pos = target
	is_moving = true
	_play_walk()

	var tween := create_tween()
	tween.tween_property(
		self, "position",
		Vector2(target.x * TILE_SIZE, target.y * TILE_SIZE),
		MOVE_DURATION
	)
	tween.tween_callback(_on_move_finished)


func _bump_animation(dir: Vector2i) -> void:
	input_locked = true
	var orig := position
	var bump_target := orig + Vector2(dir) * 4.0
	var tween := create_tween()
	tween.tween_property(self, "position", bump_target, 0.06)
	tween.tween_property(self, "position", orig, 0.06)
	tween.tween_callback(unlock_input)


func _on_move_finished() -> void:
	is_moving = false
	# Snap to whole pixels to prevent sub-pixel shimmering
	position = position.round()
	# Persist position so we can restore it after battle
	GameState.overworld_player_grid_pos = grid_pos
	# Notify overworld for visual effects (grass rustle, dust)
	move_finished_at.emit(grid_pos.x, grid_pos.y)
	# Switch back to idle animation
	_play_idle()

	var overworld := get_parent()

	# Map transition check
	if overworld.has_method("is_warp_tile") and overworld.is_warp_tile(grid_pos.x, grid_pos.y):
		var warp_data: Dictionary = overworld.get_warp_data(grid_pos.x, grid_pos.y)
		if warp_data.has("scene") and warp_data.has("pos"):
			GameState.warp_to(warp_data["scene"], warp_data["pos"])
		return

	# Random encounter check on grass tiles
	if overworld.has_method("is_grass_tile") and overworld.is_grass_tile(grid_pos.x, grid_pos.y):
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
