extends Node

## This script keeps track of Turn orders of the Player and Enemies

## Array of Turns that acts like a Queue
var turn_queue: Array[Entity]
## This is the Turn Queue for the next Round.
## Adding Entities to the turn_queue directly would cause a never-ending loop
var next_round_turn_queue: Array[Entity]
## The Entity that is currently peforming its Turn
var current_turn_user: Entity


## The game is ready to start.
func begin_game() -> void:
	## The Player always gets the very first turn. Player must be found and put to the front
	## of the queue.
	for entity: Entity in turn_queue:
		if entity is Player:
			turn_queue.push_front(turn_queue.pop_at(turn_queue.find(entity)))
	
	## Set the first Entity in the Queue (the Player, if present) as the next in line
	current_turn_user = turn_queue.front()
	#print("STARTING TURN QUEUE:", turn_queue)
	#print("STARTING TURN BELONGS TO: ", current_turn_user)
	
	## Game is ready, enter the main turn-processing loop
	process_turns()

## This function *is* the game. It handles each Turn in turn_queue one by one
func process_turns() -> void:
	## Needs a check for ending the game/pausing Turn processing
	## (outside of regular Player-Turn pseudo-pauses)
	while (true):
		## If there are no Entities to have a Turn,
		## wait until the next physics frame, hoping for more Entities to be added
		if turn_queue.is_empty() == true:
			## Turn_queue has been emptied, fill it up for the next Round of Turns
			## and empty the next_round_turn_queue
			turn_queue = next_round_turn_queue.duplicate(true)
			next_round_turn_queue.clear()
			#print("QUEUE PREPARED")
			## Wait a frame, and being the next Round
			await get_tree().physics_frame
			continue
		
		## Otherwise, if there are Entities to take a Turn, process the next one in Queue.
		## Take the Entity from the front of the Queue and remove it.
		## If an Entity wants to have another turn, it will have to request one
		current_turn_user = turn_queue.pop_front()
		#print("TURN QUEUE:", turn_queue)
		#print("CURRENT TURN BELONGS TO: ", current_turn_user)
		current_turn_user.perform_turn()
		
		## If a given Entity has instant Turns turned on, the game should NOT use await.
		## Currently this is only used so the Player can actually Input their Turn
		if current_turn_user.instant_turn == false:
			await current_turn_user.ended_turn

## This function is called when an Entity must be added to the Turn Queue next Round
func add_entity_to_turn_queue(entity: Entity) -> void:
	#print("ADDED ", entity, " TO (NEXT) TURN QUEUE")
	next_round_turn_queue.append(entity)

## This function removes all instances of a given Entity in the turn_queue
## and the queue for the next round
func remove_entity_from_turn_queue(entity: Entity) -> void:
	## Loop through the whole Array and find all instances of this Entity
	## NOTE: Has to be done backwards since looping through and removing each instance
	## can results in bugs with Godot Arrays 
	turn_queue = turn_queue.filter(func(x): return x != entity)
	next_round_turn_queue = next_round_turn_queue.filter(func(x): return x != entity)
