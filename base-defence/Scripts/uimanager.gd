extends Node

var main: Node = null
var base: Node = null

func setup(main_node: Node, base_node: Node):
	main = main_node
	base = base_node

# ── Main UI Update ────────────────────────────
func update_ui():
	main.get_node("UI/CurrencyLabel").text = "💰 " + str(main.currency) + "  |  ⭐ " + str(main.run_lp)
	main.get_node("UI/WaveLabel").text = "Wave: " + str(main.wave) + " | Phase: " + str(main.phase)
	var atk_spd_display: String
	if SkillManager.get_active_keystone() == SkillManager.TREE_BULWARK:
		var level = main.attack_speed_level
		var interval = max(1.0, 5.0 - (pow(level, 0.6) / pow(100.0, 0.6)) * 4.0)
		atk_spd_display = str(snappedf(interval, 0.01)) + "s interval"
	else:
		atk_spd_display = str(snappedf(base.fire_rate, 0.01)) + "/s"
	_update_btn(main.get_node("UI/UpgradePanel/ColumnsContainer/ATKColumn/ATKSpdButton"),
		"ATK SPD", main.attack_speed_level, main.attack_speed_max, main.attack_speed_cost,
		atk_spd_display)
	_update_btn(main.get_node("UI/UpgradePanel/ColumnsContainer/ATKColumn/DmgButton"),
		"DMG", main.damage_level, main.damage_max, main.damage_cost,
		str(10 + main.damage_level))
	_update_btn(main.get_node("UI/UpgradePanel/ColumnsContainer/ATKColumn/DmgMultButton"),
		"DMG MULT", main.dmg_mult_level, main.dmg_mult_max, main.dmg_mult_cost,
		"+" + str(main.dmg_mult_level * 10) + "%")
	_update_btn(main.get_node("UI/UpgradePanel/ColumnsContainer/ATKColumn/CritChanceButton"),
		"CRIT %", main.crit_chance_level, main.crit_chance_max, main.crit_chance_cost,
		str(snappedf(main.crit_chance_level * 0.8, 0.1)) + "%")
	_update_btn(main.get_node("UI/UpgradePanel/ColumnsContainer/ATKColumn/CritDmgButton"),
		"CRIT DMG", main.crit_dmg_level, main.crit_dmg_max, main.crit_dmg_cost,
		"+" + str(main.crit_dmg_level * 10) + "%")
	_update_btn(main.get_node("UI/UpgradePanel/ColumnsContainer/DEFColumn/ShieldButton"),
		"SHIELD", main.shield_level, main.shield_max, main.shield_cost,
		str(main.shield_level * 20))
	_update_btn(main.get_node("UI/UpgradePanel/ColumnsContainer/DEFColumn/ShieldRegenButton"),
		"SHLD RGN", main.shield_regen_level, main.shield_regen_max, main.shield_regen_cost,
		str(snappedf(main.get_node("UpgradeManager").calc_regen_spd(main.shield_regen_level), 0.01)) + "s")
	_update_btn(main.get_node("UI/UpgradePanel/ColumnsContainer/DEFColumn/ShieldStrengthButton"),
		"SHLD STR", main.shield_strength_level, main.shield_strength_max, main.shield_strength_cost,
		str(snappedf(50.0 + (main.shield_strength_level * 0.3), 0.1)) + "%")
	_update_btn(main.get_node("UI/UpgradePanel/ColumnsContainer/DEFColumn/ShieldMultButton"),
		"SHLD MULT", main.shield_mult_level, main.shield_mult_max, main.shield_mult_cost,
		"+" + str(main.shield_mult_level * 10) + "%")
	_update_btn(main.get_node("UI/UpgradePanel/ColumnsContainer/DEFColumn/EvasionButton"),
		"EVASION", main.evasion_level, main.evasion_max, main.evasion_cost,
		str(snappedf(main.evasion_level * 0.2, 0.1)) + "%")
	_update_btn(main.get_node("UI/UpgradePanel/ColumnsContainer/HPColumn/MaxHPButton"),
		"MAX HP", main.max_hp_level, main.max_hp_max, main.max_hp_cost,
		str(100 + (main.max_hp_level * 10)))
	_update_btn(main.get_node("UI/UpgradePanel/ColumnsContainer/HPColumn/RegenAmtButton"),
		"REGEN AMT", main.regen_amt_level, main.regen_amt_max, main.regen_amt_cost,
		str(main.regen_amt_level) + " hp")
	_update_btn(main.get_node("UI/UpgradePanel/ColumnsContainer/HPColumn/RegenSpdButton"),
		"REGEN SPD", main.regen_spd_level, main.regen_spd_max, main.regen_spd_cost,
		str(snappedf(main.get_node("UpgradeManager").calc_regen_spd(main.regen_spd_level), 0.01)) + "s")
	_update_btn(main.get_node("UI/UpgradePanel/ColumnsContainer/HPColumn/HPMultButton"),
		"HP MULT", main.hp_mult_level, main.hp_mult_max, main.hp_mult_cost,
		"+" + str(main.hp_mult_level * 10) + "%")
	_update_btn(main.get_node("UI/UpgradePanel/ColumnsContainer/HPColumn/HealMultButton"),
		"HEAL MULT", main.heal_mult_level, main.heal_mult_max, main.heal_mult_cost,
		"+" + str(main.heal_mult_level * 10) + "%")
	_update_btn(main.get_node("UI/UpgradePanel/ColumnsContainer/UTILColumn/GoldPerKillButton"),
		"GOLD/KILL", main.gold_per_kill_level, main.gold_per_kill_max, main.gold_per_kill_cost,
		"+" + str(main.gold_per_kill_level) + "g")
	_update_btn(main.get_node("UI/UpgradePanel/ColumnsContainer/UTILColumn/GoldMultButton"),
		"GOLD MULT", main.gold_mult_level, main.gold_mult_max, main.gold_mult_cost,
		"+" + str(main.gold_mult_level * 5) + "%")
	_update_btn(main.get_node("UI/UpgradePanel/ColumnsContainer/UTILColumn/LPGainButton"),
		"LP GAIN", main.lp_gain_level, main.lp_gain_max, main.lp_gain_cost,
		"+" + str(main.lp_gain_level) + " LP")
	_update_btn(main.get_node("UI/UpgradePanel/ColumnsContainer/UTILColumn/LegacyMultButton"),
		"LP MULT", main.legacy_mult_level, main.legacy_mult_max, main.legacy_mult_cost,
		"+" + str(main.legacy_mult_level * 5) + "%")
	_update_btn(main.get_node("UI/UpgradePanel/ColumnsContainer/UTILColumn/LegacyDropButton"),
		"LP CHANCE", main.legacy_drop_level, main.legacy_drop_max, main.legacy_drop_cost,
		str(snappedf(main.get_node("EconomyManager").calc_drop_chance(main.legacy_drop_level) * 100, 0.1)) + "%")

