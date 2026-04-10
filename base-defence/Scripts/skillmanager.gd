extends Node

# ── Constants ─────────────────────────────────
const KILLS_PER_SHARD_BASE: int = 1000
const MAX_TOKENS: int = 15
const SKILLS_PER_TREE: int = 6  # 5 skills + 1 keystone

const TREE_BARRAGE: String = "barrage"
const TREE_BULWARK: String = "bulwark"
const TREE_SIPHON: String = "siphon"

# Slot layout per tree:
#   0 = root
#   1 = left branch  (requires 0)
#   2 = right branch (requires 0)
#   3 = left continues (requires 1)
#   4 = right continues (requires 2)
#   5 = keystone (requires 3 AND 4, only one keystone allowed lifetime)

const SKILL_DATA = {
	"barrage": [
		# slot 0
		{"name": "Rapidfire",          "desc": "Every 3rd attack deals bonus damage. Base +20%, +5% per shard level."},
		# slot 1 — left branch
		{"name": "Bleed",              "desc": "Every attack applies a DoT. Ticks scale with Crit Chance investment. Base 5 dmg/tick, +2 per shard level."},
		# slot 2 — right branch
		{"name": "Focus",              "desc": "Consecutive hits on the same target ramp damage +10% per hit. Resets on kill. Base +10%, +1% per shard level."},
		# slot 3 — left continues
		{"name": "Range",              "desc": "Increases bullet detection radius. Base +50px, +25px per shard level."},
		# slot 4 — right continues
		{"name": "Momentum",           "desc": "Bullets deal more damage the further they travel. Base 0.05% per pixel, +0.02% per shard level. Synergizes with Range."},
		# slot 5 — keystone
		{"name": "Keystone: Multishot","desc": "Fires 3 bullets simultaneously. Side shots start at 20% damage, +10% per shard level. Requires Range + Momentum."},
	],
	"bulwark": [
		# slot 0
		{"name": "Fortify",            "desc": "Every 100 Max Shield adds flat bonus damage. Base +2 per 100, +1 per shard level."},
		# slot 1 — left branch
		{"name": "Ironclad",           "desc": "Current shield % adds bonus damage %. Max bonus: base 15%, +5% per shard level."},
		# slot 2 — right branch
		{"name": "Zap",                "desc": "Every shield regen tick fires damage at the nearest enemy. Base 8 dmg, +3 per shard level."},
		# slot 3 — left continues
		{"name": "Rampart",            "desc": "Killing an enemy restores flat shield. Base 3 shield, +1 per shard level. Silent — no damage number."},
		# slot 4 — right continues
		{"name": "Knockback",          "desc": "Hitting an enemy pushes them back. Force scales with Shield Strength. Base 80px, +20px per shard level. Synergizes with Momentum."},
		# slot 5 — keystone
		{"name": "Keystone: Pulse",    "desc": "Replaces bullets with AOE pulse. Fires on ATK SPD interval, hits all enemies in radius. Requires Rampart + Knockback."},
	],
	"siphon": [
		# slot 0
		{"name": "Vampiric",           "desc": "HP Regen Amount adds flat bonus damage. Base +1 per regen point, +0.5 per shard level."},
		# slot 1 — left branch
		{"name": "Chill",              "desc": "Every HP regen tick slows the nearest enemy. Base 10% slow, +3% per shard level, cap 60%."},
		# slot 2 — right branch
		{"name": "Overheal",           "desc": "Introduces an overheal buffer above max HP. Base 10% of max HP, +3% per shard level."},
		# slot 3 — left continues
		{"name": "Surge",              "desc": "While overhealed, deal bonus damage %. Base +15%, +5% per shard level. Feeds off Overheal."},
		# slot 4 — right continues
		{"name": "Vitality",           "desc": "Killing an enemy restores flat HP. Base 2 HP per kill, +1 per shard level. Feeds the Overheal loop."},
		# slot 5 — keystone
		{"name": "Keystone: Drain Beam","desc": "Replaces bullets with a continuous beam. Damages and heals simultaneously. Crits = burst damage + burst heal. Requires Surge + Vitality."},
	],
}

