extends Node2D

var radius: float = 0.0
var max_radius: float = 400.0
var expand_speed: float = 200.0
var damage: float = 10.0
var base_node: Node = null
var main_node: Node = null
var bleed_damage: float = 0.0
var is_rapidfire: bool = false
var is_crit: bool = false
var hit_enemies: Array = []

func setup(spd: float, dmg: float, max_rad: float, b: Node, mn: Node, crit: bool, rapidfire: bool, bleed: float):
	expand_speed = spd
	damage = dmg
	max_radius = max_rad
	base_node = b
	main_node = mn
	is_crit = crit
	is_rapidfire = rapidfire
	bleed_damage = bleed

func _process(delta):
	radius += expand_speed * delta
	_check_hits()
	queue_redraw()
	if radius >= max_radius:
		_dissolve()

func _check_hits():
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e in hit_enemies:
			continue
		if not is_instance_valid(e):
			continue
		var dist = global_position.distance_to(e.global_position)
		if dist <= radius:
			hit_enemies.append(e)
			var type = "crit" if is_crit else "normal"
			e.take_damage(damage, type)
			if bleed_damage > 0.0:
				e.apply_bleed(bleed_damage, is_crit)
			MechanicsManager.register_hit(e)

func _draw():
	# Pulse ring
	var alpha = 1.0 - (radius / max_radius)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 64, Color(0.2, 0.5, 1.0, alpha), 2.0)
	# Aura — permanent ring at max radius, very faint
	draw_arc(Vector2.ZERO, max_radius, 0, TAU, 64, Color(0.2, 0.5, 1.0, 0.08), 1.5)

func _dissolve():
	# Spawn particles at edge — visual polish placeholder for now
	queue_free()
