extends Node
class_name RoomEnemyFiller

#region Exports
## Reference to the Tileset Node (unused!)
@export var RoomTileset: TileMapLayer
@export var GameScript: GameManager

## Reference to the Node the Enemies will be children of.
@export var enemy_parent_node: Node2D


@export_group("Enemies")
## Array of Enemies that can be spawned in this Room
@export var enemy_types: Array[PackedScene]

## Amount of Enemies present in the Room
@export_range(0, 128, 1) var enemy_amount: int = 3

## Actual count of Enemies will be modified by this value
@export_range(0, 4, 0.1) var random_amount_multiplier: float = 1.0
#endregion

#region Variables
## Resource containing all information of a given Room
var room_data: RoomData

## Dictionary of Enemies placed in the Room
var enemies_dict: Dictionary[Vector2i, Entity] = {}
#endregion

## The RoomData Resource must be passed on
func retrieve_room_data(new_room_data: RoomData) -> void:
	room_data = new_room_data

## Called by GameManager when generating a base room is done
func begin_filling_room() -> void:
	## First, make a Queue of Enemies to spawn
	enemy_amount *= random_amount_multiplier + randf() * (random_amount_multiplier - 1.0);
	var enemies: Array[Enemy]
	for en: int in enemy_amount:
		## Pick a random type of an Enemy from enemy_types
		var rand_type_enemy: PackedScene = enemy_types.pick_random()
		enemies.append(rand_type_enemy.instantiate())
	
	## Find all empty Tiles in the Room and store them in this Array.
	## Occupation status is stored in the RoomData Resource
	var empty_tiles: Array[Vector2i] = []
	var room_status: Dictionary[Vector2i, bool] = room_data.return_tiles_occupation_dict()
	for tile: Vector2i in room_status:
		if room_status[tile] == false:
			empty_tiles.append(tile)
	
	## Now, as long as there is an empty tile and an Enemy that can be placed there,
	## choose one randomly and "place" it there
	while empty_tiles.is_empty() == false && enemies.is_empty() == false:
		## Pick an empty tile to be filled with an Enemy
		var tile: Vector2i = empty_tiles.pick_random()
		empty_tiles.erase(tile)
		
		## Place a random Enemy on that tile
		var enemy: Enemy = enemies.pick_random()
		enemies.erase(enemy)
		enemy_parent_node.add_child(enemy)
		
		## Add this Enemy to dictionary of Entities, which will be added to RoomData
		enemies_dict[tile] = enemy
		
		## Enemy setup
		enemy.place_entity_at_tile(tile)
		## rest of setup goes here, if neccessary
	
	## Filling the Room with Enemies is done.
	completed_filling_room()

## Pass on important level information to the Game script so the next step may begin
func completed_filling_room() -> void:
	## Most important bit of information, Enemies we just generated and placed
	room_data.room_entities.merge(enemies_dict)
	
	## Pass the information, the next step may begin
	GameScript.retrieve_room_data(room_data)
