# Phasefall — Game Design Document
**Studio:** Elydar Studios
**Engine:** Godot 4
**Target:** Mobile (portrait 720x1280) + Browser
**Status:** Alpha v0.5 — Barrage tree complete, Bulwark tree complete (all 6 skills including Pulse keystone), shield rework, targeting system unified, ATK SPD curve adjusted, workshop UI dynamic display.

---

## Current Build State
Everything below is BUILT and WORKING:
- Start menu with studio branding, phase selector (◀ PHASE X ▶), workshop button, skill tree button
- SaveManager autoload — persistent save across sessions
- Full game loop: spawn → kill → upgrade → die → workshop → run again
- Base (blue hexagon) true center screen (360, 640), auto-shoots nearest enemy
- Smart bullet targeting — locks onto target, prioritizes closest to base, factors in bleed + zap + momentum damage to avoid stray bullets via unified _get_committed_damage()
- Attack counter system — attack-type agnostic, used by all fire modes (bullet, pulse, future beam)
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
- Shield system — 50% base DR, absorbs hits, overflow hits HP directly, caps at 80% DR (100 levels), 10% base regen per tick
- HP regen system — tick-based with logarithmic interval scaling
- Evasion — % chance to completely dodge a hit
- Damage numbers: white (normal), orange (crit), blue (shield), red (HP), gold 💰, purple ★ (LP), red 🩸 (bleed), yellow ⚡ (zap)
- Damage number layout: damage/crit north, bleed west, gold east, LP south
- LP drop shows on enemy that dropped it (not base position)
- Damage numbers correctly scale with camera zoom (world→screen position conversion)
- Game over screen — phase reached, restart + main menu buttons
- Pause screen — resume, restart, main menu
- Workshop scene — spend LP on permanent stat floors, tiered LP costs, current value + dynamic per-level gain display
- Workshop shows current level per stat (Lv X) with accurate per-level gain for logarithmic stats
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
- ATK SPD display updates to show pulse interval (Xs interval) when Bulwark keystone active
- Barrage Rapidfire (Slot 0) ✅
- Barrage Bleed (Slot 1) ✅
- Barrage Focus (Slot 2) ✅
- Barrage Range (Slot 3) ✅
- Barrage Momentum (Slot 4) ✅
- Barrage Chain Keystone (Slot 5) ✅
- Bulwark Fortify (Slot 0) ✅
- Bulwark Ironclad (Slot 1) ✅
- Bulwark Zap (Slot 2) ✅
- Bulwark Rampart (Slot 3) ✅
- Bulwark Knockback (Slot 4) ✅
- Bulwark Pulse Keystone (Slot 5) ✅

---

## Architecture — CRITICAL, READ BEFORE CODING

### Coding Standards
- **File naming:** All folders Capitalized (Scripts/, Assets/, Scenes/), all files lowercase (base.gd, main.gd, enemymechanics.gd). This matters on export — never violate it.
- **Indentation:** Tabs only, never spaces. Godot will reject mixed indentation.
- **Visual flags:** Any visual that depends on a flag (is_crit, is_rapidfire, is_keystone, etc.) must be set in setup() not _ready(). _ready() fires before setup() so flags will always be false at draw time.
- **Full function rewrites:** When indentation is involved always provide full function rewrites, never snippets. Godot rejects mixed tab/space indentation.
- **Minimal targeted changes:** Keep changes as small and targeted as possible. Never refactor working code unless specifically asked.

### Workflow Rules
- **Always discuss logic and numbers before writing code for each skill.** Confirm design → confirm numbers/balance → confirm visuals → implement.
- **Benchmark new skills against equivalent slot in other trees** for parity. Slot 0 vs slot 0, slot 1 vs slot 1, etc.
- **Never balance off current enemy HP** — enemy scaling will need a full pass after all skills are implemented. Balance skills relative to each other, not against enemies.
- **Skill tree levels display as Lv1 on unlock** (level 0 internally = just unlocked). UI polish pass will add +1 display offset. Do NOT change formulas — the base value at level 0 is intentionally tuned.
- **No caps on skill tree skills** — infinite shard scaling is by design. Balance through base values and scaling rates, not hard caps.
- **All trees are attack trees** — win condition varies (kill fast / outlast / drain to survive) but every tree should feel offensively viable. No purely defensive skills.
- **Every core stat should eventually feel necessary** regardless of tree. Trees shift investment priority, not investment destination. A Bulwark player will eventually need damage; a Barrage player will eventually need shield.

