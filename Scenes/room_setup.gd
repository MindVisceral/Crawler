extends Node2D

#region Exports
## Reference to the Player
@export var player: Player

## Reference to the room generator
@export var room_generator: RoomGenerator
#endregion

func _ready() -> void:
	## When room generator sends a signal that it's done generating,
	## the Player is moved to the room's entrance, if it's available
	await room_generator.completed_generation
	if room_generator.room_start_point != Vector2.ZERO:
		player.position = room_generator.room_start_point * Singleton.TILE_SIZE
