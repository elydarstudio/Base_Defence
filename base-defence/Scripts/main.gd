extends Node2D

var bullet_scene: PackedScene
var enemy_scene: PackedScene
var boss_scene: PackedScene
var damage_number_scene: PackedScene

# Spawn
var spawn_timer: float = 0.0
var spawn_interval: float = 1.25
var wave_timer: float = 0.0
var wave_duration: float = 25.0

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
var legacy_points: int = 0

# UI state
var panel_open: bool = false

# ── ATK stats ─────────────────────────────────
var attack_speed_level: int = 0
var attack_speed_cost: int = 35
var attack_speed_max: int = 40

var damage_level: int = 0
var damage_cost: int = 30
var damage_max: int = 90

var dmg_mult_level: int = 0
var dmg_mult_cost: int = 60
var dmg_mult_max: int = 999

var crit_chance_level: int = 0
var crit_chance_cost: int = 40
var crit_chance_max: int = 16 # 16 * 5% = 80%

var crit_dmg_level: int = 0
var crit_dmg_cost: int = 60
var crit_dmg_max: int = 999

# ── DEF stats ─────────────────────────────────
# DEF upgrades
var shield_level: int = 0
var shield_cost: int = 35
var shield_max: int = 40

var shield_regen_level: int = 0
var shield_regen_cost: int = 50
var shield_regen_max: int = 999

var shield_strength_level: int = 0
var shield_strength_cost: int = 45
var shield_strength_max: int = 100  # 100 * 0.4% = 40%

var shield_mult_level: int = 0
var shield_mult_cost: int = 60
var shield_mult_max: int = 999

var evasion_level: int = 0
var evasion_cost: int = 50
var evasion_max: int = 100  # 100 * 0.2% = 20%

# ── HP stats ──────────────────────────────────
var max_hp_level: int = 0
var max_hp_cost: int = 35
var max_hp_max: int = 40

var regen_amt_level: int = 0
var regen_amt_cost: int = 40
var regen_amt_max: int = 999

var regen_spd_level: int = 0
var regen_spd_cost: int = 40
var regen_spd_max: int = 40

var hp_mult_level: int = 0
var hp_mult_cost: int = 60
var hp_mult_max: int = 999

var heal_mult_level: int = 0
var heal_mult_cost: int = 60
var heal_mult_max: int = 999

# ── UTIL stats ────────────────────────────────
var gold_per_kill_level: int = 0
var gold_per_kill_cost: int = 20
var gold_per_kill_max: int = 40

var gold_mult_level: int = 0
var gold_mult_cost: int = 50
var gold_mult_max: int = 999

var legacy_per_wave_level: int = 0
var legacy_per_wave_cost: int = 20
var legacy_per_wave_max: int = 40

var legacy_mult_level: int = 0
var legacy_mult_cost: int = 50
var legacy_mult_max: int = 999

var legacy_drop_level: int = 0
var legacy_drop_cost: int = 40
var legacy_drop_max: int = 8 # 8 * 5% = 40% max

const UNLOCK_REQUIREMENTS = {
	# unlock_level 0
	"ATKSpdButton": 0,
	"DmgButton": 0,
	# unlock_level 1 — reach wave 10
	"MaxHPButton": 1,
	"RegenAmtButton": 1,
	# unlock_level 2 — beat boss 1
	"ShieldButton": 2,
	"ShieldRegenButton": 2,
	"GoldPerKillButton": 2,
	"LegacyPerWaveButton": 2,
	# unlock_level 3 — beat boss 2
	"DmgMultButton": 3,
	"HPMultButton": 3,
	"ShieldStrengthButton": 3,
	"GoldMultButton": 3,
	"LegacyMultButton": 3,
	# unlock_level 4 — reach phase 3 boss
	"CritChanceButton": 4,
	"CritDmgButton": 4,
	"RegenSpdButton": 4,
	"HealMultButton": 4,
	"ShieldMultButton": 4,
	"EvasionButton": 4,
	"LegacyDropButton": 4,
	# locked placeholders
	"DEFLocked": 999,
	"HPLocked": 999,
	"UTILLocked": 999,
}

