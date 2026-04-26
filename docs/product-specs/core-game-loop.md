# Core Game Loop

## Final Direction

The project now targets `Citadel Siege`.

This is a siege-based, multi-front fortress-defense game where enemies attack a player-shaped `Citadel` defense from `north`, `south`, `east`, and `west`. The player builds walls, gates, towers, and one chosen hero around the citadel, stabilizes multiple fronts, survives a fixed number of assault cycles, and clears a siege.

This replaces the old single-lane, right-to-left stage fantasy.

## Player Fantasy

The intended emotional arc is:

- early: "I can shape the battlefield with my first wall line."
- mid: "I need a full defense network."
- late: "My fortress plan can survive a coordinated siege from every direction."

## Session Structure

One playable battle is one `Siege`.

One siege uses this flow:

1. `Preparation Phase`
   - battlefield preview
   - active-front preview for cycle 1
  - initial wall, gate, and tower planning with the chosen hero already defending beside the citadel
2. `Assault Cycle`
   - one or more fronts activate
   - enemies spawn in groups assigned to specific fronts
   - enemies may breach player-built barriers if all routes are sealed
3. `Recovery Window`
   - short controlled pause between cycles
   - cycle reward payout
   - telegraph of the next active fronts
   - normal-cost rebuilding and barrier repair
4. `Escalation`
   - more simultaneous fronts
   - more elite and support overlap
5. `Final Breach`
   - final cycle of the siege
   - may be a synchronized four-front assault or a boss-led siege
6. `Result`
   - siege clear or defeat
   - persistent reward summary
   - next action surfaced clearly

## Siege Clear And Fail Rules

Siege clear:

- all assault cycles are cleared
- all spawned enemies are resolved
- the citadel is still alive

Siege fail:

- citadel HP reaches `0`

## Battlefield Rules

### Core Layout

- the citadel position follows the campaign quadrant arc and returns near center late
- enemies always route toward the citadel
- the playable battlefield is the full green combat field between the HUD and the build bar
- player-built barriers define most blocked cells; empty grass cells remain buildable

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

This turns combat into a test of the fortress plan instead of finger-speed spam.

## Tactical Resource Rule

`Command Charges` are part of the final product direction, but they are not required for the first working prototype or the `Act 1 Playable` milestone.

Implementation timing:

- prototype and Act 1 playable: no Command Charges required
- Milestone 6: Command Charges become mandatory

Candidate commands:

- emergency barricade
- frost pulse
- quick repair
- decoy beacon

These exist to save a collapsing front, not to replace tower planning.

## Assault Cycle Counts

Baseline per act:

| Act | Cycles Per Siege | Max Simultaneous Fronts |
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

- the player may manually start the next cycle immediately once all enemies from the current cycle are resolved
- debug and QA tools may still `skip recovery` immediately

Recovery window responsibilities:

- payout cycle reward
- preview next active fronts
- allow normal-cost building and upgrading
- let the player reposition mentally before the next push

## Combat Readability Rules

The redesign must preserve these readability rules:

- active fronts are telegraphed before the cycle starts
- front identity is color-coded and spatially obvious
- enemy supports must remain readable in crowded four-front scenes
- citadel damage events must be unmistakable
- kill rewards should visibly flow back to the citadel automatically

## First-Playable Acceptance

The first playable of the new mode is only complete when all of the following are true:

- a siege can be started and completed on the new multi-front battlefield
- at least one siege uses more than two active fronts
- the player can place towers and barriers during prep and recovery
- sealed routes cause enemies to breach barriers instead of disappearing or stalling
- recovery windows show next-front telegraphs
- defeat and clear results persist correctly
- the mode remains readable on mobile-sized portrait layouts
