extends Node2D
class_name Tile

## Available tile types
enum TileType {
	SEA,
	LAND
}

@export_group("Tile ssettings")
## Type of this given tile
@export var tile_type: TileType

## Black if SEA, regular sprite if LAND
func _ready() -> void:
	if tile_type == TileType.SEA:
		%Sprite2D.modulate += Color.BLACK

func change_tile_size(tile_size: int = 32) -> void:
	var sprite_size: Vector2 = %Sprite2D.texture.get_size()
	%Sprite2D.scale = Vector2(tile_size / sprite_size.x, tile_size / sprite_size.y)
