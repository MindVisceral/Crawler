class_name RoomData

#region Exports
## Room seed, 0 by default
@export_range(-9999, 9999, 1) var room_seed: int = 0

## Percent of room originally filled with walls
@export_range(0, 100, 1) var fill_percent: int = 45

## Room's start point
@export var room_start_point: Vector2 = Vector2.ZERO
## Room's end point
@export var room_end_point: Vector2 = Vector2.ZERO
## Amount of empty space around given room's entry and exit points
@export_range(1, 10, 1) var access_size: int = 3;

## Room size
@export_range(5, 256) var room_width: int = 64
@export_range(5, 256) var room_height: int = 64
#endregion

#region Variables
## Stores terrain generated in a Room
var room_terrain: Dictionary[Vector2, bool] = {}
## Stores Entities' positions placed in a Room
var room_entities: Dictionary[Vector2, Entity] = {}
#endregion

#region Functions
## Returns a Dictionary that contains all Tiles and whether each one is occupied by
## a piece of Terrain or an Entity. If a given Tile (Vector2) is 'true', then it's filled/occupied
func return_room_tile_occupation_status() -> Dictionary[Vector2, bool]:
	var return_dict: Dictionary[Vector2, bool]
	
	## Copy all information from room_terrain Dictionary (it's of the same type)
	return_dict = room_terrain.duplicate(true)  ## NOTE: IT'S A DEEP COPY!
	
	## room_entities Dictionary isn't of the same type, it must be processed
	## All tiles occupied by Entites are marked as 'true' (means they are filled)
	for entity_pos: Vector2 in room_entities:
		return_dict[entity_pos] = true
	
	## NOTE: Room start and end point are elso considered "occupied",
	## so that nothing may be spawned there.
	## Keep this in mind! Maybe add a boolean to this function for that check.
	return_dict[room_start_point] = true
	return_dict[room_end_point] = true
	
	return return_dict
#endregion
