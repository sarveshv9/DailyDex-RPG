extends SceneTree

func _init():
	print("Starting TileSet generation...")
	
	var img = Image.new()
	var err_img = img.load("res://assets/tileset.png")
	if err_img != OK:
		printerr("Failed to load assets/tileset.png")
		quit()
		return
	var tex = ImageTexture.create_from_image(img)
		
	# Create a TileSet and add a terrain set
	var ts = TileSet.new()
	ts.tile_size = Vector2i(16, 16)
	
	# Create terrain set 0 (Match sides)
	ts.add_terrain_set()
	ts.set_terrain_set_mode(0, TileSet.TERRAIN_MODE_MATCH_SIDES)
	
	# Add Terrain 0: Dirt Path
	ts.add_terrain(0)
	ts.set_terrain_name(0, 0, "Dirt Path")
	ts.set_terrain_color(0, 0, Color(0.8, 0.6, 0.2))
	
	# Create TileSetAtlasSource
	var source = TileSetAtlasSource.new()
	source.texture = tex
	source.texture_region_size = Vector2i(16, 16)
	
	# Create standalone tiles (Row 0)
	# 0,0 : Grass Base
	source.create_tile(Vector2i(0, 0))
	# 1,0 : Grass Flowers
	source.create_tile(Vector2i(1, 0))
	# 2,0 : Tree
	source.create_tile(Vector2i(2, 0))
	# 3,0 : Water
	source.create_tile(Vector2i(3, 0))
	
	# Create autotiles for Dirt Path (Rows 1 to 4)
	# They are a 4x4 block starting at (0, 1)
	# Our Python script bitmask:
	# i = x + y * 4
	# Top=1, Bottom=2, Left=4, Right=8
	# In Godot TileSet.TERRAIN_MODE_MATCH_SIDES, peercodes are:
	# PEER_BOTTOM_SIDE, PEER_LEFT_SIDE, PEER_TOP_SIDE, PEER_RIGHT_SIDE
	# The values are terrain IDs (so 0 for Dirt Path).
	
	for i in range(16):
		var tx = i % 4
		var ty = 1 + (i / 4)
		var atlas_coords = Vector2i(tx, ty)
		
		source.create_tile(atlas_coords)
		
		# Assign to terrain set 0
		var tile_data = source.get_tile_data(atlas_coords, 0)
		tile_data.terrain_set = 0
		tile_data.terrain = 0 # Center is dirt
		
		var top = (i & 1) != 0
		var bottom = (i & 2) != 0
		var left = (i & 4) != 0
		var right = (i & 8) != 0
		
		if top: tile_data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_TOP_SIDE, 0)
		if bottom: tile_data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, 0)
		if left: tile_data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_LEFT_SIDE, 0)
		if right: tile_data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_RIGHT_SIDE, 0)
		
	ts.add_source(source, 0)
	
	var err = ResourceSaver.save(ts, "res://assets/tileset.tres")
	if err == OK:
		print("Successfully saved res://assets/tileset.tres")
	else:
		printerr("Failed to save tileset.tres, error code: ", err)
		
	quit()
