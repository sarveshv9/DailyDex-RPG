@tool
extends EditorPlugin

const IMPORT_MENU_TEXT = "Import Pokemon (GDScript)"
const RESOURCE_FOLDER = "res://resources/pokemon/"
const SPRITE_FOLDER = "res://assets/pokemon/"
const API_PATH = "https://pokeapi.co/api/v2/pokemon/"
const MENU_ICON_API_PATH = "https://img.pokemondb.net/sprites/lets-go-pikachu-eevee/normal/"
const POKEMON_NUMBERS = 151 # Gen 1

var _is_importing: bool = false
var _current_index: int = 1


func _enter_tree() -> void:
	add_tool_menu_item(IMPORT_MENU_TEXT, Callable(self, "_on_import_pokemon"))


func _exit_tree() -> void:
	remove_tool_menu_item(IMPORT_MENU_TEXT)


func _on_import_pokemon() -> void:
	if _is_importing:
		print("Pokemon import already in progress...")
		return
	
	print("Attempting to import Pokemon...")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(RESOURCE_FOLDER))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SPRITE_FOLDER))
	
	_is_importing = true
	_current_index = 1
	_process_next_pokemon()


func _process_next_pokemon() -> void:
	if _current_index > POKEMON_NUMBERS:
		print("Pokemon import complete!")
		_is_importing = false
		EditorInterface.get_resource_filesystem().scan()
		return
		
	await _import_pokemon(_current_index)
	_current_index += 1
	# Small delay to yield to editor
	await get_tree().create_timer(0.1).timeout
	_process_next_pokemon()


func _import_pokemon(id: int) -> void:
	print("Processing Pokemon ID: ", id)
	
	# Fetch Pokemon Data
	var pkmn_data_result = await _fetch_json(API_PATH + str(id))
	if pkmn_data_result.is_empty():
		printerr("Failed to fetch pokemon data for ID ", id)
		return
		
	var pokemon_name: String = pkmn_data_result.get("name", "")
	if pokemon_name.is_empty():
		printerr("Pokemon ", id, " has no name.")
		return
		
	# Fetch Species Data
	var species_url: String = pkmn_data_result.get("species", {}).get("url", "")
	var species_data_result: Dictionary = {}
	if not species_url.is_empty():
		species_data_result = await _fetch_json(species_url)
		
	# Create Resource
	print("Creating resource for ", pokemon_name, "...")
	var pokemon = CreatureData.new()
	pokemon.creature_name = pokemon_name.capitalize()
	pokemon.id = pkmn_data_result.get("id", id)
	pokemon.height = pkmn_data_result.get("height", 0)
	pokemon.weight = pkmn_data_result.get("weight", 0)
	pokemon.base_experience = pkmn_data_result.get("base_experience", 0)
	
	# Parse Description
	var flavor_entries: Array = species_data_result.get("flavor_text_entries", [])
	var desc := "Description not available"
	for entry in flavor_entries:
		if entry.get("language", {}).get("name", "") == "en":
			desc = entry.get("flavor_text", "")
			# Clean up weird newlines from pokeapi
			desc = desc.replace("\n", " ").replace("\f", " ")
			break
	pokemon.description = desc
	
	# Parse Stats
	var stats: Array = pkmn_data_result.get("stats", [])
	for stat_entry in stats:
		var stat_name: String = stat_entry.get("stat", {}).get("name", "")
		var value: int = stat_entry.get("base_stat", 0)
		match stat_name:
			"hp": pokemon.max_hp = value
			"attack": pokemon.attack = value
			"defense": pokemon.defense = value
			"special-attack": pokemon.special_attack = value
			"special-defense": pokemon.special_defense = value
			"speed": pokemon.speed = value
			
	# Parse Type
	var types: Array = pkmn_data_result.get("types", [])
	if types.size() > 0:
		pokemon.element_type = types[0].get("type", {}).get("name", "normal")
		
	# Parse Moves
	var moves: Array = pkmn_data_result.get("moves", [])
	pokemon.learnable_moves = []
	pokemon.level_up_moves = {}
	
	for move_entry in moves:
		var move_name = move_entry.get("move", {}).get("name", "")
		var version_details = move_entry.get("version_group_details", [])
		for detail in version_details:
			var version = detail.get("version_group", {}).get("name", "")
			if version == "yellow" or version == "red-blue":
				var method = detail.get("move_learn_method", {}).get("name", "")
				if method == "level-up":
					var lvl = detail.get("level_learned_at", 1)
					if not pokemon.level_up_moves.has(move_name) or lvl < pokemon.level_up_moves[move_name]:
						pokemon.level_up_moves[move_name] = lvl
				else:
					if move_name not in pokemon.learnable_moves:
						pokemon.learnable_moves.append(move_name)
	
	# Load Sprites
	var sprites: Dictionary = pkmn_data_result.get("sprites", {})
	pokemon.front_sprite = await _load_texture_from_url(sprites.get("front_default", ""), pokemon_name + "_front.png")
	pokemon.back_sprite = await _load_texture_from_url(sprites.get("back_default", ""), pokemon_name + "_back.png")
	pokemon.shiny_front_sprite = await _load_texture_from_url(sprites.get("front_shiny", ""), pokemon_name + "_shiny_front.png")
	pokemon.shiny_back_sprite = await _load_texture_from_url(sprites.get("back_shiny", ""), pokemon_name + "_shiny_back.png")
	pokemon.menu_icon_sprite = await _load_texture_from_url(MENU_ICON_API_PATH + pokemon_name + ".png", pokemon_name + "_menu_icon.png")
	
	var save_path = RESOURCE_FOLDER + pokemon_name.to_lower() + ".tres"
	var err = ResourceSaver.save(pokemon, save_path)
	if err != OK:
		printerr("Problem saving pokemon ", pokemon_name, ": ", err)


func _fetch_json(url: String) -> Dictionary:
	var req = HTTPRequest.new()
	add_child(req)
	var err = req.request(url)
	if err != OK:
		req.queue_free()
		return {}
		
	var result = await req.request_completed
	var response_code = result[1]
	var body = result[3]
	
	req.queue_free()
	
	if response_code != 200:
		return {}
		
	var json = JSON.new()
	if json.parse(body.get_string_from_utf8()) == OK:
		return json.data
	return {}


func _load_texture_from_url(url: String, filename: String) -> Texture2D:
	if url.is_empty():
		return null
		
	var resource_path = SPRITE_FOLDER + filename
	var global_path = ProjectSettings.globalize_path(resource_path)
	
	# If already downloaded, load it from disk to save API calls
	if FileAccess.file_exists(global_path):
		var img = Image.new()
		var err = img.load(global_path)
		if err == OK:
			return ImageTexture.create_from_image(img)
			
	var req = HTTPRequest.new()
	add_child(req)
	var err = req.request(url)
	if err != OK:
		req.queue_free()
		return null
		
	var result = await req.request_completed
	var response_code = result[1]
	var body: PackedByteArray = result[3]
	
	req.queue_free()
	
	if response_code != 200:
		return null
		
	# Save to disk
	var file = FileAccess.open(global_path, FileAccess.WRITE)
	if file:
		file.store_buffer(body)
		file.close()
		
	var image = Image.new()
	if image.load_png_from_buffer(body) == OK:
		return ImageTexture.create_from_image(image)
		
	return null
