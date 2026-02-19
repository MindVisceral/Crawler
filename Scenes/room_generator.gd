extends Node
class_name RoomGenerator

@export var RoomTileset: TileMapLayer
@export var GameScript: GameManager

#region Exports & variables
## Start/end point are validity-checked on _ready()
@export_group("Room access")
## Position of the start point in the Room in Tile position coordinates
@export var room_start_point: Vector2i = Vector2i.ZERO
## Position of the end point in the Room in Tile position coordinates
@export var room_end_point: Vector2i = Vector2i.ZERO

## Should the start point be placed randomly?
@export var random_start_point: bool = false
## Should the end point be placed randomly?
@export var random_end_point: bool = false
## Should the start and end points be placed randomly?
@export var random_access_points: bool = false

## Amount of empty space around given room's entry and exit points
@export_range(1, 10, 1) var access_size: int = 3;


@export_group("Room seeding")
## Room seed, 0 by default
@export_range(-9999, 9999, 1) var room_seed: int = 0

## Makes the room's seed random each time; without this, the room will remain the same
@export var randomize_seed: bool = false

## Noise height texture used to determin Tile placement in the Room and the kind of Tiles used
@export var noise_height_texture: NoiseTexture2D
## Noise variable (fast noise lite) using noise_height_texture
var noise: Noise


@export_group("Room settings")
## Room width in Tiles
@export_range(5, 256) var room_width: int = 64
## Room height in Tiles
@export_range(5, 256) var room_height: int = 64

## Percent of room filled with walls, 45% is the ideal
@export_range(0, 100, 1) var fill_percent: int = 45

## Amount of smoothing iterations before room is done
@export_range(0, 10, 1) var smoothing_iterations: int = 4

## Maximum amount of attemps to generate a room before algorithm gives up
@export_range(0, 32) var max_generation_attempts: int = 16

## Should a given room have closed edges?
@export var should_be_closed: bool = true


## Keep noise_height_texture's color_ramp in a variable for future reference
@onready var color_ramp: Gradient = noise_height_texture.color_ramp


## Dictionary which maps distinct sprite types (the ints) from the Tileset
## onto floats, which are alpha values from the color_ramp's Colors
## EMPTY BY DEFAULT! It's filled on _ready() with values from the Noise's color_ramp!
var float_to_tile_dict: Dictionary[float, int] = {}

## Stores a given generated room in form of tiles:
## contains a Tile's position and a Tile type (where -1 is an empty Tile)
var room: Dictionary[Vector2i, int] = {}
#endregion


## 
func _ready() -> void:
	## Set noise_height_texture width and height to fit the room's width and height
	noise_height_texture.width = room_width
	noise_height_texture.height = room_height
	
	## Fill the float_to_tile_dict Dictionary with color_ramp's Colors' alpha values;
	## beginning at '-1' (empty Tile),
	## ending at N-2 (where N-2 is the amount of Colors in color_ramp).
	## NOTE: The maths if fine That is technically N-2, but get_point_count() starts from 0
	## instead of -1 like in the comment.
	## The for loop goes through all offsets in color_ramp
	for i: int in range(-1, color_ramp.get_point_count() - 1, 1):
		## Use each offset's value to sample the color_ramp, and store the alpha value of the Color
		## at the offset. Alpha is all we care about here, all of this is just a roundabout way
		## of storing it in a Dictionary.
		var sample_alpha: float = color_ramp.sample(color_ramp.offsets[i+1]).a
		## Record the alpha value and its corresponding Tile kind value to the Dictionary
		float_to_tile_dict[sample_alpha] = i


func begin_generating() -> void:
	## Randomize the seed
	if randomize_seed == true:
		room_seed += randi()
	
	## Get Noise reference and set Noise seed
	noise = noise_height_texture.noise
	noise.seed = room_seed
	
	## Pick the positions of start/end points, if they're set to be random
	decide_access_points()
	## Check if access points' positions are valid and correct them
	correct_access_points()
	## Generate the level
	generate_level(room_start_point, room_end_point)

#region Access point functions
## Depending on the randomization settings, will (or won't) pick random start/end points
func decide_access_points() -> void:
	if random_access_points:
		room_start_point = randomize_access_point(0, room_width, room_height);
		room_end_point = randomize_access_point(0, room_width, room_height);
	else:
		if random_start_point:
			room_start_point = randomize_access_point(0, room_width, room_height);
		if random_end_point:
			room_end_point = randomize_access_point(0, room_width, room_height);

## Randomize access point Vector with variable width/height
func randomize_access_point(min_value: int, max_x_value: int, max_y_value: int) -> Vector2i:
	return Vector2i(randi_range(min_value, max_x_value), randi_range(min_value, max_y_value))

## Checks if chosen access points are valid and corrects them if they're not
func correct_access_points() -> void:
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
func generate_level(start: Vector2i, end: Vector2i) -> void:
	## Attempts at generation
	var attempt: int = 0
	## Given map is valid flag
	var room_is_valid: bool = false
	
	## Generate new Rooms until success or failure
	while !room_is_valid and attempt < max_generation_attempts:
		attempt += 1
		
		## Clear map data for this generation loop
		room.clear()
		
		## New room, 'attempt' is a seed
		init_room(attempt)
		
		## Make space around start and end points to allow for movement
		make_space(room_start_point, access_size)
		make_space(room_end_point, access_size)
		
		## Check if given room can even be traversed from start to end points
		## If it can, room generation has ended successfully
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
	## Position of a given Tile
	var pos: Vector2i
	## Noise value at given Tile position
	var noise_value: float
	
	## Filling the Room with Walls
	for x in range(room_width):
		for y in range(room_height):
			## Keep track of this Tile's position
			pos = Vector2i(x, y)
			## Get Noise value at this x:y position
			noise_value = noise.get_noise_2d(x, y)
			
			## Remap noise_value to be a number in 0--1 instead of -1--1 by default.
			## This will ensure the value fits onto the color_ramp
			noise_value = remap(noise_value, -1, 1, 0, 1)
			## Now get the alpha value of the Color sampled from color_ramp.
			## This is used to get the Tile type from the float_to_tile_dict Dictionary.
			## This doesn't make any sense intuitively
			var sampled_color_value: float = color_ramp.sample(noise_value).a
			
			## Assign the type of Tile to these coordinates, depending on the value
			## sampled from the Dictionary of Tiles
			room[pos] = float_to_tile_dict[sampled_color_value]

