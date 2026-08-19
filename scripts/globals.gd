extends Node
## 全局游戏状态单例
## 管理金钱、玩家属性、武器、游戏进度等

# 玩家数据
var money: int = 99999
var player_max_hp: int = 100
var player_damage: int = 10
var player_move_speed: float = 200.0
var player_fire_rate: float = 0.3  # 射击间隔（秒）

# 升级等级
var upgrade_levels := {
	"hp": 0,
	"damage": 0,
	"speed": 0,
	"fire_rate": 0,
}

# 升级费用
var upgrade_costs := {
	"hp": 50,
	"damage": 60,
	"speed": 40,
	"fire_rate": 80,
}

# 武器数据
var weapons := {
	"pistol": {
		"name": "手枪",
		"damage": 10,
		"fire_rate": 0.3,
		"bullet_speed": 500.0,
		"unlocked": true,
		"cost": 0,
		"description": "初始武器，平衡型",
	},
	"smg": {
		"name": "冲锋枪",
		"damage": 6,
		"fire_rate": 0.08,
		"bullet_speed": 600.0,
		"unlocked": false,
		"cost": 200,
		"description": "高射速，低伤害",
	},
	"shotgun": {
		"name": "霰弹枪",
		"damage": 8,
		"fire_rate": 0.6,
		"bullet_speed": 450.0,
		"pellets": 5,
		"spread": 0.4,
		"unlocked": false,
		"cost": 350,
		"description": "近距离爆发，一次5发",
	},
	"rifle": {
		"name": "步枪",
		"damage": 25,
		"fire_rate": 0.4,
		"bullet_speed": 700.0,
		"unlocked": false,
		"cost": 500,
		"description": "高伤害，中射速",
	},
}

var current_weapon: String = "pistol"

# 建造模式状态
var build_mode: bool = false

# 已激活的设施
var facilities_activated := {
	"medical": false,
	"workshop": false,
	"power": false,
}

# 塔防数据
var tower_types := {
	"machine_gun": {
		"name": "机枪塔",
		"cost": 50,
		"damage": 5,
		"fire_rate": 0.15,
		"range": 150.0,
		"color": Color(0.8, 0.6, 0.2),
	},
	"cannon": {
		"name": "火炮塔",
		"cost": 100,
		"damage": 25,
		"fire_rate": 1.5,
		"range": 180.0,
		"splash_radius": 50.0,
		"color": Color(0.7, 0.3, 0.2),
	},
	"laser": {
		"name": "激光塔",
		"cost": 150,
		"damage": 2,
		"fire_rate": 0.05,
		"range": 200.0,
		"color": Color(0.2, 0.8, 1.0),
	},
	"mortar": {
		"name": "迫击炮",
		"cost": 200,
		"damage": 40,
		"fire_rate": 2.5,
		"range": 300.0,
		"splash_radius": 80.0,
		"color": Color(0.5, 0.5, 0.5),
	},
}

# 信号
signal money_changed(new_amount: int)
signal player_stats_changed()
signal weapon_changed(weapon_id: String)
signal weapon_unlocked(weapon_id: String)
signal build_mode_changed(enabled: bool)
signal facility_activated(type: String)
signal camera_shake(intensity: float, duration: float)

var _slow_mo_end_tick: int = 0

func shake_camera(intensity: float = 5.0, duration: float = 0.1) -> void:
	camera_shake.emit(intensity, duration)

func start_slow_motion(duration: float, scale: float = 0.3) -> void:
	Engine.time_scale = scale
	_slow_mo_end_tick = Time.get_ticks_msec() + int(duration * 1000)

func _process(_delta: float) -> void:
	if _slow_mo_end_tick > 0 and Time.get_ticks_msec() >= _slow_mo_end_tick:
		Engine.time_scale = 1.0
		_slow_mo_end_tick = 0

func add_money(amount: int) -> void:
	money += amount
	money_changed.emit(money)

func spend_money(amount: int) -> bool:
	if money >= amount:
		money -= amount
		money_changed.emit(money)
		return true
	return false

func upgrade_stat(stat: String) -> bool:
	if not upgrade_costs.has(stat):
		return false
	var cost: int = upgrade_costs[stat]
	if not spend_money(cost):
		return false
	
	match stat:
		"hp":
			player_max_hp += 20
		"damage":
			player_damage += 5
		"speed":
			player_move_speed += 20.0
		"fire_rate":
			player_fire_rate = max(0.05, player_fire_rate - 0.03)
	
	upgrade_levels[stat] += 1
	upgrade_costs[stat] = int(cost * 1.5)
	player_stats_changed.emit()
	return true

func unlock_weapon(weapon_id: String) -> bool:
	if not weapons.has(weapon_id):
		return false
	var weapon = weapons[weapon_id]
	if weapon["unlocked"]:
		return false
	if not spend_money(weapon["cost"]):
		return false
	weapon["unlocked"] = true
	weapon_unlocked.emit(weapon_id)
	return true

func equip_weapon(weapon_id: String) -> bool:
	if not weapons.has(weapon_id):
		return false
	if not weapons[weapon_id]["unlocked"]:
		return false
	current_weapon = weapon_id
	weapon_changed.emit(weapon_id)
	return true

func get_current_weapon_data() -> Dictionary:
	return weapons[current_weapon]

# 设施增益
func get_tower_damage_mult() -> float:
	return 1.2 if facilities_activated["workshop"] else 1.0

func get_tower_range_mult() -> float:
	return 1.15 if facilities_activated["power"] else 1.0

func has_medical_station() -> bool:
	return facilities_activated["medical"]

func all_facilities_activated() -> bool:
	return facilities_activated["medical"] and facilities_activated["workshop"] and facilities_activated["power"]
