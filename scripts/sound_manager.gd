extends Node
## 全局音效管理器 - 自动加载单例

var _players: Dictionary = {}
var _sfx: Dictionary = {}
var _bgm_player: AudioStreamPlayer
var _current_bgm: String = ""

func _ready() -> void:
	_preload_sfx("shoot", "res://assets/audio/shoot.wav")
	_preload_sfx("hit", "res://assets/audio/hit.wav")
	_preload_sfx("enemy_die", "res://assets/audio/enemy_die.wav")
	_preload_sfx("bgm", "res://assets/audio/bgm.wav")
	
	for i in 8:
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players[i] = p
	
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "Master"
	_bgm_player.volume_db = -18
	add_child(_bgm_player)

func _preload_sfx(name: String, path: String) -> void:
	if ResourceLoader.exists(path):
		_sfx[name] = load(path)

func play_sfx(name: String, volume: float = -10.0) -> void:
	if not _sfx.has(name):
		return
	for i in _players:
		var p: AudioStreamPlayer = _players[i]
		if not p.playing:
			p.stream = _sfx[name]
			p.volume_db = volume
			p.play()
			return
	var p: AudioStreamPlayer = _players[0]
	p.stream = _sfx[name]
	p.volume_db = volume
	p.play()

func play_bgm(name: String = "bgm") -> void:
	if _current_bgm == name and _bgm_player.playing:
		return
	if not _sfx.has(name):
		return
	_current_bgm = name
	var stream = _sfx[name]
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = stream.get_data().size()
	_bgm_player.stream = stream
	_bgm_player.play()

func stop_bgm() -> void:
	_bgm_player.stop()
	_current_bgm = ""

func set_bgm_volume(db: float) -> void:
	_bgm_player.volume_db = db