func _update_btn(btn: Button, label: String, level: int, max_level: int, cost: int, stat: String):
	if level >= max_level:
		btn.text = label + "\nMAX (" + stat + ")"
		btn.disabled = true
	else:
		btn.text = label + "\nLv" + str(level + 1) + " - " + str(cost) + "g\n" + stat
		btn.disabled = main.currency < cost

# ── Tier Visibility ───────────────────────────
func apply_tier_visibility():
	var d = SaveManager.data
	var panel = main.get_node("UI/UpgradePanel/ColumnsContainer")
	# ATK
	var atk = d["unlock_atk_tier"]
	panel.get_node("ATKColumn/DmgMultButton").visible = atk >= 1
	panel.get_node("ATKColumn/CritChanceButton").visible = atk >= 2
	panel.get_node("ATKColumn/CritDmgButton").visible = atk >= 3

	# DEF
	var def_ = d["unlock_def_tier"]
	panel.get_node("DEFColumn/ShieldStrengthButton").visible = def_ >= 1
	panel.get_node("DEFColumn/ShieldMultButton").visible = def_ >= 2
	panel.get_node("DEFColumn/EvasionButton").visible = def_ >= 3

	# HP
	var hp = d["unlock_hp_tier"]
	panel.get_node("HPColumn/RegenSpdButton").visible = hp >= 1
	panel.get_node("HPColumn/HPMultButton").visible = hp >= 2
	panel.get_node("HPColumn/HealMultButton").visible = hp >= 3

	# UTIL
	var util = d["unlock_util_tier"]
	panel.get_node("UTILColumn/LPGainButton").visible = util >= 1
	panel.get_node("UTILColumn/GoldMultButton").visible = util >= 2
	panel.get_node("UTILColumn/LegacyMultButton").visible = util >= 2
	panel.get_node("UTILColumn/LegacyDropButton").visible = util >= 3

# ── Screen Flash ──────────────────────────────
func flash_screen(color: Color, alpha: float = 0.3, duration: float = 0.4):
	var flash = main.get_node("UI/ScreenFlash")
	flash.color = color
	flash.modulate.a = alpha
	var tween = main.create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, duration)

func wave_complete_flash():
	flash_screen(Color(0.2, 1.0, 0.3), 0.05, 0.6)

func boss_spawn_flash():
	flash_screen(Color(0.6, 0.0, 0.8), 0.5, 0.8)

# ── Tooltip ───────────────────────────────────
func show_tooltip(key: String):
	main.tooltip_key = key
	main.get_node("UI/TooltipTimer").start()

func hide_tooltip():
	main.get_node("UI/TooltipTimer").stop()
	main.get_node("UI/TooltipPanel").visible = false

func on_tooltip_timer_timeout():
	if main.tooltip_key != "":
		main.get_node("UI/TooltipPanel/TooltipLabel").text = TooltipData.TIPS[main.tooltip_key]
		var mouse = main.get_viewport().get_mouse_position()
		var panel_width = 400
		var x = mouse.x + 10
		if x + panel_width > main.get_viewport().get_visible_rect().size.x:
			x = mouse.x - panel_width - 10
		main.get_node("UI/TooltipPanel").position = Vector2(x, mouse.y - 60)
		main.get_node("UI/TooltipPanel").visible = true

func show_tooltip_instant(key: String):
	main.get_node("UI/TooltipPanel/TooltipLabel").text = TooltipData.TIPS[key]
	var mouse = main.get_viewport().get_mouse_position()
	var panel_width = 400
	var x = mouse.x + 10
	if x + panel_width > main.get_viewport().get_visible_rect().size.x:
		x = mouse.x - panel_width - 10
	main.get_node("UI/TooltipPanel").position = Vector2(x, mouse.y - 60)
	main.get_node("UI/TooltipPanel").visible = true
