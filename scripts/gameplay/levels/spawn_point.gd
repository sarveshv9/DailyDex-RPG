extends Node2D
## Spawn point — marks a location where the player can appear
## when entering this level. GDScript replacement for SpawnPoint.cs.


func get_spawn_position() -> Vector2:
	return global_position
