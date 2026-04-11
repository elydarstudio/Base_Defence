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
# Called from base.gd on every shield regen tick.
# Fires damage at nearest enemy.
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

	# Fortify — flat per 100 effective max shield
	flat += get_fortify_bonus(base_node.max_shield * base_node.shield_multiplier)

	# Ironclad — flat on unlock + shard levels, then % tier applied after flat in base.gd
	var ironclad = get_ironclad_bonus(base_node.shield, base_node.max_shield * base_node.shield_multiplier)
	flat += ironclad[0]
	pct += ironclad[1]

	# Vampiric — flat per regen amount
	flat += get_vampiric_bonus(base_node.hp_regen)

	# Surge — % while overhealed
	pct += get_surge_bonus(base_node.health, base_node.get_effective_max_hp())

	return [flat, pct]

# ── Momentum — Barrage Slot 4 ─────────────────
# Returns bonus damage multiplier based on distance traveled.
func get_momentum_bonus(distance: float) -> float:
	var bonus_per_pixel = SkillManager.barrage_momentum_bonus_per_pixel()
	if bonus_per_pixel == 0.0:
		return 0.0
	return distance * bonus_per_pixel

# ── Chain — Barrage Keystone ──────────────────
# Called from projectile.gd on hit when barrage keystone active.
# Sequentially hops to nearby enemies, spawning a visual projectile
# and dealing falloff damage with a damage number on each hop.
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
		# Spawn visual chain projectile
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
