extends Area2D

var speed: float = 160.0
var health: float = 4.0
var max_health: float = 4.0
var base_node: Node2D = null
var main_node: Node = null
var currency_value: int = 5
var has_exploded: bool = false

var attack_damage: float = 3.0
var attack_range: float = 35.0

# ── Bleed ─────────────────────────────────────
var bleed_damage: float = 0.0
var bleed_ticks: int = 0
var bleed_ticks_remaining: int = 0
var bleed_timer: float = 0.0
const BLEED_INTERVAL: float = 0.5

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
		var separation = Vector2.ZERO
		for other in get_tree().get_nodes_in_group("enemies"):
			if other == self:
				continue
			var d = global_position.distance_to(other.global_position)
			if d < 15.0 and d > 0:
				separation += global_position.direction_to(other.global_position) * -1
		if separation.length() > 0:
			global_position += separation.normalized() * 0.5 * delta
	else:
		if not has_exploded:
			has_exploded = true
			base_node.take_damage(attack_damage)
			if main_node != null:
				base_node._update_combat_ui()
			_die()
 
	if bleed_ticks_remaining > 0:
		bleed_timer += delta
		if bleed_timer >= BLEED_INTERVAL:
			bleed_timer = 0.0
			bleed_ticks_remaining -= 1
			health -= bleed_damage
			if main_node != null:
				main_node.spawn_damage_number(bleed_damage, global_position + Vector2(-25, 0), "bleed")
			if health <= 0:
				_die()
 
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
	var very_late = max(0, difficulty - 30)
	var multiplier = 1.0 + (early * 0.08) + (late * 0.26) + (pow(max(0, difficulty - 5), 1.4) * 0.02) + (very_late * 0.4)
	health = 4.0 * multiplier
	max_health = health
	attack_damage = 80.0 * (1.0 + (difficulty * 0.15))
	speed = 230.0
	currency_value = 5 + ((main_node.phase - 1) * 3) if main_node != null else 5

func apply_bleed(damage: float, was_crit: bool):
	var crit_pct = 0.0
	if main_node != null:
		crit_pct = main_node.get_node("Base").crit_chance * 100.0
	if crit_pct <= 20.0:
		bleed_ticks = 2
	elif crit_pct <= 40.0:
		bleed_ticks = 3
	elif crit_pct <= 60.0:
		bleed_ticks = 4
	else:
		bleed_ticks = 5
 
	var first_tick = damage * 2.0 if was_crit else damage
	health -= first_tick
	if main_node != null:
		main_node.spawn_damage_number(first_tick, global_position + Vector2(-25, 0), "bleed")
	if health <= 0:
		_die()
 
	bleed_damage = damage
	bleed_ticks_remaining = bleed_ticks - 1
	bleed_timer = 0.0

func take_damage(amount: float, type: String = "normal"):
	health -= amount
	if main_node != null:
		main_node.spawn_damage_number(amount, global_position + Vector2(randf_range(-15, 15), -40), type)
	if health <= 0:
		_die()

func _die():
	if main_node != null:
		main_node.add_currency(currency_value, global_position)
		main_node.on_enemy_killed()
	queue_free()

func setup(base: Node2D, main: Node):
	base_node = base
	main_node = main
