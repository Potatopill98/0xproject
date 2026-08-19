extends Node2D
## 大本营场景 - 安全区，可升级和返回探索

@export var player_scene: PackedScene
@export var upgrade_panel_scene: PackedScene
@export var pause_menu_scene: PackedScene

var _player: Node2D = null
var _upgrade_panel: Control = null
var _pause_menu: Control = null
var _near_terminal: bool = false
var _near_exit: bool = false
var _shake_intensity: float = 0.0
var _shake_duration: float = 0.0

@onready var camera: Camera2D = $Camera2D
@onready var terminal: Area2D = $Terminal
@onready var exit_area: Area2D = $ExitArea
@onready var hint_label: Label = $UI/HintLabel

func _ready() -> void:
	Engine.time_scale = 1.0
	SoundManager.play_bgm()
	_player = player_scene.instantiate()
	_player.position = Vector2(0, 50)
	_player.add_to_group("player")
	add_child(_player)
	
	camera.make_current()
	camera.position_smoothing_enabled = true
	
	_upgrade_panel = upgrade_panel_scene.instantiate()
	add_child(_upgrade_panel)
	
	if pause_menu_scene:
		_pause_menu = pause_menu_scene.instantiate()
		add_child(_pause_menu)
	
	terminal.body_entered.connect(_on_terminal_enter)
	terminal.body_exited.connect(_on_terminal_exit)
	exit_area.body_entered.connect(_on_exit_enter)
	exit_area.body_exited.connect(_on_exit_exit)
	GameState.camera_shake.connect(_on_camera_shake)

func _process(delta: float) -> void:
	if _player and is_instance_valid(_player):
		camera.global_position = _player.global_position
	# 屏幕震动
	if _shake_duration > 0:
		_shake_duration -= delta
		camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake_intensity
	else:
		camera.offset = Vector2.ZERO
	
	if _upgrade_panel and _upgrade_panel.visible:
		hint_label.text = "按 E / ESC 关闭"
		hint_label.visible = true
	elif _near_terminal:
		hint_label.text = "按 E 打开升级终端"
		hint_label.visible = true
	elif _near_exit:
		hint_label.text = "按 E 出发探索"
		hint_label.visible = true
	else:
		hint_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if _upgrade_panel and _upgrade_panel.visible:
			_upgrade_panel.hide()
		elif _near_terminal:
			_upgrade_panel.open_panel()
		elif _near_exit:
			get_tree().change_scene_to_file("res://scenes/explore_zone.tscn")

func _on_terminal_enter(body: Node2D) -> void:
	if body.is_in_group("player"):
		_near_terminal = true

func _on_terminal_exit(body: Node2D) -> void:
	if body.is_in_group("player"):
		_near_terminal = false

func _on_exit_enter(body: Node2D) -> void:
	if body.is_in_group("player"):
		_near_exit = true

func _on_exit_exit(body: Node2D) -> void:
	if body.is_in_group("player"):
		_near_exit = false

func _on_camera_shake(intensity: float, duration: float) -> void:
	_shake_intensity = max(_shake_intensity, intensity)
	_shake_duration = max(_shake_duration, duration)
