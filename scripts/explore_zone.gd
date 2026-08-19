extends Node2D
## 探索区域 - 废墟城市关卡，含波次系统和建造点

@export var enemy_scene: PackedScene
@export var player_scene: PackedScene
@export var tower_scene: PackedScene
@export var upgrade_panel_scene: PackedScene
@export var build_spot_scene: PackedScene
@export var facility_scene: PackedScene
@export var game_over_panel_scene: PackedScene
@export var tower_upgrade_panel_scene: PackedScene
@export var boss_scene: PackedScene
@export var pause_menu_scene: PackedScene
@export var victory_panel_scene: PackedScene

var _player: Node2D = null
var _build_mode: bool = false
var _selected_tower_type: String = "machine_gun"
var _tower_order: Array = ["machine_gun", "cannon", "laser", "mortar"]
var _upgrade_panel: Control = null
var _game_over_panel: Control = null
var _tower_upgrade_panel: Control = null
var _pause_menu: Control = null
var _victory_panel: Control = null
var _zone_cleared: bool = false
var _initial_money: int = 0
var _current_boss: Node2D = null
var _victory_shown: bool = false
var _shake_intensity: float = 0.0
var _shake_duration: float = 0.0

@onready var camera: Camera2D = $Camera2D
@onready var money_label: Label = $UI/MoneyLabel
@onready var build_hint: Label = $UI/BuildHint
@onready var weapon_hint: Label = $UI/WeaponHint
@onready var wave_label: Label = $UI/WaveLabel
@onready var tower_bar: VBoxContainer = $UI/TowerBar
@onready var wave_manager: Node2D = $WaveManager
@onready var build_spots: Node2D = $BuildSpots
@onready var facilities: Node2D = $Facilities
@onready var boss_hp_bar: ProgressBar = $UI/BossHPBar
@onready var boss_hp_label: Label = $UI/BossHPBar/BossLabel

var _tower_buttons: Array = []

func _ready() -> void:
	Engine.time_scale = 1.0
	_initial_money = GameState.money
	SoundManager.play_bgm()
	_player = player_scene.instantiate()
	_player.position = Vector2(150, 0)
	_player.add_to_group("player")
	_player.died.connect(_on_player_died)
	add_child(_player)
	
	camera.make_current()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	
	if upgrade_panel_scene:
		_upgrade_panel = upgrade_panel_scene.instantiate()
		add_child(_upgrade_panel)
	
	if game_over_panel_scene:
		_game_over_panel = game_over_panel_scene.instantiate()
		_game_over_panel.restart_requested.connect(_on_restart)
		_game_over_panel.return_base_requested.connect(_on_return_base)
		add_child(_game_over_panel)
	
	if tower_upgrade_panel_scene:
		_tower_upgrade_panel = tower_upgrade_panel_scene.instantiate()
		_tower_upgrade_panel.tower_sold.connect(_on_tower_sold)
		add_child(_tower_upgrade_panel)
	
	if pause_menu_scene:
		_pause_menu = pause_menu_scene.instantiate()
		add_child(_pause_menu)
	
	if victory_panel_scene:
		_victory_panel = victory_panel_scene.instantiate()
		_victory_panel.continue_requested.connect(_on_victory_continue)
		add_child(_victory_panel)
	
	GameState.facility_activated.connect(_on_facility_activated)
	GameState.camera_shake.connect(_on_camera_shake)
	
	# 连接建造点信号
	for spot in build_spots.get_children():
		if spot.has_signal("tower_built"):
			spot.tower_built.connect(_on_tower_built)
	
	GameState.money_changed.connect(_on_money_changed)
	GameState.weapon_changed.connect(_on_weapon_changed)
	_on_money_changed(GameState.money)
	_on_weapon_changed(GameState.current_weapon)
	
	_build_tower_bar()
	_setup_wave_manager()
	_setup_navigation()
	
	build_hint.visible = false
	tower_bar.visible = false

