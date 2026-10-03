class_name BaseEnemy
extends CharacterBody2D

enum AI { PATROL, CHASE, WINDUP, ATTACKING, STAGGERED, DEAD }

signal died(enemy: BaseEnemy)

@export var max_hp: float = 40.0
@export var move_speed: float = 55.0
@export var chase_speed: float = 95.0
@export var attack_damage: float = 12.0
@export var attack_range: float = 30.0
@export var sight_range: float = 220.0
@export var windup_time: float = 0.45
@export var attack_time: float = 0.3
@export var touch_damage: float = 6.0
@export var dust_reward: int = 12
@export var drop_luck: float = 0.0

var ai: AI = AI.PATROL
var hp: float
var facing: int = -1
var patrol_dir: int = -1
var _t: float = 0.0
var _touch_cd: float = 0.0
var _player: Node2D = null

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Hitbox
@onready var visual: Node2D = $Visual
@onready var sight: RayCast2D = $Sight
@onready var edge: RayCast2D = $EdgeCheck

func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp
	hitbox.damage = attack_damage
	hitbox.monitoring = false
	if hurtbox:
		hurtbox.got_hit.connect(_on_hurt)

func _physics_process(delta: float) -> void:
	if ai == AI.DEAD:
		return
	_t += delta
	_touch_cd = maxf(_touch_cd - delta, 0.0)
	_player = _find_player()
	match ai:
		AI.PATROL:
			_patrol(delta)
		AI.CHASE:
			_chase(delta)
		AI.WINDUP:
			_apply_gravity(delta)
			move_and_slide()
			if _t >= windup_time:
				_t = 0.0
				ai = AI.ATTACKING
				hitbox.position.x = attack_range * 0.6 * float(facing)
				hitbox.start_swing(self)
		AI.ATTACKING:
			_apply_gravity(delta)
			velocity.x = float(facing) * chase_speed * 0.4
			move_and_slide()
			if _t >= attack_time:
				_t = 0.0
				hitbox.end_swing()
				ai = AI.CHASE if _player else AI.PATROL
		AI.STAGGERED:
			_apply_gravity(delta)
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			move_and_slide()
			if _t >= 1.0:
				_t = 0.0
				ai = AI.CHASE if _player else AI.PATROL

func receive_attack(attack: Dictionary, _from: Node) -> void:
	if ai == AI.DEAD:
		return
	hitbox.end_swing()
	var dmg: float = float(attack.get("damage", 5.0))
	hp = maxf(hp - dmg, 0.0)
	var kb: Vector2 = attack.get("knockback", Vector2(120, -40))
	velocity = kb
	var stagger_need: float = max_hp * 0.35
	if float(attack.get("stagger", 0.0)) > 0.0 or dmg >= stagger_need:
		_t = 0.0
		ai = AI.STAGGERED
	elif hp <= 0.0:
		_die()
	else:
		_t = 0.0
		ai = AI.CHASE
	if hp <= 0.0 and ai != AI.DEAD:
		_die()

func _on_hurt(_attack: Dictionary, _from: Node) -> void:
	pass

func _die() -> void:
	if ai == AI.DEAD:
		return
	ai = AI.DEAD
	hitbox.end_swing()
	died.emit(self)
	var game: Node = get_tree().get_first_node_in_group("game")
	if game != null and game.has_method("on_enemy_killed"):
		game.on_enemy_killed(self)
	queue_free()

func _patrol(delta: float) -> void:
	velocity.x = float(patrol_dir) * move_speed
	facing = patrol_dir
	_apply_gravity(delta)
	move_and_slide()
	if is_on_wall():
		patrol_dir = -patrol_dir
	if edge and edge.is_colliding() == false and is_on_floor():
		patrol_dir = -patrol_dir
	if _can_see_player():
		ai = AI.CHASE

func _chase(delta: float) -> void:
	if _player == null or not _can_see_player():
		ai = AI.PATROL
		return
	var dx: float = _player.global_position.x - global_position.x
	facing = 1 if dx > 0.0 else -1
	if absf(dx) <= attack_range and is_on_floor():
		_t = 0.0
		ai = AI.WINDUP
		velocity.x = 0.0
		return
	velocity.x = float(facing) * chase_speed
	_apply_gravity(delta)
	move_and_slide()
	_try_touch_damage()

func _try_touch_damage() -> void:
	if _touch_cd > 0.0 or _player == null:
		return
	if absf(_player.global_position.x - global_position.x) > 18.0:
		return
	if absf(_player.global_position.y - global_position.y) > 26.0:
		return
	if _player.has_method("take_damage") and not _player.is_invulnerable():
		var parried: bool = _player.has_method("try_consume_parry") and _player.try_consume_parry()
		if parried:
			_t = 0.0
			ai = AI.STAGGERED
		else:
			_player.take_damage(touch_damage, facing)
			_touch_cd = 0.8

func _find_player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D

func _can_see_player() -> bool:
	if _player == null:
		_player = _find_player()
		if _player == null:
			return false
	var to: Vector2 = _player.global_position - global_position
	if to.length() > sight_range:
		return false
	if sight == null:
		return true
	sight.target_position = to_local(_player.global_position + Vector2(0, -12))
	sight.force_raycast_update()
	if sight.is_colliding():
		return sight.get_collider() == _player
	return true

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity", 980.0) * delta

func is_boss() -> bool:
	return get_meta("boss", false) as bool

func respawn() -> void:
	hp = max_hp
	ai = AI.PATROL
	_t = 0.0
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
