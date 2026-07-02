extends Node2D
## A static NPC with dialogue lines. The overworld reads `dialogue_lines`
## when the player tries to walk into this NPC.

@export var is_healer: bool = true

var dialogue_lines: Array = [
	"Hello! I'm the town healer.",
	"I have fully restored your party's HP!",
	"Take care out there!",
]
