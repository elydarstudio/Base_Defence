extends Node

var main: Node = null
var base: Node = null

func setup(main_node: Node, base_node: Node):
	main = main_node
	base = base_node

# ── Cost Calculators ──────────────────────────
func calc_cost(base_cost: int, level: int, is_capped: bool) -> int:
	if is_capped:
		var scale = 1.23 if level < 50 else 1.4
		return int(base_cost * pow(scale, level))
	else:
		return int(base_cost * pow(1.2, level))

func calc_cost_flat(base_cost: int, level: int) -> int:
	return int(base_cost * pow(1.15, level))

func calc_cost_mult(base_cost: int, level: int) -> int:
	return int(base_cost * pow(1.25, level))

func calc_atk_spd(level: int) -> float:
	var rate = 1.0
	for i in range(level):
		rate += 0.115 / (1.0 + i * 0.02)
	return rate
	
func calc_regen_spd(level: int) -> float:
	var interval = 5.0
	for i in range(level):
		interval -= 0.25 / (1.0 + i * 0.05)
	return max(0.5, interval)

# ── ATK Handlers ──────────────────────────────
func on_atk_spd(buy_amount: int):
	for i in buy_amount:
		if main.currency < main.attack_speed_cost or main.attack_speed_level >= main.attack_speed_max: break
		main.currency -= main.attack_speed_cost
		main.attack_speed_level += 1
		main.attack_speed_upgrades += 1
		main.attack_speed_cost = calc_cost(45, main.attack_speed_upgrades, true)
		base.fire_rate = calc_atk_spd(main.attack_speed_level)
	main._update_ui()

func on_dmg(buy_amount: int):
	for i in buy_amount:
		if main.currency < main.damage_cost or main.damage_level >= main.damage_max: break
		main.currency -= main.damage_cost
		main.damage_level += 1
		main.damage_upgrades += 1
		main.damage_cost = calc_cost_flat(30, main.damage_upgrades)
		base.bullet_damage += 1.0
	main._update_ui()

func on_dmg_mult(buy_amount: int):
	for i in buy_amount:
		if main.currency < main.dmg_mult_cost or main.dmg_mult_level >= main.dmg_mult_max: break
		main.currency -= main.dmg_mult_cost
		main.dmg_mult_level += 1
		main.dmg_mult_upgrades += 1
		main.dmg_mult_cost = calc_cost_mult(45, main.dmg_mult_upgrades)
		base.damage_multiplier += 0.1
	main._update_ui()

func on_crit_chance(buy_amount: int):
	for i in buy_amount:
		if main.currency < main.crit_chance_cost or main.crit_chance_level >= main.crit_chance_max: break
		main.currency -= main.crit_chance_cost
		main.crit_chance_level += 1
		main.crit_chance_upgrades += 1
		main.crit_chance_cost = calc_cost(50, main.crit_chance_upgrades, true)
		base.crit_chance += 0.008
	main._update_ui()

func on_crit_dmg(buy_amount: int):
	for i in buy_amount:
		if main.currency < main.crit_dmg_cost or main.crit_dmg_level >= main.crit_dmg_max: break
		main.currency -= main.crit_dmg_cost
		main.crit_dmg_level += 1
		main.crit_dmg_upgrades += 1
		main.crit_dmg_cost = calc_cost_mult(40, main.crit_dmg_upgrades)
		base.crit_damage += 0.10
	main._update_ui()

# ── DEF Handlers ──────────────────────────────
func on_shield(buy_amount: int):
	for i in buy_amount:
		if main.currency < main.shield_cost or main.shield_level >= main.shield_max: break
		main.currency -= main.shield_cost
		main.shield_level += 1
		main.shield_upgrades += 1
		main.shield_cost = calc_cost(28, main.shield_upgrades, false)
		base.max_shield += 20.0
		base.shield += 20.0
	base._update_combat_ui()
	main._update_ui()

func on_shield_regen(buy_amount: int):
	for i in buy_amount:
		if main.currency < main.shield_regen_cost or main.shield_regen_level >= main.shield_regen_max: break
		main.currency -= main.shield_regen_cost
		main.shield_regen_level += 1
		main.shield_regen_upgrades += 1
		main.shield_regen_cost = calc_cost(35, main.shield_regen_upgrades, true)
		base.shield_regen_interval = calc_regen_spd(main.shield_regen_level)
	main._update_ui()

