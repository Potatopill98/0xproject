extends CharacterBody2D
## 敌人 - 支持导航寻路和三种类型，行走动画

@export var enemy_type: String = "normal"
@export var move_speed: float = 80.0
@export var max_hp: int = 30
@export var damage: int = 10
@export var attack_range: float = 30.0
@export var attack_cooldown: float = 1.0
@export var money_reward: int = 10
@export var damage_number_scene: PackedScene
@export var bullet_scene: PackedScene

var hp: int
var _attack_timer: float = 0.0
var _player: Node2D = null
var _knockback: Vector2 = Vector2.ZERO
var _nav_agent: NavigationAgent2D
var _target_refresh_timer: float = 0.0
var _anim_frame: int = 0
var _anim_timer: float = 0.0
var _is_moving: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var hp_bar: ProgressBar = $HPBar

signal died()

func _ready() -> void:
	_apply_type_stats()
	hp = max_hp
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	add_to_group("enemy")
	_player = get_tree().get_first_node_in_group("player")
	
	_nav_agent = NavigationAgent2D.new()
	_nav_agent.path_desired_distance = 8.0
	_nav_agent.target_desired_distance = attack_range
	add_child(_nav_agent)
	
	# 加载对应类型的行走动画精灵表
	var sheet_path = "res://assets/sprites/enemy_%s_walk.png" % enemy_type
	if ResourceLoader.exists(sheet_path):
		sprite.texture = load(sheet_path)
		sprite.region_enabled = true
		sprite.region_rect = Rect2(0, 0, 32, 32)
		sprite.scale = Vector2(0.5, 0.5)

func _apply_type_stats() -> void:
	match enemy_type:
		"fast":
			move_speed = 140.0
			max_hp = 15
			damage = 5
			attack_range = 25.0
			attack_cooldown = 0.6
			money_reward = 8
		"ranged":
			move_speed = 55.0
			max_hp = 25
			damage = 8
			attack_range = 180.0
			attack_cooldown = 1.5
			money_reward = 15
		_:
			pass

func _process(delta: float) -> void:
	if _attack_timer > 0:
		_attack_timer -= delta
	_knockback = _knockback.lerp(Vector2.ZERO, 10.0 * delta)
	
	# 行走动画
	if _is_moving and sprite.region_enabled:
		_anim_timer += delta
		if _anim_timer >= 0.18:
			_anim_timer = 0.0
			_anim_frame = (_anim_frame + 1) % 4
			sprite.region_rect = Rect2(_anim_frame * 32, 0, 32, 32)

func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		return
	
	var to_player: Vector2 = _player.global_position - global_position
	var dist: float = to_player.length()
	_is_moving = false
	
	if enemy_type == "ranged" and dist < 120:
		velocity = -to_player.normalized() * move_speed + _knockback
		move_and_slide()
		_is_moving = true
	elif dist > attack_range:
		_target_refresh_timer -= delta
		if _target_refresh_timer <= 0:
			_target_refresh_timer = 0.3
			_nav_agent.target_position = _player.global_position
		
		var next_pos: Vector2 = _nav_agent.get_next_path_position()
		var dir: Vector2 = (next_pos - global_position).normalized()
		velocity = dir * move_speed + _knockback
		move_and_slide()
		_is_moving = true
	else:
		velocity = _knockback
		move_and_slide()
		if _attack_timer <= 0:
			_attack()
			_attack_timer = attack_cooldown
	
	sprite.flip_h = to_player.x < 0

func _attack() -> void:
	if enemy_type == "ranged":
		if bullet_scene and _player:
			var bullet = bullet_scene.instantiate()
			bullet.global_position = global_position
			var dir: Vector2 = (_player.global_position - global_position).normalized()
			bullet.direction = dir
			bullet.speed = 250.0
			bullet.damage = damage
			bullet.is_player_bullet = false
			get_tree().current_scene.add_child(bullet)
	else:
		if _player and _player.has_method("take_damage"):
			_player.take_damage(damage)

func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	hp -= amount
	hp_bar.value = hp
	_tint_hit()
	_show_damage_number(amount)
	SoundManager.play_sfx("hit", -12)
	if knockback_dir != Vector2.ZERO:
		_knockback += knockback_dir.normalized() * 150.0
	if hp <= 0:
		_die()

func _show_damage_number(amount: int) -> void:
	if not damage_number_scene:
		return
	var dmg = damage_number_scene.instantiate()
	dmg.damage = amount
	dmg.global_position = global_position + Vector2(randf_range(-8, 8), -10)
	get_tree().current_scene.add_child(dmg)

func _tint_hit() -> void:
	sprite.modulate = Color(1.5, 1.5, 1.5)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func _die() -> void:
	GameState.add_money(money_reward)
	SoundManager.play_sfx("enemy_die", -10)
	GameState.shake_camera(1.0, 0.05)
	died.emit()
	queue_free()
