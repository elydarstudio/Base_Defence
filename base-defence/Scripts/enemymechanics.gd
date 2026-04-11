extends Node

# ══════════════════════════════════════════════
# EnemyMechanics — autoload
# Owns all shared enemy behavior that would otherwise
# be copy-pasted across every enemy file.
# Enemy scripts call into here instead of reimplementing.
# Adding a new enemy type: create thin script, call these.
# ══════════════════════════════════════════════

const BLEED_INTERVAL: float = 0.5

# ── Main tick — call this from every enemy _process() ─────────────────────────
func tick(enemy: Node, delta: float) -> void:
	_tick_movement(enemy, delta)
	_tick_attack(enemy, delta)
	_tick_bleed(enemy, delta)
	enemy.queue_redraw()

# ── Boss tick ─────────────────────────────────────────────────────────────────
func tick_boss(enemy: Node, delta: float) -> void:
	_tick_boss_movement(enemy, delta)
	_tick_boss_attack(enemy, delta)
	_tick_bleed(enemy, delta)
	enemy.queue_redraw()

# ── Runner tick ───────────────────────────────────────────────────────────────
func tick_runner(enemy: Node, delta: float) -> void:
	_tick_runner_movement(enemy, delta)
	_tick_bleed(enemy, delta)
	enemy.queue_redraw()

# ── Movement ──────────────────────────────────────────────────────────────────
func _tick_movement(enemy: Node, delta: float) -> void:
	if enemy.base_node == null:
		return
	var dist = enemy.global_position.distance_to(enemy.base_node.global_position)
	if dist > enemy.attack_range:
		var dir = enemy.global_position.direction_to(enemy.base_node.global_position)
		enemy.global_position += dir * enemy.speed * delta
		_apply_separation(enemy, delta)

func _tick_boss_movement(enemy: Node, delta: float) -> void:
	if enemy.base_node == null:
		return
	var dist = enemy.global_position.distance_to(enemy.base_node.global_position)
	if dist > enemy.attack_range:
		var dir = enemy.global_position.direction_to(enemy.base_node.global_position)
		enemy.global_position += dir * enemy.speed * delta

func _tick_runner_movement(enemy: Node, delta: float) -> void:
	if enemy.base_node == null:
		return
	var dist = enemy.global_position.distance_to(enemy.base_node.global_position)
	if dist > enemy.attack_range:
		var dir = enemy.global_position.direction_to(enemy.base_node.global_position)
		enemy.global_position += dir * enemy.speed * delta
		_apply_separation(enemy, delta)
	else:
		if not enemy.has_exploded:
			enemy.has_exploded = true
			enemy.base_node.take_damage(enemy.attack_damage)
			if enemy.main_node != null:
				enemy.base_node._update_combat_ui()
			enemy._die()

# ── Separation ────────────────────────────────────────────────────────────────
func _apply_separation(enemy: Node, delta: float) -> void:
	var separation = Vector2.ZERO
	for other in enemy.get_tree().get_nodes_in_group("enemies"):
		if other == enemy:
			continue
		var d = enemy.global_position.distance_to(other.global_position)
		if d < enemy.separation_radius and d > 0:
			separation += enemy.global_position.direction_to(other.global_position) * -1
	if separation.length() > 0:
		enemy.global_position += separation.normalized() * 0.5 * delta

# ── Attack ────────────────────────────────────────────────────────────────────
func _tick_attack(enemy: Node, delta: float) -> void:
	if enemy.base_node == null:
		return
	var dist = enemy.global_position.distance_to(enemy.base_node.global_position)
	if dist <= enemy.attack_range:
		enemy.attack_timer += delta
		if enemy.attack_timer >= enemy.attack_interval:
			enemy.attack_timer = 0.0
			enemy.base_node.take_damage(enemy.attack_damage)
			if enemy.main_node != null:
				enemy.base_node._update_combat_ui()
			MechanicsManager.trigger_knockback(enemy, enemy.base_node)
			if SkillManager.is_skill_unlocked(SkillManager.TREE_BULWARK, 4):
				enemy.attack_timer = enemy.attack_interval

