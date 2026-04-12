extends Area2D

var pulse_scene: PackedScene

@export var fire_rate: float = 1.0
@export var bullet_speed: float = 400.0
@export var bullet_damage: float = 10.0
@export var detection_radius: float = 400.0

# Crit
var crit_chance: float = 0.0
var crit_damage: float = 1.5
var damage_multiplier: float = 1.0

# Health
var max_health: float = 100.0
var health: float = 100.0
var hp_regen: float = 1.0
var hp_regen_timer: float = 0.0
var regen_interval: float = 5.0
var hp_multiplier: float = 1.0
var heal_multiplier: float = 1.0

# Shield
var max_shield: float = 0.0
var shield: float = 0.0
var shield_regen_interval: float = 5.0
var shield_regen_timer: float = 0.0
var shield_strength: float = 0.5
var shield_multiplier: float = 1.0
var evasion: float = 0.0
var pulse_boss_charge: float = 0.0

# Zap
var zap_timer: float = 0.0
var zap_target: Node2D = null
var current_bullet_target: Node2D = null

var fire_timer: float = 0.0
var bullet_scene: PackedScene
var main_node: Node = null
var bullets_targeting: Dictionary = {}

# ── Attack counter ────────────────────────────
var _attack_counter: int = 0

func _ready():
	position = Vector2(360, 640)
	_draw_base()
	_update_combat_ui()

func _draw_base():
	var poly = $Visual
	var points = PackedVector2Array()
	for i in 6:
		var angle = deg_to_rad(60 * i - 30)
		points.append(Vector2(cos(angle), sin(angle)) * 30)
	poly.polygon = points
	poly.color = Color(0.2, 0.6, 1.0)

func _update_combat_ui():
	$HPLabel.text = "HP: " + str(max(0, int(health))) + "/" + str(int(get_effective_max_hp()))
	$ShieldLabel.text = "SH: " + str(int(shield))

func _process(delta):
	fire_timer += delta
	var fire_interval: float
	if SkillManager.get_active_keystone() == SkillManager.TREE_BULWARK:
		var level = main_node.attack_speed_level if main_node != null else 0
		fire_interval = max(1.0, 5.0 - (pow(level, 0.6) / pow(100.0, 0.6)) * 4.0)
	else:
		fire_interval = 1.0 / fire_rate
	if fire_timer >= fire_interval:
		fire_timer = 0.0
		_try_shoot()

	# HP regen
	hp_regen_timer += delta
	if hp_regen_timer >= regen_interval:
		hp_regen_timer = 0.0
		MechanicsManager.set_vampiric_proc()
		MechanicsManager.trigger_chill(self)
		if hp_regen > 0 and health < get_effective_max_hp():
			var heal_amount = hp_regen * heal_multiplier
			health = min(health + heal_amount, get_effective_max_hp())
			if main_node != null:
				_update_combat_ui()

	# Shield regen
	var effective_max_shield = max_shield * shield_multiplier
	if effective_max_shield > 0 and shield < effective_max_shield:
		shield_regen_timer += delta
		if shield_regen_timer >= shield_regen_interval:
			shield_regen_timer = 0.0
			var regen_amount = effective_max_shield * 0.10
			shield = min(shield + regen_amount, effective_max_shield)
			if main_node != null:
				_update_combat_ui()

	# Zap
	if SkillManager.is_skill_unlocked(SkillManager.TREE_BULWARK, 2):
		if not is_instance_valid(zap_target) or zap_target == current_bullet_target:
			zap_target = _get_closest_enemy(current_bullet_target)
		if not is_instance_valid(current_bullet_target):
			current_bullet_target = null
		zap_timer += delta
		if zap_timer >= shield_regen_interval:
			zap_timer = 0.0
			if is_instance_valid(zap_target):
				MechanicsManager.trigger_zap(main_node, self, zap_target)
			zap_target = _get_closest_enemy(current_bullet_target)

func get_effective_max_hp() -> float:
	return max_health * hp_multiplier

func _get_bleed_tick_count() -> int:
	var crit_pct = crit_chance * 100.0
	if crit_pct <= 20.0:
		return 2
	elif crit_pct <= 40.0:
		return 3
	elif crit_pct <= 60.0:
		return 4
	else:
		return 5

func _tick_attack_counter() -> bool:
	_attack_counter += 1
	if _attack_counter >= 3:
		_attack_counter = 0
		return true
	return false

func _get_closest_enemy(exclude: Node2D = null) -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest = null
	var closest_dist = INF
	for e in enemies:
		if is_instance_valid(exclude) and e == exclude:
			continue
		var d = global_position.distance_to(e.global_position)
		if d < closest_dist:
			closest_dist = d
			closest = e
	return closest

func _get_committed_damage(target: Node) -> float:
	var bleed = SkillManager.barrage_bleed_dot()
	var total_bleed = bleed * _get_bleed_tick_count()

	var zap_committed = 0.0
	if SkillManager.is_skill_unlocked(SkillManager.TREE_BULWARK, 2):
		if is_instance_valid(zap_target) and zap_target == target:
			zap_committed = shield * SkillManager.bulwark_zap_damage()

	var damage_bonuses = MechanicsManager.get_damage_bonuses(self)
	var base_with_bonuses = (bullet_damage * damage_multiplier + damage_bonuses[0]) * (1.0 + damage_bonuses[1])
	var effective_bullet = base_with_bonuses

	return total_bleed + zap_committed + (effective_bullet - bullet_damage * damage_multiplier)

