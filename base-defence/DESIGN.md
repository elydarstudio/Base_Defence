# Phasefall — Game Design Document
**Studio:** Elydar Studios
**Engine:** Godot 4
**Target:** Mobile (portrait 720x1280) + Browser
**Status:** Core loop, workshop, onboarding, phase select all complete. V1 testing phase.

---

## Current Build State (Day 3)
Everything below is BUILT and WORKING:
- Start menu with studio branding, phase selector (◀ PHASE X ▶), workshop button
- SaveManager autoload — persistent save across sessions
- Full game loop: spawn → kill → upgrade → die → workshop → run again
- Base (blue hexagon) center screen, auto-shoots nearest enemy
- Smart bullet targeting — locks onto target, prioritizes closest to base, no wasted shots
- Crit system — 1.5x base crit damage, scales with Crit DMG upgrade
- Enemies spawn from all 4 edges, walk to base, melee attack every 1.5s
- Enemy health bars (green/yellow/red), floating damage numbers (white normal, orange crit)
- Boss spawns every wave % 10, purple octagon, HP bar with number display
- Wave timer (25s), phase tracker, difficulty variable (never resets, +1/wave +3/boss)
- Gold economy — base (5 + phase * 3)g per kill, flat scaling per phase
- Legacy points — 1 per wave base + LP Gain flat upgrades, % drop chance per kill
- Slide-up upgrade panel — 4 columns (ATK/HP/DEF/UTIL), 20 total stats
- New shield system — shield absorbs hits, shield strength reduces HP damage %
- HP regen system — tick-based with configurable interval
- Evasion — % chance to completely dodge a hit
- Damage numbers: white, orange, blue (shield), red (HP), gold (currency), purple (LP)
- Game over screen — phase reached, restart + main menu buttons
- Pause screen — resume, restart, main menu
- Workshop scene — spend LP on permanent stat floors, 3-tier cost scaling
- Unlock/onboarding system — stats unlock milestone by milestone (4 levels)
- Phase start selector — unlocks after first boss, difficulty scales exactly with phase
- Debug tools — reset save, unlock all, 999999 LP, phase 1-20 access
- All 20 upgrade handlers wired and functional with _calc_cost helper
- 3-tier LP cost scaling in workshop (cheap early, steep late)

---

## File Structure
```
Base_Defence/
└── base-defence/          # Godot project root
	├── main.tscn          # Main game scene
	├── project.godot
	├── Scenes/
	│   ├── Enemy.tscn
	│   ├── Boss.tscn
	│   ├── Projectile.tscn
	│   ├── damage_number.tscn
	│   ├── StartMenu.tscn
	│   └── Workshop.tscn
	├── Scripts/
	│   ├── main.gd            # Game loop, spawning, all 20 upgrade handlers, UI
	│   ├── base.gd            # Shooting, crit, shield, HP regen, evasion, damage
	│   ├── enemy.gd           # Movement, melee attack, health bar, scaling
	│   ├── boss.gd            # Boss behavior, HP bar with number, scaling
	│   ├── projectile.gd      # Bullet movement, homing, crit type passing
	│   ├── damage_number.gd   # Floating text, 6 color types
	│   ├── start_menu.gd      # Start menu, phase select, debug buttons
	│   ├── workshop.gd        # LP spending, floor upgrades, 3-tier cost curve
	│   └── SaveManager.gd     # Autoload, persistent save, all data keys
	└── Assets/
```

---

