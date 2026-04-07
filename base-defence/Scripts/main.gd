extends Node2D

var bullet_scene: PackedScene
var enemy_scene: PackedScene
var brute_scene: PackedScene
var runner_scene: PackedScene
var boss_scene: PackedScene
var damage_number_scene: PackedScene

# Game Speed
var speed_index: int = 0
var speed_steps: Array = [1.0, 1.5, 2.0]

# Spawn
var spawn_timer: float = 0.0
var spawn_edge: int = 0
var enemies_to_spawn: int = 0
var enemies_spawned: int = 0
var wave_complete: bool = false

# Progress
var wave: int = 1
var phase: int = 1
var difficulty: int = 0
var enemies_killed: int = 0
var game_over: bool = false
var boss_wave: bool = false
var boss_alive: bool = false

# Economy
var currency: int = 0
var run_lp: int = 0

# UI state
var panel_open: bool = false

# ── ATK stats ─────────────────────────────────
var attack_speed_level: int = 0
var attack_speed_cost: int = 45
var attack_speed_max: int = 100
var attack_speed_upgrades: int = 0

var crit_chance_level: int = 0
var crit_chance_cost: int = 45
var crit_chance_max: int = 100
var crit_chance_upgrades: int = 0

var damage_level: int = 0
var damage_cost: int = 30
var damage_max: int = 999
var damage_upgrades: int = 0

var dmg_mult_level: int = 0
var dmg_mult_cost: int = 30
var dmg_mult_max: int = 999
var dmg_mult_upgrades: int = 0

var crit_dmg_level: int = 0
var crit_dmg_cost: int = 30
var crit_dmg_max: int = 999
var crit_dmg_upgrades: int = 0

# ── DEF stats ─────────────────────────────────
var shield_strength_level: int = 0
var shield_strength_cost: int = 45
var shield_strength_max: int = 100
var shield_strength_upgrades: int = 0

var evasion_level: int = 0
var evasion_cost: int = 45
var evasion_max: int = 100
var evasion_upgrades: int = 0

var shield_level: int = 0
var shield_cost: int = 30
var shield_max: int = 999
var shield_upgrades: int = 0

var shield_regen_level: int = 0
var shield_regen_cost: int = 45
var shield_regen_max: int = 100
var shield_regen_upgrades: int = 0

var shield_mult_level: int = 0
var shield_mult_cost: int = 30
var shield_mult_max: int = 999
var shield_mult_upgrades: int = 0

# ── HP stats ──────────────────────────────────
var max_hp_level: int = 0
var max_hp_cost: int = 30
var max_hp_max: int = 999
var max_hp_upgrades: int = 0

var regen_amt_level: int = 0
var regen_amt_cost: int = 30
var regen_amt_max: int = 999
var regen_amt_upgrades: int = 0

var regen_spd_level: int = 0
var regen_spd_cost: int = 45
var regen_spd_max: int = 100
var regen_spd_upgrades: int = 0

var hp_mult_level: int = 0
var hp_mult_cost: int = 30
var hp_mult_max: int = 999
var hp_mult_upgrades: int = 0

var heal_mult_level: int = 0
var heal_mult_cost: int = 30
var heal_mult_max: int = 999
var heal_mult_upgrades: int = 0

# ── UTIL stats ────────────────────────────────
var gold_per_kill_level: int = 0
var gold_per_kill_cost: int = 30
var gold_per_kill_max: int = 999
var gold_per_kill_upgrades: int = 0

var gold_mult_level: int = 0
var gold_mult_cost: int = 30
var gold_mult_max: int = 999
var gold_mult_upgrades: int = 0

var lp_gain_level: int = 0
var lp_gain_cost: int = 30
var lp_gain_max: int = 999
var lp_gain_upgrades: int = 0

var legacy_mult_level: int = 0
var legacy_mult_cost: int = 30
var legacy_mult_max: int = 999
var legacy_mult_upgrades: int = 0

var legacy_drop_level: int = 0
var legacy_drop_cost: int = 45
var legacy_drop_max: int = 100
var legacy_drop_upgrades: int = 0