func _try_shoot():
	if SkillManager.get_active_keystone() == SkillManager.TREE_BULWARK:
		_fire_pulse()
		return
	var target = _get_best_target()
	if target == null or bullet_scene == null:
		return
	current_bullet_target = target
	var bullets_en_route = bullets_targeting.get(target, 0)
	var committed = _get_committed_damage(target)
	var effective_damage = (bullet_damage * damage_multiplier) + committed
	var hits_needed = ceil(target.health / effective_damage)
	if bullets_en_route >= hits_needed:
		return
	var b = bullet_scene.instantiate()
	get_parent().add_child(b)
	b.global_position = global_position

	var is_crit = randf() < crit_chance
	var final_damage = bullet_damage * damage_multiplier
	if is_crit:
		final_damage *= crit_damage

	var is_rapidfire = _tick_attack_counter() and SkillManager.barrage_rapidfire_bonus() > 0.0
	if is_rapidfire:
		final_damage += final_damage * SkillManager.barrage_rapidfire_bonus()

	var focus_bonus = MechanicsManager.get_focus_bonus(target)
	if focus_bonus > 0.0:
		final_damage += final_damage * focus_bonus
	MechanicsManager.register_hit(target)

	var damage_bonuses = MechanicsManager.get_damage_bonuses(self)
	final_damage += damage_bonuses[0]
	final_damage *= (1.0 + damage_bonuses[1])

	# Vampiric proc — replace final_damage with proc damage, tint bullet green
	var is_vampiric = MechanicsManager.consume_vampiric_proc()
	if is_vampiric:
		final_damage = MechanicsManager.get_vampiric_proc_damage(final_damage)

	var is_barrage_keystone = SkillManager.get_active_keystone() == SkillManager.TREE_BARRAGE
	var shoot_speed = bullet_speed * 2.0 if is_barrage_keystone else bullet_speed
	var bleed = SkillManager.barrage_bleed_dot()
	b.setup(
		global_position.direction_to(target.global_position),
		shoot_speed,
		final_damage,
		target,
		self,
		is_crit,
		is_rapidfire,
		bleed,
		is_barrage_keystone,
		main_node,
		is_vampiric
	)
	bullets_targeting[target] = bullets_en_route + 1
	if main_node: AudioManager.play(AudioManager.sfx_shoot)

func _get_best_target() -> Node2D:
	for existing_target in bullets_targeting.keys():
		if not is_instance_valid(existing_target):
			bullets_targeting.erase(existing_target)
			continue
		var committed = _get_committed_damage(existing_target)
		var effective_damage = (bullet_damage * damage_multiplier) + committed
		var hits_needed = ceil(existing_target.health / effective_damage)
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
	if randf() < evasion:
		return

	var hp_damage = amount
	var shield_absorbed = 0.0

	if shield > 0:
		var absorbed = min(shield, amount)
		shield_absorbed = absorbed
		shield -= absorbed
		var overflow = amount - absorbed
		hp_damage = (absorbed * (1.0 - shield_strength)) + overflow

	health -= hp_damage
	health = max(0.0, health)
	AudioManager.play(AudioManager.sfx_take_damage)

	if SkillManager.bulwark_pulse_unlocked():
		var is_boss_present = get_tree().get_nodes_in_group("boss").size() > 0
		if is_boss_present:
			pulse_boss_charge += amount * SkillManager.bulwark_pulse_charge_pct_boss()
		else:
			pulse_boss_charge += amount * SkillManager.bulwark_pulse_charge_pct_normal()

	if main_node != null:
		_update_combat_ui()
		if shield_absorbed > 0:
			main_node.spawn_damage_number(shield_absorbed, global_position + Vector2(randf_range(-20, 20), -20), "shield")
		main_node.spawn_damage_number(hp_damage, global_position + Vector2(randf_range(-20, 20), -40), "hp")

	if health <= 0:
		if main_node != null:
			main_node.trigger_game_over()

func _fire_pulse():
	if pulse_scene == null:
		return
	var p = pulse_scene.instantiate()
	get_parent().add_child(p)
	p.global_position = global_position

	var is_crit = randf() < crit_chance
	var final_damage = bullet_damage * damage_multiplier
	if is_crit:
		final_damage *= crit_damage

	var is_rapidfire = _tick_attack_counter() and SkillManager.barrage_rapidfire_bonus() > 0.0
	if is_rapidfire:
		final_damage += final_damage * SkillManager.barrage_rapidfire_bonus()

	var damage_bonuses = MechanicsManager.get_damage_bonuses(self)
	final_damage += damage_bonuses[0]
	final_damage *= (1.0 + damage_bonuses[1])

	# Vampiric proc
	var is_vampiric = MechanicsManager.consume_vampiric_proc()
	if is_vampiric:
		final_damage = MechanicsManager.get_vampiric_proc_damage(final_damage)

	final_damage += pulse_boss_charge
	pulse_boss_charge = 0.0

	var bleed = SkillManager.barrage_bleed_dot()
	var pulse_speed = 80.0 + (fire_rate * 40.0)

	p.setup(
		pulse_speed,
		final_damage,
		detection_radius,
		self,
		main_node,
		is_crit,
		is_rapidfire,
		bleed
	)
	if main_node: AudioManager.play(AudioManager.sfx_shoot)

func add_shield(amount: float):
	max_shield += amount
	shield += amount
	_update_combat_ui()

func increase_max_health(amount: float):
	max_health += amount
	health += amount
	health = min(health, get_effective_max_hp())
	if main_node != null:
		_update_combat_ui()

func notify_bullet_resolved(target: Node2D):
	if not is_instance_valid(target):
		bullets_targeting.erase(target)
		return
	if target in bullets_targeting:
		bullets_targeting[target] -= 1
		if bullets_targeting[target] <= 0:
			bullets_targeting.erase(target)

func set_bullet_scene(scene: PackedScene):
	bullet_scene = scene

func set_main(main: Node):
	main_node = main
