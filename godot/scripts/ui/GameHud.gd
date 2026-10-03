class_name GameHud
extends CanvasLayer

var _dust_label: Label
var _msg_label: Label
var _msg_t: float = 0.0
var _menu: AltarMenu
var _inv: InventoryMenu

func _ready() -> void:
	layer = 15
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_TOP_WIDE)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_dust_label = Label.new()
	_dust_label.anchor_left = 0.45; _dust_label.anchor_right = 0.98
	_dust_label.anchor_top = 0.01; _dust_label.anchor_bottom = 0.08
	root.add_child(_dust_label)
	_msg_label = Label.new()
	_msg_label.anchor_left = 0.1; _msg_label.anchor_right = 0.9
	_msg_label.anchor_top = 0.1; _msg_label.anchor_bottom = 0.2
	_msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_msg_label)
	_menu = AltarMenu.new()
	add_child(_menu)
	_inv = InventoryMenu.new()
	add_child(_inv)
	add_to_group("game_hud")
	await get_tree().process_frame
	var game: Game = get_tree().get_first_node_in_group("game") as Game
	if game != null:
		game.dust_changed.connect(_on_dust)
		game.message.connect(show_message)
		_on_dust(game.carried_dust)

func _process(delta: float) -> void:
	if _msg_t > 0.0:
		_msg_t -= delta
		if _msg_t <= 0.0 and _msg_label:
			_msg_label.text = ""

func _on_dust(_v: int) -> void:
	var game: Game = get_tree().get_first_node_in_group("game") as Game
	if game and _dust_label:
		_dust_label.text = "Пыль %d | Банк %d | Печати %d/4" % [game.carried_dust, game.dust, game.seals.size()]

func show_message(text: String) -> void:
	if _msg_label:
		_msg_label.text = text
		_msg_t = 3.0
	_on_dust(0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _menu:
		if _menu.visible:
			_menu.close()

func open_altar(game: Game) -> void:
	if _menu:
		if _menu.visible:
			_menu.close()
		else:
			if _inv:
				_inv.close()
			_menu.open(game)

func open_inventory(game: Game) -> void:
	if _inv:
		if _inv.visible:
			_inv.close()
		else:
			if _menu:
				_menu.close()
			_inv.open(game)
