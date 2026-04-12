extends Node

# ── Constants ─────────────────────────────────
const KILLS_PER_SHARD_BASE: int = 1000
const MAX_TOKENS: int = 15
const SKILLS_PER_TREE: int = 6

const TREE_BARRAGE: String = "barrage"
const TREE_BULWARK: String = "bulwark"
const TREE_SIPHON: String = "siphon"

# ── Slot layout (identical structure for all trees) ───
# 0 = root
# 1 = left branch        (requires 0)
# 2 = right branch       (requires 0)
# 3 = left continues     (requires 1)
# 4 = right continues    (requires 2)
# 5 = keystone           (requires 3 AND 4)
#
# BARRAGE:  0=Rapidfire, 1=Bleed, 2=Range, 3=Focus, 4=Momentum, 5=Chain
# BULWARK:  0=Fortify, 1=Ironclad, 2=Zap, 3=Rampart, 4=Knockback, 5=Pulse
# SIPHON:   0=Vampiric, 1=Overheal, 2=Chill, 3=Surge, 4=Vitality, 5=Drain Beam

const SKILL_DATA = {
	"barrage": [
		{"name": "Rapidfire",       "desc": "Every 3rd attack deals bonus damage. Base +20%, +5% per shard level."},
		{"name": "Bleed",           "desc": "Every attack applies a DoT. Ticks scale with Crit Chance investment. Base 5 dmg/tick, +2 per shard level."},
		{"name": "Range",           "desc": "Increases bullet detection radius. Base +50px, +25px per shard level."},
		{"name": "Focus",           "desc": "Consecutive hits on the same target ramp damage +10% per hit. Resets on kill. Base +10%, +1% per shard level."},
		{"name": "Momentum",        "desc": "Bullets deal more damage the further they travel. Base 0.05% per pixel, +0.02% per shard level. Synergizes with Range."},
		{"name": "Keystone: Chain", "desc": "Bullets chain to nearby enemies on hit. 2 jumps base, +1 per 5 shard levels. Damage falls off per jump. Requires Focus + Momentum."},
	],
	"bulwark": [
		{"name": "Fortify",          "desc": "Every 100 Max Shield adds flat bonus damage + % damage. Base +2 flat and +5% per 100 shield, scaling with shards."},
		{"name": "Ironclad",         "desc": "Current shield % adds bonus damage %. Max bonus 60% at full shield, flat bonus scales with shards."},
		{"name": "Zap",              "desc": "Every shield regen tick fires damage at the nearest enemy. Base 5% of current shield, +1% per shard level."},
		{"name": "Rampart",          "desc": "Killing an enemy restores flat shield. Base +20 shield, +20 per shard level."},
		{"name": "Knockback",        "desc": "Hitting an enemy pushes them back. Force scales with Shield Strength. Synergizes with Momentum."},
		{"name": "Keystone: Pulse",  "desc": "Replaces bullets with an expanding AOE pulse. Incoming damage charges the next pulse. Requires Rampart + Knockback."},
	],
	"siphon": [
		{"name": "Vampiric",             "desc": "HP regen ticks charge the next attack. That attack deals bonus flat + % damage. Base +10 flat and +15%, scaling with shards."},
		{"name": "Overheal",             "desc": "Regen fills past max HP into an overheal buffer. Buffer: 50% of max HP base, +5% per shard. While overhealed: +15 flat damage, +5 per shard."},
		{"name": "Chill",                "desc": "Each regen tick permanently slows a random unchilled enemy 60%. Chilled enemies take bonus damage. Base +20%, +5% per shard."},
		{"name": "Surge",                "desc": "While overhealed, deal bonus damage %. Base +15%, +5% per shard. Stacks with Overheal flat bonus."},
		{"name": "Vitality",             "desc": "Killing an enemy restores flat HP. Base +2 HP per kill, +1 per shard. Feeds the Overheal loop."},
		{"name": "Keystone: Drain Beam", "desc": "Replaces bullets with a continuous beam. Damages and heals simultaneously. Crits = burst damage + burst heal. Requires Surge + Vitality."},
	],
}

