extends Node
class_name RoomPlayerPlacer

#region Exports
## Reference to the Player
@export var player: Player

## Reference to the Node all the Entities are children of.
@export var entity_parent_node: Node2D
#endregion

#region Variables
## Resource containing all information of a given Room.
## Local-only; meant only to be filled and pass on the data to RoomManager
@onready var room_data: RoomData = RoomData.new()

#endregion

## Called by GameManager when all previous steps are done
func begin_placing_player() -> void:
	## Add Player to dict of Entities, place it on the start Tile
	room_data.room_entities[RoomManager.room_data.room_start_point] = player
	## Physically place the Player where it should be
	## HERE: This can be changed to not always place the Player at the Room start point!
	player.place_entity_at_tile(RoomManager.room_data.room_start_point)
	
	## Placing the Player is done.
	completed_placing_player()

## Pass on important information to the Game script so the next step may begin
func completed_placing_player() -> void:
	## Update RoomManager's RoomData Resource with generated data
	RoomManager.update_roomdata_resource(room_data)