func _ready():
	bullet_scene = preload("res://Scenes/Projectile.tscn")
	enemy_scene = preload("res://Scenes/Enemy.tscn")
	boss_scene = preload("res://Scenes/Boss.tscn")
	damage_number_scene = preload("res://Scenes/damage_number.tscn")
	phase = SaveManager.data.get("start_phase", 1)
	$Base.set_bullet_scene(bullet_scene)
	$Base.set_main(self)
	_apply_workshop_floors()
	_apply_unlock_level()
	_update_ui()
	
func _apply_unlock_level():
	var unlock = SaveManager.data["unlock_level"]
	
	# Hide/show individual stat buttons
	var columns = ["ATKColumn", "DEFColumn", "HPColumn", "UTILColumn"]
	for col in columns:
		var col_node = $UI/UpgradePanel/ColumnsContainer.get_node(col)
		for child in col_node.get_children():
			if child is Button:
				var required = UNLOCK_REQUIREMENTS.get(child.name, 3)
				child.visible = unlock >= required

	# Show/hide locked placeholders
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
	# ATK
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
	# DEF
	shield_level = d["floor_shield"]
	$Base.max_shield += shield_level * 20.0
	$Base.shield += shield_level * 20.0
	shield_regen_level = d["floor_shield_regen"]
	$Base.shield_regen += shield_regen_level * 1.0
	shield_strength_level = d["floor_shield_strength"]
	$Base.shield_strength += shield_strength_level * 0.004
	shield_mult_level = d["floor_shield_mult"]
	$Base.shield_multiplier += shield_mult_level * 0.1
	evasion_level = d["floor_evasion"]
	$Base.evasion += evasion_level * 0.002
	# HP
	max_hp_level = d["floor_max_hp"]
	$Base.increase_max_health(max_hp_level * 10.0)
	regen_amt_level = d["floor_regen_amt"]
	$Base.hp_regen += regen_amt_level * 1.0
	regen_spd_level = d["floor_regen_spd"]
	$Base.regen_interval = max(1.0, 5.0 - (regen_spd_level * 0.1))
	heal_mult_level = d["floor_heal_mult"]
	$Base.heal_multiplier += heal_mult_level * 0.1
	hp_mult_level = d["floor_hp_mult"]
	$Base.hp_multiplier += hp_mult_level * 0.1
	# UTIL
	gold_per_kill_level = d["floor_gold_per_kill"]
	gold_mult_level = d["floor_gold_mult"]
	legacy_per_wave_level = d["floor_legacy_per_wave"]
	legacy_mult_level = d["floor_legacy_mult"]
	legacy_drop_level = d["floor_legacy_drop"]
func _process(delta):
	if game_over:
		return
	if boss_wave:
		return
	wave_timer += delta
	spawn_timer += delta
	var current_spawn_interval = max(0.3, spawn_interval - (difficulty * 0.045))
	if spawn_timer >= current_spawn_interval:
		spawn_timer = 0.0
		_spawn_enemy()
	if wave_timer >= wave_duration:
		wave_timer = 0.0
		_advance_wave()

func _spawn_enemy():
	var e = enemy_scene.instantiate()
	add_child(e)
	e.setup($Base, self)
	e.scale_to_wave(difficulty)
	e.global_position = _random_edge_position()

func _spawn_boss():
	boss_wave = true
	boss_alive = true
	var b = boss_scene.instantiate()
	add_child(b)
	b.setup($Base, self)
	b.scale_to_phase(phase)
	b.global_position = Vector2(360, -40)
	$UI/WaveLabel.text = "⚠ BOSS WAVE ⚠ | Phase: " + str(phase)

