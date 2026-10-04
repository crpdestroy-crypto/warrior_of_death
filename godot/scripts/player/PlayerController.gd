class_name PlayerController
extends CharacterBody2D
## Эзра, Безымянный Пилигрим. Этап 1: физика + FSM + стамина + i-frames + мобильный ввод.

enum State { IDLE, RUN, JUMP, FALL, ROLL, ATTACK, PARRY, HURT, DEAD }

signal state_changed(new_state: State)
signal health_changed(hp: float, max_hp: float)
signal stamina_changed(value: float, max_value: float)
signal died

@export_group("Movement")
@export var move_speed: float = 140.0
@export var acceleration: float = 1200.0
@export var air_acceleration: float = 800.0
@export var friction: float = 1400.0
@export var jump_velocity: float = -330.0
@export var jump_cut_multiplier: float = 0.45
@export var coyote_time: float = 0.15
@export var jump_buffer: float = 0.1
@export var gravity_scale: float = 1.0

@export_group("Stamina")
@export var max_stamina: float = 100.0
@export var roll_cost: float = 20.0
@export var attack_cost: float = 12.0
@export var stamina_regen: float = 25.0
@export var stamina_regen_delay: float = 1.2

@export_group("Roll")
@export var roll_speed: float = 260.0
@export var roll_duration: float = 0.38

@export_group("Combat")
@export var max_hp: float = 100.0
@export var combo_chain: Array = [0.32, 0.32, 0.42]
@export var combo_window: float = 0.45
@export var combo_damage: Array = [12.0, 14.0, 20.0]
@export var parry_duration: float = 0.35
@export var parry_window: float = 0.2
@export var hurt_duration: float = 0.3
@export var stagger_duration: float = 2.0

signal parried(enemy: Node)
signal combo_step(index: int)

var attack_duration: float = 0.32
var combo_index: int = 0
var combo_queued: bool = false
var state: State = State.IDLE:
	set(v):
		if state == v:
			return
		state = v
		state_changed.emit(state)
var hp: float
var stamina: float
var facing: int = 1
var touch_move: Vector2 = Vector2.ZERO
var _coyote: float = 0.0
var _buffer: float = 0.0
var _regen_timer: float = 0.0
var _state_time: float = 0.0
var _jump_cut_done: bool = false
var _hitbox_off_at: float = 0.0

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Hitbox
@onready var visual: Node2D = $Visual

func _ready() -> void:
	add_to_group("player")
	hp = max_hp
	stamina = max_stamina
	hitbox.monitoring = false
	health_changed.emit(hp, max_hp)
	stamina_changed.emit(stamina, max_stamina)

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	_state_time += delta
	_update_timers(delta)
	_regen_stamina(delta)
	match state:
		State.IDLE, State.RUN:
			_ground_move(delta)
			if not is_on_floor():
				_change_state(State.FALL)
			elif _consume_buffer():
				_do_jump()
			elif Input.is_action_just_pressed("roll"):
				try_roll()
			elif Input.is_action_just_pressed("attack"):
				try_attack()
			elif Input.is_action_just_pressed("parry"):
				try_parry()
		State.JUMP:
			_air_move(delta)
			_apply_gravity(delta)
			_check_jump_cut()
			move_and_slide()
			if velocity.y >= 0.0:
				_change_state(State.FALL)
		State.FALL:
			_air_move(delta)
			_apply_gravity(delta)
			move_and_slide()
			if is_on_floor():
				_change_state(State.IDLE)
			elif _consume_buffer():
				_do_jump()
			elif Input.is_action_just_pressed("attack"):
				try_attack()
		State.ROLL:
			velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity", 980.0) * gravity_scale * delta
			move_and_slide()
			if _state_time >= roll_duration:
				_change_state(State.IDLE if is_on_floor() else State.FALL)
		State.ATTACK, State.PARRY, State.HURT:
			_apply_gravity(delta)
			_apply_friction(delta)
			move_and_slide()
			if state == State.ATTACK:
				if Input.is_action_just_pressed("attack") and _state_time >= attack_duration * 0.5:
					combo_queued = true
				if hitbox.monitoring and _state_time >= _hitbox_off_at:
					hitbox.monitoring = false
				if combo_queued and _state_time >= attack_duration:
					_advance_combo()
				elif _state_time >= attack_duration + combo_window:
					combo_queued = false
					_change_state(State.IDLE if is_on_floor() else State.FALL)
			elif _state_time >= _current_lock_duration():
				_change_state(State.IDLE if is_on_floor() else State.FALL)
	if visual:
		visual.scale.x = float(facing)

