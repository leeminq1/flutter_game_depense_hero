# Content Pipeline

## Goal

Make it cheap to go from idea to playable content without creating asset chaos.

## Proposed Flow

1. Define gameplay role first: tower, enemy, biome prop, or effect.
2. Create concept references and prompt log.
3. For humanoid enemies, generate a base from the LPC character generator.
4. Clean silhouettes, palette, and scale for gameplay readability.
5. Export atlas-ready sprites with consistent naming.
6. Register metadata in definitions.
7. Store LPC credit and license export with the asset package.
8. Verify in a test scene before full integration.

## Required Metadata

- Asset owner
- Source link or origin
- License or usage status
- Credits export location
- Intended resolution
- Pivot point
- Animation list
- Export date

## AI-Assisted Asset Rules

- Use AI for ideation, variants, and rough material exploration.
- Human review is required before any asset becomes a shipping candidate.
- Keep generated source prompts and final cleaned export references together.

## Flame-Oriented Constraints

- Prefer sprite sheets / atlases over scattered files.
- Keep animation frame counts practical for mobile budgets.
- Reuse palettes and shared effect elements where possible.

## LPC-Specific Notes

- LPC is especially strong for humanoid fantasy units rather than large monsters.
- Build enemy diversity through role silhouettes, equipment sets, palette families, and animation timing.
- Plan separate pipelines later for non-humanoid bosses if the game needs creatures beyond the LPC sweet spot.
