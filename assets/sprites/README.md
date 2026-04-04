# Sprite Slots

This folder reserves the runtime sprite paths for the defense game.

Planned structure:

- `assets/sprites/towers/`
- `assets/sprites/enemies/`
- `assets/sprites/ui/`
- `assets/sprites/manifest/`

Until real sprite sheets are imported, the game uses shape-based placeholder rendering.

Recommended import rule:

- export final PNGs with transparent backgrounds
- keep filenames stable so code references do not change
- prefer one sprite per runtime unit first, then expand to animation sheets
