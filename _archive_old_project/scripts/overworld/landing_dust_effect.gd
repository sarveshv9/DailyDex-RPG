class_name LandingDustEffect
extends AnimatedSprite2D

func _init() -> void:
	var tex = load("res://assets/player/jump_landing_dust.png")
	if not tex: return
	
	var frames = SpriteFrames.new()
	frames.add_animation("default")
	frames.set_animation_loop("default", false)
	frames.set_animation_speed("default", 12.0)
	
	var frame_width = 16
	var frame_count = tex.get_width() / frame_width
	for i in range(frame_count):
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * frame_width, 0, frame_width, tex.get_height())
		frames.add_frame("default", atlas)
		
	sprite_frames = frames

func _ready() -> void:
	play("default")
	animation_finished.connect(queue_free)
