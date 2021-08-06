extends BulletSpawner
class_name RadialBulletSpawner

enum CircleState {CIRCUMFERENCE, ARC}
enum SpawnMode {RADIAL, LINE, MULTI_LINE}
enum AimMode {NONE, TARGET}
enum LineMode {CENTERED, END}
enum RandBulletAngleMode {OFF=1, ZERO_TO_SIGN=0, FULL_RANGE=-1}
"""
	ZeroToSign: bullet_angle to 0 (i.e. range(-179.9, 0))
	FullRange: bullet_angle to -bullet_angle
"""

# ---------------------------------------------------------------------------- #
export (SpawnMode) var spawn_mode setget set_spawn_mode
export (AimMode) var aim_mode setget set_aim_mode
export (LineMode) var line_mode setget set_line_mode
export var rand_spawn_points: bool
export var line_point_count: = 2 setget set_line_point_count
export var radius: int = 64 setget set_radius
export var line_length: int = 64 setget set_line_length
export (float, EASE) var point_curve: = 1.0 setget set_point_curve

export (float, 0, 360, 0.1) var arc_width_degrees = 110 setget set_arc_width_degrees
export (float, -360, 360, 0.1) var arc_rotation_degrees = 0 setget set_arc_rotation_degrees

export var offset: int setget set_offset
export (float, -360.0, 360.0, 0.1) var offset_rotation setget set_offset_rotation

export (float, -179.9, 179.9, 0.1) var bullet_angle: = 0.0 setget set_bullet_angle
export (float, 0, 360.0, 0.1) var line_angle: = 0.0 setget set_line_angle
export (RandBulletAngleMode) var rand_bullet_angle_mode: = RandBulletAngleMode.OFF \
													 setget set_rand_bullet_angle_mode
export var global_bullet_angle: bool setget set_global_bullet_angle
export var remove_dupes: = false setget set_remove_dupes

# ---------------------------------------------------------------------------- #
var circle_state: int
var line_midpoints: = []
var arc_offset: = Vector2.ZERO setget set_arc_offset

var cached_bullet_angle: float
var rand_bullet_angle_oneshot: bool


# ---------------------------------------------------------------------------- #
func _setup():
	# call setters to update at ready
	._setup()
	self.point_count = point_count
	self.spawn_mode = spawn_mode
	self.line_mode = line_mode
	self.line_point_count = line_point_count
	self.arc_width_degrees = arc_width_degrees
	self.arc_rotation_degrees = arc_rotation_degrees
	self.line_length = line_length

func _draw():
	if !VISUAL:
		return
	var adjusted_radian: float = deg2rad(arc_rotation_degrees / 2)
	var arc_width_radians = deg2rad(arc_width_degrees / 2)
	draw_arc(arc_offset, radius, arc_width_radians + adjusted_radian, \
			-arc_width_radians + adjusted_radian, 32, Color.aquamarine, 3)
	calculate_bullet_spawn_points()
	draw_circle(Vector2(offset, 0), 4, Color.blue)
	draw_circle(Vector2.ZERO, 4, Color.green)
	
	if global_bullet_angle:
		if rand_bullet_angle_mode != RandBulletAngleMode.OFF:
			randomize_bullet_angle()
	match spawn_mode:
		SpawnMode.RADIAL:
			for point in spawn_points:
				var dir: Vector2 = calculate_bullet_direction(point)
				draw_line(point, 8 * dir + point, Color.white, 3)
				draw_circle(point, 4, Color.red)
		SpawnMode.LINE:
			if !line_length:
				return
			draw_line(spawn_points[0], spawn_points.back(), Color.blueviolet, 3)
			var dir: = calculate_bullet_direction(line_midpoints[0])
			if !dir:
				dir = Vector2.RIGHT
			for point in spawn_points:
				draw_line(point, 12 * dir + point, Color.white, 3)
				draw_circle(point, 4, Color.red)
			for point in line_midpoints:
				draw_circle(point, 4, Color.bisque)
				
		SpawnMode.MULTI_LINE:
			if !line_length:
				return
			var idx: = 0
			var i: int; var p: int
			for point in line_midpoints:
				var end_point: = (i + 1) * line_point_count - 1
				var direction: Vector2 = calculate_bullet_direction(point)
				if end_point >= spawn_points.size():
					# When changing
					break
				draw_line(spawn_points[idx], spawn_points[end_point], Color.blueviolet, 3)
				draw_circle(point, 4, Color.bisque)
				i += 1
				idx = end_point + 1
				for n in line_point_count:
					var pos: Vector2 = spawn_points[p]
					draw_line(pos, 8 * direction + pos, Color.white, 3)
					draw_circle(pos, 2, Color.red)
					p += 1


