class_name Game
extends Node

signal dust_changed(value: int)
signal level_changed(level: int)
signal message(text: String)

const STAT_NAMES: Array = ["vigor", "strength", "endurance"]
const STAT_LABELS: Dictionary = {"vigor": "Живучесть", "strength": "Сила", "endurance": "Выносливость"}

var dust: int = 0
var carried_dust: int = 0
var level: int = 1
var stats: Dictionary = {"vigor": 5, "strength": 5, "endurance": 5}
var seals: Array = []
var bosses_dead: Array = []
var doors_open: Array = []
var spawn_altar: String = "crypt_01"

var inventory: Inventory
var loot_gen := LootGenerator.new()
var player: PlayerController = null
var _stain: Bloodstain = null
var _save_path: String = "user://savegame.json"

func _ready() -> void:
	add_to_group("game")
	inventory = Inventory.new()
	inventory.name = "Inventory"
	add_child(inventory)
	load_game()
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player") as PlayerController
	if player != null:
		_apply_stats_to_player()
		player.died.connect(_on_player_died)
		var foes: Array = get_tree().get_nodes_in_group("enemies")
		for e in foes:
			if e is BaseEnemy:
				(e as BaseEnemy).died.connect(_on_enemy_died)

func player_bonus_damage() -> float:
	var bonus: float = float(stats.get("strength", 5)) * 1.5
	bonus += float(inventory.total_stat("damage"))
	bonus += float(inventory.total_stat("physical"))
	bonus += float(inventory.total_stat("fire_damage")) * 0.7
	return bonus

func player_max_hp() -> float:
	return 80.0 + float(stats.get("vigor", 5)) * 6.0 + float(inventory.total_stat("max_hp"))

func gain_dust(amount: int) -> void:
	carried_dust += amount
	dust_changed.emit(carried_dust)

func _on_enemy_died(enemy: BaseEnemy) -> void:
	gain_dust(enemy.dust_reward)
	message.emit("Пыль Солнца +%d" % enemy.dust_reward)
	_maybe_drop_loot(enemy)

func _maybe_drop_loot(enemy: BaseEnemy) -> void:
	var chance: float = 0.3 + enemy.drop_luck
	if randf() > chance:
		return
	var roll: int = randi() % 10
	var kind: int = ItemData.ItemType.WEAPON if roll < 5 else (ItemData.ItemType.ARMOR if roll < 8 else ItemData.ItemType.RING)
	var item: ItemData = loot_gen.make_drop(kind, level, enemy.drop_luck * 10.0)
	spawn_drop(item, enemy.global_position)

func spawn_drop(item: ItemData, at: Vector2) -> void:
	var drop := LootDrop.new()
	drop.setup(item)
	drop.picked.connect(_on_loot_picked)
	var parent: Node = get_tree().current_scene
	parent.add_child(drop)
	drop.global_position = at + Vector2(0, -20)
	message.emit("Добыча: %s" % item.item_name)

func _on_loot_picked(item: ItemData) -> void:
	inventory.add(item)
	message.emit("Подобрано: %s (%s)" % [item.item_name, ItemData.rarity_name(item.rarity)])

func _on_player_died() -> void:
	drop_stain()
	message.emit("Эзра пал. Пыль осталась на месте смерти.")

func drop_stain() -> void:
	_clear_stain()
	if carried_dust <= 0 or player == null:
		return
	_stain = Bloodstain.new()
	_stain.setup(carried_dust)
	carried_dust = 0
	dust_changed.emit(carried_dust)
	var parent: Node = get_tree().current_scene
	parent.add_child(_stain)
	_stain.global_position = player.global_position

func collect_stain(stain: Bloodstain) -> void:
	if stain != _stain:
		stain.queue_free()
		return
	gain_dust(stain.dust)
	message.emit("Возвращено пыли: %d" % stain.dust)
	_stain = null
	stain.queue_free()

func _clear_stain() -> void:
	if is_instance_valid(_stain):
		_stain.queue_free()
	_stain = null

func rest_at(altar: Altar) -> void:
	spawn_altar = String(altar.altar_id)
	if player != null:
		player.hp = player_max_hp()
		player.stamina = player.max_stamina
		player.health_changed.emit(player.hp, player_max_hp())
	dust += carried_dust
	carried_dust = 0
	dust_changed.emit(carried_dust)
	save_game()
	var foes: Array = get_tree().get_nodes_in_group("enemies")
	for e in foes:
		if e is BaseEnemy and not (e as BaseEnemy).is_boss():
			(e as BaseEnemy).respawn()
	message.emit("%s. Пыль сохранена: %d" % [altar.title, dust])

func upgrade_stat(stat: String) -> bool:
	if not STAT_NAMES.has(stat):
		return false
	var cost: int = upgrade_cost()
	if dust < cost:
		message.emit("Нужно пыли: %d" % cost)
		return false
	dust -= cost
	stats[stat] = int(stats.get(stat, 5)) + 1
	_apply_stats_to_player()
	save_game()
	message.emit("%s повышено до %d" % [String(STAT_LABELS.get(stat, stat)), int(stats[stat])])
	return true

func upgrade_cost() -> int:
	var total: int = 0
	for s in STAT_NAMES:
		total += int(stats.get(s, 5))
	return 20 + total * 8

func on_enemy_killed(enemy: BaseEnemy) -> void:
	_on_enemy_died(enemy)

func add_seal(seal_id: String) -> void:
	if not seals.has(seal_id):
		seals.append(seal_id)
		message.emit("Печать Хранителя: %s (%d/4)" % [seal_id, seals.size()])
		save_game()

func mark_boss_dead(boss_id: String) -> void:
	if not bosses_dead.has(boss_id):
		bosses_dead.append(boss_id)
		save_game()

func is_boss_dead(boss_id: String) -> bool:
	return bosses_dead.has(boss_id)

func save_game() -> void:
	var data: Dictionary = {
		"dust": dust, "level": level, "stats": stats, "seals": seals,
		"bosses": bosses_dead, "doors": doors_open, "altar": spawn_altar,
		"inventory": inventory.to_json() if inventory else {},
	}
	var file := FileAccess.open(_save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_game() -> void:
	if not FileAccess.file_exists(_save_path):
		return
	var file := FileAccess.open(_save_path, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary):
		return
	var data: Dictionary = parsed
	dust = int(data.get("dust", 0))
	level = int(data.get("level", 1))
	var st: Dictionary = data.get("stats", {})
	for s in STAT_NAMES:
		stats[s] = int(st.get(s, 5))
	seals = data.get("seals", [])
	bosses_dead = data.get("bosses", [])
	doors_open = data.get("doors", [])
	spawn_altar = String(data.get("altar", "crypt_01"))
	if inventory and data.has("inventory"):
		inventory.from_json(data["inventory"])

func _apply_stats_to_player() -> void:
	if player == null:
		return
	player.max_hp = player_max_hp()
	player.hp = minf(player.hp if player.hp > 0.0 else player.max_hp(), player.max_hp())
	player.max_stamina = 80.0 + float(stats.get("endurance", 5)) * 4.0
	player.stamina = minf(player.stamina, player.max_stamina)
