extends Control
## 主菜单

@onready var start_btn: Button = $Panel/StartBtn
@onready var quit_btn: Button = $Panel/QuitBtn

func _ready() -> void:
	start_btn.pressed.connect(_on_start)
	quit_btn.pressed.connect(_on_quit)

func _on_start() -> void:
	get_tree().change_scene_to_file("res://scenes/base.tscn")

func _on_quit() -> void:
	get_tree().quit()