### Autoloads
| Name | File | Purpose |
|------|------|---------|
| SaveManager | Scripts/savemanager.gd | Persistent save, all data keys |
| AudioManager | Scripts/audiomanager.gd | SFX and music |
| TooltipData | Scripts/tooltipdata.gd | Tooltip descriptions for all 20 stats |
| SkillManager | Scripts/skillmanager.gd | Skill tree state, tokens, shards, effect queries |
| MechanicsManager | Scripts/mechanicsmanager.gd | Skill-driven mechanics (Focus, Fortify, Ironclad, Vampiric, Zap, Rampart, Knockback, Chill, Overheal, Surge, Momentum, Chain) |
| EnemyMechanics | Scripts/enemymechanics.gd | Shared enemy behavior (movement, separation, attack ticking, health bar drawing, bleed) |

### Where Things Live
**New skill mechanic goes in:** `mechanicsmanager.gd` only. Never implement skill logic in enemy files or base.gd directly.

**New enemy status effect goes in:** `enemymechanics.gd` only. Enemy files just declare state vars and delegate.

**New enemy type:** Create a thin script with unique stats, visual, scale_to_wave(), setup(). Call EnemyMechanics for everything else. Add bleed state vars. Done.

**New spawn pattern/mode:** `spawnmanager.gd` only. main.gd just calls $SpawnManager.tick(delta).

**Skill effect queries:** `skillmanager.gd` only. Gate on `is_skill_unlocked()` not `level == 0` — level 0 is valid (unlocked but no shards spent).

**Damage numbers:** All spawn via `main_node.spawn_damage_number(amount, pos, type)`. Position passed as WORLD position — spawn_damage_number converts to screen space via camera zoom. Types defined in `damage_number.gd`.

### Modular Design Rules
- Skills 0-4 (pre-keystone) work with ALL attack types — bullet, pulse, drain beam. No attack type assumptions in pre-keystone skill logic.
- Attack counter (`_attack_counter` in base.gd) is attack-type agnostic. Call `_tick_attack_counter()` at the fire point of any new attack type and Rapidfire works automatically.
- `get_damage_bonuses(base_node)` in MechanicsManager returns `[flat_bonus, pct_bonus]` — call this once in _try_shoot() and _fire_pulse() to apply all passive damage skills. Add new passive damage skills inside this function only.
- Bleed state vars are declared in each enemy file but all logic lives in EnemyMechanics. When adding new status effects follow same pattern: vars in enemy file, logic in EnemyMechanics.

### Targeting System
Unified committed damage calculation in `_get_committed_damage(target)` in base.gd. All damage sources that fire independently of bullets must be registered here to prevent stray bullets:
```gdscript
func _get_committed_damage(target: Node) -> float:
    # Bleed — full tick total
    # Zap — one tick worth if this is zap_target
    # Add new independent damage sources here
```
`_try_shoot()` and `_get_best_target()` both use this function. When adding new independent damage sources (future status effects, etc.) always update `_get_committed_damage()`.

Zap uses `current_bullet_target` to ensure it never targets the same enemy as bullets:
- `current_bullet_target` set in `_try_shoot()` when target is selected
- `zap_target` always excludes `current_bullet_target` via `_get_closest_enemy(exclude)`
- `_get_closest_enemy()` validates exclude with `is_instance_valid()` before comparing

### Keystone Implementation Pattern
- Active keystone detected via `SkillManager.get_active_keystone()`
- Barrage keystone: flag passed through projectile.setup() as `is_keystone` bool, chain in MechanicsManager
- Bulwark keystone: `_try_shoot()` redirects to `_fire_pulse()` when Bulwark keystone active
- All keystones work with pre-keystone skills automatically since they share damage calculation pipeline

