class_name Altar
extends Area2D

signal rested(altar: Altar)

@export var altar_id: StringName = &"crypt_01"
@export var title: String = "Алтарь Тлеющей Искры"

var _used_label: bool = false

func _ready() -> void:
	add_to_group("altars")
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(48, 40)
	shape.position = Vector2(0, -16)
	shape.shape = rect
	add_child(shape)
	var spr := Sprite2D.new()
	spr.texture = load("res://assets/sprites/altar.png")
	spr.position = Vector2(-24, -40)
	add_child(spr)
	body_entered.connect(_on_body)

func _on_body(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	var game: Node = get_tree().get_first_node_in_group("game")
	if game != null and game.has_method("rest_at"):
		game.rest_at(self)
	rested.emit(self)
