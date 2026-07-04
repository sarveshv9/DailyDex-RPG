class_name CreatureData
extends Resource
## Data container for a creature's base stats, moves, and metadata.

@export var creature_name: String = "Unknown"
@export var id: int = 0
@export_multiline var description: String = "Description not available"

@export var element_type: String = "Normal"
@export var height: int = 0
@export var weight: int = 0
@export var base_experience: int = 0

@export var max_hp: int = 10
@export var attack: int = 1
@export var defense: int = 1
@export var special_attack: int = 1
@export var special_defense: int = 1
@export var speed: int = 1

## Array of strings (move names) learnable via TMs/HMs (Gen 1)
@export var learnable_moves: Array[String] = []
## Dictionary mapping move_name (String) to learn_level (int)
@export var level_up_moves: Dictionary = {}

## The currently equipped active moves (MoveData resources)
@export var moves: Array[Resource] = []

@export var front_sprite: Texture2D
@export var back_sprite: Texture2D
@export var shiny_front_sprite: Texture2D
@export var shiny_back_sprite: Texture2D
@export var menu_icon_sprite: Texture2D

## For backward compatibility with the old prototype
@export var color: Color = Color.WHITE