func on_shield_strength(buy_amount: int):
	for i in buy_amount:
		if main.currency < main.shield_strength_cost or main.shield_strength_level >= main.shield_strength_max: break
		main.currency -= main.shield_strength_cost
		main.shield_strength_level += 1
		main.shield_strength_upgrades += 1
		main.shield_strength_cost = calc_cost(45, main.shield_strength_upgrades, true)
		base.shield_strength += 0.004
	main._update_ui()

func on_shield_mult(buy_amount: int):
	for i in buy_amount:
		if main.currency < main.shield_mult_cost or main.shield_mult_level >= main.shield_mult_max: break
		main.currency -= main.shield_mult_cost
		main.shield_mult_level += 1
		main.shield_mult_upgrades += 1
		main.shield_mult_cost = calc_cost(35, main.shield_mult_upgrades, false)
		base.shield_multiplier += 0.1
	main._update_ui()

func on_evasion(buy_amount: int):
	for i in buy_amount:
		if main.currency < main.evasion_cost or main.evasion_level >= main.evasion_max: break
		main.currency -= main.evasion_cost
		main.evasion_level += 1
		main.evasion_upgrades += 1
		main.evasion_cost = calc_cost(50, main.evasion_upgrades, true)
		base.evasion += 0.002
	main._update_ui()

# ── HP Handlers ───────────────────────────────
func on_max_hp(buy_amount: int):
	for i in buy_amount:
		if main.currency < main.max_hp_cost or main.max_hp_level >= main.max_hp_max: break
		main.currency -= main.max_hp_cost
		main.max_hp_level += 1
		main.max_hp_upgrades += 1
		main.max_hp_cost = calc_cost_flat(22, main.max_hp_upgrades)
		base.increase_max_health(10.0)
	main._update_ui()

func on_regen_amt(buy_amount: int):
	for i in buy_amount:
		if main.currency < main.regen_amt_cost or main.regen_amt_level >= main.regen_amt_max: break
		main.currency -= main.regen_amt_cost
		main.regen_amt_level += 1
		main.regen_amt_upgrades += 1
		main.regen_amt_cost = calc_cost_flat(18, main.regen_amt_upgrades)
		base.hp_regen += 1.0
	main._update_ui()

func on_regen_spd(buy_amount: int):
	for i in buy_amount:
		if main.currency < main.regen_spd_cost or main.regen_spd_level >= main.regen_spd_max: break
		main.currency -= main.regen_spd_cost
		main.regen_spd_level += 1
		main.regen_spd_upgrades += 1
		main.regen_spd_cost = calc_cost(25, main.regen_spd_upgrades, true)
		base.regen_interval = calc_regen_spd(main.regen_spd_level)
	main._update_ui()

func on_hp_mult(buy_amount: int):
	for i in buy_amount:
		if main.currency < main.hp_mult_cost or main.hp_mult_level >= main.hp_mult_max: break
		main.currency -= main.hp_mult_cost
		main.hp_mult_level += 1
		main.hp_mult_upgrades += 1
		main.hp_mult_cost = calc_cost(35, main.hp_mult_upgrades, false)
		base.hp_multiplier += 0.1
		base.health = min(base.health, base.get_effective_max_hp())
	base._update_combat_ui()
	main._update_ui()

func on_heal_mult(buy_amount: int):
	for i in buy_amount:
		if main.currency < main.heal_mult_cost or main.heal_mult_level >= main.heal_mult_max: break
		main.currency -= main.heal_mult_cost
		main.heal_mult_level += 1
		main.heal_mult_upgrades += 1
		main.heal_mult_cost = calc_cost(30, main.heal_mult_upgrades, false)
		base.heal_multiplier += 0.1
	main._update_ui()

# ── UTIL Handlers ─────────────────────────────
func on_gold_per_kill(buy_amount: int):
	for i in buy_amount:
		if main.currency < main.gold_per_kill_cost or main.gold_per_kill_level >= main.gold_per_kill_max: break
		main.currency -= main.gold_per_kill_cost
		main.gold_per_kill_level += 1
		main.gold_per_kill_upgrades += 1
		main.gold_per_kill_cost = calc_cost_flat(22, main.gold_per_kill_upgrades)
	main._update_ui()

