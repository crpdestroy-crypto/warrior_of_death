class_name InventoryMenu
extends CanvasLayer

var _game: Game = null
var _built: bool = false
var _root: Control
var _list: VBoxContainer
var _info: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 21
	visible = false

func open(game: Game) -> void:
	_game = game
	if not _built:
		_build()
		_built = true
	_refresh()
	visible = true
	get_tree().paused = true
	_set_touch(false)

func close() -> void:
	visible = false
	get_tree().paused = false
	_set_touch(true)

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.02, 0.05, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(bg)
	var box := VBoxContainer.new()
	box.anchor_left = 0.1; box.anchor_right = 0.9
	box.anchor_top = 0.08; box.anchor_bottom = 0.95
	_root.add_child(box)
	_info = Label.new()
	box.add_child(_info)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 380)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	var close_b := Button.new()
	close_b.text = "Закрыть"
	close_b.focus_mode = Control.FOCUS_NONE
	close_b.pressed.connect(close)
	box.add_child(close_b)

func _refresh() -> void:
	for c in _list.get_children():
		c.remove_from_parent()
		c.queue_free()
	if _game == null or _game.inventory == null:
		return
	var inv: Inventory = _game.inventory
	_info.text = "Снаряжение: урон +%d  защита +%d" % [inv.total_stat("damage") + inv.total_stat("physical"), inv.total_stat("defense")]
	for i in range(inv.items.size()):
		var item: ItemData = inv.items[i]
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var mark: String = ""
		for slot in Inventory.SLOTS:
			if int(inv.equipped.get(slot, -1)) == i:
				mark = "[E] "
		b.text = "%s%s (%s) %s" % [mark, item.item_name, ItemData.rarity_name(item.rarity), _affix_text(item)]
		b.modulate = ItemData.rarity_color(item.rarity)
		b.pressed.connect(_on_equip.bind(i))
		_list.add_child(b)

func _affix_text(item: ItemData) -> String:
	var parts: PackedStringArray = []
	if item.base_damage > 0:
		parts.append("урн %d" % item.base_damage)
	if item.base_defense > 0:
		parts.append("защ %d" % item.base_defense)
	for a in item.affixes:
		var d: Dictionary = a
		parts.append("%s %+d" % [String(d.get("label", "?")), int(d.get("value", 0))])
	return ", ".join(parts)

func _on_equip(i: int) -> void:
	if _game and _game.inventory.equip(i):
		_refresh()

func _set_touch(v: bool) -> void:
	for n in get_tree().get_nodes_in_group("touch"):
		(n as CanvasItem).visible = v
