extends Node
class_name RoomGenerator

@export var RoomTileset: TileMapLayer
@export var GameScript: GameManager

#region Exports
@export_group("Room access")
## 
## Maximum is the same as room_width/height, but that must be checked on _ready()
@export var room_start_point: Vector2 = Vector2.ZERO
@export var room_end_point: Vector2 = Vector2.ZERO
## Points can be placed randomly on the map
@export var random_start_point: bool = false
@export var random_end_point: bool = false
@export var random_access_points: bool = false


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
## Not used???
@export_range(5, 100, 1) var min_room_size: int = 50
## Amount of empty space around given room's entry and exit points
@export_range(1, 10, 1) var access_size: int = 3;

@export_group("Room settings")
## Room size
@export_range(5, 256) var room_width: int = 64
@export_range(5, 256) var room_height: int = 64
## Maximum amount of attemps to generate a room before algorithm gives up
@export_range(0, 32) var max_generation_attempts: int = 16

@export_group("Miscellaneous")
## Should a given room have closed edges?
@export var should_be_closed: bool = true
#endregion

## Stores a given generated room in form of tiles:
## contains a tile's position and whether it's empty or filled
var room: Dictionary[Vector2, bool] = {}

func begin_generating() -> void:
		## Randomize the seed
	if randomize_seed == true:
		room_seed += randi()
	
	attempt_random_access()
	check_room_access_points()
	generate_level(room_start_point, room_end_point)

#region Access point functions
## Depending on the randomization settings, will (or won't) pick random start/end points
func attempt_random_access() -> void:
	if random_access_points:
		room_start_point = randomize_access_point(0, room_width, room_height);
		room_end_point = randomize_access_point(0, room_width, room_height);
	else:
		if random_start_point:
			room_start_point = randomize_access_point(0, room_width, room_height);
		if random_end_point:
			room_end_point = randomize_access_point(0, room_width, room_height);

## Randomize access point Vector with variable width/height
func randomize_access_point(min_value: int, max_x_value: int, max_y_value: int) -> Vector2:
	return Vector2(randi_range(min_value, max_x_value), randi_range(min_value, max_y_value))

## Checks if chosen access points are valid and corrects them if they're not
func check_room_access_points() -> void:
	## Function will stop and fail after n attempts at randomization
	var attempts: int = 0
	
	## Start point check
	## X axis outside range; set to 1
	if room_start_point.x <= 0 || room_start_point.x >= room_width:
		room_start_point.x = 1
	## Y axis outside range; set to 1
	if room_start_point.y <= 0 || room_start_point.y >= room_height:
		room_start_point.y = 1
	
	## End point check
	## X axis outside range; set to maximum
	if room_end_point.x <= 0 || room_end_point.x >= room_width:
		room_end_point.x = room_width-1
	## Y axis outside range; set to maximum
	if room_end_point.y <= 0 || room_end_point.y >= room_height:
		room_end_point.y = room_height-1
	
	## Start and end point can't occupy the same position.
	## (Though this allows them to be right next to each other)
	## End point will be moved to a random valid point until it works
	while room_start_point == room_end_point && attempts < 16:
		room_end_point.x = randi_range(1, room_width-1)
		room_end_point.y = randi_range(1, room_height-1)
		attempts += 1;
	
	## Error message in case of failure
	if attempts >= 16:
		push_error("Failed to randomize valid access points after %d attempts" % attempts)
#endregion

#region BASE Room generation (includes: start, end, walls)
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
		make_space(room_start_point, access_size)
		make_space(room_end_point, access_size)
		
		## Check if given room can even be traversed
		room_is_valid = check_path_exists()
	
	
	## Generating completed. If no room was created, give up.
	if room_is_valid == false:
		push_error("Failed to generate a valid map after %d attempts" % max_generation_attempts)
	
	## Create walls at room edges if that option is checked
	if should_be_closed == true:
		force_walls()
	
	## Get the generated room and apply it to a TileSet
	apply_to_tileset()


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
	var new_room: Dictionary[Vector2, bool] = {}
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
	## Check is invalid even if there's a diagonal connection. We want *rooms* without those.
	var start_id = get_point_id(room_start_point)
	var end_id = get_point_id(room_end_point)
	
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
#endregion

#region Apply generated room to tileset
func apply_to_tileset() -> void:
	var pos: Vector2 = Vector2(0, 0)
	
	## Applying tileset tiles to each generated position
	for x in range(room_width):
		for y in range(room_height):
			pos = Vector2(x, y)
			## Wall tile
			if room[pos] == true:
				RoomTileset.set_cell(pos, 0, Vector2i(randi_range(0, 8), randi_range(1, 3)))  ## Random stone tile on x0-11,y1-3
			## Empty tile
			else:
				RoomTileset.set_cell(pos, 0, Vector2i(0, 25))  ## Black tile on index x0,y26
	
	## Start and End points get special Tiles assigned to them.
	RoomTileset.set_cell(room_start_point, 0, Vector2i(3, 8))
	RoomTileset.set_cell(room_end_point, 0, Vector2i(4, 8))
	
	completed_generation()
#endregion

## Pass on important level information to the Game script so the next step may begin
func completed_generation() -> void:
	## Record room data and send it over
	var new_room_data: RoomData = RoomData.new()
	new_room_data.room_seed = room_seed
	new_room_data.fill_percent = fill_percent
	new_room_data.room_start_point = room_start_point
	new_room_data.room_end_point = room_end_point
	new_room_data.access_size = access_size
	new_room_data.room_width = room_width
	new_room_data.room_height = room_height
	## Most important bit of information, terrain we just generated
	new_room_data.room_terrain = room
	
	## Pass the information, the next step may begin
	GameScript.retrieve_room_data(new_room_data)
