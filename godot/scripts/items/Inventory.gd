class_name Inventory
extends Node

signal changed

const SLOTS: Array = ["weapon", "armor", "ring"]
var items: Array = []
var equipped: Dictionary = {"weapon": -1, "armor": -1, "ring": -1}

func add(item: ItemData) -> void:
	items.append(item)
	changed.emit()

func equip(index: int) -> bool:
	if index < 0 or index >= items.size():
		return false
	var item: ItemData = items[index]
	var slot: String = slot_for(item.item_type)
	equipped[slot] = index
	changed.emit()
	return true

static func slot_for(item_type: int) -> String:
	match item_type:
		ItemData.ItemType.WEAPON:
			return "weapon"
		ItemData.ItemType.ARMOR:
			return "armor"
	return "ring"

func equipped_item(slot: String) -> ItemData:
	var index: int = int(equipped.get(slot, -1))
	if index >= 0 and index < items.size():
		return items[index]
	return null

func total_stat(stat: String) -> int:
	var total: int = 0
	for slot in SLOTS:
		var item: ItemData = equipped_item(slot)
		if item == null:
			continue
		if stat == "damage":
			total += item.base_damage
		elif stat == "defense":
			total += item.base_defense
		for affix in item.affixes:
			var d: Dictionary = affix
			if String(d.get("stat", "")) == stat:
				total += int(d.get("value", 0))
	return total

func to_json() -> Dictionary:
	var out: Array = []
	for item in items:
		var it: ItemData = item
		out.append({
			"name": it.item_name, "type": it.item_type, "rarity": it.rarity,
			"dmg": it.base_damage, "def": it.base_defense, "affixes": it.affixes,
		})
	return {"items": out, "equipped": equipped.duplicate()}

func from_json(data: Dictionary) -> void:
	items.clear()
	for raw in data.get("items", []):
		var d: Dictionary = raw
		var it := ItemData.new()
		it.item_name = String(d.get("name", "Клинок"))
		it.item_type = int(d.get("type", 0))
		it.rarity = int(d.get("rarity", 0))
		it.base_damage = int(d.get("dmg", 0))
		it.base_defense = int(d.get("def", 0))
		it.affixes = d.get("affixes", [])
		items.append(it)
	var eq: Dictionary = data.get("equipped", {})
	for slot in SLOTS:
		equipped[slot] = int(eq.get(slot, -1))
	changed.emit()
