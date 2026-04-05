# Campaign Structure

## Campaign Shape

- Total stages: 30
- Wave count per stage: 3 to 5
- Stage type: fixed-path tower defense
- Campaign model: permanent progression with stage unlocks and replay incentives

## Stage Progression

- Stages 1-5
  - Teach build timing, enemy lanes, and first tower counters
  - Main enemies: raiders, scouts, and a late introduction of shield infantry
- Stages 6-10
  - Hand-tuned midgame bridge that introduces armored fronts before full support pressure
  - Main enemies: bandits, shield infantry, and a delayed cult adept introduction
- Stages 11-15
  - Hand-tuned grave-march teaching band
  - Focus: revived skeleton cleanup, cult denial, and first corrupted-knight finishers
  - Main enemies: skeleton infantry, cult adepts, shield escorts, late corrupted knights
- Stages 16-20
  - Hand-tuned cursed-chapel pressure band
  - Focus: faster support overlap, corrupted-knight timing checks, and readable Grave Guard introduction
  - Main enemies: cursed knights, cult support, Grave Guards, undead elites
- Stages 21-25
  - Hand-tuned bastion-pressure band
  - Focus: warlock denial, bruiser overlap, and cleaner elite damage windows
  - Main enemies: corrupted knights, Grave Guards, Warlocks
- Stages 26-30
  - Hand-tuned throne-march band plus final boss capstone
  - Focus: low-recovery wave management, heavier summon overlap, and final boss preparation
  - Main enemies: Grave Guards, Warlocks, corrupted knights, Bastion Overlord

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
  - High starting coins so the player can learn placement before pressure spikes
- Stage 3
  - 3 waves
  - First shield infantry introduction to teach magic damage value
- Stage 5
  - 3 waves
  - Raiders, scouts, and a denser shield-frontline final push
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

## Map Presentation Rule

- Stages now carry environment bracket themes in addition to wave and path data.
- Decorative props and landmarks should support stage identity without obscuring path readability or build-slot clarity.
- Crest stages should receive stronger landmark presence than ordinary stages in the same bracket.

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

## First Five Stage Balance Rule

The first five stages are now a hand-tuned onboarding bracket instead of fully relying on the generic campaign formula.

- Stage 1-2: no support group yet, clearer pacing, extra starting coins
- Stage 3: first shield infantry lesson
- Stage 4: reinforce control and lane-hold timing
- Stage 5: first crest-stage pressure while still staying in onboarding territory

## Stage Six To Ten Balance Rule

Stages 6-10 should act as the first real difficulty bridge after onboarding.

- Stage 6-7: reinforce armored front lines and early upgrade timing
- Stage 8-9: introduce cult support without overwhelming the lane too early
- Stage 10: act as the first midgame crest with a clearer elite ending
- this bracket should punish pure physical builds more clearly, but still leave room to recover through better timing

## Stage Eleven To Twenty Balance Rule

Stages 11-20 should now act like a two-part upper-midgame arc instead of generic stat scaling.

- Stages 11-15: grave-march band
  - teach revived-wave cleanup and support denial
  - keep one real damage bend alive instead of encouraging full-map spread
  - end with a crest stage that tests economy timing under elite pressure
- Stages 16-20: cursed-chapel band
  - introduce corrupted-knight timing earlier in the wave
  - make Grave Guard pressure readable before the late campaign
  - require stronger damage overlap, not only more slows

## Current Reward Beat Rule

- Stages `6-10`, `11-15`, and `16-20` now each carry stronger base clear multipliers than the earliest band.
- Stages `21-25` and `26-30` now continue that reward step-up so late-campaign retries still feel economically valid.
- First clear, improved stars, and crest-stage clears should all feel like valid reasons to revisit or push forward.

## Stage Twenty-One To Thirty Balance Rule

Stages 21-30 should now act as the campaign completion arc instead of generic endgame scaling.

- Stages 21-25: bastion-pressure band
  - Warlocks appear early enough to define the lane
  - Grave Guards and corrupted knights overlap more often
  - the player should feel pressure to build stronger anti-support windows, not only bigger tower counts
- Stages 26-29: throne-march band
  - less recovery room between mistakes
  - stronger overlap between tanks, bruisers, and summons
  - late-wave coin discipline becomes part of the challenge
- Stage 30:
  - four pre-boss approach waves should already feel like a campaign final exam
  - the boss wave should confirm Ballista, elite damage overlap, and survival planning as the final learned skills
