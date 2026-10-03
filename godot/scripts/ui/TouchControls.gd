class_name TouchControls
extends CanvasLayer

@export var player_path: NodePath

var _player: PlayerController
var _left_held: bool = false
var _right_held: bool = false

func _ready() -> void:
	layer = 10
	_player = get_node_or_null(player_path) as PlayerController
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as PlayerController

func _process(_delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as PlayerController
		if _player == null:
			return
	var x: float = 0.0
	if _left_held:
		x -= 1.0
	if _right_held:
		x += 1.0
	_player.touch_move = Vector2(x, 0.0)

func on_left_down() -> void:
	_left_held = true

func on_left_up() -> void:
	_left_held = false

func on_right_down() -> void:
	_right_held = true

func on_right_up() -> void:
	_right_held = false

func on_jump_down() -> void:
	Input.action_press("jump")
	if _player:
		_player.try_jump()

func on_jump_up() -> void:
	Input.action_release("jump")
	if _player:
		_player.on_jump_released()

func on_roll_down() -> void:
	Input.action_press("roll")
	if _player:
		_player.try_roll()

func on_roll_up() -> void:
	Input.action_release("roll")

func on_attack_down() -> void:
	Input.action_press("attack")
	if _player:
		_player.try_attack()

func on_attack_up() -> void:
	Input.action_release("attack")

func on_parry_down() -> void:
	Input.action_press("parry")
	if _player:
		_player.try_parry()

func on_parry_up() -> void:
	Input.action_release("parry")

func on_menu_down() -> void:
	var game: Game = get_tree().get_first_node_in_group("game") as Game
	var hud: GameHud = get_tree().get_first_node_in_group("game_hud") as GameHud
	if game != null and hud != null:
		hud.open_altar(game)

func on_bag_down() -> void:
	var game: Game = get_tree().get_first_node_in_group("game") as Game
	var hud: GameHud = get_tree().get_first_node_in_group("game_hud") as GameHud
	if game != null and hud != null:
		hud.open_inventory(game)