func _advance_wave():
	wave += 1
	difficulty += 1
	_check_unlock_progression()
	spawn_interval = max(0.4, 1.8 - (difficulty * 0.03))
	# Legacy per wave
	var lp_earned = 1 + legacy_per_wave_level
	var lp_total = int(lp_earned * (1.0 + (legacy_mult_level * 0.1)))
	legacy_points += lp_total
	SaveManager.data["legacy_points"] = legacy_points
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
	spawn_interval = max(0.4, 1.8 - (difficulty * 0.03))
	enemies_killed = 0
	var unlock = SaveManager.data["unlock_level"]
	if phase == 2 and unlock < 2:
		SaveManager.data["unlock_level"] = 2
		SaveManager.save_game()
	elif phase == 3 and unlock < 3:
		SaveManager.data["unlock_level"] = 3
		SaveManager.save_game()
	_update_ui()

func add_currency(amount: int):
	var total = amount + gold_per_kill_level
	var multiplied = int(total * (1.0 + (gold_mult_level * 0.1)))
	currency += multiplied
	enemies_killed += 1
	# Legacy drop chance
	var drop_chance = legacy_drop_level * 0.05
	if randf() < drop_chance:
		legacy_points += 1
		SaveManager.data["legacy_points"] = legacy_points
		SaveManager.save_game()
	_update_ui()

func spawn_damage_number(amount: float, pos: Vector2, type: String = "normal"):
	var dn = damage_number_scene.instantiate()
	$DamageLayer.add_child(dn)
	dn.setup(amount, pos, type)

func trigger_game_over():
	game_over = true
	$UI/GameOverScreen.visible = true
	$UI/GameOverScreen/PhaseLabel.text = "Phase Reached: " + str(phase)
	SaveManager.data["legacy_points"] += legacy_points
	if phase > SaveManager.data["best_phase"]:
		SaveManager.data["best_phase"] = phase
	SaveManager.save_game()
	get_tree().paused = true

func _on_restart_button_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

# ── Panel toggle ──────────────────────────────
func _on_panel_handle_pressed():
	panel_open = !panel_open
	var target_y = 1280 - 400 if panel_open else 1280
	var panel = $UI/UpgradePanel
	var tween = create_tween()
	tween.tween_property(panel, "position:y", target_y, 0.2)
	$UI/UpgradePanel/PanelHandle.text = "▼ UPGRADES" if panel_open else "▲ UPGRADES"

