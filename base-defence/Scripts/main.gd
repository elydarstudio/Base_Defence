extends Node2D

# ── Scenes ────────────────────────────────────
var bullet_scene = preload("res://Scenes/projectile.tscn")
var damage_number_scene = preload("res://Scenes/damage_number.tscn")

# ── Game Speed ────────────────────────────────
var speed_index: int = 0
var speed_steps: Array = [1.0, 1.5, 2.0]

# ── Spawn ─────────────────────────────────────
var enemies_to_spawn: int = 0
var enemies_spawned: int = 0
var wave_complete: bool = false

# ── Progress ──────────────────────────────────
var wave: int = 1
var phase: int = 1
var difficulty: int = 0
var enemies_killed: int = 0
var game_over: bool = false
var boss_wave: bool = false
var boss_alive: bool = false

# ── Economy ───────────────────────────────────
var currency: int = 0
var run_lp: int = 0

# ── UI State ──────────────────────────────────
var panel_open: bool = false
var buy_amount: int = 1
var tooltip_buttons: Dictionary = {}
var tooltip_key: String = ""
var zoom_level: float = 0.6
const ZOOM_MIN: float = 0.4
const ZOOM_MAX: float = 1.0
const ZOOM_STEP: float = 0.1

# ── Wave Constants ────────────────────────────
const BASE_ENEMIES_PER_WAVE = 12
const ENEMIES_PER_WAVE_WAVE_SCALING: float = 1.35
const ENEMIES_PER_WAVE_PHASE_SCALING = 2

# ── ATK Stats ─────────────────────────────────
var attack_speed_level: int = 0
var attack_speed_cost: int = 45
var attack_speed_max: int = 100
var attack_speed_upgrades: int = 0

var damage_level: int = 0
var damage_cost: int = 30
var damage_max: int = 999
var damage_upgrades: int = 0

var dmg_mult_level: int = 0
var dmg_mult_cost: int = 45
var dmg_mult_max: int = 999
var dmg_mult_upgrades: int = 0

var crit_chance_level: int = 0
var crit_chance_cost: int = 50
var crit_chance_max: int = 100
var crit_chance_upgrades: int = 0

var crit_dmg_level: int = 0
var crit_dmg_cost: int = 40
var crit_dmg_max: int = 999
var crit_dmg_upgrades: int = 0

# ── DEF Stats ─────────────────────────────────
var shield_level: int = 0
var shield_cost: int = 28
var shield_max: int = 999
var shield_upgrades: int = 0

var shield_regen_level: int = 0
var shield_regen_cost: int = 35
var shield_regen_max: int = 100
var shield_regen_upgrades: int = 0

var shield_strength_level: int = 0
var shield_strength_cost: int = 45
var shield_strength_max: int = 100
var shield_strength_upgrades: int = 0

var shield_mult_level: int = 0
var shield_mult_cost: int = 35
var shield_mult_max: int = 999
var shield_mult_upgrades: int = 0

var evasion_level: int = 0
var evasion_cost: int = 50
var evasion_max: int = 100
var evasion_upgrades: int = 0

# ── HP Stats ──────────────────────────────────
var max_hp_level: int = 0
var max_hp_cost: int = 22
var max_hp_max: int = 999
var max_hp_upgrades: int = 0

var regen_amt_level: int = 0
var regen_amt_cost: int = 18
var regen_amt_max: int = 999
var regen_amt_upgrades: int = 0

var regen_spd_level: int = 0
var regen_spd_cost: int = 25
var regen_spd_max: int = 100
var regen_spd_upgrades: int = 0

var hp_mult_level: int = 0
var hp_mult_cost: int = 35
var hp_mult_max: int = 999
var hp_mult_upgrades: int = 0

var heal_mult_level: int = 0
var heal_mult_cost: int = 30
var heal_mult_max: int = 999
var heal_mult_upgrades: int = 0

# ── UTIL Stats ────────────────────────────────
var gold_per_kill_level: int = 0
var gold_per_kill_cost: int = 22
var gold_per_kill_max: int = 999
var gold_per_kill_upgrades: int = 0

var gold_mult_level: int = 0
var gold_mult_cost: int = 50
var gold_mult_max: int = 999
var gold_mult_upgrades: int = 0

var lp_gain_level: int = 0
var lp_gain_cost: int = 22
var lp_gain_max: int = 999
var lp_gain_upgrades: int = 0

