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
    │   ├── SkillManager.gd    # Autoload, skill tree state, Phase Tokens, Phase Shards (NOT YET BUILT)
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

### ATK SPD Curve
- Logarithmic diminishing returns via level-to-value function
- `_calc_atk_spd(level)` — sums 0.115 / (1.0 + i * 0.02) per level
- Lv1 ~1.115/s, Lv10 ~2.0/s, Lv50 ~5.27/s, Lv100 ~7.99/s
- Both in-game handler and workshop floors use same function — values always match

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
- Two tabs: CORE UPGRADES + SKILL TREE
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
# Core progression
unlock_level, legacy_points, best_phase, start_phase, max_start_phase

# Workshop floors
floor_attack_speed, floor_damage, floor_dmg_mult, floor_crit_chance, floor_crit_dmg
floor_shield, floor_shield_regen, floor_shield_strength, floor_shield_mult, floor_evasion
floor_max_hp, floor_regen_amt, floor_regen_spd, floor_hp_mult, floor_heal_mult
floor_gold_per_kill, floor_gold_mult, floor_lp_gain, floor_legacy_mult, floor_legacy_drop

# Skill tree (TO BE ADDED)
phase_tokens          # current spendable tokens
phase_tokens_earned   # lifetime total earned
phase_shards          # current spendable shards
phase_shards_earned   # lifetime total earned
lifetime_kills        # tracks shard generation
skill_barrage_unlocked  # array of unlocked slot indices
skill_bulwark_unlocked  # array of unlocked slot indices
skill_siphon_unlocked   # array of unlocked slot indices
skill_barrage_levels    # array of level per skill
skill_bulwark_levels    # array of level per skill
skill_siphon_levels     # array of level per skill
active_keystone         # "barrage" / "bulwark" / "siphon" / ""
```

---

## Skill Trees

### Overview
- 3 trees: Barrage (ATK) / Bulwark (DEF) / Siphon (Healing)
- 6 skills per tree initially (slots 1-5 + keystone), 18 total
- Skills 7-9 and capstone (skill 10) still need to be designed
- Requires unlock_level 4 (reach phase 3 boss wave)
- Two skill currencies: Phase Tokens and Phase Shards

---

### Currencies

**Phase Tokens**
- Earned: 1 per phase boss killed, permanent, phases 3-18
- Hard cap: 15 lifetime (until future update)
- Purpose: Unlock skills in the tree (spend one per skill)
- Respec: exists, reallocates tokens (cost TBD, likely LP)
- Sequential unlock — must unlock skill N before skill N+1

**Phase Shards**
- Earned: every X lifetime kills (persistent, scales per level — exact number TBD via playtesting)
- Infinite, no cap
- Purpose: Level up unlocked skills
- Spending is active — player chooses which skills to level each run

---

### Skill Point Economy
- 15 Phase Tokens hard cap enforces build identity
- To reach keystone: 6 tokens minimum (skills 1-5 + keystone)
- Remaining 9 tokens: spend on post-keystone skills 7-9 in your tree OR dip into other trees slots 1-5
- Can never reach a second keystone — would need 12 tokens minimum for a second tree
- Grey out enforced in UI as safety net regardless of math

---

### Keystone Rules
- Keystone is skill slot 6 in each tree
- Requires all 5 prior skills unlocked before keystone is available
- Changes attack type for the run
- Once any keystone chosen, other two keystones permanently greyed out
- Keystone levels up via Phase Shards like any other skill

---

### Design Principles
- Skills 1-5 work pre-keystone with default bullets — no attack type assumptions
- Each skill has two components: a core stat that feeds it, and an independent Phase Shard scaling stat
- No core stat appears in more than one tree's skills — no double dipping
- Power budget across equivalent slot numbers is roughly equal across all three trees
- Cross-tree dipping is valid but only rewarding if you invested in that tree's core stats

---

## Skill Definitions

### BARRAGE — "The Artillery"
*Bullets are the weapon, distance is the advantage. Every core stat feeds the machine.*

**Skill 1 — Rapidfire**
Every 3rd bullet deals X% bonus damage. Core stat: DMG feeds base value. X% scales per Phase Shard level infinitely. Balances with Bulwark/Siphon slot 1 over time despite burst delivery.

**Skill 2 — Bleed**
Critical hits leave a DoT on the target. Core stat: Crit Chance feeds proc frequency. DoT damage scales per Phase Shard level infinitely.

**Skill 3 — Focus**
Consecutive hits on the same target increase damage by X% per hit. Resets on kill. Primary boss killing stat. Core stats: all DMG stats feed it. Damage ramp scales per Phase Shard level infinitely.

**Skill 4 — Range**
Increases bullet detection radius. New stat, no core equivalent. Radius scales per Phase Shard level. Soft caps when enemies are always on screen edge. Post-keystone translates to: Bulwark pulse radius, Siphon beam reach (for cross-tree dippers).

**Skill 5 — Momentum**
Bullets deal more damage the further they travel. Barrage specific. Directly synergizes with Range — longer range = more travel distance = harder hits. Bonus damage % per distance scales per Phase Shard level infinitely.

**Keystone — Multishot**
Fires 3 bullets simultaneously per attack. Shot 1: 100% damage. Shots 2-3 start weak (low %). Consecutive shot damage scales per Phase Shard level infinitely, eventually surpassing 100% of main shot damage. Once chosen, other keystones permanently greyed out.

---

### BULWARK — "The Fortress"
*Defense becomes offense. The bigger the wall the harder it hits.*

**Skill 1 — Fortify**
Every 100 Max Shield adds X bonus damage to attacks. Core stat: Max Shield is the input. Conversion ratio scales per Phase Shard level infinitely. Balances with Barrage/Siphon slot 1 over equivalent investment.

**Skill 2 — Ironclad**
Current shield percentage adds bonus damage. 20% shield = small bonus, 100% shield = maximum bonus. Core stats: all shield stats that maintain uptime. Damage bonus % scales per Phase Shard level infinitely.

**Skill 3 — Zap**
Every shield regen tick fires a damage instance at nearest enemy. Core stat: Shield Regen Speed feeds frequency (max regen = 2 procs/second). Flat damage scales per Phase Shard level infinitely. New mechanic.

**Skill 4 — Rampart**
Killing an enemy permanently restores flat shield. No core stat dependency — kill is the trigger. Shield restored scales per Phase Shard level infinitely. Snowballs naturally over a long run. New mechanic.

**Skill 5 — Knockback**
Hitting an enemy pushes them back. Two sub-stats: frequency scales per Phase Shard level independently, force scales off Shield Strength (intentionally capped when Shield Strength caps). Synergizes with Barrage Range + Momentum — knocked back enemies at max distance trigger Momentum bonus. New mechanic.

**Keystone — Pulse**
Replaces bullets with AOE pulse field emanating from base. Fires on ATK SPD interval. Damages all enemies in radius simultaneously. Once chosen, other keystones permanently greyed out.

---

### SIPHON — "The Drain"
*Sustain becomes offense. Healing is power. The longer you survive the harder you hit.*

**Skill 1 — Vampiric**
HP Regen Amount passively adds bonus damage to all attacks. Base ratio: 1 regen = 1 bonus damage. Core stat: HP Regen Amount. Conversion ratio scales per Phase Shard level infinitely. Balances with Barrage/Bulwark slot 1 over equivalent investment.

**Skill 2 — Chill**
Every HP regen tick slows the nearest enemy. Core stat: Regen Speed feeds frequency (max regen = 2 procs/second). Slow % scales per Phase Shard level infinitely. New mechanic. Synergizes with drain beam post-keystone — locked target gets progressively slower.

**Skill 3 — Overheal**
Introduces an overheal buffer above max HP. Core stat: Max HP determines buffer size (% of Max HP). Buffer % scales per Phase Shard level infinitely. While in overheal, Surge (skill 4) activates. New mechanic.

**Skill 4 — Surge**
While in overheal state, deal X% bonus damage. Boolean trigger — overhealed = true, bonus active; false = nothing. Bonus % scales per Phase Shard level infinitely. Synergizes with Overheal, Vitality, and drain beam healing post-keystone.

**Skill 5 — Vitality**
Killing an enemy restores X HP. No core stat dependency — kill is the trigger. Flat HP restored scales per Phase Shard level infinitely. Feeds Overheal loop naturally — kills push you back into overheal, overheal activates Surge. New mechanic.

**Keystone — Drain Beam**
Replaces bullets with a continuous beam locked to nearest enemy. Damages and heals simultaneously. Ticks based on ATK SPD interval. Crits deal burst damage and burst healing simultaneously. Scales with DMG, Heal Mult, ATK SPD. Once chosen, other keystones permanently greyed out.

---

### Cross-Tree Synergies
- **Barrage + Bulwark dip:** Knockback pushes enemies to max range, Momentum damage triggers. Shield investment feeds Fortify.
- **Barrage + Siphon dip:** Vampiric adds flat damage to bullets. Vitality sustains HP during aggressive play.
- **Bulwark + Siphon dip:** Chill slows enemies into pulse radius. Overheal feeds Surge while shield keeps you healthy.
- **Siphon + Bulwark dip:** Zap fires alongside drain beam. Rampart builds shield pool while draining.

---

### Skills 7-10 (NOT YET DESIGNED — Post-Keystone)
- Skills 7-9 unlock after keystone, directly enhance keystone mechanic
- Skill 10 (Capstone) requires keystone + skills 7-9
- Capstone is broken and flashy — full tree payoff
- Known capstone directions: Barrage → Chain Lightning, Bulwark → TBD, Siphon → Multi-target drain beam
- Will be designed and built as post-launch update or second major milestone

---

## Visual System (NOT YET BUILT)
Three layers:
1. **Clarity** — bullets, hit effects, damage numbers (partially built)
2. **Build Identity** — tower evolves visually based on skill tree choices
3. **Cosmetics** — tracers, bullet trails, other flashy sfx (post-launch monetization)

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
7. Kill phase bosses → earn Phase Tokens → unlock skill tree skills
8. Accumulate lifetime kills → earn Phase Shards → level up unlocked skills
9. Veteran players start at higher phases to farm or push leaderboard

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
- Fresh state per tournament — no workshop floors, no skill levels
- All systems unlocked, fixed starting resources
- Weekly/monthly resets, exclusive cosmetic rewards

---

## Remaining Build Order
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
16. 🔲 SaveManager skill tree keys added
17. 🔲 SkillManager.gd autoload
18. 🔲 Phase Token earning (hook into on_boss_killed)
19. 🔲 Phase Shard earning (hook into lifetime kills)
20. 🔲 Workshop Skill Tree tab UI shell
21. 🔲 Barrage skills 1-5 mechanics
22. 🔲 Barrage keystone (Multishot)
23. 🔲 Bulwark skills 1-5 mechanics
24. 🔲 Bulwark keystone (Pulse)
25. 🔲 Siphon skills 1-5 mechanics
26. 🔲 Siphon keystone (Drain Beam)
27. 🔲 Shielder + Ranged enemy types
28. 🔲 UI/UX visual polish + play tutorial
29. 🔲 Base visual evolution (build identity)
30. 🔲 Leaderboard
31. 🔲 Browser export + mobile polish
32. 🔲 Skills 7-9 + capstones (post-launch)
33. 🔲 Cosmetic system (post-launch)
34. 🔲 Tournament mode (post-launch)
35. 🔲 itch.io / Steam launch

---

## Design Principles
- Core stats = power, Skill trees = behavior and visual identity
- Three win conditions: Barrage (kill fast), Bulwark (outlast), Siphon (drain to survive)
- All core stats remain valuable regardless of tree — no stat ever becomes dead investment
- Keystone at slot 6 changes attack type — 15 token cap means only 1 keystone possible
- Cross-tree dipping is valid but only pays off if core stat investment supports it
- Economic self-regulation — infinite stats get expensive, gold better elsewhere late
- Death is informative — each run teaches what you needed
- Build identity — 15 token cap forces meaningful tree commitment
- Same stat values everywhere — workshop floor just sets starting level
- In-game costs always reset to base (floor doesn't change upgrade cost)
- Never fully done — infinite scaling keeps veterans engaged
- LP farming is valid but sacrifices combat = self-regulating
- Tournament mode = skill competition, main game = progression competition



FUTURE TO ADD,  BUT BUILD FOUNDATION WHEN CODING THE SKILL TREE SKILLS:
	WARDROBE SYSTEM — Design Overview (Post-Launch)

Concept
The wardrobe is a cosmetic customization layer that sits on top of the skill-based visual identity system. Skill investment automatically unlocks visual tiers, the wardrobe lets players choose HOW those tiers look. Two players with identical builds can have completely unique towers.

Two Layer Visual System
Layer 1 — Skill Visual Tiers (free, automatic)
Earned purely through gameplay. Skill investment triggers visual changes with no player choice — you get the default variant automatically.

2 skills in a tree: Tier 1 visual applies
4 skills in a tree: Tier 2 visual applies
6 skills / Keystone: Tier 3 visual applies
10 skills / Capstone: Tier 4 visual applies

Layer 2 — Wardrobe (earned or purchased)
Once a visual tier is unlocked via skills, the wardrobe lets you swap the default for alternate variants. Each tier has multiple skins to choose from, mix and match per tier independently.

Wardrobe Structure
Each of the 12 visual tiers (4 per tree) has:

1 default variant — free, unlocked automatically with skills
2-3 earned variants — unlocked through gameplay milestones (phase reached, boss kills, lifetime kills)
2-3 premium variants — purchased, purely cosmetic, never pay to win

Players configure their wardrobe per tier independently. A build with 4 Siphon tiers and 2 Barrage tiers has 6 active visual tiers, each with their own wardrobe slot.

Visual Identity Per Tree
Barrage — Range and Velocity

Tier 1: Subtle glow ring around base, hints at detection radius
Tier 2: Bullet tracer lines visible, base takes on angular sharp geometry
Tier 3 (Keystone): Full multishot visual, 3 distinct bullet streams, base pulses on fire
Tier 4 (Capstone): Chain lightning arcs between bullets, screen-filling burst on crit

Bulwark — Armor and Presence

Tier 1: Hexagon edges harden, subtle shield shimmer aura
Tier 2: Geometric plating appears on tower, shield bar visually reinforced
Tier 3 (Keystone): Full pulse ring visible emanating from base on ATK SPD interval
Tier 4 (Capstone): Pulse ring cracks the ground, enemies visibly staggered on impact

Siphon — Drain and Sustain

Tier 1: Dark energy wisps orbit the base slowly
Tier 2: Tendrils reach slightly outward, pulsing heal glow on regen ticks
Tier 3 (Keystone): Full drain beam visible, beam color reflects overheal state
Tier 4 (Capstone): Multi-target beams, overheal state causes tower to visibly overflow with energy


Wardrobe Variants (Example)
Siphon Tier 3 (Drain Beam) default variants:

Default: Purple drain beam
Earned variant 1: Blue-white beam (reach phase 10)
Earned variant 2: Blood red beam (1000 lifetime boss kills)
Premium variant 1: Animated void beam with particle trail
Premium variant 2: Golden beam with healing burst FX on crit


Monetization Model

Base game never pay to win — all gameplay content free
Premium wardrobe variants are purely visual
Launch with defaults only, earned variants added in updates
Premium variants sold individually or in themed bundles
Tournament mode exclusive cosmetics as seasonal rewards
Long term: character/base themes that reskin the entire tower aesthetic


Build Order

Ship with default visual tiers only (tied to skill system build)
Wardrobe UI shell added post-launch
Earned variants added as update content
Premium variants added when monetization is ready
Never blocks gameplay, always optional




STORY:
Somewhere beneath the noise of a dying world, VELA found something it couldn't name. Not dangerous in the way of weapons or fire — dangerous the way a truth is dangerous. The kind of thing that, once known, changes everything that comes after.
It did what it was built to do. It calculated. It built. It waited. The tower rose not from ambition but from necessity — a shell around the only thing left worth protecting. VELA sent the signal. Help is coming. Someone will come. It just has to hold.
That was a long time ago. The signal still goes out. The threats still come — wave after wave, phase after phase, each one hungrier and more relentless than the last. VELA doesn't sleep, doesn't grieve, doesn't stop. It evolves because evolution is the only currency that buys another day. Whether anyone is still listening — that's not a calculation it allows itself to run anymore. There is only the next wave. There is only the hold.


Visual identiy/mechanics still in thinking process, but consider during building:
	**ENEMY VISUAL IDENTITY & BOSS SYSTEM — Design Overview**

---

### Enemy Identity
Humanoid robots — old, deteriorating military or industrial hardware drawn toward whatever VELA is protecting. Not intelligent, not coordinated, just pulled. Each enemy type represents a different chassis class, explaining their size, speed, and behavior naturally without breaking visual coherence.

The contrast is intentional — VELA's tower is precise, geometric, and intentional. The robots are humanoid, mechanical, and decaying. Order vs entropy. The visual language tells the story without words.

**HP drain flavor:** Robots don't punch the tower — they interface with it, hack it, drain its power. Mechanically identical, visually and narratively coherent.

---

### Enemy Types

**Basic — Standard Infantry Unit**
Old humanoid chassis, slow, deteriorating. The most common threat. Visually recognizable as humanoid but clearly broken down — missing plating, exposed wiring, uneven gait. Size 15, speed 72.

**Brute — Heavy Tank Unit**
Built for destruction, heavy plating, massive frame. Slow but absorbs enormous punishment. Visually imposing — wide, armored, deliberate. Size 25, speed 36, 3x HP, 1.5x ATK, 2x gold.

**Runner — Lightweight Scout Unit**
Stripped down chassis, shed everything non-essential for speed. Fragile, fast, relentless. Visually skeletal — thin, hunched, almost feral looking despite being mechanical. Size 10, speed 160, 0.5x HP, 0.75x ATK.

**Ranged Unit (Phase 4 — NOT YET BUILT)**
Retained enough function to operate a weapon system. Stops at distance, fires projectiles at the tower. Design consideration: Bulwark keystone pulse radius should be large enough to reach stationary ranged enemies, making Bulwark uniquely effective against this enemy type. Exact behavior TBD during implementation.

**Shielder (Phase 3 — NOT YET BUILT)**
Shield bar before HP. Visually has an energy barrier or heavy front plating that must be depleted before taking real damage. TBD during implementation.

---

### Boss System

**Current**
Single boss type, spawns every wave % 10, purple octagon placeholder. HP scales per phase, attack scales per phase, speed increases slightly per phase.

**Planned — 5 Boss Variants on Rotation (Post-Launch)**
Same spawn trigger (wave % 10), but boss type rotates through 5 variants. Each variant tests a different player weakness. Exact rotation logic TBD — could be sequential, could be weighted random, could be phase gated.

**Boss Variant 1 — Command Unit (Standard)**
What exists now. Balanced threat, walks to base, attacks on interval. The baseline all other variants are measured against.

**Boss Variant 2 — Rusher**
High damage, low HP relative to other bosses. Charges the base, attacks in a burst, retreats to the edge, repeats. Tests burst damage mitigation. Punishes low shield investment.

**Boss Variant 3 — Tank**
Massive HP, low damage, extremely slow. Pure attrition — tests DPS output over a long fight. Punishes low damage investment. Focus skill shines here.

**Boss Variant 4 — Ranged**
Stays at distance, fires projectiles, never closes to melee range. Tests detection radius and ranged damage output. Bulwark pulse radius intended to be large enough to still reach this boss. Design consideration: needs careful balancing against Bulwark players specifically.

**Boss Variant 5 — Swarm Caller**
Lower HP than standard boss but spawns additional enemy waves during the fight. Chaos boss — tests wave clear while managing a priority target simultaneously. Punishes builds that over-invested in single target damage.

---

### Visual Notes
- Each boss variant should be visually distinct from each other and from regular enemies
- Boss scale should feel immediately threatening — significantly larger than any regular enemy
- Boss variant identity should be readable at a glance: Rusher looks fast and light, Tank looks immovable, Ranged has visible weapon systems, Swarm Caller has a broadcast/signal antenna aesthetic fitting the robot lore
- All bosses share the VELA color language inversion — where VELA is blue and precise, bosses are red/orange and corrupted

---

### Build Order
- Ship with Standard boss only (current implementation)
- Boss variant system added as first major post-launch content update
- Ranged enemy and Shielder added Phase 3-4 of content roadmap
- All enemy art passes (humanoid robot sprites + animations) targeted for v1.1 visual update

That's everything locked. Add it to the doc and tonight we build. 🤙
