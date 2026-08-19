extends Control
## 升级面板 - 属性升级和武器解锁/切换

@onready var money_label: Label = $Panel/MoneyLabel
@onready var stats_container: VBoxContainer = $Panel/ScrollContainer/Content/StatsContainer
@onready var weapons_container: VBoxContainer = $Panel/ScrollContainer/Content/WeaponsContainer
@onready var close_btn: Button = $Panel/CloseBtn

var _stat_buttons: Dictionary = {}
var _weapon_buttons: Dictionary = {}

func _ready() -> void:
	visible = false
	close_btn.pressed.connect(_on_close_pressed)
	GameState.money_changed.connect(_on_money_changed)
	GameState.player_stats_changed.connect(_refresh)
	GameState.weapon_changed.connect(_refresh)
	GameState.weapon_unlocked.connect(_refresh)
	_build_ui()
	_refresh()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide()
		get_viewport().set_input_as_handled()

func open_panel() -> void:
	visible = true
	_refresh()

func _build_ui() -> void:
	# 属性升级按钮
	var stats := ["hp", "damage", "speed", "fire_rate"]
	var stat_names := {"hp": "生命上限", "damage": "攻击力", "speed": "移动速度", "fire_rate": "射速"}
	for stat in stats:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 40)
		stats_container.add_child(btn)
		btn.pressed.connect(_on_stat_upgrade.bind(stat))
		_stat_buttons[stat] = btn
		stat_names[stat] = stat_names[stat]
	
	# 武器按钮
	for weapon_id in GameState.weapons.keys():
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 40)
		weapons_container.add_child(btn)
		btn.pressed.connect(_on_weapon_clicked.bind(weapon_id))
		_weapon_buttons[weapon_id] = btn

func _refresh() -> void:
	money_label.text = "金钱: %d" % GameState.money
	
	var stat_names := {"hp": "生命上限", "damage": "攻击力", "speed": "移动速度", "fire_rate": "射速"}
	for stat in _stat_buttons.keys():
		var btn: Button = _stat_buttons[stat]
		var level: int = GameState.upgrade_levels[stat]
		var cost: int = GameState.upgrade_costs[stat]
		var can_afford: bool = GameState.money >= cost
		btn.text = "%s  Lv.%d  →  升级 (%d$)" % [stat_names[stat], level, cost]
		btn.disabled = not can_afford
	
	for weapon_id in _weapon_buttons.keys():
		var btn: Button = _weapon_buttons[weapon_id]
		var weapon: Dictionary = GameState.weapons[weapon_id]
		var is_equipped: bool = GameState.current_weapon == weapon_id
		if weapon["unlocked"]:
			if is_equipped:
				btn.text = "[装备中] %s" % weapon["name"]
				btn.disabled = true
			else:
				btn.text = "装备 %s" % weapon["name"]
				btn.disabled = false
		else:
			var can_afford: bool = GameState.money >= weapon["cost"]
			btn.text = "解锁 %s (%d$)" % [weapon["name"], weapon["cost"]]
			btn.disabled = not can_afford

func _on_stat_upgrade(stat: String) -> void:
	GameState.upgrade_stat(stat)

func _on_weapon_clicked(weapon_id: String) -> void:
	var weapon: Dictionary = GameState.weapons[weapon_id]
	if weapon["unlocked"]:
		GameState.equip_weapon(weapon_id)
	else:
		GameState.unlock_weapon(weapon_id)

func _on_money_changed(_amount: int) -> void:
	if visible:
		_refresh()

func _on_close_pressed() -> void:
	hide()
