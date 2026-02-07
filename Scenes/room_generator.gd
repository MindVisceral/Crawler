extends Node2D

@export var tilemaplayer: TileMapLayer


@export_group("Room seeding")
## Room seed, 0 by default
@export_range(-9999, 9999, 1) var room_seed: int = 0
## Makes the room's seed random each time; without this, the room will remain the same
@export var randomize_seed: bool = false

@export_group("Room data")
## Percent of room filled with walls
@export_range(0, 100, 1) var fill_percent: int = 45
## Amount of smoothing iterations before room is done
@export_range(0, 10, 1) var smoothing_iterations: int = 4
## 
@export_range(5, 100, 1) var min_room_size: int = 50
## Amount of empty space around given room's entry and exit points
@export_range(1, 10, 1) var access_size: int = 5;

@export_group("Room settings")
## Room size
@export_range(5, 256) var room_width: int = 64
@export_range(5, 256) var room_height: int = 64
## Maximum amount of attemps to generate a room before algorithm gives up
@export_range(0, 32) var max_generation_attempts: int = 16

@export_group("Miscellaneous")
## Should a given room have closed edges?
@export var should_be_closed: bool = true

## Kinds of tiles
const WALL_TILE: int = 0
const EMPTY: int = -1

## Stores a given generated room
var room: Dictionary = {}
## Start position in given room
var start_point: Vector2
## End position in given room
var end_point: Vector2


func _ready() -> void:
	## Randomize the seed
	if randomize_seed == true:
		room_seed += randi()
	
	generate_level(Vector2(2, 5), Vector2(10, 10))


## Generates level comprised of rooms
func generate_level(start: Vector2, end: Vector2) -> void:
	## Attempts at generation
	var attempt: int = 0
	## Check if given map is valid
	var room_is_valid: bool = false
	
	## Generating rooms while possible
	while !room_is_valid and attempt < max_generation_attempts:
		attempt += 1
		
		## Clear map data
		room.clear()
		
		## New room, 'attempt' is a seed
		init_room(attempt)
		
		## Smooths out above generated room
		for i in smoothing_iterations:
			smooth_room()
		
		## Make space around start and end points to allow for movement
		make_space(start_point, access_size)
		make_space(end_point, access_size)
		
		## Check if given room can even be traversed
		room_is_valid = check_path_exists()
	
	
	## Generating completed. If no room was created, give up.
	if room_is_valid == false:
		push_error("Failed to generate a valid map after %d attempts" % max_generation_attempts)
	
	## Create walls at room edges if that option is checked
	if should_be_closed == true:
		force_walls()
	
	## Get the generated room and apply it to a TileMap
	apply_to_tilemap()


## Generates a room randomly
func init_room(seed_value: int) -> void:
	seed(seed_value * room_seed)
	## Position; made a variable as to not create a new one every loop
	var pos: Vector2 = Vector2(0, 0)
	
	## Initial room filling
	for x in range(room_width):
		for y in range(room_height):
			pos = Vector2(x, y)
			
			## Fills the rooms's edges
			if x == 0 || x == room_width - 1 || y == 0 || y == room_height - 1:
				room[pos] = true
			## Randomly decides if given tile is filled or not
			else:
				room[pos] = randf() * 100 < fill_percent

## Smooths out the current room
func smooth_room() -> void:
	## Position; made a variable as to not create a new one every loop
	var pos: Vector2 = Vector2(0, 0)
	
	## New room, result of smoothing
	var new_room: Dictionary = {}
	for x in range(room_width):
		for y in range(room_height):
			pos = Vector2(x, y)
			## Get amount of wall tiles surrounding the given tile
			var wall_count = get_surrounding_wall_count(pos)
			
			## Made up cellular automata rules.
			if wall_count > 4:
				new_room[pos] = true
			elif wall_count < 4:
				new_room[pos] = false
			else:
				new_room[pos] = room[pos]
	
	## Update room data
	room = new_room

