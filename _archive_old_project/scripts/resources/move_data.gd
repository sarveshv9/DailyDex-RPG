class_name MoveData
extends Resource
## Data container for a single creature move.

@export var move_name: String = "Tackle"
@export var element_type: String = "Normal"
@export var category: String = "physical" # physical, special, status
@export var target: String = "selected-pokemon"
@export var power: int = 40
@export var accuracy: int = 100
@export var pp: int = 35

@export var crit_rate: int = 0
@export var drain: int = 0
@export var flinch_chance: int = 0
@export var healing: int = 0
@export var max_hits: int = -1
@export var max_turns: int = -1
@export var min_hits: int = -1
@export var min_turns: int = -1
@export var ailment_chance: int = 0
@export var ailment: String = "none"

## Dictionary of stat changes e.g., {"attack": -1, "defense": 2}
@export var stat_changes: Dictionary = {}