var tooltip_buttons: Dictionary = {}
var tooltip_key: String = ""
var zoom_level: float = 0.6
const ZOOM_MIN: float = 0.4
const ZOOM_MAX: float = 1.0
const ZOOM_STEP: float = 0.1

var sfx_shoot: AudioStreamPlayer
var sfx_boss_spawn: AudioStreamPlayer
var sfx_take_damage: AudioStreamPlayer
var sfx_boss_death: AudioStreamPlayer
var sfx_music: AudioStreamPlayer
var sfx_muted: bool = false

const BASE_ENEMIES_PER_WAVE = 12
const ENEMIES_PER_WAVE_WAVE_SCALING = 2
const ENEMIES_PER_WAVE_PHASE_SCALING = 2

const UNLOCK_REQUIREMENTS = {
	"ATKSpdButton": 0,
	"DmgButton": 0,
	"MaxHPButton": 1,
	"RegenAmtButton": 1,
	"ShieldButton": 2,
	"ShieldRegenButton": 2,
	"GoldPerKillButton": 2,
	"LPGainButton": 2,
	"DmgMultButton": 3,
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

func _ready():
	bullet_scene = preload("res://Scenes/Projectile.tscn")
	enemy_scene = preload("res://Scenes/Enemy.tscn")
	brute_scene = preload("res://Scenes/Brute.tscn")
	runner_scene = preload("res://Scenes/Runner.tscn")
	boss_scene = preload("res://Scenes/Boss.tscn")
	damage_number_scene = preload("res://Scenes/damage_number.tscn")
	phase = SaveManager.data.get("start_phase", 1)
	difficulty = (phase - 1) * 10
	$Base.set_bullet_scene(bullet_scene)
	$Base.set_main(self)
	_apply_workshop_floors()
	_apply_unlock_level()
	enemies_to_spawn = _get_wave_enemy_count()
	_setup_audio() 
	_update_ui()
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
		btn.mouse_entered.connect(func(): _show_tooltip(key))
		btn.mouse_exited.connect(func(): _hide_tooltip())

func _get_wave_enemy_count() -> int:
	return BASE_ENEMIES_PER_WAVE + (wave * ENEMIES_PER_WAVE_WAVE_SCALING) + (phase * ENEMIES_PER_WAVE_PHASE_SCALING)

func _calc_cost(base: int, level: int, is_capped: bool) -> int:
	if is_capped:
		var scale = 1.23 if level < 50 else 1.4
		return int(base * pow(scale, level))
	else:
		return int(base * pow(1.2, level))

func _apply_unlock_level():
	var unlock = SaveManager.data["unlock_level"]
	var columns = ["ATKColumn", "DEFColumn", "HPColumn", "UTILColumn"]
	for col in columns:
		var col_node = $UI/UpgradePanel/ColumnsContainer.get_node(col)
		for child in col_node.get_children():
			if child is Button:
				var required = UNLOCK_REQUIREMENTS.get(child.name, 3)
				child.visible = unlock >= required
	var def_locked = $UI/UpgradePanel/ColumnsContainer/DEFColumn/DEFLocked
	var hp_locked = $UI/UpgradePanel/ColumnsContainer/HPColumn/HPLocked
	var util_locked = $UI/UpgradePanel/ColumnsContainer/UTILColumn/UTILLocked
	def_locked.visible = unlock < 1
	hp_locked.visible = unlock < 2
	util_locked.visible = unlock < 2

func _check_unlock_progression():
	var unlock = SaveManager.data["unlock_level"]
	if unlock == 0 and wave % 10 == 0:
		SaveManager.data["unlock_level"] = 1
		SaveManager.save_game()
	if unlock < 4 and phase >= 3:
		SaveManager.data["unlock_level"] = 4
		SaveManager.save_game()
		_apply_unlock_level()

func _apply_workshop_floors():
	var d = SaveManager.data
	attack_speed_level = d["floor_attack_speed"]
	$Base.fire_rate += attack_speed_level * 0.125
	damage_level = d["floor_damage"]
	$Base.bullet_damage += damage_level * 1.0
	dmg_mult_level = d["floor_dmg_mult"]
	$Base.damage_multiplier += dmg_mult_level * 0.1
	crit_chance_level = d["floor_crit_chance"]
	$Base.crit_chance += crit_chance_level * 0.0125
	crit_dmg_level = d["floor_crit_dmg"]
	$Base.crit_damage += crit_dmg_level * 0.10
	shield_level = d["floor_shield"]
	$Base.max_shield += shield_level * 50.0
	$Base.shield += shield_level * 50.0
	shield_regen_level = d["floor_shield_regen"]
	$Base.shield_regen_interval = max(0.5, 5.0 - (shield_regen_level * 0.045))
	shield_strength_level = d["floor_shield_strength"]
	$Base.shield_strength += shield_strength_level * 0.004
	shield_mult_level = d["floor_shield_mult"]
	$Base.shield_multiplier += shield_mult_level * 0.1
	evasion_level = d["floor_evasion"]
	$Base.evasion += evasion_level * 0.002
	max_hp_level = d["floor_max_hp"]
	$Base.increase_max_health(max_hp_level * 10.0)
	regen_amt_level = d["floor_regen_amt"]
	$Base.hp_regen += regen_amt_level * 1.0
	regen_spd_level = d["floor_regen_spd"]
	$Base.regen_interval = max(0.5, 5.0 - (regen_spd_level * 0.045))
	heal_mult_level = d["floor_heal_mult"]
	$Base.heal_multiplier += heal_mult_level * 0.1
	hp_mult_level = d["floor_hp_mult"]
	$Base.hp_multiplier += hp_mult_level * 0.1
	gold_per_kill_level = d["floor_gold_per_kill"]
	gold_mult_level = d["floor_gold_mult"]
	lp_gain_level = d["floor_lp_gain"]
	legacy_mult_level = d["floor_legacy_mult"]
	legacy_drop_level = d["floor_legacy_drop"]

func _process(delta):
	if game_over:
		return
	if boss_wave:
		return
	if wave_complete:
		return
	spawn_timer += delta
	var current_spawn_interval = 0.8 / (1.0 + (difficulty * 0.09))
	if spawn_timer >= current_spawn_interval and enemies_spawned < enemies_to_spawn:
		spawn_timer = 0.0
		enemies_spawned += 1
		_spawn_enemy()

func _get_spawn_scene() -> PackedScene:
	if phase < 2:
		return enemy_scene
	var brute_every: int = max(6, 10 - (phase - 2))
	var runner_every: int = max(4, 8 - (phase - 3)) if phase >= 3 else 0
	if runner_every > 0 and enemies_spawned % runner_every == 0:
		return runner_scene
	if enemies_spawned % brute_every == 0:
		return brute_scene
	return enemy_scene

func _spawn_enemy():
	var scene = _get_spawn_scene()
	var e = scene.instantiate()
	add_child(e)
	e.setup($Base, self)
	e.scale_to_wave(difficulty)
	e.global_position = _random_edge_position()

func on_enemy_killed():
	if enemies_spawned >= enemies_to_spawn and not boss_wave:
		var remaining = get_tree().get_nodes_in_group("enemies").size()
		if remaining <= 1:
			wave_complete = true
			_advance_wave()

func _spawn_boss():
	boss_wave = true
	boss_alive = true
	var b = boss_scene.instantiate()
	add_child.call_deferred(b)
	b.setup($Base, self)
	b.scale_to_phase(phase)
	b.global_position = Vector2(360, -40)
	$UI/WaveLabel.text = "⚠ BOSS WAVE ⚠ | Phase: " + str(phase)
	_on_boss_spawn_flash()
	play_sfx(sfx_boss_spawn)

func _advance_wave():
	wave += 1
	difficulty += 1
	enemies_spawned = 0
	enemies_to_spawn = _get_wave_enemy_count()
	wave_complete = false
	if wave % 10 != 0:
		_on_wave_complete_flash()
	_check_unlock_progression()
	var lp_earned = 1 + lp_gain_level
	var lp_total = int(lp_earned * (1.0 + (legacy_mult_level * 0.1)))
	run_lp += lp_total
	SaveManager.data["legacy_points"] += lp_total
	SaveManager.save_game()
	if wave % 10 == 0:
		_spawn_boss()
	else:
		_update_ui()

func on_boss_killed():
	boss_alive = false
	boss_wave = false
	wave += 1
	phase += 1
	difficulty += 3
	enemies_spawned = 0
	enemies_to_spawn = _get_wave_enemy_count()
	wave_complete = false
	enemies_killed = 0
	var unlock = SaveManager.data["unlock_level"]
	if phase > SaveManager.data["max_start_phase"]:
		SaveManager.data["max_start_phase"] = phase
	SaveManager.save_game()
	if phase == 2 and unlock < 2:
		SaveManager.data["unlock_level"] = 2
		SaveManager.save_game()
	elif phase == 3 and unlock < 3:
		SaveManager.data["unlock_level"] = 3
		SaveManager.save_game()
	_update_ui()

func add_currency(amount: int, enemy_pos: Vector2 = Vector2.ZERO):
	var total = amount + gold_per_kill_level
	var multiplied = int(total * (1.0 + (gold_mult_level * 0.1)))
	currency += multiplied
	enemies_killed += 1
	var drop_chance = 0.05 + (legacy_drop_level * 0.0055)
	if randf() < drop_chance:
		var drop = int((1 + lp_gain_level) * (1.0 + (legacy_mult_level * 0.1)))
		run_lp += drop
		SaveManager.data["legacy_points"] += drop
		SaveManager.save_game()
		spawn_damage_number(drop, enemy_pos + Vector2(randf_range(-20, 20), -50), "lp")
	_update_ui()
	
func spawn_damage_number(amount: float, pos: Vector2, type: String = "normal"):
	var dn = damage_number_scene.instantiate()
	$DamageLayer.add_child(dn)
	dn.setup(amount, pos, type)

func trigger_game_over():
	game_over = true
	$UI/GameOverScreen.visible = true
	$UI/GameOverScreen/PhaseLabel.text = "Phase Reached: " + str(phase)
	if phase > SaveManager.data["best_phase"]:
		SaveManager.data["best_phase"] = phase
	SaveManager.save_game()
	Engine.time_scale = 1.0
	get_tree().paused = true

func _on_restart_button_pressed():
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_panel_handle_pressed():
	panel_open = !panel_open
	var target_y = 1280 - 400 if panel_open else 1280
	var panel = $UI/UpgradePanel
	var tween = create_tween()
	tween.tween_property(panel, "position:y", target_y, 0.2)
	$UI/UpgradePanel/PanelHandle.text = "▼ UPGRADES" if panel_open else "▲ UPGRADES"

func _update_ui():
	$UI/CurrencyLabel.text = "💰 " + str(currency) + "  |  ⭐ " + str(run_lp)
	$UI/WaveLabel.text = "Wave: " + str(wave) + " | Phase: " + str(phase)
	_update_btn($UI/UpgradePanel/ColumnsContainer/ATKColumn/ATKSpdButton,
		"ATK SPD", attack_speed_level, attack_speed_max, attack_speed_cost,
		str(snappedf($Base.fire_rate, 0.01)) + "/s")
	_update_btn($UI/UpgradePanel/ColumnsContainer/ATKColumn/DmgButton,
		"DMG", damage_level, damage_max, damage_cost,
		str(10 + damage_level))
	_update_btn($UI/UpgradePanel/ColumnsContainer/ATKColumn/DmgMultButton,
		"DMG MULT", dmg_mult_level, dmg_mult_max, dmg_mult_cost,
		"+" + str(dmg_mult_level * 10) + "%")
	_update_btn($UI/UpgradePanel/ColumnsContainer/ATKColumn/CritChanceButton,
		"CRIT %", crit_chance_level, crit_chance_max, crit_chance_cost,
		str(snappedf(crit_chance_level * 0.8, 0.1)) + "%")
	_update_btn($UI/UpgradePanel/ColumnsContainer/ATKColumn/CritDmgButton,
		"CRIT DMG", crit_dmg_level, crit_dmg_max, crit_dmg_cost,
		"+" + str(crit_dmg_level * 10) + "%")
	_update_btn($UI/UpgradePanel/ColumnsContainer/DEFColumn/ShieldButton,
		"SHIELD", shield_level, shield_max, shield_cost,
		str(shield_level * 50))
	_update_btn($UI/UpgradePanel/ColumnsContainer/DEFColumn/ShieldRegenButton,
		"SHLD RGN", shield_regen_level, shield_regen_max, shield_regen_cost,
		str(snappedf(max(0.5, 5.0 - (shield_regen_level * 0.045)), 0.01)) + "s")
	_update_btn($UI/UpgradePanel/ColumnsContainer/DEFColumn/ShieldStrengthButton,
		"SHLD STR", shield_strength_level, shield_strength_max, shield_strength_cost,
		str(snappedf(10.0 + (shield_strength_level * 0.3), 0.1)) + "%")
	_update_btn($UI/UpgradePanel/ColumnsContainer/DEFColumn/ShieldMultButton,
		"SHLD MULT", shield_mult_level, shield_mult_max, shield_mult_cost,
		"+" + str(shield_mult_level * 10) + "%")
	_update_btn($UI/UpgradePanel/ColumnsContainer/DEFColumn/EvasionButton,
		"EVASION", evasion_level, evasion_max, evasion_cost,
		str(snappedf(evasion_level * 0.2, 0.1)) + "%")
	_update_btn($UI/UpgradePanel/ColumnsContainer/HPColumn/MaxHPButton,
		"MAX HP", max_hp_level, max_hp_max, max_hp_cost,
		str(100 + (max_hp_level * 10)))
	_update_btn($UI/UpgradePanel/ColumnsContainer/HPColumn/RegenAmtButton,
		"REGEN AMT", regen_amt_level, regen_amt_max, regen_amt_cost,
		str(regen_amt_level) + " hp")
	_update_btn($UI/UpgradePanel/ColumnsContainer/HPColumn/RegenSpdButton,
		"REGEN SPD", regen_spd_level, regen_spd_max, regen_spd_cost,
		str(snappedf(max(0.5, 5.0 - (regen_spd_level * 0.045)), 0.01)) + "s")
	_update_btn($UI/UpgradePanel/ColumnsContainer/HPColumn/HPMultButton,
		"HP MULT", hp_mult_level, hp_mult_max, hp_mult_cost,
		"+" + str(hp_mult_level * 10) + "%")
	_update_btn($UI/UpgradePanel/ColumnsContainer/HPColumn/HealMultButton,
		"HEAL MULT", heal_mult_level, heal_mult_max, heal_mult_cost,
		"+" + str(heal_mult_level * 10) + "%")
	_update_btn($UI/UpgradePanel/ColumnsContainer/UTILColumn/GoldPerKillButton,
		"GOLD/KILL", gold_per_kill_level, gold_per_kill_max, gold_per_kill_cost,
		"+" + str(gold_per_kill_level) + "g")
	_update_btn($UI/UpgradePanel/ColumnsContainer/UTILColumn/GoldMultButton,
		"GOLD MULT", gold_mult_level, gold_mult_max, gold_mult_cost,
		"+" + str(gold_mult_level * 10) + "%")
	_update_btn($UI/UpgradePanel/ColumnsContainer/UTILColumn/LPGainButton,
		"LP GAIN", lp_gain_level, lp_gain_max, lp_gain_cost,
		"+" + str(lp_gain_level) + " LP")
	_update_btn($UI/UpgradePanel/ColumnsContainer/UTILColumn/LegacyMultButton,
		"LP MULT", legacy_mult_level, legacy_mult_max, legacy_mult_cost,
		"+" + str(legacy_mult_level * 10) + "%")
	_update_btn($UI/UpgradePanel/ColumnsContainer/UTILColumn/LegacyDropButton,
		"LP CHANCE", legacy_drop_level, legacy_drop_max, legacy_drop_cost,
		str(snappedf(5.0 + (legacy_drop_level * 0.55), 0.1)) + "%")

func _update_btn(btn: Button, label: String, level: int, max_level: int, cost: int, stat: String):
	if level >= max_level:
		btn.text = label + "\nMAX (" + stat + ")"
		btn.disabled = true
	else:
		btn.text = label + "\nLv" + str(level + 1) + " - " + str(cost) + "g\n" + stat
		btn.disabled = currency < cost

func _flash_screen(color: Color, alpha: float = 0.3, duration: float = 0.4):
	var flash = $UI/ScreenFlash
	flash.color = color
	flash.modulate.a = alpha
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, duration)

