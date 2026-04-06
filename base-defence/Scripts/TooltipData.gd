extends Node

const TIPS = {
	"atk_spd": "How fast the base fires. More attacks = more damage output.",
	"damage": "Base damage per bullet. Multiplied by Damage Multiplier and Crits.",
	"dmg_mult": "Multiplies all bullet damage. Stacks with Base Damage.",
	"crit_chance": "% chance each bullet deals bonus crit damage. Caps at 80%.",
	"crit_dmg": "Multiplier applied on a crit hit. Base is 1.5x.",
	"shield": "Absorbs incoming hits before HP is touched. Regens automatically.",
	"shield_regen": "How fast shield recharges. Regens 10% of max shield per tick.",
	"shield_strength": "Reduces HP damage on shielded hits. Base 10%, caps at 40%.",
	"shield_mult": "Multiplies your effective max shield ceiling.",
	"evasion": "% chance to completely dodge an incoming hit. Caps at 20%.",
	"max_hp": "Increases your maximum HP pool.",
	"regen_amt": "HP restored per regen tick.",
	"regen_spd": "How often HP regen ticks. Faster = more healing per second.",
	"hp_mult": "Multiplies your effective max HP.",
	"heal_mult": "Multiplies all HP healed per tick.",
	"gold_per_kill": "Flat gold added to every enemy kill.",
	"gold_mult": "Multiplies all gold earned from kills.",
	"lp_gain": "Flat LP added to every LP source — waves and drops.",
	"lp_mult": "Multiplies all LP earned from waves and drops.",
	"lp_drop": "% chance an enemy drop includes a Legacy Point. Caps at 40%.",
}
