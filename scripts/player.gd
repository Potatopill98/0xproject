extends CharacterBody2D
## 玩家控制器 - 俯视角射击，支持多武器，行走动画

@export var move_speed: float = 200.0
@export var max_hp: int = 100
@export var bullet_scene: PackedScene

var hp: int
var _fire_cooldown: float = 0.0
var _aim_direction: Vector2 = Vector2.RIGHT
var _current_weapon: Dictionary = {}
var _heal_timer: float = 0.0
var _anim_frame: int = 0
var _anim_timer: float = 0.0
var _is_moving: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var muzzle: Marker2D = $Muzzle
@onready var hp_bar: ProgressBar = $HPBar

signal died()
signal hp_changed(current: int, maximum: int)

func _ready() -> void:
	max_hp = GameState.player_max_hp
	move_speed = GameState.player_move_speed
	hp = max_hp
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	hp_changed.emit(hp, max_hp)
	_refresh_weapon()
	GameState.weapon_changed.connect(_on_weapon_changed)
	GameState.player_stats_changed.connect(_on_stats_changed)
	# 行走动画精灵表
	if ResourceLoader.exists("res://assets/sprites/player_walk.png"):
		sprite.texture = load("res://assets/sprites/player_walk.png")
		sprite.region_enabled = true
		sprite.region_rect = Rect2(0, 0, 32, 32)
		sprite.scale = Vector2(0.5, 0.5)

func _process(delta: float) -> void:
	if _fire_cooldown > 0:
		_fire_cooldown -= delta
	
	# 医疗站回血
	if GameState.has_medical_station() and hp < max_hp:
		_heal_timer += delta
		if _heal_timer >= 1.0:
			_heal_timer = 0.0
			heal(2)
	
	var mouse_pos: Vector2 = get_global_mouse_position()
	_aim_direction = (mouse_pos - global_position).normalized()
	_update_sprite_flip()
	
	# 行走动画
	if _is_moving:
		_anim_timer += delta
		if _anim_timer >= 0.15:
			_anim_timer = 0.0
			_anim_frame = (_anim_frame + 1) % 4
			if sprite.region_enabled:
				sprite.region_rect = Rect2(_anim_frame * 32, 0, 32, 32)
	else:
		_anim_frame = 0
		_anim_timer = 0.0
		if sprite.region_enabled:
			sprite.region_rect = Rect2(0, 0, 32, 32)
	
	# 数字键切换武器
	if Input.is_action_just_pressed("weapon_1"):
		GameState.equip_weapon("pistol")
	elif Input.is_action_just_pressed("weapon_2"):
		GameState.equip_weapon("smg")
	elif Input.is_action_just_pressed("weapon_3"):
		GameState.equip_weapon("shotgun")
	elif Input.is_action_just_pressed("weapon_4"):
		GameState.equip_weapon("rifle")

func _physics_process(delta: float) -> void:
	var input_dir: Vector2 = Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_up", "move_down")
	if input_dir.length() > 0:
		input_dir = input_dir.normalized()
		_is_moving = true
	else:
		_is_moving = false
	
	velocity = input_dir * move_speed
	move_and_slide()
	
	if Input.is_action_pressed("shoot") and _fire_cooldown <= 0 and not GameState.build_mode:
		_shoot()

func _shoot() -> void:
	_fire_cooldown = _current_weapon.get("fire_rate", 0.3)
	var damage: int = _current_weapon.get("damage", 10) + GameState.player_damage - 10
	var bullet_speed: float = _current_weapon.get("bullet_speed", 500.0)
	var pellets: int = _current_weapon.get("pellets", 1)
	var spread: float = _current_weapon.get("spread", 0.0)
	
	SoundManager.play_sfx("shoot", -15)
	GameState.shake_camera(0.8, 0.04)
	_spawn_muzzle_flash()
	
	for i in pellets:
		var bullet = bullet_scene.instantiate()
		bullet.global_position = muzzle.global_position
		var dir: Vector2 = _aim_direction
		if pellets > 1:
			var angle_offset: float = randf_range(-spread, spread)
			dir = dir.rotated(angle_offset)
		bullet.direction = dir
		bullet.speed = bullet_speed
		bullet.damage = damage
		bullet.is_player_bullet = true
		get_tree().current_scene.add_child(bullet)

func _spawn_muzzle_flash() -> void:
	var flash = ColorRect.new()
	flash.size = Vector2(8, 8)
	flash.color = Color(1, 0.9, 0.4, 1)
	flash.global_position = muzzle.global_position - Vector2(4, 4)
	get_tree().current_scene.add_child(flash)
	var tween := create_tween()
	tween.tween_property(flash, "scale", Vector2(2, 2), 0.05)
	tween.parallel().tween_property(flash, "color:a", 0.0, 0.08)
	tween.tween_callback(flash.queue_free)

func _refresh_weapon() -> void:
	_current_weapon = GameState.get_current_weapon_data()

func _update_sprite_flip() -> void:
	sprite.flip_h = _aim_direction.x < 0

func take_damage(amount: int) -> void:
	hp -= amount
	hp_bar.value = hp
	hp_changed.emit(hp, max_hp)
	GameState.shake_camera(3.0, 0.1)
	sprite.modulate = Color(1.5, 0.5, 0.5)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.15)
	if hp <= 0:
		_die()

func heal(amount: int) -> void:
	hp = min(max_hp, hp + amount)
	hp_bar.value = hp
	hp_changed.emit(hp, max_hp)

func _die() -> void:
	died.emit()
	queue_free()

func _on_weapon_changed(_weapon_id: String) -> void:
	_refresh_weapon()

func _on_stats_changed() -> void:
	move_speed = GameState.player_move_speed
	var old_max: int = max_hp
	max_hp = GameState.player_max_hp
	hp += (max_hp - old_max)
	hp_bar.max_value = max_hp
	hp_bar.value = hp