# ── UI update ─────────────────────────────────
func _update_ui():
	$UI/CurrencyLabel.text = "Gold: " + str(currency) + "  |  LP: " + str(legacy_points)
	$UI/WaveLabel.text = "Wave: " + str(wave) + " | Phase: " + str(phase)

	# ATK
	_update_btn($UI/UpgradePanel/ColumnsContainer/ATKColumn/ATKSpdButton,
		"ATK SPD", attack_speed_level, attack_speed_max, attack_speed_cost,
		str(snappedf(1.0 + (attack_speed_level * 0.15), 0.01)) + "/s")
	_update_btn($UI/UpgradePanel/ColumnsContainer/ATKColumn/DmgButton,
		"DMG", damage_level, damage_max, damage_cost,
		str(10 + damage_level))
	_update_btn($UI/UpgradePanel/ColumnsContainer/ATKColumn/DmgMultButton,
		"DMG MULT", dmg_mult_level, dmg_mult_max, dmg_mult_cost,
		"+" + str(dmg_mult_level * 10) + "%")
	_update_btn($UI/UpgradePanel/ColumnsContainer/ATKColumn/CritChanceButton,
		"CRIT %", crit_chance_level, crit_chance_max, crit_chance_cost,
		str(snappedf(crit_chance_level * 1.25, 0.01)) + "%")
	_update_btn($UI/UpgradePanel/ColumnsContainer/ATKColumn/CritDmgButton,
		"CRIT DMG", crit_dmg_level, crit_dmg_max, crit_dmg_cost,
		"+" + str(crit_dmg_level * 10) + "%")

	# DEF
	# DEF
	_update_btn($UI/UpgradePanel/ColumnsContainer/DEFColumn/ShieldButton,
		"SHIELD", shield_level, shield_max, shield_cost,
		str(shield_level * 20))
	_update_btn($UI/UpgradePanel/ColumnsContainer/DEFColumn/ShieldRegenButton,
		"SHLD RGN", shield_regen_level, shield_regen_max, shield_regen_cost,
		str(shield_regen_level) + "/s")
	_update_btn($UI/UpgradePanel/ColumnsContainer/DEFColumn/ShieldStrengthButton,
		"SHLD STR", shield_strength_level, shield_strength_max, shield_strength_cost,
		str(snappedf(shield_strength_level * 0.4, 0.1)) + "%")
	_update_btn($UI/UpgradePanel/ColumnsContainer/DEFColumn/ShieldMultButton,
		"SHLD MULT", shield_mult_level, shield_mult_max, shield_mult_cost,
		"+" + str(shield_mult_level * 10) + "%")
	_update_btn($UI/UpgradePanel/ColumnsContainer/DEFColumn/EvasionButton,
		"EVASION", evasion_level, evasion_max, evasion_cost,
		str(snappedf(evasion_level * 0.2, 0.1)) + "%")

	# HP
	_update_btn($UI/UpgradePanel/ColumnsContainer/HPColumn/MaxHPButton,
		"MAX HP", max_hp_level, max_hp_max, max_hp_cost,
		str(100 + (max_hp_level * 20)))
	_update_btn($UI/UpgradePanel/ColumnsContainer/HPColumn/RegenAmtButton,
		"REGEN AMT", regen_amt_level, regen_amt_max, regen_amt_cost,
		str(regen_amt_level) + " hp")
	_update_btn($UI/UpgradePanel/ColumnsContainer/HPColumn/RegenSpdButton,
		"REGEN SPD", regen_spd_level, regen_spd_max, regen_spd_cost,
		str(max(1.0, 5.0 - (regen_spd_level * 0.1))) + "s")
	_update_btn($UI/UpgradePanel/ColumnsContainer/HPColumn/HPMultButton,
		"HP MULT", hp_mult_level, hp_mult_max, hp_mult_cost,
		"+" + str(hp_mult_level * 10) + "%")
	_update_btn($UI/UpgradePanel/ColumnsContainer/HPColumn/HealMultButton,
		"HEAL MULT", heal_mult_level, heal_mult_max, heal_mult_cost,
		"+" + str(heal_mult_level * 10) + "%")

	# UTIL
	_update_btn($UI/UpgradePanel/ColumnsContainer/UTILColumn/GoldPerKillButton,
		"GOLD/KILL", gold_per_kill_level, gold_per_kill_max, gold_per_kill_cost,
		"+" + str(gold_per_kill_level * 2) + "g")
	_update_btn($UI/UpgradePanel/ColumnsContainer/UTILColumn/GoldMultButton,
		"GOLD MULT", gold_mult_level, gold_mult_max, gold_mult_cost,
		"+" + str(gold_mult_level * 10) + "%")
	_update_btn($UI/UpgradePanel/ColumnsContainer/UTILColumn/LegacyPerWaveButton,
		"LP/WAVE", legacy_per_wave_level, legacy_per_wave_max, legacy_per_wave_cost,
		"+" + str(legacy_per_wave_level))
	_update_btn($UI/UpgradePanel/ColumnsContainer/UTILColumn/LegacyMultButton,
		"LP MULT", legacy_mult_level, legacy_mult_max, legacy_mult_cost,
		"+" + str(legacy_mult_level * 10) + "%")
	_update_btn($UI/UpgradePanel/ColumnsContainer/UTILColumn/LegacyDropButton,
		"LP CHANCE", legacy_drop_level, legacy_drop_max, legacy_drop_cost,
		str(legacy_drop_level * 5) + "%")

