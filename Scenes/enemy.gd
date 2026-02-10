extends Entity
class_name Enemy

#region IDs
## ID of this Enemy type, assigned manually (could be a Name instead?)
@export var enemy_type_id: int = 0
#endregion

func _ready() -> void:
	super()

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

#region Enemy Turn functions
## All Entity turns are called in order from a Queue in TurnManager Autoload
func perform_turn() -> void:
	super()
	
	## Navigation doesn't happen without these circumstances being right
	if NavigationServer2D.map_get_iteration_id(nav_agent.get_navigation_map()) == 0:
		print("No navmap")
		return
	## Turn is started by finding a a path to the Entity's goal, which included finding this goal
	pathfind()
#endregion

#region Enemy pathfinding functions
## Function that handles Pathfinding, combining all other Pathfinding functions
func pathfind() -> void:
	super()


## Pick a goal to move towards based on Enemy-specific behaviour
func pick_goal_node() -> void:
	super()
	## By default, just pick the Player, if present, from all Entities in the Room
	for entity: StaticBody2D in EntityManager.entities:  ## Array of Entities from EntityManager
		if entity is Player:
			## Set as target for pathfinding
			goal = entity
			nav_agent.target_position = goal.global_position  ## in non-tile coordinates!
			break  ## Stop looking for more goals

## Determine next step towards the goal
func find_next_step_to_goal(next_path_pos: Vector2) -> Vector2:
	return super(next_path_pos)

#endregion

#region Enemy movement
## Place this Enemy on the given *tile* position, if there aren't any obstacles there
func move_entity_to_tile(pos: Vector2) -> void:
	super(pos)
#endregion
