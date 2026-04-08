extends Node

var main: Node = null

func setup(main_node: Node):
	main = main_node

# ── Gold & LP calculation ──────────────────────
func calc_gold(base_amount: int, gold_per_kill_level: int, gold_mult_level: int) -> int:
	var total = base_amount + gold_per_kill_level
	return int(total * (1.0 + (gold_mult_level * 0.1)))

func calc_lp_drop(lp_gain_level: int, legacy_mult_level: int) -> int:
	return int((1 + lp_gain_level) * (1.0 + (legacy_mult_level * 0.1)))

func calc_drop_chance(legacy_drop_level: int) -> float:
	return 0.05 + (legacy_drop_level * 0.0055)

func calc_wave_lp(lp_gain_level: int, legacy_mult_level: int) -> int:
	var earned = 1 + lp_gain_level
	return int(earned * (1.0 + (legacy_mult_level * 0.1)))
