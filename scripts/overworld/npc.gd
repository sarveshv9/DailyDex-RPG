extends CharacterBody2D
## NPC controller — supports idle animation, wandering, patrolling,
## and dialogue interaction. Uses AnimatedSprite2D from the new asset pack.

## NPC appearance: 0 = bug_catcher, 1 = gardener, 2 = worker
@export var npc_appearance: int = 2

## Movement type: 0 = standing, 1 = wander, 2 = patrol, 3 = look_around
@export var npc_movement_type: int = 0

## Dialogue messages
@export var dialogue_lines: Array[String] = ["Hello there!"]

## Is this NPC a healer?
@export var is_healer: bool = false

## Wander settings
@export var wander_origin: Vector2 = Vector2.ZERO
@export var wander_radius: float = 64.0
@export var wander_move_interval: float = 2.0

## Patrol settings
@export var patrol_points: Array[Vector2] = []
@export var patrol_move_interval: float = 2.0

## Look around interval
@export var look_around_interval: float = 3.5

## Direction names matching animation suffixes
var _dir_names: Array[String] = ["down", "left", "right", "up"]
var _facing_dir: int = 0
var _move_timer: float = 0.0
var _is_moving: bool = false
var _patrol_index: int = 0

## Spriteframe resource paths by appearance index
var _appearance_sprites: Array[String] = [
	"res://resources/spriteframes/bug_catcher.tres",
	"res://resources/spriteframes/gardener.tres",
	"res://resources/spriteframes/worker.tres",
]

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	# Load the correct SpriteFrames for this NPC's appearance
	if anim_sprite and npc_appearance < _appearance_sprites.size():
		var sf = load(_appearance_sprites[npc_appearance])
		if sf:
			anim_sprite.sprite_frames = sf
	_play_idle()
	_move_timer = randf() * wander_move_interval  # Stagger initial timers


func _process(delta: float) -> void:
	if _is_moving:
		return

	_move_timer += delta

	match npc_movement_type:
		0:  # Standing — just idle
			_play_idle()
		1:  # Wander
			if _move_timer >= wander_move_interval:
				_move_timer = 0.0
				_wander_step()
		2:  # Patrol
			if _move_timer >= patrol_move_interval:
				_move_timer = 0.0
				_patrol_step()
		3:  # Look around
			if _move_timer >= look_around_interval:
				_move_timer = 0.0
				_look_random()


func _play_idle() -> void:
	var anim_name := "idle_" + _dir_names[_facing_dir]
	if anim_sprite and anim_sprite.sprite_frames:
		if anim_sprite.sprite_frames.has_animation(anim_name):
			if anim_sprite.animation != anim_name:
				anim_sprite.play(anim_name)


func _play_walk() -> void:
	var anim_name := "walk_" + _dir_names[_facing_dir]
	if anim_sprite and anim_sprite.sprite_frames:
		if anim_sprite.sprite_frames.has_animation(anim_name):
			if anim_sprite.animation != anim_name:
				anim_sprite.play(anim_name)


func _look_random() -> void:
	_facing_dir = randi() % 4
	_play_idle()


func _wander_step() -> void:
	# Pick a random direction
	var dirs := [Vector2(0, -1), Vector2(0, 1), Vector2(-1, 0), Vector2(1, 0)]
	var dir_idx := randi() % 4
	var dir: Vector2 = dirs[dir_idx]
	_facing_dir = dir_idx  # 0=up mapped to down here, let's fix:
	# Map: 0=up→3, 1=down→0, 2=left→1, 3=right→2
	var dir_map := [3, 0, 1, 2]
	_facing_dir = dir_map[dir_idx]

	var target := position + dir * 16.0
	# Check if target is within wander radius
	var origin := wander_origin if wander_origin != Vector2.ZERO else position
	if target.distance_to(origin) > wander_radius:
		_play_idle()
		return

	_move_to(target)


func _patrol_step() -> void:
	if patrol_points.is_empty():
		return

	var target: Vector2 = patrol_points[_patrol_index]
	var diff := target - position

	if diff.length() < 2.0:
		_patrol_index = (_patrol_index + 1) % patrol_points.size()
		_play_idle()
		return

	# Face toward the target
	if abs(diff.x) > abs(diff.y):
		_facing_dir = 2 if diff.x > 0 else 1  # right or left
	else:
		_facing_dir = 0 if diff.y > 0 else 3  # down or up

	# Move one tile toward the target
	var step := diff.normalized() * 16.0
	_move_to(position + step)


func _move_to(target: Vector2) -> void:
	_is_moving = true
	_play_walk()

	var tween := create_tween()
	tween.tween_property(self, "position", target, 0.3)
	tween.tween_callback(_on_move_done)


func _on_move_done() -> void:
	_is_moving = false
	position = position.round()
	_play_idle()


## Get dialogue lines for interaction
func get_messages() -> Array[String]:
	return dialogue_lines
