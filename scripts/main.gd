extends Node2D
## 主场景 - 探索地图

@export var enemy_scene: PackedScene
@export var player_scene: PackedScene
@export var tower_scene: PackedScene
@export var upgrade_panel_scene: PackedScene
@export var spawn_interval: float = 3.0
@export var max_enemies: int = 15

var _player: Node2D = null
var _spawn_timer: float = 0.0
var _enemy_count: int = 0
var _build_mode: bool = false
var _selected_tower_type: String = "machine_gun"
var _tower_order: Array = ["machine_gun", "cannon", "laser", "mortar"]
var _upgrade_panel: Control = null

@onready var camera: Camera2D = $Camera2D
@onready var money_label: Label = $UI/MoneyLabel
@onready var build_hint: Label = $UI/BuildHint
@onready var weapon_hint: Label = $UI/WeaponHint
@onready var tower_bar: VBoxContainer = $UI/TowerBar
@onready var spawn_points: Node2D = $SpawnPoints

var _tower_buttons: Array = []

func _ready() -> void:
	_player = player_scene.instantiate()
	_player.position = Vector2(0, 0)
	_player.add_to_group("player")
	add_child(_player)
	
	camera.make_current()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	
	if upgrade_panel_scene:
		_upgrade_panel = upgrade_panel_scene.instantiate()
		add_child(_upgrade_panel)
	
	GameState.money_changed.connect(_on_money_changed)
	GameState.weapon_changed.connect(_on_weapon_changed)
	_on_money_changed(GameState.money)
	_on_weapon_changed(GameState.current_weapon)
	
	_build_tower_bar()
	
	for i in 3:
		_spawn_enemy()
	
	build_hint.visible = false
	tower_bar.visible = false

func _process(delta: float) -> void:
	if _player and is_instance_valid(_player):
		camera.global_position = _player.global_position
	
	_spawn_timer += delta
	if _spawn_timer >= spawn_interval and _enemy_count < max_enemies:
		_spawn_timer = 0.0
		_spawn_enemy()
	
	if Input.is_action_just_pressed("build_mode"):
		_build_mode = not _build_mode
		GameState.build_mode = _build_mode
		GameState.build_mode_changed.emit(_build_mode)
		build_hint.visible = _build_mode
		tower_bar.visible = _build_mode
		_update_build_hint()
		_update_tower_bar()
	
	# 建造模式下 1-4 切换塔
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
		get_tree().change_scene_to_file("res://scenes/base.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if _build_mode and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_place_tower(get_global_mouse_position())

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

func _update_build_hint() -> void:
	var tower_data = GameState.tower_types[_selected_tower_type]
	build_hint.text = "建造模式: %s (%d$) - 左键放置, 1-4切换, B退出" % [tower_data["name"], tower_data["cost"]]

func _update_tower_bar() -> void:
	for i in _tower_buttons.size():
		var btn: Button = _tower_buttons[i]
		var tower_id: String = _tower_order[i]
		var tower_data = GameState.tower_types[tower_id]
		var can_afford: bool = GameState.money >= tower_data["cost"]
		var selected: bool = tower_id == _selected_tower_type
		btn.text = "[%d] %s (%d$)%s" % [i + 1, tower_data["name"], tower_data["cost"], " ←选中" if selected else ""]
		btn.disabled = not can_afford
		btn.modulate = Color(1, 1, 0.6) if selected else Color.WHITE

func _spawn_enemy() -> void:
	if not enemy_scene:
		return
	var enemy = enemy_scene.instantiate()
	var spawn_children = spawn_points.get_children()
	if spawn_children.size() > 0:
		var spawn_point = spawn_children[randi() % spawn_children.size()]
		enemy.position = spawn_point.position
	else:
		enemy.position = Vector2(randf_range(-300, 300), randf_range(-300, 300))
	enemy.died.connect(_on_enemy_died)
	add_child(enemy)
	_enemy_count += 1

func _place_tower(pos: Vector2) -> void:
	var tower_data = GameState.tower_types[_selected_tower_type]
	var cost: int = tower_data["cost"]
	if not GameState.spend_money(cost):
		return
	var tower = tower_scene.instantiate()
	tower.tower_type = _selected_tower_type
	tower.position = pos
	add_child(tower)
	_update_tower_bar()

func _on_money_changed(new_amount: int) -> void:
	money_label.text = "金钱: %d" % new_amount
	if _build_mode:
		_update_tower_bar()

func _on_weapon_changed(weapon_id: String) -> void:
	var weapon = GameState.weapons[weapon_id]
	weapon_hint.text = "武器: %s | R回大本营 | B建造" % weapon["name"]

func _on_enemy_died() -> void:
	_enemy_count -= 1
