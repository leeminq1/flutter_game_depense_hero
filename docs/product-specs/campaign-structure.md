# Campaign Structure

## Campaign Shape

- Total stages: 30
- Wave count per stage: 3 to 5
- Stage type: fixed-path tower defense
- Campaign model: permanent progression with stage unlocks and replay incentives

## Stage Progression

- Stages 1-5
  - Teach build timing, enemy lanes, and first tower counters
  - Main enemies: bandit raiders and scouts
- Stages 6-10
  - Introduce armored units and support enemies
  - Main enemies: bandits, shield infantry, cult adepts
- Stages 11-15
  - Add undead pressure, tankier waves, and mixed compositions
  - Main enemies: skeleton infantry, grave guards, necromancers
- Stages 16-20
  - Increase simultaneous threat types and route pressure
  - Main enemies: cursed knights, ranged cultists, undead elites
- Stages 21-25
  - Demand stronger tower synergy and upgrade timing
  - Main enemies: elite armored factions, corrupted support units
- Stages 26-30
  - Late-campaign challenge and boss-style stage capstones
  - Main enemies: champion knights, warlocks, elite undead commanders

## Unlock Structure

- Every stage after Stage 1 requires at least 1 star from the previous stage.
- Stage 6 adds a total-star gate.
- Stage 11 adds a meta-upgrade gate.
- Stage 16 adds a stronger total-star gate.
- Stage 21 adds a stronger meta-upgrade gate.
- Stage 26 adds a late-campaign total-star gate.

These gates now exist in the prototype so campaign progression is not only linear by index.

## Wave Scaling Rules

Every stage should tune the following per wave:
- enemy count
- enemy mix
- base HP
- movement pressure
- armor or resistance traits
- reward payout

Recommended scaling direction:
- Wave 1: familiar or readable opener
- Wave 2: add mixed roles
- Wave 3: stress core counterplay
- Wave 4: spike or elite composition when present
- Wave 5: boss-style or climax wave when present

## Baseline Scaling Model

Use this as the starting balancing model before playtest tuning:

- Stage HP multiplier
  - `1.0 + ((stage - 1) * 0.11)`
- Stage reward multiplier
  - `1.0 + ((stage - 1) * 0.08)`
- Stage count multiplier
  - `1.0 + ((stage - 1) * 0.06)`
- Per-wave intensity modifier
  - Wave 1: `1.00`
  - Wave 2: `1.15`
  - Wave 3: `1.35`
  - Wave 4: `1.60`
  - Wave 5: `1.95`

Use those multipliers to derive:
- total spawn count
- average enemy HP
- elite unit chance
- support unit chance

## Example Early Stage Rhythm

- Stage 1
  - 3 waves
  - Mostly raiders and scouts
- Stage 5
  - 4 waves
  - Raiders, scouts, first shield infantry
- Stage 10
  - 4 waves
  - Mixed bandits and cult support
- Stage 15
  - 5 waves
  - Undead tanks and support casters
- Stage 20
  - 5 waves
  - Elite cursed knights and pressure comps
- Stage 25
  - 5 waves
  - High-density mixed counters
- Stage 30
  - 5 waves
  - Final campaign capstone with a dedicated boss wave

## Placement Rules

- Players may place towers and support structures during active waves.
- Real-time placement should carry a clear cost and small commitment delay if needed for balance.
- The game should stay readable while the player is placing during combat.
- Placement UI must remain fast and low-friction on mobile.

## Buildable Content Categories

- Damage towers
- Utility towers
- Slow / control towers
- Economy or support structures
- Stage-specific unlockables later in the campaign

## Boss And Elite Rule

- Every 5th stage should feel like a difficulty crest.
- Stages 10, 20, and 30 should introduce elite or boss-like wave endings.
- Final stage should test placement, upgrade timing, and sustained wave management together.
- Stage 30 now ends with the Bastion Overlord, which phases, self-wards, and summons escorts during the fight.

## Prototype Objective Rule

Each stage now carries three star objectives built from:
- clear the stage
- preserve a minimum amount of base health
- one tactical constraint such as low tower count, no selling, or using a specific tower type

## Difficulty Philosophy

- Difficulty should rise through composition and map design before raw stat inflation alone.
- New enemy roles should force counterplay changes, not just bigger numbers.
- Each 5-stage bracket should feel like a mini arc with a different faction emphasis.
