class_name AudioBus
extends Node
## Центральный звук: эмбиент склепа + SFX боя/лута/алтаря. Всё CC0, синтез внутри проекта.

var _players: Dictionary = {}
var _ambient: AudioStreamPlayer

func _ready() -> void:
	add_to_group("audio")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ambient = AudioStreamPlayer.new()
	_ambient.name = "Ambient"
	_ambient.stream = load("res://assets/audio/ambient_crypt.wav")
	_ambient.volume_db = -10.0
	add_child(_ambient)
	_ambient.play()
	for name in ["swing", "hit", "parry", "roll", "jump", "pickup", "altar", "death"]:
		var p := AudioStreamPlayer.new()
		p.name = "Sfx_" + name
		p.stream = load("res://assets/audio/%s.wav" % name)
		p.volume_db = -4.0
		add_child(p)
		_players[name] = p

func play(name: String) -> void:
	var p: AudioStreamPlayer = _players.get(name)
	if p:
		p.play()
