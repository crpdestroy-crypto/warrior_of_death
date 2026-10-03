class_name HuskVisual
extends Node2D

var enemy: BaseEnemy
var spr: AnimatedSprite2D

func _ready() -> void:
	enemy = get_parent() as BaseEnemy
	spr = AnimatedSprite2D.new()
	add_child(spr)
	spr.frames = SpriteSheet.make(
		{
			"idle": SpriteSheet.slice("res://assets/sprites/husk_idle.png", 4, 32, 32),
			"walk": SpriteSheet.slice("res://assets/sprites/husk_walk.png", 4, 32, 32),
			"attack": SpriteSheet.slice("res://assets/sprites/husk_attack.png", 3, 32, 32),
		},
		{"idle": 5.0, "walk": 8.0, "attack": 10.0},
		{"idle": true, "walk": true, "attack": false}
	)
	spr.play("idle")

func _process(_delta: float) -> void:
	if enemy == null or spr == null:
		return
	spr.scale.x = float(enemy.facing)
	var want: String = "idle"
	match enemy.ai:
		BaseEnemy.AI.PATROL:
			want = "walk"
		BaseEnemy.AI.CHASE:
			want = "walk"
		BaseEnemy.AI.WINDUP, BaseEnemy.AI.ATTACKING:
			want = "attack"
		BaseEnemy.AI.STAGGERED:
			want = "idle"
	if spr.animation != want:
		spr.play(want)
	spr.modulate = Color(1, 0.45, 0.45) if enemy.ai == BaseEnemy.AI.STAGGERED else Color.WHITE
