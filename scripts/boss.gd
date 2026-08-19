extends CharacterBody2D
## BOSS敌人 - 大体型，高血量，有冲撞和范围攻击

@export var max_hp: int = 1500
@export var damage: int = 20
@export var move_speed: float = 50.0
@export var charge_speed: float = 250.0
@export var attack_range: float = 50.0
@export var attack_cooldown: float = 1.5
@export var charge_cooldown: float = 4.0
@export var aoe_cooldown: float = 6.0
@export var money_reward: int = 100
@export var damage_number_scene: PackedScene
@export var explosion_scene: PackedScene

var hp: int
var _attack_timer: float = 0.0
var _charge_timer: float = 2.0
var _aoe_timer: float = 4.0
var _player: Node2D = null
var _knockback: Vector2 = Vector2.ZERO
var _is_charging: bool = false
var _charge_dir: Vector2 = Vector2.ZERO
var _charge_duration: float = 0.0
var _nav_agent: NavigationAgent2D

signal boss_died()
signal hp_changed(current: int, maximum: int)

@onready var sprite: Sprite2D = $Sprite2D
@onready var hp_bar: ProgressBar = $HPBar

func _ready() -> void:
	hp = max_hp
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	add_to_group("enemy")
	add_to_group("boss")
	_player = get_tree().get_first_node_in_group("player")
	scale = Vector2(1.25, 1.25)
	hp_bar.scale = Vector2(0.4, 0.4)
	hp_bar.position = Vector2(0, -20)
	
	_nav_agent = NavigationAgent2D.new()
	_nav_agent.path_desired_distance = 12.0
	_nav_agent.target_desired_distance = attack_range
	add_child(_nav_agent)
	
	hp_changed.emit(hp, max_hp)

func _process(delta: float) -> void:
	if _attack_timer > 0:
		_attack_timer -= delta
	if _charge_timer > 0:
		_charge_timer -= delta
	if _aoe_timer > 0:
		_aoe_timer -= delta
	_knockback = _knockback.lerp(Vector2.ZERO, 8.0 * delta)

func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		return
	
	var to_player: Vector2 = _player.global_position - global_position
	var dist: float = to_player.length()
	
	# 冲撞攻击
	if _is_charging:
		_charge_duration -= delta
		velocity = _charge_dir * charge_speed + _knockback
		move_and_slide()
		if _charge_duration <= 0:
			_is_charging = false
			_charge_timer = charge_cooldown
		# 冲撞中碰到玩家造成伤害
		if dist < 40 and _attack_timer <= 0:
			_player.take_damage(damage)
			_attack_timer = 0.5
		return
	
	# 启动冲撞
	if _charge_timer <= 0 and dist > 80 and dist < 300:
		_is_charging = true
		_charge_dir = to_player.normalized()
		_charge_duration = 0.6
		return
	
	# AOE范围攻击
	if _aoe_timer <= 0 and dist < 120:
		_do_aoe_attack()
		_aoe_timer = aoe_cooldown
		return
	
	# 普通追击+近战
	if dist > attack_range:
		_nav_agent.target_position = _player.global_position
		var next_pos: Vector2 = _nav_agent.get_next_path_position()
		var dir: Vector2 = (next_pos - global_position).normalized()
		velocity = dir * move_speed + _knockback
		move_and_slide()
	else:
		velocity = _knockback
		move_and_slide()
		if _attack_timer <= 0:
			_player.take_damage(damage)
			_attack_timer = attack_cooldown
	
	sprite.flip_h = to_player.x < 0

func _do_aoe_attack() -> void:
	# 范围爆炸
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		explosion.radius = 100.0
		explosion.global_position = global_position
		get_tree().current_scene.add_child(explosion)
	# 对范围内玩家造成伤害
	if _player and global_position.distance_to(_player.global_position) < 100:
		_player.take_damage(int(damage * 1.5))
	SoundManager.play_sfx("enemy_die", -8)

func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	hp -= amount
	hp_bar.value = hp
	hp_changed.emit(hp, max_hp)
	sprite.modulate = Color(1.5, 1.5, 1.5)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(0.8, 0.2, 0.2), 0.1)
	_show_damage_number(amount)
	SoundManager.play_sfx("hit", -10)
	if knockback_dir != Vector2.ZERO:
		_knockback += knockback_dir.normalized() * 80.0
	if hp <= 0:
		_die()

func _show_damage_number(amount: int) -> void:
	if not damage_number_scene:
		return
	var dmg = damage_number_scene.instantiate()
	dmg.damage = amount
	dmg.is_crit = amount > 30
	dmg.global_position = global_position + Vector2(randf_range(-15, 15), -20)
	get_tree().current_scene.add_child(dmg)

func _die() -> void:
	GameState.add_money(money_reward)
	SoundManager.play_sfx("enemy_die", -5)
	GameState.shake_camera(8.0, 0.3)
	GameState.start_slow_motion(3.0, 0.3)
	boss_died.emit()
	# 死亡爆炸
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		explosion.radius = 120.0
		explosion.global_position = global_position
		get_tree().current_scene.add_child(explosion)
	queue_free()
