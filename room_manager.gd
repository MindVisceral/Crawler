extends Node

## This Script keeps all data about the current Room; terrain, Entity positions, etc.

## Resource containing all information on a given Room
var room_data: RoomData


## Creates an empty room_data
func _ready() -> void:
	room_data = RoomData.new()


#region Functions
## Update the Manager's RoomData Resource by merging or replacing room_data data with the
## data from  new_room_data
func update_roomdata_resource(new_room_data: RoomData) -> void:
	## Iterate over all properties in new_room_data and use them to update data in room_data.
	## Arrays are merged, regular variables are replaced.
	for property in new_room_data.get_property_list():
		
		## We only care about properties that are variables in the RoomData Resource script
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			## If a property in this passed new_room_data is Null, ignore it
			if new_room_data.get(property.name) == null:
				continue
			
			## Arrays are merged
			if (new_room_data.get(property.name) is Array) and \
						(room_data.get(property.name) is Array):
				var new_array: Array = new_room_data.get(property.name)
				new_array.append_array(room_data.get(property.name))
				room_data.set(property.name, new_array)
				continue
			
			## Dictionaries are merged
			if (new_room_data.get(property.name) is Dictionary) and \
						(room_data.get(property.name) is Dictionary):
				var new_dict: Dictionary = new_room_data.get(property.name)
				new_dict.merge(room_data.get(property.name))
				room_data.set(property.name, new_dict)
				continue
			
			
			## Everything else is copied over from new_room_data to room_data
			room_data.set(property.name, new_room_data.get(property.name))
	
	
	### Replacement, if new info is not Null
	#room_data.room_seed = new_room_data.room_seed
	#room_data.fill_percent = new_room_data.fill_percent
	#room_data.room_start_point = new_room_data.room_start_point
	#room_data.room_end_point = new_room_data.room_end_point
	#room_data.access_size = new_room_data.access_size
	#room_data.room_width = new_room_data.room_width
	#room_data.room_height = new_room_data.room_height
	#
	### Merging
	#room_data.room_terrain.merge(new_room_data.room_terrain)
	#room_data.room_entities.merge(new_room_data.room_terrain)

## Return whether the Tile on the passed position is free
func is_tile_empty(tile_pos: Vector2i) -> bool:
	## If this Tile position is empty, return true.
	## If a Tile is not recorder in the room_terrain Dict, it's considered empty anyway.
	## This allows the Entities to move outside the boundary of the Room
	if (room_data.room_terrain.get(tile_pos, false) == false) \
			&& (room_data.room_entities.has(tile_pos) == false):
		return true
	
	## Otherwise, Tile is occupied, return false
	return false

## Returns an Array of Entities/Items/etc. present on the given Tile
func return_tile_contents(tile_pos: Vector2i) -> Array[Node2D]:
	var contents: Array[Node2D]
	## Add all Entities to the Array
	for entity_pos in room_data.room_entities:
		if entity_pos == tile_pos:
			contents.append(room_data.room_entities[entity_pos])
	
	## Add all X to the array... and so on
	
	## Return Array
	return contents

## Returns a Dictionary that contains all Tiles and whether each one is occupied by
## a piece of Terrain or an Entity. If a given Tile (Vector2) is 'true', then it's filled/occupied
func return_tiles_occupation_dict() -> Dictionary[Vector2i, bool]:
	var return_dict: Dictionary[Vector2i, bool]
	
	## Copy all information from room_terrain Dictionary (it's of the same type)
	return_dict = room_data.room_terrain.duplicate(true)  ## NOTE: IT'S A DEEP COPY!
	
	## room_entities Dictionary isn't of the same type, it must be processed
	## All tiles occupied by Entites are marked as 'true' (means they are filled)
	for entity_pos: Vector2i in room_data.room_entities:
		return_dict[entity_pos] = true
	
	## NOTE: Room start and end point are elso considered "occupied",
	## so that nothing may be spawned there.
	## Keep this in mind! Maybe add a boolean to this function for that check.
	return_dict[room_data.room_start_point] = true
	return_dict[room_data.room_end_point] = true
	
	return return_dict

## Places an Entity on a given Tile
## NOTE: DOESN'T CHECK IF THIS PLACEMENT IS VALID, IT JUST PLACES THE ENTITY
## THIS CAN MAKE room_data LOSE TRACK OF AN ENTITY IN new_pos IF THAT ISN'T CHECKED ELSEWHERE
func place_entity(new_pos: Vector2i, entity: Entity) -> void:
	room_data.room_entities[new_pos] = entity
	#print("Placed Entity (", entity, ") at position ", new_pos)

## Moves the Entity from the passed old_pos to the passed new_pos Tile position,
## keeps track of this change in RoomData.
## NOTE: DOESN'T CHECK IF THIS MOVEMENT IS POSSIBLE, IT JUST MOVES IT
## THIS CAN MAKE room_data LOSE TRACK OF AN ENTITY IN new_pos IF THAT ISN'T CHECKED ELSEWHERE
func move_entity(old_pos: Vector2i, new_pos: Vector2i) -> void:
	#print("MOVEMENT POSITIONS: old-", old_pos, " new-", new_pos)
	## Check if there is an Entity at the given old_position
	if room_data.room_entities.has(old_pos) == true:
		#print("Entity (", room_data.room_entities[old_pos], ") moved from ", old_pos, " to ", new_pos)
		## If there is an Entity there, create a new key at new_position with the same Entity
		room_data.room_entities[new_pos] = room_data.room_entities[old_pos]
		## and remove the old_pos key
		room_data.room_entities.erase(old_pos)

## Remove Entity from RoomData altogether. Used when an Entity is killed
func remove_entity(position: Vector2i, entity: Entity) -> void:
	## Check if there is an Entity on the given position and if the Entity there is the same one
	## as the one that was passed (this check is currently unnecessary)
	if room_data.room_entities.has(position) == true:
		if room_data.room_entities[position] == entity:
			room_data.room_entities.erase(position)

#endregion
