extends Node
## Global Type Chart autoload.
## Defines the damage multipliers for different elemental matchups.

const MULTIPLIERS := {
	"Fire": {
		"Grass": 2.0,
		"Water": 0.5,
		"Fire": 0.5
	},
	"Water": {
		"Fire": 2.0,
		"Grass": 0.5,
		"Water": 0.5
	},
	"Grass": {
		"Water": 2.0,
		"Fire": 0.5,
		"Grass": 0.5
	},
	"Normal": {
		# Normal has no special strengths or weaknesses in this simplified chart
	}
}

func get_multiplier(atk_type: String, def_type: String) -> float:
	if MULTIPLIERS.has(atk_type) and MULTIPLIERS[atk_type].has(def_type):
		return MULTIPLIERS[atk_type][def_type]
	return 1.0
