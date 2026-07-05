extends CharacterBody2D

const TILE_SIZE = 16
const MOVE_SPEED = 0.15 # seconds per tile
const ENCOUNTER_CHANCE = 0.15

signal encounter_triggered

@onready var ray = $RayCast2D
@onready var anim = $AnimationPlayer
@onready var sprite = $Sprite2D

var is_moving = false
var facing = Vector2.DOWN

func _ready():
	# Mask 1 (world_solid) + Mask 4 (npc, which is layer 3 bit) = 5
	ray.collision_mask = 5
	
	var transition = get_node_or_null("/root/TransitionLayer")
	if transition and transition.player_spawn_pos != Vector2.ZERO:
		global_position = transition.player_spawn_pos
		transition.player_spawn_pos = Vector2.ZERO
		
	_play_idle(facing)
	
	# Automatically adjust camera limits based on the map's tilemap
	var camera = $Camera2D
	if camera:
		var map_parent = get_parent()
		var first_tilemap: TileMapLayer = null
		for child in map_parent.get_children():
			if child is TileMapLayer:
				first_tilemap = child
				break
				
		if first_tilemap and first_tilemap.tile_set:
			var used_rect = first_tilemap.get_used_rect()
			var tile_size = first_tilemap.tile_set.tile_size
			camera.limit_left = used_rect.position.x * tile_size.x
			camera.limit_top = used_rect.position.y * tile_size.y
			camera.limit_right = (used_rect.position.x + used_rect.size.x) * tile_size.x
			camera.limit_bottom = (used_rect.position.y + used_rect.size.y) * tile_size.y
func _physics_process(_delta):
	if is_moving:
		return
		
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		input_dir = Vector2.UP
	elif Input.is_action_pressed("move_down"):
		input_dir = Vector2.DOWN
	elif Input.is_action_pressed("move_left"):
		input_dir = Vector2.LEFT
	elif Input.is_action_pressed("move_right"):
		input_dir = Vector2.RIGHT
		
	if input_dir != Vector2.ZERO:
		_attempt_move(input_dir)
	else:
		_play_idle(facing)

func _attempt_interact():
	ray.target_position = facing * TILE_SIZE
	ray.force_raycast_update()
	
	if ray.is_colliding():
		var collider = ray.get_collider()
		if collider and collider.has_method("interact"):
			collider.interact(self)

func _unhandled_input(event):
	if event.is_action_pressed("interact") and not is_moving:
		_attempt_interact()

func _attempt_move(dir: Vector2):
	facing = dir
	_play_walk(facing)
	
	ray.target_position = dir * TILE_SIZE
	ray.force_raycast_update()
	
	if not ray.is_colliding():
		is_moving = true
		var target_pos = global_position + (dir * TILE_SIZE)
		
		var tween = create_tween()
		tween.tween_property(self, "global_position", target_pos, MOVE_SPEED).set_trans(Tween.TRANS_LINEAR)
		await tween.finished
		
		# Ensure we snap exactly to the target to prevent floating point drift
		global_position = target_pos
		is_moving = false
		
		# Check encounter zone (Phase 7 prep)
		_check_encounter()
		
func _play_idle(dir: Vector2):
	if dir == Vector2.UP:
		anim.play("idle_up")
	elif dir == Vector2.DOWN:
		anim.play("idle_down")
	elif dir == Vector2.LEFT:
		anim.play("idle_left")
	elif dir == Vector2.RIGHT:
		anim.play("idle_right")

func _play_walk(dir: Vector2):
	if dir == Vector2.UP:
		anim.play("walk_up")
	elif dir == Vector2.DOWN:
		anim.play("walk_down")
	elif dir == Vector2.LEFT:
		anim.play("walk_left")
	elif dir == Vector2.RIGHT:
		anim.play("walk_right")

func _check_encounter():
	# Check both "Ground" (new maps) and "GroundLayer" (old maps)
	var tilemap = get_parent().get_node_or_null("Ground") as TileMapLayer
	if not tilemap:
		tilemap = get_parent().get_node_or_null("GroundLayer") as TileMapLayer
	if not tilemap:
		return
		
	var tile_pos = tilemap.local_to_map(tilemap.to_local(global_position))
	var tile_data = tilemap.get_cell_tile_data(tile_pos)
	if tile_data and tile_data.get_custom_data("is_encounter_tile"):
		if randf() < ENCOUNTER_CHANCE:
			print("Wild Encounter Triggered!")
			encounter_triggered.emit()
