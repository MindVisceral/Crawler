extends Node2D
class_name GameManager

#region Exports
## Reference to the room generator
@export var room_generator: RoomGenerator
## Reference to the Player placer
@export var room_player_placer: RoomPlayerPlacer
## Reference to the room enemy filler
@export var room_enemy_filler: RoomEnemyFiller
#endregion

#region Variables
## Resource containing all information of a given Room
var room_data: RoomData
#endregion

## Steps in preparing the Room for the Game.
## Each Script does what is is made to do and this function waits until that is done
## before starting the next Script.
func _ready() -> void:
	## Generate a new Room
	room_generator.begin_generating()
	await room_generator.completed_generation
	
	## The Player is moved to the room's entrance
	room_player_placer.begin_placing_player()
	await room_player_placer.completed_placing_player()
	
	## Room generator calls room enemy filler to start filing the room with Enemies
	room_enemy_filler.begin_filling_room()
	await room_enemy_filler.completed_filling_room
	
	## (MORE STEPS GO HERE!)
	
	
	## Room is done, start the game proper by setting up the TurnManager
	## First, add all Entities to its Turn Queue
	for entity: Vector2i in RoomManager.room_data.room_entities:
		TurnManager.turn_queue.append(RoomManager.room_data.room_entities[entity])
	TurnManager.begin_game()

## Used by Scripts to return Data about the current Room
func retrieve_room_data(new_room_data: RoomData) -> void:
	room_data = new_room_data
