extends Area2D
## 子弹 - 玩家和敌人通用，支持范围爆炸

@export var speed: float = 500.0
@export var damage: int = 10
@export var lifetime: float = 2.0
@export var splash_radius: float = 0.0
@export var explosion_scene: PackedScene
var direction: Vector2 = Vector2.RIGHT
var is_player_bullet: bool = true

var _life_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	collision_layer = 8
	if is_player_bullet:
		collision_mask = 5
		if ResourceLoader.exists("res://assets/sprites/bullet_player.png") and sprite:
			sprite.texture = load("res://assets/sprites/bullet_player.png")
			sprite.scale = Vector2(0.5, 0.5)
	else:
		collision_mask = 3
		if ResourceLoader.exists("res://assets/sprites/bullet_enemy.png") and sprite:
			sprite.texture = load("res://assets/sprites/bullet_enemy.png")
			sprite.scale = Vector2(0.5, 0.5)
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	position += direction * speed * delta
	_life_timer += delta
	if _life_timer >= lifetime:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if is_player_bullet and body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage, direction)
		if splash_radius > 0:
			_apply_splash()
		queue_free()
	elif not is_player_bullet and body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()

func _apply_splash() -> void:
	# 生成爆炸视觉效果
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		explosion.radius = splash_radius
		explosion.global_position = global_position
		get_tree().current_scene.add_child(explosion)
	# 范围伤害
	var enemies := get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist: float = global_position.distance_to(enemy.global_position)
		if dist <= splash_radius:
			if enemy.has_method("take_damage"):
				var dir: Vector2 = (enemy.global_position - global_position).normalized()
				enemy.take_damage(int(damage * 0.5), dir)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("world_obstacle"):
		queue_free()
