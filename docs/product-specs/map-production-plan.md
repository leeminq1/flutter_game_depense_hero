# Map Production Plan

## Canonical Battlefield Spec

The first production battlefield for `Pixel Guard: Wave` uses this exact spec.

| Item | Value |
| --- | --- |
| Grid size | `14 x 14` |
| Tile size | `52 px` |
| Board size | `728 x 728 px` |
| Castle footprint | runtime `1 x 1`, visually larger landmark |
| Castle cells | campaign-authored `citadelCell` |
| Minimum zoom target | `0.55x` |
| Default overview zoom target | `0.75x` |

## Zone Model

Every stage map should read as five zones:

1. `Core Zone`
   - castle cells
   - never buildable
2. `Inner Ring`
   - premium cross-coverage build space
   - best for high-value towers
3. `Outer Ring`
   - riskier economy and front-control space
   - best for early stalling and pressure routing
4. `Spawn Fronts`
   - north, south, east, west ingress spaces
   - telegraphed and readable
5. `Fallback Pockets`
   - rebuild anchors near the inner ring

## Tile Types

The map authoring model should support these tile semantics:

```dart
enum TileType {
  path,
  buildable,
  blocked,
  supplyNode,
  castle,
}
```

## Castle Rules

The castle is both a gameplay object and a visual landmark.

Requirements:

- one shared HP pool
- one visible landmark sprite
- clear damage feedback
- strong visual presence at any zoom

Required art slot:

- `assets/sprites/environment/landmarks/central_citadel.png`

## Route Authoring Rule

The first production version must use `authored routes`.

Do not ship the first stage campaign with fully free pathfinding.

Required stage field:

- `pathsByDirection`
- `spawnRoutes`

Each direction owns three fixed spawn entries:

| Direction | Entries |
| --- | --- |
| North | `[3,0]`, `[6,0]`, `[10,0]` |
| South | `[3,13]`, `[6,13]`, `[10,13]` |
| West | `[0,3]`, `[0,6]`, `[0,10]` |
| East | `[13,3]`, `[13,6]`, `[13,10]` |

## Canonical Stage 1 Example

This is the older centered baseline `14 x 14` authored example. Current validation runtime keeps the same grid and route-entry rules, but Stage 1-5 share the fixed citadel cell `[1,12]` so players can learn fortress design before map-position variance returns later.

Legend:

- `X` = `blocked`
- `B` = `buildable`
- `$` = `supplyNode`
- `C` = `castle`
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

## Barrier And Obstacle Rule

Current v2 maps should rely on player-built barriers first.

Rules:

- authored blocking obstacles are removed from the main campaign pass
- walls, fences, and fortress walls block enemy routing
- towers never block enemy routing
- enemies only target barriers on their assigned authored route; they must not peel toward a nearest off-route barrier
- if the assigned route is blocked, enemies attack the first barrier on that route until a path opens
- each stage filters out spawn route entries that are too close to the authored
  citadel cell; `activeRouteIds` is the single source for spawn legality and
  visible road rendering
- early stages should expose only authored build cells near the citadel, route bends, and fallback pockets; do not make the whole grass field buildable
- wall placement is a fortress-design choice, not freeform map drawing
- Stage 1-5 enemies stop and attack the wall in front of them; map-route variety should come from authored lanes, not hidden enemy reroutes

Future-facing option:

- non-blocking decorative props may return once the player-built wall language is stable
- supply nodes may return later as a separate economy-layer rule

## Telegraph Rules

Before a wave begins, active fronts must be visible.

Telegraph methods:

- front-edge glow
- path tint pulse
- subtle trampled-grass, dust, and footprint marks over authored route cells
- HUD front icons
- next-wave preview panel

Path-readability rule:

- route marks are a visual readability layer only
- they must use existing `spawnRoutes` / `pathsByDirection` route data
- they must not change build legality, enemy routing, citadel position, or stage objectives
- active and next fronts may add only a low-opacity tint over those marks
- road visuals should draw only the current/next authored enemy routes as a narrow continuous lane; do not show the full stage route network or buildable-zone shading during normal play

## Camera Rules

The mode must remain legible on mobile portrait layouts.

Requirements:

- allow full-board view at minimum zoom
- allow precise tile selection at higher zoom
- keep HUD chrome out of the battlefield center

## Production Variance Rules

Stage maps should vary by:

- active route count
- player-available build space around the citadel
- fallback pocket placement
- front activation order
- decoration theme
- castle position pattern

Stage maps should not vary by:

- arbitrary path ambiguity
- unreadable decorative obstruction
- fully random route generation in the first playable

## Authored Campaign Expansion

After the first playable baseline is stable, campaign map growth should follow an `authored stage map` workflow.

Rules:

- prefer handcrafted obstacle layouts over unrestricted random generation
- vary castle placement only through approved patterns
- vary front pressure through authored wave order
- keep map identity tied to stage learning goals, not only to enemy stat scaling

Working companion docs:

- [map-authoring/README.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/README.md)
- [map-authoring/castle-and-spawn-rules.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/castle-and-spawn-rules.md)
- [map-authoring/obstacle-language.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/obstacle-language.md)
- [map-authoring/stage-1-5-map-bible.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/stage-1-5-map-bible.md)
- [map-authoring/visual-guide.md](/C:/Users/min21/Desktop/flutter_grame/depense_game/docs/design-docs/map-authoring/visual-guide.md)

Campaign authoring target:

- `30 handcrafted stage maps`