var _kills_since_last_shard: int = 0

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

func on_boss_killed(phase: int):
	if SaveManager.data["phase_tokens_earned"] >= MAX_TOKENS:
		return
	SaveManager.data["phase_tokens"] += 1
	SaveManager.data["phase_tokens_earned"] += 1
	SaveManager.save_game()

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

func get_kills_since_last_shard() -> int:
	return _kills_since_last_shard

func get_next_shard_threshold() -> int:
	return _get_shard_threshold()

func unlock_skill(tree: String, slot: int) -> bool:
	if get_tokens() <= 0:
		return false
	if SaveManager.data["phase_tokens_earned"] > MAX_TOKENS:
		return false
	if is_skill_unlocked(tree, slot):
		return false
	if not _check_prereq(tree, slot):
		return false
	SaveManager.data["skill_" + tree + "_unlocked"].append(slot)
	SaveManager.data["skill_" + tree + "_levels"].append(0)
	SaveManager.data["phase_tokens"] -= 1
	if slot == 5:
		SaveManager.data["active_keystone"] = tree
	SaveManager.save_game()
	return true

func _check_prereq(tree: String, slot: int) -> bool:
	match slot:
		0: return true
		1: return is_skill_unlocked(tree, 0)
		2: return is_skill_unlocked(tree, 0)
		3: return is_skill_unlocked(tree, 1)
		4: return is_skill_unlocked(tree, 2)
		5:
			if has_keystone(): return false
			return is_skill_unlocked(tree, 3) and is_skill_unlocked(tree, 4)
	return false

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
func barrage_rapidfire_bonus() -> float:
	if not is_skill_unlocked(TREE_BARRAGE, 0): return 0.0
	var level = get_skill_level(TREE_BARRAGE, 0)
	return 0.20 + (level * 0.05)

# Slot 1 — Bleed
func barrage_bleed_dot() -> float:
	if not is_skill_unlocked(TREE_BARRAGE, 1): return 0.0
	var level = get_skill_level(TREE_BARRAGE, 1)
	return 5.0 + (level * 2.0)

# Slot 2 — Range
func barrage_range_bonus() -> float:
	if not is_skill_unlocked(TREE_BARRAGE, 2): return 0.0
	var level = get_skill_level(TREE_BARRAGE, 2)
	return 50.0 + (level * 25.0)

# Slot 3 — Focus
func barrage_focus_bonus_per_hit() -> float:
	if not is_skill_unlocked(TREE_BARRAGE, 3): return 0.0
	var level = get_skill_level(TREE_BARRAGE, 3)
	return 0.10 + (level * 0.01)

# Slot 4 — Momentum
func barrage_momentum_bonus_per_pixel() -> float:
	if not is_skill_unlocked(TREE_BARRAGE, 4): return 0.0
	var level = get_skill_level(TREE_BARRAGE, 4)
	return 0.0005 + (level * 0.0002)

# Slot 5 — Keystone: Chain
func barrage_chain_jump_count() -> int:
	if not is_skill_unlocked(TREE_BARRAGE, 5): return 0
	var level = get_skill_level(TREE_BARRAGE, 5)
	return 2 + int(level / 5.0)

func barrage_chain_falloff() -> float:
	if not is_skill_unlocked(TREE_BARRAGE, 5): return 0.0
	var level = get_skill_level(TREE_BARRAGE, 5)
	return 0.60 + (level * 0.02)

# ── BULWARK ───────────────────────────────────

# Slot 0 — Fortify
func bulwark_fortify_flat_per_100_shield() -> float:
	if not is_skill_unlocked(TREE_BULWARK, 0): return 0.0
	var level = get_skill_level(TREE_BULWARK, 0)
	return 2.0 + (level * 0.5)

func bulwark_fortify_pct_bonus() -> float:
	if not is_skill_unlocked(TREE_BULWARK, 0): return 0.0
	var level = get_skill_level(TREE_BULWARK, 0)
	return 0.05 + (level * 0.02)

