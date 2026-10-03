class_name Hud
extends CanvasLayer
## HP/стамина поверх игры. Подписывается на сигналы игрока из группы "player".

@onready var hp_bar: ProgressBar = $Root/HpBar
@onready var st_bar: ProgressBar = $Root/StBar

func _ready() -> void:
	layer = 5
	var p: PlayerController = get_tree().get_first_node_in_group("player") as PlayerController
	if p == null:
		await get_tree().process_frame
		p = get_tree().get_first_node_in_group("player") as PlayerController
	if p == null:
		return
	p.health_changed.connect(_on_hp)
	p.stamina_changed.connect(_on_st)
	_on_hp(p.hp, p.max_hp)
	_on_st(p.stamina, p.max_stamina)

func _on_hp(hp: float, max_hp: float) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = hp

func _on_st(v: float, max_v: float) -> void:
	st_bar.max_value = max_v
	st_bar.value = v
