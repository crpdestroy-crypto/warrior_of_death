class_name Hitbox
extends Area2D

@export var damage: float = 10.0
@export var stagger_duration: float = 0.0
@export var knockback: Vector2 = Vector2(140.0, -50.0)
@export var element: StringName = &"physical"

var source: Node = null
var swing_id: int = 0
var _hit: Dictionary = {}

func _ready() -> void:
	monitoring = false
	monitorable = false
	area_entered.connect(_on_area_entered)

func start_swing(from: Node) -> void:
	source = from
	swing_id += 1
	_hit.clear()
	set_deferred("monitoring", true)

func end_swing() -> void:
	set_deferred("monitoring", false)

func _on_area_entered(area: Area2D) -> void:
	if not monitoring:
		return
	if not (area is Hurtbox):
		return
	var key: int = area.get_instance_id()
	if _hit.has(key):
		return
	_hit[key] = true
	var dir: int = 1
	if source != null and source.get("facing") != null:
		dir = int(source.get("facing"))
	area.receive_hit(self, dir)
