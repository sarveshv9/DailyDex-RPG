extends Node
## Autoload singleton — holds party, HP, flags, and handles scene transitions.

# --- Party ---
var party: Array = []           # Array of CreatureData
var current_hp: Dictionary = {} # CreatureData → current HP (int)

# --- Flags ---
var game_flags: Dictionary = {} # General-purpose flags (unused in V1, ready for expansion)

# --- Scene transition state ---
var overworld_player_grid_pos: Vector2i = Vector2i(3, 3)
var wild_creature: CreatureData = null
var returning_from_battle: bool = false


func _ready() -> void:
	_register_inputs()
	# Give the player a starter creature
	var flamelet := load("res://data/creatures/flamelet.tres") as CreatureData
	if flamelet:
		party.append(flamelet)
		current_hp[flamelet] = flamelet.max_hp


func _register_inputs() -> void:
	## Create move_* input actions in code so we don't depend on project.godot
	## serialization (which is fragile across Godot versions).
	var bindings := {
		"move_up":    [KEY_W, KEY_UP],
		"move_down":  [KEY_S, KEY_DOWN],
		"move_left":  [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
	}
	for action_name: String in bindings:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name, 0.2)  # 0.2 = deadzone
		for keycode: int in bindings[action_name]:
			var ev := InputEventKey.new()
			ev.physical_keycode = keycode
			if not InputMap.action_has_event(action_name, ev):
				InputMap.action_add_event(action_name, ev)


func get_lead_creature() -> CreatureData:
	if party.size() > 0:
		return party[0]
	return null


func heal_party() -> void:
	for creature in party:
		current_hp[creature] = creature.max_hp


func is_party_alive() -> bool:
	for creature in party:
		if current_hp.get(creature, 0) > 0:
			return true
	return false


func start_battle(wild: CreatureData) -> void:
	wild_creature = wild
	get_tree().change_scene_to_file("res://scenes/battle/battle.tscn")


func end_battle(won: bool) -> void:
	if not won:
		heal_party()
	returning_from_battle = true
	get_tree().change_scene_to_file("res://scenes/overworld/overworld.tscn")
