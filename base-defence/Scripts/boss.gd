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
var crit_chance: float = 0.0
var crit_multiplier: float = 2.0

# ── Bleed ─────────────────────────────────────
var bleed_damage: float = 0.0
var bleed_ticks: int = 0
var bleed_ticks_remaining: int = 0
var bleed_timer: float = 0.0
const BLEED_INTERVAL: float = 0.5

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
			var final_damage = attack_damage
			if randf() < crit_chance:
				final_damage *= crit_multiplier
			base_node.take_damage(final_damage)
			if main_node != null:
				base_node._update_combat_ui()
 
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
	var bar_width: float = 60.0
	var bar_height: float = 6.0
	var offset: Vector2 = Vector2(-30, -45)
	var pct: float = health / max_health
	draw_rect(Rect2(offset, Vector2(bar_width, bar_height)), Color(0.2, 0.2, 0.2))
	var fill_color: Color
	if pct > 0.5:
		fill_color = Color(0.8, 0.0, 0.8)
	elif pct > 0.25:
		fill_color = Color(0.9, 0.5, 0.0)
	else:
		fill_color = Color(0.9, 0.1, 0.1)
	draw_rect(Rect2(offset, Vector2(bar_width * pct, bar_height)), fill_color)
	draw_string(ThemeDB.fallback_font, Vector2(-25, -50), str(int(health)), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)

func scale_to_phase(p: int):
	var hp_mult = pow(5.0, p - 1)
	var dmg_mult = pow(4.6, p - 1)
	health = 400.0 * hp_mult
	max_health = health
	attack_damage = 22.0 * dmg_mult
	attack_interval = 1.5
	speed = min(50.0 + (p * 2.0), 110.0)
	crit_chance = 0.3
	crit_multiplier = 2.0

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
		main_node.add_currency(100 + ((main_node.phase - 1) * 20))
		var lp_drop = 10 + ((main_node.phase - 1) * 3)
		var lp_gain = main_node.lp_gain_level
		var lp_mult = main_node.legacy_mult_level
		var total_lp = int((lp_drop + lp_gain) * (1.0 + (lp_mult * 0.1)))
		main_node.run_lp += total_lp
		SaveManager.data["legacy_points"] += total_lp
		SaveManager.save_game()
		main_node.spawn_damage_number(total_lp, global_position + Vector2(0, -50), "lp")
		main_node.on_boss_killed()
		AudioManager.play(AudioManager.sfx_boss_death)
	queue_free()

func setup(base: Node2D, main: Node):
	base_node = base
	main_node = main
