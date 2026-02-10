extends Node2D
class_name GameManager

#region Exports
## Reference to the Player
@export var player: Player

## Reference to the room generator
@export var room_generator: RoomGenerator
## Reference to the room enemy filler
@export var room_enemy_filler: RoomEnemyFiller
#endregion

#region Variables
## Resource containing all information of a given Room
var room_data: RoomData
#endregion

func _ready() -> void:
	## When room generator sends a signal that it's done generating,
	## the Player is moved to the room's entrance, if it's available
	room_generator.begin_generating()
	await room_generator.completed_generation
	player.position = room_generator.room_start_point * Singleton.TILE_SIZE
	## room_generator returns a RoomData Resource with information about the Room's structure.
	
	## Room generator calls room enemy filler to start filing the room with Enemies
	## Wait for that to finish
	room_enemy_filler.retrieve_room_data(room_data)
	room_enemy_filler.begin_filling_room()
	await room_enemy_filler.completed_filling_room
	
	## (MORE STEPS GO HERE!)
	
	## Room is done, start the game proper by setting up the TurnManager
	## First, add all Entities to its Turn Queue
	for entity: Entity in EntityManager.entities:
		TurnManager.turn_queue.append(entity)
	TurnManager.begin_game()

## Used by Scripts to return Data about the current Room
func retrieve_room_data(new_room_data: RoomData) -> void:
	room_data = new_room_data