# ---------------------------------------------------------------------------- #
func spawn_bullet():
	if update_spawn_points:
		calculate_bullet_spawn_points()
	var spawn_offset: Vector2 = global_position.direction_to((arc_offset + global_position) * offset) \
								if offset \
								else Vector2.ZERO
	var global_dir: = get_global_direction()
	var p: = []; var dupes: = []
	var n: = 0; var idx: = 0			# MultiLine midpoint idx and counter
	for pos in spawn_points:
		if pool.empty():	break
		if remove_dupes:
			var skip: = p.has(pos)
			p.append(pos)
			if skip:
				dupes.append(p)
				continue
		var bullet: Bullet = pool.pop_front()
		
		var dir: Vector2
		if global_dir:
			dir = global_dir
		else:
			match spawn_mode:
				SpawnMode.RADIAL:
					dir = calculate_bullet_direction(pos)
				SpawnMode.MULTI_LINE:
					dir = calculate_bullet_direction(line_midpoints[idx])
					n += 1
					if n == line_point_count:
						n = 0
						idx += 1
		pos -= spawn_offset
		if local_bullets:
			bullet.is_local = true
			bullet.max_speed = 0
			local_pool.append(bullet)
		bullet.init(pos, dir)
	.spawn_bullet()

func release_local_bullets(speed: = bullet_res.max_speed):
	var global_dir: Vector2
	if global_bullet_angle:
		global_dir = calculate_bullet_direction(Vector2.ZERO)
	var n: = 0; var idx: = 0			# MultiLine midpoint idx and counter
	var line_dir: Vector2
	for bullet in local_pool:
		bullet.max_speed = speed
		var dir: Vector2
		if global_dir:
			dir = global_dir
		else:
			match spawn_mode:
				SpawnMode.RADIAL:
					dir = calculate_bullet_direction(bullet.position)
				SpawnMode.LINE, SpawnMode.MULTI_LINE:
					if !n:
						var next_bullet: Bullet = local_pool[idx * line_point_count + 1]
						if next_bullet:
							var local_dir: Vector2 = (bullet.position - next_bullet.position).normalized()
							line_dir = calculate_bullet_direction(bullet.position - (line_length * 0.5 * local_dir))
					dir = line_dir
					n += 1
					if n == line_point_count:
						n = 0
						idx += 1
		bullet.dir = dir
		bullet.is_local = false
		if bullet_res.lifetime != 0:
			bullet.lifetime = bullet_res.lifetime
			bullet.start_lifetime_timer()
	local_pool.clear()


# ---------------------------------------------------------------------------- #
func calculate_bullet_spawn_points():
	spawn_points.clear()
	line_midpoints.clear()
	
	var angle_step: float
	match spawn_mode:
		SpawnMode.RADIAL:
			if rand_spawn_points:
				randomize_arc_points()
			else:
				calculate_points_on_arc()
#
		SpawnMode.LINE:
			var midpoint: = calculate_point_on_circle(0)
			calculate_points_on_line(0)
			line_midpoints.append(midpoint)
		
		SpawnMode.MULTI_LINE:
			var _pc = point_count - 1 if circle_state == CircleState.ARC else point_count
			angle_step = arc_width_degrees / _pc
			var start_angle: float = -(arc_width_degrees / 2.0)
			for n in point_count:
				var angle: float = angle_step * n if point_count != 1 else angle_step
				var radians: = deg2rad(start_angle + angle)
				var midpoint: = calculate_point_on_circle(radians)
				calculate_points_on_line(radians)
				line_midpoints.append(midpoint)
	update_spawn_points = false

