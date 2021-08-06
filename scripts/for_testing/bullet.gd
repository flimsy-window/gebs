extends CollisionShape2D
class_name Bullet

signal _continue

export var align_sprite: bool

onready var sprite: = $Sprite as Sprite

var damage: int = 1
var max_speed: float
var acceleration: float
var knockback_power: int
var lifetime: float
var rotation_speed: int

# ---------------------------------------------------------------------------- #
var dir : Vector2
var velocity: Vector2

var active: bool setget set_active
var is_local: bool

var elapsed_time: float
var timer_active: bool
var _speed: float
var _scale: Vector2
var _yielded: bool

# ---------------------------------------------------------------------------- #
func _ready():
	self.active = false

func _physics_process(delta):
	velocity = max_speed * dir
	position += velocity
	if timer_active:
		elapsed_time += delta
		if elapsed_time > lifetime:
			elapsed_time = 0
			timer_active = false
			reallocate()


# ---------------------------------------------------------------------------- #
func init(pos: Vector2, direction: Vector2):
	self.active = true
	position = pos
	dir = direction
	timer_active = lifetime != 0
	if align_sprite:
		rotation = dir.angle()

func reallocate():
	self.active = false
	if _yielded:
		_yielded = false
		emit_signal("_continue")

func early_clear():
	# animation
	reallocate()

func start_lifetime_timer():
	timer_active = true


# ---------------------------------------------------------------------------- #
func set_active(value: bool):
	active = value
	visible = value
	set_deferred("disabled", !value)
	set_physics_process(active)

func apply_scale_modifier(scale_mod: float):
	if active:
		_yielded = true
		yield(self, "_continue")
	
	if !_scale:
		_scale = scale
	if scale_mod:
		scale = _scale + (_scale * scale_mod)
	else:
		scale = _scale
	# alternatively, change the Shape2D size directly

func apply_speed_modifier(speed_mod: float):
	if active:
		_yielded = true
		yield(self, "_continue")
	
	if!_speed:
		_speed = max_speed
	if speed_mod:
		max_speed = _speed + (_speed * speed_mod)
	else:
		max_speed = _speed

func _on_VisibilityNotifier2D_screen_exited():
	reallocate()

