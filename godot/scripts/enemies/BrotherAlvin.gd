class_name BrotherAlvin
extends BaseEnemy

@export var boss_id: StringName = &"alvin"
@export var seal_id: String = "alvin"
@export var slam_count: int = 3

var _slam_i: int = 0

func _ready() -> void:
	set_meta("boss", true)
	max_hp = 220.0
	attack_damage = 22.0
	attack_range = 44.0
	sight_range = 400.0
	move_speed = 35.0
	chase_speed = 70.0
	windup_time = 0.6
	super._ready()

func _die() -> void:
	if ai == AI.DEAD:
		return
	super._die()
	var game: Node = get_tree().get_first_node_in_group("game")
	if game != null:
		if game.has_method("mark_boss_dead"):
			game.mark_boss_dead(String(boss_id))
		if game.has_method("add_seal"):
			game.add_seal(seal_id)
		if game.has_method("gain_dust"):
			game.gain_dust(150)