## Returns o the amount of wall tiles around a tile at given position
func get_surrounding_wall_count(pos: Vector2i) -> int:
	var wall_count: int = 0
	## Check position; made a variable as to not create a new one every loop
	var check_pos: Vector2i = Vector2i(0, 0)
	
	## Keep in mind: range stops *before* '2', so we get a 3x3 grid
	for x in range(-1, 2):
		for y in range(-1, 2):
			check_pos = Vector2i(pos.x + x, pos.y + y)
			if check_pos != pos:
				if room.get(check_pos, true):
					wall_count += 1
	
	return wall_count



## Make some empty space around given position
func make_space(center: Vector2i, radius: int) -> void:
	## Position; made a variable as to not create a new one every loop
	var pos: Vector2i = Vector2i(0, 0)
	
	## Check for (radius) tiles around the given position
	for x in range(-radius, radius+1):
		for y in range(-radius, radius+1):
			pos = Vector2i(center.x + x, center.y + y)
			## If given surrounding tile is outside of the room's boundaries, it will be ignored
			if pos.x >= 0 && pos.x < room_width && \
			pos.y >= 0 && pos.y < room_height:
				## Otherwise, that tile is made empty
				if Vector2i(x, y).length() <= radius:
					room[pos] = -1

## Check if there is a valid path between entry and exit points
## with A* algorithm
func check_path_exists() -> bool:
	var astar = AStar2D.new()
	## Position; made a variable as to not create a new one every loop
	var pos: Vector2i = Vector2i(0, 0)
	
	## Empty tiles are added to A*, wall tiles are ignored
	for x in range(room_width):
		for y in range(room_height):
			pos = Vector2i(x, y)
			## Given tile is empty, add it to A*'s list
			if room[pos] == -1:
				var point_id: int = get_point_id(pos)
				astar.add_point(point_id, pos)
	
	## Tiles that are neighbours will be connected
	for x in range(room_width):
		for y in range(room_height):
			pos = Vector2i(x, y)
			## Only check for neighbours if a given tile is empty
			if room[pos] == -1:
				## Get given tile's ID
				var point_id: int = get_point_id(pos)
				
				## Check all orthogontal neighbours and connect this tile to each if it's valid
				for neighbour in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var next_pos: Vector2i = pos + neighbour
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
func get_point_id(pos: Vector2i) -> int:
	return int(pos.x + pos.y * room_width)

## A given tile can't be at the edge of the room and it must be empty to be an empty tile 
func is_valid_empty_pos(pos: Vector2i) -> bool:
	return pos.x >= 0 && pos.x < room_width && \
	pos.y >= 0 && pos.y < room_height && \
	room[pos] == -1

## Creates walls around the edges of a room
func force_walls() -> void:
	if should_be_closed == false:
		return
	
	## Create walls on top and bottom edges
	for x in range(room_width):
		room[Vector2i(x, 0)] = true
		room[Vector2i(x, room_height - 1)] = true
	
	## Create walls on left and right edges
	for y in range(room_height):
		room[Vector2i(0, y)] = true
		room[Vector2i(room_width - 1, y)] = true
#endregion

#region Apply generated room to tileset
func apply_to_tileset() -> void:
	var pos: Vector2i = Vector2i(0, 0)
	
	## Applying tileset tiles to each generated position
	for x in range(room_width):
		for y in range(room_height):
			pos = Vector2i(x, y)
			## Wall tile
			## HERE: Should be reworked to work on undefined amount of different Tiles,
			## as many as the float_to_tile_dict Dictionary allows
			if room[pos] != -1:
				## Determine specific Tile kind based on room[pos] value
				if room[pos] == 0:
					## Random stone tile on x0-5,y5
					RoomTileset.set_cell(pos, 0, Vector2i(randi_range(0, 5), 5))
				elif room[pos] == 1:
					## Random brick stone tile on x0-3,y3
					RoomTileset.set_cell(pos, 0, Vector2i(randi_range(0, 3), 3))
				elif room[pos] == 2:
					## Random dark stone tile on x0-5,y0
					RoomTileset.set_cell(pos, 0, Vector2i(randi_range(0, 5), 0))
			## Empty tile
			else:
				RoomTileset.set_cell(pos, 0, Vector2i(0, 25))  ## A dark tile on index x0,y25
	
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
	## Most important bit of information, terrain we just generated.
	## Does not keep track of Tile kinds, just if the Tile is filled or not.
	new_room_data.room_terrain = translate_room_terrain_to_bool(room)
	
	## Pass the information, the next step may begin
	GameScript.retrieve_room_data(new_room_data)

## Takes given room Dictionary and changes Tile info from int to bool,
## where it's true if Tile is filled (!= -1) and false if empty (== -1)
func translate_room_terrain_to_bool(room_dict: Dictionary[Vector2i, int]) \
									-> Dictionary[Vector2i, bool]:
	var translated_room: Dictionary[Vector2i, bool]
	for info: Vector2i in room_dict:
		if (room_dict[info] == -1):
			translated_room[info] = false
		else:
			translated_room[info] = true
	
	return translated_room
