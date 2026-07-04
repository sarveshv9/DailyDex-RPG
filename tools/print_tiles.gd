extends SceneTree

func _init():
	var scene = load("res://_unused_assets/pokemon_emerald_godot-main/rooms/room_03_duplicate.tscn")
	if not scene:
		print("Failed to load arr_00")
		quit()
		return
		
	var root = scene.instantiate()
	var tilemap = null
	
	# Find TileMap or TileMapLayer
	for child in root.get_children():
		if child is TileMap or child is TileMapLayer:
			tilemap = child
			break
			
	if not tilemap:
		print("No tilemap found")
		quit()
		return
		
	var tally = {}
	# In Godot 4, TileMap or TileMapLayer has get_used_cells
	var cells = []
	if tilemap is TileMapLayer:
		cells = tilemap.get_used_cells()
	else:
		cells = tilemap.get_used_cells(0)
		
	for cell in cells:
		var atlas_coord
		if tilemap is TileMapLayer:
			atlas_coord = tilemap.get_cell_atlas_coords(cell)
		else:
			atlas_coord = tilemap.get_cell_atlas_coords(0, cell)
			
		if atlas_coord not in tally:
			tally[atlas_coord] = 0
		tally[atlas_coord] += 1
		
	# Sort by frequency
	var arr = []
	for k in tally.keys():
		arr.append({"coord": k, "count": tally[k]})
		
	arr.sort_custom(func(a, b): return a["count"] > b["count"])
	
	print("Most used tiles:")
	for i in range(min(10, arr.size())):
		print(arr[i]["coord"], ": ", arr[i]["count"])
		
	quit()
