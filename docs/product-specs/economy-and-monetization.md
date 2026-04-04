# Economy And Monetization

## Product Goal

Support long-term progression and optional monetization without making the game feel like combat is being interrupted for ads.

## Economy Shape

- Primary soft currency from stage clears and mission rewards
- Secondary progression items for tower unlocks or upgrades
- Stage mastery rewards for replay value
- Optional rewarded ad bonuses for extra currency, revive alternatives, or timed boosts

## Ad Rules

- Rewarded ads are the preferred first monetization surface.
- Interstitial-style interruptions should not appear during active combat.
- Show ads only at natural pauses such as post-stage results, optional revive offers, or shop refresh moments.
- Ad rewards must be persisted transactionally to avoid duplicate grants.

## Retention Rules

- Every session should move at least one permanent goal forward.
- The next unlock should be visible before the player leaves the game.
- Stage progression and tower growth should create short-term and long-term goals at the same time.

## Offline-First Rule

- The game must remain fully playable and progression-capable without a server.
- Device storage is the source of truth until a future sync strategy exists.
- Anti-cheat should not over-complicate the first release; focus first on consistency and migration safety.
