extends Area2D

var direction: Vector2 = Vector2.ZERO
var speed: float = 400.0
var damage: float = 10.0
var lifetime: float = 2.0
var target: Node2D = null
var base: Node2D = null
var is_crit: bool = false
var is_rapidfire: bool = false
var bleed_damage: float = 0.0
var is_keystone: bool = false
var is_chain: bool = false
var main_node: Node = null
var _distance_traveled: float = 0.0

func _ready():
	area_entered.connect(_on_area_entered)

func setup(dir: Vector2, spd: float, dmg: float, tgt: Node2D, b: Node2D, crit: bool = false, rapidfire: bool = false, bleed: float = 0.0, keystone: bool = false, mn: Node = null):
	direction = dir
	speed = spd
	damage = dmg
	target = tgt
	base = b
	is_crit = crit
	is_rapidfire = rapidfire
	bleed_damage = bleed
	is_keystone = keystone
	main_node = mn

	var poly = $Visual
	if is_keystone:
		# Railgun — thin rectangle oriented to travel direction
		poly.polygon = PackedVector2Array([
			Vector2(-10, -1.5), Vector2(10, -1.5),
			Vector2(10, 1.5), Vector2(-10, 1.5)
		])
		
		poly.color = Color(0.6, 0.95, 1.0)
	elif is_crit:
		poly.polygon = PackedVector2Array([
			Vector2(-6, -1.5), Vector2(6, -1.5),
			Vector2(6, 1.5), Vector2(-6, 1.5)
		])
		poly.color = Color(1.0, 0.4, 0.0)
	elif is_rapidfire:
		poly.polygon = PackedVector2Array([
			Vector2(-6, -6), Vector2(6, -6),
			Vector2(6, 6), Vector2(-6, 6)
		])
		poly.color = Color(0.1, 0.2, 0.9)
	else:
		poly.polygon = PackedVector2Array([
			Vector2(-4, -4), Vector2(4, -4),
			Vector2(4, 4), Vector2(-4, 4)
		])
		poly.color = Color(1.0, 0.9, 0.2)

func _process(delta):
	if is_instance_valid(target):
		direction = global_position.direction_to(target.global_position)
		# Chain hops arrive on proximity, not collision
		if is_chain and global_position.distance_to(target.global_position) < 12.0:
			_on_chain_arrived()
			return
	position += direction * speed * delta
	_distance_traveled += speed * delta
	# Rotate visual to face travel direction for keystone/chain
	if is_keystone or is_chain:
		$Visual.rotation = direction.angle()
	lifetime -= delta
	if lifetime <= 0:
		_resolve()
		queue_free()

func _on_area_entered(area):
	if area == target:
		if area.health <= 0:
			_resolve()
			queue_free()
			return
		var momentum_bonus = MechanicsManager.get_momentum_bonus(_distance_traveled)
		var final_damage = damage * (1.0 + momentum_bonus)
		var type = "crit" if is_crit else "normal"
		area.take_damage(final_damage, type)
		if bleed_damage > 0.0:
			area.apply_bleed(bleed_damage, is_crit)
		# Trigger chain if barrage keystone active
		if is_keystone and main_node != null:
			MechanicsManager.trigger_chain(area, final_damage, main_node, load("res://Scenes/projectile.tscn"))
		_resolve()
		queue_free()

func setup_chain(dir: Vector2, spd: float, dmg: float, tgt: Node2D, mn: Node):
	direction = dir
	speed = spd
	damage = dmg
	target = tgt
	main_node = mn
	is_chain = true
	lifetime = 2.0
	# Chain hop visual — same style as railgun, slightly smaller
	var poly = $Visual
	poly.polygon = PackedVector2Array([
		Vector2(-4, -1), Vector2(4, -1),
		Vector2(4, 1), Vector2(-4, 1)
	])
	poly.color = Color(0.6, 0.95, 1.0)

func _on_chain_arrived():
	# Called when chain projectile reaches its target
	if is_instance_valid(target) and target.health > 0:
		target.take_damage(damage, "normal")
	queue_free()

func _resolve():
	if is_instance_valid(base) and is_instance_valid(target):
		base.notify_bullet_resolved(target)
