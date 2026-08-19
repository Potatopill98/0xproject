extends Control
## 游戏结束面板

@onready var restart_btn: Button = $Panel/RestartBtn
@onready var base_btn: Button = $Panel/BaseBtn
@onready var stats_label: Label = $Panel/StatsLabel

signal restart_requested()
signal return_base_requested()

func _ready() -> void:
	visible = false
	restart_btn.pressed.connect(_on_restart)
	base_btn.pressed.connect(_on_return_base)

func show_game_over(wave_reached: int, money_earned: int) -> void:
	visible = true
	stats_label.text = "坚持到第 %d 波\n获得金钱: %d" % [wave_reached, money_earned]

func _on_restart() -> void:
	visible = false
	restart_requested.emit()

func _on_return_base() -> void:
	visible = false
	return_base_requested.emit()