func calculate_points_on_arc():
	var angle_step: = 0.0
	if point_count > 1:
		var p = point_count - 1 if circle_state == CircleState.ARC else point_count
		angle_step = arc_width_degrees / p
	else:
		angle_step = arc_width_degrees / 2
	var start_angle: float = -(arc_width_degrees / 2.0)
	for n in point_count:
		var angle: float = angle_step * n if point_count > 1 else angle_step
		var radians: = deg2rad(start_angle + angle)
		var point: Vector2 = calculate_point_on_circle(radians)
		spawn_points.append(point)

func randomize_arc_points():
	var p: = point_count - 1 if point_count > 1 else point_count
	var angle_step: float = arc_width_degrees / p
	var start_angle: float = -(arc_width_degrees / 2.0)
	for n in point_count:
		var angle: = rand_range(0.0, float(point_count - 1)) \
					if point_count > 1 \
					else rand_range(0.0, float(point_count)) 
		angle *= angle_step
		var radians: = deg2rad(start_angle + angle)
		var point: Vector2 = calculate_point_on_circle(radians)
		spawn_points.append(point)

func calculate_bullet_direction(point: Vector2) -> Vector2:
	var spawn_dir: Vector2
	var relative_direction: = arc_offset.direction_to(point)
	if rand_bullet_angle_mode != RandBulletAngleMode.OFF && !global_bullet_angle:
		randomize_bullet_angle()
	match aim_mode:
		AimMode.NONE:
			match spawn_mode:
				SpawnMode.LINE:
					if global_bullet_angle:			# follows bullet angle
						var radians: = deg2rad(bullet_angle + 90)
						relative_direction = Vector2(sin(radians), cos(radians))
						spawn_dir = relative_direction
					else:							# follows line angle
						spawn_dir = arc_offset.direction_to(point)
						var radians: = deg2rad(line_angle + bullet_angle)
						spawn_dir = spawn_dir.rotated(radians)
				
				SpawnMode.MULTI_LINE:
					if global_bullet_angle:			# follows bullet angle
						var radians: = deg2rad(bullet_angle + 90)
						spawn_dir = Vector2(sin(radians), cos(radians))
					else:							# follows line angle
						spawn_dir = arc_offset.direction_to(point)
						var radians: = deg2rad(line_angle + bullet_angle)
						spawn_dir = spawn_dir.rotated(radians)
			
				SpawnMode.RADIAL:
					if global_bullet_angle:
						var radians: = deg2rad(bullet_angle + 90)
						relative_direction = Vector2(sin(radians), cos(radians))
					else:
						relative_direction +=  Vector2.ZERO \
											if !bullet_angle \
											else calculate_bullet_angle_adjustment(point)
						relative_direction = relative_direction.normalized()
					spawn_dir = relative_direction
		
		AimMode.TARGET:
			spawn_dir = (point + global_position).direction_to(target.global_position)
	return spawn_dir

func calculate_bullet_angle_adjustment(point: Vector2) -> Vector2:
	var added_angle: = deg2rad(bullet_angle)
	var adjusted_direction: Vector2
	adjusted_direction = (point - arc_offset).rotated(added_angle).normalized()
	return adjusted_direction

func calculate_point_on_circle(angle_radians: float) -> Vector2:
	var adjusted_rotation: = deg2rad(arc_rotation_degrees / 2)
	return Vector2(	arc_offset.x + radius * cos(angle_radians + adjusted_rotation),
					arc_offset.y + radius * sin(angle_radians + adjusted_rotation))

func calculate_points_on_line(angle_radians: float):
	if !line_length:
		return
	var dist_step: = line_length / float(line_point_count - 1)
	var line_center: = calculate_point_on_circle(angle_radians)
	var use_curve: = (point_curve != 1.0)
	
	match line_mode:
		LineMode.CENTERED:
			var tangent: = line_center.tangent().normalized()
			tangent = calculate_line_angle_adjustments(line_center, tangent)
			var pos: = line_center - (line_length / 2.0 * tangent)
			if !rand_spawn_points:
				for n in line_point_count:
					var point: Vector2
					if !use_curve:
						point = ((dist_step * n) * tangent) + pos
					else:
						var e: = ease((n+1) / float(line_point_count), point_curve)
						point = e * line_length * tangent + pos
					point = point.round()
					spawn_points.append(point)
			else:
				randomize_line_points(pos, tangent)
		
		LineMode.END:
			var dir: = line_center.normalized()
			dir = calculate_line_angle_adjustments(line_center, dir)
			if !rand_spawn_points:
				for n in line_point_count:
					var point: Vector2
					if !use_curve:
						point = dir * (dist_step * n) + (line_center - line_length * dir)
					else:
						var e: = ease((n+1) / float(line_point_count), point_curve)
						point = ((1.0 - e) * line_length * dir) + (line_center - line_length * dir)
					point = point.round()
					spawn_points.append(point)
			else:
				randomize_line_points(line_center, dir)

