extends StaticBody2D
class_name Enemy

@export var enemy_type_id: int = 0
var enemy_id: int = 0

## Place this Enemy on the given tile position
func place_enemy(pos: Vector2) -> void:
	position = pos.snapped(Vector2.ONE) * Singleton.TILE_SIZE
