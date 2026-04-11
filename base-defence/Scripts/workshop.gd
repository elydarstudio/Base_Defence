extends Control

const COSTS = {
	"WFloorAtkSpd": 8,
	"WFloorDmg": 6,
	"WFloorDmgMult": 12,
	"WFloorCritChance": 14,
	"WFloorCritDmg": 12,
	"WFloorShield": 8,
	"WFloorShieldRegen": 8,
	"WFloorShieldStrength": 12,
	"WFloorShieldMult": 10,
	"WFloorEvasion": 14,
	"WFloorMaxHP": 5,
	"WFloorRegenAmt": 5,
	"WFloorRegenSpd": 6,
	"WFloorHealMult": 8,
	"WFloorHPMult": 10,
	"WFloorGoldPerKill": 6,
	"WFloorGoldMult": 14,
	"WFloorLpGain": 6,
	"WFloorLpMult": 14,
	"WFloorLpDrop": 8,
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
	"WFloorLpGain": "floor_lp_gain",
	"WFloorLpMult": "floor_legacy_mult",
	"WFloorLpDrop": "floor_legacy_drop",
}

const STAT_LABELS = {
	"WFloorAtkSpd": ["ATK SPD", ""],
	"WFloorDmg": ["DMG", "+1 dmg"],
	"WFloorDmgMult": ["DMG MULT", "+10%"],
	"WFloorCritChance": ["CRIT %", "+0.8%"],
	"WFloorCritDmg": ["CRIT DMG", "+10%"],
	"WFloorShield": ["SHIELD", "+20"],
	"WFloorShieldRegen": ["SHLD RGN", ""],
	"WFloorShieldStrength": ["SHLD STR", "+0.4%"],
	"WFloorShieldMult": ["SHLD MULT", "+10%"],
	"WFloorEvasion": ["EVASION", "+0.2%"],
	"WFloorMaxHP": ["MAX HP", "+10"],
	"WFloorRegenAmt": ["REGEN AMT", "+1hp"],
	"WFloorRegenSpd": ["REGEN SPD", ""],
	"WFloorHealMult": ["HEAL MULT", "+10%"],
	"WFloorHPMult": ["HP MULT", "+10%"],
	"WFloorGoldPerKill": ["GOLD/KILL", "+1g"],
	"WFloorGoldMult": ["GOLD MULT", "+5%"],
	"WFloorLpGain": ["LP GAIN", "+1 LP"],
	"WFloorLpMult": ["LP MULT", "+5%"],
	"WFloorLpDrop": ["LP CHANCE", ""],
}

# tier_key -> [save_key, lp_cost]
const TIER_COSTS = {
	"unlock_atk_tier": [25, 75, 200],
	"unlock_def_tier": [25, 75, 200],
	"unlock_hp_tier":  [25, 75, 200],
	"unlock_util_tier": [25, 75, 200],
}

# Which stats are gated by each column's tier (1-indexed tier)
const ATK_TIER = {1: ["WFloorDmgMult"], 2: ["WFloorCritChance"], 3: ["WFloorCritDmg"]}
const DEF_TIER = {1: ["WFloorShieldStrength"], 2: ["WFloorShieldMult"], 3: ["WFloorEvasion"]}
const HP_TIER  = {1: ["WFloorRegenSpd"], 2: ["WFloorHPMult"], 3: ["WFloorHealMult"]}
const UTIL_TIER = {1: ["WFloorLpGain"], 2: ["WFloorGoldMult", "WFloorLpMult"], 3: ["WFloorLpDrop"]}

var tooltip_buttons: Dictionary = {}
var tooltip_key: String = ""

