# Base_Defence — Game Design Document

## Core Loop
- Single base, center of portrait screen
- Enemies spawn from edges, walk to base, melee attack
- Kill enemies → gold → mid-run upgrades
- Complete waves → phase progression
- Die → earn legacy points → spend in workshop → run again

---

## Phase & Wave Structure
- 10 waves per phase
- Wave 10 = boss
- Phases scale infinitely via difficulty variable (never resets)
- Difficulty increments +1 per wave, +3 per boss kill
- Players can unlock starting phase in workshop (costs legacy points)
- Speed multiplier toggle planned (1x/2x/3x) — build later

---

## Two Layer System

### Layer 1 — Mid-Run Upgrades (Ceiling)
What you build each run with gold. Resets on death.

### Layer 2 — Workshop (Floor)
Permanent starting stat levels bought with legacy points.
A veteran player might start at Phase 3 with attack speed Lv2 already unlocked.
Core stat floors + phase unlock + skill tree nodes.

---

## Upgrade Categories

### ⚔️ Attack
| Stat | Type | Cap | Notes |
|---|---|---|---|
| Base Damage | +1 per level | Level 10 | Small increments, multiplier handles big jumps |
| Attack Speed | +0.5/sec per level | Level 10 | Physics cap |
| Crit Chance | +5% per level | 80% | Leave variance |
| Damage Multiplier | +10% per level | None (infinite) | Gets expensive, self-regulating |
| Crit Damage | +25% per level | None (infinite) | Gets expensive, self-regulating |

### 🛡️ Defense
| Stat | Type | Cap | Notes |
|---|---|---|---|
| Max Shield | +20 per level | Level 10 | Shield sits above HP |
| Shield Regen | +1/sec per level | None (infinite) | Gets expensive |
| Damage Reduction | +2% per level | Level 10 | Hard cap ~20% |
| Knockback | Pushes enemies back | Level 10 | Behavior modifier |

### ❤️ Healing
| Stat | Type | Cap | Notes |
|---|---|---|---|
| Max Health | +20 per level | Level 10 | — |
| Health Regen | +1/sec per level | None (infinite) | Gets expensive |
| Heal Efficiency | +10% per level | None (infinite) | Gets expensive |
| Recovery Delay | -0.2s per level | Level 10 | Regen starts faster after damage |

### 💰 Utility
| Stat | Type | Cap | Notes |
|---|---|---|---|
| Gold Per Kill | +2 per level | Level 10 | Base gold income |
| Gold Multiplier | +10% per level | None (infinite) | Gets expensive |
| Legacy Per Wave | +1 per level | Level 10 | Base LP income |
| Legacy Multiplier | +10% per level | None (infinite) | Gets expensive |

---

## Cost Structure
| Stat | Start Cost | Scale | Cap |
|---|---|---|---|
| Attack Speed | 25g | x1.3 | Level 10 |
| Base Damage | 30g | x1.3 | Level 10 |
| Crit Chance | 40g | x1.3 | 80% |
| Damage Multiplier | 60g | x1.5 | None |
| Crit Damage | 60g | x1.5 | None |
| Max Health | 35g | x1.3 | Level 10 |
| Health Regen | 50g | x1.5 | None |
| Max Shield | 35g | x1.3 | Level 10 |
| Shield Regen | 50g | x1.5 | None |
| Gold Per Kill | 20g | x1.3 | Level 10 |
| Gold Multiplier | 50g | x1.5 | None |
| Legacy Per Wave | 20g | x1.3 | Level 10 |
| Legacy Multiplier | 50g | x1.5 | None |

**Design rule:** Infinite stats get expensive enough that gold is genuinely better spent elsewhere. The cap is economic, not mechanical.

---

## Economy Design
- Gold income scales with difficulty (enemies drop more as game progresses)
- Utility tree (gold multiplier etc) creates a fourth strategic axis
- Early players: dump gold into damage/speed
- Economy players: invest in gold multiplier to snowball
- Late game: infinite sinks (multipliers, regens) compete for gold

---

## Enemy Scaling
- Difficulty variable never resets — Phase 3 Wave 1 harder than Phase 1 Wave 1
- HP scales aggressively (main challenge driver)
- Speed scales mildly
- Quantity scales slowly (more enemies but strength is the focus)
- Boss scales off difficulty, not just phase

---

## Damage Progression Intent
- Wave 1-3: 1-shot enemies with base stats
- Wave 5-6: need base damage upgrades to 1-shot
- Phase 2: need damage multiplier to keep up
- Phase 3+: crit chance/crit damage become the scaling engine
- Skill trees modify behavior on top of this curve

---

## Skill Trees (Build Later)
3 trees: Attack / Defense / Healing
30 skills per tree = 90 total
Hard cap of 50 skill points per run — can never fill all trees
Skills modify BEHAVIOR not raw stats:
- Pierce, aura, knockback effects
- Introduce new mechanics
- Create build diversity
Two players at Phase 50 should look visually and mechanically different

---

## Workshop (Build Later)
- Spend legacy points between runs
- Buy starting stat levels (permanent floors)
- Unlock ability to start at higher phases
- Unlock skill tree nodes
- Visual evolution of base tied to workshop upgrades

---

## Build Order (Modular)
1. ✅ Vertical slice (done)
2. ✅ Smart targeting, damage numbers, health bars (done)
3. 🔲 Enemy HP scaling curve finalized
4. 🔲 Base damage upgrade
5. 🔲 Health + health regen upgrades
6. 🔲 Shield system + shield upgrades
7. 🔲 Utility upgrades (gold per kill, gold multiplier)
8. 🔲 Legacy points system
9. 🔲 Workshop screen
10. 🔲 Crit chance + crit damage
11. 🔲 Damage multiplier
12. 🔲 Skill trees
13. 🔲 Visual evolution
14. 🔲 Leaderboard
15. 🔲 Speed multiplier toggle
16. 🔲 Mobile polish + browser export
