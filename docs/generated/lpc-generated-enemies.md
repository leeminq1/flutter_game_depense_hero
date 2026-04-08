# LPC Generated Enemy Sprites

These enemy sprites were generated from the Universal LPC generator through a Playwright-driven Node export script.
High-level role prompts live in `assets/sprites/enemies/AI_GENERATION_PROMPTS.md`, and exact LPC selections live in `tools/generate_lpc_enemy_sprites.ps1`.

| Enemy | Files | Notes |
| --- | --- | --- |
| raider | assets/sprites/enemies/raider.png plus walk companions | ZIP frame mapping: base <= standard/walk/down/5.png, walk_02 <= standard/walk/down/3.png, walk_03 <= standard/walk/down/7.png |
| scout | assets/sprites/enemies/scout.png plus walk companions | ZIP frame mapping: base <= standard/walk/down/5.png, walk_02 <= standard/walk/down/3.png, walk_03 <= standard/walk/down/7.png |
| banner_captain | assets/sprites/enemies/banner_captain.png plus walk companions | ZIP frame mapping: base <= standard/walk/down/5.png, walk_02 <= standard/walk/down/3.png, walk_03 <= standard/walk/down/7.png |
| wolf_scout | assets/sprites/enemies/wolf_scout.png plus walk companions | ZIP frame mapping: base <= standard/walk/down/5.png, walk_02 <= standard/walk/down/3.png, walk_03 <= standard/walk/down/7.png |
| shield_infantry | assets/sprites/enemies/shield_infantry.png plus walk companions | ZIP frame mapping: base <= standard/walk/down/5.png, walk_02 <= standard/walk/down/3.png, walk_03 <= standard/walk/down/7.png |
| cult_adept | assets/sprites/enemies/cult_adept.png plus walk companions | ZIP frame mapping: base <= standard/walk/down/5.png, walk_02 <= standard/walk/down/3.png, walk_03 <= standard/walk/down/7.png |
| skeleton | assets/sprites/enemies/skeleton.png plus walk companions | ZIP frame mapping: base <= standard/walk/down/5.png, walk_02 <= standard/walk/down/3.png, walk_03 <= standard/walk/down/7.png |
| bone_archer | assets/sprites/enemies/bone_archer.png plus walk companions | ZIP frame mapping: base <= standard/walk/down/5.png, walk_02 <= standard/walk/down/3.png, walk_03 <= standard/walk/down/7.png |
| grave_guard | assets/sprites/enemies/grave_guard.png plus walk companions | ZIP frame mapping: base <= standard/walk/down/5.png, walk_02 <= standard/walk/down/3.png, walk_03 <= standard/walk/down/7.png |
| plague_bearer | assets/sprites/enemies/plague_bearer.png plus walk companions | ZIP frame mapping: base <= standard/walk/down/5.png, walk_02 <= standard/walk/down/3.png, walk_03 <= standard/walk/down/7.png |
| corrupted_knight | assets/sprites/enemies/corrupted_knight.png plus walk companions | ZIP frame mapping: base <= standard/walk/down/5.png, walk_02 <= standard/walk/down/3.png, walk_03 <= standard/walk/down/7.png |
| hex_sniper | assets/sprites/enemies/hex_sniper.png plus walk companions | ZIP frame mapping: base <= standard/walk/down/5.png, walk_02 <= standard/walk/down/3.png, walk_03 <= standard/walk/down/7.png |
| warlock | assets/sprites/enemies/warlock.png plus walk companions | ZIP frame mapping: base <= standard/walk/down/5.png, walk_02 <= standard/walk/down/3.png, walk_03 <= standard/walk/down/7.png |
| bastion_priest | assets/sprites/enemies/bastion_priest.png plus walk companions | ZIP frame mapping: base <= standard/walk/down/5.png, walk_02 <= standard/walk/down/3.png, walk_03 <= standard/walk/down/7.png |
| bastion_overlord | assets/sprites/enemies/bastion_overlord.png plus walk companions | ZIP frame mapping: base <= standard/walk/down/5.png, walk_02 <= standard/walk/down/3.png, walk_03 <= standard/walk/down/7.png |

## Source and Format

- Source generator: https://liberatedpixelcup.github.io/Universal-LPC-Spritesheet-Character-Generator/
- License status: LPC-derived assets require attribution. Preserve the generator credits export before shipping.
- Export format: transparent RGBA PNG, 64x64 centered crop from the split animation ZIP.
- Canonical frame mapping: base `standard/walk/down/5.png`, `walk_02` `standard/walk/down/3.png`, `walk_03` `standard/walk/down/7.png`.
- Local polish is applied only to the extracted base PNGs after export.

Attribution is still required for LPC-derived assets.
Source generator: https://liberatedpixelcup.github.io/Universal-LPC-Spritesheet-Character-Generator/
Regenerate with: `powershell -ExecutionPolicy Bypass -File .\tools\generate_lpc_enemy_sprites.ps1`
