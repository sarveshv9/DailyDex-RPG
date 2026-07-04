extends Control
## Turn-based battle scene. Builds its entire UI programmatically so the .tscn
## file is minimal. Reads creature data from GameState.

enum BattleState { CHOOSING, ANIMATING, BATTLE_OVER }

var player_creature: CreatureData
var enemy_creature: CreatureData
var player_hp: int
var enemy_hp: int
var state: BattleState = BattleState.CHOOSING

# UI nodes
var player_sprite: Sprite2D
var enemy_sprite: Sprite2D
var player_hp_bar: ProgressBar
var enemy_hp_bar: ProgressBar
var player_name_label: Label
var enemy_name_label: Label
var player_hp_label: Label
var enemy_hp_label: Label
var move_btn_1: Button
var move_btn_2: Button
var catch_btn: Button
var battle_log: RichTextLabel
var battle_log_panel: PanelContainer
var moves_container: Control

var is_typing: bool = false
var text_tween: Tween
var CreatureSprites := preload("res://scripts/battle/creature_sprites.gd")

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_init_battle()

func _build_ui() -> void:
	# --- Gradient background & terrain ---
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.2, 0.35, 0.5) # sky
	add_child(bg)
	
	var sky2 := ColorRect.new()
	sky2.color = Color(0.15, 0.25, 0.4)
	sky2.position = Vector2(0, 0)
	sky2.size = Vector2(320, 60)
	add_child(sky2)

	var ground := ColorRect.new()
	ground.color = Color(0.25, 0.5, 0.3) # grass
	ground.position = Vector2(0, 100)
	ground.size = Vector2(320, 80)
	add_child(ground)
	
	var ground_top := ColorRect.new()
	ground_top.color = Color(0.3, 0.55, 0.35)
	ground_top.position = Vector2(0, 95)
	ground_top.size = Vector2(320, 5)
	add_child(ground_top)

	# --- Enemy creature (top-right) ---
	enemy_sprite = Sprite2D.new()
	enemy_sprite.position = Vector2(240, 50)
	add_child(enemy_sprite)

	# --- Player creature (bottom-left) ---
	player_sprite = Sprite2D.new()
	player_sprite.position = Vector2(70, 110)
	add_child(player_sprite)

	# --- Enemy info (top-left) ---
	enemy_name_label = _make_label(Vector2(10, 10), 11)
	enemy_hp_bar = _make_hp_bar(Vector2(10, 26), Vector2(120, 8))
	enemy_hp_label = _make_label(Vector2(10, 36), 8)

	# --- Player info (bottom-rightish) ---
	player_name_label = _make_label(Vector2(190, 90), 11)
	player_hp_bar = _make_hp_bar(Vector2(190, 106), Vector2(120, 8))
	player_hp_label = _make_label(Vector2(190, 116), 8)

	# --- Battle log (very bottom) ---
	battle_log_panel = PanelContainer.new()
	battle_log_panel.position = Vector2(4, 140)
	battle_log_panel.size = Vector2(200, 36)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	style.border_width_left = 2; style.border_width_top = 2
	style.border_width_right = 2; style.border_width_bottom = 2
	style.border_color = Color(0.8, 0.8, 0.8)
	style.corner_radius_top_left = 4; style.corner_radius_bottom_right = 4
	style.corner_radius_top_right = 4; style.corner_radius_bottom_left = 4
	battle_log_panel.add_theme_stylebox_override("panel", style)
	add_child(battle_log_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_top", 2)
	margin.add_theme_constant_override("margin_right", 4)
	battle_log_panel.add_child(margin)

	battle_log = RichTextLabel.new()
	battle_log.add_theme_font_size_override("normal_font_size", 9)
	battle_log.scroll_active = false
	margin.add_child(battle_log)

	# --- Move buttons & Catch container ---
	moves_container = Control.new()
	moves_container.position = Vector2(210, 130) # Will animate in from right
	add_child(moves_container)

	move_btn_1 = _make_styled_button(Vector2(0, 0), Vector2(106, 22))
	move_btn_2 = _make_styled_button(Vector2(0, 26), Vector2(106, 22))
	catch_btn = _make_styled_button(Vector2(-40, 0), Vector2(36, 48))
	
	moves_container.add_child(move_btn_1)
	moves_container.add_child(move_btn_2)
	moves_container.add_child(catch_btn)


func _make_label(pos: Vector2, font_size: int) -> Label:
	var lbl := Label.new()
	lbl.position = pos
	lbl.add_theme_font_size_override("font_size", font_size)
	# Add small shadow
	lbl.add_theme_color_override("font_shadow_color", Color(0,0,0,0.5))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	add_child(lbl)
	return lbl


func _make_hp_bar(pos: Vector2, sz: Vector2) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = pos
	bar.size = sz
	bar.show_percentage = false
	
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.2, 0.2, 0.2)
	bg.border_width_left = 1; bg.border_width_top = 1
	bg.border_width_right = 1; bg.border_width_bottom = 1
	bg.border_color = Color.BLACK
	bar.add_theme_stylebox_override("background", bg)
	
	var fg := StyleBoxFlat.new()
	fg.bg_color = Color(0.2, 0.8, 0.2)
	bar.add_theme_stylebox_override("fill", fg)
	
	add_child(bar)
	return bar