## Returns o the amount of wall tiles around a tile at given position
func get_surrounding_wall_count(pos: Vector2) -> int:
	var wall_count: int = 0
	## Check position; made a variable as to not create a new one every loop
	var check_pos: Vector2 = Vector2(0, 0)
	
	## Keep in mind: range stops *before* '2', so we get a 3x3 grid
	for x in range(-1, 2):
		for y in range(-1, 2):
			check_pos = Vector2(pos.x + x, pos.y + y)
			if check_pos != pos:
				if room.get(check_pos, true):
					wall_count += 1
	
	return wall_count



## Make some empty space around given position
func make_space(center: Vector2, radius: int) -> void:
	## Position; made a variable as to not create a new one every loop
	var pos: Vector2 = Vector2(0, 0)
	
	## Check for (radius) tiles around the given position
	for x in range(-radius, radius+1):
		for y in range(-radius, radius+1):
			pos = Vector2(center.x + x, center.y + y)
			## If given surrounding tile is outside of the room's boundaries, it will be ignored
			if pos.x >= 0 && pos.x < room_width && \
			pos.y >= 0 && pos.y < room_height:
				## Otherwise, that tile is made empty
				if Vector2(x, y).length() <= radius:
					room[pos] = false

## Check if there is a valid path between entry and exit points
## with A* algorithm
func check_path_exists() -> bool:
	var astar = AStar2D.new()
	## Position; made a variable as to not create a new one every loop
	var pos: Vector2 = Vector2(0, 0)
	
	## Empty tiles are added to A*, wall tiles are ignored
	for x in range(room_width):
		for y in range(room_height):
			pos = Vector2(x, y)
			## Given tile is empty, add it to A*'s list
			if room[pos] == false:
				var point_id: int = get_point_id(pos)
				astar.add_point(point_id, pos)
	
	## Tiles that are neighbours will be connected
	for x in range(room_width):
		for y in range(room_height):
			pos = Vector2(x, y)
			## Only check for neighbours if a given tile is empty
			if room[pos] == false:
				## Get given tile's ID
				var point_id: int = get_point_id(pos)
				
				## Check all orthogontal neighbours and connect this tile to each if it's valid
				for neighbour in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
					var next_pos: Vector2 = pos + neighbour
					## Neighbour must be valid
					if is_valid_empty_pos(next_pos):
						## A* connection
						var next_id := get_point_id(next_pos)
						if !astar.are_points_connected(point_id, next_id):
							astar.connect_points(point_id, next_id)
	
	## Check if there's a way to get from start to end with A*.
	## Check is invalid even if there's a diagonal connection. We want *rooms*  without those.
	var start_id = get_point_id(start_point)
	var end_id = get_point_id(end_point)
	
	return astar.has_point(start_id) && astar.has_point(end_id) && \
		astar.get_point_path(start_id, end_id).size() > 0
	
	return false

## Returns given tile's ID, based on the tile's position in the room
func get_point_id(pos: Vector2) -> int:
	return int(pos.x + pos.y * room_width)

## A given tile can't be at the edge of the room and it must be empty to be an empty tile 
func is_valid_empty_pos(pos: Vector2) -> bool:
	return pos.x >= 0 && pos.x < room_width && \
	pos.y >= 0 && pos.y < room_height && \
	room[pos] == false

## Creates walls around the edges of a room
func force_walls() -> void:
	if should_be_closed == false:
		return
	
	## Create walls on top and bottom edges
	for x in range(room_width):
		room[Vector2(x, 0)] = true
		room[Vector2(x, room_height - 1)] = true
	
	## Create walls on left and right edges
	for y in range(room_height):
		room[Vector2(0, y)] = true
		room[Vector2(room_width - 1, y)] = true

func apply_to_tilemap() -> void:
	var pos: Vector2 = Vector2(0, 0)
	
	## 
	for x in range(room_width):
		for y in range(room_height):
			pos = Vector2(x, y)
			## Wall tile
			if room[pos] == true:
				tilemaplayer.set_cell(pos, 0, Vector2i(0, randi_range(0, 1)))
			## Empty tile
			else:
				tilemaplayer.set_cell(pos, -1)