func randomize_line_points(pos: Vector2, dir: Vector2):
	for n in line_point_count:
		randomize()
		var r: = randi() % (line_length + 1)
		var point: Vector2 = r * dir
		point += pos
		spawn_points.append(point)

func calculate_line_angle_adjustments(point: Vector2, dir: Vector2) -> Vector2:
	var angle: = line_angle if line_mode != LineMode.END else line_angle - 180
	if angle:
		dir = dir.rotated(deg2rad(angle))
	elif aim_mode == AimMode.TARGET && !global_bullet_angle:
		var radians: = (point + global_position).angle_to_point(target.global_position)
		radians += deg2rad(angle) if line_angle else 0.0
		dir = dir.rotated(radians)
	return dir

func randomize_bullet_angle():
	randomize()
	bullet_angle = rand_range(cached_bullet_angle, cached_bullet_angle * rand_bullet_angle_mode)

func calculate_offset():
	var rad: = deg2rad(offset_rotation / 2.0)
	var center: = Vector2(cos(rad), sin(rad)) * offset
	arc_offset = center

func get_global_direction() -> Vector2:
	match spawn_mode:
		SpawnMode.RADIAL, SpawnMode.MULTI_LINE:
			if global_bullet_angle:
				return calculate_bullet_direction(Vector2.ZERO)
		
		SpawnMode.LINE:
			return calculate_bullet_direction(line_midpoints[0])
		
	return Vector2.ZERO


# ---------------------------------------------------------------------------- #
func set_spawn_mode(value: int):
	spawn_mode = value
	if spawn_mode == SpawnMode.MULTI_LINE && point_count < 2:
		self.point_count = 2
	update_spawn_points = true

func set_aim_mode(value: int):
	aim_mode = value

func set_line_mode(value: int):
	line_mode = value
	update_spawn_points = true

func set_radius(value: int):
	radius = value
	update_spawn_points = true

func set_line_point_count(value: int):
	line_point_count = value
	if value < 2:
		push_warning("%s :: line point count cannot == 0, value defaulted to 1" % [name])
		line_point_count = 2
	update_spawn_points = true

func set_line_length(value: int):
	line_length = value
	update_spawn_points = true

func set_point_curve(value: float):
	point_curve = value
	update_spawn_points = true

func set_arc_width_degrees(value: float):
	arc_width_degrees = value
	circle_state = CircleState.CIRCUMFERENCE if arc_width_degrees > 359.9 else CircleState.ARC
	update_spawn_points = true

func set_arc_rotation_degrees(value: float):
	arc_rotation_degrees = value
	update_spawn_points = true

func set_offset(value: int):
	offset = value
	calculate_offset()
	update_spawn_points = true

func set_offset_rotation(value: float):
	offset_rotation = value
	calculate_offset()
	update_spawn_points = true

func set_arc_offset(value: Vector2):
	arc_offset = value
	update_spawn_points = true

func set_bullet_angle(value:float):
	bullet_angle = value
	cached_bullet_angle = value
	update_spawn_points = true		# only used for visualizing

func set_line_angle(value: float):
	line_angle = value
	update_spawn_points = true

func set_rand_bullet_angle_mode(value: int):
	rand_bullet_angle_mode = value
	if value == RandBulletAngleMode.OFF:
		self.bullet_angle = cached_bullet_angle
	update_spawn_points = true

func set_global_bullet_angle(value: bool):
	global_bullet_angle = value
	update_spawn_points = true		# not actually needed, only for testing

func set_remove_dupes(value: bool):
	remove_dupes = value
	update_spawn_points = true
