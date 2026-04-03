extends Area2D

var speed: float = 80.0
var health: float = 30.0
var base_node: Node2D = null
var main_node: Node = null
var currency_value: int = 5

func _ready():
	add_to_group("enemies")
	_draw_enemy()

func _draw_enemy():
	var poly = $Visual
	var points = PackedVector2Array()
	for i in 6:
		var angle = deg_to_rad(60 * i)
		points.append(Vector2(cos(angle), sin(angle)) * 15)
	poly.polygon = points
	poly.color = Color(1.0, 0.2, 0.2)

func _process(delta):
	if base_node == null:
		return
	var dir = global_position.direction_to(base_node.global_position)
	global_position += dir * speed * delta

func take_damage(amount: float):
	health -= amount
	if health <= 0:
		_die()

func _die():
	if main_node != null:
		main_node.add_currency(currency_value)
	queue_free()

func setup(base: Node2D, main: Node):
	base_node = base
	main_node = main
