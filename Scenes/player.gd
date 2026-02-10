extends Entity
class_name Player

#region Variables
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
	super()
	
	## Player must be added to the Array of all Entities present in a Room.
	## Since Player is always present, this is only necessary once (for now, this could change!)
	EntityManager.entities.append(self)
	
	## Player must be snapped to closest tile
	position = position.snapped(Vector2.ONE * Singleton.TILE_SIZE)

## Player Input for movement
func _unhandled_input(event: InputEvent) -> void:
	## Movement only works if it's the Players Turn!
	if is_entity_turn == true:
		## Match Player input to input direction Dictionary and attempt to move in that direction
		for move_dir in inputs_dict.keys():
			if event.is_action_pressed(move_dir):
				move_manually(move_dir)
		
		## Move up/down a floor if possible
		if event.is_action_pressed("move_up_floor"):
			pass
		elif event.is_action_pressed("move_down_floor"):
			pass


#region Player Turn functions
## All Entity turns are called in order by a Queue in TurnManager Autoload
## The Player may decide a number of actions, so the turn begin signal simply unlocks control.
## A turn lasts as long as necessary and is only stopped by a turn-ending action, like
## walking or attacking
func perform_turn() -> void:
	super()
	## Turn is started, the Player gets to decide what to do
	## (currently, this happens in _unhandled_input()

## Called when the Player takes a turn-ending action, like moving or attacking.
func end_turn() -> void:
	super()
#endregion


#region Player pathfinding functions
## Function that handles Pathfinding, combining all other Pathfinding functions
func pathfind() -> void:
	super()

## Pick a goal to move towards based on Entity-specific behaviour
func pick_goal_node() -> void:
	pass  ## Player movement AI goes here!

## Determine next step towards the goal
func find_next_step_to_goal(next_path_pos: Vector2) -> Vector2:
	return super(next_path_pos)

#endregion

#region Player movement
## Attemp to move the Player in a given direction
func move_manually(move_dir) -> void:
	## First, check for any obstacles in chosen neighbouring tile and don't move if there are any
	%ObstacleCast.target_position = inputs_dict[move_dir] * Singleton.TILE_SIZE
	%ObstacleCast.force_raycast_update()
	if !%ObstacleCast.is_colliding():
		position += inputs_dict[move_dir] * Singleton.TILE_SIZE
		## Successful movement ends the Turn
		end_turn()
	

## Place Player on the given *tile* position, if there aren't any obstacles there
## Like any other Entity, used by pathfinding
func move_entity_to_tile(pos: Vector2) -> void:
	super(pos)
#endregion
