extends Area2D

var direction: Vector2 = Vector2.ZERO
var speed: float = 400.0
var damage: float = 10.0
var lifetime: float = 2.0
var target: Node2D = null
var base: Node2D = null
var is_crit: bool = false
var is_rapidfire: bool = false

func _ready():
	area_entered.connect(_on_area_entered)

func setup(dir: Vector2, spd: float, dmg: float, tgt: Node2D, b: Node2D, crit: bool = false, rapidfire: bool = false):
	direction = dir
	speed = spd
	damage = dmg
	target = tgt
	base = b
	is_crit = crit
	is_rapidfire = rapidfire

	var poly = $Visual
	if is_crit:
		poly.polygon = PackedVector2Array([
			Vector2(-4, -4), Vector2(4, -4),
			Vector2(4, 4), Vector2(-4, 4)
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
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0:
		_resolve()
		queue_free()

func _on_area_entered(area):
	if area == target:
		# Damage type: rapidfire crit gets its own label, otherwise normal crit/normal rules apply
		var type = "crit" if is_crit else "normal"
		area.take_damage(damage, type)
		_resolve()
		queue_free()

func _resolve():
	if is_instance_valid(base) and is_instance_valid(target):
		base.notify_bullet_resolved(target)