---

## File Structure
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
│   ├── pulse.tscn
│   ├── damage_number.tscn
│   ├── startmenu.tscn
│   ├── workshop.tscn
│   └── skilltree.tscn
├── Scripts/
│   ├── main.gd              # Game loop, wave progression, economy, UI handlers, pause/restart
│   ├── base.gd              # Shooting, targeting, crit, shield, HP regen, attack counter, zap timer, pulse firing, hover ring
│   ├── enemy.gd             # Thin — unique stats + visual only, delegates to EnemyMechanics
│   ├── brute.gd             # Thin — unique stats + visual only, delegates to EnemyMechanics
│   ├── runner.gd            # Thin — unique stats + visual only, delegates to EnemyMechanics
│   ├── boss.gd              # Thin — unique stats + visual only, delegates to EnemyMechanics
│   ├── projectile.gd        # Bullet movement, homing, visual flags (crit/rapidfire/keystone/chain), bleed + momentum + chain
│   ├── pulse.gd             # Expanding AOE ring, hit detection, charge consumption, dissolve
│   ├── damage_number.gd     # Floating text, color types, emoji prefixes
│   ├── start_menu.gd        # Start menu, phase select, debug buttons
│   ├── workshop.gd          # LP spending, floor upgrades, tiered costs, dynamic per-level display
│   ├── skilltree.gd         # Skill tree UI — fully procedural, standalone scene
│   ├── spawnmanager.gd      # All spawn logic — enemy selection, edge positions, boss spawn
│   ├── upgrademanager.gd    # All 20 upgrade handlers, workshop floor application, calc functions
│   ├── uimanager.gd         # Button updates, tooltip, screen flash, unlock system, keystone-aware ATK SPD display
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

---

## Scene Tree (main.tscn)
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
- **NOTE: Enemy scaling will need a full pass once all skill trees are complete.** Current scaling was designed before skill tree damage existed. Expect enemies to feel too easy once skills are stacked — do not rebalance mid-implementation.

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
- Gold Multiplier: +5% per level
- Displayed gold = actual received amount (post-multiplier)

### LP Economy
- run_lp: tracks this run only (shown in UI, resets each run)
- SaveManager["legacy_points"]: cumulative total, saves incrementally (crash-safe)
- Base: 1 LP per wave completion
- Boss: `10 + ((phase-1) * 3)` LP, affected by LP Gain and LP Mult
- LP Gain: +1 LP flat added to all sources
- LP Multiplier: +5% per level
- LP Drop Chance: base 10%, logarithmic scaling, cap 60%
  - Formula: `chance += 0.008 / (1.0 + i * 0.03)` per level
- Drop formula: `int((1 + lp_gain_level) * (1.0 + legacy_mult_level * 0.05))`

### Bullet + Crit System
- Locks onto target, never switches mid-flight
- Only fires if target needs more bullets — hits_needed uses _get_committed_damage() which factors bleed + zap + momentum
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
- Targeting accounts for full bleed tick total via _get_committed_damage()
- **NOTE: Bleed is likely overtuned. Nerf pass planned after all trees are implemented and cross-tree testing is complete.**

### Shield System
- Shield absorbs incoming hits (pool depletes by hit amount)
- Formula: `hp_damage = (absorbed * (1.0 - shield_strength)) + overflow`
  - absorbed = min(shield, hit_amount)
  - overflow = hit_amount - absorbed (hits HP directly, no DR)
- Base shield strength: 50% DR
- DR cap: 80% at 100 levels (+0.3% per level)
- Shield per upgrade level: +20
- Shield regen: 10% of effective max shield per tick, base interval 5s (logarithmic curve)
- Shield Multiplier: multiplies effective max shield
- Design intent: shield is NOT just another HP bar. Equal HP and shield investment provides equivalent effective survivability due to DR. Phase 4-5 is where shield becomes necessary.