func on_gold_mult(buy_amount: int):
	for i in buy_amount:
		if main.currency < main.gold_mult_cost or main.gold_mult_level >= main.gold_mult_max: break
		main.currency -= main.gold_mult_cost
		main.gold_mult_level += 1
		main.gold_mult_upgrades += 1
		main.gold_mult_cost = calc_cost_mult(50, main.gold_mult_upgrades)
	main._update_ui()

func on_lp_gain(buy_amount: int):
	for i in buy_amount:
		if main.currency < main.lp_gain_cost or main.lp_gain_level >= main.lp_gain_max: break
		main.currency -= main.lp_gain_cost
		main.lp_gain_level += 1
		main.lp_gain_upgrades += 1
		main.lp_gain_cost = calc_cost_flat(22, main.lp_gain_upgrades)
	main._update_ui()

func on_legacy_mult(buy_amount: int):
	for i in buy_amount:
		if main.currency < main.legacy_mult_cost or main.legacy_mult_level >= main.legacy_mult_max: break
		main.currency -= main.legacy_mult_cost
		main.legacy_mult_level += 1
		main.legacy_mult_upgrades += 1
		main.legacy_mult_cost = calc_cost_mult(50, main.legacy_mult_upgrades)
	main._update_ui()

func on_legacy_drop(buy_amount: int):
	for i in buy_amount:
		if main.currency < main.legacy_drop_cost or main.legacy_drop_level >= main.legacy_drop_max: break
		main.currency -= main.legacy_drop_cost
		main.legacy_drop_level += 1
		main.legacy_drop_upgrades += 1
		main.legacy_drop_cost = calc_cost(35, main.legacy_drop_upgrades, true)
	main._update_ui()

# ── Workshop Floors ───────────────────────────
func apply_workshop_floors():
	var d = SaveManager.data
	main.attack_speed_level = d["floor_attack_speed"]
	base.fire_rate = calc_atk_spd(main.attack_speed_level)
	main.damage_level = d["floor_damage"]
	base.bullet_damage += main.damage_level * 1.0
	main.dmg_mult_level = d["floor_dmg_mult"]
	base.damage_multiplier += main.dmg_mult_level * 0.1
	main.crit_chance_level = d["floor_crit_chance"]
	base.crit_chance += main.crit_chance_level * 0.0125
	main.crit_dmg_level = d["floor_crit_dmg"]
	base.crit_damage += main.crit_dmg_level * 0.10
	main.shield_level = d["floor_shield"]
	base.max_shield += main.shield_level * 20.0
	base.shield += main.shield_level * 20.0
	main.shield_regen_level = d["floor_shield_regen"]
	base.shield_regen_interval = str(snappedf(calc_regen_spd(main.shield_regen_level), 0.01)) + "s"
	main.shield_strength_level = d["floor_shield_strength"]
	base.shield_strength += main.shield_strength_level * 0.003
	main.shield_mult_level = d["floor_shield_mult"]
	base.shield_multiplier += main.shield_mult_level * 0.1
	main.evasion_level = d["floor_evasion"]
	base.evasion += main.evasion_level * 0.002
	main.max_hp_level = d["floor_max_hp"]
	base.increase_max_health(main.max_hp_level * 10.0)
	main.regen_amt_level = d["floor_regen_amt"]
	base.hp_regen += main.regen_amt_level * 1.0
	main.regen_spd_level = d["floor_regen_spd"]
	base.regen_interval = str(snappedf(calc_regen_spd(main.regen_spd_level), 0.01)) + "s"
	main.heal_mult_level = d["floor_heal_mult"]
	base.heal_multiplier += main.heal_mult_level * 0.1
	main.hp_mult_level = d["floor_hp_mult"]
	base.hp_multiplier += main.hp_mult_level * 0.1
	base.health = base.get_effective_max_hp()
	base._update_combat_ui()
	main.gold_per_kill_level = d["floor_gold_per_kill"]
	main.gold_mult_level = d["floor_gold_mult"]
	main.lp_gain_level = d["floor_lp_gain"]
	main.legacy_mult_level = d["floor_legacy_mult"]
	main.legacy_drop_level = d["floor_legacy_drop"]