func _on_wave_complete_flash():
	_flash_screen(Color(0.2, 1.0, 0.3), 0.05, 0.6)

func _on_boss_spawn_flash():
	_flash_screen(Color(0.6, 0.0, 0.8), 0.5, 0.8)

func _show_tooltip(key: String):
	tooltip_key = key
	$UI/TooltipTimer.start()

func _hide_tooltip():
	$UI/TooltipTimer.stop()
	$UI/TooltipPanel.visible = false

func _on_tooltip_timer_timeout():
	if tooltip_key != "":
		$UI/TooltipPanel/TooltipLabel.text = TooltipData.TIPS[tooltip_key]
		var mouse = get_viewport().get_mouse_position()
		var panel_width = 400
		var x = mouse.x + 10
		if x + panel_width > get_viewport().get_visible_rect().size.x:
			x = mouse.x - panel_width - 10
		$UI/TooltipPanel.position = Vector2(x, mouse.y - 60)
		$UI/TooltipPanel.visible = true

func _show_tooltip_instant(key: String):
	$UI/TooltipPanel/TooltipLabel.text = TooltipData.TIPS[key]
	var mouse = get_viewport().get_mouse_position()
	var panel_width = 400
	var x = mouse.x + 10
	if x + panel_width > get_viewport().get_visible_rect().size.x:
		x = mouse.x - panel_width - 10
	$UI/TooltipPanel.position = Vector2(x, mouse.y - 60)
	$UI/TooltipPanel.visible = true

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		for btn in tooltip_buttons:
			if btn.get_global_rect().has_point(event.position):
				_show_tooltip_instant(tooltip_buttons[btn])
				return
		_hide_tooltip()
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

