extends Sprite

onready var tween: = $Tween as Tween

#func _physics_process(delta):
#	global_position = get_global_mouse_position()

func hit():
	tween.interpolate_property(	self, "modulate", Color.red, Color.white, .5, 
								Tween.TRANS_QUART, Tween.EASE_OUT)
	tween.start()

func _on_area_shape_entered(area_id, area, area_shape, local_shape):
	hit()
#	area.all_bullets[area_shape].set_physics_process(false)
	area.reallocate_bullet(area_shape)
