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
		## Match Player input to input direction Dictionary
		for move_dir in inputs_dict.keys():
			if event.is_action_pressed(move_dir):
				#move_manually(move_dir)
				## and translate the movement direction to Tile position
				## and make the Player decide what to do with it
				decide_action(translate_input_to_tile_pos(move_dir))
		
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
	#print("PLAYER Rest Turn")
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

#region Player decisions
## The Player will automatically decide to move or attack a given Tile.
## "Moving" at an occupied Tile attacks it automatically
func decide_action(tile_position: Vector2i) -> void:
	## If the Player chose their current Tile as the target Tile, that's considered a Rest Turn
	if tile_position == translate_position_to_tile_pos(position):
		rest_turn()
		return
	
	## If it's not a Rest Turn, try movement.
	## Player moves only if the target Tile is empty
	if RoomManager.room_data.is_tile_empty(tile_position) == true:
		move_entity_to_tile(tile_position)
	## If target Tile isn't empty, there's an Entity there, so attack it.
	else:
		## Tile isn't empty, get its contents
		var contents: Array[Node2D] = RoomManager.room_data.return_tile_contents(tile_position)
		## Check if this Tile contains an Enemy
		for content: Node2D in contents:
			if content is Entity:
				## TODO: FOR NOW:
				## just attack the Enemy. This should allow for more than just attacking
				attack_at_tile(tile_position)
#endregion

#region Player movement
## Moves Player to a given Tile position without checking if it's valid.
## Differs from most Entities' movement; Rest Turns are handled earlier in the script in
## decide_action() function and failed Turns cannot occur.
func move_entity_to_tile(pos: Vector2i) -> void:
	var current_pos: Vector2i = translate_position_to_tile_pos(position)
	position = pos.snapped(Vector2i.ONE) * Singleton.TILE_SIZE
	RoomManager.move_entity(current_pos, pos)
	
	## End the Turn after successful movement
	end_turn()
#endregion

#region Dealing damage
## Attempt to attack whatever is present on the given Tile.
## Identical to Entity versin of this function, but doesn't check for goal.
## TODO: It should, once more than 1 thing can be present on a Tile.
func attack_at_tile(tile_position: Vector2i) -> void:
	print("Player attempted attack at tile position: ", tile_position)
	## Can only attack if that given Tile isn't empty
	if RoomManager.room_data.is_tile_empty(tile_position) == false:
		var contents: Array[Node2D] = RoomManager.room_data.return_tile_contents(tile_position)
		for content: Node2D in contents:
			if content is Entity:
				content.damage_health(damage_value)
	
	## Attempted attacks result in end of Turn
	end_turn()
#endregion

#region Utility functions
## This function takes an Input direction (string)
## and translates it to get a target Tile in Tile space,
## taking the Player's current position into consideration.
func translate_input_to_tile_pos(input_dir: String) -> Vector2i:
	var return_tile_pos: Vector2i
	return_tile_pos = (Vector2i(position.x, position.y) / Singleton.TILE_SIZE) \
		+ inputs_dict[input_dir]
	
	return return_tile_pos
#endregion
