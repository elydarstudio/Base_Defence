extends Control

# LP costs scale steeper than gold — x1.4 per level
const LP_SCALE = 1.4

# Base LP costs per stat
const COSTS = {
	"floor_attack_speed": 10,
	"floor_damage": 10,
	"floor_dmg_mult": 20,
	"floor_crit_chance": 15,
	"floor_crit_dmg": 20,
	"floor_shield": 12,
	"floor_shield_regen": 18,
	"floor_dmg_reduct": 15,
	"floor_kb_freq": 12,
	"floor_kb_str": 12,
	"floor_max_hp": 12,
	"floor_regen_amt": 15,
	"floor_regen_spd": 15,
	"floor_recov_delay": 12,
	"floor_heal_mult": 20,
	"floor_gold_per_kill": 8,
	"floor_gold_mult": 18,
	"floor_legacy_per_wave": 8,
	"floor_legacy_mult": 18,
	"floor_legacy_drop": 15,
}

# Map button node names to save keys
const BUTTON_MAP = {
	"WFloorAtkSpd": "floor_attack_speed",
	"WFloorDmg": "floor_damage",
	"WFloorDmgMult": "floor_dmg_mult",
	"WFloorCritChance": "floor_crit_chance",
	"WFloorCritDmg": "floor_crit_dmg",
	"WFloorShield": "floor_shield",
	"WFloorShieldRegen": "floor_shield_regen",
	"WFloorDmgReduct": "floor_dmg_reduct",
	"WFloorKbFreq": "floor_kb_freq",
	"WFloorKbStr": "floor_kb_str",
	"WFloorMaxHP": "floor_max_hp",
	"WFloorRegenAmt": "floor_regen_amt",
	"WFloorRegenSpd": "floor_regen_spd",
	"WFloorRecovDelay": "floor_recov_delay",
	"WFloorHealMult": "floor_heal_mult",
	"WFloorGoldPerKill": "floor_gold_per_kill",
	"WFloorGoldMult": "floor_gold_mult",
	"WFloorLpPerWave": "floor_legacy_per_wave",
	"WFloorLpMult": "floor_legacy_mult",
	"WFloorLpDrop": "floor_legacy_drop",
}

const STAT_LABELS = {
	"floor_attack_speed": ["ATK SPD", "+0.125/s"],
	"floor_damage": ["DMG", "+1 dmg"],
	"floor_dmg_mult": ["DMG MULT", "+10%"],
	"floor_crit_chance": ["CRIT %", "+5%"],
	"floor_crit_dmg": ["CRIT DMG", "+25%"],
	"floor_shield": ["SHIELD", "+20"],
	"floor_shield_regen": ["SHLD RGN", "+1/s"],
	"floor_dmg_reduct": ["DMG REDUCT", "+2%"],
	"floor_kb_freq": ["KB FREQ", "+1"],
	"floor_kb_str": ["KB STR", "+20"],
	"floor_max_hp": ["MAX HP", "+20"],
	"floor_regen_amt": ["REGEN AMT", "+1hp"],
	"floor_regen_spd": ["REGEN SPD", "-0.1s"],
	"floor_recov_delay": ["RECOV DLY", "-0.15s"],
	"floor_heal_mult": ["HEAL MULT", "+10%"],
	"floor_gold_per_kill": ["GOLD/KILL", "+1g"],
	"floor_gold_mult": ["GOLD MULT", "+10%"],
	"floor_legacy_per_wave": ["LP/WAVE", "+1"],
	"floor_legacy_mult": ["LP MULT", "+10%"],
	"floor_legacy_drop": ["LP CHANCE", "+5%"],
}

func _ready():
	_update_ui()

func _update_ui():
	var lp = SaveManager.data["legacy_points"]
	$LPLabel.text = "Legacy Points: " + str(lp)

	# Update all 20 buttons
	for btn_name in BUTTON_MAP:
		var key = BUTTON_MAP[btn_name]
		var level = SaveManager.data[key]
		var base_cost = COSTS[key]
		var cost = int(base_cost * pow(LP_SCALE, level))
		var label = STAT_LABELS[key][0]
		var per_level = STAT_LABELS[key][1]
		var btn = _find_button(btn_name)
		if btn == null:
			continue
		btn.text = label + "\nLv" + str(level) + " → " + str(level + 1) + "\n" + per_level + " | " + str(cost) + " LP"
		btn.disabled = lp < cost

func _find_button(btn_name: String) -> Button:
	# Search through all columns
	var columns = ["ATKColumn", "DEFColumn", "HPColumn", "UTILColumn"]
	for col in columns:
		var path = "CoreContent/ColumnsContainer/" + col + "/" + btn_name
		if has_node(path):
			return get_node(path)
	return null

func _purchase(btn_name: String):
	var key = BUTTON_MAP[btn_name]
	var level = SaveManager.data[key]
	var base_cost = COSTS[key]
	var cost = int(base_cost * pow(LP_SCALE, level))
	var lp = SaveManager.data["legacy_points"]
	if lp < cost:
		return
	SaveManager.data["legacy_points"] -= cost
	SaveManager.data[key] += 1
	SaveManager.save_game()
	_update_ui()

# ── Tab switching ─────────────────────────────
func _on_core_tab_pressed():
	$CoreContent.visible = true
	$SkillContent.visible = false

func _on_skill_tab_pressed():
	$CoreContent.visible = false
	$SkillContent.visible = true

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/StartMenu.tscn")

# ── Purchase handlers ─────────────────────────
func _on_w_floor_atk_spd_pressed():
	_purchase("WFloorAtkSpd")

func _on_w_floor_dmg_pressed():
	_purchase("WFloorDmg")

func _on_w_floor_dmg_mult_pressed():
	_purchase("WFloorDmgMult")

func _on_w_floor_crit_chance_pressed():
	_purchase("WFloorCritChance")

func _on_w_floor_crit_dmg_pressed():
	_purchase("WFloorCritDmg")

func _on_w_floor_shield_pressed():
	_purchase("WFloorShield")

func _on_w_floor_shield_regen_pressed():
	_purchase("WFloorShieldRegen")

func _on_w_floor_dmg_reduct_pressed():
	_purchase("WFloorDmgReduct")

func _on_w_floor_kb_freq_pressed():
	_purchase("WFloorKbFreq")

func _on_w_floor_kb_str_pressed():
	_purchase("WFloorKbStr")

func _on_w_floor_max_hp_pressed():
	_purchase("WFloorMaxHP")

func _on_w_floor_regen_amt_pressed():
	_purchase("WFloorRegenAmt")

func _on_w_floor_regen_spd_pressed():
	_purchase("WFloorRegenSpd")

func _on_w_floor_recov_delay_pressed():
	_purchase("WFloorRecovDelay")

func _on_w_floor_heal_mult_pressed():
	_purchase("WFloorHealMult")

func _on_w_floor_gold_per_kill_pressed():
	_purchase("WFloorGoldPerKill")

func _on_w_floor_gold_mult_pressed():
	_purchase("WFloorGoldMult")

func _on_w_floor_lp_per_wave_pressed():
	_purchase("WFloorLpPerWave")

func _on_w_floor_lp_mult_pressed():
	_purchase("WFloorLpMult")

func _on_w_floor_lp_drop_pressed():
	_purchase("WFloorLpDrop")
