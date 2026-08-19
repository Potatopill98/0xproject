extends Control
## 塔防升级/出售面板

@onready var level_label: Label = $Panel/LevelLabel
@onready var upgrade_btn: Button = $Panel/UpgradeBtn
@onready var sell_btn: Button = $Panel/SellBtn
@onready var close_btn: Button = $Panel/CloseBtn

var _tower: Node2D = null

signal tower_upgraded(tower: Node2D)
signal tower_sold(tower: Node2D)

func _ready() -> void:
	visible = false
	upgrade_btn.pressed.connect(_on_upgrade)
	sell_btn.pressed.connect(_on_sell)
	close_btn.pressed.connect(_on_close)

func show_for_tower(tower: Node2D) -> void:
	_tower = tower
	visible = true
	global_position = tower.global_position + Vector2(30, -50)
	_refresh()

func _refresh() -> void:
	if not _tower:
		return
	var level: int = _tower.tower_level if "tower_level" in _tower else 1
	var cost: int = _tower.get_upgrade_cost() if _tower.has_method("get_upgrade_cost") else 50
	var can_upgrade: bool = level < 3 and GameState.money >= cost
	level_label.text = "等级 %d / 3" % level
	if level >= 3:
		upgrade_btn.text = "已满级"
		upgrade_btn.disabled = true
	else:
		upgrade_btn.text = "升级 (%d$)" % cost
		upgrade_btn.disabled = not can_upgrade
	var sell_value: int = _tower.get_sell_value() if _tower.has_method("get_sell_value") else 25
	sell_btn.text = "出售 (+%d$)" % sell_value

func _on_upgrade() -> void:
	if _tower and _tower.has_method("upgrade"):
		if _tower.upgrade():
			tower_upgraded.emit(_tower)
			_refresh()

func _on_sell() -> void:
	if _tower and _tower.has_method("sell"):
		_tower.sell()
		tower_sold.emit(_tower)
		visible = false

func _on_close() -> void:
	visible = false
	_tower = null
