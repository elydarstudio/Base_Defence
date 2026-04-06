extends Control

const LP_SCALE = 1.4

const COSTS = {
	"WFloorAtkSpd": 10,
	"WFloorDmg": 10,
	"WFloorDmgMult": 20,
	"WFloorCritChance": 15,
	"WFloorCritDmg": 20,
	"WFloorShield": 12,
	"WFloorShieldRegen": 18,
	"WFloorShieldStrength": 15,
	"WFloorShieldMult": 20,
	"WFloorEvasion": 15,
	"WFloorMaxHP": 12,
	"WFloorRegenAmt": 15,
	"WFloorRegenSpd": 15,
	"WFloorHealMult": 20,
	"WFloorHPMult": 20,
	"WFloorGoldPerKill": 8,
	"WFloorGoldMult": 18,
	"WFloorLpPerWave": 8,
	"WFloorLpMult": 18,
	"WFloorLpDrop": 15,
}

const BUTTON_MAP = {
	"WFloorAtkSpd": "floor_attack_speed",
	"WFloorDmg": "floor_damage",
	"WFloorDmgMult": "floor_dmg_mult",
	"WFloorCritChance": "floor_crit_chance",
	"WFloorCritDmg": "floor_crit_dmg",
	"WFloorShield": "floor_shield",
	"WFloorShieldRegen": "floor_shield_regen",
	"WFloorShieldStrength": "floor_shield_strength",
	"WFloorShieldMult": "floor_shield_mult",
	"WFloorEvasion": "floor_evasion",
	"WFloorMaxHP": "floor_max_hp",
	"WFloorRegenAmt": "floor_regen_amt",
	"WFloorRegenSpd": "floor_regen_spd",
	"WFloorHealMult": "floor_heal_mult",
	"WFloorHPMult": "floor_hp_mult",
	"WFloorGoldPerKill": "floor_gold_per_kill",
	"WFloorGoldMult": "floor_gold_mult",
	"WFloorLpPerWave": "floor_legacy_per_wave",
	"WFloorLpMult": "floor_legacy_mult",
	"WFloorLpDrop": "floor_legacy_drop",
}

const STAT_LABELS = {
	"WFloorAtkSpd": ["ATK SPD", "+0.125/s"],
	"WFloorDmg": ["DMG", "+1 dmg"],
	"WFloorDmgMult": ["DMG MULT", "+10%"],
	"WFloorCritChance": ["CRIT %", "+1.25%"],
	"WFloorCritDmg": ["CRIT DMG", "+10%"],
	"WFloorShield": ["SHIELD", "+20"],
	"WFloorShieldRegen": ["SHLD RGN", "+1/s"],
	"WFloorShieldStrength": ["SHLD STR", "+0.4%"],
	"WFloorShieldMult": ["SHLD MULT", "+10%"],
	"WFloorEvasion": ["EVASION", "+0.2%"],
	"WFloorMaxHP": ["MAX HP", "+10"],
	"WFloorRegenAmt": ["REGEN AMT", "+1hp"],
	"WFloorRegenSpd": ["REGEN SPD", "-0.1s"],
	"WFloorHealMult": ["HEAL MULT", "+10%"],
	"WFloorHPMult": ["HP MULT", "+10%"],
	"WFloorGoldPerKill": ["GOLD/KILL", "+1g"],
	"WFloorGoldMult": ["GOLD MULT", "+10%"],
	"WFloorLpPerWave": ["LP/WAVE", "+1"],
	"WFloorLpMult": ["LP MULT", "+10%"],
	"WFloorLpDrop": ["LP CHANCE", "+5%"],
}

const WORKSHOP_UNLOCK_REQUIREMENTS = {
	"WFloorAtkSpd": 0,
	"WFloorDmg": 0,
	"WFloorMaxHP": 1,
	"WFloorRegenAmt": 1,
	"WFloorShield": 2,
	"WFloorShieldRegen": 2,
	"WFloorGoldPerKill": 2,
	"WFloorLpPerWave": 2,
	"WFloorDmgMult": 3,
	"WFloorHPMult": 3,
	"WFloorShieldStrength": 3,
	"WFloorGoldMult": 3,
	"WFloorLpMult": 3,
	"WFloorCritChance": 4,
	"WFloorCritDmg": 4,
	"WFloorRegenSpd": 4,
	"WFloorHealMult": 4,
	"WFloorShieldMult": 4,
	"WFloorEvasion": 4,
	"WFloorLpDrop": 4,
}

func _ready():
	_apply_unlock_level()
	_update_ui()

func _apply_unlock_level():
	var unlock = SaveManager.data["unlock_level"]
	var columns = ["ATKColumn", "DEFColumn", "HPColumn", "UTILColumn"]
	for col in columns:
		var col_node = $CoreContent/ColumnsContainer.get_node(col)
		for child in col_node.get_children():
			if child is Button:
				var required = WORKSHOP_UNLOCK_REQUIREMENTS.get(child.name, 4)
				child.visible = unlock >= required

func _update_ui():
	var lp = SaveManager.data["legacy_points"]
	$LPLabel.text = "Legacy Points: " + str(lp)
	for btn_name in BUTTON_MAP:
		var key = BUTTON_MAP[btn_name]
		var level = SaveManager.data[key]
		var base_cost = COSTS[btn_name]
		var cost = int(base_cost * pow(LP_SCALE, level))
		var label = STAT_LABELS[btn_name][0]
		var per_level = STAT_LABELS[btn_name][1]
		var btn = _find_button(btn_name)
		if btn == null:
			continue
		btn.text = label + "\nLv" + str(level) + " → " + str(level + 1) + "\n" + per_level + " | " + str(cost) + " LP"
		btn.disabled = lp < cost

func _find_button(btn_name: String) -> Button:
	var columns = ["ATKColumn", "DEFColumn", "HPColumn", "UTILColumn"]
	for col in columns:
		var path = "CoreContent/ColumnsContainer/" + col + "/" + btn_name
		if has_node(path):
			return get_node(path)
	return null

func _purchase(btn_name: String):
	var key = BUTTON_MAP[btn_name]
	var level = SaveManager.data[key]
	var base_cost = COSTS[btn_name]
	var cost = int(base_cost * pow(LP_SCALE, level))
	var lp = SaveManager.data["legacy_points"]
	if lp < cost:
		return
	SaveManager.data["legacy_points"] -= cost
	SaveManager.data[key] += 1
	SaveManager.save_game()
	_update_ui()

func _on_core_tab_pressed():
	$CoreContent.visible = true
	$SkillContent.visible = false

func _on_skill_tab_pressed():
	$CoreContent.visible = false
	$SkillContent.visible = true

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/StartMenu.tscn")

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

func _on_w_floor_shield_strength_pressed():
	_purchase("WFloorShieldStrength")

func _on_w_floor_shield_mult_pressed():
	_purchase("WFloorShieldMult")

func _on_w_floor_evasion_pressed():
	_purchase("WFloorEvasion")

func _on_w_floor_max_hp_pressed():
	_purchase("WFloorMaxHP")

func _on_w_floor_regen_amt_pressed():
	_purchase("WFloorRegenAmt")

func _on_w_floor_regen_spd_pressed():
	_purchase("WFloorRegenSpd")

func _on_w_floor_heal_mult_pressed():
	_purchase("WFloorHealMult")

func _on_w_floor_hp_mult_pressed():
	_purchase("WFloorHPMult")

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
