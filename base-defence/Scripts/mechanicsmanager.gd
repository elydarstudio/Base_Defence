extends Node

# ══════════════════════════════════════════════
# MechanicsManager — autoload
# Owns all skill-driven mechanics that originate
# from the player/base side.
# Every new skill mechanic gets added here only.
# Game systems read from here, never reimplement.
# ══════════════════════════════════════════════

# ── Focus — Barrage Slot 2 ────────────────────
var _focus_stacks: Dictionary = {}

func get_focus_bonus(enemy: Node) -> float:
	if not SkillManager.is_skill_unlocked(SkillManager.TREE_BARRAGE, 2):
		return 0.0
	var stacks = _focus_stacks.get(enemy, 0)
	return stacks * SkillManager.barrage_focus_bonus_per_hit()

func register_hit(enemy: Node) -> void:
	if not SkillManager.is_skill_unlocked(SkillManager.TREE_BARRAGE, 2):
		return
	if not is_instance_valid(enemy):
		return
	_focus_stacks[enemy] = _focus_stacks.get(enemy, 0) + 1

func reset_focus(enemy: Node) -> void:
	_focus_stacks.erase(enemy)

func cleanup_focus(enemy: Node) -> void:
	_focus_stacks.erase(enemy)

# ── Range — Barrage Slot 3 ────────────────────
func get_range_bonus() -> float:
	return SkillManager.barrage_range_bonus()

# ── Fortify — Bulwark Slot 0 ──────────────────
func get_fortify_bonus(max_shield: float) -> float:
	var bonus_per_100 = SkillManager.bulwark_fortify_damage_per_100_shield()
	if bonus_per_100 == 0.0:
		return 0.0
	return floor(max_shield / 100.0) * bonus_per_100

func get_ironclad_bonus(shield: float, max_shield: float) -> Array:
	if not SkillManager.is_skill_unlocked(SkillManager.TREE_BULWARK, 1):
		return [0.0, 0.0]
	if max_shield == 0.0:
		return [0.0, 0.0]
	var shield_pct = clamp(shield / max_shield, 0.0, 1.0)
	var flat = SkillManager.bulwark_ironclad_flat_bonus()
	var max_pct_bonus = SkillManager.bulwark_ironclad_max_bonus()
	var pct = shield_pct * max_pct_bonus
	return [flat, pct]

# ── Zap — Bulwark Slot 2 ──────────────────────
func trigger_zap(_main_node: Node, base_node: Node, target: Node) -> void:
	var zap_pct = SkillManager.bulwark_zap_damage()
	if zap_pct == 0.0:
		return
	if not is_instance_valid(target):
		return
	var zap_dmg = base_node.shield * zap_pct
	if zap_dmg <= 0.0:
		return
	EnemyMechanics.take_damage(target, zap_dmg, "zap")

# ── Rampart — Bulwark Slot 3 ──────────────────
func trigger_rampart(base_node: Node) -> void:
	if not SkillManager.is_skill_unlocked(SkillManager.TREE_BULWARK, 3):
		return
	var restore = SkillManager.bulwark_rampart_shield_per_kill()
	var effective_max = base_node.max_shield * base_node.shield_multiplier
	base_node.shield = min(base_node.shield + restore, effective_max)
	base_node._update_combat_ui()

# ── Knockback — Bulwark Slot 4 ────────────────
func trigger_knockback(enemy: Node, base_node: Node, apply_force: bool = true) -> void:
	if not SkillManager.is_skill_unlocked(SkillManager.TREE_BULWARK, 4):
		return
	var damage = SkillManager.bulwark_knockback_damage(base_node.shield_strength)
	if apply_force:
		var force = SkillManager.bulwark_knockback_force(base_node.shield_strength)
		if force > 0.0:
			var dir = base_node.global_position.direction_to(enemy.global_position)
			var target_pos = enemy.global_position + (dir * force)
			if enemy.has_meta("knockback_tween"):
				var old_tween = enemy.get_meta("knockback_tween")
				if old_tween is Tween:
					old_tween.kill()
			var tween = enemy.create_tween()
			enemy.set_meta("knockback_tween", tween)
			tween.tween_property(enemy, "global_position", target_pos, 0.2)
	if damage > 0.0:
		EnemyMechanics.take_damage(enemy, damage, "normal")

# ── Vampiric — Siphon Slot 0 ──────────────────
# Regen tick sets the proc flag. Next attack consumes it for bonus damage.
var _vampiric_proc_ready: bool = false

func set_vampiric_proc() -> void:
	if not SkillManager.is_skill_unlocked(SkillManager.TREE_SIPHON, 0):
		return
	_vampiric_proc_ready = true

