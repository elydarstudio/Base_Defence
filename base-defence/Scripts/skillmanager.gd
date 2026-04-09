extends Node

# ── Constants ─────────────────────────────────
const KILLS_PER_SHARD_BASE: int = 1000
const MAX_TOKENS: int = 15
const SKILLS_PER_TREE: int = 9

const TREE_BARRAGE: String = "barrage"
const TREE_BULWARK: String = "bulwark"
const TREE_SIPHON: String = "siphon"

const SKILL_DATA = {
	"barrage": [
		{"name": "Rapidfire", "desc": "Every 3rd attack deals bonus damage. Base +20%, +5% per shard level."},
		{"name": "Bleed", "desc": "Critical hits leave a DoT on the target. Scales with Crit Chance."},
		{"name": "Focus", "desc": "Consecutive hits on the same target increase damage. Resets on kill."},
		{"name": "Range", "desc": "Increases bullet detection radius."},
		{"name": "Keystone: Multishot", "desc": "Fires 3 bullets simultaneously. Side shots scale with shard level."},
	],
	"bulwark": [
		{"name": "Fortify", "desc": "Every 100 Max Shield adds bonus damage to attacks."},
		{"name": "Ironclad", "desc": "Current shield % adds bonus damage. More shield uptime = harder hits."},
		{"name": "Zap", "desc": "Every shield regen tick fires a damage instance at nearest enemy."},
		{"name": "Rampart", "desc": "Killing an enemy permanently restores flat shield."},
		{"name": "Keystone: Pulse", "desc": "Replaces bullets with AOE pulse. Damages all enemies in radius on ATK SPD interval."},
	],
	"siphon": [
		{"name": "Vampiric", "desc": "HP Regen Amount adds bonus damage to all attacks."},
		{"name": "Chill", "desc": "Every HP regen tick slows the nearest enemy."},
		{"name": "Overheal", "desc": "Introduces an overheal buffer above max HP based on Max HP investment."},
		{"name": "Surge", "desc": "While in overheal state, deal bonus damage."},
		{"name": "Keystone: Drain Beam", "desc": "Replaces bullets with a continuous beam. Damages and heals simultaneously."},
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
	if count >= 6: return 3
	if count >= 4: return 2
	if count >= 2: return 1
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

# ── Token spending — unlock a skill ───────────
func unlock_skill(tree: String, slot: int) -> bool:
	if get_tokens() <= 0:
		return false
	if SaveManager.data["phase_tokens_earned"] > MAX_TOKENS:
		return false
	if is_skill_unlocked(tree, slot):
		return false
	match slot:
		0:
			pass
		1:
			if not is_skill_unlocked(tree, 0): return false
		2:
			if not is_skill_unlocked(tree, 1): return false
		3:
			if not is_skill_unlocked(tree, 1): return false
		4:
			if not is_skill_unlocked(tree, 2): return false
			if not is_skill_unlocked(tree, 3): return false
			if has_keystone(): return false
		5, 6, 7:
			if not is_skill_unlocked(tree, 4): return false
		8:
			if not is_skill_unlocked(tree, 5): return false
			if not is_skill_unlocked(tree, 6): return false
			if not is_skill_unlocked(tree, 7): return false
	SaveManager.data["skill_" + tree + "_unlocked"].append(slot)
	SaveManager.data["skill_" + tree + "_levels"].append(0)
	SaveManager.data["phase_tokens"] -= 1
	if slot == 4:
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
# Gate on is_skill_unlocked only — level 0 is valid (base effect).
# level == 0 means unlocked but no shards spent, still gives base bonus.
# ══════════════════════════════════════════════

# ── BARRAGE ───────────────────────────────────

# Slot 0 — Rapidfire
# Every 3rd attack deals bonus damage. Base 20%, +5% per shard level.
func barrage_rapidfire_bonus() -> float:
	if not is_skill_unlocked(TREE_BARRAGE, 0): return 0.0
	var level = get_skill_level(TREE_BARRAGE, 0)
	return 0.20 + (level * 0.05)

# Slot 1 — Bleed
# Crit hits apply a DoT. Base 5 dmg/tick, +2 per shard level.
func barrage_bleed_dot() -> float:
	if not is_skill_unlocked(TREE_BARRAGE, 1): return 0.0
	var level = get_skill_level(TREE_BARRAGE, 1)
	return 5.0 + (level * 2.0)

# Slot 2 — Focus
# Consecutive hits on same target ramp damage. Base 3% per hit, +1% per shard level.
func barrage_focus_bonus_per_hit() -> float:
	if not is_skill_unlocked(TREE_BARRAGE, 2): return 0.0
	var level = get_skill_level(TREE_BARRAGE, 2)
	return 0.10 + (level * 0.01)

# Slot 3 — Range
# Bonus detection radius. Base 50px, +25 per shard level.
func barrage_range_bonus() -> float:
	if not is_skill_unlocked(TREE_BARRAGE, 3): return 0.0
	var level = get_skill_level(TREE_BARRAGE, 3)
	return 50.0 + (level * 25.0)

# Slot 4 — Keystone: Multishot
# Side shot damage as % of main shot. Base 20%, +10% per shard level.
func barrage_multishot_side_damage() -> float:
	if not is_skill_unlocked(TREE_BARRAGE, 4): return 0.0
	var level = get_skill_level(TREE_BARRAGE, 4)
	return 0.20 + (level * 0.10)

# ── BULWARK ───────────────────────────────────

# Slot 0 — Fortify
# Bonus damage per 100 max shield. Base 2, +1 per shard level.
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

# Slot 4 — Keystone: Pulse
# Knockback force in pixels. Base 80, +20 per shard level.
func bulwark_knockback_force() -> float:
	if not is_skill_unlocked(TREE_BULWARK, 4): return 0.0
	var level = get_skill_level(TREE_BULWARK, 4)
	return 80.0 + (level * 20.0)

# ── SIPHON ────────────────────────────────────

# Slot 0 — Vampiric
# Bonus damage per 1 HP regen amount. Base 1.0, +0.5 per shard level.
func siphon_vampiric_damage_per_regen() -> float:
	if not is_skill_unlocked(TREE_SIPHON, 0): return 0.0
	var level = get_skill_level(TREE_SIPHON, 0)
	return 1.0 + (level * 0.5)

# Slot 1 — Chill
# Slow % applied on regen tick. Base 10%, +3% per shard level, soft cap 60%.
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
# Damage bonus % while in overheal. Base 15%, +5% per shard level.
func siphon_surge_bonus() -> float:
	if not is_skill_unlocked(TREE_SIPHON, 3): return 0.0
	var level = get_skill_level(TREE_SIPHON, 3)
	return 0.15 + (level * 0.05)

# Slot 4 — Keystone: Drain Beam
# HP restored per drain tick. Base 2, +1 per shard level.
func siphon_vitality_hp_per_kill() -> float:
	if not is_skill_unlocked(TREE_SIPHON, 4): return 0.0
	var level = get_skill_level(TREE_SIPHON, 4)
	return 2.0 + (level * 1.0)
