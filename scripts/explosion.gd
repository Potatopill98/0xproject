extends Node2D
## 爆炸效果 - 范围伤害的视觉反馈

@export var radius: float = 50.0
@export var duration: float = 0.3

var _timer: float = 0.0
var _circle: Line2D
var _particles: Array = []
var _exp_sprite: Sprite2D = null

func _ready() -> void:
	_circle = Line2D.new()
	_circle.width = 2.0
	_circle.default_color = Color(1, 0.6, 0.2, 0.8)
	_draw_circle()
	add_child(_circle)
	
	# 爆炸图
	if ResourceLoader.exists("res://assets/sprites/explosion.png"):
		var exp_sprite = Sprite2D.new()
		exp_sprite.texture = load("res://assets/sprites/explosion.png")
		exp_sprite.scale = Vector2(0.5, 0.5)
		exp_sprite.z_index = 1
		add_child(exp_sprite)
		_exp_sprite = exp_sprite
	
	# 粒子效果
	_particles = []
	for i in 12:
		var flash = ColorRect.new()
		flash.size = Vector2(3, 3)
		flash.color = Color(1, randf_range(0.5, 0.9), 0.2, 1)
		flash.position = Vector2(-1.5, -1.5)
		add_child(flash)
		var angle: float = randf() * TAU
		var speed: float = randf_range(60, 180)
		_particles.append({"node": flash, "vel": Vector2(cos(angle), sin(angle)) * speed})
	
	GameState.shake_camera(radius * 0.04, 0.1)

func _draw_circle() -> void:
	_circle.clear_points()
	var segments: int = 24
	for i in segments + 1:
		var angle: float = (float(i) / segments) * TAU
		_circle.add_point(Vector2(cos(angle), sin(angle)) * radius)

func _process(delta: float) -> void:
	_timer += delta
	var t: float = _timer / duration
	var scale_val: float = t
	scale = Vector2(scale_val, scale_val)
	_circle.default_color.a = 0.8 * (1.0 - t)
	
	# 爆炸图放大淡出
	if _exp_sprite:
		_exp_sprite.scale = Vector2(0.5 + t * 1.5, 0.5 + t * 1.5)
		_exp_sprite.modulate.a = 1.0 - t
	
	# 更新火花
	for f in _particles:
		var flash: ColorRect = f["node"]
		flash.position += f["vel"] * delta
		f["vel"] = f["vel"] * 0.92
		flash.color.a = 1.0 - t
	
	if _timer >= duration:
		queue_free()
