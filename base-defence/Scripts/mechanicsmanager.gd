extends Node

# ══════════════════════════════════════════════
# MechanicsManager — autoload
# Owns all skill-driven mechanics that originate
# from the player/base side.
# Every new skill mechanic gets added here only.
# Game systems read from here, never reimplement.
# ══════════════════════════════════════════════

# ── Focus — Barrage Slot 2 ────────────────────
# Tracks consecutive hit stacks per enemy instance.
# Resets on kill. Works for any attack type.
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
# Returns bonus detection radius to add to base.
func get_range_bonus() -> float:
	return SkillManager.barrage_range_bonus()

# ── Fortify — Bulwark Slot 0 ──────────────────
# Bonus flat damage based on max shield investment.
func get_fortify_bonus(max_shield: float) -> float:
	var bonus_per_100 = SkillManager.bulwark_fortify_damage_per_100_shield()
	if bonus_per_100 == 0.0:
		return 0.0
	return floor(max_shield / 100.0) * bonus_per_100

# ── Ironclad — Bulwark Slot 1 ─────────────────
# Bonus damage % based on current shield uptime.
func get_ironclad_bonus(shield: float, max_shield: float) -> float:
	var max_bonus = SkillManager.bulwark_ironclad_max_bonus()
	if max_bonus == 0.0 or max_shield == 0.0:
		return 0.0
	var shield_pct = clamp(shield / max_shield, 0.0, 1.0)
	return shield_pct * max_bonus

# ── Zap — Bulwark Slot 2 ──────────────────────
# Called from base.gd on every shield regen tick.
# Fires damage at nearest enemy.
func trigger_zap(_main_node: Node, base_node: Node) -> void:
	var zap_dmg = SkillManager.bulwark_zap_damage()
	if zap_dmg == 0.0:
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
	EnemyMechanics.take_damage(closest, zap_dmg, "zap")

# ── Rampart — Bulwark Slot 3 ──────────────────
# Called from enemy _die(). Restores flat shield to base.
func trigger_rampart(base_node: Node) -> void:
	var restore = SkillManager.bulwark_rampart_shield_per_kill()
	if restore == 0.0:
		return
	var effective_max = base_node.max_shield * base_node.shield_multiplier
	base_node.shield = min(base_node.shield + restore, effective_max)
	base_node._update_combat_ui()

# ── Vampiric — Siphon Slot 0 ──────────────────
# Bonus flat damage based on HP regen investment.
func get_vampiric_bonus(hp_regen: float) -> float:
	var bonus_per_regen = SkillManager.siphon_vampiric_damage_per_regen()
	if bonus_per_regen == 0.0:
		return 0.0
	return hp_regen * bonus_per_regen

# ── Chill — Siphon Slot 1 ─────────────────────
# Called from base.gd on every HP regen tick.
# Slows nearest enemy.
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
# Returns the overheal buffer ceiling above max HP.
func get_overheal_ceiling(max_hp: float) -> float:
	var buffer_pct = SkillManager.siphon_overheal_buffer()
	if buffer_pct == 0.0:
		return 0.0
	return max_hp * buffer_pct

# ── Surge — Siphon Slot 3 ─────────────────────
# Returns bonus damage % if currently in overheal state.
func get_surge_bonus(health: float, max_hp: float) -> float:
	if not SkillManager.is_skill_unlocked(SkillManager.TREE_SIPHON, 3):
		return 0.0
	if health <= max_hp:
		return 0.0
	return SkillManager.siphon_surge_bonus()

# ── Combined outgoing damage bonus ────────────
# Call this from base.gd _try_shoot() to get total
# flat and % bonus from all passive damage skills.
# Returns [flat_bonus, percent_bonus]
func get_damage_bonuses(base_node: Node) -> Array:
	var flat: float = 0.0
	var pct: float = 0.0

	# Fortify — flat per 100 max shield
	flat += get_fortify_bonus(base_node.max_shield * base_node.shield_multiplier)

	# Ironclad — % based on shield uptime
	pct += get_ironclad_bonus(base_node.shield, base_node.max_shield * base_node.shield_multiplier)

	# Vampiric — flat per regen amount
	flat += get_vampiric_bonus(base_node.hp_regen)

	# Surge — % while overhealed
	pct += get_surge_bonus(base_node.health, base_node.get_effective_max_hp())

	return [flat, pct]
