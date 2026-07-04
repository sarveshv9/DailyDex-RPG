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
signal player_moving_signal
signal player_stopped_signal
signal player_entering_door_signal
signal player_entered_door_signal

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

var shadow_sprite: Sprite2D
var jumping_over_ledge: bool = false
var door_entered: bool = false

func _ready() -> void:
	shadow_sprite = Sprite2D.new()
	shadow_sprite.texture = load("res://assets/player/player_shadow.png")
	shadow_sprite.visible = false
	shadow_sprite.z_index = -1
	# The shadow is usually drawn at the player's feet
	shadow_sprite.position = Vector2(0, 8) 
	add_child(shadow_sprite)
	
	position = Vector2(grid_pos.x * TILE_SIZE, grid_pos.y * TILE_SIZE)
	_play_idle()


func _process(_delta: float) -> void:
	if is_moving or input_locked or jumping_over_ledge or door_entered:
		return

	var direction := Vector2i.ZERO
	var new_facing_dir := facing_dir
	if Input.is_action_pressed("move_up"):
		direction = Vector2i(0, -1)
		new_facing_dir = 3
	elif Input.is_action_pressed("move_down"):
		direction = Vector2i(0, 1)
		new_facing_dir = 0
	elif Input.is_action_pressed("move_left"):
		direction = Vector2i(-1, 0)
		new_facing_dir = 1
	elif Input.is_action_pressed("move_right"):
		direction = Vector2i(1, 0)
		new_facing_dir = 2

	if direction != Vector2i.ZERO:
		if new_facing_dir != facing_dir:
			facing_dir = new_facing_dir
			_play_idle() # Face new direction
			input_locked = true
			get_tree().create_timer(0.08).timeout.connect(unlock_input)
		else:
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

	# Ledge Jumping Check
	if overworld.has_method("is_ledge_tile") and overworld.is_ledge_tile(target.x, target.y) and direction == Vector2i(0, 1):
		_do_ledge_jump()
		return

	# Obstacles / map edge
	if overworld.has_method("is_tile_walkable") and not overworld.is_tile_walkable(target.x, target.y):
		_bump_animation(direction)
		return

	# Door Check
	if overworld.has_method("is_door_tile") and overworld.is_door_tile(target.x, target.y):
		_do_door_entry(target)
		return

	# Commit to the normal move
	grid_pos = target
	is_moving = true
	player_moving_signal.emit()
	_play_walk()

	var tween := create_tween()
	tween.tween_property(
		self, "position",
		Vector2(target.x * TILE_SIZE, target.y * TILE_SIZE),
		MOVE_DURATION
	)
	tween.tween_callback(_on_move_finished)

func _do_ledge_jump() -> void:
	is_moving = true
	jumping_over_ledge = true
	player_moving_signal.emit()
	
	grid_pos.y += 2
	var start_pos = position
	var end_pos = Vector2(grid_pos.x * TILE_SIZE, grid_pos.y * TILE_SIZE)
	
	shadow_sprite.visible = true
	
	var tween = create_tween()
	tween.set_parallel(true)
	# Move X/Y horizontally and vertically
	tween.tween_property(self, "position:x", end_pos.x, 0.3)
	# Create parabolic arc for Y visually
	var arc_tween = create_tween()
	arc_tween.tween_property(self, "position:y", start_pos.y - 12.0, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	arc_tween.tween_property(self, "position:y", end_pos.y, 0.15).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	
	await arc_tween.finished
	
	# Landed
	shadow_sprite.visible = false
	jumping_over_ledge = false
	is_moving = false
	player_stopped_signal.emit()
	
	var dust = LandingDustEffect.new()
	dust.position = position
	get_tree().current_scene.add_child(dust)
	
	_play_idle()
	GameState.overworld_player_grid_pos = grid_pos
	move_finished_at.emit(grid_pos.x, grid_pos.y)

func _do_door_entry(target: Vector2i) -> void:
	is_moving = true
	door_entered = true
	player_moving_signal.emit()
	player_entering_door_signal.emit()
	
	var tween = create_tween()
	tween.tween_property(self, "position", Vector2(target.x * TILE_SIZE, target.y * TILE_SIZE), MOVE_DURATION)
	await tween.finished
	
	anim_sprite.visible = false
	player_entered_door_signal.emit()
	
	# The Door will handle the SceneManager transition.
	# We just stay invisible and locked until the scene unloads.


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
	player_stopped_signal.emit()
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
