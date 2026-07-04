extends Node2D
## Overworld map — generates tile data, draws richly detailed Stardew Valley-style
## tiles procedurally, provides tile queries for the player script.

const TILE_SIZE := 16

enum Tile { GROUND, OBSTACLE, GRASS, WARP }

## 2-D array [row][col] of Tile values, generated in _ready.
var map_data: Array = []

## Grid position of the NPC (used for collision checks).
var npc_grid_pos: Vector2i = Vector2i(10, 7)

## Warp targets: { Vector2i(x, y): {"scene": path, "pos": Vector2i} }
var warps: Dictionary = {}

## Warp tile animation time
var _warp_time: float = 0.0

## Effects manager
var effects: Node2D = null

@onready var player: Node2D = $Player
@onready var npc: Node2D = get_node_or_null("NPC")
@onready var dialogue_box: CanvasLayer = get_node_or_null("DialogueBox")


func _ready() -> void:
	GameState.current_map_scene = scene_file_path
	_generate_map()
	_render_tilemap()

	# Spawn effects layer
	var EffectsScript := load("res://scripts/overworld/effects.gd")
	effects = Node2D.new()
	effects.set_script(EffectsScript)
	effects.name = "Effects"
	add_child(effects)

	# Place NPC at its grid position
	if npc:
		npc.position = Vector2(npc_grid_pos.x * TILE_SIZE, npc_grid_pos.y * TILE_SIZE)

	# Always restore player position from GameState
	player.grid_pos = GameState.overworld_player_grid_pos
	player.position = Vector2(
		player.grid_pos.x * TILE_SIZE,
		player.grid_pos.y * TILE_SIZE
	)

	# Camera limits — keep within the map
	var cam: Camera2D = player.get_node("Camera2D")
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = map_data[0].size() * TILE_SIZE
	cam.limit_bottom = map_data.size() * TILE_SIZE

	# Wire up signals
	player.interact_with_npc.connect(_on_player_interact_npc)
	if dialogue_box:
		dialogue_box.dialogue_finished.connect(_on_dialogue_finished)

	# Connect player movement for effects
	if player.has_signal("move_finished_at"):
		player.move_finished_at.connect(_on_player_move_finished_at)

	# Add warm-afternoon CanvasModulate
	var modulate := CanvasModulate.new()
	modulate.color = Color(1.0, 0.96, 0.88, 1.0)  # subtle warm tint
	add_child(modulate)

	queue_redraw()


func _process(_delta: float) -> void:
	_warp_time += _delta
	queue_redraw()  # Re-draw for warp animation

func _render_tilemap() -> void:
	var tm: TileMap = get_node_or_null("TileMap")
	if not tm: return
	
	tm.clear()
	var dirt_cells: Array[Vector2i] = []
	
	for y in range(map_data.size()):
		for x in range(map_data[y].size()):
			var pos = Vector2i(x, y)
			# Default background is grass
			var seed_val := x * 7919 + y * 6271
			var atlas_coord = Vector2i(0, 0)
			if _hash_float(seed_val, 10) > 0.85:
				atlas_coord = Vector2i(1, 0) # Flowers
			
			match map_data[y][x]:
				Tile.GRASS:
					tm.set_cell(0, pos, 0, atlas_coord)
				Tile.GROUND:
					dirt_cells.append(pos)
				Tile.OBSTACLE:
					tm.set_cell(0, pos, 0, Vector2i(2, 0)) # Tree
				Tile.WARP:
					tm.set_cell(0, pos, 0, atlas_coord) # Grass under warp
					
	# Execute autotiling for dirt paths
	tm.set_cells_terrain_connect(0, dirt_cells, 0, 0)


# ---------------------------------------------------------------------------
# Map generation
# ---------------------------------------------------------------------------

func _generate_map() -> void:
	var width := 20
	var height := 15
	map_data.clear()

	for y in range(height):
		var row: Array = []
		for x in range(width):
			if x == 0 or x == width - 1 or y == 0 or y == height - 1:
				# Border walls
				row.append(Tile.OBSTACLE)
			elif x >= 13 and x <= 17 and y >= 9 and y <= 12:
				# Grass patch (bottom-right)
				row.append(Tile.GRASS)
			elif x == 7 and y >= 3 and y <= 8:
				# Vertical internal wall
				row.append(Tile.OBSTACLE)
			elif y == 5 and x >= 10 and x <= 13:
				# Horizontal internal wall
				row.append(Tile.OBSTACLE)
			else:
				row.append(Tile.GROUND)
		map_data.append(row)

	# Add a warp to Map 2 at the top edge
	map_data[0][10] = Tile.WARP
	warps[Vector2i(10, 0)] = {
		"scene": "res://scenes/overworld/overworld2.tscn",
		"pos": Vector2i(5, 8)
	}


# ---------------------------------------------------------------------------
# Drawing — Rich Stardew Valley-style procedural tiles
# ---------------------------------------------------------------------------