func _setup_navigation() -> void:
	# 创建导航区域
	var nav_region = NavigationRegion2D.new()
	nav_region.name = "NavigationRegion"
	add_child(nav_region)
	
	var nav_poly = NavigationPolygon.new()
	# 外轮廓 - 整个可走区域
	var outline = PackedVector2Array([
		Vector2(-390, -240),
		Vector2(390, -240),
		Vector2(390, 240),
		Vector2(-390, 240),
	])
	nav_poly.add_outline(outline)
	# 孔洞 - 废墟障碍物
	var hole1 = PackedVector2Array([
		Vector2(-140, -110), Vector2(-60, -110),
		Vector2(-60, -90), Vector2(-140, -90),
	])
	var hole2 = PackedVector2Array([
		Vector2(-140, 90), Vector2(-60, 90),
		Vector2(-60, 110), Vector2(-140, 110),
	])
	var hole3 = PackedVector2Array([
		Vector2(90, -75), Vector2(110, -75),
		Vector2(110, 75), Vector2(90, 75),
	])
	nav_poly.add_outline(hole1)
	nav_poly.add_outline(hole2)
	nav_poly.add_outline(hole3)
	nav_poly.make_polygons_from_outlines()
	nav_region.navigation_polygon = nav_poly

func _setup_wave_manager() -> void:
	# 配置波次
	wave_manager.enemy_scene = enemy_scene
	wave_manager.spawn_points = $SpawnPoints.get_children()
	wave_manager.waves = [
		{"count": 5, "interval": 1.2, "hp_mult": 1.0, "types": ["normal"]},
		{"count": 8, "interval": 1.0, "hp_mult": 1.2, "types": ["normal", "fast"]},
		{"count": 12, "interval": 0.8, "hp_mult": 1.5, "types": ["normal", "fast", "ranged"]},
		{"count": 10, "interval": 0.7, "hp_mult": 1.8, "types": ["fast", "ranged", "normal"], "boss": true},
	]
	wave_manager.boss_scene = boss_scene
	wave_manager.boss_spawned.connect(_on_boss_spawned)
	wave_manager.wave_started.connect(_on_wave_started)
	wave_manager.wave_cleared.connect(_on_wave_cleared)
	wave_manager.all_waves_cleared.connect(_on_all_cleared)
	wave_manager.start_waves()

func _process(delta: float) -> void:
	if _player and is_instance_valid(_player):
		camera.global_position = _player.global_position
	# 屏幕震动
	if _shake_duration > 0:
		_shake_duration -= delta
		camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake_intensity
	else:
		camera.offset = Vector2.ZERO
	
	if Input.is_action_just_pressed("build_mode"):
		_build_mode = not _build_mode
		GameState.build_mode = _build_mode
		GameState.build_mode_changed.emit(_build_mode)
		build_hint.visible = _build_mode
		tower_bar.visible = _build_mode
		_update_build_hint()
		_update_tower_bar()
	
	if _build_mode:
		if Input.is_action_just_pressed("weapon_1"):
			_select_tower(0)
		elif Input.is_action_just_pressed("weapon_2"):
			_select_tower(1)
		elif Input.is_action_just_pressed("weapon_3"):
			_select_tower(2)
		elif Input.is_action_just_pressed("weapon_4"):
			_select_tower(3)
	
	if Input.is_action_just_pressed("return_base"):
		GameState.build_mode = false
		get_tree().change_scene_to_file("res://scenes/base.tscn")
	
	# 更新波次UI
	if wave_manager:
		wave_label.text = wave_manager.get_progress_text()

func _build_tower_bar() -> void:
	for i in _tower_order.size():
		var tower_id: String = _tower_order[i]
		var tower_data = GameState.tower_types[tower_id]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(160, 36)
		btn.text = "[%d] %s (%d$)" % [i + 1, tower_data["name"], tower_data["cost"]]
		btn.pressed.connect(_select_tower.bind(i))
		tower_bar.add_child(btn)
		_tower_buttons.append(btn)

func _select_tower(index: int) -> void:
	if index < 0 or index >= _tower_order.size():
		return
	_selected_tower_type = _tower_order[index]
	_update_build_hint()
	_update_tower_bar()

func get_selected_tower() -> String:
	return _selected_tower_type