func _ready():
	_apply_tier_visibility()
	_update_ui()
	tooltip_buttons = {
		$CoreContent/ColumnsContainer/ATKColumn/WFloorAtkSpd: "atk_spd",
		$CoreContent/ColumnsContainer/ATKColumn/WFloorDmg: "damage",
		$CoreContent/ColumnsContainer/ATKColumn/WFloorDmgMult: "dmg_mult",
		$CoreContent/ColumnsContainer/ATKColumn/WFloorCritChance: "crit_chance",
		$CoreContent/ColumnsContainer/ATKColumn/WFloorCritDmg: "crit_dmg",
		$CoreContent/ColumnsContainer/DEFColumn/WFloorShield: "shield",
		$CoreContent/ColumnsContainer/DEFColumn/WFloorShieldRegen: "shield_regen",
		$CoreContent/ColumnsContainer/DEFColumn/WFloorShieldStrength: "shield_strength",
		$CoreContent/ColumnsContainer/DEFColumn/WFloorShieldMult: "shield_mult",
		$CoreContent/ColumnsContainer/DEFColumn/WFloorEvasion: "evasion",
		$CoreContent/ColumnsContainer/HPColumn/WFloorMaxHP: "max_hp",
		$CoreContent/ColumnsContainer/HPColumn/WFloorRegenAmt: "regen_amt",
		$CoreContent/ColumnsContainer/HPColumn/WFloorRegenSpd: "regen_spd",
		$CoreContent/ColumnsContainer/HPColumn/WFloorHPMult: "hp_mult",
		$CoreContent/ColumnsContainer/HPColumn/WFloorHealMult: "heal_mult",
		$CoreContent/ColumnsContainer/UTILColumn/WFloorGoldPerKill: "gold_per_kill",
		$CoreContent/ColumnsContainer/UTILColumn/WFloorGoldMult: "gold_mult",
		$CoreContent/ColumnsContainer/UTILColumn/WFloorLpGain: "lp_gain",
		$CoreContent/ColumnsContainer/UTILColumn/WFloorLpMult: "lp_mult",
		$CoreContent/ColumnsContainer/UTILColumn/WFloorLpDrop: "lp_drop",
	}
	for btn in tooltip_buttons:
		var key = tooltip_buttons[btn]
		btn.mouse_entered.connect(func(): _show_tooltip(key))
		btn.mouse_exited.connect(func(): _hide_tooltip())

func _apply_tier_visibility():
	var d = SaveManager.data
	# ATK
	var atk = d["unlock_atk_tier"]
	$CoreContent/ColumnsContainer/ATKColumn/ATKTier1Unlock.visible = atk < 1
	$CoreContent/ColumnsContainer/ATKColumn/WFloorDmgMult.visible = atk >= 1
	$CoreContent/ColumnsContainer/ATKColumn/ATKTier2Unlock.visible = atk >= 1 and atk < 2
	$CoreContent/ColumnsContainer/ATKColumn/WFloorCritChance.visible = atk >= 2
	$CoreContent/ColumnsContainer/ATKColumn/ATKTier3Unlock.visible = atk >= 2 and atk < 3
	$CoreContent/ColumnsContainer/ATKColumn/WFloorCritDmg.visible = atk >= 3
	# DEF
	var def_ = d["unlock_def_tier"]
	$CoreContent/ColumnsContainer/DEFColumn/DEFTier1Unlock.visible = def_ < 1
	$CoreContent/ColumnsContainer/DEFColumn/WFloorShieldStrength.visible = def_ >= 1
	$CoreContent/ColumnsContainer/DEFColumn/DEFTier2Unlock.visible = def_ >= 1 and def_ < 2
	$CoreContent/ColumnsContainer/DEFColumn/WFloorShieldMult.visible = def_ >= 2
	$CoreContent/ColumnsContainer/DEFColumn/DEFTier3Unlock.visible = def_ >= 2 and def_ < 3
	$CoreContent/ColumnsContainer/DEFColumn/WFloorEvasion.visible = def_ >= 3
	# HP
	var hp = d["unlock_hp_tier"]
	$CoreContent/ColumnsContainer/HPColumn/HPTier1Unlock.visible = hp < 1
	$CoreContent/ColumnsContainer/HPColumn/WFloorRegenSpd.visible = hp >= 1
	$CoreContent/ColumnsContainer/HPColumn/HPTier2Unlock.visible = hp >= 1 and hp < 2
	$CoreContent/ColumnsContainer/HPColumn/WFloorHPMult.visible = hp >= 2
	$CoreContent/ColumnsContainer/HPColumn/HPTier3Unlock.visible = hp >= 2 and hp < 3
	$CoreContent/ColumnsContainer/HPColumn/WFloorHealMult.visible = hp >= 3
	# UTIL
	var util = d["unlock_util_tier"]
	$CoreContent/ColumnsContainer/UTILColumn/UTILTier1Unlock.visible = util < 1
	$CoreContent/ColumnsContainer/UTILColumn/WFloorLpGain.visible = util >= 1
	$CoreContent/ColumnsContainer/UTILColumn/UTILTier2Unlock.visible = util >= 1 and util < 2
	$CoreContent/ColumnsContainer/UTILColumn/WFloorGoldMult.visible = util >= 2
	$CoreContent/ColumnsContainer/UTILColumn/WFloorLpMult.visible = util >= 2
	$CoreContent/ColumnsContainer/UTILColumn/UTILTier3Unlock.visible = util >= 2 and util < 3
	$CoreContent/ColumnsContainer/UTILColumn/WFloorLpDrop.visible = util >= 3
	# Update tier unlock button text
	_update_tier_button_text()

