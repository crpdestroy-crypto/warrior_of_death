class_name Hurtbox
extends Area2D

signal got_hit(attack: Dictionary, from: Node)

func _ready() -> void:
	monitoring = false
	monitorable = true

func receive_hit(box: Hitbox, dir: int) -> void:
	var attack: Dictionary = {
		"damage": box.damage,
		"stagger": box.stagger_duration,
		"knockback": box.knockback * Vector2(float(dir), 1.0),
		"element": box.element,
		"swing": box.swing_id,
	}
	got_hit.emit(attack, box.source)
	var owner_node: Node = get_parent()
	if owner_node != null and owner_node.has_method("receive_attack"):
		owner_node.receive_attack(attack, box.source)
