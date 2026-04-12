extends Area2D

var speed: float = 80.0
var health: float = 8.0
var max_health: float = 8.0
var base_node: Node2D = null
var main_node: Node = null
var currency_value: int = 5
var separation_radius: float = 20.0

var attack_timer: float = 1.4
var attack_interval: float = 1.5
var attack_damage: float = 4.0
var attack_range: float = 35.0

# ── Bleed state ───────────────────────────────
var bleed_damage: float = 0.0
var bleed_ticks: int = 0
var bleed_ticks_remaining: int = 0
var bleed_timer: float = 0.0

# ── Chill state ───────────────────────────────
var is_chilled: bool = false

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
	EnemyMechanics.tick(self, delta)

func _draw():
	EnemyMechanics.draw_health_bar(self, 30.0, 4.0, Vector2(-15, -25))

func scale_to_wave(difficulty: int):
	var early = min(difficulty, 10)
	var late = max(0, difficulty - 10)
	var very_late = max(0, difficulty - 30)
	var multiplier = 1.0 + (early * 0.08) + (late * 0.26) + (pow(max(0, difficulty - 5), 1.4) * 0.02) + (very_late * 0.4)
	health = 8.0 * multiplier
	max_health = health
	var phase_scale = 1.0 if main_node == null or main_node.phase <= 1 else 0.85
	attack_damage = 7.0 * (1.0 + (difficulty * 0.13)) * phase_scale
	speed = 72.0
	currency_value = 5 + (main_node.phase * 3) if main_node != null else 5

func take_damage(amount: float, type: String = "normal"):
	EnemyMechanics.take_damage(self, amount, type)

func apply_bleed(damage: float, was_crit: bool):
	EnemyMechanics.apply_bleed(self, damage, was_crit)

func apply_chill():
	EnemyMechanics.apply_chill(self)

func _die():
	MechanicsManager.cleanup_focus(self)
	if main_node != null:
		MechanicsManager.trigger_rampart(main_node.get_node("Base"))
		MechanicsManager.trigger_vitality(main_node.get_node("Base"))
		var base_gold = 5 + ((main_node.phase - 1) * 3)
		main_node.add_currency(base_gold, global_position)
		main_node.on_enemy_killed()
	queue_free()

func setup(base: Node2D, main: Node):
	base_node = base
	main_node = main
