extends Node

const SAVE_PATH = "user://phasefall_save.cfg"

var data = {
	"unlock_level": 0,
	"legacy_points": 0,
	"best_phase": 0,
	# Workshop floors
	"floor_attack_speed": 0,
	"floor_damage": 0,
	"floor_dmg_mult": 0,
	"floor_crit_chance": 0,
	"floor_crit_dmg": 0,
	"floor_shield": 0,
	"floor_shield_regen": 0,
	"floor_shield_strength": 0,
	"floor_shield_mult": 0,
	"floor_evasion": 0,
	"floor_max_hp": 0,
	"floor_regen_amt": 0,
	"floor_regen_spd": 0,
	"floor_hp_mult": 0,
	"floor_heal_mult": 0,
	"floor_gold_per_kill": 0,
	"floor_gold_mult": 0,
	"floor_lp_gain": 0,  # replaces floor_legacy_per_wave
	"floor_legacy_mult": 0,
	"floor_legacy_drop": 0,
	# Phase start
	"max_start_phase": 1,
	"start_phase": 1,
	# Skill currencies
"phase_tokens": 0,
"phase_tokens_earned": 0,
"phase_shards": 0,
"phase_shards_earned": 0,
"lifetime_kills": 0,

# Unlocked skills (which slot indices are unlocked, 0-based)
"skill_barrage_unlocked": [],
"skill_bulwark_unlocked": [],
"skill_siphon_unlocked": [],

# Skill levels (level per slot, index matches unlocked array)
"skill_barrage_levels": [],
"skill_bulwark_levels": [],
"skill_siphon_levels": [],

# Active keystone
"active_keystone": "",
}



func _ready():
	load_game()

func save_game():
	var config = ConfigFile.new()
	for key in data:
		config.set_value("save", key, data[key])
	config.save(SAVE_PATH)

func load_game():
	var config = ConfigFile.new()
	
	if config.load(SAVE_PATH) != OK:
		print("No save found, creating new one")
		save_game()
		# DO NOT RETURN — let the game continue with defaults
	
	for key in data:
		if config.has_section_key("save", key):
			data[key] = config.get_value("save", key)

func reset_save():
	for key in data:
		data[key] = 0
	data["max_start_phase"] = 1
	data["start_phase"] = 1
	data["best_phase"] = 1
	save_game()
