# Campaign Visual Expansion and Bombardment Design

- Status: approved for implementation
- Date: 2026-08-11
- Target: Android-first Flutter + Flame campaign, Stages 1-30

## Outcome

Extend the device-approved Stage 1 constrained top-down 3/4 pixel style to the
full 30-stage campaign without changing combat balance. Fix road seams at their
source, preserve the completed tower tier artwork, improve bombardment motion
and impact readability, and expose every Stage in the local content-review
build.

## Scope

Included:

- A topology-complete road tile family for all 16 N/E/S/W connection masks.
- Shared Stage 1-quality towers, tower tiers, barriers, and citadel across the
  campaign.
- Six five-Stage environment themes using the existing authored campaign data.
- Theme-aware ground color, road treatment, environment props, and landmarks.
- Animated bombardment flight, trail, warning, impact, and smoke presentation.
- Development-only unlocking of all 30 Stages for device content review.
- Automated route, asset, and campaign smoke checks.
- Removal of superseded assets only after a repository reference audit.

Excluded:

- Enemy health, speed, damage, composition, rewards, or Wave changes.
- Tower and barrier costs, statistics, targeting, or upgrade behavior changes.
- New campaign rules, monetization, audio, or progression requirements.
- Thirty completely independent art sets.

## Visual Architecture

Replace the Stage-number-specific visual switch with a campaign visual catalog.
The catalog resolves presentation by `StageEnvironmentTheme` while Stage data
remains the authority for paths, buildable cells, citadel placement, obstacles,
decorations, Waves, and bombardment rules.

Player-owned structures remain visually stable across the campaign:

- The seven tower families use the completed level 1, 2, and 3 constrained-B
  assets.
- The four barrier materials use their full-cell constrained-B assets.
- The player citadel uses one stable blue-heraldry identity.

Environment treatment changes in six brackets:

| Stages | Theme | Ground and road treatment | Landmark family |
| --- | --- | --- | --- |
| 1-5 | frontier road | warm green grass, tan packed earth | village and watch posts |
| 6-10 | bandit crossroads | dry olive grass, worn ochre earth | stockade and checkpoints |
| 11-15 | grave fields | desaturated moss, gray-brown earth | cemetery and mausoleum |
| 16-20 | cursed chapel | violet-charcoal ground, ashen path | ritual and chapel ruins |
| 21-25 | bastion approach | cold stone-green ground, siege road | breached fortifications |
| 26-30 | throne march | ember-brown ground, scorched road | throne monuments and infernal gate |

Existing authored decorations remain the content source. Runtime metadata
normalizes their bottom-center anchor, render size, layer, and shadow so legacy
pixel density does not control world footprint.

## Seamless Road Contract

The current road defects have two independent causes:

1. Source road sprites taper to only a few opaque pixels at tile edges, so the
   visible road width does not continue across adjacent cells.
2. Masks with three or four neighbors use the same cross-shaped `fill` image,
   creating visual exits where the route has no neighbor.

The replacement road family contains six canonical modules:

- isolated
- cap
- straight
- corner
- tee
- cross

Rotation maps these modules to all 16 masks. Each logical connection must have
the same centered opening width on the corresponding 64-pixel edge. No opening
may exist for a missing mask bit. Runtime draws every road tile at exactly one
grid-cell size; it must not use overscale as a seam workaround.

AI output supplies texture and style only. A deterministic exporter enforces
the alpha bounds, connection corridors, edge widths, rotations, nearest-neighbor
resampling, and final 64x64 RGBA canvases. Ground remains visible beneath
transparent non-road pixels.

## Campaign Map Presentation

- The full battlefield remains clipped below the complete HUD and above the
  persistent construction panel.
- Initial camera framing remains centered on the authored map/citadel baseline.
- Pinch zoom and pan never rewrite building or unit world coordinates.
- Active and next routes use the same authored cells used by enemy movement.
- Only currently relevant routes are drawn, preserving the existing Wave
  readability contract.
- Crest Stages 5, 10, 15, 20, 25, and 30 retain stronger authored landmarks.
- Build-slot overlays remain interaction-state-only and do not become permanent
  grid noise.

## Bombardment Presentation

Bombardment simulation remains unchanged. `projectileSeconds`, warning timing,
target positions, shell count, radius, and damage stay data-driven.

Rendering changes:

- Four looping in-flight frames communicate flame and smoke movement.
- The shell rotates along its trajectory while retaining a readable leading
  edge.
- A short particle-like trailing sequence replaces the single orange line.
- The target warning pulses faster near impact without hiding buildables.
- Six non-looping impact frames show flash, debris, blast, and dissipating smoke.
- The existing procedural shock ring remains as a low-cost readability layer.
- Animation frame selection is derived from visual age; it introduces no timer
  or simulation state that can change combat outcomes.

Two strip atlases are preferred over GIF decoding to keep frame selection
deterministic and mobile rendering cheap.

## Development Stage Unlock

Set `kUnlockAllCampaignStagesForDevelopment` to `true` for the requested local
content-review build. Both in-memory and local progress stores must expose all
30 Stages as unlocked. The flag remains clearly documented as release-unsafe
and must be returned to `false` before a production release.

## Asset Hygiene

- Record every generated source, final prompt, post-processing step, output
  path, and license/source statement under `docs/generated/`.
- Keep project-consumed files inside `assets/sprites/`.
- Use nearest-neighbor export for pixel-art resizing.
- Validate RGBA, transparent corners, dimensions, visible coverage, and asset
  bundle loading.
- Delete an old asset only when `rg` and asset-manifest inspection show no code,
  test, documentation, or tool reference that still needs it.

## Verification

Automated acceptance:

- Every mask from 0 through 15 resolves to the correct module and rotation.
- Every road edge has an opening if and only if the mask contains that edge.
- Adjacent route cells expose equal-width touching openings.
- Every Stage 1-30 has a valid visual theme and bundled campaign assets.
- Every active Wave route is drawable using the new road topology.
- Every generated Stage retains valid paths, build cells, and citadel cells.
- Bombardment frame lookup clamps safely before, during, and after impact.
- Development campaign overview reports all 30 Stages unlocked.
- Targeted tests, full `flutter test`, `flutter analyze`, and Android debug build
  pass.

Device acceptance:

- No green gaps, false exits, or doubled seams at straight, corner, tee, or
  cross road joints at minimum and maximum zoom.
- Building positions do not move when combat starts or camera scale changes.
- All 30 maps load and remain clipped within the battlefield.
- The six environment brackets are distinguishable while player structures
  remain consistent.
- Bombardment reads as moving and impacting rather than a static image sliding
  across the screen.
- Frame pacing remains stable on the target Android device.

