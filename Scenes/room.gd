extends Node2D
## This script/node represents a grid-based room on which entities and objects are present
class_name RoomGrid

#region Variables
## Room's start and end point (used to move up/down "vertical" levels of rooms)
var room_start_point: Vector2
var room_end_point: Vector2

## Room's dimensions (always starting from 0, up to these two variables)
var room_width: int
var room_height: int
#endregion
