extends Sprite

#func _ready():
#	get_parent().target = self

func _physics_process(delta):
	global_position = get_global_mouse_position()

func hit():
	pass

func _on_area_shape_entered(area_id, area, area_shape, local_shape):
	hit()
	area.reallocate_bullet(area_shape)
