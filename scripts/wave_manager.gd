extends Node2D
## 波次管理器 - 支持混合敌人和BOSS

@export var enemy_scene: PackedScene
@export var boss_scene: PackedScene
@export var waves: Array = []
@export var spawn_points: Array = []
@export var auto_start: bool = false
@export var start_delay: float = 3.0

var current_wave: int = 0
var total_waves: int = 0
var wave_active: bool = false
var _wave_cleared: bool = false
var all_cleared: bool = false

var _enemies_spawned: int = 0
var _enemies_alive: int = 0
var _spawn_timer: float = 0.0
var _start_timer: float = 0.0
var _waiting: bool = false
var _boss_spawned: bool = false
var _current_boss: Node2D = null

signal wave_started(wave_num: int, total: int)
signal wave_cleared(wave_num: int)
signal all_waves_cleared()
signal boss_spawned(boss: Node2D)

func _ready() -> void:
	total_waves = waves.size()
	if auto_start:
		start_waves()

func start_waves() -> void:
	current_wave = 0
	total_waves = waves.size()
	all_cleared = false
	_start_next_wave()

func _start_next_wave() -> void:
	if current_wave >= total_waves:
		all_cleared = true
		all_waves_cleared.emit()
		return
	
	current_wave += 1
	wave_active = true
	_wave_cleared = false
	_enemies_spawned = 0
	_enemies_alive = 0
	_spawn_timer = 0.0
	_boss_spawned = false
	_current_boss = null
	wave_started.emit(current_wave, total_waves)

func _process(delta: float) -> void:
	if all_cleared:
		return
	
	if _waiting:
		_start_timer -= delta
		if _start_timer <= 0:
			_waiting = false
			_start_next_wave()
		return
	
	if not wave_active:
		return
	
	var wave_data = waves[current_wave - 1]
	var count: int = wave_data.get("count", 5)
	var interval: float = wave_data.get("interval", 1.0)
	var types: Array = wave_data.get("types", ["normal"])
	var has_boss: bool = wave_data.get("boss", false)
	
	# 生成普通敌人
	if _enemies_spawned < count:
		_spawn_timer += delta
		if _spawn_timer >= interval:
			_spawn_timer = 0.0
			var type: String = types[randi() % types.size()]
			_spawn_enemy(wave_data, type)
			_enemies_spawned += 1
	
	# 普通敌人生成完后生成BOSS
	if has_boss and not _boss_spawned and _enemies_spawned >= count:
		_spawn_boss()
	
	# 检查波次清除（包括BOSS）
	if _enemies_spawned >= count and _enemies_alive <= 0:
		if not has_boss or (_boss_spawned and (_current_boss == null or not is_instance_valid(_current_boss))):
			wave_active = false
			_wave_cleared = true
			wave_cleared.emit(current_wave)
			_waiting = true
			_start_timer = 2.0

func _spawn_enemy(wave_data: Dictionary, enemy_type: String) -> void:
	if not enemy_scene or spawn_points.size() == 0:
		return
	var enemy = enemy_scene.instantiate()
	var spawn_point = spawn_points[randi() % spawn_points.size()]
	enemy.position = spawn_point.position
	enemy.enemy_type = enemy_type
	var hp_mult: float = wave_data.get("hp_mult", 1.0)
	enemy.max_hp = int(enemy.max_hp * hp_mult)
	enemy.died.connect(_on_enemy_died)
	get_parent().add_child(enemy)
	_enemies_alive += 1

func _spawn_boss() -> void:
	if not boss_scene:
		_boss_spawned = true
		return
	_boss_spawned = true
	var boss = boss_scene.instantiate()
	var spawn_point = spawn_points[randi() % spawn_points.size()]
	boss.position = spawn_point.position + Vector2(50, 0)
	boss.boss_died.connect(_on_boss_died)
	get_parent().add_child(boss)
	_current_boss = boss
	_enemies_alive += 1
	boss_spawned.emit(boss)

func _on_enemy_died() -> void:
	_enemies_alive -= 1

func _on_boss_died() -> void:
	_enemies_alive -= 1
	_current_boss = null

func get_progress_text() -> String:
	if all_cleared:
		return "区域已清除!"
	if not wave_active and current_wave == 0:
		return "准备中..."
	var boss_text = ""
	if _current_boss and is_instance_valid(_current_boss):
		boss_text = "  BOSS出现!"
	return "第 %d / %d 波  剩余: %d%s" % [current_wave, total_waves, _enemies_alive, boss_text]