func get_input_vector() -> Vector2:
	var x: float = Input.get_axis("move_left", "move_right") + touch_move.x
	return Vector2(clampf(x, -1.0, 1.0), 0.0)


func _sfx(name: String) -> void:
	var bus: Node = get_tree().get_first_node_in_group("audio")
	if bus != null and bus.has_method("play"):
		bus.play(name)

func try_jump() -> bool:
	if state in [State.DEAD, State.ROLL]:
		return false
	if is_on_floor() or _coyote > 0.0:
		_do_jump()
		_sfx("jump")
		return true
	_buffer = jump_buffer
	return false

func try_roll() -> bool:
	if state in [State.ROLL, State.ATTACK, State.HURT, State.DEAD]:
		return false
	if stamina < roll_cost:
		return false
	_consume_stamina(roll_cost)
	var dir: float = get_input_vector().x
	if dir == 0.0:
		dir = float(facing)
	facing = 1 if dir > 0.0 else -1
	velocity = Vector2(float(facing) * roll_speed, velocity.y * 0.2)
	_set_iframes(true)
	_sfx("roll")
	_change_state(State.ROLL)
	return true

func current_attack_damage() -> float:
	var i: int = clampi(combo_index, 0, combo_damage.size() - 1)
	var bonus: float = 0.0
	var game: Node = get_tree().get_first_node_in_group("game")
	if game != null and game.has_method("player_bonus_damage"):
		bonus = float(game.player_bonus_damage())
	return float(combo_damage[i]) + bonus

func try_attack() -> bool:
	if state == State.ATTACK:
		if _state_time >= attack_duration * 0.5:
			combo_queued = true
		return false
	if state in [State.ROLL, State.HURT, State.DEAD]:
		return false
	if stamina < attack_cost:
		return false
	_consume_stamina(attack_cost)
	combo_index = 0
	combo_queued = false
	_start_swing()
	_sfx("swing")
	return true

func _advance_combo() -> void:
	combo_index = mini(combo_index + 1, combo_chain.size() - 1)
	combo_queued = false
	_consume_stamina(attack_cost * 0.5)
	_start_swing()
	_sfx("swing")

func _start_swing() -> void:
	var i: int = clampi(combo_index, 0, combo_chain.size() - 1)
	attack_duration = float(combo_chain[i])
	var dir: float = get_input_vector().x
	if dir != 0.0:
		facing = 1 if dir > 0.0 else -1
	velocity.x = 0.0
	hitbox.position.x = 18.0 * float(facing)
	hitbox.damage = current_attack_damage()
	hitbox.stagger_duration = stagger_duration if combo_index == combo_chain.size() - 1 else 0.0
	hitbox.start_swing(self)
	_hitbox_off_at = attack_duration * 0.6
	_change_state(State.ATTACK)
	combo_step.emit(combo_index)

func try_parry() -> bool:
	if state in [State.ROLL, State.ATTACK, State.PARRY, State.HURT, State.DEAD]:
		return false
	velocity.x = 0.0
	_change_state(State.PARRY)
	return true

func receive_attack(attack: Dictionary, from: Node) -> void:
	if state == State.DEAD or state == State.ROLL:
		return
	if is_parry_window_open():
		_change_state(State.IDLE if is_on_floor() else State.FALL)
		_sfx("parry")
		parried.emit(from)
		var foe: Node = from
		if foe != null and foe.has_method("receive_attack"):
			foe.receive_attack({"damage": 0.0, "stagger": stagger_duration, "knockback": Vector2.ZERO, "element": &"parry"}, self)
		return
	take_damage(float(attack.get("damage", 5.0)), 0)