# ── Kill tracking for shard generation ────────
var _kills_since_last_shard: int = 0

# ── Read-only helpers ─────────────────────────
func get_tokens() -> int:
	return SaveManager.data["phase_tokens"]

func get_shards() -> int:
	return SaveManager.data["phase_shards"]

func get_lifetime_kills() -> int:
	return SaveManager.data["lifetime_kills"]

func get_skill_level(tree: String, slot: int) -> int:
	var unlocked = SaveManager.data["skill_" + tree + "_unlocked"]
	var idx = unlocked.find(slot)
	if idx == -1:
		return 0
	var levels = SaveManager.data["skill_" + tree + "_levels"]
	if idx < levels.size():
		return levels[idx]
	return 0

func is_skill_unlocked(tree: String, slot: int) -> bool:
	var unlocked = SaveManager.data["skill_" + tree + "_unlocked"]
	return slot in unlocked

func get_active_keystone() -> String:
	return SaveManager.data["active_keystone"]

func has_keystone() -> bool:
	return SaveManager.data["active_keystone"] != ""

func get_tree_skill_count(tree: String) -> int:
	return SaveManager.data["skill_" + tree + "_unlocked"].size()

func get_visual_tier(tree: String) -> int:
	var count = get_tree_skill_count(tree)
	if count >= 10: return 4
	if count >= 6:  return 3
	if count >= 4:  return 2
	if count >= 2:  return 1
	return 0

# ── Token earning ──────────────────────────────
func on_boss_killed(phase: int):
	if phase < 3:
		return
	if SaveManager.data["phase_tokens_earned"] >= MAX_TOKENS:
		return
	SaveManager.data["phase_tokens"] += 1
	SaveManager.data["phase_tokens_earned"] += 1
	SaveManager.save_game()

# ── Shard earning ──────────────────────────────
func on_enemy_killed() -> int:
	SaveManager.data["lifetime_kills"] += 1
	_kills_since_last_shard += 1
	var threshold = _get_shard_threshold()
	var shards_earned = 0
	while _kills_since_last_shard >= threshold:
		_kills_since_last_shard -= threshold
		SaveManager.data["phase_shards"] += 1
		SaveManager.data["phase_shards_earned"] += 1
		shards_earned += 1
	if shards_earned > 0:
		SaveManager.save_game()
	return shards_earned

func _get_shard_threshold() -> int:
	var shards_earned = SaveManager.data["phase_shards_earned"]
	return KILLS_PER_SHARD_BASE + (shards_earned * 100)

# Returns kills made toward the next shard
func get_kills_since_last_shard() -> int:
	return _kills_since_last_shard

# Returns the kill count needed for the next shard
func get_next_shard_threshold() -> int:
	return _get_shard_threshold()

# ── Token spending — unlock a skill ───────────
func unlock_skill(tree: String, slot: int) -> bool:
	if get_tokens() <= 0:
		return false
	if SaveManager.data["phase_tokens_earned"] > MAX_TOKENS:
		return false
	if is_skill_unlocked(tree, slot):
		return false
	# Prerequisite check
	match slot:
		0:
			pass  # root — always available
		1:
			if not is_skill_unlocked(tree, 0): return false
		2:
			if not is_skill_unlocked(tree, 0): return false
		3:
			if not is_skill_unlocked(tree, 1): return false
		4:
			if not is_skill_unlocked(tree, 2): return false
		5:
			# Keystone — requires both branch ends AND no other keystone
			if not is_skill_unlocked(tree, 3): return false
			if not is_skill_unlocked(tree, 4): return false
			if has_keystone(): return false
		_:
			return false
	SaveManager.data["skill_" + tree + "_unlocked"].append(slot)
	SaveManager.data["skill_" + tree + "_levels"].append(0)
	SaveManager.data["phase_tokens"] -= 1
	if slot == 5:
		SaveManager.data["active_keystone"] = tree
	SaveManager.save_game()
	return true

