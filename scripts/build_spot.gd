extends Area2D
## 建造点 - 只能在指定位置建造炮塔

@export var tower_scene: PackedScene

var _occupied: bool = false
var _tower: Node2D = null
var _player_nearby: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var hint: Label = $HintLabel

signal tower_built(spot: Node)

func _ready() -> void:
	body_entered.connect(_on_body_enter)
	body_exited.connect(_on_body_exit)
	hint.visible = false
	if ResourceLoader.exists("res://assets/sprites/build_spot.png"):
		sprite.texture = load("res://assets/sprites/build_spot.png")
		sprite.scale = Vector2(0.5, 0.5)

func _process(_delta: float) -> void:
	if _occupied:
		hint.visible = false
		sprite.modulate = Color(0.5, 0.5, 0.5)
	else:
		sprite.modulate = Color(0.3, 0.9, 0.3) if _player_nearby else Color(0.3, 0.5, 0.3)
		hint.visible = _player_nearby and GameState.build_mode
		if hint.visible:
			hint.text = "左键建塔"

func _unhandled_input(event: InputEvent) -> void:
	if not GameState.build_mode or _occupied:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		if global_position.distance_to(mouse_pos) < 30:
			_build_tower()
			get_viewport().set_input_as_handled()

func _build_tower() -> void:
	if _occupied or not tower_scene:
		return
	var selected_type = "machine_gun"
	var main = get_tree().current_scene
	if main and main.has_method("get_selected_tower"):
		selected_type = main.get_selected_tower()
	var cost: int = GameState.tower_types[selected_type]["cost"]
	if not GameState.spend_money(cost):
		return
	var tower = tower_scene.instantiate()
	tower.tower_type = selected_type
	tower.position = Vector2.ZERO
	add_child(tower)
	_tower = tower
	_occupied = true
	tower.tree_exited.connect(_on_tower_removed)
	tower_built.emit(self)

func _on_tower_removed() -> void:
	_occupied = false
	_tower = null

func _on_body_enter(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = true

func _on_body_exit(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false

func is_occupied() -> bool:
	return _occupied