func try_consume_parry() -> bool:
	if not is_parry_window_open():
		return false
	var foe: Node = null
	var foes: Array = get_tree().get_nodes_in_group("enemies")
	var best: float = 64.0
	for e in foes:
		var n := e as Node2D
		if n == null:
			continue
		var d: float = (n.global_position - global_position).length()
		if d < best:
			best = d
			foe = e
	_change_state(State.IDLE if is_on_floor() else State.FALL)
	_sfx("parry")
	parried.emit(foe)
	return true

func take_damage(amount: float, _from_dir: int = 0) -> void:
	if state == State.DEAD or state == State.ROLL:
		return
	hp = maxf(hp - amount, 0.0)
	health_changed.emit(hp, max_hp)
	_sfx("hit")
	if hp <= 0.0:
		_change_state(State.DEAD)
		_set_iframes(true)
		_sfx("death")
		died.emit()
	else:
		_change_state(State.HURT)

func is_parry_window_open() -> bool:
	return state == State.PARRY and _state_time <= parry_window

func is_invulnerable() -> bool:
	return state == State.ROLL or state == State.DEAD

func on_jump_released() -> void:
	if state == State.JUMP and not _jump_cut_done and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier
		_jump_cut_done = true

func _ground_move(delta: float) -> void:
	var dir: float = get_input_vector().x
	if dir != 0.0:
		facing = 1 if dir > 0.0 else -1
		velocity.x = move_toward(velocity.x, dir * move_speed, acceleration * delta)
		_change_state(State.RUN)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		_change_state(State.IDLE)
	_apply_gravity(delta)
	move_and_slide()

func _air_move(delta: float) -> void:
	var dir: float = get_input_vector().x
	if dir != 0.0:
		facing = 1 if dir > 0.0 else -1
		velocity.x = move_toward(velocity.x, dir * move_speed, air_acceleration * delta)

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity", 980.0) * gravity_scale * delta

func _apply_friction(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, friction * delta)

func _do_jump() -> void:
	_buffer = 0.0
	_coyote = 0.0
	_jump_cut_done = false
	velocity.y = jump_velocity
	_change_state(State.JUMP)

func _check_jump_cut() -> void:
	if _jump_cut_done:
		return
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier
		_jump_cut_done = true

func _update_timers(delta: float) -> void:
	if is_on_floor():
		_coyote = coyote_time
	else:
		_coyote = maxf(_coyote - delta, 0.0)
	if Input.is_action_just_pressed("jump"):
		_buffer = jump_buffer
	else:
		_buffer = maxf(_buffer - delta, 0.0)

func _consume_buffer() -> bool:
	if _buffer > 0.0 and (is_on_floor() or _coyote > 0.0):
		_buffer = 0.0
		return true
	return false

func _consume_stamina(amount: float) -> void:
	stamina = maxf(stamina - amount, 0.0)
	_regen_timer = stamina_regen_delay
	stamina_changed.emit(stamina, max_stamina)

func _regen_stamina(delta: float) -> void:
	if _regen_timer > 0.0:
		_regen_timer -= delta
		return
	if stamina < max_stamina:
		stamina = minf(stamina + stamina_regen * delta, max_stamina)
		stamina_changed.emit(stamina, max_stamina)

func _set_iframes(enabled: bool) -> void:
	hurtbox.set_deferred("monitorable", not enabled)

func _change_state(next: State) -> void:
	if state == State.ROLL and next != State.ROLL:
		_set_iframes(false)
	if state == State.ATTACK and next != State.ATTACK:
		hitbox.end_swing()
		combo_queued = false
	state = next
	_state_time = 0.0
	state_changed.emit(state)

func _current_lock_duration() -> float:
	match state:
		State.ATTACK:
			return attack_duration
		State.PARRY:
			return parry_duration
		State.HURT:
			return hurt_duration
	return 0.1
