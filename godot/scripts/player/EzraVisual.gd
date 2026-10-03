class_name EzraVisual
extends Node2D
## Подключает сгенерированные спрайты Эзры к PlayerController.
## Анимации: Idle/Run/Roll/Attack. Спрайты лежат в assets/sprites/ (CC0).

@export var controller_path: NodePath
var _ctl: PlayerController
var _spr: AnimatedSprite2D

func _ready() -> void:
	_ctl = get_node_or_null(controller_path) as PlayerController
	if _ctl == null:
		_ctl = get_parent() as PlayerController
	_spr = AnimatedSprite2D.new()
	add_child(_spr)
	_spr.frames = _build_frames()
	_spr.play("idle")
	if _ctl:
		_ctl.state_changed.connect(_on_state)

func _process(_d: float) -> void:
	if _ctl == null or _spr == null:
		return
	if _spr.scale.x != float(_ctl.facing):
		_spr.scale.x = float(_ctl.facing)

func _on_state(st: PlayerController.State) -> void:
	match st:
		PlayerController.State.IDLE:
			_spr.play("idle")
		PlayerController.State.RUN:
			_spr.play("run")
		PlayerController.State.JUMP, PlayerController.State.FALL:
			_spr.play("run")
		PlayerController.State.ROLL:
			_spr.play("roll")
		PlayerController.State.ATTACK:
			_spr.play("attack")
		PlayerController.State.PARRY:
			_spr.play("idle")
		PlayerController.State.HURT:
			_spr.play("idle")
			_spr.modulate = Color(1, 0.4, 0.4)
			await get_tree().create_timer(0.25).timeout
			_spr.modulate = Color.WHITE
		PlayerController.State.DEAD:
			_spr.play("idle")
			_spr.modulate = Color(0.4, 0.4, 0.45)

func _sheet(path: String, n: int, w: int, h: int) -> Array[Texture2D]:
	var tex: Texture2D = load(path)
	var out: Array[Texture2D] = []
	for i in n:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * w, 0, w, h)
		out.append(at)
	return out

func _build_frames() -> SpriteFrames:
	var f := SpriteFrames.new()
	f.add_animation("idle"); f.set_animation_speed("idle", 6); f.set_animation_loop("idle", true)
	for t in _sheet("res://assets/sprites/ezra_idle.png", 4, 48, 48):
		f.add_frame("idle", t)
	f.add_animation("run"); f.set_animation_speed("run", 10); f.set_animation_loop("run", true)
	for t in _sheet("res://assets/sprites/ezra_run.png", 4, 48, 48):
		f.add_frame("run", t)
	f.add_animation("roll"); f.set_animation_speed("roll", 12); f.set_animation_loop("roll", false)
	for t in _sheet("res://assets/sprites/ezra_roll.png", 4, 48, 48):
		f.add_frame("roll", t)
	f.add_animation("attack"); f.set_animation_speed("attack", 12); f.set_animation_loop("attack", false)
	for t in _sheet("res://assets/sprites/ezra_attack.png", 3, 64, 48):
		f.add_frame("attack", t)
	return f