var legacy_mult_level: int = 0
var legacy_mult_cost: int = 50
var legacy_mult_max: int = 999
var legacy_mult_upgrades: int = 0

var legacy_drop_level: int = 0
var legacy_drop_cost: int = 35
var legacy_drop_max: int = 100
var legacy_drop_upgrades: int = 0

# ── Unlock Requirements ───────────────────────
const UNLOCK_REQUIREMENTS = {
	"ATKSpdButton": 0,
	"DmgButton": 0,
	"MaxHPButton": 1,
	"RegenAmtButton": 1,
	"ShieldButton": 2,
	"ShieldRegenButton": 2,
	"GoldPerKillButton": 2,
	"LPGainButton": 2,
	"DmgMultButton": 1,
	"HPMultButton": 3,
	"ShieldStrengthButton": 3,
	"GoldMultButton": 3,
	"LegacyMultButton": 3,
	"CritChanceButton": 4,
	"CritDmgButton": 4,
	"RegenSpdButton": 4,
	"HealMultButton": 4,
	"ShieldMultButton": 4,
	"EvasionButton": 4,
	"LegacyDropButton": 4,
	"DEFLocked": 999,
	"HPLocked": 999,
	"UTILLocked": 999,
}

# ── Ready ─────────────────────────────────────
func _ready():
	phase = SaveManager.data.get("start_phase", 1)
	difficulty = (phase - 1) * 10
	$Base.set_bullet_scene(bullet_scene)
	$Base.set_main(self)
	$EconomyManager.setup(self)
	$UpgradeManager.setup(self, $Base)
	$UpgradeManager.apply_workshop_floors()
	$UIManager.setup(self, $Base)
	$UIManager.apply_unlock_level()
	$SpawnManager.setup(self)
	enemies_to_spawn = $SpawnManager.get_wave_enemy_count()
	tooltip_buttons = {
		$UI/UpgradePanel/ColumnsContainer/ATKColumn/ATKSpdButton: "atk_spd",
		$UI/UpgradePanel/ColumnsContainer/ATKColumn/DmgButton: "damage",
		$UI/UpgradePanel/ColumnsContainer/ATKColumn/DmgMultButton: "dmg_mult",
		$UI/UpgradePanel/ColumnsContainer/ATKColumn/CritChanceButton: "crit_chance",
		$UI/UpgradePanel/ColumnsContainer/ATKColumn/CritDmgButton: "crit_dmg",
		$UI/UpgradePanel/ColumnsContainer/DEFColumn/ShieldButton: "shield",
		$UI/UpgradePanel/ColumnsContainer/DEFColumn/ShieldRegenButton: "shield_regen",
		$UI/UpgradePanel/ColumnsContainer/DEFColumn/ShieldStrengthButton: "shield_strength",
		$UI/UpgradePanel/ColumnsContainer/DEFColumn/ShieldMultButton: "shield_mult",
		$UI/UpgradePanel/ColumnsContainer/DEFColumn/EvasionButton: "evasion",
		$UI/UpgradePanel/ColumnsContainer/HPColumn/MaxHPButton: "max_hp",
		$UI/UpgradePanel/ColumnsContainer/HPColumn/RegenAmtButton: "regen_amt",
		$UI/UpgradePanel/ColumnsContainer/HPColumn/RegenSpdButton: "regen_spd",
		$UI/UpgradePanel/ColumnsContainer/HPColumn/HPMultButton: "hp_mult",
		$UI/UpgradePanel/ColumnsContainer/HPColumn/HealMultButton: "heal_mult",
		$UI/UpgradePanel/ColumnsContainer/UTILColumn/GoldPerKillButton: "gold_per_kill",
		$UI/UpgradePanel/ColumnsContainer/UTILColumn/GoldMultButton: "gold_mult",
		$UI/UpgradePanel/ColumnsContainer/UTILColumn/LPGainButton: "lp_gain",
		$UI/UpgradePanel/ColumnsContainer/UTILColumn/LegacyMultButton: "lp_mult",
		$UI/UpgradePanel/ColumnsContainer/UTILColumn/LegacyDropButton: "lp_drop",
	}
	for btn in tooltip_buttons:
		var key = tooltip_buttons[btn]
		btn.mouse_entered.connect(func(): $UIManager.show_tooltip(key))
		btn.mouse_exited.connect(func(): $UIManager.hide_tooltip())
	_update_ui()

