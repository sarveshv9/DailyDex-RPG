extends Node2D
## Overworld map — generates tile data, draws colored rectangles, provides
## tile queries for the player script.

const TILE_SIZE := 16

enum Tile { GROUND, OBSTACLE, GRASS }

## 2-D array [row][col] of Tile values, generated in _ready.
var map_data: Array = []

## Grid position of the NPC (used for collision checks).
var npc_grid_pos: Vector2i = Vector2i(10, 7)

@onready var player: Node2D = $Player
@onready var npc: Node2D = $NPC
@onready var dialogue_box: CanvasLayer = $DialogueBox


func _ready() -> void:
	_generate_map()

	# Place NPC at its grid position
	npc.position = Vector2(npc_grid_pos.x * TILE_SIZE, npc_grid_pos.y * TILE_SIZE)

	# Restore player position when returning from battle
	if GameState.returning_from_battle:
		player.grid_pos = GameState.overworld_player_grid_pos
		player.position = Vector2(
			player.grid_pos.x * TILE_SIZE,
			player.grid_pos.y * TILE_SIZE
		)
		GameState.returning_from_battle = false

	# Camera limits — keep within the map
	var cam: Camera2D = player.get_node("Camera2D")
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = map_data[0].size() * TILE_SIZE
	cam.limit_bottom = map_data.size() * TILE_SIZE

	# Wire up signals
	player.interact_with_npc.connect(_on_player_interact_npc)
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)

	queue_redraw()


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


# ---------------------------------------------------------------------------
# Drawing (colored rectangles — placeholder visuals)
# ---------------------------------------------------------------------------

func _draw() -> void:
	for y in range(map_data.size()):
		for x in range(map_data[y].size()):
			var color: Color
			match map_data[y][x]:
				Tile.GROUND:
					color = Color(0.82, 0.71, 0.55)  # sandy tan
				Tile.OBSTACLE:
					color = Color(0.35, 0.30, 0.25)  # dark brown
				Tile.GRASS:
					color = Color(0.20, 0.65, 0.20)  # green
			draw_rect(
				Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE),
				color
			)
			# Subtle grid lines for clarity
			draw_rect(
				Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE),
				Color(0, 0, 0, 0.08),
				false
			)


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
	return Vector2i(grid_x, grid_y) == npc_grid_pos


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
	dialogue_box.start(npc.dialogue_lines)


func _on_dialogue_finished() -> void:
	player.unlock_input()
