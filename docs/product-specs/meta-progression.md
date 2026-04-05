# Meta Progression

## Goal

Create long-term motivation without making early defeats feel paywalled or opaque.

The game should favor permanent growth over roguelike reset structure.

## Early Meta Systems

- Unlock new towers
- Improve tower branches
- Open new maps or biomes
- Add passive account-level upgrades cautiously
- Track stage stars or mastery for replay incentives
- Offer optional rewarded boosts that accelerate, not replace, progression
- Unlock additional buildable units and support structures across the campaign

## Current Prototype Upgrade Tree

- Stronghold Masonry: more base health every stage
- Supply Cache: more starting build gold
- Bow Mastery: stronger archer damage spikes and unlocks Ballista at level 2
- Guard Drill: stronger barracks damage and stagger
- Arcane Mastery: stronger mage burst and chains, and unlocks Emberkeep at level 2
- Frost Focus: stronger frost slow and range
- Commerce Guild: more coin mill income and better stage rewards

## Current Curve Notes

- Upgrade costs now use per-tree curves instead of one shared slope.
- Early levels are intentionally cheaper so the first meaningful purchase still lands within the first few clears.
- Unlock-oriented trees keep their level 2 breakpoint readable and reachable.
- Commerce Guild is no longer the most punishing early economy investment.

## Reward Beats

- Every clear still grants XP and Meta Gold.
- First clears now grant an explicit bonus.
- Improving a stage to a higher star result now grants an extra catch-up payout.
- Crest stages `5/10/15/20/25/30` grant an extra first-clear milestone bonus.
- Result UX should always show the reward breakdown so players understand why replaying a stage can still matter.

## UX Requirements

- The home screen should surface the next campaign gate and the most likely next upgrade target.
- Upgrade UI should show `current effect`, `next effect`, and upcoming milestone text when relevant.
- Account progress should feel tied to real goals, not only bigger numbers.

## Current Unlock Interaction

- Some campaign stages now require total stars.
- Some campaign stages now require specific meta upgrade levels.
- Some buildable structures now unlock from specific meta upgrade levels.
- Meta upgrades are therefore part of campaign pacing, not only combat efficiency.

## Rules

- Core skill expression should remain relevant.
- Permanent progression should widen options before it increases raw power too much.
- Reward cadence should reinforce short-session replayability.
- Returning the next day should feel valuable even without a live server.
- Offline progress storage must survive app restarts and upgrades safely.
