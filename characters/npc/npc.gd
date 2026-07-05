extends CharacterBody2D

signal dialogue_requested(text)

@export var dialogue_text: String = "Hello! I am a placeholder NPC."

@export_group("Sprite Frames")
@export var frame_down: int = 1
@export var frame_up: int = 4
@export var frame_left: int = 7
@export var frame_right: int = 10
@export var flip_right: bool = false

@export_group("Walk Animations")
@export var anim_down: Array[int] = [0, 1, 2, 1]
@export var anim_up: Array[int] = [3, 4, 5, 4]
@export var anim_left: Array[int] = [6, 7, 8, 7]
@export var anim_right: Array[int] = [9, 10, 11, 10]

@export_group("Movement")
@export var can_move: bool = true
@export var move_radius: int = 3
@export var move_interval_min: float = 2.0
@export var move_interval_max: float = 5.0

var is_moving: bool = false
var start_pos: Vector2
var move_timer: Timer
var ray: RayCast2D

func _ready():
	start_pos = global_position
	
	if can_move:
		ray = RayCast2D.new()
		add_child(ray)
		ray.collision_mask = 7 # Matches World (1), Player (2), NPCs (4)
		
		move_timer = Timer.new()
		add_child(move_timer)
		move_timer.one_shot = true
		move_timer.timeout.connect(_on_move_timer_timeout)
		_start_move_timer()

func _start_move_timer():
	if move_timer:
		move_timer.start(randf_range(move_interval_min, move_interval_max))

func _on_move_timer_timeout():
	if is_moving:
		_start_move_timer()
		return
		
	var dirs = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var dir = dirs[randi() % 4]
	_attempt_move(dir)

func _attempt_move(dir: Vector2):
	var target_pos = global_position + (dir * 16)
	
	if target_pos.distance_to(start_pos) > (move_radius * 16) + 1:
		_start_move_timer()
		return
		
	ray.target_position = dir * 16
	ray.force_raycast_update()
	
	if not ray.is_colliding():
		is_moving = true
		var tween = create_tween()
		tween.tween_property(self, "global_position", target_pos, 0.3).set_trans(Tween.TRANS_LINEAR)
		tween.tween_callback(func(): 
			is_moving = false
			_start_move_timer()
		)
		
		if has_node("Sprite2D"):
			var sprite = $Sprite2D
			var anim_frames = []
			if dir == Vector2.UP:
				anim_frames = anim_up
			elif dir == Vector2.DOWN:
				anim_frames = anim_down
			elif dir == Vector2.RIGHT:
				anim_frames = anim_left if flip_right else anim_right
			elif dir == Vector2.LEFT:
				anim_frames = anim_left
				
			if anim_frames.size() > 0:
				var anim_tween = create_tween()
				var delay = 0.3 / anim_frames.size()
				for f in anim_frames:
					anim_tween.tween_callback(func(): sprite.frame = f)
					anim_tween.tween_interval(delay)
				anim_tween.tween_callback(func(): _face_dir(dir))
	else:
		_start_move_timer()

func _face_dir(dir: Vector2):
	if not has_node("Sprite2D"):
		return
	var sprite = $Sprite2D
	sprite.flip_h = false
	if dir == Vector2.UP:
		sprite.frame = frame_up
	elif dir == Vector2.DOWN:
		sprite.frame = frame_down
	elif dir == Vector2.RIGHT:
		if flip_right:
			sprite.frame = frame_left
			sprite.flip_h = true
		else:
			sprite.frame = frame_right
	elif dir == Vector2.LEFT:
		sprite.frame = frame_left

func interact(player):
	if is_moving:
		return

	print("NPC interacted with!")
	
	# Face the player!
	_face_dir(-player.facing)
	
	# Delay next move while interacting
	_start_move_timer()
	
	dialogue_requested.emit(dialogue_text)
	if get_node_or_null("/root/DialogueUI"):
		get_node("/root/DialogueUI").show_dialogue(dialogue_text)
