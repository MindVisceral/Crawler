extends Node
class_name RoomEnemyFiller

#region Exports
## Tileset (unused!)
@export var RoomTileset: TileMapLayer

## Reference to the Node the Enemies will be children of.
## This Node also knows all Entities, so it can be used for pathfinding's targetting
@export var enemy_parent_node: Node2D


@export_group("Enemies")
## Array of Enemies that can be spawned in this Room
@export var enemy_types: Array[PackedScene]

## Amount of Enemies present in the Room
@export_range(0, 128, 1) var enemy_amount: int = 3

## Actual count of Enemies will be modified by this value
@export_range(0, 4, 0.1) var random_amount_multiplier: float = 1.0
#endregion

#region Veriables
## Resource containing all information of a given Room
var room_data: RoomData

## Dictionary of Enemies placed in the Room
var enemies_dict: Dictionary[int, int] = {}
#endregion


## Called by RoomGenerator when it's done generating a base room
func start_filling_room() -> void:
	## First, make a Queue of Enemies to spawn
	enemy_amount *= random_amount_multiplier + randf() * (random_amount_multiplier - 1.0);
	var enemies: Array[Enemy]
	for en: int in enemy_amount:
		## Pick a random type of an Enemy from enemy_types
		var rand_type_enemy: PackedScene = enemy_types.pick_random()
		enemies.append(rand_type_enemy.instantiate())
	
	## Find all empty spaces in the Room and store them in this Array
	var empty_tiles: Array[Vector2] = []
	for tile: Vector2 in room_data.room_terrain:
		if room_data.room_terrain[tile] == false:
			empty_tiles.append(tile)
	
	## Now, as long as there is an empty tile, choose one randomly and "place" an Enemy there
	while empty_tiles.is_empty() == false && enemies.is_empty() == false:
		## Pick an empty tile to be filled with an Enemy
		var tile: Vector2 = empty_tiles.pick_random()
		empty_tiles.erase(tile)
		
		## Place a random Enemy on that tile
		var enemy: Enemy = enemies.pick_random()
		enemies.erase(enemy)
		enemy_parent_node.add_child(enemy)
		## Enemy added to Singleton EntityManager list of Entities
		EntityManager.entities.append(enemy)
		## Enemy setup
		enemy.move_enemy_to_tile(tile)
