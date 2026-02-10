extends Node

## This script keeps track of Turn orders of the Player and Enemies

## Array of Turns that acts like a Queue
var turn_queue: Array[StaticBody2D]
## The Entity that is currently peforming its Turn
var current_turn_user: StaticBody2D


func _physics_process(delta: float) -> void:
	pass

## Tells the next Entity in Queue to begin its turn.
func call_begin_turn() -> void:
	## Take the Entity from the front of the Queue and remove it.
	current_turn_user = turn_queue.front()
	## If an Entity wants to have another turn, it will have to request one
	turn_queue.erase(current_turn_user)
	#current_turn_user.  ## turn call. Need to add an Entity class

## If a given Entity's turn is finished, it must call this function for the game to proceed
func report_turn_finished() -> void:
	pass

## Entities call this function to be added to the Queue
func request_add_queue() -> void:
	pass
