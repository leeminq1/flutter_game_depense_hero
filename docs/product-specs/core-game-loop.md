# Core Game Loop

## Final Direction

The project now targets `Citadel Siege`.

This is a stage-based, multi-front fortress-defense game where enemies attack a player-shaped `Citadel` defense from `north`, `south`, `east`, and `west`. The player builds walls, gates, towers, and one chosen hero around the citadel, stabilizes multiple fronts, survives a fixed number of waves, and clears a stage.

This replaces the old single-lane, right-to-left stage fantasy.

## Player Fantasy

The intended emotional arc is:

- early: "I can shape the battlefield with my first wall line."
- mid: "I need a full defense network."
- late: "My fortress plan can survive a coordinated siege from every direction."

## Session Structure

One playable battle is one `Stage`.

Player-facing terms:

- `Stage`: one combat map, shown as `STAGE 1`
- `Wave`: one enemy assault inside a Stage, shown as `WAVE 1/3`
- `Act`: an internal campaign chapter of five Stages; do not emphasize it in the battle UI

One stage uses this flow:

1. `Preparation Phase`
   - battlefield preview
   - active-front preview for Wave 1
   - Stage 1-3: no random dice offer; show a fixed learning operation
   - Stage 4 and every three stages after that: one design-card dice offer roll
   - initial wall, gate, and tower planning with the chosen hero already defending beside the citadel
2. `Wave`
   - one or more fronts activate
   - enemies spawn in groups assigned to specific fronts
- enemies may breach player-built barriers if all routes are sealed
- from Stage 2 onward, a seeded artillery roll may trigger once on Wave 3
  or Wave 4 and fire three spaced shells at player defenses near the citadel
- the chosen hero automatically guards near its assigned defense position and engages enemies within `3.2` tiles
- normal enemies damage the citadel by `1` when they leak; boss-class enemies
  damage the citadel by `2`
3. `Recovery Window`
   - short controlled pause between waves
   - wave reward payout
   - telegraph of the next active fronts
   - normal-cost rebuilding and barrier repair
4. `Escalation`
   - more simultaneous fronts
   - more elite and support overlap
5. `Final Breach`
   - final wave of the stage
   - may be a synchronized four-front assault or a boss-led siege
6. `Result`
   - siege clear or defeat
   - persistent reward summary
   - next action surfaced clearly

## Stage Clear And Fail Rules

Stage clear:

- all waves are cleared
- all spawned enemies are resolved
- the citadel is still alive

Stage fail:

- citadel HP reaches `0`

## Battlefield Rules

### Core Layout

- the citadel position follows the campaign quadrant arc and returns near center late
- enemies always route toward the citadel
- enemies attack barriers when blocked
- towers do not block movement; enemies may apply unit-specific pass-through
  contact damage to nearby towers without stopping or turning away from their
  route or barrier target
- the playable battlefield is the full green combat field between the HUD and the build bar
- player-built barriers define most blocked cells; empty grass cells remain buildable
- visible route marks are muted brown only on actual authored front route cells; non-route grass should stay green so the player can read where enemies really enter

### Route Rule

The current production version uses `front-authored entry points` plus `barrier-aware grid routing`, not a painted fixed road.

Allowed in the first playable:

- 2-front, 3-front, and 4-front edge spawns
- three fixed route entries per direction
- player-built walls, fences, and gates that can redirect or block enemies
- full route sealing; sealed enemies attack the nearest barrier until a route opens
- special enemies that temporarily break the normal rule only in controlled cases

Not allowed in the first playable:

- invisible blocked overlays or fake road tiles that do not match visible scenery
- enemies choosing arbitrary tiles as attack vectors without telegraph

### Build Rule

- all towers, including `Coin Mill`, occupy `1x1`
- towers, walls, fences, and gates occupy `1x1`
- any non-citadel, non-occupied battlefield cell may accept a tower or barrier
- towers do not block enemy movement; barriers do

## Real-Time Build Rule

The player builds during preparation and recovery, not during active assault.

Cost rule:

- preparation and recovery build cost: `100%`
- live assault building: disabled for towers and barriers
- live assault demolition: barrier demolition is allowed as an emergency route
  release; tower selling remains a prep/recovery economy action

This turns combat into a test of the fortress plan instead of finger-speed spam.

## Tactical Resource Rule

`Command Charges` are part of the future product direction, but they are held out of the Stage 1-5 fun validation pass.

Implementation timing:

- Stage 1-5 validation: no Command Charges
- Stage 6+ candidate: test `quick repair` first before adding broader tactical buttons

Candidate commands:

- emergency barricade
- frost pulse
- quick repair
- decoy beacon

These exist to save a collapsing front, not to replace tower planning.

## Run Offer Rule

Stage 4 and every three stages after that present one light roguelike design-card choice before Wave 1. Stage 1-3 use fixed learning operations instead.

Rules:

- the player first taps `Roll` to reveal the offer set
- the player must choose exactly `1 of 3` offers before starting Wave 1
- offers last only for the current stage run in the MVP
- design-card choice cadence is `Stage 4, 7, 10...` so the player is not asked to pick a card every stage
- retrying a stage creates a fresh offer seed and new offer sequence
- the first validation pool is limited to six design cards: archer wall line, hero guard anchor, mage crossroad, wall HP network, barracks gate hold, and frost chokepoint
- offers may modify tower range, tower damage, tower cooldown, barrier HP, first-build tower level, or chosen-hero damage
- offers must be positive, numeric effects with a short visible `effectLine`
- offers must also expose an `operationLine` such as `성벽 뒤 궁수 라인`
- tradeoff effects such as losing hero revive or increasing repair cost are out of scope for the first playable
- offers must not randomize enemy paths, citadel position, stage objectives, or front activation order

