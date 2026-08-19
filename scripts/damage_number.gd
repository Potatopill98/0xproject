extends Node2D
## 伤害数字 - 受击时飘出的数字

@export var damage: int = 10
@export var is_crit: bool = false
@export var float_speed: float = 60.0
@export var lifetime: float = 0.8

var _timer: float = 0.0
var _velocity: Vector2 = Vector2.ZERO

@onready var label: Label = $Label

func _ready() -> void:
	label.text = str(damage)
	if is_crit:
		label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
		label.add_theme_font_size_override("font_size", 18)
	else:
		label.add_theme_color_override("font_color", Color(1, 1, 1))
		label.add_theme_font_size_override("font_size", 14)
	_velocity = Vector2(randf_range(-20, 20), -float_speed)

func _process(delta: float) -> void:
	_timer += delta
	position += _velocity * delta
	_velocity.y += 100.0 * delta  # 重力
	
	var alpha: float = 1.0 - (_timer / lifetime)
	label.modulate.a = max(0, alpha)
	
	if _timer >= lifetime:
		queue_free()
