# Phasefall — Game Design Document
**Studio:** Elydar Studios
**Engine:** Godot 4
**Target:** Mobile (portrait 720x1280) + Browser
**Status:** Core loop complete, workshop next

---

## Current Build State
Everything below is BUILT and WORKING:
- Base (blue hexagon) center screen, auto-shoots nearest enemy
- Smart bullet targeting — locks onto target, no stray bullets, prioritizes closest to base
- Crit system — orange bullets for crits, yellow for normal
- Enemies spawn from all 4 edges, walk to base, melee attack every 1.5s
- Enemy health bars (green/yellow/red), damage numbers pop off on hit
- Boss spawns every wave % 10 == 0, purple octagon, has HP bar with number
- Wave timer (25s per wave), phase tracker, difficulty variable (never resets)
- Gold economy — base 5g + (phase * 3), scales per phase not per wave
- Legacy points — earned per wave, % chance per kill
- Slide-up upgrade panel — 4 columns (ATK/DEF/HP/UTIL), 20 total stats
- Shield system — absorbs damage before HP, regenerates over time
- HP regen system — tick-based, recovery delay before regen starts
- Damage reduction — % reduction before shield absorbs
- Knockback — pushes enemies away from base on interval
- Game over screen — shows phase reached, restart button
- All 20 upgrade handlers wired and functional

---

## File Structure
```
base-defence/
├── main.tscn
├── project.godot
├── Scenes/
│   ├── Enemy.tscn
│   ├── Boss.tscn
│   ├── Projectile.tscn
│   └── damage_number.tscn
├── Scripts/
│   ├── main.gd        # Game loop, spawning, all upgrade handlers, UI
│   ├── base.gd        # Shooting, crit, shield, HP regen, knockback, damage
│   ├── enemy.gd       # Movement, melee attack, health bar, scaling
│   ├── boss.gd        # Boss behavior, HP bar, scaling
│   ├── projectile.gd  # Bullet movement, homing, crit color
│   └── damage_number.gd # Floating damage text
└── Assets/
```

---

## Scene Tree (main.tscn)
```
Main (Node2D) — main.gd
├── Base (Area2D) — base.gd
│   ├── CollisionShape2D
│   └── Visual (Polygon2D)
├── DamageLayer (CanvasLayer)
└── UI (CanvasLayer)
	├── CurrencyLabel
	├── WaveLabel
	├── BaseHealthLabel
	├── GameOverScreen (ColorRect) [hidden by default]
	│   ├── GameOverLabel
	│   ├── PhaseLabel
	│   └── RestartButton
	└── UpgradePanel (Control) [slides up from bottom]
		├── PanelBG (ColorRect)
		├── PanelHandle (Button) → _on_panel_handle_pressed
		└── ColumnsContainer (HBoxContainer)
			├── ATKColumn (VBoxContainer)
			│   ├── ATKHeader (Label)
			│   ├── ATKSpdButton → _on_atk_spd_button_pressed
			│   ├── DmgButton → _on_dmg_button_pressed
			│   ├── DmgMultButton → _on_dmg_mult_button_pressed
			│   ├── CritChanceButton → _on_crit_chance_button_pressed
			│   └── CritDmgButton → _on_crit_dmg_button_pressed
			├── DEFColumn (VBoxContainer)
			│   ├── DEFHeader (Label)
			│   ├── ShieldButton → _on_shield_button_pressed
			│   ├── ShieldRegenButton → _on_shield_regen_button_pressed
			│   ├── DmgReductButton → _on_dmg_reduct_button_pressed
			│   ├── KnockbackFreqButton → _on_knockback_freq_button_pressed
			│   └── KnockbackStrButton → _on_knockback_str_button_pressed
			├── HPColumn (VBoxContainer)
			│   ├── HPHeader (Label)
			│   ├── MaxHPButton → _on_max_hp_button_pressed
			│   ├── RegenAmtButton → _on_regen_amt_button_pressed
			│   ├── RegenSpdButton → _on_regen_spd_button_pressed
			│   ├── RecovDelayButton → _on_recov_delay_button_pressed
			│   └── HealMultButton → _on_heal_mult_button_pressed
			└── UTILColumn (VBoxContainer)
				├── UTILHeader (Label)
				├── GoldPerKillButton → _on_gold_per_kill_button_pressed
				├── GoldMultButton → _on_gold_mult_button_pressed
				├── LegacyPerWaveButton → _on_legacy_per_wave_button_pressed
				├── LegacyMultButton → _on_legacy_mult_button_pressed
				└── LegacyDropButton → _on_legacy_drop_button_pressed
```

---

## Core Systems

### Difficulty Scaling
- difficulty variable never resets
- Increments +1 per wave, +3 per boss kill
- Enemy HP: 8.0 * (1.0 + (difficulty * 0.27) + (pow(difficulty, 1.4) * 0.03))
- Enemy attack damage: 7.0 * (1.0 + (difficulty * 0.11))
- Enemy speed: min(72.0 + (difficulty * 1.1), 155.0)
- Spawn interval: max(0.3, 1.25 - (difficulty * 0.045))

### Gold Economy
- Base drop: 5 + (main_node.phase * 3) per kill
- Phase 1: 8g/kill, Phase 2: 11g/kill, Phase 3: 14g/kill
- Gold Per Kill upgrade: +1g flat per level
- Gold Multiplier: +10% per level (infinite)
- Boss drop: 100g flat

