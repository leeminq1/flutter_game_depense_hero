# Campaign Ending Asset Specification

## Dawn Battlefield Background

| Field | Value |
| --- | --- |
| File | `assets/images/campaign_ending_dawn.png` |
| Category | Ending background |
| Size | Portrait 9:16, minimum 1080×1920 source |
| Role | Stage 30 ending backdrop behind separately composited game sprites |

### Style rules

- Detailed top-down 3/4 fantasy pixel art consistent with the renewed campaign maps.
- The lower third shows battle-worn earth, extinguished embers, and light ash without depicting active violence.
- The upper area opens into a pale blue and warm-gold dawn, shifting the mood from hardship to hope.
- Preserve a quiet central vertical corridor for separately composited heroes, citadel, and monsters.
- Do not include characters, creatures, monsters, buildings, castles, weapons, UI, text, logos, borders, or watermarks.
- Avoid photorealism, smooth vector art, and dense foreground clutter.

### Prompt

```text
Use case: stylized-concept
Asset type: portrait Flutter game ending background
Primary request: portrait 9:16 high-angle top-down 3/4 fantasy pixel-art battlefield at dawn, matching Pixel Guard detailed campaign environment
Scene/backdrop: dark battle-worn earth and extinguished embers in the lower third, warm gold and pale blue dawn horizon, subtle drifting ash, hopeful atmosphere after a long siege
Composition: central empty vertical space for separately composited game sprites, readable dark-to-light value transition, edge details framing the scene
Constraints: no characters, no creatures, no monsters, no buildings, no castle, no weapons, no UI, no text, no logo, no border, no watermark
```

### Acceptance

- Reads clearly at a 430×900 logical-pixel phone viewport.
- Supports white Korean copy in both the dark lower area and dawn upper area with an overlay scrim.
- Leaves enough uncluttered space for five hero sprites, representative enemies, and the citadel.
- Contains none of the prohibited subjects or typography.
- Export is a valid PNG larger than 10 KB and is bundled by Flutter.

## Generation record

- Source: OpenAI image generation tool, generated specifically for this project.
- Prompt: the exact prompt above.
- License/provenance: AI-generated project asset; no third-party source image was copied.
- Export: PNG source retained at `docs/generated/campaign-ending-dawn-source.png`; runtime copy at `assets/images/campaign_ending_dawn.png`.
