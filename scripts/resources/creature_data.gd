class_name CreatureData
extends Resource
## Data container for a creature's base stats and move list.

@export var creature_name: String = "Unknown"
@export var element_type: String = "Normal"
@export var max_hp: int = 10
@export var attack: int = 1
@export var defense: int = 1
@export var speed: int = 1
@export var moves: Array[Resource] = []  # Array of MoveData resources
@export var color: Color = Color.WHITE   # Display color (colored rectangle in V1)
