extends StaticBody2D
class_name Entity

## Reference to this Entity's NavigationAgent
@export var nav_agent: NavigationAgent2D

#region Turn variables
## Some Entities' Turns can be performed instantly in one frame, while others may want to
## use Godot's 'await', like the Player which must wait for Input.
## Enemy AI typically knows what to immediately, so this is turned on by default.
## Used by TurnManager to know when to wait and when not to.
## WARNING: Turning this on for the Player *will* cause problems.
@export var instant_turn: bool = true

## All Entities are capable of having a Turn. This boolean is switched when it's this Entity's turn.
var is_entity_turn: bool = false

## Signal emmited whenever this Entity finishes its Turn,
## it's required by the TurnManager for the game to proceed
signal ended_turn
#endregion

#region Health variables
@export_group("Health")
## Maximum health
@export_range(1, 100) var max_health: int = 10
## Current health amount out of max_health
var current_health: int = 10
#endregion

#region Damage variables
@export_group("Damage")
## Damage dealt
@export_range(1, 100) var damage_value: int = 2
#endregion

#region Pathfinding variables
## This Entity's goal (a Node), used for pathfinding
var goal: Node2D = self

## Next closest position to move to while pathfinding
var next_pos: Vector2i
#endregion


func _ready() -> void:
	## Set NavAgent's pathfinding settings to work for any TILE_SIZE (which is 16x16 by default).
	## This might not work ideally for unevenly-sized tiles (ex. 12x16)
	##
	## This should be the minimal viable value possible, ideally only a pixel or two
	nav_agent.path_desired_distance = Singleton.TILE_SIZE / 16
	## Ideal distance from Enemy to goal. Since the Enemy moves on a perfect grid,
	## this distance should be a multiple of TILE_SIZE.
	## This should depend on the Enemy's AI; by default, the Enemy wants
	## to be as close as possible to its goal (that is, 1 tile away) 
	nav_agent.target_desired_distance = Singleton.TILE_SIZE
	## How far away the Enemy may stray from the calculated path. Since the Enemy is tied to a grid,
	## they shouldn't stray from the path at all, if possible. Hence, one Tile away from path.
	nav_agent.path_max_distance = Singleton.TILE_SIZE
	
	## Set current_health to max_health
	settle_health()
	

#region Entity Turn functions
## All Entity turns are called in order by a Queue in TurnManager Autoload
func perform_turn() -> void:
	## It's this Entity's Turn now, allow it to take an action
	is_entity_turn = true

## Called when the Entity takes a turn-ending action, like moving or attacking.
## By default, successfully ending a Turn asks the TurnManager for another Turn
func end_turn() -> void:
	is_entity_turn = false
	TurnManager.add_entity_to_turn_queue(self)
	
	## This must be called last
	ended_turn.emit()

## This Turn end without movement.
## What "Rest" means exactly is up to the Entity's AI, but it just ends the turn by default
func rest_turn() -> void:
	end_turn()
#endregion

#region Entity pathfinding functions
## Function that handles Pathfinding, combining all other Pathfinding functions
func pathfind() -> void:
	## Pick a goal from all Entities present in the Room
	pick_goal_node()
	## Find a path to the goal
	var next_path_pos: Vector2i = find_next_step_to_goal()
	
	## Debugging code for paths, snapping to paths
	#var navigation_path = nav_agent.get_current_navigation_path()
	#var tile_coords_nav_path: Array[Vector2]
	#for vect in navigation_path:
		#tile_coords_nav_path.append(vect / Singleton.TILE_SIZE)
	
	#print("NAVIGATION GLOBAL PATH:", navigation_path)
	#print("NAVIGATION TILE PATH:", tile_coords_nav_path)
	#print("Next path position (tile coordinates): ", next_path_pos)
	
	## Finally, decide what the Entity should do with information of their next target Tile
	decide_action(next_path_pos)
	#move_entity_to_tile(next_path_pos)


## Pick a goal to move towards based on Entity-specific behaviour
func pick_goal_node() -> void:
	pass  ## Defined by each Entity's specific AI

