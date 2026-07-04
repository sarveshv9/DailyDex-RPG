extends Node
## Autoload singleton — holds party, HP, flags, and handles scene transitions.

# --- Party ---
const MAX_PARTY_SIZE: int = 6
var party: Array = []           # Array of CreatureData
var party_hp: Array[int] = []   # Parallel array: current HP

# --- Flags ---
var game_flags: Dictionary = {} # General-purpose flags (unused in V1, ready for expansion)

# --- Scene transition state ---
var current_map_scene: String = "res://scenes/overworld/overworld.tscn"
var overworld_player_grid_pos: Vector2i = Vector2i(3, 3)
var wild_creature: CreatureData = null


func _ready() -> void:
	_register_inputs()
	# Give the player a starter creature
	var flamelet := load("res://data/creatures/flamelet.tres") as CreatureData
	if flamelet:
		party.append(flamelet)
		party_hp.append(flamelet.max_hp)


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
	for i in range(party.size()):
		party_hp[i] = party[i].max_hp


func is_party_alive() -> bool:
	for hp in party_hp:
		if hp > 0:
			return true
	return false


func start_battle(wild: CreatureData) -> void:
	wild_creature = wild
	TransitionLayer.battle_flash()
	await TransitionLayer.fade_finished
	get_tree().change_scene_to_file("res://scenes/battle/battle.tscn")
	TransitionLayer.fade_in()


func end_battle(won: bool) -> void:
	if not won:
		heal_party()
	TransitionLayer.fade_out()
	await TransitionLayer.fade_finished
	get_tree().change_scene_to_file(current_map_scene)
	TransitionLayer.fade_in()


func warp_to(scene_path: String, target_pos: Vector2i) -> void:
	current_map_scene = scene_path
	overworld_player_grid_pos = target_pos
	TransitionLayer.fade_out()
	await TransitionLayer.fade_finished
	get_tree().change_scene_to_file(scene_path)
	TransitionLayer.fade_in()


func save_game() -> void:
	var save_data := {
		"current_map_scene": current_map_scene,
		"player_pos_x": overworld_player_grid_pos.x,
		"player_pos_y": overworld_player_grid_pos.y,
		"party": []
	}
	
	for i in range(party.size()):
		var c: CreatureData = party[i]
		save_data["party"].append({
			"resource": c.resource_path,
			"hp": party_hp[i]
		})
	
	var file := FileAccess.open("user://savegame.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))


func load_game() -> void:
	if not FileAccess.file_exists("user://savegame.json"):
		return
		
	var file := FileAccess.open("user://savegame.json", FileAccess.READ)
	var content := file.get_as_text()
	var save_data: Dictionary = JSON.parse_string(content)
	
	if save_data:
		current_map_scene = save_data.get("current_map_scene", "res://scenes/overworld/overworld.tscn")
		overworld_player_grid_pos = Vector2i(
			save_data.get("player_pos_x", 3),
			save_data.get("player_pos_y", 3)
		)
		
		party.clear()
		party_hp.clear()
		
		var saved_party: Array = save_data.get("party", [])
		for c_data in saved_party:
			var res_path: String = c_data.get("resource", "")
			if ResourceLoader.exists(res_path):
				var creature: CreatureData = load(res_path) as CreatureData
				if creature:
					party.append(creature)
					party_hp.append(c_data.get("hp", creature.max_hp))
		
		# Resume the loaded state
		get_tree().paused = false
		TransitionLayer.fade_out()
		await TransitionLayer.fade_finished
		get_tree().change_scene_to_file(current_map_scene)
		TransitionLayer.fade_in()
