extends "res://scripts/overworld/overworld.gd"
## Second map for V2 testing — extends the base overworld to inherit
## drawing, queries, and initialization logic.

func _generate_map() -> void:
	var width := 10
	var height := 10
	map_data.clear()

	for y in range(height):
		var row: Array = []
		for x in range(width):
			if x == 0 or x == width - 1 or y == 0 or y == height - 1:
				# Border walls
				row.append(Tile.OBSTACLE)
			elif x >= 2 and x <= 7 and y >= 2 and y <= 4:
				# A small patch of grass
				row.append(Tile.GRASS)
			else:
				row.append(Tile.GROUND)
		map_data.append(row)

	# Warp back to Map 1 at the bottom edge
	map_data[9][5] = Tile.WARP
	warps[Vector2i(5, 9)] = {
		"scene": "res://scenes/overworld/overworld.tscn",
		"pos": Vector2i(10, 1) # Put them right below the warp tile on map 1
	}
