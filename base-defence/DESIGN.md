# Phasefall — Game Design Document
**Studio:** Elydar Studios
**Engine:** Godot 4
**Target:** Mobile (portrait 720x1280) + Browser
**Status:** Alpha v1 — core loop complete, balancing done, ready for friend testing.

---

## Current Build State (Day 4)
Everything below is BUILT and WORKING:
- Start menu with studio branding, phase selector (◀ PHASE X ▶), workshop button
- SaveManager autoload — persistent save across sessions
- Full game loop: spawn → kill → upgrade → die → workshop → run again
- Base (blue hexagon) true center screen (360, 640), auto-shoots nearest enemy
- Smart bullet targeting — locks onto target, prioritizes closest to base, no wasted shots
- Crit system — 1.5x base crit damage, scales with Crit DMG upgrade
- Kill-based wave system — fixed enemy count per wave, wave advances on last kill
- Enemies spawn from 6 edges (hexagon pattern), deterministic rotation, walk to base
- Brute enemies (Phase 2+) — 3x HP, 0.5x speed, 2x gold, deterministic spawn every Nth enemy
- Runner enemies (Phase 3+) — 0.5x HP, 2x speed, deterministic spawn every Nth enemy
- Enemy health bars (green/yellow/red), floating damage numbers (white normal, orange crit)
- Boss spawns every wave % 10, purple octagon, HP bar with number display
- Boss drops gold (phase scaled) + LP (phase scaled), has death sound
- Difficulty variable — never resets, +1/wave +3/boss, phase start = (phase-1) * 10
- Gold economy — base (5 + (phase-1) * 3)g per kill, flat scaling per phase
- Legacy points — run_lp (this run, shown in UI) separate from cumulative SaveManager total
- LP saves incrementally (crash-safe), no double-add on game over
- Slide-up upgrade panel — 4 columns (ATK/HP/DEF/UTIL), 20 total stats
- In-game upgrade costs always start from base (floor levels don't inflate costs)
- Tiered pricing system — 7 tiers with differentiated gold and LP costs
- Shield system — absorbs hits, strength reduces HP bleed-through, 10% base regen per tick
- HP regen system — tick-based with configurable interval
- Evasion — % chance to completely dodge a hit
- Damage numbers: white, orange, blue (shield), red (HP), gold 💰, purple ★ (LP)
- LP drop shows on enemy that dropped it (not base position)
- Game over screen — phase reached, restart + main menu buttons
- Pause screen — resume, restart, main menu
- Workshop scene — spend LP on permanent stat floors, tiered LP costs, current value display
- Workshop shows current level per stat (Lv X)
- Unlock/onboarding system — stats unlock milestone by milestone (4 levels)
- Phase start selector — unlocks after first boss, difficulty scales exactly with phase
- Debug tools — reset save, unlock all, 999999 LP, phase 1-20 access
- Tooltip system — hover (2s) or right-click to show stat description, all 20 stats
- TooltipData.gd autoload with descriptions for all stats
- Camera2D with zoom — scroll wheel / pinch, range 0.4x-1.0x, default 0.6x
- Speed toggle button — 1x / 1.5x / 2x, resets on pause/game over/menu
- Mute toggle button — mutes all SFX and music
- Screen flash — subtle green on wave complete, purple on boss spawn
- Sound effects — shoot, boss spawn, take damage, boss death
- Background music — looping wav track
- Boss damage numbers now display correctly
- Enemy speed no longer scales with difficulty (fixed stat per type)

---

## File Structure
```
Base_Defence/
└── base-defence/          # Godot project root
    ├── main.tscn          # Main game scene
    ├── project.godot
    ├── Scenes/
    │   ├── Enemy.tscn
    │   ├── Brute.tscn
    │   ├── Runner.tscn
    │   ├── Boss.tscn
    │   ├── Projectile.tscn
    │   ├── damage_number.tscn
    │   ├── StartMenu.tscn
    │   └── Workshop.tscn
    ├── Scripts/
    │   ├── main.gd            # Game loop, spawning, all 20 upgrade handlers, UI, audio, camera
    │   ├── base.gd            # Shooting, crit, shield, HP regen, evasion, damage
    │   ├── enemy.gd           # Movement, melee attack, health bar, scaling
    │   ├── brute.gd           # Brute enemy — 3x HP, 0.5x speed, 2x gold
    │   ├── runner.gd          # Runner enemy — 0.5x HP, 2x speed
    │   ├── boss.gd            # Boss behavior, HP bar with number, scaling
    │   ├── projectile.gd      # Bullet movement, homing, crit type passing
    │   ├── damage_number.gd   # Floating text, 6 color types + emoji prefixes
    │   ├── start_menu.gd      # Start menu, phase select, debug buttons
    │   ├── workshop.gd        # LP spending, floor upgrades, tiered costs, current values
    │   ├── SaveManager.gd     # Autoload, persistent save, all data keys
    │   └── TooltipData.gd     # Autoload, tooltip descriptions for all 20 stats
    └── Assets/
        └── Sounds/
            ├── Shoot.wav
            ├── BossSpawn.wav
            ├── TakeDamage.wav
            ├── BossDeath.wav
            └── Music.wav
```

---

## Scene Tree (main.tscn)
```
Main (Node2D) — main.gd
├── Camera2D (centered at 360, 640, default zoom 0.6)
├── Base (Area2D) — base.gd
│   ├── CollisionShape2D
│   ├── Visual (Polygon2D)
│   ├── HPLabel (Label)
│   └── ShieldLabel (Label)
├── DamageLayer (CanvasLayer)
└── UI (CanvasLayer)
    ├── CurrencyLabel
    ├── WaveLabel
    ├── PauseButton
    ├── SpeedButton (top right)
    ├── MuteButton
    ├── TooltipTimer
    ├── TooltipPanel (PanelContainer)
    │   └── TooltipLabel (Label)
    ├── ScreenFlash (ColorRect, full screen, alpha 0)
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
            │   └── HPLocked
            ├── DEFColumn (VBoxContainer)
            │   ├── DEFHeader
            │   ├── ShieldButton      unlock: 2
            │   ├── ShieldRegenButton unlock: 2
            │   ├── ShieldStrengthButton unlock: 3
            │   ├── ShieldMultButton  unlock: 4
            │   ├── EvasionButton     unlock: 4
            │   └── DEFLocked
            └── UTILColumn (VBoxContainer)
                ├── UTILHeader
                ├── GoldPerKillButton unlock: 2
                ├── LPGainButton      unlock: 2
                ├── GoldMultButton    unlock: 3
                ├── LegacyMultButton  unlock: 3
                ├── LegacyDropButton  unlock: 4
                └── UTILLocked
```

---

## Core Systems

### Difficulty Scaling
- `difficulty` never resets — Phase 3 Wave 1 harder than Phase 1 Wave 1
- +1 per wave, +3 per boss kill
- Phase start: `difficulty = (phase - 1) * 10`
- Enemy HP: `8.0 * multiplier` where multiplier uses flattened curve (0.08 early, 0.22 late)
- Enemy attack: `7.0 * (1.0 + (difficulty * 0.11))`
- Enemy speed: FIXED per type (no difficulty scaling)
  - Basic: 72, Brute: 36, Runner: 160 (adjusted for longer travel distance)
- Spawn interval: `(0.8 / (1.0 + (difficulty * 0.09))) * randf_range(0.8, 1.2)` (slight variance)

### Wave System (Kill-Based)
- Enemy count per wave: `BASE_ENEMIES_PER_WAVE + (wave * 1.5) + (phase * 2)`
- BASE_ENEMIES_PER_WAVE = 12
- Wave advances when all enemies spawned AND all killed
- Boss wave on wave % 10 == 0
- Spawn boundaries set for 0.6x zoom default (enemies always off-screen)

### Enemy Spawn (Deterministic)
- 6 spawn edges (hexagon pattern), cycles in order
- Slight random variance in timing (0.8-1.2x interval) to prevent clustering
- Phase 2+: Brute every Nth spawn (max(6, 10 - (phase-2)))
- Phase 3+: Runner every Nth spawn (max(4, 8 - (phase-3)))
- Runner takes priority over Brute when intervals collide

### Gold Economy
- Base drop: `5 + ((phase-1) * 3)` per kill
- Phase 1: 5g, Phase 2: 8g, Phase 3: 11g
- Brute: 2x gold value
- Boss: `100 + ((phase-1) * 20)` gold
- Gold Per Kill: +1g flat per level
- Gold Multiplier: +10% per level
- Displayed gold = actual received amount (post-multiplier)

### LP Economy
- run_lp: tracks this run only (shown in UI, resets each run)
- SaveManager["legacy_points"]: cumulative total, saves incrementally (crash-safe)
- Base: 1 LP per wave completion
- Boss: `10 + ((phase-1) * 3)` LP, affected by LP Gain and LP Mult
- LP Gain: +1 LP flat added to all sources
- LP Multiplier: +10% multiplies all LP
- LP Drop Chance: base 5%, +0.55% per level, cap 60% at 100 levels
- Drop formula: `int((1 + lp_gain_level) * (1.0 + legacy_mult_level * 0.1))`

### Bullet + Crit System
- Locks onto target, never switches mid-flight
- Only fires if target needs more bullets (ceil(health/damage))
- Base crit: 1.5x damage, 0% chance
- Crits calculated in base.gd, passed through to projectile and damage numbers

### Shield System
- Shield absorbs incoming hits (pool depletes by hit amount)
- Formula: HP damage = (absorbed * (1 - shield_strength)) + overflow
- Base shield strength: 10%, caps at 40% (100 levels, +0.3% per level)
- Shield regen: 10% of max shield per tick, base interval 5s
- Shield Regen upgrade reduces interval (min 0.5s at 100 levels)
- Shield Multiplier: multiplies effective max shield

### Damage Number Colors
- ⚪ White — normal damage to enemies
- 🟠 Orange — crit damage (larger font)
- 🔵 Blue — shield absorption on base
- 🔴 Red — HP damage on base
- 💰 Gold — gold dropped on kill (shows actual received amount)
- ★ Purple — LP dropped on kill (shows on enemy position)

---

## 20 Core Stats — Tiered Pricing

### Tier 1 — Core Survival
| Stat | Gold Base | Gold Scale | LP Base |
|------|-----------|------------|---------|
| ATK SPD | 45g | x1.23/x1.4 capped | 8 LP |
| DMG | 30g | x1.15 flat | 6 LP |
| Max HP | 22g | x1.15 flat | 5 LP |

### Tier 2A — Immediate Defense
| Stat | Gold Base | Gold Scale | LP Base |
|------|-----------|------------|---------|
| Shield | 28g | x1.2 infinite | 8 LP |
| Regen Amt | 18g | x1.15 flat | 5 LP |

### Tier 2B — Scaling Defense
| Stat | Gold Base | Gold Scale | LP Base |
|------|-----------|------------|---------|
| Shield Regen | 35g | x1.23/x1.4 capped | 8 LP |
| Regen Spd | 25g | x1.23/x1.4 capped | 6 LP |

### Tier 3A — General Multipliers
| Stat | Gold Base | Gold Scale | LP Base |
|------|-----------|------------|---------|
| DMG Mult | 45g | x1.25 mult | 12 LP |
| HP Mult | 35g | x1.2 infinite | 10 LP |
| Shield Mult | 35g | x1.2 infinite | 10 LP |
| Heal Mult | 30g | x1.2 infinite | 8 LP |

### Tier 3B — Specialized/Capped
| Stat | Gold Base | Gold Scale | LP Base |
|------|-----------|------------|---------|
| Crit Chance | 50g | x1.23/x1.4 capped | 14 LP |
| Crit DMG | 40g | x1.25 mult | 12 LP |
| Shield Strength | 45g | x1.23/x1.4 capped | 12 LP |
| Evasion | 50g | x1.23/x1.4 capped | 14 LP |

### Tier 4A — Base Economy
| Stat | Gold Base | Gold Scale | LP Base |
|------|-----------|------------|---------|
| Gold Per Kill | 22g | x1.15 flat | 6 LP |
| LP Gain | 22g | x1.15 flat | 6 LP |
| LP Drop Chance | 35g | x1.23/x1.4 capped | 8 LP |

### Tier 4B — Economy Multipliers
| Stat | Gold Base | Gold Scale | LP Base |
|------|-----------|------------|---------|
| Gold Mult | 50g | x1.25 mult | 14 LP |
| LP Mult | 50g | x1.25 mult | 14 LP |

### Cost Helpers
```gdscript
func _calc_cost(base, level, is_capped)  # standard capped/infinite
func _calc_cost_flat(base, level)         # x1.15 scale (T1, T2A, T4A)
func _calc_cost_mult(base, level)         # x1.25 scale (T3A mult, T4B)
```

### Workshop LP Cost Curve
- Levels 1-5: base * x1.25
- Levels 6-15: steeper x1.35
- Levels 16+: steep x1.5

---

## Unlock System
| Level | Trigger | Stats Unlocked |
|---|---|---|
| 0 | New game | ATK SPD + Base Damage only |
| 1 | Reach wave 10 (boss wave) | + Max HP, HP Regen |
| 2 | Beat boss 1 | + Shield, Shield Regen, Gold/Kill, LP Gain. Workshop + Phase selector unlock. |
| 3 | Beat boss 2 | + DMG Mult, HP Mult, Shield Strength, Gold Mult, LP Mult |
| 4 | Reach phase 3 boss wave | Everything — all 20 stats, skill tree tab visible |

---

## Workshop
- Separate scene (Workshop.tscn)
- Two tabs: CORE UPGRADES + SKILL TREE (skill tree placeholder)
- Spend LP on permanent stat floors
- Same stat values as in-game (workshop Lv5 = in-game Lv5 starting point)
- In-game costs ALWAYS reset to base (floor level doesn't affect upgrade cost)
- Button displays: STAT NAME (Lv X) | current value | gain per level | cost LP
- Workshop mirrors unlock_level — same stats visible as in-game

---

## Phase Start Selector
- Shows on start menu after unlock_level >= 2
- ◀ PHASE X ▶ buttons cycle available phases
- max_start_phase updates when player beats a boss
- Starting at phase X sets difficulty = (phase-1) * 10
- Debug unlock gives access to phases 1-20

---

## SaveManager Keys
```
unlock_level, legacy_points, best_phase, start_phase, max_start_phase
floor_attack_speed, floor_damage, floor_dmg_mult, floor_crit_chance, floor_crit_dmg
floor_shield, floor_shield_regen, floor_shield_strength, floor_shield_mult, floor_evasion
floor_max_hp, floor_regen_amt, floor_regen_spd, floor_hp_mult, floor_heal_mult
floor_gold_per_kill, floor_gold_mult, floor_lp_gain, floor_legacy_mult, floor_legacy_drop
```

---

## Skill Trees (NOT YET BUILT)
- 3 trees: Barrage (ATK) / Bulwark (DEF) / Siphon (Healing)
- 10 skills per tree, 30 total
- 15 skill points total (can never fill all trees, max 1 keystone)
- Skill points: 1 per phase boss beaten (permanent)
- Skills unlock via skill points (1 point per skill), then level up via enemy kills
- Kill count tracked globally, persists between runs
- Requires unlock_level 4

### Tree Philosophy
- **Barrage** — projectile focused, ranged, high burst. Multishot, pierce, chain. Same attack mechanic but more bullets, flashier.
- **Bulwark** — AOE pulse/shockwave, close range. Enemies die walking into you. Thorns field pulses based on ATK SPD.
- **Siphon** — drain beam, short-mid range, DoT. Locks onto nearest enemy, damages and heals simultaneously. Scales with DMG and Heal Mult.

### Skill Tree Structure (per tree)
- Skills 1-3: Small additive buffs, useless without corresponding stat investment
- Skills 4-6: Conditional power, synergies with core stats
- Skills 7-8: Strong standalone, sets up keystone fantasy
- Skill 9 (Keystone): Changes attack type. Costs 9 points to reach = can only have 1 keystone with 15 total points
- Skill 10 (Capstone): Full tree payoff, broken and flashy

### ATK (Barrage) Tree — Placeholder Skills
Multishot, Pierce, Bounce, Chain Lightning, Explosion on Crit, [more TBD]

### DEF (Bulwark) Tree — Placeholder Skills
Thorns AOE pulse, Block chance, Shield Spike, Damage Reflection, [more TBD]

### Healing (Siphon) Tree — Placeholder Skills
Regen Burst, Fortified Regen, Overheal, Drain Beam (keystone), [more TBD]

---

## Visual System (NOT YET BUILT)
Three layers:
1. **Clarity** — bullets, hit effects, damage numbers (partially built)
2. **Build Identity** — tower evolves visually based on skill tree choices
3. **Cosmetics** — tracers, bullet trails (post-launch monetization)

---

## Enemy Variety
### Built
- Basic: red hexagon, size 15, speed 72, standard stats
- Brute (Phase 2+): orange hexagon, size 25, speed 36, 3x HP, 1.5x ATK, 2x gold
- Runner (Phase 3+): yellow hexagon, size 10, speed 160, 0.5x HP, 0.75x ATK

### Not Yet Built
- Shielder: shield bar before HP — Phase 3
- Ranged: stops at distance, shoots projectiles — Phase 4

---

## Meta Progression Loop
1. Run → die → earn LP based on phase reached (saves incrementally)
2. Spend LP in workshop on permanent stat floors
3. Stats unlock milestone by milestone (boss kills, phase reached)
4. Beat boss 1 → workshop + phase selector unlock
5. Beat boss 2 → advanced stats unlock
6. Reach phase 3 boss → everything unlocks including skill trees
7. Veteran players start at higher phases to farm or push leaderboard

---

## Balance (Tested)
- Phase 1 fresh run: 3 run arc feels correct
  - Run 1: die to boss (learn the game)
  - Run 2: almost beat boss ("almost had him" hook)
  - Run 3: beat boss with workshop investment, die wave 11
- ~33 LP per boss-kill run
- Phase 2 spike intentional — requires workshop investment
- Enemy speed not scaling with difficulty (fixed per type)
- Boss HP: `400 * (1.0 + ((phase-1) * 0.3))` — Phase 1 = 400 HP

---

## Tournament Mode (POST LAUNCH)
- Time-limited competitive mode
- Fresh state per tournament — no workshop floors, no kill-based skill levels
- All systems unlocked, fixed starting resources
- Weekly/monthly resets, exclusive cosmetic rewards

---

## Remaining Build Order (Post Alpha)
1. ✅ Core loop
2. ✅ Workshop + LP system
3. ✅ Unlock/onboarding
4. ✅ Phase start selector
5. ✅ Damage number colors (6 types)
6. ✅ Kill-based wave system
7. ✅ Enemy variety (Brute, Runner)
8. ✅ Tiered balance (gold, LP, enemy scaling)
9. ✅ Sound effects + music
10. ✅ Camera zoom
11. ✅ Speed toggle
12. ✅ Tooltip system
13. ✅ Workshop current values + level display
14. ✅ LP persistence fix
15. 🔲 Alpha friend testing + feedback
16. 🔲 Skill tree UI + mechanics (Barrage/Bulwark/Siphon)
17. 🔲 Kill-based skill leveling system
18. 🔲 Shielder + Ranged enemy types
19. 🔲 UI/UX visual polish + play tutorial
20. 🔲 Base visual evolution (build identity)
21. 🔲 Leaderboard
22. 🔲 Browser export + mobile polish
23. 🔲 Cosmetic system (post-launch)
24. 🔲 Tournament mode (post-launch)
25. 🔲 itch.io / Steam launch

---

## Design Principles
- Core stats = power, Skill trees = behavior (win condition)
- Three win conditions: Barrage (kill fast), Bulwark (outlast), Siphon (drain to survive)
- Keystone at skill 9 changes attack type — 15 point cap means only 1 keystone possible
- Economic self-regulation — infinite stats get expensive, gold better elsewhere
- Death is informative — each run teaches what you needed
- Build identity — 15 skill point cap forces meaningful tree commitment
- Same stat values everywhere — workshop floor just sets starting level
- In-game costs always reset to base (floor doesn't change upgrade cost)
- Never fully done — infinite scaling keeps veterans engaged
- LP farming is valid but sacrifices combat = self-regulating
- Tournament mode = skill competition, main game = progression competition