# ── Shard spending — level up a skill ─────────
func level_skill(tree: String, slot: int) -> bool:
	if get_shards() <= 0:
		return false
	if not is_skill_unlocked(tree, slot):
		return false
	var unlocked = SaveManager.data["skill_" + tree + "_unlocked"]
	var idx = unlocked.find(slot)
	if idx == -1:
		return false
	SaveManager.data["skill_" + tree + "_levels"][idx] += 1
	SaveManager.data["phase_shards"] -= 1
	SaveManager.save_game()
	return true

# ── Respec ────────────────────────────────────
func respec(tree: String):
	var unlocked = SaveManager.data["skill_" + tree + "_unlocked"]
	var refund = unlocked.size()
	SaveManager.data["phase_tokens"] += refund
	SaveManager.data["skill_" + tree + "_unlocked"] = []
	SaveManager.data["skill_" + tree + "_levels"] = []
	if SaveManager.data["active_keystone"] == tree:
		SaveManager.data["active_keystone"] = ""
	SaveManager.save_game()

# ══════════════════════════════════════════════
# SKILL EFFECT QUERIES
# Gate on is_skill_unlocked only.
# level 0 = unlocked but no shards spent — still gives base bonus.
# ══════════════════════════════════════════════

# ── BARRAGE ───────────────────────────────────

# Slot 0 — Rapidfire
# Every 3rd attack deals bonus damage. Base 20%, +5% per shard level.
func barrage_rapidfire_bonus() -> float:
	if not is_skill_unlocked(TREE_BARRAGE, 0): return 0.0
	var level = get_skill_level(TREE_BARRAGE, 0)
	return 0.20 + (level * 0.05)

# Slot 1 — Bleed
# Every attack applies DoT. Base 5 dmg/tick, +2 per shard level.
func barrage_bleed_dot() -> float:
	if not is_skill_unlocked(TREE_BARRAGE, 1): return 0.0
	var level = get_skill_level(TREE_BARRAGE, 1)
	return 5.0 + (level * 2.0)

# Slot 2 — Focus
# Consecutive hits ramp damage. Base +10% per hit, +1% per shard level.
func barrage_focus_bonus_per_hit() -> float:
	if not is_skill_unlocked(TREE_BARRAGE, 2): return 0.0
	var level = get_skill_level(TREE_BARRAGE, 2)
	return 0.10 + (level * 0.01)

# Slot 3 — Range
# Bonus detection radius. Base +50px, +25px per shard level.
func barrage_range_bonus() -> float:
	if not is_skill_unlocked(TREE_BARRAGE, 3): return 0.0
	var level = get_skill_level(TREE_BARRAGE, 3)
	return 100.0 + (level * 15.0)

# Slot 4 — Momentum
# Bonus damage % per pixel traveled. Base 0.05%, +0.02% per shard level.
func barrage_momentum_bonus_per_pixel() -> float:
	if not is_skill_unlocked(TREE_BARRAGE, 4): return 0.0
	var level = get_skill_level(TREE_BARRAGE, 4)
	return 0.0005 + (level * 0.0002)

# Slot 5 — Keystone: Multishot
# Side shot damage as % of main shot. Base 20%, +10% per shard level.
func barrage_multishot_side_damage() -> float:
	if not is_skill_unlocked(TREE_BARRAGE, 5): return 0.0
	var level = get_skill_level(TREE_BARRAGE, 5)
	return 0.20 + (level * 0.10)

# ── BULWARK ───────────────────────────────────

