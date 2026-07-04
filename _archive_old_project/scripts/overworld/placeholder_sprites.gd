class_name PlaceholderSprites
extends Node
## Static utility class to generate placeholder sprite textures at runtime.
## This allows us to have animated characters before actual art assets are added.

static func generate_character_sprite(base_color: Color) -> Texture2D:
	# 64x64 image for 16x16 frames in a 4x4 grid
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	
	# 4 directions (0: down, 1: left, 2: right, 3: up)
	# 4 frames (0: idle, 1: walk1, 2: idle, 3: walk2)
	for dir in range(4):
		for frame in range(4):
			var px := frame * 16
			var py := dir * 16
			
			var head_color := base_color.lightened(0.2)
			var body_color := base_color
			var foot_color := base_color.darkened(0.4)
			
			# Idle animation: slight head bob
			var head_bob := 0
			if frame == 0 or frame == 2:
				head_bob = 1
			
			# Draw Body (base 8x8)
			for y in range(6, 12):
				for x in range(4, 12):
					img.set_pixel(px + x, py + y, body_color)
			
			# Draw Head (6x6)
			for y in range(2 + head_bob, 8 + head_bob):
				for x in range(5, 11):
					img.set_pixel(px + x, py + y, head_color)
			
			# Draw Eyes
			var eye_color := Color(0.1, 0.1, 0.1, 1.0)
			var eye_y := 4 + head_bob
			if dir == 0: # Down
				img.set_pixel(px + 6, py + eye_y, eye_color)
				img.set_pixel(px + 9, py + eye_y, eye_color)
			elif dir == 1: # Left
				img.set_pixel(px + 5, py + eye_y, eye_color)
			elif dir == 2: # Right
				img.set_pixel(px + 10, py + eye_y, eye_color)
			elif dir == 3: # Up
				pass # no eyes visible from back
			
			# Draw Feet & Animation
			var left_foot_y := py + 12
			var right_foot_y := py + 12
			
			# Animate feet up when walking
			if frame == 1:
				left_foot_y -= 1
			elif frame == 3:
				right_foot_y -= 1
				
			img.set_pixel(px + 5, left_foot_y, foot_color)
			img.set_pixel(px + 6, left_foot_y, foot_color)
			
			img.set_pixel(px + 9, right_foot_y, foot_color)
			img.set_pixel(px + 10, right_foot_y, foot_color)
			
			# Small shadow under feet
			var shadow_color := Color(0, 0, 0, 0.2)
			for sx in range(4, 12):
				img.set_pixel(px + sx, py + 14, shadow_color)
			
	return ImageTexture.create_from_image(img)
