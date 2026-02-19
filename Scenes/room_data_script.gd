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
