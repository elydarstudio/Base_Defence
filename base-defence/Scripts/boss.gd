extends Area2D

var speed: float = 50.0
var health: float = 250.0
var max_health: float = 250.0
var base_node: Node2D = null
var main_node: Node = null

var attack_timer: float = 1.4
var attack_interval: float = 2.0
var attack_damage: float = 18.0
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
	poly.color = Color(0.8, 0.0, 0.8)

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
				main_node.update_health_ui(base_node.health, base_node.shield)
	queue_redraw()

func _draw():
	var bar_width: float = 60.0
	var bar_height: float = 6.0
	var offset: Vector2 = Vector2(-30, -45)
	var pct: float = health / max_health

	# Background
	draw_rect(Rect2(offset, Vector2(bar_width, bar_height)), Color(0.2, 0.2, 0.2))

	# Fill
	var fill_color: Color
	if pct > 0.5:
		fill_color = Color(0.8, 0.0, 0.8)
	elif pct > 0.25:
		fill_color = Color(0.9, 0.5, 0.0)
	else:
		fill_color = Color(0.9, 0.1, 0.1)

	draw_rect(Rect2(offset, Vector2(bar_width * pct, bar_height)), fill_color)

	# HP text above bar
	draw_string(ThemeDB.fallback_font, Vector2(-25, -50), str(int(health)), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)

func scale_to_phase(p: int):
	var multiplier = 1.0 + (p * 0.3)
	health = 200.0 * multiplier
	max_health = health
	attack_damage = 22.0 * multiplier
	attack_interval = 1.5
	speed = min(50.0 + (p * 2.0), 110.0)
	
func take_damage(amount: float):
	health -= amount
	if health <= 0:
		_die()

func _die():
	if main_node != null:
		main_node.add_currency(100)
		main_node.on_boss_killed()
	queue_free()

func setup(base: Node2D, main: Node):
	base_node = base
	main_node = main