## Scene Tree (main.tscn)
```
Main (Node2D) — main.gd
├── Base (Area2D) — base.gd
│   ├── CollisionShape2D
│   ├── Visual (Polygon2D)
│   ├── HPLabel (Label)       # shows under base
│   └── ShieldLabel (Label)   # shows under base
├── DamageLayer (CanvasLayer)
└── UI (CanvasLayer)
	├── CurrencyLabel
	├── WaveLabel
	├── PauseButton
	├── PauseScreen (ColorRect) [hidden, Process Mode: Always]
	│   ├── PauseLabel
	│   ├── ResumeButton
	│   ├── PauseRestartButton
	│   └── PauseMenuButton
	├── GameOverScreen (ColorRect) [hidden, Process Mode: Always]
	│   ├── GameOverLabel
	│   ├── PhaseLabel
	│   ├── RestartButton
	│   └── MenuButton
	└── UpgradePanel (Control) [slides up from bottom]
		├── PanelBG (ColorRect)
		├── PanelHandle (Button)
		└── ColumnsContainer (HBoxContainer)
			├── ATKColumn (VBoxContainer)
			│   ├── ATKHeader
			│   ├── ATKSpdButton      unlock: 0
			│   ├── DmgButton         unlock: 0
			│   ├── DmgMultButton     unlock: 3
			│   ├── CritChanceButton  unlock: 4
			│   └── CritDmgButton     unlock: 4
			├── HPColumn (VBoxContainer)
			│   ├── HPHeader
			│   ├── MaxHPButton       unlock: 1
			│   ├── RegenAmtButton    unlock: 1
			│   ├── HPMultButton      unlock: 3
			│   ├── RegenSpdButton    unlock: 4

			│   ├── HealMultButton    unlock: 4
			│   └── HPLocked          (placeholder)
			├── DEFColumn (VBoxContainer)
			│   ├── DEFHeader
			│   ├── ShieldButton      unlock: 2
			│   ├── ShieldRegenButton unlock: 2
			│   ├── ShieldStrengthButton unlock: 3
			│   ├── ShieldMultButton  unlock: 4
			│   ├── EvasionButton     unlock: 4
			│   └── DEFLocked         (placeholder)
			└── UTILColumn (VBoxContainer)
				├── UTILHeader
				├── GoldPerKillButton unlock: 2
				├── LPGainButton      unlock: 2
				├── GoldMultButton    unlock: 3
				├── LegacyMultButton  unlock: 3
				├── LegacyDropButton  unlock: 4
				└── UTILLocked        (placeholder)
```

---

## Core Systems

### Difficulty Scaling
- `difficulty` never resets — Phase 3 Wave 1 harder than Phase 1 Wave 1
- +1 per wave, +3 per boss kill
- Phase start: `difficulty = (phase - 1) * 13` (exact reconstruction)
- Enemy HP: `8.0 * (1.0 + (difficulty * 0.27) + (pow(difficulty, 1.4) * 0.03))`
  - Flattened early curve: difficulty 0-10 scales at 0.08, 11+ scales at 0.22
- Enemy attack: `7.0 * (1.0 + (difficulty * 0.11))`
- Enemy speed: `min(72.0 + (difficulty * 1.1), 155.0)`
- Spawn interval: `1.8 / (1.0 + (difficulty * 0.09))` — no cap, scales forever

### Gold Economy
- Base drop: `5 + (phase * 3)` per kill (flat per phase, not per wave)
- Phase 1: 8g, Phase 2: 11g, Phase 3: 14g
- Gold Per Kill: +1g flat per level (infinite)
- Gold Multiplier: +10% per level (infinite)
- Boss drop: 100g flat

### LP Economy
- Base: 1 LP per wave + 10% drop chance per kill
- LP Gain: +1 LP flat per level to ALL LP earned (wave + drops)
- LP Multiplier: +10% multiplies all LP earned
- LP Drop Chance: +0.8% per level, 40% hard cap (50 levels)
- Full formula: `(1 + lp_gain_level) * (1.0 + legacy_mult_level * 0.1)`

### Wave Structure
- 25 seconds per wave, timer-based not kill-based
- Wave % 10 == 0 = boss wave (spawning stops)
- Boss HP: `280 * (1.0 + phase * 0.3)`, Attack: `25 * multiplier`

### Bullet + Crit System
- Locks onto target, never switches mid-flight
- Only fires if target needs more bullets (ceil(health/damage))
- Base crit: 1.5x damage, 0% chance (upgrades add chance + multiplier)
- Crits calculated in base.gd, passed through to projectile and damage numbers

### Shield System (NEW)
- Shield absorbs incoming hits (shield pool depletes)
- Shield Strength (% based, max 40%) reduces HP damage on shielded hit
- Formula: `hp_damage = amount * (1.0 - shield_strength)` when shield > 0
- Base shield strength: 10% (feels useful from first purchase)
- Shield Regen: 1/s base, upgrades add more
- Shield Multiplier: increases effective max shield ceiling
- Evasion: % chance to completely dodge (max 20%, 100 levels)

### Damage Number Colors
- ⚪ White — normal damage to enemies
- 🟠 Orange — crit damage to enemies (larger font)
- 🔵 Blue — shield absorption on base
- 🔴 Red — HP damage on base
- 🟡 Gold — gold dropped on kill
- 🟣 Purple — LP dropped on kill

---

## 20 Core Stats

