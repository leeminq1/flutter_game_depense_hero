# Effect Asset Generation Notes

## cannonball_projectile.png

- Date: 2026-05-13
- Tool: Codex built-in image generation, then local chroma-key removal and 256px crop/resize
- Source file retained by Codex under the generated image cache; project asset is `assets/sprites/effects/cannonball_projectile.png`
- Prompt summary: stylized 2D fantasy tower-defense cannonball/mortar projectile, dark iron ball with orange fire rim and smoke trail, generated on flat `#00ff00` chroma-key background, no text, no watermark
- Runtime use: once-per-stage artillery projectile visual for `StageBombardmentDefinition`

## shuriken_projectile.png

- Date: 2026-05-15
- Tool: Codex built-in image generation, then local chroma-key removal and 128px crop/resize
- Source file retained by Codex under the generated image cache; project asset is `assets/sprites/effects/shuriken_projectile.png`
- Prompt summary: stylized top-down pixel-art ninja shuriken projectile for a fantasy tower-defense game, silver four-point star with subtle blue edge highlight and motion glint, generated on flat `#00ff00` chroma-key background, no text, no watermark
- Runtime use: ranged ninja hero projectile in `DefensePrototypeGame._fireHero`

## boss_shockwave_impact.png

- Date: 2026-05-15
- Tool: Codex built-in image generation, then local chroma-key removal and 256px crop/resize
- Source file retained by Codex under the generated image cache; project asset is `assets/sprites/effects/boss_shockwave_impact.png`
- Prompt summary: stylized top-down fantasy boss ground-impact shockwave, circular orange-gold cracked-earth pulse with transparent-looking center and expanding energy ring, generated on flat `#00ff00` chroma-key background, no text, no watermark
- Runtime use: boss and stage-event boss structure-impact shockwave effect
