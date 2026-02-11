class_name RoomData

#region Exports
## Room seed, 0 by default
@export_range(-9999, 9999, 1) var room_seed: int = 0

## Percent of room originally filled with walls
@export_range(0, 100, 1) var fill_percent: int = 45

## Room's start point
@export var room_start_point: Vector2i = Vector2i.ZERO
## Room's end point
@export var room_end_point: Vector2i = Vector2i.ZERO
## Amount of empty space around given room's entry and exit points
@export_range(1, 10, 1) var access_size: int = 3;

## Room size
@export_range(5, 256) var room_width: int = 64
@export_range(5, 256) var room_height: int = 64
#endregion

#region Variables
## Stores terrain generated in a Room
var room_terrain: Dictionary[Vector2i, bool] = {}
## Stores Entities' positions placed in a Room
var room_entities: Dictionary[Vector2i, Entity] = {}
#endregion

#region Functions
### Return whether the Tile on the passed position is free
#func is_tile_empty(tile_pos: Vector2) -> bool:
	### If this Tile position is empty, return true
	#if room_terrain.has(tile_pos) && room_entities.has(tile_pos) == false:
		#if room_terrain[tile_pos] != false:
			#return true
	#
	### Tile is occupied, return false
	#return false
## Return whether the Tile on the passed position is free
func is_tile_empty(tile_pos: Vector2i) -> bool:
	#print("Tile at pos", tile_pos, " is terrain filled:", room_terrain.get(tile_pos, false))
	## If this Tile position is empty, return true.
	## If a Tile is not recorder in the room_terrain Dict, it's considered empty anyway.
	## This allows the Entities to move outside the boundary of the Room
	if (room_terrain.get(tile_pos, false) == false) && (room_entities.has(tile_pos) == false):
		return true
	
	## Otherwise, Tile is occupied, return false
	return false

## Returns a Dictionary that contains all Tiles and whether each one is occupied by
## a piece of Terrain or an Entity. If a given Tile (Vector2) is 'true', then it's filled/occupied
func return_tiles_occupation_dict() -> Dictionary[Vector2i, bool]:
	var return_dict: Dictionary[Vector2i, bool]
	
	## Copy all information from room_terrain Dictionary (it's of the same type)
	return_dict = room_terrain.duplicate(true)  ## NOTE: IT'S A DEEP COPY!
	
	## room_entities Dictionary isn't of the same type, it must be processed
	## All tiles occupied by Entites are marked as 'true' (means they are filled)
	for entity_pos: Vector2i in room_entities:
		return_dict[entity_pos] = true
	
	## NOTE: Room start and end point are elso considered "occupied",
	## so that nothing may be spawned there.
	## Keep this in mind! Maybe add a boolean to this function for that check.
	return_dict[room_start_point] = true
	return_dict[room_end_point] = true
	
	return return_dict
#endregion