func _make_styled_button(pos: Vector2, sz: Vector2) -> Button:
	var btn := Button.new()
	btn.position = pos
	btn.size = sz
	btn.add_theme_font_size_override("font_size", 9)
	
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.25, 0.25, 0.3)
	normal.border_width_bottom = 2
	normal.border_color = Color(0.15, 0.15, 0.2)
	normal.corner_radius_top_left = 2; normal.corner_radius_top_right = 2
	normal.corner_radius_bottom_right = 2; normal.corner_radius_bottom_left = 2
	btn.add_theme_stylebox_override("normal", normal)
	
	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.15, 0.15, 0.2)
	pressed.border_width_bottom = 0
	pressed.border_width_top = 2
	btn.add_theme_stylebox_override("pressed", pressed)
	
	var hover := normal.duplicate()
	hover.bg_color = Color(0.3, 0.3, 0.35)
	btn.add_theme_stylebox_override("hover", hover)
	
	return btn


func _init_battle() -> void:
	player_creature = GameState.get_lead_creature()
	enemy_creature = GameState.wild_creature

	player_hp = GameState.party_hp[0]
	enemy_hp = enemy_creature.max_hp

	# Visuals
	var p_tex = null
	if "front_sprite" in player_creature:
		p_tex = player_creature.front_sprite
	player_sprite.texture = CreatureSprites.generate_creature_sprite(player_creature.element_type, player_creature.color, p_tex)
	
	var e_tex = null
	if "front_sprite" in enemy_creature:
		e_tex = enemy_creature.front_sprite
	enemy_sprite.texture = CreatureSprites.generate_creature_sprite(enemy_creature.element_type, enemy_creature.color, e_tex)
	
	player_name_label.text = "%s (%s)" % [player_creature.creature_name, player_creature.element_type]
	enemy_name_label.text = "%s (%s)" % [enemy_creature.creature_name, enemy_creature.element_type]
	
	player_hp_bar.max_value = player_creature.max_hp
	player_hp_bar.value = player_hp
	enemy_hp_bar.max_value = enemy_creature.max_hp
	enemy_hp_bar.value = enemy_hp
	_update_hp_text()

	# Move buttons coloring
	_style_type_button(move_btn_1, player_creature.element_type)
	if player_creature.moves.size() > 0:
		move_btn_1.text = player_creature.moves[0].move_name
		move_btn_1.pressed.connect(_on_move_selected.bind(0))
		
	if player_creature.moves.size() > 1:
		_style_type_button(move_btn_2, player_creature.element_type)
		move_btn_2.text = player_creature.moves[1].move_name
		move_btn_2.pressed.connect(_on_move_selected.bind(1))
	else:
		move_btn_2.visible = false

	catch_btn.text = "Catch"
	catch_btn.pressed.connect(_on_catch_pressed)
	if GameState.party.size() >= GameState.MAX_PARTY_SIZE:
		catch_btn.disabled = true

	# Slide in buttons
	moves_container.position.x = 350
	var t := create_tween()
	t.tween_property(moves_container, "position:x", 210, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	_type_log("A wild %s appeared!" % enemy_creature.creature_name)
	state = BattleState.CHOOSING


func _style_type_button(btn: Button, type: String) -> void:
	var col := Color(0.3, 0.3, 0.3)
	if type == "Fire": col = Color(0.8, 0.3, 0.2)
	elif type == "Water": col = Color(0.2, 0.4, 0.8)
	elif type == "Grass": col = Color(0.3, 0.7, 0.3)
	
	var sb := btn.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	sb.bg_color = col
	sb.border_color = col.darkened(0.4)
	btn.add_theme_stylebox_override("normal", sb)
	
	var hover := sb.duplicate() as StyleBoxFlat
	hover.bg_color = col.lightened(0.2)
	btn.add_theme_stylebox_override("hover", hover)


func _type_log(msg: String) -> void:
	battle_log.text = msg
	battle_log.visible_ratio = 0.0
	is_typing = true
	var duration := float(msg.length()) / 40.0
	if text_tween: text_tween.kill()
	text_tween = create_tween()
	text_tween.tween_property(battle_log, "visible_ratio", 1.0, duration)
	text_tween.tween_callback(func(): is_typing = false)


func _on_move_selected(move_index: int) -> void:
	if state != BattleState.CHOOSING or is_typing:
		return

	state = BattleState.ANIMATING
	_set_moves_enabled(false)

	# Hide buttons
	var t := create_tween()
	t.tween_property(moves_container, "position:x", 350, 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	await t.finished

	var player_move = player_creature.moves[move_index]

	if player_creature.speed >= enemy_creature.speed:
		await _execute_turn(player_creature, player_move, true)
		if enemy_hp > 0:
			var enemy_move = _pick_enemy_move()
			await _execute_turn(enemy_creature, enemy_move, false)
	else:
		var enemy_move = _pick_enemy_move()
		await _execute_turn(enemy_creature, enemy_move, false)
		if player_hp > 0:
			await _execute_turn(player_creature, player_move, true)

	if enemy_hp <= 0:
		state = BattleState.BATTLE_OVER
		_type_log("You won!")
		await get_tree().create_timer(1.5).timeout
		GameState.party_hp[0] = player_hp
		GameState.end_battle(true)
	elif player_hp <= 0:
		state = BattleState.BATTLE_OVER
		_type_log("You lost!")
		await get_tree().create_timer(1.5).timeout
		GameState.end_battle(false)
	else:
		state = BattleState.CHOOSING
		var t2 := create_tween()
		t2.tween_property(moves_container, "position:x", 210, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		_set_moves_enabled(true)


func _execute_turn(attacker: CreatureData, move: Resource, is_player_attacking: bool) -> void:
	_type_log("%s used %s!" % [attacker.creature_name, move.move_name])
	
	# Attack jump animation
	var sprite := player_sprite if is_player_attacking else enemy_sprite
	var orig_pos := sprite.position
	var t := create_tween()
	var jump_dir := Vector2(20, -10) if is_player_attacking else Vector2(-20, 10)
	t.tween_property(sprite, "position", orig_pos + jump_dir, 0.15).set_ease(Tween.EASE_OUT)
	t.tween_property(sprite, "position", orig_pos, 0.15).set_ease(Tween.EASE_IN)
	await t.finished
	await get_tree().create_timer(0.2).timeout

	var defender: CreatureData = enemy_creature if is_player_attacking else player_creature
	var multiplier := TypeChart.get_multiplier(move.element_type, defender.element_type)
	var damage := _calc_damage(attacker, move, defender, multiplier)

	var target_sprite := enemy_sprite if is_player_attacking else player_sprite
	var target_bar := enemy_hp_bar if is_player_attacking else player_hp_bar

	# Hit flash and shake
	var s := create_tween()
	target_sprite.modulate = Color(10, 10, 10)
	s.tween_property(target_sprite, "modulate", Color.WHITE, 0.15)
	
	var shake := create_tween()
	var tp := target_sprite.position
	shake.tween_property(target_sprite, "position", tp + Vector2(4, 0), 0.04)
	shake.tween_property(target_sprite, "position", tp + Vector2(-4, 0), 0.04)
	shake.tween_property(target_sprite, "position", tp + Vector2(3, 0), 0.04)
	shake.tween_property(target_sprite, "position", tp + Vector2(-3, 0), 0.04)
	shake.tween_property(target_sprite, "position", tp, 0.04)

	# Damage popup
	var dmg_lbl := Label.new()
	dmg_lbl.text = str(damage)
	dmg_lbl.add_theme_font_size_override("font_size", 12)
	dmg_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	dmg_lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
	dmg_lbl.position = target_sprite.position + Vector2(-10, -20)
	add_child(dmg_lbl)
	
	var float_tw := create_tween()
	float_tw.tween_property(dmg_lbl, "position:y", dmg_lbl.position.y - 20, 0.6).set_ease(Tween.EASE_OUT)
	var fade_tw := create_tween()
	fade_tw.tween_property(dmg_lbl, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN)
	fade_tw.tween_callback(dmg_lbl.queue_free)

	# Update HP
	if is_player_attacking:
		enemy_hp = maxi(0, enemy_hp - damage)
	else:
		player_hp = maxi(0, player_hp - damage)

	var hp_tw := create_tween()
	hp_tw.tween_property(target_bar, "value", float(enemy_hp if is_player_attacking else player_hp), 0.3)
	
	# Update bar color based on %
	var max_v := float(enemy_creature.max_hp if is_player_attacking else player_creature.max_hp)
	hp_tw.tween_method(_update_hp_bar_color.bind(target_bar, max_v), target_bar.value, float(enemy_hp if is_player_attacking else player_hp), 0.3)
	
	_update_hp_text()
	await get_tree().create_timer(0.6).timeout

	if multiplier > 1.0:
		_type_log("It's super effective!")
		await get_tree().create_timer(0.8).timeout
	elif multiplier < 1.0:
		_type_log("It's not very effective...")
		await get_tree().create_timer(0.8).timeout


func _update_hp_bar_color(val: float, bar: ProgressBar, max_v: float) -> void:
	var pct := val / max_v
	var fg := bar.get_theme_stylebox("fill") as StyleBoxFlat
	if pct > 0.5: fg.bg_color = Color(0.2, 0.8, 0.2)
	elif pct > 0.2: fg.bg_color = Color(0.8, 0.8, 0.2)
	else: fg.bg_color = Color(0.8, 0.2, 0.2)


func _on_catch_pressed() -> void:
	if state != BattleState.CHOOSING or is_typing:
		return

	state = BattleState.ANIMATING
	_set_moves_enabled(false)
	var t := create_tween()
	t.tween_property(moves_container, "position:x", 350, 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)

	_type_log("You threw a CatchBall!")
	await get_tree().create_timer(1.2).timeout

	var hp_percent := float(enemy_hp) / float(enemy_creature.max_hp)
	var chance := 1.15 - hp_percent
	
	if randf() < chance:
		_type_log("Gotcha! Caught %s!" % enemy_creature.creature_name)
		
		# Fade out enemy
		var fade := create_tween()
		fade.tween_property(enemy_sprite, "modulate:a", 0.0, 0.5)
		
		await get_tree().create_timer(1.5).timeout
		GameState.party.append(enemy_creature.duplicate())
		GameState.party_hp.append(enemy_hp)
		GameState.party_hp[0] = player_hp
		GameState.end_battle(true)
	else:
		_type_log("Oh no! It broke free!")
		await get_tree().create_timer(1.2).timeout
		
		var enemy_move = _pick_enemy_move()
		await _execute_turn(enemy_creature, enemy_move, false)
		
		if player_hp <= 0:
			state = BattleState.BATTLE_OVER
			_type_log("You lost!")
			await get_tree().create_timer(1.5).timeout
			GameState.end_battle(false)
		else:
			state = BattleState.CHOOSING
			var t2 := create_tween()
			t2.tween_property(moves_container, "position:x", 210, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			_set_moves_enabled(true)


func _calc_damage(attacker: CreatureData, move: Resource, defender: CreatureData, multiplier: float) -> int:
	var raw: float = (attacker.attack * move.power / 10.0 - defender.defense) * multiplier
	return maxi(1, int(raw))


func _pick_enemy_move() -> Resource:
	return enemy_creature.moves[randi() % enemy_creature.moves.size()]


func _update_hp_text() -> void:
	player_hp_label.text = "%d / %d" % [player_hp, player_creature.max_hp]
	enemy_hp_label.text = "%d / %d" % [enemy_hp, enemy_creature.max_hp]
	# Force initial color update
	_update_hp_bar_color(player_hp, player_hp_bar, player_creature.max_hp)
	_update_hp_bar_color(enemy_hp, enemy_hp_bar, enemy_creature.max_hp)


func _set_moves_enabled(enabled: bool) -> void:
	move_btn_1.disabled = not enabled
	if move_btn_2.visible:
		move_btn_2.disabled = not enabled
	if GameState.party.size() < GameState.MAX_PARTY_SIZE:
		catch_btn.disabled = not enabled
