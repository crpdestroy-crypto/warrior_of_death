class_name ItemData
extends Resource

enum ItemType { WEAPON, ARMOR, RING }
enum Rarity { COMMON, RARE, CURSED, RELIC }

@export var id: StringName = &""
@export var item_name: String = ""
@export var item_type: int = ItemType.WEAPON
@export var rarity: int = Rarity.COMMON
@export var base_damage: int = 0
@export var base_defense: int = 0
@export var affixes: Array = []
@export var flavor: String = ""

const NAMES_WEAPON: Array = ["Клинок", "Секира", "Копье", "Молот", "Кинжал"]
const NAMES_ARMOR: Array = ["Панцирь", "Мантия", "Шлем", "Поножи", "Наплеч"]
const NAMES_RING: Array = ["Кольцо", "Печать", "Амулет", "Осколок"]
const ORIGINS: Array = ["Забвения", "Пепла", "Горна", "Тишины", "Свечи"]

const AFFIX_POOL: Array = [
	{"stat": "physical", "min": 2, "max": 6, "label": "урон"},
	{"stat": "fire_damage", "min": 3, "max": 9, "label": "огонь"},
	{"stat": "stamina_regen", "min": 3, "max": 8, "label": "восст. стамины"},
	{"stat": "max_hp", "min": 8, "max": 20, "label": "здоровье"},
	{"stat": "crit_chance", "min": 3, "max": 7, "label": "крит%"},
]
const CURSE_POOL: Array = [
	{"stat": "max_stamina", "min": -15, "max": -8, "label": "проклятие стамины"},
	{"stat": "move_slow", "min": 5, "max": 10, "label": "тяжесть"},
]

static func rarity_name(r: int) -> String:
	match r:
		Rarity.COMMON:
			return "Common"
		Rarity.RARE:
			return "Rare"
		Rarity.CURSED:
			return "Cursed"
		Rarity.RELIC:
			return "Relic"
	return "Common"

static func rarity_color(r: int) -> Color:
	match r:
		Rarity.COMMON:
			return Color(0.74, 0.74, 0.74)
		Rarity.RARE:
			return Color(0.35, 0.62, 1.0)
		Rarity.CURSED:
			return Color(1.0, 0.3, 0.3)
		Rarity.RELIC:
			return Color(1.0, 0.84, 0.31)
	return Color.WHITE
