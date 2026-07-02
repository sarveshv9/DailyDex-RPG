class_name CreatureSprites
extends Node
## Procedural 64x64 creature sprites for battle.

static func generate_creature_sprite(element_type: String, base_color: Color) -> Texture2D:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var cx := 32
	var cy := 32
	
	if element_type == "Fire":
		_draw_fire_shape(img, cx, cy, base_color)
	elif element_type == "Water":
		_draw_water_shape(img, cx, cy, base_color)
	elif element_type == "Grass":
		_draw_grass_shape(img, cx, cy, base_color)
	else:
		_draw_normal_shape(img, cx, cy, base_color)
		
	# Draw basic face
	img.set_pixel(cx - 6, cy - 2, Color.BLACK)
	img.set_pixel(cx - 5, cy - 2, Color.BLACK)
	img.set_pixel(cx + 4, cy - 2, Color.BLACK)
	img.set_pixel(cx + 5, cy - 2, Color.BLACK)
	
	# Mouth
	var mouth_color := Color(0.2, 0.1, 0.1, 1.0)
	img.set_pixel(cx - 1, cy + 4, mouth_color)
	img.set_pixel(cx, cy + 4, mouth_color)

	return ImageTexture.create_from_image(img)


static func _draw_fire_shape(img: Image, cx: int, cy: int, c: Color) -> void:
	# Spiky, flame-like body
	for y in range(cy - 20, cy + 18):
		for x in range(cx - 20, cx + 21):
			var dist := Vector2(x - cx, y - cy).length()
			var y_factor := clampf((cy + 18 - y) / 38.0, 0.0, 1.0) # 0 at bottom, 1 at top
			var max_dist := 18.0 - (y_factor * 12.0)
			
			# Add noise to make it spiky
			var noise := sin(x * 1.5) * 5.0 * y_factor
			
			if dist + noise < max_dist:
				img.set_pixel(x, y, c)
			elif dist + noise < max_dist + 1.5:
				img.set_pixel(x, y, c.darkened(0.3))


static func _draw_water_shape(img: Image, cx: int, cy: int, c: Color) -> void:
	# Round, droplet-like body
	for y in range(cy - 18, cy + 16):
		for x in range(cx - 18, cx + 19):
			var dist := Vector2(x - cx, y - (cy + 2)).length()
			var max_dist := 16.0
			
			# Narrow at top
			if y < cy:
				max_dist -= (cy - y) * 0.4
				
			if dist < max_dist:
				img.set_pixel(x, y, c)
			elif dist < max_dist + 2.0:
				img.set_pixel(x, y, c.darkened(0.3))


static func _draw_grass_shape(img: Image, cx: int, cy: int, c: Color) -> void:
	# Bulb/leaf shape
	# First draw a leaf on top
	for y in range(cy - 24, cy - 8):
		for x in range(cx - 10, cx + 11):
			var l_dist := Vector2(x - cx, y - (cy - 16)).length()
			if l_dist < 6.0 + (y - (cy - 24)) * 0.2:
				img.set_pixel(x, y, Color(0.2, 0.8, 0.3))
				
	# Then the body
	for y in range(cy - 12, cy + 18):
		for x in range(cx - 20, cx + 21):
			var dist := Vector2(x - cx, y - cy).length()
			var max_dist := 18.0
			
			# slightly wider at bottom
			if y > cy:
				max_dist += (y - cy) * 0.2
				
			if dist < max_dist:
				img.set_pixel(x, y, c)
			elif dist < max_dist + 2.0:
				img.set_pixel(x, y, c.darkened(0.3))


static func _draw_normal_shape(img: Image, cx: int, cy: int, c: Color) -> void:
	# Generic round shape
	for y in range(cy - 16, cy + 16):
		for x in range(cx - 16, cx + 17):
			var dist := Vector2(x - cx, y - cy).length()
			if dist < 15.0:
				img.set_pixel(x, y, c)
			elif dist < 17.0:
				img.set_pixel(x, y, c.darkened(0.3))
