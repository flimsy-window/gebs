extends Node2D
class_name BulletSpawner
"""
Base class for BulletSpawners; bullet pooling and helper functions
"""

# ---------------------------------------------------------------------------- #
export var VISUAL: bool = true

export var bullet_container: NodePath
export var bullet_res: Resource
export var local_bullets: bool setget set_local_bullets
export var pool_size: = 100
export var point_count: = 3 setget set_point_count
export var rotation_speed: = 0.0 setget set_rotation_speed

export (float, 0.0, 0.5, 0.05) var bullet_scale_modifier setget set_bullet_scale_modifier
export (float, 0.0, 0.5, 0.05) var bullet_speed_modifier setget set_bullet_speed_modifier

# ---------------------------------------------------------------------------- #
onready var viewport: Viewport

# ---------------------------------------------------------------------------- #
var active: = false setget set_active
var pool: Reference
var local_pool: = []
var spawn_points: = []
var update_spawn_points: = true
var update_speed_modifier: = false
var update_scale_modifier: = false


var target setget set_target


# ---------------------------------------------------------------------------- #
func _get_configuration_warning():
	var err: = ""
	if !bullet_res:
		err += "No bullet scene\n"
	return err

func _input(event):
	if event.is_action_pressed("LEFT_CLICK"):
		self.active = true
	elif event.is_action_pressed("MIDDLE_CLICK"):
		spawn_bullet()
	elif event.is_action_pressed("RIGHT_CLICK"):
		self.active = false

# ---------------------------------------------------------------------------- #
func _ready():
	_setup()
	pool = get_node(bullet_container).initialize_pool(bullet_res, pool_size)
	update()

func _setup():
	self.active = active


# ---------------------------------------------------------------------------- #
func _physics_process(delta):
	apply_rotation()
	handle_local_bullets()
	update()

func spawn_bullet():
	return

func handle_local_bullets():
	if update_spawn_points && local_bullets:
		calculate_bullet_spawn_points()
		var idx: = 0
		for bullet in local_pool:
			if idx > spawn_points.size() - 1:
				bullet.is_local = false
				bullet.reallocate()
			else:
				var pos: Vector2 = spawn_points[idx]
				bullet.position = pos + global_position
			idx += 1

func release_local_bullets(speed: = bullet_res.max_speed):
	for bullet in local_pool:
		bullet.max_speed = speed
		bullet.dir = calculate_bullet_direction(bullet.position)
		bullet.is_local = false
		if bullet_res.lifetime != 0:
			bullet.lifetime = bullet_res.lifetime
			bullet.start_lifetime_timer()
	local_pool.clear()


# ---------------------------------------------------------------------------- #
func calculate_bullet_spawn_points():
	pass

func calculate_bullet_direction(point: Vector2) -> Vector2:
	return Vector2.ZERO

func calculate_bullet_angle_adjustment(point: Vector2) -> Vector2:
	return Vector2.ZERO

func apply_rotation():
	if rotation_speed:
		self.arc_rotation_degrees += rotation_speed

func rand_modifier(modifier: float) -> float:
	randomize()
	return rand_range(-modifier, modifier)


# ---------------------------------------------------------------------------- #
func set_active(value: bool):
	active = value

func set_local_bullets(value: bool):
	if local_bullets && !value:
		release_local_bullets()
	local_bullets = value

func set_point_count(value: int):
	point_count = value
	if value <= 0:
		push_warning("%s :: point count cannot == 0, value defaulted to 1" % [name])
		point_count = 1
	update_spawn_points = true

func set_rotation_speed(value: float):
	rotation_speed = value

func set_bullet_scale_modifier(value: float):
	if bullet_scale_modifier != value:
		bullet_scale_modifier = value
		for bullet in pool.all_bullets:
			var scale_mod: = rand_modifier(bullet_scale_modifier) if bullet_scale_modifier else 0.0
			bullet.apply_scale_modifier(scale_mod)

func set_bullet_speed_modifier(value: float):
	if bullet_speed_modifier != value:
		bullet_speed_modifier = value
		for bullet in pool.all_bullets:
			var speed_mod: = rand_modifier(bullet_speed_modifier) if bullet_speed_modifier else 0.0
			bullet.apply_speed_modifier(speed_mod)

func set_target(value):
	target = value
	update_spawn_points = true

