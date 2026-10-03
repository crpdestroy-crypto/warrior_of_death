class_name Bloodstain
extends Area2D

var dust: int = 0

func setup(amount: int) -> void:
	dust = amount

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 14.0
	shape.shape = circle
	add_child(shape)
	var spr := Sprite2D.new()
	spr.texture = load("res://assets/sprites/bloodstain.png")
	spr.position = Vector2(-16, -6)
	add_child(spr)
	body_entered.connect(_on_body)

func _on_body(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	var game: Node = get_tree().get_first_node_in_group("game")
	if game != null and game.has_method("collect_stain"):
		game.collect_stain(self)
