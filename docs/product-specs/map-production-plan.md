# Map Production Plan

## Canonical Battlefield Spec

The first production battlefield for `Citadel Siege` uses this exact spec.

| Item | Value |
| --- | --- |
| Grid size | `14 x 14` |
| Tile size | `52 px` |
| Board size | `728 x 728 px` |
| Citadel footprint | central `3 x 3` block |
| Citadel cells | `col 5-7`, `row 5-7` |
| Minimum zoom target | `0.55x` |
| Default overview zoom target | `0.75x` |

## Zone Model

Every siege map should read as five zones:

1. `Core Zone`
   - citadel cells
   - never buildable
2. `Inner Ring`
   - premium cross-coverage build space
   - best for high-value towers
3. `Outer Ring`
   - riskier economy and front-control space
   - best for early stalling and supply-node tension
4. `Breach Fronts`
   - north, south, east, west ingress spaces
   - telegraphed and color-coded
5. `Fallback Pockets`
   - late-run rebuild anchors near the inner ring

## Tile Types

The map authoring model should support these tile semantics:

```dart
enum TileType {
  path,
  buildable,
  blocked,
  supplyNode,
  citadel,
}
```

## Citadel Rules

The citadel is both a gameplay object and a visual landmark.

Requirements:

- one center HP pool
- one visible landmark sprite
- clear damage feedback
- strong visual presence at any zoom

Required art slot:

- `assets/sprites/environment/landmarks/central_citadel.png`

## Route Authoring Rule

The first production version must use `authored routes`.

Do not ship the first multi-front mode with fully free pathfinding.

Required stage field:

- `pathsByDirection`

## Canonical Siege 1 Example

This is the baseline `14 x 14` authored example used for implementation.

Legend:

- `X` = `blocked`
- `B` = `buildable`
- `$` = `supplyNode`
- `C` = `citadel`
- `N`,`S`,`E`,`W` = path cells belonging to the north, south, east, and west fronts

```text
row00: X X X X X X N X X X X X X X
row01: X X X B B B N B B B B X X X
row02: X X B B B B N B B B B B X X
row03: X X B $ B B N B B B $ B X X
row04: X X B B B B N B B B B B X X
row05: X X B B B C C C B B B B X X
row06: W W W W W C C C E E E E E E
row07: X X B B B C C C B B B B X X
row08: X X B B B B S B B B B B X X
row09: X X B B B B S B B B B B X X
row10: X X B $ B B S B B B $ B X X
row11: X X B B B B S B B B B B X X
row12: X X X B B B S B B B B X X X
row13: X X X X X X S X X X X X X X
```

Exact authored fields:

```dart
final supplyNodeCells = const [
  [3, 3],
  [10, 3],
  [3, 10],
  [10, 10],
];

final pathsByDirection = const {
  SpawnDirection.north: [[6, 0], [6, 1], [6, 2], [6, 3], [6, 4]],
  SpawnDirection.south: [[6, 8], [6, 9], [6, 10], [6, 11], [6, 12], [6, 13]],
  SpawnDirection.east: [[8, 6], [9, 6], [10, 6], [11, 6], [12, 6], [13, 6]],
  SpawnDirection.west: [[0, 6], [1, 6], [2, 6], [3, 6], [4, 6]],
};
```

Fallback pockets:

- west fallback pocket: cells around `[2, 5]` and `[2, 7]`
- east fallback pocket: cells around `[11, 5]` and `[11, 7]`

## Obstacle Rule

Act 1 playable sieges should rely on visible environment obstacles first.

Rules:

- only cells occupied by visible obstacle sprites are blocked
- obstacle density should be highest in early stages and decrease across the act
- enemies must detour around those obstacles
- players must never be able to build on those obstacle cells

Future-facing option:

- supply nodes may return later as a separate economy-layer rule once the obstacle-driven battlefield is stable

## Telegraph Rules

Before a cycle begins, active fronts must be visible.

Telegraph methods:

- front-edge glow
- path tint pulse
- HUD front icons
- recovery-window next-cycle panel

## Camera Rules

The mode must remain legible on mobile portrait layouts.

Requirements:

- allow full-board view at minimum zoom
- allow precise tile selection at higher zoom
- keep HUD chrome out of the battlefield center

## Production Variance Rules

Sieges should vary by:

- route bends
- obstacle layout and density
- fallback pocket placement
- front activation order
- decoration theme

Sieges should not vary by:

- arbitrary path ambiguity
- unreadable decorative obstruction
- random route generation in the first playable

## Authored Campaign Expansion

After the first playable baseline is stable, campaign map growth should follow an `authored map` workflow.

Rules:

- prefer handcrafted obstacle layouts over unrestricted random generation
- vary citadel placement only through approved patterns
- vary front pressure through authored cycle order
- keep map identity tied to stage learning goals, not only to enemy stat scaling

Working companion docs:

- [map-authoring/README.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/README.md)
- [map-authoring/castle-and-spawn-rules.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/castle-and-spawn-rules.md)
- [map-authoring/obstacle-language.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/obstacle-language.md)

Campaign authoring target:

- `6 acts x 5 handcrafted siege maps`
