extends Control
## 暂停菜单

signal resume_requested()
signal return_base_requested()
signal quit_requested()

@onready var resume_btn: Button = $Panel/ResumeBtn
@onready var base_btn: Button = $Panel/BaseBtn
@onready var quit_btn: Button = $Panel/QuitBtn

func _ready() -> void:
	visible = false
	resume_btn.pressed.connect(_on_resume)
	base_btn.pressed.connect(_on_return_base)
	quit_btn.pressed.connect(_on_quit)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible:
			_on_resume()
		else:
			show_pause()
		get_viewport().set_input_as_handled()

func show_pause() -> void:
	visible = true
	get_tree().paused = true

func _on_resume() -> void:
	visible = false
	get_tree().paused = false
	resume_requested.emit()

func _on_return_base() -> void:
	visible = false
	get_tree().paused = false
	GameState.build_mode = false
	get_tree().change_scene_to_file("res://scenes/base.tscn")

func _on_quit() -> void:
	visible = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