# Slot 1 — Ironclad
func bulwark_ironclad_flat_bonus() -> float:
	if not is_skill_unlocked(TREE_BULWARK, 1): return 0.0
	var level = get_skill_level(TREE_BULWARK, 1)
	return 5.0 + (level * 5.0)

func bulwark_ironclad_max_bonus() -> float:
	if not is_skill_unlocked(TREE_BULWARK, 1): return 0.0
	return 0.60

# Slot 2 — Zap
func bulwark_zap_damage() -> float:
	if not is_skill_unlocked(TREE_BULWARK, 2): return 0.0
	var level = get_skill_level(TREE_BULWARK, 2)
	return 0.05 + (level * 0.01)

# Slot 3 — Rampart
func bulwark_rampart_shield_per_kill() -> float:
	if not is_skill_unlocked(TREE_BULWARK, 3): return 0.0
	var level = get_skill_level(TREE_BULWARK, 3)
	return 20.0 + (level * 20.0)

# Slot 4 — Knockback
func bulwark_knockback_force(shield_strength: float) -> float:
	if not is_skill_unlocked(TREE_BULWARK, 4): return 0.0
	return shield_strength * 300.0

func bulwark_knockback_damage(shield_strength: float) -> float:
	if not is_skill_unlocked(TREE_BULWARK, 4): return 0.0
	var level = get_skill_level(TREE_BULWARK, 4)
	return shield_strength * (50.0 + (level * 25.0))

# Slot 5 — Keystone: Pulse
func bulwark_pulse_unlocked() -> bool:
	return is_skill_unlocked(TREE_BULWARK, 5)

func bulwark_pulse_charge_pct_normal() -> float:
	if not is_skill_unlocked(TREE_BULWARK, 5): return 0.0
	var level = get_skill_level(TREE_BULWARK, 5)
	return 0.10 + (level * 0.025)

func bulwark_pulse_charge_pct_boss() -> float:
	if not is_skill_unlocked(TREE_BULWARK, 5): return 0.0
	var level = get_skill_level(TREE_BULWARK, 5)
	return 1.00 + (level * 0.10)

# ── SIPHON ────────────────────────────────────

# Slot 0 — Vampiric
func siphon_vampiric_flat_bonus() -> float:
	if not is_skill_unlocked(TREE_SIPHON, 0): return 0.0
	var level = get_skill_level(TREE_SIPHON, 0)
	return 10.0 + (level * 4.0)

func siphon_vampiric_pct_bonus() -> float:
	if not is_skill_unlocked(TREE_SIPHON, 0): return 0.0
	var level = get_skill_level(TREE_SIPHON, 0)
	return 0.15 + (level * 0.05)

# Slot 1 — Overheal
func siphon_overheal_buffer() -> float:
	if not is_skill_unlocked(TREE_SIPHON, 1): return 0.0
	var level = get_skill_level(TREE_SIPHON, 1)
	return 0.50 + (level * 0.05)

func siphon_overheal_flat_bonus() -> float:
	if not is_skill_unlocked(TREE_SIPHON, 1): return 0.0
	var level = get_skill_level(TREE_SIPHON, 1)
	return 15.0 + (level * 5.0)

# Slot 2 — Chill
func siphon_chill_damage_bonus() -> float:
	if not is_skill_unlocked(TREE_SIPHON, 2): return 0.0
	var level = get_skill_level(TREE_SIPHON, 2)
	return 0.20 + (level * 0.05)

# Slot 3 — Surge
func siphon_surge_bonus() -> float:
	if not is_skill_unlocked(TREE_SIPHON, 3): return 0.0
	var level = get_skill_level(TREE_SIPHON, 3)
	return 0.15 + (level * 0.05)

# Slot 4 — Vitality
func siphon_vitality_hp_per_kill() -> float:
	if not is_skill_unlocked(TREE_SIPHON, 4): return 0.0
	var level = get_skill_level(TREE_SIPHON, 4)
	return 5.0 + (level * 2.0)

# Slot 5 — Keystone: Drain Beam
func siphon_drain_beam_unlocked() -> bool:
	return is_skill_unlocked(TREE_SIPHON, 5)
