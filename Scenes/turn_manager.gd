extends Node

## This script keeps track of Turn orders of the Player and Enemies

## Array of Turns that acts like a Queue
var turn_queue: Array[Entity]
## The Entity that is currently peforming its Turn
var current_turn_user: Entity


## The game is ready to start.
func begin_game() -> void:
	print("TURN QUEUE:", turn_queue)
	
	## The Player always gets the very first turn. It must be found and put to the front
	for entity: Entity in turn_queue:
		if entity is Player:
			turn_queue.push_front(turn_queue.pop_at(turn_queue.find(entity)))
	
	## Now that the game is ready, call the next Entity's turn.
	next_entity_begin_turn()

## Tells the next Entity in Queue to begin its turn.
func next_entity_begin_turn() -> void:
	if !turn_queue.is_empty():
		## Take the Entity from the front of the Queue and remove it.
		current_turn_user = turn_queue.front()
		## If an Entity wants to have another turn, it will have to request one
		turn_queue.erase(current_turn_user)
		current_turn_user.perform_turn()

## If a given Entity's turn is finished, it must call this function so that the game may proceed
func report_turn_finished() -> void:
	pass

## This function is called when an Entity must be added to the Turn Queue
func add_entity_to_turn_queue(entity: Entity) -> void:
	turn_queue.append(entity)