# ── ATK handlers ──────────────────────────────
func _on_atk_spd_button_pressed():
	if currency < attack_speed_cost or attack_speed_level >= attack_speed_max: return
	currency -= attack_speed_cost
	attack_speed_level += 1
	attack_speed_upgrades += 1
	attack_speed_cost = _calc_cost(45, attack_speed_upgrades, true)
	var gain = 0.12 / (1.0 + attack_speed_upgrades * 0.02)
	$Base.fire_rate += gain
	_update_ui()

func _on_dmg_button_pressed():
	if currency < damage_cost or damage_level >= damage_max: return
	currency -= damage_cost
	damage_level += 1
	damage_upgrades += 1
	damage_cost = _calc_cost(30, damage_upgrades, false)
	$Base.bullet_damage += 1.0
	_update_ui()

func _on_dmg_mult_button_pressed():
	if currency < dmg_mult_cost or dmg_mult_level >= dmg_mult_max: return
	currency -= dmg_mult_cost
	dmg_mult_level += 1
	dmg_mult_upgrades += 1
	dmg_mult_cost = _calc_cost(30, dmg_mult_upgrades, false)
	$Base.damage_multiplier += 0.1
	_update_ui()

func _on_crit_chance_button_pressed():
	if currency < crit_chance_cost or crit_chance_level >= crit_chance_max: return
	currency -= crit_chance_cost
	crit_chance_level += 1
	crit_chance_upgrades += 1
	crit_chance_cost = _calc_cost(45, crit_chance_upgrades, true)
	$Base.crit_chance += 0.008
	_update_ui()