func consume_vampiric_proc() -> bool:
	if not _vampiric_proc_ready:
		return false
	_vampiric_proc_ready = false
	return true

# Returns the full proc damage given the bullet's pre-bonus damage.
# Formula: (bullet_damage + flat) * (1.0 + pct)
# Called only when consume_vampiric_proc() returns true.
func get_vampiric_proc_damage(bullet_damage: float) -> float:
	var flat = SkillManager.siphon_vampiric_flat_bonus()
	var pct = SkillManager.siphon_vampiric_pct_bonus()
	return (bullet_damage + flat) * (1.0 + pct)

# ── Chill — Siphon Slot 1 ─────────────────────
func trigger_chill(base_node: Node) -> void:
	var slow_pct = SkillManager.siphon_chill_slow()
	if slow_pct == 0.0:
		return
	var enemies = base_node.get_tree().get_nodes_in_group("enemies")
	var closest = null
	var closest_dist = INF
	for e in enemies:
		var d = base_node.global_position.distance_to(e.global_position)
		if d < closest_dist:
			closest_dist = d
			closest = e
	if closest == null:
		return
	if closest.has_method("apply_chill"):
		closest.apply_chill(slow_pct)

# ── Overheal — Siphon Slot 2 ──────────────────
func get_overheal_ceiling(max_hp: float) -> float:
	var buffer_pct = SkillManager.siphon_overheal_buffer()
	if buffer_pct == 0.0:
		return 0.0
	return max_hp * buffer_pct

# ── Surge — Siphon Slot 3 ─────────────────────
func get_surge_bonus(health: float, max_hp: float) -> float:
	if not SkillManager.is_skill_unlocked(SkillManager.TREE_SIPHON, 3):
		return 0.0
	if health <= max_hp:
		return 0.0
	return SkillManager.siphon_surge_bonus()

# ── Combined outgoing damage bonus ────────────
# Returns [flat_bonus, percent_bonus] for constant passive bonuses only.
# Vampiric is NOT included here — it's a proc, handled separately in base.gd.
func get_damage_bonuses(base_node: Node) -> Array:
	var flat: float = 0.0
	var pct: float = 0.0

	# Fortify — flat per 100 effective max shield
	flat += get_fortify_bonus(base_node.max_shield * base_node.shield_multiplier)

	# Ironclad — flat on unlock + shard levels, % based on current shield %
	var ironclad = get_ironclad_bonus(base_node.shield, base_node.max_shield * base_node.shield_multiplier)
	flat += ironclad[0]
	pct += ironclad[1]

	# Surge — % while overhealed
	pct += get_surge_bonus(base_node.health, base_node.get_effective_max_hp())

	return [flat, pct]

# ── Momentum — Barrage Slot 4 ─────────────────
func get_momentum_bonus(distance: float) -> float:
	var bonus_per_pixel = SkillManager.barrage_momentum_bonus_per_pixel()
	if bonus_per_pixel == 0.0:
		return 0.0
	return distance * bonus_per_pixel

# ── Chain — Barrage Keystone ──────────────────
const CHAIN_HOP_RADIUS: float = 250.0
const CHAIN_HOP_SPEED: float = 800.0

func trigger_chain(hit_enemy: Node, damage: float, main_node: Node, chain_scene: PackedScene) -> void:
	var jump_count = SkillManager.barrage_chain_jump_count()
	var falloff    = SkillManager.barrage_chain_falloff()
	if jump_count <= 0:
		return
	var hit_enemies: Array = [hit_enemy]
	var current_enemy = hit_enemy
	var current_damage = damage * falloff
	for i in range(jump_count):
		if not is_instance_valid(current_enemy):
			break
		var next = _find_chain_target(current_enemy, hit_enemies, main_node)
		if next == null:
			break
		hit_enemies.append(next)
		var proj = chain_scene.instantiate()
		main_node.add_child(proj)
		proj.global_position = current_enemy.global_position
		proj.setup_chain(
			current_enemy.global_position.direction_to(next.global_position),
			CHAIN_HOP_SPEED,
			current_damage,
			next,
			main_node
		)
		current_enemy  = next
		current_damage = current_damage * falloff

func _find_chain_target(from_enemy: Node, already_hit: Array, main_node: Node) -> Node:
	var enemies  = main_node.get_tree().get_nodes_in_group("enemies")
	var closest  = null
	var closest_dist = CHAIN_HOP_RADIUS
	for e in enemies:
		if e in already_hit:
			continue
		if not is_instance_valid(e):
			continue
		var d = from_enemy.global_position.distance_to(e.global_position)
		if d < closest_dist:
			closest_dist = d
			closest = e
	return closest
