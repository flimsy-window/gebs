extends Node2D

onready var bullet_spawner: = $bullet_spawner as RadialBulletSpawner
onready var target: = $target as Sprite

func _ready():
	bullet_spawner.target = target