### ATK SPD Curve
- Logarithmic diminishing returns via level-to-value function
- `calc_atk_spd(level)` — sums `0.115 / (1.0 + i * 0.008)` per level
- Lv10: ~2.08/s, Lv50: ~5.22/s, Lv80: ~6.62/s, Lv100: ~7.65/s
- Both in-game handler and workshop floors use same function — values always match
- **Pulse keystone:** ATK SPD controls pulse interval not fire rate. Formula: `max(1.0, 5.0 - (pow(level, 0.6) / pow(100.0, 0.6)) * 4.0)`. Base 5.0s, rounds off ~level 50, approaches 1.0s at level 100.
- UI displays `/s` normally, `Xs interval` when Pulse keystone active. Same in workshop.

### HP Regen + Shield Regen
- Both use `calc_regen_spd(level)` from upgrademanager.gd
- Base 5.0s, reduces by `0.25 / (1.0 + i * 0.05)` per level
- Level 20: ~3.5s, Level 50: ~1.75s, Level 100: ~0.7s
- Zap fires on shield_regen_interval independently of shield regen condition

### Damage Number System
- All numbers spawn via `main_node.spawn_damage_number(amount, pos, type)`
- Position passed as WORLD position — converted to screen space via camera zoom
- Types and colors:
  - normal: white
  - crit: orange, larger font
  - shield: blue
  - hp: red
  - gold: gold + 💰 prefix
  - lp: purple + ★ prefix, larger font
  - bleed: bright red + 🩸 prefix
  - zap: bright yellow + ⚡ prefix

### Boss Scaling
- HP: `400 * pow(5.0, phase-1)` — aggressive scaling, boss is always a bullet sponge
- Damage: `22.0 * pow(2.25, phase-1) * phase_scale`
- Boss crit chance 30%, 2x crit multiplier
- Boss cannot be physically knocked back (Knockback deals damage only, no push)

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
**Note:** workshop.gd duplicates calc_atk_spd(), calc_regen_spd(), and calc_drop_chance() locally for display purposes. Keep in sync with upgrademanager.gd if values change.

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
| 3 | Beat boss 2 | + HP Mult, Shield Strength, Gold Mult, LP Mult, Crit Chance, Regen Spd |
| 4 | Reach phase 3 boss wave | Everything — all 20 stats, skill tree visible |

**Future plan:** Replace milestone unlocks with LP-gated unlocks within the workshop. Stats hidden until unlocked. Workshop shows "VELA continues to evolve..." hint. Skill tree always fully visible.

---