### ⚔️ ATK (5 stats)
| Stat | Type | Per Level | Cap | Start Cost | Scale |
|---|---|---|---|---|---|
| Attack Speed | CAPPED | diminishing returns | ~8/s (100 lvls) | 45g | x1.23 (<50) x1.4 (50+) |
| Base Damage | INFINITE | +1 dmg | None | 30g | x1.2 |
| Damage Multiplier | INFINITE | +10% | None | 30g | x1.2 |
| Crit Chance | CAPPED | +0.8% | 80% (100 lvls) | 45g | x1.23/<50 x1.4/50+ |
| Crit Damage | INFINITE | +10% | None | 30g | x1.2 |

### 🛡️ DEF (5 stats)
| Stat | Type | Per Level | Cap | Start Cost | Scale |
|---|---|---|---|---|---|
| Max Shield | INFINITE | +20 | None | 30g | x1.2 |
| Shield Regen | INFINITE | +1/s | None | 30g | x1.2 |
| Shield Strength | CAPPED | +0.3% | 40% (100 lvls) | 45g | x1.23/<50 x1.4/50+ |
| Shield Multiplier | INFINITE | +10% | None | 30g | x1.2 |
| Evasion | CAPPED | +0.2% | 20% (100 lvls) | 45g | x1.23/<50 x1.4/50+ |

### ❤️ HP (5 stats)
| Stat | Type | Per Level | Cap | Start Cost | Scale |
|---|---|---|---|---|---|
| Max Health | INFINITE | +10 | None | 30g | x1.2 |
| Regen Amount | INFINITE | +1 hp/tick | None | 30g | x1.2 |
| Regen Speed | INFINITE | -0.04s interval | min 1s | 30g | x1.2 |
| HP Multiplier | INFINITE | +10% | None | 30g | x1.2 |
| Heal Multiplier | INFINITE | +10% | None | 30g | x1.2 |

### 💰 UTIL (5 stats)
| Stat | Type | Per Level | Cap | Start Cost | Scale |
|---|---|---|---|---|---|
| Gold Per Kill | INFINITE | +1g flat | None | 30g | x1.2 |
| Gold Multiplier | INFINITE | +10% | None | 30g | x1.2 |
| LP Gain | INFINITE | +1 LP flat | None | 30g | x1.2 |
| LP Multiplier | INFINITE | +10% | None | 30g | x1.2 |
| LP Drop Chance | CAPPED | +0.8% | 40% (50 lvls) | 45g | x1.23/<50 x1.4/50+ |

### Cost Helper (_calc_cost in main.gd)
```gdscript
func _calc_cost(base: int, level: int, is_capped: bool) -> int:
	if is_capped:
		var scale = 1.23 if level < 50 else 1.4
		return int(base * pow(scale, level))
	else:
		return int(base * pow(1.2, level))
```

---

## Unlock System
Single `unlock_level` in SaveManager gates both in-game panel AND workshop.

| Level | Trigger | Stats Unlocked |
|---|---|---|
| 0 | New game | ATK SPD + Base Damage only |
| 1 | Reach wave 10 (boss wave) | + Max HP, HP Regen |
| 2 | Beat boss 1 | + Shield, Shield Regen, Gold/Kill, LP Gain. Workshop opens. Phase selector unlocks. |
| 3 | Beat boss 2 | + DMG Mult, HP Mult, Shield Strength, Gold Mult, LP Mult |
| 4 | Reach phase 3 boss wave | Everything — all 20 stats, skill tree tab visible |

---

## Workshop
- Separate scene (Workshop.tscn)
- Two tabs: CORE UPGRADES + SKILL TREE (skill tree placeholder for now)
- Spend LP on permanent stat floors
- Same stat values as in-game (workshop Lv5 = in-game Lv5)
- In-game costs always reset to base regardless of floor level
- LP costs use 3-tier curve (_calc_lp_cost in workshop.gd):
  - Levels 1-5: base 10 LP, x1.25
  - Levels 6-15: steeper x1.35
  - Levels 16+: steep x1.5
- Workshop mirrors unlock_level — same stats visible as in-game

---

## Phase Start Selector
- Shows on start menu after unlock_level >= 2
- ◀ PHASE X ▶ buttons cycle available phases
- max_start_phase updates when player beats a boss
- Starting at phase X sets difficulty = (phase-1) * 13 exactly
- Debug unlock gives access to phases 1-20

---

