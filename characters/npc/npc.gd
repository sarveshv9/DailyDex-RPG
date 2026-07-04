extends CharacterBody2D

signal dialogue_requested(text)

@export var dialogue_text: String = "Hello! I am a placeholder NPC."

func interact():
	print("NPC interacted with!")
	dialogue_requested.emit(dialogue_text)