## Workshop
- Separate scene (workshop.tscn)
- Spend LP on permanent stat floors
- Same stat values as in-game (workshop Lv5 = in-game Lv5 starting point)
- In-game costs ALWAYS reset to base (floor level doesn't affect upgrade cost)
- Button displays: STAT NAME (Lv X) | current value | gain per level (dynamic for log stats) | cost LP
- Logarithmic stats (ATK SPD, Shield Regen, Regen SPD, LP Drop) show actual next-level gain dynamically
- Phase Tokens, Phase Shards, Lifetime Kills displayed at top

---

## Skill Tree Scene
- Standalone scene (skilltree.tscn) accessible from start menu
- Fully procedurally built UI in skilltree.gd
- Stat bar at top: 🔷 Tokens | ⚡ Shards | ☠ Kills (X / next_shard_threshold)
- Three tree cards on select view, tap to open tree
- Tree view: Keystone(5) → [3,4] → [1,2] → [0]
- Skills always fully visible — players need to see the tree to plan builds
- **UI display note:** Skills show Lv0 on unlock internally but should display as Lv1. Fix in UI polish pass — display offset only, no formula changes.
- UI rewrite planned for polish phase

---

## Phase Start Selector
- Shows on start menu after unlock_level >= 2
- ◀ PHASE X ▶ buttons cycle available phases
- max_start_phase updates when player beats a boss
- Starting at phase X sets difficulty = (phase-1) * 10
- Debug unlock gives access to phases 1-20

---

## SaveManager Keys
Core progression
unlock_level, legacy_points, best_phase, start_phase, max_start_phase
Workshop floors
floor_attack_speed, floor_damage, floor_dmg_mult, floor_crit_chance, floor_crit_dmg
floor_shield, floor_shield_regen, floor_shield_strength, floor_shield_mult, floor_evasion
floor_max_hp, floor_regen_amt, floor_regen_spd, floor_hp_mult, floor_heal_mult
floor_gold_per_kill, floor_gold_mult, floor_lp_gain, floor_legacy_mult, floor_legacy_drop
Skill tree
phase_tokens, phase_tokens_earned, phase_shards, phase_shards_earned, lifetime_kills
skill_barrage_unlocked, skill_bulwark_unlocked, skill_siphon_unlocked
skill_barrage_levels, skill_bulwark_levels, skill_siphon_levels
active_keystone  # "barrage" / "bulwark" / "siphon" / ""

---

## Skill Trees

### Overview
- 3 trees: Barrage (ATK) / Bulwark (DEF) / Siphon (Healing)
- 6 slots per tree: slots 0-4 are skills, slot 5 is keystone
- Requires unlock_level 4 (reach phase 3 boss wave)
- Two skill currencies: Phase Tokens and Phase Shards
- Gate ALL skill effects on `is_skill_unlocked()` — level 0 = unlocked, base effect active

### Slot Structure
Position 0: root — always available
Position 1: left branch — requires 0
Position 2: right branch — requires 0
Position 3: left continues — requires 1
Position 4: right continues — requires 2
Position 5: keystone — requires 3 AND 4, only one keystone allowed lifetime

### Currencies

**Phase Tokens**
- Earned: 1 per phase boss killed, phases 3-18
- Hard cap: 15 lifetime
- Unlock skills (1 per skill)
- Respec exists (LP cost TBD)

**Phase Shards**
- Earned: every X lifetime kills (base 1000 kills, +100 per shard already earned — scaling threshold)
- Infinite, no cap
- Level up unlocked skills
- Progress shown in skill tree: kills / next_threshold
- **Shard threshold escalation means early shards come fast, late shards require significant kill investment. This is intentional — early skills feel immediately rewarding, deep investment requires commitment.**

### Skill Point Economy
- 15 token cap: 6 to reach keystone, 9 remaining
- Cannot reach second keystone (needs 12 minimum)

### Keystone Rules
- Slot 5, requires slots 3 AND 4
- Changes attack type
- Once chosen, other two keystones permanently greyed out

---

## Skill Definitions

### BARRAGE — "The Artillery"
*Bullets are the weapon. Distance is the advantage. Built for single target and boss killing.*

**Slot 0 — Rapidfire** ✅ BUILT
Every 3rd attack deals bonus damage. Base +20%, +5% per shard level.
Visual: cyan-blue larger bullet on every 3rd shot.

**Slot 1 — Bleed** ✅ BUILT (left branch)
Every attack applies DoT. Tick count scales with crit chance investment (0-20%=2, 21-40%=3, 41-60%=4, 61-80%=5).
First tick fires simultaneously with hit, doubles if actual crit. Ticks every 0.5s.
Base 5 dmg/tick, +2 per shard level. Resets on new application, no stacking.
Targeting accounts for full bleed total via _get_committed_damage().
**NOTE: Likely overtuned — nerf pass after all trees complete.**

**Slot 2 — Focus** ✅ BUILT (right branch)
Consecutive hits on same target ramp damage +10% per hit. Resets on kill.
Base +10% per hit, +1% per shard level. Primary boss killing stat — stacks indefinitely.

**Slot 3 — Range** ✅ BUILT (left continues)
Increases detection radius. Base +100px, +15px per shard level.
Soft cap ~800-900px (spawn distance ~1300-1400px — reaching spawn trivializes game).
Visual: detection ring shown on base hover.

**Slot 4 — Momentum** ✅ BUILT (right continues)
Bullets deal more damage the further they travel. Base 0.05% per pixel, +0.02% per shard level.
Estimated at fire time using target distance for stray bullet prevention.
Synergizes with Range and Knockback (knocked enemies travel further before being shot).

**Slot 5 — Keystone: Chain** ✅ BUILT
Bullets chain to nearby enemies on hit. Sequential hops, visual projectile per hop.
2 jumps base, +1 per 5 shard levels. Falloff 60% base, +2% per shard (no cap).
250px hop radius. Cannot hit same enemy twice per chain.
Visual: thin cyan railgun (14x4px), 2x bullet speed. Chain hops (8x4px) same style.

---

### BULWARK — "The Fortress"
*Defense becomes offense. Shield investment feeds damage. Pulse blankets waves, charges off boss hits.*

**Slot 0 — Fortify** ✅ BUILT
Every 100 effective max shield adds flat bonus damage.
Base +2 per 100, shard scaling: `2.0 * (1.0 + level * 0.05)`.
Uses effective max shield (max_shield × shield_multiplier). Active even at 0 current shield.
Wired via get_damage_bonuses() in MechanicsManager.

**Slot 1 — Ironclad** ✅ BUILT (left branch)
Flat damage bonus on unlock + per shard, then % bonus scaled linearly by current shield %.
Flat: +5 on unlock, +5 per shard level. % bonus: current_shield / max_shield × 60% max.
Formula: `shield_pct * 0.60` applied after flat bonus in _try_shoot().
Full shield = full 60% bonus. 50% shield = 30% bonus. Rewards maintaining shield uptime.
Wired via get_damage_bonuses() in MechanicsManager.

**Slot 2 — Zap** ✅ BUILT (right branch)
Independent timer fires damage at nearest enemy (excluding current bullet target) on shield_regen_interval.
Damage: 5% of current shield, +1% per shard level.
Uses current shield (not max) — depleted shield = weaker Zap. Incentivizes shield uptime.
Zap target tracked as zap_target in base.gd, always excludes current_bullet_target to prevent stray bullets.
Visual: ⚡ bright yellow damage number.

**Slot 3 — Rampart** ✅ BUILT (left continues)
On kill, restore flat shield. Base +20 shield per kill, +20 per shard level.
Formula: `20.0 + (level * 20.0)`. Wired in all enemy _die() functions.
Synergizes with Ironclad — keeps shield % high after kills maintaining damage bonus.
With Pulse AOE, each simultaneous kill triggers Rampart independently — significant shield sustain in dense waves.

**Slot 4 — Knockback** ✅ BUILT (right continues)
On enemy melee hit: push enemy back + deal chip damage. Attack timer resets to ready after knockback so enemies attack immediately on re-entry (no extra delay beyond travel time).
Force: `shield_strength × 300px` — natural cap via shield strength 80% cap (max 240px push).
Damage: `shield_strength × (50 + level × 25)`.
Boss: damage only, no push. Regular enemies: smooth tween push (0.2s).
Wired in EnemyMechanics._tick_attack() and _tick_boss_attack().

**Slot 5 — Keystone: Pulse** ✅ BUILT
Replaces bullets with expanding AOE ring. Hits each enemy once per ring pass.
Interval: `max(1.0, 5.0 - (pow(atk_spd_level, 0.6) / pow(100.0, 0.6)) * 4.0)` — 5s base, ~1s at max investment.
Ring dissolves at detection_radius edge. All pre-keystone skills apply per hit (bleed, rapidfire, focus).
Fortify and Ironclad feed damage via get_damage_bonuses() same as bullets.
**Boss charge mechanic:** incoming damage charges next Pulse.
- Normal enemies: 10% conversion base, +2.5% per shard level
- Bosses: 100% conversion base, +10% per shard level
- Charges stored in `pulse_boss_charge` in base.gd, consumed and reset on each Pulse fire
- Harder boss hits = harder next Pulse retaliation. Self-scaling boss kill mechanic.
Requires Slot 3 AND Slot 4.

---

### SIPHON — "The Drain"
*Sustain becomes offense. The longer you survive, the harder you hit.*

**Slot 0 — Vampiric** 🔲 NOT BUILT
HP Regen Amount adds flat bonus damage. Base +1 per regen point, +0.5 per shard level.
Reads from MechanicsManager.get_vampiric_bonus(hp_regen). Already defined, needs wiring in base.gd via get_damage_bonuses().

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
Folds into get_damage_bonuses() — no separate number.

**Slot 4 — Vitality** 🔲 NOT BUILT (right continues)
Killing an enemy restores flat HP. Base 2 HP per kill, +1 per shard level.
Feeds Overheal loop — kills push into overheal, overheal activates Surge.
Silent — no damage number, HP bar updates.

**Slot 5 — Keystone: Drain Beam** 🔲 NOT BUILT
Replaces bullets with continuous beam. Damages and heals simultaneously.
Ticks on ATK SPD interval. Crits = burst damage + burst heal.
Requires Slot 3 AND Slot 4.
Note: Drain Beam is instant (no travel), Momentum does not apply. Range affects detection only. Vampiric still feeds damage.

---

### Cross-Tree Synergies
- Barrage + Bulwark: Knockback → enemies travel further → Momentum bonus. Shield investment feeds Fortify.
- Barrage + Siphon: Vampiric adds flat to bullets. Vitality sustains HP.
- Bulwark + Siphon: Chill slows enemies into Pulse range. Overheal → Surge while shield holds.
- Siphon + Bulwark: Zap fires alongside drain beam ticks. Rampart builds shield from kills.

---

## Enemy Variety

### Built
- Basic: red hexagon, size 15, speed 72, standard stats
- Brute (Phase 2+): orange hexagon, size 25, speed 45, 3x HP, attack scales with difficulty, 2x gold
- Runner (Phase 3+): yellow hexagon, size 10, speed 230, 0.5x HP — explodes on contact, high contact damage
- Boss: purple octagon, spawns every 10 waves, scales aggressively per phase. Cannot be knocked back.

### Not Yet Built
- Shielder (Phase 3): shield bar before HP
- Ranged (Phase 4): stops at distance, fires projectiles

### Enemy Architecture
All enemies are thin scripts — unique stats, visual draw, scale_to_wave(), setup().
EnemyMechanics handles: movement, separation, attack ticking, health bar, bleed, knockback trigger.
Adding a new enemy: declare state vars (bleed vars required), draw visual, set separation_radius, done.

---

## Meta Progression Loop
1. Run → die → earn LP based on phase reached (saves incrementally)
2. Spend LP in workshop on permanent stat floors
3. Stats unlock milestone by milestone → future: LP-gated unlocks
4. Kill phase bosses (phase 3+) → earn Phase Tokens → unlock skill tree skills
5. Accumulate lifetime kills → earn Phase Shards (threshold escalates) → level up skills
6. Veteran players start at higher phases to farm or push leaderboard

---

## Balance Notes
- Phase 1 fresh run: 3 run arc feels correct — do not touch phase 1 scaling
- Phase 2 spike fixed with 0.85 phase_scale on enemy attack
- Shield 50% base DR is immediately noticeable even with minimal investment
- Gold mult and LP mult at 5% per level (reduced from 10%)
- LP drop chance logarithmic, base 10%
- Boss damage `pow(2.25)` — dangerous but survivable with shield
- Barrage vs Bulwark wave 1 parity (zero investment): 21.8s vs 22.5s — healthy
- **Bleed likely overtuned — nerf pass pending**
- **Enemy scaling pass needed after all skill trees complete**
- **All skill tree numbers are first-pass estimates. Expect significant rebalancing after cross-tree playtesting.**

---

## Known Issues / Tech Debt
- Skill tree UI displays Lv0 on unlock — should display Lv1. Fix in UI polish pass (display offset only, no formula changes).
- Detection range ring hover broken after refactor — fix in UI polish pass
- Skill tree procedural UI has layout limitations — node-based rewrite planned for polish phase
- Skill descriptions are placeholder text — real numbers and formatting in UI polish pass
- Game speed feels slow at 1x — consider making 1.5x the new default (flag for after all skills complete)
- Damage number toggle planned (per-type on/off) — important for late game lightshow builds
- skilltree.gd has corrupted comment block (repeated # ─ STAT BAR lines) — clean up in polish pass

---

## Remaining Build Order
1. ✅ Core loop
2. ✅ Workshop + LP system
3. ✅ Unlock/onboarding
4. ✅ Phase start selector
5. ✅ Damage number system
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
22. ✅ Balance pass (shield rework, boss damage, economy tuning)
23. ✅ Bulwark Fortify (Slot 0)
24. ✅ Bulwark Ironclad (Slot 1)
25. ✅ Bulwark Zap (Slot 2)
26. ✅ Bulwark Rampart (Slot 3)
27. ✅ Bulwark Knockback (Slot 4)
28. ✅ Bulwark Pulse Keystone (Slot 5)
29. ✅ Unified targeting system (_get_committed_damage)
30. ✅ ATK SPD curve adjustment (0.008 diminishing returns)
31. ✅ Workshop dynamic per-level gain display
32. ✅ Keystone-aware ATK SPD UI (interval display for Pulse)
33. 🔲 Siphon Vampiric (Slot 0)
34. 🔲 Siphon Chill (Slot 1)
35. 🔲 Siphon Overheal (Slot 2)
36. 🔲 Siphon Surge (Slot 3)
37. 🔲 Siphon Vitality (Slot 4)
38. 🔲 Siphon Drain Beam Keystone (Slot 5)
39. 🔲 Cross-tree balance pass (all 3 trees, bleed nerf, enemy scaling)
40. 🔲 Shielder + Ranged enemy types
41. 🔲 Damage number display toggle
42. 🔲 Skill tree UI rewrite (node-based, Lv1 display fix, real numbers in descriptions)
43. 🔲 Detection range ring hover fix
44. 🔲 Tower visual evolution (build identity)
45. 🔲 Enemy/boss visuals (humanoid robot sprites, neon EDM aesthetic)
46. 🔲 Particle effects (enemy death, skill visuals, bullet trails)
47. 🔲 UI/UX visual polish
48. 🔲 LP-gated unlock system (replace milestone unlocks)
49. 🔲 Game speed default increase (1.5x as new 1x)
50. 🔲 Leaderboard
51. 🔲 Browser export + mobile polish
52. 🔲 Skills 7-9 + capstones (post-launch)
53. 🔲 Boss variant system (post-launch)
54. 🔲 Wardrobe/cosmetic system (post-launch)
55. 🔲 Challenge + Idle + Tournament modes (post-launch)
56. 🔲 itch.io / Steam launch

---

## Design Principles
- Core stats = power, Skill trees = behavior and visual identity
- Three win conditions: Barrage (kill fast), Bulwark (outlast), Siphon (drain to survive) — but all trees must feel offensively viable
- All core stats remain valuable regardless of tree — trees shift investment priority, not destination
- Keystone changes attack type — 15 token cap means only 1 keystone possible
- Cross-tree dipping valid but only pays off with core stat investment
- Economic self-regulation — diminishing returns naturally push stat diversification
- Death is informative — each run teaches what you needed
- Build identity — 15 token cap forces meaningful commitment
- Never fully done — infinite scaling keeps veterans engaged
- Monetization: never pay to win. Premium cosmetics only.
- Speed toggle (1x/1.5x/2x) free for all players

---

## WARDROBE SYSTEM (Post-Launch)
Cosmetic layer on skill visual tier system. Investment unlocks tiers automatically.

Visual identity per tree:
- Barrage: range/velocity (glow ring → tracers → chain lightning streams)
- Bulwark: armor/presence (hardened edges → pulse ring → ground crack)
- Siphon: drain/sustain (wisps → tendrils → drain beam → overflow)

---

## STORY
VELA — an AI that found something worth protecting in a dying world. Built a tower. Sent a signal. Waits. Evolves because evolution is the only currency that buys another day.

Enemies: humanoid robots — not intelligent, not coordinated, just pulled toward whatever VELA is protecting.

---

## Skill Tree UI — Future Rewrite Note
Current skilltree.gd is fully procedural. When skills are complete, rewrite using Godot editor nodes. Each skill gets dedicated screen: current level (displayed as Lv1 on unlock), next level preview, effect curve, lore text. Skill logic stays identical — presentation layer only.
