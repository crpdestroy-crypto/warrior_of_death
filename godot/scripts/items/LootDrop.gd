class_name LootDrop
extends Area2D

signal picked(item: ItemData)

var item: ItemData
var bob_t: float = 0.0
var _taken: bool = false
var _spr: Sprite2D

func setup(data: ItemData) -> void:
	item = data

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, 16)
	shape.shape = rect
	add_child(shape)
	_spr = Sprite2D.new()
	_spr.texture = load("res://assets/sprites/dust.png")
	_spr.modulate = ItemData.rarity_color(item.rarity) if item != null else Color.WHITE
	add_child(_spr)
	body_entered.connect(_on_body)

func _process(delta: float) -> void:
	bob_t += delta
	if _spr:
		_spr.position.y = -8.0 + sin(bob_t * 3.0) * 2.0

func _on_body(body: Node2D) -> void:
	if _taken or item == null:
		return
	if not body.is_in_group("player"):
		return
	_taken = true
	picked.emit(item)
	queue_free()
