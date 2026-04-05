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
	"floor_dmg_reduct": 0,
	"floor_kb_freq": 0,
	"floor_kb_str": 0,
	"floor_max_hp": 0,
	"floor_regen_amt": 0,
	"floor_regen_spd": 0,
	"floor_recov_delay": 0,
	"floor_heal_mult": 0,
	"floor_gold_per_kill": 0,
	"floor_gold_mult": 0,
	"floor_legacy_per_wave": 0,
	"floor_legacy_mult": 0,
	"floor_legacy_drop": 0,
	# Phase start
	"max_start_phase": 1,
	"start_phase": 1,
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
		return
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