## Determine next step towards the goal
func find_next_step_to_goal() -> Vector2i:
	var next_path_pos: Vector2i = nav_agent.get_next_path_position()  ## in non-tile coordinates!
	
	next_path_pos = find_closest_valid_tile(next_path_pos)
	
	#next_path_pos = next_path_pos / Singleton.TILE_SIZE  ## Divided to give tile coordinates!
	#next_path_pos = next_path_pos.snapped(Vector2i(1, 1))  ## Snap to nearest full value
	## This snapping may still break a bit sometimes due to NavAgent's navigation settings,
	## but little errors like that only manifest by picking wrong paths and are rarely noticable.
	return next_path_pos

## Returns the nearest valid (empty) Tile in Tile coordinates, given a position in non-Tile space
func find_closest_valid_tile(next_position: Vector2) -> Vector2i:
	var return_tile_pos: Vector2i
	
	## First, check if a Tile in the given next_position is valid
	return_tile_pos = next_position / Singleton.TILE_SIZE
	return_tile_pos = return_tile_pos.snapped(Vector2i(1, 1))
	if (RoomManager.is_tile_empty(return_tile_pos) == true):
		#print("BASE WORKS")
		## That Tile is empty, so the Entity may indeed go there. This works most of the time.
		return return_tile_pos
	
	
	## If that Tile isn't empty, a different one must be picked. Messily.
	## We will try two more Tiles before giving up, those that are neighbours to next_position Tile.
	## ex. neighbours of Right Tile (1, 0) will be corners (1, -1) and (1, 1); top & bottom right,
	## neighbours of corner Tile (1, 1) will be ortho. (1, 0) and (0, 1); right & bottom middle
	#
	## First, determine next_position's location on a 3x3 grid around the Entity
	## by subtracting it from the Entity's position.
	## This should result in coordinates between (-1, -1) and (1, 1),
	## but only if next_position is adjacent to the Entity. That fact isn't checked here.
	return_tile_pos -= (Vector2i(position) / Singleton.TILE_SIZE)
	
	## Then determine its neighbours in this 3x3 grid. Middle Tile (Entity positon) not included.
	## The checks in this if-tree are done in perceived order of prevelance in-game.
	## The two bottom statements may never even happen.
	var neighbour1: Vector2i
	var neighbour2: Vector2i
	## If next_position Tile is orthogonal to Entity, get corner-neighbours.
	## y is orthogonal - direct left or right to Entity; neighbours are below and above
	if return_tile_pos.y == 0:
		#print("NEIGH BELOW/ABOVE")
		neighbour1 = Vector2i(return_tile_pos.x, -1)
		neighbour2 = Vector2i(return_tile_pos.x, 1)
	## x is orthogonal - direct top or bottom to Entity; neighbours are left and right
	elif return_tile_pos.x == 0:
		#print("NEIGH LEFT/RIGHT")
		neighbour1 = Vector2i(1, return_tile_pos.y)
		neighbour2 = Vector2i(-1, return_tile_pos.y)
	## If not, the next_position Tile is diagonal to Entity.
	## Neighbours are: one horizontal to next_position and one vartical to next_position
	else:
		#print("NEIGH HORIZONTAL/VERTICAL")
		neighbour1 = Vector2i(return_tile_pos.x, 0)
		neighbour2 = Vector2i(0, return_tile_pos.y)
	
	## Now, having the neighbours, translate them to global Tile space instead of this 3x3 grid and
	## check if either of them is empty and return the first valid one.
	neighbour1 += (Vector2i(position) / Singleton.TILE_SIZE)
	neighbour2 += (Vector2i(position) / Singleton.TILE_SIZE)
	if RoomManager.is_tile_empty(neighbour1) == true:
		#print("1 WORKED")
		return neighbour1
	elif RoomManager.is_tile_empty(neighbour2) == true:
		#print("2 WORKED")
		return neighbour2
	else:
		#print("ALL FAILED!")
		return (Vector2i(position) / Singleton.TILE_SIZE)
	
	#print("SOMETHING BROKE: ", return_tile_pos)
	return return_tile_pos

#endregion

#region Entity decisions
## While pathfinding, the Entity must decide whether to move to the next Tile or attack what is
## placed on that Tile, if the Tile contains the Entity's goal. This logic can vary between Entities
func decide_action(tile_position: Vector2i) -> void:
	## If that next Tile is empty, move there
	if RoomManager.is_tile_empty(tile_position) == true:
		move_entity_to_tile(tile_position)
	else:
		## Tile isn't empty, get its contents
		var contents: Array[Node2D] = RoomManager.return_tile_contents(tile_position)
		## Check if this Tile contains our goal
		for content: Node2D in contents:
			if content == goal:
				## TODO: FOR NOW:
				## just attack the goal. This should allow for more than just attacking
				attack_at_tile(tile_position)
