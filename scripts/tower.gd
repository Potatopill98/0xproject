extends Node2D
## 塔防炮塔基类 - 支持升级/出售，激光塔为持续射线

@export var tower_type: String = "machine_gun"
@export var damage: int = 5
@export var fire_rate: float = 0.15
@export var range: float = 150.0
@export var bullet_speed: float = 400.0
@export var splash_radius: float = 0.0
@export var bullet_scene: PackedScene

var tower_level: int = 1
var _base_cost: int = 50
var _fire_cooldown: float = 0.0
var _target: Node2D = null
var _tower_data: Dictionary = {}

# 激光塔专用
var _laser_charge: float = 0.0
var _laser_timer: float = 0.0
var _laser_line: Line2D = null

signal tower_clicked(tower: Node2D)

@onready var sprite: Sprite2D = $Sprite2D
@onready var range_indicator: Node2D = $RangeIndicator
@onready var muzzle: Marker2D = $Muzzle

func _ready() -> void:
	add_to_group("tower")
	_load_tower_data()
	range_indicator.visible = false
	# 加载对应类型的塔防外观
	var tex_path = "res://assets/sprites/tower_%s.png" % tower_type
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path)
		sprite.scale = Vector2(0.5, 0.5)
	if tower_type == "laser":
		_setup_laser()
	_update_visual()

func _load_tower_data() -> void:
	if GameState.tower_types.has(tower_type):
		_tower_data = GameState.tower_types[tower_type]
		damage = _tower_data.get("damage", damage)
		fire_rate = _tower_data.get("fire_rate", fire_rate)
		range = _tower_data.get("range", range)
		splash_radius = _tower_data.get("splash_radius", 0.0)
		_base_cost = _tower_data.get("cost", 50)

func _setup_laser() -> void:
	_laser_line = Line2D.new()
	_laser_line.width = 2.0
	_laser_line.default_color = Color(0.3, 0.9, 1.0, 0.8)
	_laser_line.visible = false
	add_child(_laser_line)

func _process(delta: float) -> void:
	if tower_type == "laser":
		_process_laser(delta)
		return
	if _fire_cooldown > 0:
		_fire_cooldown -= delta
	_find_target()
	if _target and _fire_cooldown <= 0:
		_shoot()

func _process_laser(delta: float) -> void:
	_find_target()
	if _target and is_instance_valid(_target):
		_laser_line.visible = true
		_laser_line.clear_points()
		_laser_line.add_point(to_local(muzzle.global_position))
		_laser_line.add_point(to_local(_target.global_position))
		_laser_charge = min(3.0, _laser_charge + delta * 0.5)
		var charge_mult: float = 1.0 + _laser_charge * 0.8
		_laser_timer += delta
		if _laser_timer >= 0.1:
			_laser_timer = 0.0
			var dmg: int = int(damage * charge_mult * GameState.get_tower_damage_mult())
			if _target.has_method("take_damage"):
				_target.take_damage(dmg, Vector2.ZERO)
	else:
		_laser_charge = max(0.0, _laser_charge - delta * 2.0)
		_laser_line.visible = false

func _find_target() -> void:
	_target = null
	var effective_range: float = range * GameState.get_tower_range_mult()
	var enemies := get_tree().get_nodes_in_group("enemy")
	var closest_dist: float = effective_range
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist: float = global_position.distance_to(enemy.global_position)
		if dist < closest_dist:
			closest_dist = dist
			_target = enemy

func _shoot() -> void:
	if not _target or not is_instance_valid(_target):
		return
	_fire_cooldown = fire_rate
	var bullet = bullet_scene.instantiate()
	bullet.global_position = muzzle.global_position
	var dir: Vector2 = (_target.global_position - muzzle.global_position).normalized()
	bullet.direction = dir
	bullet.speed = bullet_speed
	bullet.damage = int(damage * GameState.get_tower_damage_mult())
	bullet.is_player_bullet = true
	bullet.splash_radius = splash_radius
	get_tree().current_scene.add_child(bullet)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		if global_position.distance_to(mouse_pos) < 20:
			tower_clicked.emit(self)
			get_viewport().set_input_as_handled()

func get_upgrade_cost() -> int:
	return int(_base_cost * 0.8 * tower_level)

func get_sell_value() -> int:
	var total_spent: int = _base_cost
	for i in range(1, tower_level):
		total_spent += int(_base_cost * 0.8 * i)
	return int(total_spent * 0.7)

func upgrade() -> bool:
	if tower_level >= 3:
		return false
	var cost: int = get_upgrade_cost()
	if not GameState.spend_money(cost):
		return false
	tower_level += 1
	# 升级属性
	damage = int(damage * 1.4)
	range = range * 1.15
	fire_rate = fire_rate * 0.85
	_update_visual()
	return true

func sell() -> void:
	GameState.add_money(get_sell_value())
	queue_free()

func _update_visual() -> void:
	# 等级越高颜色越亮
	var brightness: float = 0.7 + tower_level * 0.15
	sprite.modulate = Color(brightness, brightness, brightness)
	# 等级标记
	if tower_level >= 2:
		sprite.scale = Vector2(1.1, 1.1)
	if tower_level >= 3:
		sprite.scale = Vector2(1.2, 1.2)

func show_range(show: bool) -> void:
	range_indicator.visible = show
