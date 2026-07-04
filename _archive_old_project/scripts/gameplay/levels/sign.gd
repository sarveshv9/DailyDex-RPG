extends StaticBody2D
## Sign — an interactable object that displays messages when the player
## interacts with it. GDScript replacement for Sign.cs.

@export var messages: Array[String] = []
## 0 = wood, 1 = metal
@export var sign_style: int = 0


func _ready() -> void:
	pass


## Called by the interaction system to get the messages to display
func get_messages() -> Array[String]:
	return messages
