class_name AltarMenu
extends CanvasLayer

var _game: Game = null
var _built: bool = false
var _root: Control
var _info: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	visible = false

func open(game: Game) -> void:
	_game = game
	if not _built:
		_build()
		_built = true
	_refresh()
	visible = true
	get_tree().paused = true

func close() -> void:
	visible = false
	get_tree().paused = false

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.02, 0.05, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(bg)
	var box := VBoxContainer.new()
	box.anchor_left = 0.15; box.anchor_right = 0.85
	box.anchor_top = 0.12; box.anchor_bottom = 0.9
	_root.add_child(box)
	_info = Label.new()
	box.add_child(_info)
	for stat in Game.STAT_NAMES:
		var b := Button.new()
		b.text = "+ %s" % String(Game.STAT_LABELS.get(stat, stat))
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_on_upgrade.bind(stat))
		box.add_child(b)
	var close_b := Button.new()
	close_b.text = "Встать и идти"
	close_b.focus_mode = Control.FOCUS_NONE
	close_b.pressed.connect(close)
	box.add_child(close_b)

func _on_upgrade(stat: String) -> void:
	if _game:
		_game.upgrade_stat(String(stat))
		_refresh()

func _refresh() -> void:
	if _game == null:
		return
	_info.text = "Пыль: %d (кошель) / %d (банк)\nЖивучесть %d  Сила %d  Выносливость %d\nЦена улучшения: %d" % [
		_game.carried_dust, _game.dust,
		int(_game.stats.get("vigor", 5)), int(_game.stats.get("strength", 5)), int(_game.stats.get("endurance", 5)),
		_game.upgrade_cost(),
	]
