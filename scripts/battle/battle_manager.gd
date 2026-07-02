extends Control
## Turn-based battle scene. Builds its entire UI programmatically so the .tscn
## file is minimal. Reads creature data from GameState.

enum BattleState { CHOOSING, ANIMATING, BATTLE_OVER }

var player_creature: CreatureData
var enemy_creature: CreatureData
var player_hp: int
var enemy_hp: int
var state: BattleState = BattleState.CHOOSING

# UI nodes (created in _build_ui)
var player_rect: ColorRect
var enemy_rect: ColorRect
var player_hp_bar: ProgressBar
var enemy_hp_bar: ProgressBar
var player_name_label: Label
var enemy_name_label: Label
var player_hp_label: Label
var enemy_hp_label: Label
var move_btn_1: Button
var move_btn_2: Button
var battle_log: Label


func _ready() -> void:
	# Ensure this Control fills the viewport
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_init_battle()


# ---------------------------------------------------------------------------
# UI Construction (320 × 180 viewport)
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	# --- Dark background ---
	var bg := ColorRect.new()
	bg.color = Color(0.10, 0.10, 0.16)
	bg.anchor_left = 0; bg.anchor_top = 0
	bg.anchor_right = 1; bg.anchor_bottom = 1
	bg.offset_left = 0; bg.offset_top = 0
	bg.offset_right = 0; bg.offset_bottom = 0
	add_child(bg)

	# --- Enemy creature rectangle (top-right) ---
	enemy_rect = ColorRect.new()
	enemy_rect.position = Vector2(218, 10)
	enemy_rect.size = Vector2(48, 48)
	add_child(enemy_rect)

	# --- Player creature rectangle (bottom-left) ---
	player_rect = ColorRect.new()
	player_rect.position = Vector2(50, 62)
	player_rect.size = Vector2(48, 48)
	add_child(player_rect)

	# --- Enemy info (top-left) ---
	enemy_name_label = _make_label(Vector2(10, 6), 11)
	enemy_hp_bar = _make_hp_bar(Vector2(10, 22), Vector2(130, 10))
	enemy_hp_label = _make_label(Vector2(10, 34), 8)

	# --- Player info (left, below creatures) ---
	player_name_label = _make_label(Vector2(10, 116), 11)
	player_hp_bar = _make_hp_bar(Vector2(10, 132), Vector2(130, 10))
	player_hp_label = _make_label(Vector2(10, 144), 8)

	# --- Move buttons (bottom-right) ---
	move_btn_1 = _make_button(Vector2(185, 120), Vector2(126, 22))
	move_btn_2 = _make_button(Vector2(185, 146), Vector2(126, 22))

	# --- Battle log (very bottom) ---
	battle_log = _make_label(Vector2(10, 164), 9)
	battle_log.size = Vector2(170, 14)


# Helpers to reduce boilerplate
func _make_label(pos: Vector2, font_size: int) -> Label:
	var lbl := Label.new()
	lbl.position = pos
	lbl.add_theme_font_size_override("font_size", font_size)
	add_child(lbl)
	return lbl


func _make_hp_bar(pos: Vector2, sz: Vector2) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = pos
	bar.size = sz
	bar.show_percentage = false
	add_child(bar)
	return bar


func _make_button(pos: Vector2, sz: Vector2) -> Button:
	var btn := Button.new()
	btn.position = pos
	btn.size = sz
	btn.add_theme_font_size_override("font_size", 9)
	add_child(btn)
	return btn


# ---------------------------------------------------------------------------
# Battle init
# ---------------------------------------------------------------------------

func _init_battle() -> void:
	player_creature = GameState.get_lead_creature()
	enemy_creature = GameState.wild_creature

	player_hp = GameState.current_hp.get(player_creature, player_creature.max_hp)
	enemy_hp = enemy_creature.max_hp

	# Visuals
	player_rect.color = player_creature.color
	enemy_rect.color = enemy_creature.color
	player_name_label.text = player_creature.creature_name
	enemy_name_label.text = enemy_creature.creature_name
	_update_hp_display()

	# Move buttons
	if player_creature.moves.size() > 0:
		move_btn_1.text = player_creature.moves[0].move_name
		move_btn_1.pressed.connect(_on_move_selected.bind(0))
	if player_creature.moves.size() > 1:
		move_btn_2.text = player_creature.moves[1].move_name
		move_btn_2.pressed.connect(_on_move_selected.bind(1))
	else:
		move_btn_2.visible = false

	battle_log.text = "A wild %s appeared!" % enemy_creature.creature_name
	state = BattleState.CHOOSING


# ---------------------------------------------------------------------------
# Turn logic
# ---------------------------------------------------------------------------

func _on_move_selected(move_index: int) -> void:
	if state != BattleState.CHOOSING:
		return

	state = BattleState.ANIMATING
	_set_moves_enabled(false)

	var player_move = player_creature.moves[move_index]

	# Speed determines turn order (tie → player first)
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

	# Check win / lose
	if enemy_hp <= 0:
		state = BattleState.BATTLE_OVER
		battle_log.text = "You won!"
		await get_tree().create_timer(1.5).timeout
		GameState.current_hp[player_creature] = player_hp
		GameState.end_battle(true)
	elif player_hp <= 0:
		state = BattleState.BATTLE_OVER
		battle_log.text = "You lost!"
		await get_tree().create_timer(1.5).timeout
		GameState.end_battle(false)
	else:
		state = BattleState.CHOOSING
		_set_moves_enabled(true)


func _execute_turn(attacker: CreatureData, move: Resource, is_player_attacking: bool) -> void:
	battle_log.text = "%s used %s!" % [attacker.creature_name, move.move_name]
	await get_tree().create_timer(0.7).timeout

	var defender: CreatureData = enemy_creature if is_player_attacking else player_creature
	var damage := _calc_damage(attacker, move, defender)

	if is_player_attacking:
		enemy_hp = maxi(0, enemy_hp - damage)
	else:
		player_hp = maxi(0, player_hp - damage)

	# Flash the target white briefly
	var target_rect: ColorRect = enemy_rect if is_player_attacking else player_rect
	var original_color: Color = target_rect.color
	target_rect.color = Color.WHITE
	await get_tree().create_timer(0.12).timeout
	target_rect.color = original_color

	battle_log.text = "It dealt %d damage!" % damage
	_update_hp_display()
	await get_tree().create_timer(0.5).timeout


func _calc_damage(attacker: CreatureData, move: Resource, defender: CreatureData) -> int:
	## damage = atk * power / 10 − def, minimum 1
	var raw: float = attacker.attack * move.power / 10.0 - defender.defense
	return maxi(1, int(raw))


func _pick_enemy_move() -> Resource:
	return enemy_creature.moves[randi() % enemy_creature.moves.size()]


# ---------------------------------------------------------------------------
# UI helpers
# ---------------------------------------------------------------------------

func _update_hp_display() -> void:
	player_hp_bar.max_value = player_creature.max_hp
	player_hp_bar.value = player_hp
	player_hp_label.text = "%d / %d" % [player_hp, player_creature.max_hp]

	enemy_hp_bar.max_value = enemy_creature.max_hp
	enemy_hp_bar.value = enemy_hp
	enemy_hp_label.text = "%d / %d" % [enemy_hp, enemy_creature.max_hp]


func _set_moves_enabled(enabled: bool) -> void:
	move_btn_1.disabled = not enabled
	if move_btn_2.visible:
		move_btn_2.disabled = not enabled
