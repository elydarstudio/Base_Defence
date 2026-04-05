extends Area2D

@export var fire_rate: float = 1.0
@export var bullet_speed: float = 400.0
@export var bullet_damage: float = 10.0
@export var detection_radius: float = 400.0

# Crit
var crit_chance: float = 0.0
var crit_damage: float = 1.5
var damage_multiplier: float = 1.0

# Defense
var damage_reduction: float = 0.0
var knockback_freq: float = 999.0
var knockback_strength: float = 0.0
var knockback_timer: float = 0.0

# Health
var max_health: float = 100.0
var health: float = 100.0
var hp_regen: float = 0.0
var regen_interval: float = 5.0
var hp_regen_timer: float = 0.0
var recovery_delay: float = 3.0
var recovery_timer: float = 0.0
var taking_damage: bool = false
var heal_multiplier: float = 1.0

# Shield
var max_shield: float = 0.0
var shield: float = 0.0
var shield_regen: float = 0.0
var shield_regen_timer: float = 0.0

var fire_timer: float = 0.0
var bullet_scene: PackedScene
var main_node: Node = null
var bullets_targeting: Dictionary = {}

func _ready():
	position = Vector2(360, 500)
	_draw_base()

func _draw_base():
	var poly = $Visual
	var points = PackedVector2Array()
	for i in 6:
		var angle = deg_to_rad(60 * i - 30)
		points.append(Vector2(cos(angle), sin(angle)) * 30)
	poly.polygon = points
	poly.color = Color(0.2, 0.6, 1.0)

func _process(delta):
	fire_timer += delta
	if fire_timer >= 1.0 / fire_rate:
		fire_timer = 0.0
		_try_shoot()

	# Recovery delay
	if taking_damage:
		recovery_timer += delta
		if recovery_timer >= recovery_delay:
			taking_damage = false
			recovery_timer = 0.0

	# HP regen
	if not taking_damage and hp_regen > 0 and health < max_health:
		hp_regen_timer += delta
		if hp_regen_timer >= regen_interval:
			hp_regen_timer = 0.0
			var heal_amount = hp_regen * heal_multiplier
			health = min(health + heal_amount, max_health)
			if main_node != null:
				main_node.update_health_ui(health, shield)

	# Shield regen
	if shield_regen > 0 and shield < max_shield:
		shield_regen_timer += delta
		if shield_regen_timer >= 1.0:
			shield_regen_timer = 0.0
			shield = min(shield + shield_regen, max_shield)
			if main_node != null:
				main_node.update_health_ui(health, shield)

	# Knockback
	if knockback_strength > 0:
		knockback_timer += delta
		if knockback_timer >= knockback_freq:
			knockback_timer = 0.0
			_do_knockback()

func _do_knockback():
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		var dist = global_position.distance_to(e.global_position)
		if dist < 200.0:
			var dir = global_position.direction_to(e.global_position)
			e.global_position += dir * knockback_strength

func _try_shoot():
	var target = _get_best_target()
	if target == null or bullet_scene == null:
		return
	var bullets_en_route = bullets_targeting.get(target, 0)
	var hits_needed = ceil(target.health / (bullet_damage * damage_multiplier))
	if bullets_en_route >= hits_needed:
		return
	var b = bullet_scene.instantiate()
	get_parent().add_child(b)
	b.global_position = global_position
	# Calculate crit
	var is_crit = randf() < crit_chance
	var final_damage = bullet_damage * damage_multiplier
	if is_crit:
		final_damage *= crit_damage
	b.setup(
		global_position.direction_to(target.global_position),
		bullet_speed,
		final_damage,
		target,
		self,
		is_crit
	)
	bullets_targeting[target] = bullets_en_route + 1

func notify_bullet_resolved(target: Node2D):
	if target in bullets_targeting:
		bullets_targeting[target] -= 1
		if bullets_targeting[target] <= 0:
			bullets_targeting.erase(target)

func _get_best_target() -> Node2D:
	for existing_target in bullets_targeting.keys():
		if not is_instance_valid(existing_target):
			bullets_targeting.erase(existing_target)
			continue
		var hits_needed = ceil(existing_target.health / (bullet_damage * damage_multiplier))
		var en_route = bullets_targeting.get(existing_target, 0)
		if en_route < hits_needed:
			return existing_target
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest = null
	var closest_dist = detection_radius
	for e in enemies:
		var d = global_position.distance_to(e.global_position)
		if d < closest_dist:
			closest_dist = d
			closest = e
	return closest

func take_damage(amount: float):
	taking_damage = true
	recovery_timer = 0.0
	hp_regen_timer = 0.0
	var reduced = amount * (1.0 - damage_reduction)
	if shield > 0:
		var absorbed = min(shield, reduced)
		shield -= absorbed
		reduced -= absorbed
		print("shield AFTER subtraction: ", shield)
		print("take_damage: amount=", amount, " shield=", shield, " reduction=", damage_reduction)
		print("damage_reduction value: ", damage_reduction)
	if reduced > 0:
		health -= reduced
	if main_node != null:
		main_node.update_health_ui(health, shield)
	if health <= 0:
		if main_node != null:
			main_node.trigger_game_over()

func add_shield(amount: float):
	max_shield += amount
	shield += amount
	if main_node != null:
		main_node.update_health_ui(health, shield)

func increase_max_health(amount: float):
	max_health += amount
	health += amount
	if main_node != null:
		main_node.update_health_ui(health, shield)

func set_bullet_scene(scene: PackedScene):
	bullet_scene = scene

func set_main(main: Node):
	main_node = main