func _update_build_hint() -> void:
	var tower_data = GameState.tower_types[_selected_tower_type]
	build_hint.text = "建造模式: %s (%d$) - 点击绿色建造点, 1-4切换, B退出" % [tower_data["name"], tower_data["cost"]]

func _update_tower_bar() -> void:
	for i in _tower_buttons.size():
		var btn: Button = _tower_buttons[i]
		var tower_id: String = _tower_order[i]
		var tower_data = GameState.tower_types[tower_id]
		var can_afford: bool = GameState.money >= tower_data["cost"]
		var selected: bool = tower_id == _selected_tower_type
		btn.text = "[%d] %s (%d$)%s" % [i + 1, tower_data["name"], tower_data["cost"], " ←" if selected else ""]
		btn.disabled = not can_afford
		btn.modulate = Color(1, 1, 0.6) if selected else Color.WHITE

func _on_money_changed(new_amount: int) -> void:
	money_label.text = "金钱: %d" % new_amount
	if _build_mode:
		_update_tower_bar()

func _on_weapon_changed(weapon_id: String) -> void:
	var weapon = GameState.weapons[weapon_id]
	weapon_hint.text = "武器: %s | R回大本营 | B建造" % weapon["name"]

func _on_wave_started(wave_num: int, total: int) -> void:
	pass

func _on_wave_cleared(wave_num: int) -> void:
	pass

func _on_all_cleared() -> void:
	_zone_cleared = true
	wave_label.text = "区域已清除! 恢复设施后按R返回"
	_spawn_facilities()

func _spawn_facilities() -> void:
	if not facility_scene:
		return
	var facility_data = [
		{"type": "medical", "cost": 50, "pos": Vector2(-150, -80)},
		{"type": "workshop", "cost": 100, "pos": Vector2(0, -80)},
		{"type": "power", "cost": 80, "pos": Vector2(150, -80)},
	]
	for data in facility_data:
		var facility = facility_scene.instantiate()
		facility.facility_type = data["type"]
		facility.cost = data["cost"]
		facility.position = data["pos"]
		facilities.add_child(facility)

func _on_player_died() -> void:
	if _game_over_panel:
		var wave_reached: int = wave_manager.current_wave if wave_manager else 0
		var money_earned: int = GameState.money - _initial_money
		_game_over_panel.show_game_over(wave_reached, money_earned)

func _on_restart() -> void:
	get_tree().reload_current_scene()

func _on_return_base() -> void:
	GameState.build_mode = false
	get_tree().change_scene_to_file("res://scenes/base.tscn")

func _on_tower_built(spot: Node) -> void:
	# 找到刚建的塔并连接点击信号
	for child in spot.get_children():
		if child.is_in_group("tower"):
			child.tower_clicked.connect(_on_tower_clicked)

func _on_tower_clicked(tower: Node2D) -> void:
	if _tower_upgrade_panel:
		_tower_upgrade_panel.show_for_tower(tower)

func _on_tower_sold(_tower: Node2D) -> void:
	pass

func _on_boss_spawned(boss: Node2D) -> void:
	_current_boss = boss
	boss.hp_changed.connect(_on_boss_hp_changed)
	boss.boss_died.connect(_on_boss_died)
	boss_hp_bar.visible = true
	boss_hp_bar.max_value = boss.max_hp
	boss_hp_bar.value = boss.hp
	boss_hp_label.text = "BOSS"

func _on_boss_hp_changed(current: int, maximum: int) -> void:
	boss_hp_bar.max_value = maximum
	boss_hp_bar.value = current

func _on_boss_died() -> void:
	boss_hp_bar.visible = false
	_current_boss = null

func _on_facility_activated(_type: String) -> void:
	if not _victory_shown and GameState.all_facilities_activated():
		_victory_shown = true
		if _victory_panel:
			_victory_panel.show_victory(wave_manager.current_wave, GameState.money)

func _on_victory_continue() -> void:
	pass

func _on_camera_shake(intensity: float, duration: float) -> void:
	_shake_intensity = max(_shake_intensity, intensity)
	_shake_duration = max(_shake_duration, duration)
