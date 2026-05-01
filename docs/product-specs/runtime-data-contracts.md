# Runtime Data Contracts

## Purpose

This document is the bridge between product intent and implementation. It defines the smallest concrete model changes required to build the new mode without overgeneralizing too early.

## Implementation Principle

Do not jump directly to a fully abstract `FrontDefinition` engine.

First bridge:

- keep the current codebase understandable
- add the minimum new contracts needed for multi-front Stages

## Required Enums

```dart
enum SpawnDirection { north, south, east, west }

enum TileType {
  path,
  buildable,
  blocked,
  supplyNode,
  citadel,
}
```

## Required Stage/Wave Contracts

```dart
class AssaultCycleDefinition {
  final int number;
  final List<SpawnDirection> activeFronts;
  final List<FrontSpawnGroupDefinition> groups;
  final double recoverySeconds;
  final int recoveryGoldBonus;
  final bool isFinalBreach;
}

class FrontSpawnGroupDefinition {
  final SpawnDirection front;
  final EnemyDefinition enemy;
  final int count;
  final double spawnInterval;
}
```

## Siege Definition Bridge

Recommended first-pass shape keeps the player-facing `StageDefinition` name:

```dart
class StageDefinition {
  final int number;
  final int actNumber;
  final String title;
  final String description;
  final int startingGold;
  final int citadelHp;
  final List<List<TileType>> tileGrid;
  final Map<SpawnDirection, List<List<int>>> pathsByDirection;
  final List<List<int>> supplyNodeCells;
  final List<AssaultCycleDefinition> assaultCycles;
  final List<StageObjectiveDefinition> objectives;
}
```

Current implementation note:

- `stage_definition.dart` remains the canonical runtime model
- `SiegeDefinition` may remain only as a compatibility alias while docs/UI use Stage/Wave

## Runtime Scaling Formulas

These formulas are required rules, not optional tuning ideas.

```dart
final hpMultiplier = 1 + ((stageNumber - 1) * 0.11);
final moveSpeedMultiplier = 1 + ((actNumber - 1) * 0.04);
final killRewardMultiplier = 1 + ((stageNumber - 1) * 0.05);
```

Rules:

- HP scales by stage number
- move speed scales by act number only
- kill rewards scale by stage number
- `citadelDamage` does not scale in MVP
- authored Stage data stores base enemy composition and the runtime applies the derived multipliers

## Runtime Movement Rule

Current state:

- all enemies advance on one `_pathPoints` list

Required new state:

- `_pathsByDirection: Map<SpawnDirection, List<Vector2>>`
- `_citadelCenter: Vector2`

Each enemy must store:

- `spawnDirection`
- `currentDirection`

## Targeting Rule

Existing target logic based on one linear path progress is no longer sufficient.

MVP targeting rule:

- prefer enemies with the smallest `distanceToCitadel`
- break ties with support priority or elite priority where needed

This applies to:

- normal tower targeting
- Ballista targeting
- cluster targeting
- support-priority targeting

## Rendering Rule

`GameVisualRegistry` must support direction-aware sprite selection.

Required signature target:

```dart
Image enemySprite(EnemyKind kind, int frame, SpawnDirection direction)
```

MVP behavior:

- `west`: current sprite package or nested `west` package
- `east`: mirrored draw from `west`
- `north`: true up package if available, else temporary rotation fallback
- `south`: true down package if available, else temporary rotation fallback

## File-By-File Expectations

### `lib/game/models/stage_definition.dart`

Required changes:

- add `SpawnDirection`
- expand `TileType`
- add `AssaultCycleDefinition`
- add `pathsByDirection`
- add `supplyNodeCells`
- expose `SiegeDefinition` naming aliases during migration

### `lib/data/campaign/campaign_data.dart`

Required changes:

- convert authored stage data to the new siege layout
- provide `14 x 14` tile grids
- provide `pathsByDirection`
- author `assaultCycles`
- validate every direction route before runtime load

### `lib/game/core/depense_game.dart`

Required changes:

- maintain `_pathsByDirection`
- compute `_citadelCenter`
- spawn by front
- update enemies by assigned route
- switch targeting to `distanceToCitadel`
- add recovery-window state handling
- render citadel, nodes, and front telegraphs

### `lib/game/rendering/game_visual_registry.dart`

Required changes:

- expose direction-aware enemy sprite lookup
- preserve legacy fallback during migration
- prefer the nested enemy-folder structure when available

### `lib/app/screens/game_screen.dart`

Required changes:

- expose new HUD fields
- support recovery-state UI
- keep gameplay viewport clear of overlapping chrome
- support QA overlay fields for web verification

## Map Rendering Rule

The renderer must support:

- citadel landmark draw
- multi-front path draw
- supply node visuals
- front telegraph overlays

## UI Bridge Rule

Flutter overlays must surface at least:

- citadel HP
- gold
- current cycle
- next active fronts
- selected buildable
- recovery timer

## Explicit Non-Goals For MVP

Do not build these in the first bridge:

- fully dynamic front graph editor
- global A* mazing system for every enemy
- complete endless mode
- fully independent summoned-unit simulation rewrite
