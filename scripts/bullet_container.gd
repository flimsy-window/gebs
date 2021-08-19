extends Area2D
class_name BulletContainer
"""
	This class can be used as a singleton if all bullets in the game react with 
	the same objects.
	Using different bullet containers can allow bullets to be grouped together 
	based on collision.
"""

var pools: = {}
var all_bullets: = []

# ---------------------------------------------------------------------------- #
func initialize_pool(bullet_res: Resource, pool_size: int) -> BulletPool:
	print("initialize pool: ", float(OS.get_ticks_msec()) / 1000.0)
	var _complete: bool
	var pool: = BulletPool.new()
	var pool_id: = pools.size()
	pools[pool_id] = pool
	
	while !_complete:
		var n: = 0
		for i in pool_size:
			var bullet: Bullet = bullet_res.bullet.instance()
			setup_bullet(bullet, bullet_res)
			bullet.pool_id = pool_id
			bullet.connect("reallocate", self, "reallocate_bullet", [i])
			pool.all_bullets.append(bullet)
			all_bullets.append(bullet)
			pool.pool.append(bullet)
			add_child(bullet)
			n += 1
			if n == 1000:
				n = 0
				yield(get_tree(), "idle_frame")
		_complete = true
	
	print("bullets added to scene %s: %s" % [self, float(OS.get_ticks_msec()) / 1000.0])
	return pool

func setup_bullet(bullet: Bullet, bullet_res: Resource):
	bullet.max_speed = bullet_res.max_speed
	bullet.acceleration = bullet_res.acceleration
	bullet.knockback_power = bullet_res.knockback_power
	bullet.lifetime = bullet_res.lifetime
	
	bullet.position = Vector2.ZERO
	bullet.visible = false

func reallocate_bullet(shape_id: int):
	var bullet: Bullet = all_bullets[shape_id]
	var pool: BulletPool = pools[bullet.pool_id]
	bullet.reallocate()
	if !bullet.is_local:
		pool.pool.push_back(bullet)


# ---------------------------------------------------------------------------- #
class BulletPool:
	var all_bullets: = []
	var pool: = []
	
