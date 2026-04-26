# Economy And Monetization

## Economy Goal

The economy must support three things at once:

- immediate combat feedback
- meaningful build tradeoffs inside a siege
- durable progression between sieges

It must also stay compatible with offline-first persistence and ad-safe timing.

## Resource Layers

### 1. In-Siege Build Currency: `Gold`

Short-term rule:

- keep the runtime and UI term `Gold` for implementation simplicity

Long-term thematic option:

- rename to `Supply` later if the fantasy shifts further toward siege logistics

Gold sources:

- starting gold
- enemy kill payouts
- recovery window payout
- clean-cycle performance bonus
- Coin Mill income

Gold uses:

- tower placement
- tower upgrades
- wall, fence, gate placement
- tactical rebuilding and barrier repair during recovery
- one free selected-hero revive during recovery after the auto-placed hero falls
- command charge activation or refill later

### 2. Permanent Soft Currency: `Meta Gold`

Meta Gold is the durable account-wide progression currency.

Uses:

- broad upgrade tracks
- roster unlock support when needed
- repeat-clear progression value

Implementation note:

- the current runtime field `softCurrency` maps directly to `Meta Gold`

### 3. Tactical Resource: `Command Charges`

This resource is part of the spec, but it is optional for the first working prototype.

Purpose:

- recover from one collapsing front
- create tactical decision points without replacing tower strategy

Candidate actions:

- emergency barricade
- frost pulse
- quick repair
- decoy beacon

Command Charge schedule:

- not required for the first prototype
- not required for `Act 1 Playable`
- required in `Milestone 6`

### 4. Permanent Milestone Currency: `Siege Tokens`

Siege Tokens are the milestone-grade durable reward for campaign progression.

They fund:

- act unlock gates
- major meta upgrades
- branch or roster milestone access

## Starting Gold Curve

The new mode needs more opening currency than the old single-lane layout because the player must answer multiple fronts earlier.

| Stage Range | Starting Gold |
| --- | --- |
| 1-5 | 300 |
| 6-10 | 330 |
| 11-15 | 360 |
| 16-20 | 390 |
| 21-25 | 420 |
| 26-30 | 450 |

## Citadel HP Curve

The citadel starts with more health than the old single-lane base because pressure arrives from more than one direction.

| Act | Citadel HP |
| --- | --- |
| 1 | 40 |
| 2 | 36 |
| 3 | 32 |
| 4 | 28 |
| 5 | 24 |
| 6 | 20 |

## Kill Reward Rule

Enemy kills should feel satisfying without manual loot pickup.

Rule:

- killing an enemy immediately awards gold
- a visible reward particle or soul mote arcs from the kill point back toward the citadel
- the player does not tap to collect it

## Recovery Payout Rule

Every completed assault cycle gives:

- flat recovery gold
- optional clean-cycle bonus
- optional citadel-health bonus
- optional fast-clear bonus

Recommended baseline bonus set:

| Condition | Bonus |
| --- | --- |
| Cycle completed | +40 to +80 gold depending on act |
| No leak during cycle | +20 gold |
| Citadel at full HP after cycle | +15 gold |
| Fast clear | +10 gold |

## Coin Mill And Supply Nodes

`Coin Mill` remains in the roster, but its battlefield role changes.

Act 1 playable rule:

- Coin Mills follow the same `1x1` placement rule as every other tower
- they are not restricted to special node tiles in the current playable

Future-facing variant:

- Coin Mills can only be built on `Supply Node` tiles

Recommended income curve:

| Act | Gold Per Tick | Tick Interval | Cycle Flavor |
| --- | --- | --- | --- |
| 1 | 4 | 4.5s | conservative economy |
| 2 | 4 | 4.2s | still early greed |
| 3 | 5 | 4.0s | economy becomes important |
| 4 | 5 | 3.8s | risk-reward sharper |
| 5 | 6 | 3.6s | high-pressure payoff |
| 6 | 6 | 3.4s | late-siege stabilization tool |

## Build-Time Cost Rule

The player can build at all times, but not at equal efficiency.

| Timing | Cost Multiplier |
| --- | --- |
| Preparation phase | 1.0x |
| Recovery window | 1.0x |
| Live assault | building disabled |

## Sell Rule

Recommended sell value:

- normal sell: `70%`
- special economy or recovery branch may increase this later
- sell during live assault may use a lower floor if balance needs it

## Persistent Reward Rule

Recommended siege token rule:

| Result | Tokens |
| --- | --- |
| Siege clear | 1 |
| Clear with HP objective | +1 |
| Clear with one mastery objective | +1 |
| Maximum per siege | 3 |

Failure reward formulas:

- `failureMetaGold = round(clearMetaGoldBase * 0.35 * cycleProgressRatio)`
- `failureXp = round(clearXpBase * 0.50 * cycleProgressRatio)`
- `cycleProgressRatio = completedCycles / totalCycles`
- once a siege has started, `cycleProgressRatio` has a minimum floor of `0.25`

Result rules:

- clear: award `Meta Gold + XP`, then award `Siege Tokens` if the clear conditions are met
- fail: award `Meta Gold + XP`, never award `Siege Tokens`

## Ad Rules

The product remains ad-safe by design.

Allowed ad surfaces:

- post-siege results
- optional retry accelerators
- optional reward claim boosts
- shop or upgrade refresh moments outside live combat

Not allowed:

- interrupting active assault cycles
- interrupting a recovery window countdown unexpectedly
- inserting ads during citadel damage or boss transitions

## Persistence Rule

Rewards must be persisted transactionally.

This especially applies to:

- Siege Tokens
- Meta Gold
- one-time first-clear grants
- ad-related bonus claims