func _update_tier_button_text():
	var d = SaveManager.data
	var lp = d["legacy_points"]
	var costs = [25, 75, 200]
	var cols = [
		["unlock_atk_tier", "ATKColumn", ["ATKTier1Unlock", "ATKTier2Unlock", "ATKTier3Unlock"]],
		["unlock_def_tier", "DEFColumn", ["DEFTier1Unlock", "DEFTier2Unlock", "DEFTier3Unlock"]],
		["unlock_hp_tier",  "HPColumn",  ["HPTier1Unlock",  "HPTier2Unlock",  "HPTier3Unlock"]],
		["unlock_util_tier","UTILColumn",["UTILTier1Unlock","UTILTier2Unlock","UTILTier3Unlock"]],
	]
	for col_data in cols:
		var save_key = col_data[0]
		var col_name = col_data[1]
		var btn_names = col_data[2]
		var tier = d[save_key]
		for i in range(3):
			var btn_path = "CoreContent/ColumnsContainer/" + col_name + "/" + btn_names[i]
			if not has_node(btn_path):
				continue
			var btn = get_node(btn_path)
			var cost = costs[i]
			if lp >= cost:
				btn.text = "🔓 Unlock — " + str(cost) + " LP"
				btn.disabled = false
			else:
				btn.text = "🔒 Unlock — " + str(cost) + " LP"
				btn.disabled = true