# Slot 0 — Fortify
# Bonus flat damage per 100 max shield. Base +2, +1 per shard level.
func bulwark_fortify_damage_per_100_shield() -> float:
	if not is_skill_unlocked(TREE_BULWARK, 0): return 0.0
	var level = get_skill_level(TREE_BULWARK, 0)
	return 2.0 + (level * 1.0)

# Slot 1 — Ironclad
# Max bonus damage % at full shield. Base 15%, +5% per shard level.
func bulwark_ironclad_max_bonus() -> float:
	if not is_skill_unlocked(TREE_BULWARK, 1): return 0.0
	var level = get_skill_level(TREE_BULWARK, 1)
	return 0.15 + (level * 0.05)

# Slot 2 — Zap
# Damage per zap on shield regen tick. Base 8, +3 per shard level.
func bulwark_zap_damage() -> float:
	if not is_skill_unlocked(TREE_BULWARK, 2): return 0.0
	var level = get_skill_level(TREE_BULWARK, 2)
	return 8.0 + (level * 3.0)

# Slot 3 — Rampart
# Shield restored per kill. Base 3, +1 per shard level.
func bulwark_rampart_shield_per_kill() -> float:
	if not is_skill_unlocked(TREE_BULWARK, 3): return 0.0
	var level = get_skill_level(TREE_BULWARK, 3)
	return 3.0 + (level * 1.0)

# Slot 4 — Knockback
# Knockback force in pixels. Base 80px, +20px per shard level.
func bulwark_knockback_force() -> float:
	if not is_skill_unlocked(TREE_BULWARK, 4): return 0.0
	var level = get_skill_level(TREE_BULWARK, 4)
	return 80.0 + (level * 20.0)

# Slot 5 — Keystone: Pulse
# AOE pulse — radius and damage handled in base.gd when implemented.
# Query kept here for gating purposes.
func bulwark_pulse_unlocked() -> bool:
	return is_skill_unlocked(TREE_BULWARK, 5)

# ── SIPHON ────────────────────────────────────

# Slot 0 — Vampiric
# Bonus flat damage per 1 HP regen amount. Base 1.0, +0.5 per shard level.
func siphon_vampiric_damage_per_regen() -> float:
	if not is_skill_unlocked(TREE_SIPHON, 0): return 0.0
	var level = get_skill_level(TREE_SIPHON, 0)
	return 1.0 + (level * 0.5)

# Slot 1 — Chill
# Slow % on regen tick. Base 10%, +3% per shard level, cap 60%.
func siphon_chill_slow() -> float:
	if not is_skill_unlocked(TREE_SIPHON, 1): return 0.0
	var level = get_skill_level(TREE_SIPHON, 1)
	return min(0.60, 0.10 + (level * 0.03))

# Slot 2 — Overheal
# Overheal buffer as % of max HP. Base 10%, +3% per shard level.
func siphon_overheal_buffer() -> float:
	if not is_skill_unlocked(TREE_SIPHON, 2): return 0.0
	var level = get_skill_level(TREE_SIPHON, 2)
	return 0.10 + (level * 0.03)

# Slot 3 — Surge
# Damage bonus % while overhealed. Base 15%, +5% per shard level.
func siphon_surge_bonus() -> float:
	if not is_skill_unlocked(TREE_SIPHON, 3): return 0.0
	var level = get_skill_level(TREE_SIPHON, 3)
	return 0.15 + (level * 0.05)

# Slot 4 — Vitality
# HP restored per kill. Base 2, +1 per shard level.
func siphon_vitality_hp_per_kill() -> float:
	if not is_skill_unlocked(TREE_SIPHON, 4): return 0.0
	var level = get_skill_level(TREE_SIPHON, 4)
	return 2.0 + (level * 1.0)

# Slot 5 — Keystone: Drain Beam
# Drain beam — implemented in base.gd when built.
# Query kept here for gating purposes.
func siphon_drain_beam_unlocked() -> bool:
	return is_skill_unlocked(TREE_SIPHON, 5)
