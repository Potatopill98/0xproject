extends Control
## 胜利界面 - 恢复全部设施后显示

@onready var stats_label: Label = $Panel/StatsLabel
@onready var continue_btn: Button = $Panel/ContinueBtn
@onready var menu_btn: Button = $Panel/MenuBtn

signal continue_requested()
signal menu_requested()

func _ready() -> void:
	visible = false
	continue_btn.pressed.connect(_on_continue)
	menu_btn.pressed.connect(_on_menu)

func show_victory(wave_cleared: int, money: int) -> void:
	visible = true
	get_tree().paused = true
	stats_label.text = "区域已完全恢复!\n清除波次: %d\n剩余金钱: %d" % [wave_cleared, money]

func _on_continue() -> void:
	visible = false
	get_tree().paused = false
	continue_requested.emit()

func _on_menu() -> void:
	visible = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