# ── Process ───────────────────────────────────
func _process(delta):
	if game_over or boss_wave or wave_complete:
		return
	$SpawnManager.tick(delta)

# ── Wave Progression ──────────────────────────
func on_enemy_killed():
	if enemies_spawned >= enemies_to_spawn and not boss_wave:
		var remaining = get_tree().get_nodes_in_group("enemies").size()
		if remaining <= 1:
			wave_complete = true
			_advance_wave()

func _advance_wave():
	wave += 1
	difficulty += 1
	enemies_spawned = 0
	enemies_to_spawn = $SpawnManager.get_wave_enemy_count()
	wave_complete = false
	if wave % 10 != 0:
		$UIManager.wave_complete_flash()
	_check_unlock_progression()
	var lp_total = $EconomyManager.calc_wave_lp(lp_gain_level, legacy_mult_level)
	run_lp += lp_total
	SaveManager.data["legacy_points"] += lp_total
	SaveManager.save_game()
	if wave % 10 == 0:
		$SpawnManager.spawn_boss()
	else:
		_update_ui()

func on_boss_killed():
	boss_alive = false
	boss_wave = false
	wave += 1
	phase += 1
	difficulty += int(pow(phase, 1.8) * 3)
	enemies_spawned = 0
	enemies_to_spawn = $SpawnManager.get_wave_enemy_count()
	wave_complete = false
	enemies_killed = 0
	if phase > SaveManager.data["max_start_phase"]:
		SaveManager.data["max_start_phase"] = phase
	SaveManager.save_game()
	var unlock = SaveManager.data["unlock_level"]
	if phase == 2 and unlock < 2:
		SaveManager.data["unlock_level"] = 2
		SaveManager.save_game()
	elif phase == 3 and unlock < 3:
		SaveManager.data["unlock_level"] = 3
		SaveManager.save_game()
	$UIManager.apply_unlock_level()
	SkillManager.on_boss_killed(phase)
	_update_ui()

# ── Economy ───────────────────────────────────
func add_currency(amount: int, enemy_pos: Vector2 = Vector2.ZERO):
	var multiplied = $EconomyManager.calc_gold(amount, gold_per_kill_level, gold_mult_level)
	currency += multiplied
	enemies_killed += 1
	SkillManager.on_enemy_killed()
	spawn_damage_number(multiplied, enemy_pos + Vector2(25, 0), "gold")
	if randf() < $EconomyManager.calc_drop_chance(legacy_drop_level):
		var drop = $EconomyManager.calc_lp_drop(lp_gain_level, legacy_mult_level)
		run_lp += drop
		SaveManager.data["legacy_points"] += drop
		SaveManager.save_game()
		spawn_damage_number(drop, enemy_pos + Vector2(0, 20), "lp")
	_update_ui()

func spawn_damage_number(amount: float, pos: Vector2, type: String = "normal"):
	var dn = damage_number_scene.instantiate()
	$DamageLayer.add_child(dn)
	var screen_pos = $Camera2D.get_screen_center_position()
	var zoom = $Camera2D.zoom.x
	var center = get_viewport().get_visible_rect().size / 2
	var adjusted_pos = center + (pos - screen_pos) * zoom
	dn.setup(amount, adjusted_pos, type)

# ── Game Over ─────────────────────────────────
func trigger_game_over():
	game_over = true
	$UI/GameOverScreen.visible = true
	$UI/GameOverScreen/PhaseLabel.text = "Phase Reached: " + str(phase)
	if phase > SaveManager.data["best_phase"]:
		SaveManager.data["best_phase"] = phase
	SaveManager.save_game()
	Engine.time_scale = 1.0
	get_tree().paused = true

func _update_ui():
	$UIManager.update_ui()

