extends Entity
class_name Player

#region Variables
## Possible room movement inputs as Dictionary
var inputs_dict: Dictionary[String, Vector2i] = {
	"move_stay": Vector2i.ZERO,
	"move_up": Vector2i.UP,
	"move_down": Vector2i.DOWN,
	"move_right": Vector2i.RIGHT,
	"move_left": Vector2i.LEFT,
	"move_up_right": Vector2i(1, -1),
	"move_down_right": Vector2i(1, 1),
	"move_up_left": Vector2i(-1, -1),
	"move_down_left": Vector2i(-1, 1)
}
#endregion


func _ready() -> void:
	super()
	
	## Player must be snapped to closest tile
	position = position.snapped(Vector2.ONE * Singleton.TILE_SIZE)

## Player Input for movement
func _unhandled_input(event: InputEvent) -> void:
	## Movement only works if it's the Players Turn!
	if is_entity_turn == true:
		## Match Player input to input direction Dictionary and attempt to move in that direction
		for move_dir in inputs_dict.keys():
			if event.is_action_pressed(move_dir):
				print("MOVED")
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

## Called when the Player opts to Rest for a Turn.
## (for now, just ends the Turn)
func rest_turn() -> void:
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
func find_next_step_to_goal(next_path_pos: Vector2i) -> Vector2i:
	return super(next_path_pos)

#endregion

#region Player movement
## Attemp to move the Player in a given direction
func move_manually(move_dir: String) -> void:
	## If the chosen Tile is the current Tile, the Player will just rest for a Turn
	## and the remaining code will be ignored. Resting end the turn.
	if inputs_dict[move_dir] == Vector2i.ZERO:
		rest_turn()
		return
	
	## First, get the Tile to which the Player will move to,
	## which is the Player's position in Tile space + movement direction
	var target_tile: Vector2i = Vector2i(self.position.x / Singleton.TILE_SIZE, \
	self.position.y / Singleton.TILE_SIZE) \
		+ inputs_dict[move_dir]
	
	## And check if that Tile is empty. If so, move there.
	if RoomManager.room_data.is_tile_empty(target_tile) == true:
		## Move the Player's position to that Tile
		## and record the change in RoomManager's RoomData Resource.
		## NOTE: inputs_dict[] dictionary is of Vector2i, so that has to be translated to Vector2
		position += Vector2(inputs_dict[move_dir].x, inputs_dict[move_dir].y) * Singleton.TILE_SIZE
		RoomManager.move_entity(target_tile - inputs_dict[move_dir], target_tile)
		
		## Successful movement ends the Turn
		end_turn()
	

## Place Player on the given *tile* position, if there aren't any obstacles there
## Like any other Entity, used by pathfinding
func move_entity_to_tile(pos: Vector2i) -> void:
	super(pos)
#endregion
