# LPC Generated Enemy Sprites

These enemy sprites are generated from the Universal LPC generator through a Playwright-driven Node export script and then refined with the local silhouette polish pass when needed.

| Enemy | File | Notes |
| --- | --- | --- |
| raider | assets/sprites/enemies/raider.png | idle preview best frame 1 |
| scout | assets/sprites/enemies/scout.png | targeted refinement rerender on frame 1 with teen body silhouette plus local polish |
| shield_infantry | assets/sprites/enemies/shield_infantry.png | targeted refinement rerender on frame 1 with stronger shield-first silhouette plus local polish |
| cult_adept | assets/sprites/enemies/cult_adept.png | targeted third-pass rerender on frame 1 plus local polish |
| skeleton | assets/sprites/enemies/skeleton.png | idle preview best frame 0 |
| grave_guard | assets/sprites/enemies/grave_guard.png | targeted third-pass rerender on frame 1 plus local polish |
| corrupted_knight | assets/sprites/enemies/corrupted_knight.png | idle preview best frame 0 |
| warlock | assets/sprites/enemies/warlock.png | targeted third-pass rerender on frame 1 plus local polish |
| bastion_overlord | assets/sprites/enemies/bastion_overlord.png | full rerender restored through Node exporter |

## Tooling Status

- The earlier Windows `command line is too long` blocker is resolved.
- LPC batch export now runs through `tools/lpc-export/lpc_batch_export.mjs`.
- Playwright is isolated in `tools/lpc-export/package.json` so Flutter project dependencies stay untouched.
- `tools/generate_lpc_enemy_sprites.ps1` now supports targeted reruns through `-Ids`.
- Single-id targeted reruns now serialize correctly as JSON arrays, so one-enemy A/B tests no longer break the Node exporter.

## Targeted Rerender Flow

Current preferred iteration path for a few enemies:

- `powershell -ExecutionPolicy Bypass -File .\tools\generate_lpc_enemy_sprites.ps1 -Ids cult_adept,grave_guard,warlock`
- `powershell -ExecutionPolicy Bypass -File .\tools\generate_lpc_enemy_sprites.ps1 -Ids scout,shield_infantry`
- `python .\tools\polish_enemy_sprites.py`

Attribution is still required for LPC-derived assets.
Source generator: https://liberatedpixelcup.github.io/Universal-LPC-Spritesheet-Character-Generator/
Regenerate with: `powershell -ExecutionPolicy Bypass -File .\tools\generate_lpc_enemy_sprites.ps1`