func _update_btn(btn: Button, label: String, level: int, max_level: int, cost: int, stat: String):
	if level >= max_level:
		btn.text = label + "\nMAX (" + stat + ")"
		btn.disabled = true
	else:
		btn.text = label + "\nLv" + str(level + 1) + " - " + str(cost) + "g\n" + stat
		btn.disabled = currency < cost

# ── ATK handlers ──────────────────────────────
func _on_atk_spd_button_pressed():
	if currency < attack_speed_cost or attack_speed_level >= attack_speed_max: return
	currency -= attack_speed_cost
	attack_speed_level += 1
	attack_speed_cost = int(attack_speed_cost * 1.2)
	$Base.fire_rate += 0.125
	_update_ui()

func _on_dmg_button_pressed():
	if currency < damage_cost or damage_level >= damage_max: return
	currency -= damage_cost
	damage_level += 1
	damage_cost = int(damage_cost * 1.2)
	$Base.bullet_damage += 1.0
	_update_ui()

func _on_dmg_mult_button_pressed():
	if currency < dmg_mult_cost or dmg_mult_level >= dmg_mult_max: return
	currency -= dmg_mult_cost
	dmg_mult_level += 1
	dmg_mult_cost = int(dmg_mult_cost * 1.25)
	$Base.damage_multiplier += 0.1
	_update_ui()

func _on_crit_chance_button_pressed():
	if currency < crit_chance_cost or crit_chance_level >= crit_chance_max: return
	currency -= crit_chance_cost
	crit_chance_level += 1
	crit_chance_cost = int(crit_chance_cost * 1.3)
	$Base.crit_chance += 0.0125
	_update_ui()

func _on_crit_dmg_button_pressed():
	if currency < crit_dmg_cost or crit_dmg_level >= crit_dmg_max: return
	currency -= crit_dmg_cost
	crit_dmg_level += 1
	crit_dmg_cost = int(crit_dmg_cost * 1.25)
	$Base.crit_damage += 0.10
	_update_ui()

# ── DEF handlers ──────────────────────────────
func _on_shield_button_pressed():
	if currency < shield_cost or shield_level >= shield_max: return
	currency -= shield_cost
	shield_level += 1
	shield_cost = int(shield_cost * 1.2)
	$Base.max_shield += 20.0
	$Base.shield += 20.0
	$Base._update_combat_ui()
	_update_ui()

func _on_shield_regen_button_pressed():
	if currency < shield_regen_cost or shield_regen_level >= shield_regen_max: return
	currency -= shield_regen_cost
	shield_regen_level += 1
	shield_regen_cost = int(shield_regen_cost * 1.25)
	$Base.shield_regen += 1.0
	_update_ui()

func _on_shield_strength_button_pressed():
	if currency < shield_strength_cost or shield_strength_level >= shield_strength_max: return
	currency -= shield_strength_cost
	shield_strength_level += 1
	shield_strength_cost = int(shield_strength_cost * 1.3)
	$Base.shield_strength += 0.004  # 0.4% per level
	_update_ui()

func _on_shield_mult_button_pressed():
	if currency < shield_mult_cost or shield_mult_level >= shield_mult_max: return
	currency -= shield_mult_cost
	shield_mult_level += 1
	shield_mult_cost = int(shield_mult_cost * 1.25)
	$Base.shield_multiplier += 0.1
	_update_ui()

func _on_evasion_button_pressed():
	if currency < evasion_cost or evasion_level >= evasion_max: return
	currency -= evasion_cost
	evasion_level += 1
	evasion_cost = int(evasion_cost * 1.3)
	$Base.evasion += 0.002  # 0.2% per level
	_update_ui()

# ── HP handlers ───────────────────────────────
func _on_max_hp_button_pressed():
	if currency < max_hp_cost or max_hp_level >= max_hp_max: return
	currency -= max_hp_cost
	max_hp_level += 1
	max_hp_cost = int(max_hp_cost * 1.2)
	$Base.increase_max_health(20.0)
	_update_ui()

