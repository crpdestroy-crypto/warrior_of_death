class_name LootGenerator
extends RefCounted

var rng := RandomNumberGenerator.new()

func _init(seed_value: int = 0) -> void:
	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value

func roll_rarity(luck: float = 0.0) -> int:
	var roll: float = rng.randf() * 100.0 - luck
	if roll < 2.0:
		return ItemData.Rarity.RELIC
	if roll < 8.0:
		return ItemData.Rarity.CURSED
	if roll < 30.0:
		return ItemData.Rarity.RARE
	return ItemData.Rarity.COMMON

func make_drop(item_type: int, level: int, luck: float = 0.0) -> ItemData:
	var rarity: int = roll_rarity(luck)
	var item := ItemData.new()
	item.item_type = item_type
	item.rarity = rarity
	item.id = StringName("loot_%d_%d" % [Time.get_ticks_msec(), rng.randi()])
	match item_type:
		ItemData.ItemType.WEAPON:
			item.item_name = "%s %s" % [ItemData.NAMES_WEAPON[rng.randi() % ItemData.NAMES_WEAPON.size()], ItemData.ORIGINS[rng.randi() % ItemData.ORIGINS.size()]]
			item.base_damage = 6 + level * 2 + _bonus_for(rarity, level)
		ItemData.ItemType.ARMOR:
			item.item_name = "%s %s" % [ItemData.NAMES_ARMOR[rng.randi() % ItemData.NAMES_ARMOR.size()], ItemData.ORIGINS[rng.randi() % ItemData.ORIGINS.size()]]
			item.base_defense = 2 + level + _bonus_for(rarity, level) / 2
		_:
			item.item_name = "%s %s" % [ItemData.NAMES_RING[rng.randi() % ItemData.NAMES_RING.size()], ItemData.ORIGINS[rng.randi() % ItemData.ORIGINS.size()]]
	var count: int = affix_count(rarity)
	for i in range(count):
		item.affixes.append(roll_affix(level, rarity))
	if rarity == ItemData.Rarity.CURSED:
		item.affixes.append(roll_curse())
	if rarity == ItemData.Rarity.RELIC:
		item.affixes.append({"stat": "ember", "value": 5 + level, "label": "искра Горна"})
	return item

static func affix_count(rarity: int) -> int:
	match rarity:
		ItemData.Rarity.COMMON:
			return 0
		ItemData.Rarity.RARE:
			return 2
		ItemData.Rarity.CURSED:
			return 2
		ItemData.Rarity.RELIC:
			return 3
	return 0

func roll_affix(level: int, _rarity: int) -> Dictionary:
	var pool: Dictionary = ItemData.AFFIX_POOL[rng.randi() % ItemData.AFFIX_POOL.size()]
	var value: int = rng.randi_range(int(pool["min"]), int(pool["max"])) + level / 2
	return {"stat": String(pool["stat"]), "value": value, "label": String(pool["label"])}

func roll_curse() -> Dictionary:
	var pool: Dictionary = ItemData.CURSE_POOL[rng.randi() % ItemData.CURSE_POOL.size()]
	return {"stat": String(pool["stat"]), "value": rng.randi_range(int(pool["min"]), int(pool["max"])), "label": String(pool["label"]), "curse": true}

func _bonus_for(rarity: int, level: int) -> int:
	match rarity:
		ItemData.Rarity.RARE:
			return 2 + level / 2
		ItemData.Rarity.CURSED:
			return 4 + level
		ItemData.Rarity.RELIC:
			return 6 + level * 2
	return 0
