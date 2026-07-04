@tool
extends EditorPlugin

const IMPORT_MENU_TEXT = "Import Moves (GDScript)"
const FOLDER_PATH = "res://resources/moves/"
const API_PATH = "https://pokeapi.co/api/v2/move/"
const MOVE_NUMBERS = 165 # Gen 1 move count

var _http_request: HTTPRequest
var _current_index: int = 1
var _is_importing: bool = false


func _enter_tree() -> void:
	add_tool_menu_item(IMPORT_MENU_TEXT, Callable(self, "_on_import_moves"))
	_http_request = HTTPRequest.new()
	add_child(_http_request)
	_http_request.request_completed.connect(_on_request_completed)


func _exit_tree() -> void:
	remove_tool_menu_item(IMPORT_MENU_TEXT)
	if _http_request:
		_http_request.queue_free()


func _on_import_moves() -> void:
	if _is_importing:
		print("Move import already in progress...")
		return
	
	print("Attempting to import moves...")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FOLDER_PATH))
	
	_is_importing = true
	_current_index = 1
	_fetch_next()


func _fetch_next() -> void:
	if _current_index > MOVE_NUMBERS:
		print("Move import complete!")
		_is_importing = false
		EditorInterface.get_resource_filesystem().scan()
		return
		
	var url = API_PATH + str(_current_index)
	print("Fetching move ID ", _current_index, " from ", url)
	_http_request.request(url)


func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		printerr("Failed to fetch move ID ", _current_index, ". HTTP Code: ", response_code)
		_current_index += 1
		_fetch_next()
		return
		
	var json = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		printerr("Failed to parse JSON for move ID ", _current_index)
		_current_index += 1
		_fetch_next()
		return
		
	var data: Dictionary = json.data
	_process_move_data(data)
	
	_current_index += 1
	# Give the editor a tiny visual break before the next request
	await get_tree().create_timer(0.1).timeout
	_fetch_next()


func _process_move_data(data: Dictionary) -> void:
	var generation: String = data.get("generation", {}).get("name", "")
	if generation != "generation-i":
		print("Move ", _current_index, " is not Gen 1, skipping.")
		return
		
	var move_name: String = data.get("name", "")
	if move_name.is_empty():
		printerr("Move ", _current_index, " has no name.")
		return
		
	print("Creating resource for ", move_name, "...")
	var move := MoveData.new()
	move.move_name = move_name.capitalize()
	
	var pokemon_type: String = data.get("type", {}).get("name", "normal")
	move.element_type = pokemon_type
	
	var damage_class: String = data.get("damage_class", {}).get("name", "physical")
	move.category = damage_class
	
	var target: String = data.get("target", {}).get("name", "selected-pokemon")
	move.target = target
	
	move.accuracy = data.get("accuracy") if data.get("accuracy") != null else 100
	move.pp = data.get("pp") if data.get("pp") != null else 35
	move.power = data.get("power") if data.get("power") != null else 0
	
	var meta: Dictionary = data.get("meta")
	if meta != null and typeof(meta) == TYPE_DICTIONARY:
		move.crit_rate = meta.get("crit_rate", 0)
		move.drain = meta.get("drain", 0)
		move.flinch_chance = meta.get("flinch_chance", 0)
		move.healing = meta.get("healing", 0)
		move.max_hits = meta.get("max_hits") if meta.get("max_hits") != null else -1
		move.max_turns = meta.get("max_turns") if meta.get("max_turns") != null else -1
		move.min_hits = meta.get("min_hits") if meta.get("min_hits") != null else -1
		move.min_turns = meta.get("min_turns") if meta.get("min_turns") != null else -1
		move.ailment_chance = meta.get("ailment_chance", 0)
		move.ailment = meta.get("ailment", {}).get("name", "none")
		
	var stat_changes: Array = data.get("stat_changes", [])
	move.stat_changes = {}
	for change in stat_changes:
		if typeof(change) == TYPE_DICTIONARY:
			var amount: int = change.get("change", 0)
			var stat_name: String = change.get("stat", {}).get("name", "")
			if not stat_name.is_empty():
				move.stat_changes[stat_name] = amount
				
	var save_path = FOLDER_PATH + move_name.to_lower() + ".tres"
	var err = ResourceSaver.save(move, save_path)
	if err != OK:
		printerr("Failed to save move ", move_name, " to ", save_path, ": ", err)