func _tick_boss_attack(enemy: Node, delta: float) -> void:
	if enemy.base_node == null:
		return
	var dist = enemy.global_position.distance_to(enemy.base_node.global_position)
	if dist <= enemy.attack_range:
		enemy.attack_timer += delta
		if enemy.attack_timer >= enemy.attack_interval:
			enemy.attack_timer = 0.0
			var final_damage = enemy.attack_damage
			if randf() < enemy.crit_chance:
				final_damage *= enemy.crit_multiplier
			enemy.base_node.take_damage(final_damage)
			if enemy.main_node != null:
				enemy.base_node._update_combat_ui()
			MechanicsManager.trigger_knockback(enemy, enemy.base_node, false)

# ── Health bar drawing ────────────────────────────────────────────────────────
func draw_health_bar(enemy: Node, bar_width: float, bar_height: float, offset: Vector2) -> void:
	var pct: float = enemy.health / enemy.max_health
	enemy.draw_rect(Rect2(offset, Vector2(bar_width, bar_height)), Color(0.2, 0.2, 0.2))
	var fill_color: Color
	if pct > 0.5:
		fill_color = Color(0.2, 0.9, 0.2)
	elif pct > 0.25:
		fill_color = Color(0.9, 0.9, 0.2)
	else:
		fill_color = Color(0.9, 0.2, 0.2)
	enemy.draw_rect(Rect2(offset, Vector2(bar_width * pct, bar_height)), fill_color)

# ── take_damage ───────────────────────────────────────────────────────────────
func take_damage(enemy: Node, amount: float, type: String = "normal") -> void:
	if enemy.health <= 0:
		return
	enemy.health -= amount
	if enemy.main_node != null:
		enemy.main_node.spawn_damage_number(amount, enemy.global_position + Vector2(randf_range(-10, 10), -20), type)
	if enemy.health <= 0:
		enemy._die()

# ── Bleed ─────────────────────────────────────────────────────────────────────
func apply_bleed(enemy: Node, damage: float, was_crit: bool) -> void:
	if not is_instance_valid(enemy):
		return
	var crit_pct = 0.0
	if enemy.main_node != null:
		crit_pct = enemy.main_node.get_node("Base").crit_chance * 100.0
	if crit_pct <= 20.0:
		enemy.bleed_ticks = 2
	elif crit_pct <= 40.0:
		enemy.bleed_ticks = 3
	elif crit_pct <= 60.0:
		enemy.bleed_ticks = 4
	else:
		enemy.bleed_ticks = 5

	var first_tick = damage * 2.0 if was_crit else damage
	if enemy.main_node != null:
		enemy.main_node.spawn_damage_number(first_tick, enemy.global_position + Vector2(-25, 0), "bleed")
	if enemy.health > 0:
		enemy.health -= first_tick
		if enemy.health <= 0:
			enemy._die()
			return

	enemy.bleed_damage = damage
	enemy.bleed_ticks_remaining = enemy.bleed_ticks - 1
	enemy.bleed_timer = 0.0

func _tick_bleed(enemy: Node, delta: float) -> void:
	if enemy.bleed_ticks_remaining <= 0:
		return
	enemy.bleed_timer += delta
	if enemy.bleed_timer >= BLEED_INTERVAL:
		enemy.bleed_timer = 0.0
		enemy.bleed_ticks_remaining -= 1
		if enemy.health <= 0:
			return
		enemy.health -= enemy.bleed_damage
		if enemy.main_node != null:
			enemy.main_node.spawn_damage_number(enemy.bleed_damage, enemy.global_position + Vector2(-25, 0), "bleed")
		if enemy.health <= 0:
			enemy._die()
