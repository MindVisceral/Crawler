extends Node2D
class_name Player

#region Variables
## Tile size in pixels
var tile_size: int = 16

## Possible room movement inputs as Dictionary
var inputs_dict: Dictionary = {
	"move_stay": Vector2.ZERO,
	"move_up": Vector2.UP,
	"move_down": Vector2.DOWN,
	"move_right": Vector2.RIGHT,
	"move_left": Vector2.LEFT,
	"move_up_right": Vector2(1, -1),
	"move_down_right": Vector2(1, 1),
	"move_up_left": Vector2(-1, -1),
	"move_down_left": Vector2(-1, 1)
}
#endregion


func _ready() -> void:
	## Player must be snapped to closest tile
	position = position.snapped(Vector2.ONE * tile_size)

## Player Input for movement
func _unhandled_input(event: InputEvent) -> void:
	## Match Player input to input direction Dictionary and attempt to move in that direction
	for move_dir in inputs_dict.keys():
		if event.is_action_pressed(move_dir):
			move(move_dir)
	
	## Move up/down a floor if possible
	if event.is_action_pressed("move_up_floor"):
		pass
	elif event.is_action_pressed("move_down_floor"):
		pass


#region Movement
## Attemp to move the Player in a given direction
func move(move_dir) -> void:
	## First, check for any obstacles in chosen neighbouring tile and don't move if there are any
	%ObstacleCast.target_position = inputs_dict[move_dir] * tile_size
	%ObstacleCast.force_raycast_update()
	if !%ObstacleCast.is_colliding():
		position += inputs_dict[move_dir] * tile_size
#endregion
