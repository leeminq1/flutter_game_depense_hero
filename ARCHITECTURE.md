# Architecture

This project is a Flutter app that hosts a Flame-driven tower defense simulation.

## Top-Level Architecture

- Flutter owns app shell concerns: boot, navigation, settings, store, profile, and debug tools.
- Flutter also owns monetization surfaces such as rewarded prompts, ad-safe pause points, and offer presentation.
- Flame owns the real-time game loop: map, waves, towers, projectiles, enemies, targeting, collisions, and combat effects.
- Shared domain data defines towers, enemies, waves, upgrades, missions, and economy values.
- A local persistence layer owns durable player progress, settings, unlocks, and ad-related cooldown bookkeeping.
- Tooling converts source assets and design data into game-ready formats.

## Recommended Package Boundaries

When code is added, prefer this structure:

```text
lib/
├── app/
│   ├── bootstrap/
│   ├── routing/
│   ├── theme/
│   └── overlays/
├── game/
│   ├── core/
│   ├── camera/
│   ├── map/
│   ├── simulation/
│   ├── entities/
│   │   ├── towers/
│   │   ├── enemies/
│   │   ├── projectiles/
│   │   └── effects/
│   ├── waves/
│   ├── ui_bridge/
│   └── debug/
├── features/
│   ├── onboarding/
│   ├── progression/
│   ├── inventory/
│   └── settings/
├── data/
│   ├── definitions/
│   ├── repositories/
│   ├── persistence/
│   └── save/
└── tooling/
    ├── asset_pipeline/
    └── balancing/
```

## Runtime Rules

- The simulation should run from a single authoritative `FlameGame` root.
- Flutter widgets should observe state and send commands, not own combat logic.
- Prefer data-driven entity definitions over hardcoded per-enemy behavior.
- Use overlays for menus and HUD panels that do not need per-frame component logic.
- Keep hitboxes simple and deliberate. Avoid collision-heavy designs when path or lane checks are enough.
- Ads must never interrupt active combat unexpectedly. Only show them at explicit, player-safe boundaries.

## Performance Shape

- Use sprite atlases and batch-friendly rendering where possible.
- Load and cache assets intentionally at scene boundaries.
- Avoid deep component trees for cheap visual effects that can be pooled or batched.
- Separate update frequency for expensive systems when full per-frame precision is unnecessary.
- Profile on target devices early, especially spawn bursts, projectile spam, and death effects.
- Treat audio like a budgeted subsystem: preload hot SFX, pool repeated sounds, and avoid long-audio misuse for short events.

## Data Contracts To Stabilize Early

- `TowerDefinition`
- `EnemyDefinition`
- `WaveDefinition`
- `MapDefinition`
- `UpgradeDefinition`
- `SessionResult`
- `PlayerProgress`
- `StageProgress`
- `EconomyState`
- `AudioEventId`

## Architecture Risks

- Letting Flutter UI state and Flame simulation state drift apart.
- Mixing authored content with generated runtime state.
- Building highly bespoke tower logic before the data schema settles.
- Over-investing in VFX before the enemy count budget is proven.

## Persistence Recommendation

For the current plan, prefer a local-first database layer built on Isar:
- It is designed for Flutter and documents cross-platform support, async operations, and ACID semantics.
- It fits durable player progression, unlocks, inventory-like structures, and run history better than ad hoc key-value storage.
- Keep ephemeral combat state out of the database; persist only checkpoints, results, and durable progression.