### Wave Structure
- 25 seconds per wave
- Wave % 10 == 0 = boss wave
- Boss: 160 HP base, 20 attack damage, scales with difficulty * 0.3

### Bullet System
- Locks onto target, never switches
- Only fires if target needs more bullets
- Crits: orange bullets, normal: yellow

### Shield + HP System
- Damage reduction first → shield absorbs → HP takes remainder
- Recovery delay pauses HP regen after damage

---

## 20 Core Stats

### ATK (5)
- Attack Speed: +0.125/s, Lv40, 35g start, x1.2
- Base Damage: +1 dmg, Lv90, 30g start, x1.2
- Damage Multiplier: +10%, Infinite, 60g, x1.25
- Crit Chance: +5%, 80% cap (Lv16), 40g, x1.3
- Crit Damage: +25%, Infinite, 60g, x1.25

### DEF (5)
- Max Shield: +20, Lv40, 35g, x1.2
- Shield Regen: +1/s, Infinite, 50g, x1.25
- Damage Reduction: +2%, 20% cap (Lv10), 45g, x1.2
- Knockback Freq: -0.2s interval, Lv20, 40g, x1.2
- Knockback Strength: +20, Lv20, 40g, x1.2

### HP (5)
- Max Health: +20, Lv40, 35g, x1.2
- Regen Amount: +1 hp/tick, Infinite, 40g, x1.25
- Regen Speed: -0.1s interval, Lv40 (min 1s), 40g, x1.2
- Recovery Delay: -0.15s, Lv20 (min 0s), 35g, x1.2
- Heal Multiplier: +10%, Infinite, 60g, x1.25

### UTIL (5)
- Gold Per Kill: +1g, Lv40, 20g, x1.2
- Gold Multiplier: +10%, Infinite, 50g, x1.25
- Legacy Per Wave: +1 LP, Lv40, 20g, x1.2
- Legacy Multiplier: +10%, Infinite, 50g, x1.25
- Legacy Drop Chance: +5%, 40% cap (Lv8), 40g, x1.3

---

## Unlock System (NOT YET BUILT)
Single unlock_level variable gates what's visible in upgrade panel AND workshop.

- unlock_level 0 (new game): ATK SPD + Base Damage only
- unlock_level 1 (die to boss): + Shield, Shield Regen, Max HP, HP Regen
- unlock_level 2 (beat boss): + DMG Mult, Crit Chance, Regen Spd, Recov Delay, workshop opens
- unlock_level 3 (reach Phase 3): Everything — all 20 stats, skill tree, full workshop

---

## Workshop (NOT YET BUILT)
- Accessed from game over screen after first boss kill
- Two sections: Core Stat Floors + Skill Tree
- Spend Legacy Points on permanent starting levels
- Same stat values as mid-run (workshop Lv5 = mid-run Lv5)
- LP costs scale much steeper than gold costs
- In-game upgrade cost resets to base from floor level
- Workshop Lv5 floor means in-game Lv6 costs same as Lv1 would from zero

---

## Phase Start Selector (NOT YET BUILT)
- Unlocks after beating first boss
- Lets veteran players skip to higher phases

---

## Skill Trees (NOT YET BUILT)
- 3 trees: Attack / Defense / Healing
- Launch with 5-6 skills per tree, expand post-launch
- Hard cap: 50 skill points total ever
- 1 skill point per phase boss beaten
- Requires unlock_level 3
- Skills modify BEHAVIOR not raw stats
- Each node upgradeable infinitely (steep LP cost)
- 5-6 active skills per tree for leaderboard play

ATK Tree: Multishot, Pierce, Bounce, Explosion on crit, Chain lightning
DEF Tree: Thorns, Block chance, Shield spike, Damage reflection
HP Tree: Overheal aura, Regen burst, Healing pulse

---


Skill Progression (Kill-Based)

Skill points (from phase bosses) unlock skills
Once unlocked, skills level up automatically through enemy kills
Kill count is tracked globally and persists between runs
Skill levels only apply to unlocked skills — kills before unlock don't count retroactively
Runs are never pointless — kills always contribute to something
Tournament mode resets kill-based skill levels to base for fair competition
Kill counter should be visible to player so progression feels real
Scaling should be steep enough that casual players feel growth, veterans feel mastery

## Meta Progression Loop
1. Run → die → earn LP based on phase reached
2. Spend LP in workshop on permanent stat floors
3. New stats unlock based on milestones
4. Beat first boss → workshop opens, phase selector unlocks
5. Reach Phase 3 → skill trees unlock
6. Veteran players start at higher phases to farm or push leaderboard

---

## Remaining Build Order
1. Workshop screen + LP spending
2. Unlock system (unlock_level gates stats in panel + workshop)
3. Onboarding (new game shows only ATK SPD + DMG)
4. Phase start selector
5. Skill tree UI + mechanics
6. Enemy death explosion effect
7. Base visual evolution
8. Sound effects
9. Enemy variety (2-3 new types)
10. Leaderboard
11. Speed multiplier toggle (1x/2x/3x)
12. Browser export + mobile polish
13. itch.io launch

---

## Design Principles
- Core stats = power, Skill trees = behavior
- Economic self-regulation — infinite stats get expensive naturally
- Death is informative — each run teaches what you needed
- Build identity — 50 skill point cap forces meaningful choices
- Same stat values everywhere — workshop floor just sets starting level
- All three trees can win, just differently
- Never fully done — infinite scaling keeps veterans engaged
