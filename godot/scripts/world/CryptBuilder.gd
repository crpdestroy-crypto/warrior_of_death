class_name CryptBuilder
extends Node2D

const TS: int = 16
const FLOOR_Y: int = 8
const X0: int = 0
const X1: int = 79

var _map: TileMap

func _ready() -> void:
	_build_tiles()
	_build_bodies()

func _sy(row: int) -> float:
	return float(row * TS)

func _build_tiles() -> void:
	var map := TileMap.new()
	map.name = "Ground"
	var atlas := TileSetAtlasSource.new()
	atlas.texture = load("res://assets/tiles/crypt_tileset.png")
	atlas.texture_region_size = Vector2i(TS, TS)
	for i in range(8):
		atlas.create_tile(Vector2i(i, 0))
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TS, TS)
	ts.add_source(atlas)
	map.tile_set = ts
	add_child(map)
	_map = map
	for x in range(X0, X1 + 1):
		_pit_gap(x)
	for x in range(X0, X1 + 1):
		if _in_pit(x):
			continue
		_map.set_cell(0, Vector2i(x, FLOOR_Y), 0, Vector2i(0, 0))
	for x in [12, 66]:
		_map.set_cell(0, Vector2i(x, FLOOR_Y - 1), 0, Vector2i(6, 0))
	for y in range(-2, FLOOR_Y):
		_map.set_cell(0, Vector2i(X0, y), 0, Vector2i(2, 0))
		_map.set_cell(0, Vector2i(X1, y), 0, Vector2i(2, 0))
	for x in range(8, 17):
		_map.set_cell(0, Vector2i(x, 2), 0, Vector2i(0, 0))
	for x in range(24, 37):
		_map.set_cell(0, Vector2i(x, 0), 0, Vector2i(0, 0))
	for x in range(46, 53):
		_map.set_cell(0, Vector2i(x, 3), 0, Vector2i(0, 0))
	for x in range(62, 75):
		_map.set_cell(0, Vector2i(x, 1), 0, Vector2i(0, 0))
	move_child(_map, 1)

func _pit_gap(_x: int) -> void:
	pass

func _in_pit(x: int) -> bool:
	return (x >= 30 and x <= 33) or (x >= 55 and x <= 58)

func _solid(x0: int, x1: int, row: int) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(float((x1 - x0 + 1) * TS), float(TS))
	shape.shape = rect
	shape.position = Vector2(float((x0 + x1 + 1) * TS) / 2.0, float(row * TS) + TS / 2.0)
	body.add_child(shape)
	add_child(body)

func _build_bodies() -> void:
	_run(0, 29, FLOOR_Y); _run(34, 54, FLOOR_Y); _run(59, 79, FLOOR_Y)
	_run(8, 16, 2); _run(24, 36, 0); _run(46, 52, 3); _run(62, 74, 1)
	_wall(X0); _wall(X1)

func _run(x0: int, x1: int, row: int) -> void:
	_solid(x0, x1, row)

func _wall(x: int) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(float(TS), float((FLOOR_Y + 2) * TS))
	shape.shape = rect
	shape.position = Vector2(float(x * TS) + TS / 2.0, float((FLOOR_Y - 2) * TS))
	body.add_child(shape)
	add_child(body)
