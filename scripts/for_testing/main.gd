extends Node2D

onready var bullet_spawner: = $bullet_spawner as RadialBulletSpawner
onready var target: = $target as Sprite

func _ready():
	bullet_spawner.target = target

func _input(event):
	if event.is_action_pressed("LEFT_CLICK"):
		$AnimationPlayer.stop(true)
		yield(get_tree().create_timer(10.0), "timeout")
		$AnimationPlayer.play("demo")
	if event.is_action_pressed("ui_cancel"):
		$AnimationPlayer.stop(true)
