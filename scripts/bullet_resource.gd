extends Resource
class_name BulletResource

export var bullet: PackedScene
# ---------------------------------------------------------------------------- #
export (float, 0.0, 30.0, 0.01) var max_speed: = 1.0
export var acceleration: float = 0.75
export var knockback_power: int = 30
export var lifetime: int = 0
export var damage: int= 1


export (float, 0.0, 0.5, 0.05) var bullet_scale_modifier
export (float, 0.0, 0.5, 0.05) var bullet_speed_modifier