## SaveManager Keys
```
unlock_level, legacy_points, best_phase, start_phase, max_start_phase
floor_attack_speed, floor_damage, floor_dmg_mult, floor_crit_chance, floor_crit_dmg
floor_shield, floor_shield_regen, floor_shield_strength, floor_shield_mult, floor_evasion
floor_max_hp, floor_regen_amt, floor_regen_spd, floor_hp_mult, floor_heal_mult
floor_gold_per_kill, floor_gold_mult, floor_lp_gain, floor_lp_mult, floor_lp_drop
```

---

## Skill Trees (NOT YET BUILT)
- 3 trees: Attack / Defense / Healing
- Launch with 5-6 skills per tree, expand post-launch
- Hard cap: 50 skill points total (can never fill all trees)
- Skill points: 1 per phase boss beaten (permanent)
- Skills unlock via skill points, then level up automatically via enemy kills
- Kill count tracked globally, persists between runs
- Kill-based leveling only applies after skill is unlocked
- Requires unlock_level 4
- Skills modify BEHAVIOR not raw stats
- 5-6 active skills per tree for competitive leaderboard play
- Tournament mode resets kill-based skill levels

### ATK Tree
Multishot, Pierce, Bounce, Explosion on crit, Chain lightning, [1 active skill]

### DEF Tree
Thorns, Block chance, Shield spike, Damage reflection, [1 active skill]

### HP Tree
Overheal aura, Regen burst, Healing pulse, [1 active skill]

---

## Visual System (NOT YET BUILT)
Three layers:
1. **Clarity** — bullets, hit effects, damage numbers (already building)
2. **Build Identity** — tower evolves visually based on skill tree choices
   - Multishot adds emitters, Shield adds rotating ring, Healing adds aura
   - Veteran players recognizable at a glance
3. **Cosmetics** — tracers, bullet trails (post-launch monetization)
   - Basic: earnable with gold
   - Premium: real money (no pay to win)
   - Tournament exclusive: status symbols

---

## Enemy Variety (NOT YET BUILT)
- Brute: 3x health, half speed — Phase 2
- Runner: half health, 2x speed — Phase 2
- Shielder: shield bar before HP — Phase 3
- Ranged: stops at distance, shoots projectiles — Phase 4
New enemy types slot into spawn cycle, replacing % of basic spawns per phase

---

## Meta Progression Loop
1. Run → die → earn LP based on phase reached
2. Spend LP in workshop on permanent stat floors
3. Stats unlock milestone by milestone (boss kills, phase reached)
4. Beat boss 1 → workshop + phase selector unlock
5. Beat boss 2 → advanced stats unlock
6. Reach phase 3 boss → everything unlocks including skill trees
7. Veteran players start at higher phases to farm or push leaderboard

---

## Tournament Mode (POST LAUNCH)
- Time-limited competitive mode
- Fresh state per tournament — no workshop floors, no kill-based skill levels
- All systems unlocked, fixed starting resources
- Weekly/monthly resets
- Rewards exclusive cosmetics
- Solves "whoever played most wins" problem on main leaderboard

---

## Remaining Build Order
1. ✅ Core loop
2. ✅ Workshop + LP system
3. ✅ Unlock/onboarding
4. ✅ Phase start selector
5. ✅ Damage number colors (6 types)
6. 🔲 Spreadsheet balance session (gold, LP, enemy scaling, boss HP)
7. 🔲 Enemy variety (Brute, Runner minimum)
8. 🔲 Skill tree UI + mechanics
9. 🔲 Kill-based skill leveling system
10. 🔲 Enemy death explosion effect
11. 🔲 Base visual evolution (build identity)
12. 🔲 Sound effects
13. 🔲 Camera zoom (scroll wheel PC, pinch mobile)
14. 🔲 Leaderboard
15. 🔲 Speed multiplier toggle (1x/2x/3x)
16. 🔲 Browser export + mobile polish
17. 🔲 Cosmetic system (post-launch)
18. 🔲 Tournament mode (post-launch)
19. 🔲 itch.io launch

---

## Design Principles
- Core stats = power, Skill trees = behavior
- Economic self-regulation — infinite stats get expensive, gold better elsewhere
- Death is informative — each run teaches what you needed
- Build identity — 50 skill point cap forces meaningful choices
- Same stat values everywhere — workshop floor just sets starting level
- In-game costs always reset to base (floor doesn't change upgrade cost)
- All three trees can win, just differently
- Never fully done — infinite scaling keeps veterans engaged
- Capped stats: expensive, feel powerful, unreachable for most players
- Infinite stats: always worth buying, natural economic ceiling
- LP farming is valid strategy but sacrifices combat = self-regulating
- Tournament mode = skill competition, main game = progression competition