func _draw() -> void:
	for y in range(map_data.size()):
		for x in range(map_data[y].size()):
			if map_data[y][x] == Tile.WARP:
				var rect := Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
				_draw_warp_tile(x, y, rect)


func _draw_warp_tile(x: int, y: int, rect: Rect2) -> void:
	# Animated glowing portal
	var pulse := (sin(_warp_time * 3.0) + 1.0) * 0.5  # 0..1 oscillation
	
	# Dark base
	var base_color := Color.from_hsv(0.75, 0.60, 0.25 + pulse * 0.10)
	draw_rect(rect, base_color)
	
	# Concentric glow rings
	var center := rect.position + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)
	
	# Outer glow
	var glow_color := Color.from_hsv(0.78, 0.50, 0.50 + pulse * 0.25)
	glow_color.a = 0.3 + pulse * 0.2
	draw_circle(center, 6.0, glow_color)
	
	# Inner bright core
	var core_color := Color.from_hsv(0.72 + pulse * 0.06, 0.40, 0.70 + pulse * 0.20)
	core_color.a = 0.5 + pulse * 0.3
	draw_circle(center, 3.0, core_color)
	
	# Bright center pixel
	var bright := Color.from_hsv(0.70, 0.20, 0.95)
	bright.a = 0.6 + pulse * 0.4
	draw_rect(Rect2(center.x - 1, center.y - 1, 2, 2), bright)
	
	# Sparkle particles around the portal
	for i in range(4):
		var angle := _warp_time * 2.0 + i * PI * 0.5
		var radius := 5.0 + sin(_warp_time * 4.0 + i) * 1.5
		var spark_pos := center + Vector2(cos(angle), sin(angle)) * radius
		var spark_alpha := 0.3 + pulse * 0.5
		draw_rect(
			Rect2(spark_pos.x, spark_pos.y, 1, 1),
			Color(0.85, 0.70, 1.0, spark_alpha)
		)
	
	# Arrow indicator pointing into the warp
	var arrow_y := rect.position.y + 2 + sin(_warp_time * 2.5) * 1.0
	var arrow_color := Color(1.0, 1.0, 1.0, 0.4 + pulse * 0.3)
	draw_line(
		Vector2(center.x - 3, arrow_y + 3),
		Vector2(center.x, arrow_y),
		arrow_color, 1.0
	)
	draw_line(
		Vector2(center.x + 3, arrow_y + 3),
		Vector2(center.x, arrow_y),
		arrow_color, 1.0
	)





# ---------------------------------------------------------------------------
# Hash utility — deterministic float from seed + offset
# ---------------------------------------------------------------------------

func _hash_float(seed_val: int, offset: int) -> float:
	## Returns a deterministic pseudo-random float in [0, 1) from seed + offset.
	var h := ((seed_val + offset * 15731) * 789221 + 1376312589) & 0x7FFFFFFF
	return float(h % 10000) / 10000.0


# ---------------------------------------------------------------------------
# Effects hooks (called by player)
# ---------------------------------------------------------------------------

func _on_player_move_finished_at(grid_x: int, grid_y: int) -> void:
	var world_pos := Vector2(grid_x * TILE_SIZE, grid_y * TILE_SIZE)
	if effects:
		if is_grass_tile(grid_x, grid_y):
			effects.spawn_grass_rustle(world_pos)
		else:
			effects.spawn_footstep_dust(world_pos)


# ---------------------------------------------------------------------------
# Tile queries (called by the player script)
# ---------------------------------------------------------------------------

func is_tile_walkable(grid_x: int, grid_y: int) -> bool:
	if grid_y < 0 or grid_y >= map_data.size():
		return false
	if grid_x < 0 or grid_x >= map_data[grid_y].size():
		return false
	return map_data[grid_y][grid_x] != Tile.OBSTACLE


func is_npc_at(grid_x: int, grid_y: int) -> bool:
	if not npc:
		return false
	return Vector2i(grid_x, grid_y) == npc_grid_pos


func is_warp_tile(grid_x: int, grid_y: int) -> bool:
	if grid_y < 0 or grid_y >= map_data.size():
		return false
	if grid_x < 0 or grid_x >= map_data[grid_y].size():
		return false
	return map_data[grid_y][grid_x] == Tile.WARP


func get_warp_data(grid_x: int, grid_y: int) -> Dictionary:
	return warps.get(Vector2i(grid_x, grid_y), {})


func is_grass_tile(grid_x: int, grid_y: int) -> bool:
	if grid_y < 0 or grid_y >= map_data.size():
		return false
	if grid_x < 0 or grid_x >= map_data[grid_y].size():
		return false
	return map_data[grid_y][grid_x] == Tile.GRASS


# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------

func _on_player_interact_npc() -> void:
	player.lock_input()
	if "is_healer" in npc and npc.is_healer:
		GameState.heal_party()
	dialogue_box.start(npc.dialogue_lines)


func _on_dialogue_finished() -> void:
	player.unlock_input()
