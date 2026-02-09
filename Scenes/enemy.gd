extends StaticBody2D
class_name Enemy

## Reference to this Enemy's NavigationAgent
@export var nav_agent: NavigationAgent2D

#region IDs
## ID of this Enemy type, assigned manually (could be a Name instead?)
@export var enemy_type_id: int = 0
## ID of this specific Enemy, assigned by this Enemy's manager
var enemy_id: int = 0
#endregion

#region Pathfinding variables
## This Enemy's goal (a Node), used for pathfinding
var goal: Node2D = self

## Next closest position to move to in pathfinding
var next_pos: Vector2
#endregion


func _physics_process(delta: float) -> void:
	## Navigation doesn't happen without these circumstances being right
	if NavigationServer2D.map_get_iteration_id(nav_agent.get_navigation_map()) == 0:
		print("No navmap")
		return
	#if nav_agent.is_navigation_finished():
		#print("Done with navigation")
		#return
	
	## Run the pathfinding algorithm, including targetting (finding the Enemy's goal)
	pathfind()

#region Enemy pathfinding functions
## Function that handles Pathfinding, combining all other Pathfinding functions
func pathfind() -> void:
	## Timer, in place of a Queue/Turn system
	if !%TurnTimer.is_stopped():
		return
	%TurnTimer.start()
	
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
	
	## Finally, move Enemy to next tile position,
	## as determined by find_next_step_to_goal()
	move_enemy_to_tile(next_path_pos)


## Pick a goal to move towards based on Enemy-specific behaviour
func pick_goal_node() -> void:
	## By default, just pick the Player, if present, from all Entities in the Room
	for entity: StaticBody2D in EntityManager.entities:  ## Array of Entities from EntityManager
		if entity is Player:
			## Set as target for pathfinding
			goal = entity
			nav_agent.target_position = goal.global_position  ## in non-tile coordinates!
			break  ## Stop looking for more goals

## Determine next step towards the goal
func find_next_step_to_goal(next_path_pos: Vector2) -> Vector2:
	next_path_pos = nav_agent.get_next_path_position()  ## in non-tile coordinates!
	next_path_pos = next_path_pos / Singleton.TILE_SIZE  ## Divided to give tile coordinates!
	next_path_pos = next_path_pos.snapped(Vector2i(1, 1))  ## Snap to nearest full value
	## This snapping may still break a bit sometimes due to NavAgent's navigation settings,
	## but little errors like that only manifest by picking wrong paths and are rarely noticable.
	return next_path_pos

#endregion

#region Enemy movement
## Place this Enemy on the given *tile* position, if there aren't any obstacles there
func move_enemy_to_tile(pos: Vector2) -> void:
	## Passed 'pos' position is in tile coordinates, so it has to be adjusted
	## so the raycast will fire and see objects locally, in relation to Enemy space
	var ray_target_pos: Vector2 = \
		(pos - (self.position / Singleton.TILE_SIZE)) * Singleton.TILE_SIZE
	%ObstacleCast.target_position = ray_target_pos
	%ObstacleCast.force_raycast_update()
	
	## If not obstacles are present, allow for the Enemy to move there
	if !%ObstacleCast.is_colliding():
		position = pos.snapped(Vector2.ONE) * Singleton.TILE_SIZE
	else:
		push_error("CAN'T MOVE ENEMY(", self, "), OBSTACLE DETECTED: ", %ObstacleCast.get_collider())
#endregion