func _on_crit_dmg_button_pressed():
	if currency < crit_dmg_cost or crit_dmg_level >= crit_dmg_max: return
	currency -= crit_dmg_cost
	crit_dmg_level += 1
	crit_dmg_upgrades += 1
	crit_dmg_cost = _calc_cost(30, crit_dmg_upgrades, false)
	$Base.crit_damage += 0.10
	_update_ui()

# ── DEF handlers ──────────────────────────────
func _on_shield_button_pressed():
	if currency < shield_cost or shield_level >= shield_max: return
	currency -= shield_cost
	shield_level += 1
	shield_upgrades += 1
	shield_cost = _calc_cost(30, shield_upgrades, false)
	$Base.max_shield += 50.0
	$Base.shield += 50.0
	$Base._update_combat_ui()
	_update_ui()

func _on_shield_regen_button_pressed():
	if currency < shield_regen_cost or shield_regen_level >= shield_regen_max: return
	currency -= shield_regen_cost
	shield_regen_level += 1
	shield_regen_upgrades += 1
	shield_regen_cost = _calc_cost(45, shield_regen_upgrades, true)
	$Base.shield_regen_interval = max(0.5, 5.0 - (shield_regen_level * 0.045))
	_update_ui()

func _on_shield_strength_button_pressed():
	if currency < shield_strength_cost or shield_strength_level >= shield_strength_max: return
	currency -= shield_strength_cost
	shield_strength_level += 1
	shield_strength_upgrades += 1
	shield_strength_cost = _calc_cost(45, shield_strength_upgrades, true)
	$Base.shield_strength += 0.003
	_update_ui()

