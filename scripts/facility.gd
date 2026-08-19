extends Area2D
## 可恢复设施 - 区域清除后可花钱激活，提供永久增益

@export var facility_type: String = "medical"  # medical / workshop / power
@export var cost: int = 50
@export var activated: bool = false

var _player_nearby: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var hint: Label = $HintLabel

signal facility_activated(type: String)

func _ready() -> void:
	body_entered.connect(_on_body_enter)
	body_exited.connect(_on_body_exit)
	# 加载对应类型的设施外观
	var tex_path = "res://assets/sprites/facility_%s.png" % facility_type
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path)
		sprite.scale = Vector2(0.5, 0.5)
	_update_visual()

func _process(_delta: float) -> void:
	if activated:
		hint.visible = false
	else:
		hint.visible = _player_nearby
		if hint.visible:
			var name = _get_name()
			hint.text = "按E恢复 %s (%d$)" % [name, cost]

func _unhandled_input(event: InputEvent) -> void:
	if activated or not _player_nearby:
		return
	if event.is_action_pressed("interact"):
		_activate()

func _activate() -> void:
	if not GameState.spend_money(cost):
		return
	activated = true
	GameState.facilities_activated[facility_type] = true
	GameState.facility_activated.emit(facility_type)
	facility_activated.emit(facility_type)
	_update_visual()

func _update_visual() -> void:
	if activated:
		sprite.modulate = Color.WHITE
	else:
		sprite.modulate = Color(0.4, 0.4, 0.4)

func _get_name() -> String:
	match facility_type:
		"medical": return "医疗站"
		"workshop": return "工坊"
		"power": return "发电站"
		_: return "设施"

func _get_active_color() -> Color:
	match facility_type:
		"medical": return Color(0.3, 1, 0.4)
		"workshop": return Color(1, 0.7, 0.2)
		"power": return Color(0.3, 0.7, 1)
		_: return Color.WHITE

func _on_body_enter(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = true

func _on_body_exit(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
