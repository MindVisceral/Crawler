extends Node2D

@export_group("Room data")
## Amount of tiles in a room
@export_range(5, 256, 1) var ROOM_SIZE: int = 64

@export_group("Tile data")
## Size of a given tile (x by x)
@export_range(1, 128, 1) var TILE_SIZE: int = 32
## Reference to a tile
@export var tile: PackedScene

@export_group("Noise")
## Noise generator
@export var altitude_noise: FastNoiseLite 
## Noise level
@export_range(0, 1, 0.01) var SEA_LEVEL: float = 0.2

## Generates a room of given size with given tiles
func _ready() -> void:
	## Generate a room in x by y size
	for x in ROOM_SIZE:
		for y in ROOM_SIZE:
			generate_terrain_tile(x, y)
			
		
	

## Generates a tile at given position
func generate_terrain_tile(x: int, y: int):
	var new_tile: Tile = tile.instantiate()
	## New tile's type depending on altitude
	new_tile.tile_type = get_altitude(x, y)
	## New tile's position
	new_tile.position = Vector2(x, y) * TILE_SIZE
	## Change tile's size to fit
	new_tile.change_tile_size(TILE_SIZE);
	
	## Add new tile as child
	add_child(new_tile)


## Returns tile type for altitude at given position
func get_altitude(x: int, y: int) -> Tile.TileType:
	## Samples referenced noise to get altitude value
	var altitude = altitude_noise.get_noise_2d(x, y)
	
	if altitude >= SEA_LEVEL:
		return Tile.TileType.LAND
		
	
	return Tile.TileType.SEA