Design purpose:

- create replayable build variation without replacing the tower / wall / hero build tabs
- keep debugging feasible by recording a run seed in session state
- keep the run seed internal; player-facing banners show the selected operation and numeric effect only
- make the system feel like a deliberate dice roll that changes fortress planning, not a generic stat buff lottery

## Stage Pressure Events

Stage pressure events are separate from player design-card offers.

- Stage 4, 7, 10... may also roll one final-wave boss or elite event from
  `StageEventDefinition`
- the boss event triggers once when final-wave spawns are complete and the
  remaining enemy count is `2` or lower
- from Stage 2 onward, `StageBombardmentDefinition` can roll a single artillery
  event for the stage
- artillery only targets Wave 3 or Wave 4, rolls once for the whole stage, and
  damages nearby walls or towers instead of changing enemy paths
- an artillery event fires exactly three shells; targets prefer the closest
  non-overlapping player structures around the citadel, then fall back to
  nearby empty impact points when fewer valid structures exist
- the artillery projectile uses `assets/sprites/effects/cannonball_projectile.png`
  so the visual can later be swapped without changing combat rules
- ninja hero attacks use `assets/sprites/effects/shuriken_projectile.png`; boss
  structure hits use `assets/sprites/effects/boss_shockwave_impact.png`

## Stage 1-5 Fun Validation

Stage 1-5 exist to prove that fortress design is fun before adding more randomness.

| Stage | Player-facing lesson | Randomness |
| --- | --- | --- |
| 1 | 성벽으로 늦추기 | none |
| 2 | 타워 사거리 겹치기 | none |
| 3 | 영웅 방어 위치 | none |
| 4 | 첫 설계 카드 | design-card dice |
| 5 | 초반 종합 시험 | none; continue fortress validation |

Rules:

- Stage 1-5 share a fixed lower-left corner citadel position at `[1,12]` and authored route language
- Stage 1 uses the north front only so wall slowdown is readable
- Stage 2-5 introduce the east front, but avoid west/south same-quadrant spawns near the citadel
- buildable ground is a rectangular authored area near the citadel, rendered with a distinct terrain tile
- Stage 1-5 use the early role set: Raider, Scout, Wolf Scout, Shield Infantry, Skeleton, Bone Archer, Cult Adept, and Grave Guard
- Stage 4+ may choose a seeded Wave variant, but the next Wave threat tags are shown before combat
- failure hints are stage-specific templates, not complex automatic analysis yet

## Monster / Wall / Tower Rules

- Citadel HP is fixed at `3`; each normal leak deals `1` damage, so three leaks defeat the Stage.
- Fast enemies hit the wall ahead with low structure damage.
- Medium enemies hit the wall ahead with medium structure damage.
- Heavy enemies hit the wall ahead with high structure damage and are the clearest wall-breaker role.
- Towers never block movement. Enemies can pass through tower cells and deal contact damage while moving.
- Tower damage is intentionally lower than the earlier prototype so walls create the time needed for kill zones.

## Hero Guard Rule

The selected hero is a semi-autonomous defender, not a fully manual action character.

- auto placement creates the initial defense position beside the citadel
- choosing `방어 위치` sets a new defense position and moves the hero there
- during an active Wave, the hero only chases and attacks enemies inside `3.2` tiles of that defense position
- during an active Wave, the player cannot change the hero defense position
- enemies treat a living hero standing ahead of them on the citadel approach as a blocker target and attack the hero before continuing, even though the hero does not alter pathfinding like a wall
- when no valid target remains, the hero returns to the defense position
- hero auras should be local to the hero's defense area, not global stage passives
- current MVP attack readability uses procedural lunge, slash, projectile trail, and hit effects on top of the existing walk sprites

## Wave Counts

Baseline per act:

| Act | Waves Per Stage | Max Simultaneous Fronts |
| --- | --- | --- |
| 1 | 3-4 | 2 |
| 2 | 4 | 3 |
| 3 | 4 | 3 |
| 4 | 4 | 4 |
| 5 | 5 | 4 |
| 6 | 5 | 4 + boss |

## Recovery Window Rules

Default recovery window length:

- `30 seconds`

Player-facing early-start rule:

- the player may manually start the next wave immediately once all enemies from the current wave are resolved
- debug and QA tools may still `skip recovery` immediately

Recovery window responsibilities:

- payout wave reward
- preview next active fronts
- allow normal-cost building and upgrading
- let the player reposition mentally before the next push

## Combat Readability Rules

The redesign must preserve these readability rules:

- active fronts are telegraphed before the wave starts
- front identity is color-coded and spatially obvious
- enemy supports must remain readable in crowded four-front scenes
- citadel damage events must be unmistakable
- citadel leaks resolve at the visible front-facing gate cell, not at a hidden sprite center
- the active or next gate threshold remains subtly visible during preparation, combat, and recovery
- kill rewards should visibly flow back to the citadel automatically
- enemy hits and deaths should use lightweight flashes, impact rings, and reward text before adding heavier animation assets

## First-Playable Acceptance

The first playable of the new mode is only complete when all of the following are true:

- a siege can be started and completed on the new multi-front battlefield
- at least one siege uses more than two active fronts
- the player can place towers and barriers during prep and recovery
- sealed routes cause enemies to breach barriers instead of disappearing or stalling
- recovery windows show next-front telegraphs
- defeat and clear results persist correctly
- the mode remains readable on mobile-sized portrait layouts
