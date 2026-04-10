# Phasefall — Game Design Document
**Studio:** Elydar Studios
**Engine:** Godot 4
**Target:** Mobile (portrait 720x1280) + Browser
**Status:** Alpha v0.4 — Barrage tree complete (all 6 skills including Chain keystone), balance pass done, shield rework, economy tuning.

---

## Current Build State
Everything below is BUILT and WORKING:
- Start menu with studio branding, phase selector (◀ PHASE X ▶), workshop button, skill tree button
- SaveManager autoload — persistent save across sessions
- Full game loop: spawn → kill → upgrade → die → workshop → run again
- Base (blue hexagon) true center screen (360, 640), auto-shoots nearest enemy
- Smart bullet targeting — locks onto target, prioritizes closest to base, factors in bleed + momentum damage to avoid stray bullets
- Attack counter system — attack-type agnostic, used by all fire modes (bullet, future beam/pulse)
- Crit system — 1.5x base crit damage, scales with Crit DMG upgrade
- Kill-based wave system — fixed enemy count per wave, wave advances on last kill
- Enemies spawn from 6 edges (hexagon pattern), deterministic rotation, walk to base
- Brute enemies (Phase 2+) — 3x HP, 0.5x speed, 2x gold, deterministic spawn every Nth enemy
- Runner enemies (Phase 3+) — 0.5x HP, 2x speed, deterministic spawn every Nth enemy
- Enemy health bars (green/yellow/red), floating damage numbers
- Boss spawns every wave % 10, purple octagon, HP bar with number display
- Boss drops gold (phase scaled) + LP (phase scaled), has death sound
- Difficulty variable — never resets, +1/wave +3/boss, phase start = (phase-1) * 10
- Gold economy — base (5 + (phase-1) * 3)g per kill, flat scaling per phase
- Legacy points — run_lp (this run, shown in UI) separate from cumulative SaveManager total
- LP saves incrementally (crash-safe), no double-add on game over
- Slide-up upgrade panel — 4 columns (ATK/HP/DEF/UTIL), 20 total stats
- In-game upgrade costs always start from base (floor levels don't inflate costs)
- Tiered pricing system — 7 tiers with differentiated gold and LP costs
- Shield system — 50% base DR, caps at 80% (100 levels), 10% base regen per tick
- HP regen system — tick-based with logarithmic interval scaling
- Evasion — % chance to completely dodge a hit
- Damage numbers: white (normal), orange (crit), blue (shield), red (HP), gold 💰, purple ★ (LP), red 🩸 (bleed)
- Damage number layout: damage/crit north, bleed west, gold east, LP south
- LP drop shows on enemy that dropped it (not base position)
- Damage numbers correctly scale with camera zoom (world→screen position conversion)
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
- Skill tree scene — standalone scene from start menu, procedurally built UI (rewrite planned for polish phase)
- SkillManager autoload — tokens, shards, unlock/level logic, all effect queries built
- MechanicsManager autoload — all skill-driven mechanics
- EnemyMechanics autoload — all shared enemy behavior
- SpawnManager node — all spawn logic moved out of main.gd
- Detection range ring — shows on hover over base, scales with Range skill investment
- Barrage Rapidfire (Slot 0) ✅ — every 3rd attack deals +20% bonus damage, cyan-blue larger bullet visual
- Barrage Bleed (Slot 1) ✅ — every attack applies DoT, ticks every 0.5s, tick count scales with crit chance investment, first tick doubles on actual crit
- Barrage Focus (Slot 2) ✅ — consecutive hits on same target ramp damage +10% per hit, resets on kill
- Barrage Range (Slot 3) ✅ — increases detection radius, base +100px, +15px per shard level, soft cap ~800-900px
- Barrage Momentum (Slot 4) ✅ — bullets deal more damage the further they travel, base 0.05% per pixel, +0.02% per shard level. Estimated at fire time for stray bullet prevention.
- Barrage Chain Keystone (Slot 5) ✅ — bullets chain to nearby enemies on hit. 2 jumps base, +1 per 5 shard levels. Falloff 60% base, +2% per shard (no cap — late game chains can exceed primary damage). 250px hop radius per jump. Railgun visual (thin cyan rectangle, 2x bullet speed). Chain hops are sequential, each spawns visual projectile, each deals damage number.

---

## Architecture — CRITICAL, READ BEFORE CODING

### Coding Standards
- **File naming:** All folders Capitalized (Scripts/, Assets/, Scenes/), all files lowercase (base.gd, main.gd, enemymechanics.gd). This matters on export — never violate it.
- **Indentation:** Tabs only, never spaces. Godot will reject mixed indentation.
- **Visual flags:** Any visual that depends on a flag (is_crit, is_rapidfire, is_keystone, etc.) must be set in setup() not _ready(). _ready() fires before setup() so flags will always be false at draw time.

### Autoloads
| Name | File | Purpose |
|------|------|---------|
| SaveManager | Scripts/savemanager.gd | Persistent save, all data keys |
| AudioManager | Scripts/audiomanager.gd | SFX and music |
| TooltipData | Scripts/tooltipdata.gd | Tooltip descriptions for all 20 stats |
| SkillManager | Scripts/skillmanager.gd | Skill tree state, tokens, shards, effect queries |
| MechanicsManager | Scripts/mechanicsmanager.gd | Skill-driven mechanics (Focus, Fortify, Vampiric, Zap, Rampart, Chill, Overheal, Surge, Momentum, Chain) |
| EnemyMechanics | Scripts/enemymechanics.gd | Shared enemy behavior (movement, separation, attack ticking, health bar drawing, bleed) |

### Where Things Live
**New skill mechanic goes in:** `mechanicsmanager.gd` only. Never implement skill logic in enemy files or base.gd directly.

**New enemy status effect goes in:** `enemymechanics.gd` only. Enemy files just declare state vars and delegate.

**New enemy type:** Create a thin script with unique stats, visual, scale_to_wave(), setup(). Call EnemyMechanics for everything else. Add bleed state vars. Done.

**New spawn pattern/mode:** `spawnmanager.gd` only. main.gd just calls $SpawnManager.tick(delta).

**Skill effect queries:** `skillmanager.gd` only. Gate on `is_skill_unlocked()` not `level == 0` — level 0 is valid (unlocked but no shards spent).

**Damage numbers:** All spawn via `main_node.spawn_damage_number(amount, pos, type)`. Position must be passed as world position — `spawn_damage_number` converts to screen space accounting for camera zoom. Types defined in `damage_number.gd`.

### Modular Design Rules
- Skills 0-4 (pre-keystone) work with ALL attack types — bullet, pulse, drain beam. No attack type assumptions in pre-keystone skill logic.
- Attack counter (`_attack_counter` in base.gd) is attack-type agnostic. Call `_tick_attack_counter()` at the fire point of any new attack type and Rapidfire works automatically.
- `get_damage_bonuses(base_node)` in MechanicsManager returns `[flat_bonus, pct_bonus]` — call this once in _try_shoot() to apply all passive damage skills. Add new passive damage skills inside this function only.
- Bleed state vars are declared in each enemy file but all logic lives in EnemyMechanics. When adding new status effects follow same pattern: vars in enemy file, logic in EnemyMechanics.

### Targeting System
Smart targeting in base.gd factors in bleed and momentum damage when calculating hits_needed:
```gdscript
var estimated_travel = global_position.distance_to(target.global_position)
var momentum_bonus = MechanicsManager.get_momentum_bonus(estimated_travel)
var effective_damage = ((bullet_damage * damage_multiplier) + total_bleed) * (1.0 + momentum_bonus)
var hits_needed = ceil(target.health / effective_damage)
```
When adding new damage-over-time or damage-modifier effects, update effective_damage calculation here too.

### Keystone Implementation Pattern
- Barrage keystone detected via `SkillManager.get_active_keystone() == SkillManager.TREE_BARRAGE`
- Keystone flag passed through `projectile.setup()` as `is_keystone` bool
- Chain logic lives entirely in `MechanicsManager.trigger_chain()`
- Chain hop projectiles use proximity detection (< 12px) not collision for arrival
- All keystones must work with: Range bonus to detection, Momentum travel bonus, Rapidfire attack counter

---

## File Structure
```
base-defence/
├── main.tscn
├── project.godot
├── DESIGN.md
├── Scenes/
│   ├── enemy.tscn
│   ├── brute.tscn
│   ├── runner.tscn
│   ├── boss.tscn
│   ├── projectile.tscn
│   ├── damage_number.tscn
│   ├── startmenu.tscn
│   ├── workshop.tscn
│   └── skilltree.tscn
├── Scripts/
│   ├── main.gd              # Game loop, wave progression, economy, UI handlers, pause/restart
│   ├── base.gd              # Shooting, targeting, crit, shield, HP regen, attack counter, hover ring
│   ├── enemy.gd             # Thin — unique stats + visual only, delegates to EnemyMechanics
│   ├── brute.gd             # Thin — unique stats + visual only, delegates to EnemyMechanics
│   ├── runner.gd            # Thin — unique stats + visual only, delegates to EnemyMechanics
│   ├── boss.gd              # Thin — unique stats + visual only, delegates to EnemyMechanics
│   ├── projectile.gd        # Bullet movement, homing, visual flags (crit/rapidfire/keystone/chain), bleed + momentum + chain
│   ├── damage_number.gd     # Floating text, color types, emoji prefixes
│   ├── start_menu.gd        # Start menu, phase select, debug buttons
│   ├── workshop.gd          # LP spending, floor upgrades, tiered costs
│   ├── skilltree.gd         # Skill tree UI — fully procedural, standalone scene
│   ├── spawnmanager.gd      # All spawn logic — enemy selection, edge positions, boss spawn
│   ├── upgrademanager.gd    # All 20 upgrade handlers, workshop floor application, calc functions
│   ├── uimanager.gd         # Button updates, tooltip, screen flash, unlock system
│   ├── economymanager.gd    # Gold/LP calculations
│   ├── savemanager.gd       # AUTOLOAD — persistent save
│   ├── audiomanager.gd      # AUTOLOAD — SFX and music
│   ├── tooltipdata.gd       # AUTOLOAD — tooltip text for all 20 stats
│   ├── skillmanager.gd      # AUTOLOAD — skill state, tokens, shards, effect queries
│   ├── mechanicsmanager.gd  # AUTOLOAD — all skill-driven mechanics
│   └── enemymechanics.gd    # AUTOLOAD — all shared enemy behavior
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
├── EconomyManager (Node) — economymanager.gd
├── UpgradeManager (Node) — upgrademanager.gd
├── UIManager (Node) — uimanager.gd
├── SpawnManager (Node) — spawnmanager.gd
└── UI (CanvasLayer)
    ├── CurrencyLabel
    ├── WaveLabel
    ├── PauseButton
    ├── SpeedButton (top right)
    ├── MuteButton
    ├── BuyAmountButton
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
            │   ├── DmgMultButton     unlock: 1
            │   ├── CritChanceButton  unlock: 3
            │   └── CritDmgButton     unlock: 4
            ├── HPColumn (VBoxContainer)
            │   ├── HPHeader
            │   ├── MaxHPButton       unlock: 1
            │   ├── RegenAmtButton    unlock: 1
            │   ├── HPMultButton      unlock: 3
            │   ├── RegenSpdButton    unlock: 3
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
- Enemy attack: `7.0 * (1.0 + (difficulty * 0.13)) * phase_scale` where phase_scale = 1.0 for phase 1, 0.85 for phase 2+
- Enemy speed: FIXED per type (no difficulty scaling)
  - Basic: 72, Brute: 45, Runner: 230
- Spawn interval: `(0.8 / (1.0 + (difficulty * 0.09))) * randf_range(0.8, 1.2)` (slight variance)

### Wave System (Kill-Based)
- Enemy count per wave: `BASE_ENEMIES_PER_WAVE + (wave * 1.35) + (phase * 2)`
- BASE_ENEMIES_PER_WAVE = 12
- Wave is cumulative — never resets between phases
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
- Gold Multiplier: +5% per level (changed from 10%)
- Displayed gold = actual received amount (post-multiplier)

### LP Economy
- run_lp: tracks this run only (shown in UI, resets each run)
- SaveManager["legacy_points"]: cumulative total, saves incrementally (crash-safe)
- Base: 1 LP per wave completion
- Boss: `10 + ((phase-1) * 3)` LP, affected by LP Gain and LP Mult
- LP Gain: +1 LP flat added to all sources
- LP Multiplier: +5% per level (changed from 10%)
- LP Drop Chance: base 10%, logarithmic scaling, cap 60%
  - Formula: `chance += 0.008 / (1.0 + i * 0.03)` per level
  - Level 10: ~17.5%, Level 20: ~22.5%, Level 50: ~36%, Level 100: ~58%
- Drop formula: `int((1 + lp_gain_level) * (1.0 + legacy_mult_level * 0.05))`

### Bullet + Crit System
- Locks onto target, never switches mid-flight
- Only fires if target needs more bullets — hits_needed factors in bleed + momentum total damage
- Base crit: 1.5x damage, 0% chance
- Crits calculated in base.gd, passed through to projectile and damage numbers
- Bleed resets (not stacks) on each new hit — fresh application cancels remaining ticks
- Barrage keystone active: bullet speed 2x, railgun visual, chain triggers on hit

### Bleed System
- Procs on every attack (not crit-gated)
- First tick fires simultaneously with hit damage
- First tick doubles if the hit was an actual crit roll
- Tick count based on crit chance investment:
  - 0-20%: 2 ticks, 21-40%: 3 ticks, 41-60%: 4 ticks, 61-80%: 5 ticks
- Ticks every 0.5 seconds
- Damage per tick: 5 + (shard_level * 2)
- Bleed resets on new application — no stacking
- Targeting accounts for full bleed tick total to prevent stray bullets

### Shield System (Reworked)
- Shield absorbs incoming hits (pool depletes by hit amount)
- Formula: HP damage = hit_amount * (1.0 - shield_strength)
- Base shield strength: 50% DR (changed from 20%)
- DR cap: 80% at 100 levels (+0.3% per level)
- Shield per level: +20 (changed from +50, keeps parity with HP at +10 — DR does the heavy lifting)
- Shield regen: 10% of max shield per tick, base interval 5s (logarithmic curve)
- Shield Regen uses same `calc_regen_spd()` function as HP regen
- Shield Multiplier: multiplies effective max shield
- Design intent: shield is NOT just another HP bar — it's mandatory survivability mid-late game. Phase 4-5 is where shield investment becomes necessary. Equal investment in HP and shield provides equivalent effective survivability due to DR.

### HP Regen System
- Tick-based with logarithmic interval scaling
- `calc_regen_spd(level)` in upgrademanager.gd:
  - Base 5.0s, reduces by `0.25 / (1.0 + i * 0.05)` per level
  - Level 5: ~4.0s, Level 20: ~2.4s, Level 50: ~1.2s, Level 100: ~0.5s cap
- Same function used for both HP regen interval and Shield regen interval

### ATK SPD Curve
- Logarithmic diminishing returns via level-to-value function
- `calc_atk_spd(level)` — sums 0.115 / (1.0 + i * 0.02) per level
- Lv1 ~1.115/s, Lv10 ~2.0/s, Lv50 ~5.27/s, Lv100 ~7.99/s
- Both in-game handler and workshop floors use same function — values always match

### Damage Number System
- All numbers spawn via `main_node.spawn_damage_number(amount, pos, type)`
- Position passed as WORLD position — spawn_damage_number converts to screen space via camera zoom
- Layout (relative to enemy center): damage/crit north, bleed west, gold east, LP south
- Types and colors defined in damage_number.gd:
  - normal: white
  - crit: orange, larger font
  - shield: blue
  - hp: red
  - gold: gold + 💰 prefix
  - lp: purple + ★ prefix, larger font
  - bleed: bright red + 🩸 prefix
  - zap: future — color TBD
  - chain: same as normal (each hop shows damage number)

### Boss Scaling
- HP: `400 * pow(5.0, phase-1)` — aggressive, boss is always a bullet sponge
- Damage: `22.0 * pow(2.25, phase-1) * phase_scale` — dangerous but not instant kill
  - Phase 1: ~22 dmg, Phase 3: ~95 dmg, Phase 6: ~1079 dmg (539 to HP with 50% DR)
  - Design intent: boss should always feel like a close call. High DPS players kill it before it reaches them. Lower DPS players need to tank hits — shield becomes critical.
- Boss crit chance 30%, 2x crit multiplier

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

### Cost Helpers (in upgrademanager.gd)
```gdscript
func calc_cost(base, level, is_capped)   # standard capped/infinite
func calc_cost_flat(base, level)          # x1.15 scale (T1, T2A, T4A)
func calc_cost_mult(base, level)          # x1.25 scale (T3A mult, T4B)
func calc_atk_spd(level)                 # logarithmic ATK SPD curve
func calc_regen_spd(level)               # logarithmic regen interval curve (HP and Shield)
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
| 1 | Reach wave 10 (boss wave) | + Max HP, HP Regen Amt, DMG Mult |
| 2 | Beat boss 1 | + Shield, Shield Regen, Gold/Kill, LP Gain. Workshop + Phase selector unlock. |
| 3 | Beat boss 2 | + DMG Mult, HP Mult, Shield Strength, Gold Mult, LP Mult, Crit Chance, Regen Spd |
| 4 | Reach phase 3 boss wave | Everything — all 20 stats, skill tree visible |

**Future plan:** Replace milestone unlocks with LP-gated unlocks within the workshop. Stats are hidden until unlocked (mystery preserved). Workshop shows "VELA continues to evolve..." hint at bottom. Skill tree skills remain fully visible at all times — players need to see the tree to plan builds.

---

## Workshop
- Separate scene (workshop.tscn)
- Spend LP on permanent stat floors
- Same stat values as in-game (workshop Lv5 = in-game Lv5 starting point)
- In-game costs ALWAYS reset to base (floor level doesn't affect upgrade cost)
- Button displays: STAT NAME (Lv X) | current value | gain per level | cost LP
- Workshop mirrors unlock_level — same stats visible as in-game
- Skill Tree tab removed from workshop — skill tree is its own scene from start menu
- Phase Tokens, Phase Shards, Lifetime Kills displayed at top of workshop (from SaveManager)

---

## Skill Tree Scene
- Standalone scene (skilltree.tscn) accessible from start menu
- Fully procedurally built UI in skilltree.gd — no scene nodes, all code
- Stat bar at top of both views: 🔷 Tokens | ⚡ Shards | ☠ Kills (X / next_shard_threshold)
- Three tree cards on select view, tap to open tree
- Tree view shows skill slots: Keystone(5) → [3,4] side-by-side → [1,2] side-by-side → [0]
- Each card shows: name, level, description, unlock or level button, prereq hint if locked
- Skills always fully visible — players need to see the tree to plan builds
- UI rewrite planned for polish phase — procedural approach intentional for now

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

# Skill tree
phase_tokens          # current spendable tokens
phase_tokens_earned   # lifetime total earned
phase_shards          # current spendable shards
phase_shards_earned   # lifetime total earned
lifetime_kills        # tracks shard generation
skill_barrage_unlocked  # array of unlocked slot indices
skill_bulwark_unlocked  # array of unlocked slot indices
skill_siphon_unlocked   # array of unlocked slot indices
skill_barrage_levels    # array of level per skill (index matches unlocked array)
skill_bulwark_levels    # array of level per skill
skill_siphon_levels     # array of level per skill
active_keystone         # "barrage" / "bulwark" / "siphon" / ""
```

---

## Skill Trees

### Overview
- 3 trees: Barrage (ATK) / Bulwark (DEF) / Siphon (Healing)
- 6 slots per tree: slots 0-4 are skills, slot 5 is keystone
- Skills 7-9 and capstone (skill 10) not yet designed — post-launch
- Requires unlock_level 4 (reach phase 3 boss wave)
- Two skill currencies: Phase Tokens and Phase Shards
- Skill effect gates: use `is_skill_unlocked()` only — level 0 is valid (base effect active)

### Slot Structure
```
Position 0: root skill, always available
Position 1: left branch, requires position 0
Position 2: right branch, requires position 0
Position 3: left continues, requires position 1
Position 4: right continues, requires position 2
Position 5: Keystone, requires position 3 AND position 4
```

### Currencies

**Phase Tokens**
- Earned: 1 per phase boss killed, permanent, phases 3-18
- Hard cap: 15 lifetime
- Purpose: Unlock skills (spend one per skill)
- Respec: exists, reallocates tokens (LP cost TBD)
- Sequential unlock per branch — must unlock prior slot before next

**Phase Shards**
- Earned: every X lifetime kills (scales — base 1000, +100 per shard already earned)
- Infinite, no cap
- Purpose: Level up unlocked skills
- Progress visible in skill tree stat bar as (kills / next_threshold)

### Skill Point Economy
- 15 Phase Tokens hard cap enforces build identity
- To reach keystone: 6 tokens minimum (slots 0,1,2,3,4 + keystone)
- Cannot reach a second keystone (needs 12 tokens minimum)
- Grey out enforced in UI regardless of math

### Keystone Rules
- Keystone is slot index 5 in each tree
- Requires slots 3 AND 4 unlocked before keystone available
- Changes attack type for the run
- Once any keystone chosen, other two permanently greyed out

### Design Principles
- Skills 0-4 work pre-keystone with default bullets — no attack type assumptions
- Each skill: one core stat feeds it, Phase Shards scale it
- No core stat appears in more than one tree
- Power budget roughly equal across equivalent slot numbers
- Cross-tree dipping valid but only pays off with core stat investment

---

## Skill Definitions

### BARRAGE — "The Artillery"
*Bullets are the weapon. Distance is the advantage.*

**Slot 0 — Rapidfire** ✅ BUILT
Every 3rd attack deals bonus damage. Base +20%, +5% per shard level.
Visual: cyan-blue larger bullet on every 3rd shot.

**Slot 1 — Bleed** ✅ BUILT (left branch)
Every attack applies a DoT. Procs on every attack, not crit-gated.
Tick count based on crit chance: 0-20%=2, 21-40%=3, 41-60%=4, 61-80%=5 ticks.
First tick fires simultaneously with hit. First tick doubles if actual crit.
Ticks every 0.5s. Base 5 damage/tick, +2 per shard level.
Visual: 🩸 red damage number, west of hit number.

**Slot 2 — Focus** ✅ BUILT (right branch)
Consecutive hits on same target ramp damage +10% per hit. Resets on kill.
Base +10% per hit, +1% per shard level. Primary boss killing stat.

**Slot 3 — Range** ✅ BUILT (left continues)
Increases bullet detection radius. Base +100px, +15px per shard level.
Soft cap ~800-900px (spawn distance is ~1300-1400px, reaching spawn would trivialize game).
Visual: detection ring shown on base hover, scales with Range investment.

**Slot 4 — Momentum** ✅ BUILT (right continues)
Bullets deal more damage the further they travel. Base 0.05% per pixel, +0.02% per shard level.
Synergizes with Range — longer detection = more travel = harder hits.
Estimated at fire time using target distance for stray bullet prevention.
No hard cap — scales infinitely with Range investment.

**Slot 5 — Keystone: Chain** ✅ BUILT
Bullets chain to nearby enemies on hit. Sequential hops, each spawns visual projectile.
2 jumps base, +1 per 5 shard levels.
Falloff: 60% base, +2% per shard level, no cap — late game chains can exceed primary damage.
250px hop radius from last hit enemy. Cannot hit same enemy twice per chain.
Visual: thin cyan railgun line (14x4px), 2x bullet speed. Chain hops same style (8x4px).
Damage number on every hop. Works with all pre-keystone skills.
Note: bullet speed increase indirectly boosts DPS (faster resolution = faster next shot) — intentional, balanced against Pulse AOE and Drain Beam instant damage.

---

### BULWARK — "The Fortress"
*Defense becomes offense. The bigger the wall, the harder it hits.*

**Slot 0 — Fortify** 🔲 NOT BUILT
Every 100 Max Shield adds flat bonus damage. Base 2 per 100, +1 per shard level.
Reads from MechanicsManager.get_fortify_bonus(max_shield). Already defined, needs wiring in base.gd.

**Slot 1 — Ironclad** 🔲 NOT BUILT (left branch)
Current shield % adds bonus damage %. Max bonus: base 15%, +5% per shard level.
Reads from MechanicsManager.get_ironclad_bonus(shield, max_shield). Already defined, needs wiring.

**Slot 2 — Zap** 🔲 NOT BUILT (right branch)
Every shield regen tick fires damage at nearest enemy. Base 8 dmg, +3 per shard level.
Triggered via MechanicsManager.trigger_zap() in base.gd shield regen tick. Already defined.
Uses "zap" damage number type (color TBD).

**Slot 3 — Rampart** 🔲 NOT BUILT (left continues)
Killing enemy restores flat shield. Base 3, +1 per shard level.
MechanicsManager.trigger_rampart() already called in every enemy _die(). Already defined.
Silent — no damage number, shield bar updates.

**Slot 4 — Knockback** 🔲 NOT BUILT (right continues)
Hitting an enemy pushes them back. Force scales off Shield Strength.
Base 80px knockback force, +20 per shard level.
Note: needs range consideration — infinite knockback not viable. Design TBD (diminishing returns or secondary effect at high levels).

**Slot 5 — Keystone: Pulse** 🔲 NOT BUILT
Replaces bullets with AOE pulse. Fires on ATK SPD interval, hits all enemies in radius.
Requires Slot 3 AND Slot 4.
Note: Range affects pulse radius. Pulse is instant (no travel), so Momentum does not apply. Fortify and Ironclad still feed damage.

---

### SIPHON — "The Drain"
*Sustain becomes offense. The longer you survive, the harder you hit.*

**Slot 0 — Vampiric** 🔲 NOT BUILT
HP Regen Amount adds flat bonus damage. Base 1 per regen, +0.5 per shard level.
Reads from MechanicsManager.get_vampiric_bonus(hp_regen). Already defined, needs wiring in base.gd.

**Slot 1 — Chill** 🔲 NOT BUILT (left branch)
Every HP regen tick slows nearest enemy. Base 10% slow, +3% per shard, cap 60%.
MechanicsManager.trigger_chill() triggered in base.gd HP regen tick. Already defined.
Visual: icy blue glow on slowed enemy (no damage number).

**Slot 2 — Overheal** 🔲 NOT BUILT (right branch)
Overheal buffer above max HP. Base 10% of max HP, +3% per shard level.
MechanicsManager.get_overheal_ceiling(max_hp) already defined.
Needs implementation in base.gd — allow health to exceed get_effective_max_hp() up to ceiling.

**Slot 3 — Surge** 🔲 NOT BUILT (left continues)
While overhealed, deal bonus damage %. Base 15%, +5% per shard level.
MechanicsManager.get_surge_bonus(health, max_hp) already defined.
Folds into hit damage — no separate number.

**Slot 4 — Vitality** 🔲 NOT BUILT (right continues)
Killing an enemy restores flat HP. Base 2 HP per kill, +1 per shard level.
Feeds Overheal loop — kills push back into overheal, overheal activates Surge.
Silent — no damage number, HP bar updates.

**Slot 5 — Keystone: Drain Beam** 🔲 NOT BUILT
Replaces bullets with continuous beam. Damages and heals simultaneously.
Ticks on ATK SPD interval. Crits = burst damage + burst heal.
Requires Slot 3 AND Slot 4.
Note: Drain Beam is instant (no travel), Momentum does not apply. Range affects detection only. Vampiric still feeds damage. Implementation is complex — later problem.

---

### Cross-Tree Synergies
- Barrage + Bulwark: Knockback → enemies travel further → Momentum bonus. Shield feeds Fortify.
- Barrage + Siphon: Vampiric adds flat to bullets. Vitality sustains HP for more aggressive play.
- Bulwark + Siphon: Chill slows enemies into pulse range. Overheal → Surge while shield holds.
- Siphon + Bulwark: Zap fires with drain beam ticks. Rampart builds shield pool from kills.

---

## Enemy Variety

### Built
- Basic: red hexagon, size 15, speed 72, standard stats
- Brute (Phase 2+): orange hexagon, size 25, speed 45, 3x HP, attack scales with difficulty, 2x gold
- Runner (Phase 3+): yellow hexagon, size 10, speed 230, 0.5x HP — explodes on contact, high contact damage
- Boss: purple octagon, spawns every 10 waves, scales aggressively per phase

### Not Yet Built
- Shielder (Phase 3): shield bar before HP
- Ranged (Phase 4): stops at distance, fires projectiles

### Enemy Architecture
All enemies are thin scripts — unique stats, visual draw, scale_to_wave(), setup().
EnemyMechanics autoload handles: movement, separation, attack ticking, health bar drawing, bleed ticking, take_damage.
Adding a new enemy: declare state vars (bleed vars required), draw visual, set separation_radius, done.

### Boss System
- Single boss type currently — purple octagon placeholder
- Spawns every wave % 10
- HP/ATK/speed scale per phase
- 5 boss variants planned post-launch (Rusher, Tank, Ranged, Swarm Caller, Standard)

---

## Enemy/Boss Visual Identity (Future)
Humanoid robots — deteriorating military/industrial hardware drawn to VELA.
VELA: precise, geometric, blue. Robots: humanoid, mechanical, decaying. Order vs entropy.
Overall visual direction: EDM festival lightshow aesthetic — clean neon lines, bright geometry, 3D-feeling shapes. Similar to The Tower but more flashy and vibrant.

---

## Meta Progression Loop
1. Run → die → earn LP based on phase reached (saves incrementally)
2. Spend LP in workshop on permanent stat floors
3. Stats unlock milestone by milestone (boss kills, phase reached) — future: LP-gated unlocks
4. Kill phase bosses → earn Phase Tokens → unlock skill tree skills
5. Accumulate lifetime kills → earn Phase Shards → level up unlocked skills
6. Veteran players start at higher phases to farm or push leaderboard

---

## Balance Notes (Tested)
- Phase 1 fresh run: 3 run arc feels correct — do not touch phase 1 scaling
- Phase 2 spike was too harsh — fixed with 0.85 phase_scale on enemy attack for phase 2+
- Shield at 50% base DR is immediately noticeable even with minimal investment
- Economy: gold mult and LP mult reduced to 5% per level (from 10%) — felt too spikey
- LP drop chance reworked to logarithmic curve, base 10% (from 5%)
- Boss damage reworked to `pow(2.25)` (from `pow(4.6)`) — was one-shotting players mid-game
- Late game (phase 6-7) boss hits for ~539 to HP per non-crit — dangerous but survivable with shield
- ~33 LP per boss-kill run (phase 1)
- Wave enemy count at phase 4 wave 40: ~74 enemies

---

## Known Issues / Tech Debt
- Upgrade panel UI has a display bug (introduced during this session) — defer until UI rewrite
- StatContent removed from workshop.tscn (tokens/shards/kills now coded in)
- Skill tree procedural UI has layout limitations — full node-based rewrite planned for polish phase
- Save file location differs between editor and exported builds — document and backup before export
- Damage number toggle planned (per-type on/off) — important for late game lightshow builds

---

## Future Game Modes (NOT YET BUILT — foundation first)
- **Challenge Mode:** 5-minute daily run, fixed phase, enemies don't scale, simulates ~1hr of normal progression
- **Idle Mode:** 12-hour session, fixed phase/difficulty, enemies trickle in slowly
- **Tournament Mode:** Fresh state, no workshop floors/skill levels, all systems unlocked, weekly/monthly resets, exclusive cosmetic rewards
- All modes share same enemies/mechanics/base — only spawn behavior and session rules change
- SpawnManager is the right place to implement mode-specific spawn logic when the time comes

---

## Remaining Build Order
1. ✅ Core loop
2. ✅ Workshop + LP system
3. ✅ Unlock/onboarding
4. ✅ Phase start selector
5. ✅ Damage number system (7 types)
6. ✅ Kill-based wave system
7. ✅ Enemy variety (Brute, Runner)
8. ✅ Tiered balance (gold, LP, enemy scaling)
9. ✅ Sound effects + music
10. ✅ Camera zoom + speed toggle
11. ✅ Tooltip system
12. ✅ Workshop current values + level display
13. ✅ LP persistence fix
14. ✅ Architecture refactor (EnemyMechanics, MechanicsManager, SpawnManager)
15. ✅ Skill tree scene + SkillManager foundation
16. ✅ Barrage Rapidfire (Slot 0)
17. ✅ Barrage Bleed (Slot 1)
18. ✅ Barrage Focus (Slot 2)
19. ✅ Barrage Range (Slot 3)
20. ✅ Barrage Momentum (Slot 4)
21. ✅ Barrage Chain Keystone (Slot 5)
22. ✅ Balance pass (shield rework, boss damage, enemy scaling, economy tuning)
23. 🔲 Bulwark Fortify (Slot 0)
24. 🔲 Bulwark Ironclad (Slot 1)
25. 🔲 Bulwark Zap (Slot 2)
26. 🔲 Bulwark Rampart (Slot 3)
27. 🔲 Bulwark Knockback (Slot 4)
28. 🔲 Bulwark Pulse Keystone (Slot 5)
29. 🔲 Siphon Vampiric (Slot 0)
30. 🔲 Siphon Chill (Slot 1)
31. 🔲 Siphon Overheal (Slot 2)
32. 🔲 Siphon Surge (Slot 3)
33. 🔲 Siphon Vitality (Slot 4)
34. 🔲 Siphon Drain Beam Keystone (Slot 5)
35. 🔲 Shielder + Ranged enemy types
36. 🔲 Damage number display toggle (per-type player setting)
37. 🔲 Skill tree UI rewrite (node-based, polish phase)
38. 🔲 Tower visual evolution (build identity)
39. 🔲 Enemy/boss visuals (humanoid robot sprites, neon EDM aesthetic)
40. 🔲 UI/UX visual polish
41. 🔲 LP-gated unlock system (replace milestone unlocks)
42. 🔲 Leaderboard
43. 🔲 Browser export + mobile polish
44. 🔲 Skills 7-9 + capstones (post-launch)
45. 🔲 Boss variant system (post-launch)
46. 🔲 Wardrobe/cosmetic system (post-launch)
47. 🔲 Challenge + Idle + Tournament modes (post-launch)
48. 🔲 itch.io / Steam launch

---

## Design Principles
- Core stats = power, Skill trees = behavior and visual identity
- Three win conditions: Barrage (kill fast), Bulwark (outlast), Siphon (drain to survive)
- All core stats remain valuable regardless of tree — no dead investment. Every stat should eventually feel necessary, just at different investment levels depending on build.
- Keystone changes attack type — 15 token cap means only 1 keystone possible
- Cross-tree dipping valid but only pays off with core stat investment
- Economic self-regulation — infinite stats get expensive, gold better elsewhere late
- Death is informative — each run teaches what you needed
- Build identity — 15 token cap forces meaningful commitment
- Same stat values everywhere — workshop floor sets starting level
- In-game costs always reset to base
- Never fully done — infinite scaling keeps veterans engaged
- Tournament mode = skill competition, main game = progression competition
- Monetization: never pay to win. Premium cosmetics only (wardrobe system).
- Speed toggle (1x/1.5x/2x) is free for all players — cosmetics are the monetization hook, not convenience

---

## WARDROBE SYSTEM (Post-Launch)
Cosmetic layer on top of skill visual tier system. Skill investment unlocks tiers automatically. Wardrobe lets players choose alternate variants per tier.

Each tier: 1 free default, 2-3 earned variants (gameplay milestones), 2-3 premium variants (purchased).

Visual identity per tree:
- Barrage: range/velocity theme (glow ring → tracers → chain lightning streams)
- Bulwark: armor/presence theme (hardened edges → plating → pulse ring → ground crack)
- Siphon: drain/sustain theme (wisps → tendrils → drain beam → multi-target overflow)

Shader approach: single CanvasItem shader on projectile Visual node, color as parameter. Glow effect on all bullet types — especially impactful on thin railgun lines and chain hops.

---

## STORY
VELA — an AI that found something worth protecting in a dying world. Built a tower. Sent a signal. Waits. Evolves because evolution is the only currency that buys another day.

Enemies: humanoid robots — not intelligent, not coordinated, just pulled toward whatever VELA is protecting.

---

## Skill Tree UI — Future Rewrite Note
Current skilltree.gd is fully procedural (all UI built in code). This was intentional to move fast and test skills. When skills are complete, rewrite the UI using Godot editor nodes for cleaner styling. Each skill gets its own dedicated screen showing: current level, next level preview, effect curve visualization, lore/flavor text. The skill logic (SkillManager calls, unlock/level handlers) stays identical — only presentation layer changes.
