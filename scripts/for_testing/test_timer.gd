extends Timer


func _input(event):
	if event.is_action_pressed("RIGHT_CLICK"):
		if is_stopped():
			start()
		else:
			stop()


func _timeout():
	pass
#	start()