func _on_tooltip_timer_timeout():
	$UIManager.on_tooltip_timer_timeout()

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		for btn in tooltip_buttons:
			if btn.get_global_rect().has_point(event.position):
				$UIManager.show_tooltip_instant(tooltip_buttons[btn])
				return
		$UIManager.hide_tooltip()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom_level = clamp(zoom_level - ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
			$Camera2D.zoom = Vector2(zoom_level, zoom_level)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom_level = clamp(zoom_level + ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
			$Camera2D.zoom = Vector2(zoom_level, zoom_level)
	if event is InputEventMagnifyGesture:
		zoom_level = clamp(zoom_level / event.factor, ZOOM_MIN, ZOOM_MAX)
		$Camera2D.zoom = Vector2(zoom_level, zoom_level)

func _check_unlock_progression():
	var unlock = SaveManager.data["unlock_level"]
	if unlock == 0 and wave % 10 == 0:
		SaveManager.data["unlock_level"] = 1
		SaveManager.save_game()
	if unlock < 4 and phase >= 3:
		SaveManager.data["unlock_level"] = 4
		SaveManager.save_game()
		$UIManager.apply_unlock_level()

# ── Pause ─────────────────────────────────────
func _on_pause_button_pressed():
	get_tree().paused = true
	$UI/PauseScreen.visible = true

func _on_resume_button_pressed():
	get_tree().paused = false
	$UI/PauseScreen.visible = false

func _on_pause_restart_button_pressed():
	Engine.time_scale = 1.0
	get_tree().paused = false
	await get_tree().process_frame
	get_tree().reload_current_scene()

func _on_pause_menu_button_pressed():
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/startmenu.tscn")

func _on_mute_button_pressed():
	var muted = AudioManager.toggle_mute()
	$UI/MuteButton.text = "🔇" if muted else "🔊"

func _on_speed_button_pressed():
	speed_index = (speed_index + 1) % speed_steps.size()
	Engine.time_scale = speed_steps[speed_index]
	$UI/SpeedButton.text = str(speed_steps[speed_index]) + "x"

func _on_panel_handle_pressed():
	panel_open = !panel_open
	var target_y = 1280 - 440 if panel_open else 1280
	var panel = $UI/UpgradePanel
	var tween = create_tween()
	tween.tween_property(panel, "position:y", target_y, 0.2)
	$UI/UpgradePanel/PanelHandle.text = "▼ UPGRADES" if panel_open else "▲ UPGRADES"

func _on_restart_button_pressed():
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_button_pressed():
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/startmenu.tscn")

func _on_buy_amount_button_pressed():
	match buy_amount:
		1: buy_amount = 5
		5: buy_amount = 10
		10: buy_amount = 1
	$UI/BuyAmountButton.text = "x" + str(buy_amount)

# ── ATK Handlers ──────────────────────────────
func _on_atk_spd_button_pressed():
	$UpgradeManager.on_atk_spd(buy_amount)

func _on_dmg_button_pressed():
	$UpgradeManager.on_dmg(buy_amount)

func _on_dmg_mult_button_pressed():
	$UpgradeManager.on_dmg_mult(buy_amount)

func _on_crit_chance_button_pressed():
	$UpgradeManager.on_crit_chance(buy_amount)

func _on_crit_dmg_button_pressed():
	$UpgradeManager.on_crit_dmg(buy_amount)

# ── DEF Handlers ──────────────────────────────
func _on_shield_button_pressed():
	$UpgradeManager.on_shield(buy_amount)

func _on_shield_regen_button_pressed():
	$UpgradeManager.on_shield_regen(buy_amount)

func _on_shield_strength_button_pressed():
	$UpgradeManager.on_shield_strength(buy_amount)

func _on_shield_mult_button_pressed():
	$UpgradeManager.on_shield_mult(buy_amount)

func _on_evasion_button_pressed():
	$UpgradeManager.on_evasion(buy_amount)

# ── HP Handlers ───────────────────────────────
func _on_max_hp_button_pressed():
	$UpgradeManager.on_max_hp(buy_amount)

func _on_regen_amt_button_pressed():
	$UpgradeManager.on_regen_amt(buy_amount)

func _on_regen_spd_button_pressed():
	$UpgradeManager.on_regen_spd(buy_amount)

func _on_hp_mult_button_pressed():
	$UpgradeManager.on_hp_mult(buy_amount)

func _on_heal_mult_button_pressed():
	$UpgradeManager.on_heal_mult(buy_amount)

# ── UTIL Handlers ─────────────────────────────
func _on_gold_per_kill_button_pressed():
	$UpgradeManager.on_gold_per_kill(buy_amount)

func _on_gold_mult_button_pressed():
	$UpgradeManager.on_gold_mult(buy_amount)

func _on_lp_gain_button_pressed():
	$UpgradeManager.on_lp_gain(buy_amount)

func _on_legacy_mult_button_pressed():
	$UpgradeManager.on_legacy_mult(buy_amount)

func _on_legacy_drop_button_pressed():
	$UpgradeManager.on_legacy_drop(buy_amount)
