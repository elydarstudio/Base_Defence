extends Node

# ── Constants ─────────────────────────────────
const KILLS_PER_SHARD_BASE: int = 1000
const MAX_TOKENS: int = 15
const SKILLS_PER_TREE: int = 9  # slots 0-8, slot 4 = keystone, slot 8 = capstone

const TREE_BARRAGE: String = "barrage"
const TREE_BULWARK: String = "bulwark"
const TREE_SIPHON: String = "siphon"

const SKILL_DATA = {
	"barrage": [
		{"name": "Rapidfire", "desc": "Every 3rd bullet deals bonus damage. Scales with DMG."},
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
	var levels = SaveManager.data["skill_" + tree + "_levels"]
	if slot < levels.size():
		return levels[slot]
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

# ── Visual tier helper (for tower visuals later) ──
# Returns 0-4 based on how many skills unlocked in tree
# 0 = none, 1 = tier1 (2 skills), 2 = tier2 (4), 3 = keystone (6), 4 = capstone (10)
func get_visual_tier(tree: String) -> int:
	var count = get_tree_skill_count(tree)
	if count >= 10: return 4
	if count >= 6: return 3
	if count >= 4: return 2
	if count >= 2: return 1
	return 0

# ── Token earning ──────────────────────────────
# Call this from main.gd on_boss_killed()
# Phase Tokens earned from phase 3 boss onward
func on_boss_killed(phase: int):
	if phase < 3:
		return
	if SaveManager.data["phase_tokens_earned"] >= MAX_TOKENS:
		return
	SaveManager.data["phase_tokens"] += 1
	SaveManager.data["phase_tokens_earned"] += 1
	SaveManager.save_game()

# ── Shard earning ──────────────────────────────
# Call this from main.gd add_currency() on every kill
# Returns how many shards were earned this kill (0 or more)
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

# Shard threshold scales up over time
# Base 1000, +100 per shard already earned (soft scaling)
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
	# Slot-specific prerequisite check
	match slot:
		0:
			pass # always available
		1:
			if not is_skill_unlocked(tree, 0): return false
		2:
			if not is_skill_unlocked(tree, 1): return false
		3:
			if not is_skill_unlocked(tree, 1): return false
		4: # Keystone
			if not is_skill_unlocked(tree, 2): return false
			if not is_skill_unlocked(tree, 3): return false
			if has_keystone(): return false
		5, 6, 7: # Skills 7-9
			if not is_skill_unlocked(tree, 4): return false
		8: # Capstone
			if not is_skill_unlocked(tree, 5): return false
			if not is_skill_unlocked(tree, 6): return false
			if not is_skill_unlocked(tree, 7): return false
	# All checks passed
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
	# Find the index in the levels array
	var unlocked = SaveManager.data["skill_" + tree + "_unlocked"]
	var idx = unlocked.find(slot)
	if idx == -1:
		return false
	SaveManager.data["skill_" + tree + "_levels"][idx] += 1
	SaveManager.data["phase_shards"] -= 1
	SaveManager.save_game()
	return true

# ── Respec — reallocate all tokens ────────────
# Cost TBD — for now just resets, LP cost will be added later
func respec(tree: String):
	var unlocked = SaveManager.data["skill_" + tree + "_unlocked"]
	var refund = unlocked.size()
	SaveManager.data["phase_tokens"] += refund
	SaveManager.data["skill_" + tree + "_unlocked"] = []
	SaveManager.data["skill_" + tree + "_levels"] = []
	if SaveManager.data["active_keystone"] == tree:
		SaveManager.data["active_keystone"] = ""
	SaveManager.save_game()

# ── Skill effect queries ───────────────────────
# These are what game systems read to apply skill effects.
# Returns 0.0 if skill not unlocked or level 0.

# BARRAGE
func barrage_rapidfire_bonus() -> float:
	# Every 3rd bullet deals X% bonus — X scales with shard level
	# Base 20%, +5% per shard level
	var level = get_skill_level(TREE_BARRAGE, 0)
	if level == 0 or not is_skill_unlocked(TREE_BARRAGE, 0): return 0.0
	return 0.20 + (level * 0.05)

func barrage_bleed_dot() -> float:
	# DoT damage per tick — scales with shard level
	# Base 5 damage, +2 per level
	var level = get_skill_level(TREE_BARRAGE, 1)
	if level == 0 or not is_skill_unlocked(TREE_BARRAGE, 1): return 0.0
	return 5.0 + (level * 2.0)

func barrage_focus_bonus_per_hit() -> float:
	# Consecutive hit damage ramp — % per hit
	# Base 3%, +1% per level
	var level = get_skill_level(TREE_BARRAGE, 2)
	if level == 0 or not is_skill_unlocked(TREE_BARRAGE, 2): return 0.0
	return 0.03 + (level * 0.01)

func barrage_range_bonus() -> float:
	# Bonus detection radius — flat pixels
	# Base 50px, +25 per level
	var level = get_skill_level(TREE_BARRAGE, 3)
	if level == 0 or not is_skill_unlocked(TREE_BARRAGE, 3): return 0.0
	return 50.0 + (level * 25.0)

func barrage_momentum_bonus_per_pixel() -> float:
	# Bonus damage % per pixel traveled
	# Base 0.05%, +0.02% per level
	var level = get_skill_level(TREE_BARRAGE, 4)
	if level == 0 or not is_skill_unlocked(TREE_BARRAGE, 4): return 0.0
	return 0.0005 + (level * 0.0002)

# BULWARK
func bulwark_fortify_damage_per_100_shield() -> float:
	# Bonus damage per 100 max shield
	# Base 2, +1 per level
	var level = get_skill_level(TREE_BULWARK, 0)
	if level == 0 or not is_skill_unlocked(TREE_BULWARK, 0): return 0.0
	return 2.0 + (level * 1.0)

func bulwark_ironclad_max_bonus() -> float:
	# Max bonus damage % at full shield
	# Base 15%, +5% per level
	var level = get_skill_level(TREE_BULWARK, 1)
	if level == 0 or not is_skill_unlocked(TREE_BULWARK, 1): return 0.0
	return 0.15 + (level * 0.05)

func bulwark_zap_damage() -> float:
	# Damage per zap on shield regen tick
	# Base 8, +3 per level
	var level = get_skill_level(TREE_BULWARK, 2)
	if level == 0 or not is_skill_unlocked(TREE_BULWARK, 2): return 0.0
	return 8.0 + (level * 3.0)

func bulwark_rampart_shield_per_kill() -> float:
	# Shield restored per kill
	# Base 3, +1 per level
	var level = get_skill_level(TREE_BULWARK, 3)
	if level == 0 or not is_skill_unlocked(TREE_BULWARK, 3): return 0.0
	return 3.0 + (level * 1.0)

func bulwark_knockback_force() -> float:
	# Knockback force in pixels
	# Base 80, +20 per level
	var level = get_skill_level(TREE_BULWARK, 4)
	if level == 0 or not is_skill_unlocked(TREE_BULWARK, 4): return 0.0
	return 80.0 + (level * 20.0)

# SIPHON
func siphon_vampiric_damage_per_regen() -> float:
	# Bonus damage per 1 HP regen amount
	# Base 1.0, +0.5 per level
	var level = get_skill_level(TREE_SIPHON, 0)
	if level == 0 or not is_skill_unlocked(TREE_SIPHON, 0): return 0.0
	return 1.0 + (level * 0.5)

func siphon_chill_slow() -> float:
	# Slow % applied on regen tick
	# Base 10%, +3% per level, soft cap at 60%
	var level = get_skill_level(TREE_SIPHON, 1)
	if level == 0 or not is_skill_unlocked(TREE_SIPHON, 1): return 0.0
	return min(0.60, 0.10 + (level * 0.03))

func siphon_overheal_buffer() -> float:
	# Overheal buffer as % of max HP
	# Base 10%, +3% per level
	var level = get_skill_level(TREE_SIPHON, 2)
	if level == 0 or not is_skill_unlocked(TREE_SIPHON, 2): return 0.0
	return 0.10 + (level * 0.03)

func siphon_surge_bonus() -> float:
	# Damage bonus % while in overheal
	# Base 15%, +5% per level
	var level = get_skill_level(TREE_SIPHON, 3)
	if level == 0 or not is_skill_unlocked(TREE_SIPHON, 3): return 0.0
	return 0.15 + (level * 0.05)

func siphon_vitality_hp_per_kill() -> float:
	# HP restored per kill
	# Base 2, +1 per level
	var level = get_skill_level(TREE_SIPHON, 4)
	if level == 0 or not is_skill_unlocked(TREE_SIPHON, 4): return 0.0
	return 2.0 + (level * 1.0)
