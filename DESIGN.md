# Design

## Target Feel

The game should feel readable first, flashy second.

Primary emotional targets:
- A calm setup phase with clear choices.
- A satisfying escalation as waves stack pressure.
- Strong visual readability when many enemies are on screen.

## Chosen World Direction

Use a stylized pixel-fantasy world built around LPC-compatible humanoid characters.

Why this direction fits:
- The Universal LPC generator is strongest for modular fantasy humanoids.
- Tower defense readability benefits from clear silhouette-based classes like raider, knight, necromancer, scout, and priest.
- This style keeps content production cheap because armor, hair, weapons, and palette swaps can create many variants from one base pipeline.

Recommended initial enemy factions:
- Bandit raiders for basic and fast units
- Undead infantry for tanks and attrition units
- Cultist casters for support, buffs, and debuffs
- Corrupted knights for elite stage milestones

## Initial Visual Direction

- Top-down 2D battlefield with slight depth cues, not true isometric complexity.
- Clean silhouettes and faction-based color coding.
- Limited palette per biome so enemy threats remain legible.
- Effects should communicate state changes, not just spectacle.
- Humanoid enemies should remain readable at small mobile sizes before decorative detail is added.

## Asset Pipeline Direction

- Start with modular enemy and tower concepts that can be re-skinned.
- Prefer atlas-friendly sprite outputs over many loose PNG files.
- Normalize naming, pivot points, and animation frame counts early.
- Keep a prompt log for AI-assisted concept generation and a cleanup checklist for export.
- Use LPC-generated bases for humanoid enemies, then derive factions through palette, gear set, and role markers.

## Non-Goals For Early Production

- Full procedural animation system.
- High-complexity skeletal rigs.
- Overly detailed backgrounds that reduce gameplay clarity.