#endregion

#region Entity movement
## Place this Entity on the given *tile* position, if there aren't any obstacles there.
## If movement succeeds, end turn. If it fails, rest
func move_entity_to_tile(pos: Vector2i) -> void:
	#print("Entity taget pos: ", pos)
	var current_pos: Vector2i = translate_position_to_tile_pos(position)
	## Movement has no point if the Entity just wants to remain where they are
	if pos != current_pos:
		## If a given Tile is empty, move the Entity to that spot
		## and update its position in RoomManger's RoomData Resource
		if RoomManager.is_tile_empty(pos):
			position = pos.snapped(Vector2i.ONE) * Singleton.TILE_SIZE
			RoomManager.move_entity(current_pos, pos)
		else:
			push_warning("CAN'T MOVE ENTITY(ID: ", self, "), OBSTACLE DETECTED AT: ", pos)
		
	## Remaining in place is a Rest Turn
	else:
		rest_turn()
		return
	
	## No matter if it succeeded, movement ends a Turn
	end_turn()
#endregion

#region Entity position setup
## Places the given Entity at the Tile's provided position.
## Doesn't end the Entity's turn.
## DOESN'T ACCOUNT FOR OBSTACLES, OTHER SCRIPTS SHOULD HANDLE THAT
func place_entity_at_tile(pos: Vector2i) -> void:
	position = pos.snapped(Vector2i.ONE) * Singleton.TILE_SIZE
	## Also place the Entity in RoomManager's RoomData Resource
	RoomManager.place_entity(pos, self)

## Called on _ready(), sets current_health to maximum_health
func settle_health() -> void:
	current_health = max_health
#endregion

#region Health functions
## Heal the Entity by given health_amount
func heal_health(heal_amount: int) -> void:
	current_health += heal_amount
	current_health = clampi(current_health, 0, max_health)
	
	print("Entity ", self, " has been healed for ", heal_amount, \
	"; HP: ", current_health,"/",max_health)

## Damage the Entity by given damage_amount
func damage_health(damage_amount: int) -> void:
	current_health -= damage_amount
	current_health = clampi(current_health, 0, max_health)
	
	print("Entity ", self, " has been hit for ", damage_amount, \
		"; HP: ", current_health,"/",max_health)
	
	if current_health <= 0:
		kill_entity()

## Entity lost all HP, kill it
func kill_entity() -> void:
	print("Entity ", self, " is dead!")
	## Before freeing, remove all of this Entity's Turns from TurnManager's turn_queue
	TurnManager.remove_entity_from_turn_queue(self)
	## and remove Entity from RoomManager's keeper of Entities
	RoomManager.remove_entity(translate_position_to_tile_pos(position), self)
	queue_free()
#endregion

#region Dealing damage
## Attempt to attack whatever is present on the given Tile.
## Doesn't check for distance or what is being attacked,
## assumes Tile is within reach and goal is there.
func attack_at_tile(tile_position: Vector2i) -> void:
	#print("Attempted attack at tile position: ", tile_position)
	## Can only attack if that given Tile isn't empty
	if RoomManager.is_tile_empty(tile_position) == false:
		var contents: Array[Node2D] = RoomManager.return_tile_contents(tile_position)
		for content: Node2D in contents:
			if content == goal and goal is Entity:
				goal.damage_health(damage_value)
	
	## Attempted attacks result in end of Turn
	end_turn()
#endregion

#region Utility functions
## Takes given position Vector2 and divides it by TILE_SIZE to get that position
## but in Tile space and returns that as Vector2i
func translate_position_to_tile_pos(regular_pos: Vector2) -> Vector2i:
	return Vector2i(regular_pos.x / Singleton.TILE_SIZE, regular_pos.y / Singleton.TILE_SIZE)

## Takes given Tile position Vector2i and multiplies it by TILE_SIZE to get that position
## but in regular position space and returns that as Vector2
func translate_tile_pos_to_position(tile_pos: Vector2i) -> Vector2:
	return Vector2(tile_pos.x * Singleton.TILE_SIZE, tile_pos.y * Singleton.TILE_SIZE)
#endregion