func _on_shield_mult_button_pressed():
	if currency < shield_mult_cost or shield_mult_level >= shield_mult_max: return
	currency -= shield_mult_cost
	shield_mult_level += 1
	shield_mult_upgrades += 1
	shield_mult_cost = _calc_cost(30, shield_mult_upgrades, false)
	$Base.shield_multiplier += 0.1
	_update_ui()

func _on_evasion_button_pressed():
	if currency < evasion_cost or evasion_level >= evasion_max: return
	currency -= evasion_cost
	evasion_level += 1
	evasion_upgrades += 1
	evasion_cost = _calc_cost(45, evasion_upgrades, true)
	$Base.evasion += 0.002
	_update_ui()

# ── HP handlers ───────────────────────────────
func _on_max_hp_button_pressed():
	if currency < max_hp_cost or max_hp_level >= max_hp_max: return
	currency -= max_hp_cost
	max_hp_level += 1
	max_hp_upgrades += 1
	max_hp_cost = _calc_cost(30, max_hp_upgrades, false)
	$Base.increase_max_health(10.0)
	_update_ui()

func _on_regen_amt_button_pressed():
	if currency < regen_amt_cost or regen_amt_level >= regen_amt_max: return
	currency -= regen_amt_cost
	regen_amt_level += 1
	regen_amt_upgrades += 1
	regen_amt_cost = _calc_cost(30, regen_amt_upgrades, false)
	$Base.hp_regen += 1.0
	_update_ui()

