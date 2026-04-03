extends Area2D

var speed: float = 50.0
var health: float = 300.0
var base_node: Node2D = null
var main_node: Node = null
var currency_value: int = 50

var attack_timer: float = 1.4
var attack_interval: float = 2.0
var attack_damage: float = 20.0
var attack_range: float = 45.0

func _ready():
	add_to_group("enemies")
	add_to_group("boss")
	_draw_boss()

func _draw_boss():
	var poly = $Visual
	var points = PackedVector2Array()
	for i in 8:
		var angle = deg_to_rad(45 * i)
		points.append(Vector2(cos(angle), sin(angle)) * 30)
	poly.polygon = points
	poly.color = Color(0.8, 0.0, 0.8)  # purple

func _process(delta):
	if base_node == null:
		return
	var dist = global_position.distance_to(base_node.global_position)
	if dist > attack_range:
		var dir = global_position.direction_to(base_node.global_position)
		global_position += dir * speed * delta
	else:
		attack_timer += delta
		if attack_timer >= attack_interval:
			attack_timer = 0.0
			base_node.take_damage(attack_damage)
			if main_node != null:
				main_node.update_health_ui(base_node.health)

func scale_to_phase(p: int):
	var multiplier = 1.0 + (p * 0.3)
	health = 150.0 * multiplier
	attack_damage = 12.0 * multiplier
	speed = min(40.0 + (p * 3.0), 100.0)
	currency_value = int(50.0 * multiplier)

func take_damage(amount: float):
	health -= amount
	if health <= 0:
		_die()

func _die():
	if main_node != null:
		main_node.add_currency(currency_value)
		main_node.on_boss_killed()
	queue_free()

func setup(base: Node2D, main: Node):
	base_node = base
	main_node = main
