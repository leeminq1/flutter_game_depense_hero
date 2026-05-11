# Visual Refresh Asset Specification

## Purpose

Refresh runtime art that still looked placeholder-like while preserving the
current readable battlefield colors and the already-approved hero, enemy,
central citadel, and tile art.

## Generated Asset Groups

### Tower and Defender Sprites

| Field | Value |
| --- | --- |
| Files | `assets/sprites/towers/*.png`, `assets/sprites/defenders/*.png` |
| Category | buildable combat structures and barracks defenders |
| Size | towers `64x64` PNG, defenders `48x48` PNG, transparent |
| Role | show tower identity, tier growth, branch identity, and barracks unit presence |

Style rules:
- Top-down high-angle fantasy strategy sprites.
- Towers must read larger and more anchored than enemies.
- Tier progression must change silhouette or visible equipment, not only color.
- Branch variants must preserve the base tower family while adding a clear role cue.

Prompt:
```text
top-down high-angle mobile fantasy defense game sprite, transparent background,
clean readable structure silhouette, polished 2D game asset, strong outline,
soft shadow, faction color accent, no UI, no text, no ground plane, no characters
except barracks defender sprites, match blue-gold citadel and existing hero/enemy
quality
```

Acceptance:
- Readable at portrait phone scale.
- Distinct tower family and tier at a glance.
- No replacement touches hero, enemy, central citadel, or tile files.
- Current production pass uses an AI-authored local generation script with
  material noise, rim highlights, outline cleanup, and soft contact shadows so
  every generated PNG remains deterministic and buildable from source.

### Barrier Sprites

| Field | Value |
| --- | --- |
| Files | `assets/sprites/barriers/wood_fence.png`, `stone_wall.png`, `reinforced_wall.png`, `fortress_wall.png` |
| Category | buildable blocker structures |
| Size | `64x64` PNG, transparent |
| Role | replace flat Canvas wall blocks with readable wall assets |

Style rules:
- Must read as blockers, not attack towers.
- Durability should increase from wood to fortress wall through material and silhouette.
- Saturation should stay below active towers.

Prompt:
```text
top-down high-angle fantasy wall tile, transparent background, mobile strategy
readability, compact blocker footprint, strong outline, soft shadow, no UI,
no characters, no ground plane, not a tower
```

Acceptance:
- Each wall type is visually distinct.
- Fits one grid cell without obscuring nearby units.

### Environment Props and Landmarks

| Field | Value |
| --- | --- |
| Files | `assets/sprites/environment/props/*.png`, `assets/sprites/environment/landmarks/*.png` except `central_citadel.png` |
| Category | decorative stage set dressing |
| Size | props `64x64` PNG, landmarks `96x96` PNG, transparent |
| Role | improve battlefield atmosphere without competing with combat units |

Style rules:
- Lower saturation than towers and enemies.
- Must support the campaign bracket themes from the stage art bible.
- Must not look buildable or tappable.

Prompt:
```text
top-down high-angle fantasy battlefield prop, transparent background, polished
2D mobile game sprite, subdued saturation, readable silhouette, no UI, no text,
no character, no ground plane, supports frontier, bandit, grave, chapel, bastion,
or infernal stage theme
```

Acceptance:
- Props remain decorative and do not obscure road/build readability.
- Landmarks identify stage theme without becoming confused with towers.

### Attack Effect Sprites

| Field | Value |
| --- | --- |
| Files | `assets/sprites/effects/arrow_projectile.png`, `siege_bolt_projectile.png`, `arcane_bolt_projectile.png`, `frost_impact.png`, `flame_impact.png` |
| Category | combat VFX |
| Size | projectile `64x16` PNG, impact `64x64` PNG, transparent |
| Role | enhance the existing Canvas projectile and impact effects |

Style rules:
- Projectile sprites face right and are rotated by runtime code.
- Impact sprites are centered, radial, and fade cleanly.
- Existing Canvas effects remain fallback behavior.

Prompt:
```text
transparent fantasy tower defense combat effect sprite, crisp mobile game VFX,
projectile facing right or centered magical burst, bright readable core, soft
outer fade, no UI, no text, no ground plane
```

Acceptance:
- Sprites load through the visual registry.
- Combat remains readable with or without the PNG fallback.