func _on_regen_spd_button_pressed():
	if currency < regen_spd_cost or regen_spd_level >= regen_spd_max: return
	currency -= regen_spd_cost
	regen_spd_level += 1
	regen_spd_upgrades += 1
	regen_spd_cost = _calc_cost(45, regen_spd_upgrades, true)
	$Base.regen_interval = max(0.5, 5.0 - (regen_spd_level * 0.045))
	_update_ui()

func _on_heal_mult_button_pressed():
	if currency < heal_mult_cost or heal_mult_level >= heal_mult_max: return
	currency -= heal_mult_cost
	heal_mult_level += 1
	heal_mult_upgrades += 1
	heal_mult_cost = _calc_cost(30, heal_mult_upgrades, false)
	$Base.heal_multiplier += 0.1
	_update_ui()

func _on_hp_mult_button_pressed():
	if currency < hp_mult_cost or hp_mult_level >= hp_mult_max: return
	currency -= hp_mult_cost
	hp_mult_level += 1
	hp_mult_upgrades += 1
	hp_mult_cost = _calc_cost(30, hp_mult_upgrades, false)
	$Base.hp_multiplier += 0.1
	_update_ui()

# ── UTIL handlers ─────────────────────────────
func _on_gold_per_kill_button_pressed():
	if currency < gold_per_kill_cost or gold_per_kill_level >= gold_per_kill_max: return
	currency -= gold_per_kill_cost
	gold_per_kill_level += 1
	gold_per_kill_upgrades += 1
	gold_per_kill_cost = _calc_cost(30, gold_per_kill_upgrades, false)
	_update_ui()