func _on_regen_amt_button_pressed():
	if currency < regen_amt_cost or regen_amt_level >= regen_amt_max: return
	currency -= regen_amt_cost
	regen_amt_level += 1
	regen_amt_cost = int(regen_amt_cost * 1.25)
	$Base.hp_regen += 1.0
	_update_ui()

func _on_regen_spd_button_pressed():
	if currency < regen_spd_cost or regen_spd_level >= regen_spd_max: return
	currency -= regen_spd_cost
	regen_spd_level += 1
	regen_spd_cost = int(regen_spd_cost * 1.2)
	$Base.regen_interval = max(1.0, 5.0 - (regen_spd_level * 0.1))
	_update_ui()

func _on_heal_mult_button_pressed():
	if currency < heal_mult_cost or heal_mult_level >= heal_mult_max: return
	currency -= heal_mult_cost
	heal_mult_level += 1
	heal_mult_cost = int(heal_mult_cost * 1.25)
	$Base.heal_multiplier += 0.1
	_update_ui()

# ── UTIL handlers ─────────────────────────────
func _on_gold_per_kill_button_pressed():
	if currency < gold_per_kill_cost or gold_per_kill_level >= gold_per_kill_max: return
	currency -= gold_per_kill_cost
	gold_per_kill_level += 1
	gold_per_kill_cost = int(gold_per_kill_cost * 1.2)
	_update_ui()

func _on_gold_mult_button_pressed():
	if currency < gold_mult_cost or gold_mult_level >= gold_mult_max: return
	currency -= gold_mult_cost
	gold_mult_level += 1
	gold_mult_cost = int(gold_mult_cost * 1.25)
	_update_ui()

func _on_legacy_per_wave_button_pressed():
	if currency < legacy_per_wave_cost or legacy_per_wave_level >= legacy_per_wave_max: return
	currency -= legacy_per_wave_cost
	legacy_per_wave_level += 1
	legacy_per_wave_cost = int(legacy_per_wave_cost * 1.2)
	_update_ui()

func _on_legacy_mult_button_pressed():
	if currency < legacy_mult_cost or legacy_mult_level >= legacy_mult_max: return
	currency -= legacy_mult_cost
	legacy_mult_level += 1
	legacy_mult_cost = int(legacy_mult_cost * 1.25)
	_update_ui()

func _on_legacy_drop_button_pressed():
	if currency < legacy_drop_cost or legacy_drop_level >= legacy_drop_max: return
	currency -= legacy_drop_cost
	legacy_drop_level += 1
	legacy_drop_cost = int(legacy_drop_cost * 1.3)
	_update_ui()

func _random_edge_position() -> Vector2:
	var edge = randi() % 4
	match edge:
		0: return Vector2(randf_range(0, 720), -20)
		1: return Vector2(randf_range(0, 720), 1300)
		2: return Vector2(-20, randf_range(0, 1280))
		3: return Vector2(740, randf_range(0, 1280))
	return Vector2.ZERO


# ── Pause ─────────────────────────────────────
func _on_pause_button_pressed():
	get_tree().paused = true
	$UI/PauseScreen.visible = true

func _on_resume_button_pressed():
	get_tree().paused = false
	$UI/PauseScreen.visible = false

func _on_pause_restart_button_pressed():
	get_tree().paused = false
	await get_tree().process_frame
	get_tree().reload_current_scene()

func _on_pause_menu_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/StartMenu.tscn")

# ── Game Over extra button ─────────────────────
func _on_menu_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/StartMenu.tscn")


func _on_hp_mult_button_pressed():
	if currency < hp_mult_cost or hp_mult_level >= hp_mult_max: return
	currency -= hp_mult_cost
	hp_mult_level += 1
	hp_mult_cost = int(hp_mult_cost * 1.25)
	$Base.hp_multiplier += 0.1
	_update_ui()