func _update_ui():
	var lp = SaveManager.data["legacy_points"]
	$LPLabel.text = "Legacy Points: " + str(lp)
	$StatContent/TokenLabel.text = "🔷 Phase Tokens: " + str(SaveManager.data["phase_tokens"]) + " / " + str(SkillManager.MAX_TOKENS)
	$StatContent/ShardLabel.text = "⚡ Phase Shards: " + str(SaveManager.data["phase_shards"])
	$StatContent/KillLabel.text = "☠ Lifetime Kills: " + str(SaveManager.data["lifetime_kills"])
	var d = SaveManager.data

	var levels = {
		"WFloorAtkSpd": d["floor_attack_speed"],
		"WFloorDmg": d["floor_damage"],
		"WFloorDmgMult": d["floor_dmg_mult"],
		"WFloorCritChance": d["floor_crit_chance"],
		"WFloorCritDmg": d["floor_crit_dmg"],
		"WFloorShield": d["floor_shield"],
		"WFloorShieldRegen": d["floor_shield_regen"],
		"WFloorShieldStrength": d["floor_shield_strength"],
		"WFloorShieldMult": d["floor_shield_mult"],
		"WFloorEvasion": d["floor_evasion"],
		"WFloorMaxHP": d["floor_max_hp"],
		"WFloorRegenAmt": d["floor_regen_amt"],
		"WFloorRegenSpd": d["floor_regen_spd"],
		"WFloorHealMult": d["floor_heal_mult"],
		"WFloorHPMult": d["floor_hp_mult"],
		"WFloorGoldPerKill": d["floor_gold_per_kill"],
		"WFloorGoldMult": d["floor_gold_mult"],
		"WFloorLpGain": d["floor_lp_gain"],
		"WFloorLpMult": d["floor_legacy_mult"],
		"WFloorLpDrop": d["floor_legacy_drop"],
	}

	var current_vals = {
		"WFloorAtkSpd": str(snappedf(max(1.0, 5.0 - (pow(levels["WFloorAtkSpd"], 0.6) / pow(100.0, 0.6)) * 4.0), 0.01)) + "s interval" if SkillManager.get_active_keystone() == SkillManager.TREE_BULWARK else str(snappedf(calc_atk_spd(levels["WFloorAtkSpd"]), 0.01)) + "/s",
		"WFloorDmg": str(10 + levels["WFloorDmg"]),
		"WFloorDmgMult": "+" + str(levels["WFloorDmgMult"] * 10) + "%",
		"WFloorCritChance": str(snappedf(levels["WFloorCritChance"] * 0.8, 0.1)) + "%",
		"WFloorCritDmg": str(snappedf(1.5 + (levels["WFloorCritDmg"] * 0.1), 0.01)) + "x",
		"WFloorShield": str(levels["WFloorShield"] * 20),
		"WFloorShieldRegen": str(snappedf(calc_regen_spd(levels["WFloorShieldRegen"]), 0.01)) + "s",
		"WFloorShieldStrength": str(snappedf(50.0 + (levels["WFloorShieldStrength"] * 0.3), 0.1)) + "%",
		"WFloorShieldMult": "+" + str(levels["WFloorShieldMult"] * 10) + "%",
		"WFloorEvasion": str(snappedf(levels["WFloorEvasion"] * 0.2, 0.1)) + "%",
		"WFloorMaxHP": str(100 + (levels["WFloorMaxHP"] * 10)),
		"WFloorRegenAmt": str(levels["WFloorRegenAmt"]) + " hp",
		"WFloorRegenSpd": str(snappedf(calc_regen_spd(levels["WFloorRegenSpd"]), 0.01)) + "s",
		"WFloorHealMult": "+" + str(levels["WFloorHealMult"] * 10) + "%",
		"WFloorHPMult": "+" + str(levels["WFloorHPMult"] * 10) + "%",
		"WFloorGoldPerKill": "+" + str(levels["WFloorGoldPerKill"]) + "g",
		"WFloorGoldMult": "+" + str(levels["WFloorGoldMult"] * 5) + "%",
		"WFloorLpGain": str(1 + levels["WFloorLpGain"]) + " LP",
		"WFloorLpMult": "+" + str(levels["WFloorLpMult"] * 5) + "%",
		"WFloorLpDrop": str(snappedf(calc_drop_chance(levels["WFloorLpDrop"]) * 100, 0.1)) + "%",
	}

	var dynamic_gains = {
		"WFloorAtkSpd": "-" + str(snappedf(max(1.0, 5.0 - (pow(levels["WFloorAtkSpd"], 0.6) / pow(100.0, 0.6)) * 4.0) - max(1.0, 5.0 - (pow(levels["WFloorAtkSpd"] + 1, 0.6) / pow(100.0, 0.6)) * 4.0), 0.001)) + "s" if SkillManager.get_active_keystone() == SkillManager.TREE_BULWARK else "+" + str(snappedf(calc_atk_spd(levels["WFloorAtkSpd"] + 1) - calc_atk_spd(levels["WFloorAtkSpd"]), 0.01)) + "/s",
		"WFloorShieldRegen": "-" + str(snappedf(calc_regen_spd(levels["WFloorShieldRegen"]) - calc_regen_spd(levels["WFloorShieldRegen"] + 1), 0.001)) + "s",
		"WFloorRegenSpd": "-" + str(snappedf(calc_regen_spd(levels["WFloorRegenSpd"]) - calc_regen_spd(levels["WFloorRegenSpd"] + 1), 0.001)) + "s",
		"WFloorLpDrop": "+" + str(snappedf((calc_drop_chance(levels["WFloorLpDrop"] + 1) - calc_drop_chance(levels["WFloorLpDrop"])) * 100, 0.001)) + "%",
	}

	for btn_name in levels:
		var level = levels[btn_name]
		var base_cost = COSTS[btn_name]
		var cost = _calc_lp_cost(base_cost, level)
		var label = STAT_LABELS[btn_name][0]
		var per_level = STAT_LABELS[btn_name][1]
		var current = current_vals[btn_name]
		var btn = _find_button(btn_name)
		if btn == null:
			continue
		var display_per_level = dynamic_gains.get(btn_name, per_level)
		btn.text = label + " (Lv" + str(level) + ")\n" + current + " | " + display_per_level + "\n" + str(cost) + " LP"
		btn.disabled = lp < cost

	_update_tier_button_text()

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
	var cost = _calc_lp_cost(base_cost, level)
	var lp = SaveManager.data["legacy_points"]
	if lp < cost:
		return
	SaveManager.data["legacy_points"] -= cost
	SaveManager.data[key] += 1
	SaveManager.save_game()
	_update_ui()