func _on_gold_mult_button_pressed():
	if currency < gold_mult_cost or gold_mult_level >= gold_mult_max: return
	currency -= gold_mult_cost
	gold_mult_level += 1
	gold_mult_upgrades += 1
	gold_mult_cost = _calc_cost(30, gold_mult_upgrades, false)
	_update_ui()

func _on_lp_gain_button_pressed():
	if currency < lp_gain_cost or lp_gain_level >= lp_gain_max: return
	currency -= lp_gain_cost
	lp_gain_level += 1
	lp_gain_upgrades += 1
	lp_gain_cost = _calc_cost(30, lp_gain_upgrades, false)
	_update_ui()

func _on_legacy_mult_button_pressed():
	if currency < legacy_mult_cost or legacy_mult_level >= legacy_mult_max: return
	currency -= legacy_mult_cost
	legacy_mult_level += 1
	legacy_mult_upgrades += 1
	legacy_mult_cost = _calc_cost(30, legacy_mult_upgrades, false)
	_update_ui()

func _on_legacy_drop_button_pressed():
	if currency < legacy_drop_cost or legacy_drop_level >= legacy_drop_max: return
	currency -= legacy_drop_cost
	legacy_drop_level += 1
	legacy_drop_upgrades += 1
	legacy_drop_cost = _calc_cost(45, legacy_drop_upgrades, true)
	_update_ui()

func _random_edge_position() -> Vector2:
	spawn_edge = (spawn_edge + 1) % 6
	match spawn_edge:
		0: return Vector2(randf_range(-240, 960), -500)           # top
		1: return Vector2(randf_range(-240, 960), 1800)           # bottom
		2: return Vector2(-240, randf_range(-500, 1800))          # left top
		3: return Vector2(-240, randf_range(-500, 1800))          # left bottom
		4: return Vector2(960, randf_range(-500, 1800))           # right top
		5: return Vector2(960, randf_range(-500, 1800))           # right bottom
	return Vector2.ZERO

func _setup_audio():
	sfx_shoot = AudioStreamPlayer.new()
	sfx_shoot.stream = preload("res://Assets/Sounds/Shoot.wav")
	add_child(sfx_shoot)

	sfx_boss_spawn = AudioStreamPlayer.new()
	sfx_boss_spawn.stream = preload("res://Assets/Sounds/BossSpawn.wav")
	add_child(sfx_boss_spawn)
	
	sfx_take_damage = AudioStreamPlayer.new()
	sfx_take_damage.stream = preload("res://Assets/Sounds/TakeDamage.wav")
	add_child(sfx_take_damage)
	
	sfx_boss_death = AudioStreamPlayer.new()
	sfx_boss_death.stream = preload("res://Assets/Sounds/BossDeath.wav")
	add_child(sfx_boss_death)
	
	sfx_music = AudioStreamPlayer.new()
	sfx_music.stream = preload("res://Assets/Sounds/Music.wav")
	sfx_music.volume_db = -7.0
	sfx_music.autoplay = true
	sfx_music.finished.connect(func(): sfx_music.play())
	add_child(sfx_music)

func play_sfx(player: AudioStreamPlayer):
	if not sfx_muted:
		player.volume_db = -15.0
		player.play()

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
	get_tree().change_scene_to_file("res://Scenes/StartMenu.tscn")

func _on_mute_button_pressed():
	sfx_muted = !sfx_muted
	$UI/MuteButton.text = "🔇" if sfx_muted else "🔊"
	if sfx_muted:
		sfx_music.stop()
	else:
		sfx_music.play()

# ── Game Over ─────────────────────────────────
func _on_menu_button_pressed():
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/StartMenu.tscn")

func _on_speed_button_pressed():
	speed_index = (speed_index + 1) % speed_steps.size()
	Engine.time_scale = speed_steps[speed_index]
	$UI/SpeedButton.text = str(speed_steps[speed_index]) + "x"
