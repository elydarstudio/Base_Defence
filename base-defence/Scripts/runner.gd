extends Area2D

var speed: float = 160.0
var health: float = 4.0
var max_health: float = 4.0
var base_node: Node2D = null
var main_node: Node = null
var currency_value: int = 5

var attack_timer: float = 1.4
var attack_interval: float = 1.5
var attack_damage: float = 3.0
var attack_range: float = 35.0

func _ready():
	add_to_group("enemies")
	_draw_runner()

func _draw_runner():
	var poly = $Visual
	var points = PackedVector2Array()
	for i in 6:
		var angle = deg_to_rad(60 * i)
		points.append(Vector2(cos(angle), sin(angle)) * 10)
	poly.polygon = points
	poly.color = Color(0.9, 0.9, 0.0)

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
				base_node._update_combat_ui()
	queue_redraw()

func _draw():
	var bar_width: float = 20.0
	var bar_height: float = 3.0
	var offset: Vector2 = Vector2(-10, -20)
	var pct: float = health / max_health
	draw_rect(Rect2(offset, Vector2(bar_width, bar_height)), Color(0.2, 0.2, 0.2))
	var fill_color: Color
	if pct > 0.5:
		fill_color = Color(0.2, 0.9, 0.2)
	elif pct > 0.25:
		fill_color = Color(0.9, 0.9, 0.2)
	else:
		fill_color = Color(0.9, 0.2, 0.2)
	draw_rect(Rect2(offset, Vector2(bar_width * pct, bar_height)), fill_color)

func scale_to_wave(difficulty: int):
	var early = min(difficulty, 10)
	var late = max(0, difficulty - 10)
	var multiplier = 1.0 + (early * 0.08) + (late * 0.22) + (pow(max(0, difficulty - 5), 1.4) * 0.02)
	health = 4.0 * multiplier
	max_health = health
	attack_damage = 5.25 * (1.0 + (difficulty * 0.11))
	speed = min(144.0 + (difficulty * 2.2), 310.0)
	currency_value = 5 + ((main_node.phase - 1) * 3) if main_node != null else 5

func take_damage(amount: float, type: String = "normal"):
	health -= amount
	if main_node != null:
		main_node.spawn_damage_number(amount, global_position + Vector2(0, -20), type)
	if health <= 0:
		_die()

func _die():
	if main_node != null:
		main_node.add_currency(currency_value)
		main_node.spawn_damage_number(currency_value, global_position + Vector2(0, -35), "gold")
		main_node.on_enemy_killed()
	queue_free()

func setup(base: Node2D, main: Node):
	base_node = base
	main_node = main