func _purchase_tier(save_key: String, tier: int):
	var costs = [25, 75, 200]
	var cost = costs[tier - 1]
	var lp = SaveManager.data["legacy_points"]
	if lp < cost:
		return
	if SaveManager.data[save_key] >= tier:
		return
	SaveManager.data["legacy_points"] -= cost
	SaveManager.data[save_key] = tier
	SaveManager.save_game()
	_apply_tier_visibility()
	_update_ui()

func _calc_lp_cost(base: int, level: int) -> int:
	if level < 5:
		return int(base * pow(1.25, level))
	elif level < 15:
		return int(base * pow(1.25, 4) * pow(1.35, level - 4))
	else:
		return int(base * pow(1.25, 4) * pow(1.35, 10) * pow(1.5, level - 14))

func _show_tooltip(key: String):
	tooltip_key = key
	$TooltipTimer.start()

func _hide_tooltip():
	$TooltipTimer.stop()
	$TooltipPanel.visible = false

func _on_tooltip_timer_timeout():
	if tooltip_key != "":
		$TooltipPanel/TooltipLabel.text = TooltipData.TIPS[tooltip_key]
		var mouse = get_viewport().get_mouse_position()
		var panel_width = 400
		var x = mouse.x + 10
		if x + panel_width > get_viewport().get_visible_rect().size.x:
			x = mouse.x - panel_width - 10
		$TooltipPanel.position = Vector2(x, mouse.y - 60)
		$TooltipPanel.visible = true

func _show_tooltip_instant(key: String):
	$TooltipPanel/TooltipLabel.text = TooltipData.TIPS[key]
	var mouse = get_viewport().get_mouse_position()
	var panel_width = 400
	var x = mouse.x + 10
	if x + panel_width > get_viewport().get_visible_rect().size.x:
		x = mouse.x - panel_width - 10
	$TooltipPanel.position = Vector2(x, mouse.y - 60)
	$TooltipPanel.visible = true

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		for btn in tooltip_buttons:
			if btn.get_global_rect().has_point(event.position):
				_show_tooltip_instant(tooltip_buttons[btn])
				return
		_hide_tooltip()

func calc_regen_spd(level: int) -> float:
	var interval = 5.0
	for i in range(level):
		interval -= 0.25 / (1.0 + i * 0.05)
	return max(0.5, interval)

func calc_drop_chance(level: int) -> float:
	var chance = 0.10
	for i in range(level):
		chance += 0.008 / (1.0 + i * 0.03)
	return min(0.60, chance)

func calc_atk_spd(level: int) -> float:
	var rate = 1.0
	for i in range(level):
		rate += 0.115 / (1.0 + i * 0.008)
	return rate

func _on_core_tab_pressed():
	$CoreContent.visible = true
	$SkillContent.visible = false

func _on_skill_tab_pressed():
	$CoreContent.visible = false
	$SkillContent.visible = true

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/startmenu.tscn")

# ── Stat purchase handlers ─────────────────────
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

func _on_w_floor_lp_gain_pressed():
	_purchase("WFloorLpGain")

func _on_w_floor_lp_mult_pressed():
	_purchase("WFloorLpMult")

func _on_w_floor_lp_drop_pressed():
	_purchase("WFloorLpDrop")

# ── Tier unlock handlers ───────────────────────
func _on_atk_tier1_unlock_pressed():
	_purchase_tier("unlock_atk_tier", 1)

func _on_atk_tier2_unlock_pressed():
	_purchase_tier("unlock_atk_tier", 2)

func _on_atk_tier3_unlock_pressed():
	_purchase_tier("unlock_atk_tier", 3)

func _on_def_tier1_unlock_pressed():
	_purchase_tier("unlock_def_tier", 1)

func _on_def_tier2_unlock_pressed():
	_purchase_tier("unlock_def_tier", 2)

func _on_def_tier3_unlock_pressed():
	_purchase_tier("unlock_def_tier", 3)

func _on_hp_tier1_unlock_pressed():
	_purchase_tier("unlock_hp_tier", 1)

func _on_hp_tier2_unlock_pressed():
	_purchase_tier("unlock_hp_tier", 2)

func _on_hp_tier3_unlock_pressed():
	_purchase_tier("unlock_hp_tier", 3)

func _on_util_tier1_unlock_pressed():
	_purchase_tier("unlock_util_tier", 1)

func _on_util_tier2_unlock_pressed():
	_purchase_tier("unlock_util_tier", 2)

func _on_util_tier3_unlock_pressed():
	_purchase_tier("unlock_util_tier", 3)
