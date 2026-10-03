class_name AlvinVisual
extends Node2D

var enemy: BaseEnemy
var spr: AnimatedSprite2D

func _ready() -> void:
	enemy = get_parent() as BaseEnemy
	spr = AnimatedSprite2D.new()
	add_child(spr)
	spr.frames = SpriteSheet.make(
		{
			"idle": SpriteSheet.slice("res://assets/sprites/alvin_idle.png", 2, 64, 64),
			"attack": SpriteSheet.slice("res://assets/sprites/alvin_attack.png", 3, 64, 64),
		},
		{"idle": 4.0, "attack": 8.0},
		{"idle": true, "attack": false}
	)
	spr.play("idle")

func _process(_delta: float) -> void:
	if enemy == null or spr == null:
		return
	spr.scale.x = float(enemy.facing)
	var want: String = "attack" if enemy.ai in [BaseEnemy.AI.WINDUP, BaseEnemy.AI.ATTACKING] else "idle"
	if spr.animation != want:
		spr.play(want)
