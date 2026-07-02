extends Node2D
## Lightweight effects manager for grass rustle and footstep dust.
## Spawns procedural visual effects that auto-free after their animation.

const TILE_SIZE := 16


func spawn_grass_rustle(world_pos: Vector2) -> void:
	## Spawn 3-4 small grass blade arcs at the given tile position.
	var effect := Node2D.new()
	effect.position = world_pos + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.8)
	effect.z_index = 10
	add_child(effect)
	
	var blade_count := randi_range(3, 5)
	for i in range(blade_count):
		var blade := _GrassBlade.new()
		blade.offset_x = randf_range(-5.0, 5.0)
		blade.offset_y = randf_range(-2.0, 1.0)
		blade.direction = -1.0 if randf() < 0.5 else 1.0
		blade.blade_color = Color(0.35, 0.75, 0.30, 0.9)
		effect.add_child(blade)
	
	# Fade and free after animation
	var tween := create_tween()
	tween.tween_interval(0.35)
	tween.tween_callback(effect.queue_free)


func spawn_footstep_dust(world_pos: Vector2) -> void:
	## Spawn small dust puff particles at the given tile position.
	var effect := Node2D.new()
	effect.position = world_pos + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.9)
	effect.z_index = 5
	add_child(effect)
	
	var particle_count := randi_range(3, 5)
	for i in range(particle_count):
		var dust := _DustParticle.new()
		dust.velocity = Vector2(randf_range(-12.0, 12.0), randf_range(-8.0, -2.0))
		dust.particle_color = Color(0.72, 0.63, 0.48, 0.6)
		dust.particle_size = randf_range(1.0, 2.5)
		effect.add_child(dust)
	
	var tween := create_tween()
	tween.tween_interval(0.5)
	tween.tween_callback(effect.queue_free)


# ---------------------------------------------------------------------------
# Inner helper classes
# ---------------------------------------------------------------------------

class _GrassBlade extends Node2D:
	var offset_x: float = 0.0
	var offset_y: float = 0.0
	var direction: float = 1.0
	var blade_color: Color = Color.GREEN
	var _time: float = 0.0
	var _duration: float = 0.35
	
	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()
	
	func _draw() -> void:
		var progress := _time / _duration
		if progress >= 1.0:
			return
		
		var alpha := 1.0 - progress
		var sway := sin(progress * PI) * direction * 4.0
		
		var base := Vector2(offset_x, offset_y)
		var tip := base + Vector2(sway, -6.0 + progress * 3.0)
		
		var col := blade_color
		col.a = alpha * col.a
		draw_line(base, tip, col, 1.0)


class _DustParticle extends Node2D:
	var velocity: Vector2 = Vector2.ZERO
	var particle_color: Color = Color.WHITE
	var particle_size: float = 1.5
	var _time: float = 0.0
	var _duration: float = 0.45
	
	func _process(delta: float) -> void:
		_time += delta
		position += velocity * delta
		velocity *= 0.92  # friction
		queue_redraw()
	
	func _draw() -> void:
		var progress := _time / _duration
		if progress >= 1.0:
			return
		
		var alpha := 1.0 - progress * progress
		var col := particle_color
		col.a = alpha * col.a
		var sz := particle_size * (1.0 - progress * 0.5)
		draw_circle(Vector2.ZERO, sz, col)
