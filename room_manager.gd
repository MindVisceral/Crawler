extends Node

## This Script keeps all data about the current Room; terrain, Entity positions, etc.

## Resource containing all information on a given Room
var room_data: RoomData

## Creates an empty room_data
func _ready() -> void:
	room_data = RoomData.new()

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
