extends StaticBody2D
class_name Entity

## Reference to this Entity's NavigationAgent
@export var nav_agent: NavigationAgent2D

#region Turn variables
## All Entities are capable of having a Turn. This boolean is switched when it's this Entity's turn.
var is_entity_turn: bool = false
#endregion

#region Pathfinding variables
## This Entity's goal (a Node), used for pathfinding
var goal: Node2D = self

## Next closest position to move to while pathfinding
var next_pos: Vector2
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

func _physics_process(delta: float) -> void:
	### Navigation doesn't happen without these circumstances being right
	#if NavigationServer2D.map_get_iteration_id(nav_agent.get_navigation_map()) == 0:
		#print("No navmap")
		#return
	#if nav_agent.is_navigation_finished():
		#print("Done with navigation")
		#return
	
	## Run the pathfinding algorithm, including targetting (finding the Enemy's goal)
	#pathfind()
	pass

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
	TurnManager.report_turn_finished()  ## This must be called last
#endregion

#region Entity pathfinding functions
## Function that handles Pathfinding, combining all other Pathfinding functions
func pathfind() -> void:
	## Pick a goal from all Entities present in the Room
	pick_goal_node()
	## Find a path to the goal
	var next_path_pos: Vector2
	next_path_pos = find_next_step_to_goal(next_path_pos)
	
	## Debugging code for paths, snapping to paths
	#var navigation_path = nav_agent.get_current_navigation_path()
	#var tile_coords_nav_path: Array[Vector2]
	#for vect in navigation_path:
		#tile_coords_nav_path.append(vect / Singleton.TILE_SIZE)
	
	#print("NAVIGATION GLOBAL PATH:", navigation_path)
	#print("NAVIGATION TILE PATH:", tile_coords_nav_path)
	#print("Next path position (tile coordinates): ", next_path_pos)
	
	## Finally, move Entity to next tile position,
	## as determined by find_next_step_to_goal()
	move_entity_to_tile(next_path_pos)


## Pick a goal to move towards based on Entity-specific behaviour
func pick_goal_node() -> void:
	pass  ## Defined by each Entity's specific AI

## Determine next step towards the goal
func find_next_step_to_goal(next_path_pos: Vector2) -> Vector2:
	next_path_pos = nav_agent.get_next_path_position()  ## in non-tile coordinates!
	next_path_pos = next_path_pos / Singleton.TILE_SIZE  ## Divided to give tile coordinates!
	next_path_pos = next_path_pos.snapped(Vector2i(1, 1))  ## Snap to nearest full value
	## This snapping may still break a bit sometimes due to NavAgent's navigation settings,
	## but little errors like that only manifest by picking wrong paths and are rarely noticable.
	return next_path_pos

#endregion

#region Entity movement
## Place this Entity on the given *tile* position, if there aren't any obstacles there
func move_entity_to_tile(pos: Vector2) -> void:
	print("CALLED ENTITY MOVEMENT FOR ", self)
	## Passed 'pos' position is in tile coordinates, so it has to be adjusted
	## so the raycast will fire and see objects locally, in relation to Entity space
	var ray_target_pos: Vector2 = \
		(pos - (self.position / Singleton.TILE_SIZE)) * Singleton.TILE_SIZE
	%ObstacleCast.target_position = ray_target_pos
	%ObstacleCast.force_raycast_update()
	
	## If not obstacles are present, allow for the Entity to move there
	if !%ObstacleCast.is_colliding():
		position = pos.snapped(Vector2.ONE) * Singleton.TILE_SIZE
	else:
		push_warning("CAN'T MOVE ENTITY(ID: ", self, "), OBSTACLE DETECTED: ", %ObstacleCast.get_collider())
	
	## No matter if it succeeded, movement ends a Turn
	end_turn()
#endregion

#region Entity setup
## Places the given Entity at the Tile's provided position.
## Doesn't end the Entity's turn.
## DOESN'T ACCOUNT FOR OBSTACLES, OTHER SCRIPTS SHOULD HANDLE THAT
func place_entity_at_tile(pos: Vector2) -> void:
	position = pos.snapped(Vector2.ONE) * Singleton.TILE_SIZE
#endregion
