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

## Called when the Entity takes a turn-ending action, like moving or attacking.
## By default, successfully ending a Turn asks the TurnManager for another Turn
func end_turn() -> void:
	super()
#endregion

#region Enemy pathfinding functions
## Function that handles Pathfinding, combining all other Pathfinding functions
func pathfind() -> void:
	super()


## Pick a goal to move towards based on Enemy-specific behaviour
func pick_goal_node() -> void:
	super()
	## By default, just pick the Player, if present, from all Entities in the Room
	## Array of Entities from EntityManager
	#for entity: Entity in RoomManager.room_data.room_entities:
		#if entity is Player:
			### Set as target for pathfinding
			#goal = entity
			#nav_agent.target_position = goal.global_position  ## in non-tile coordinates!
			#break  ## Stop looking for more goals

## Determine next step towards the goal
func find_next_step_to_goal(next_path_pos: Vector2i) -> Vector2i:
	return super(next_path_pos)

#endregion

#region Enemy movement
## Place this Enemy on the given *tile* position, if there aren't any obstacles there
func move_entity_to_tile(pos: Vector2i) -> void:
	super(pos)
#endregion
