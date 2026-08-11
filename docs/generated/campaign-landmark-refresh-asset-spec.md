# Campaign Landmark Refresh Asset Specification

- Date: 2026-08-11
- Use case: `stylized-concept`
- Runtime target: Android Flutter + Flame battlefield
- Style references:
  - `assets/sprites/stage1/environment/tutorial_citadel.png`
  - `assets/sprites/stage1/environment/village_gatehouse.png`
- Shared export contract: 256×256 RGBA PNG, transparent background, bottom-center
  anchor, crisp nearest-neighbor pixel edges, no text or characters.

### 1. Frontier Watch Post

| Field | Value |
| --- | --- |
| File | `assets/sprites/campaign/environment/landmarks/watch_post.png` |
| Category | landmark |
| Size | 256×256 PNG, transparent |
| Role | Frontier scouting landmark for Stages 2–4 |

Style rules:
- Top-down high-angle 3/4 fantasy pixel art matching the blue citadel and gatehouse.
- Warm timber, stone footing, small blue pennant; readable as a two-storey lookout.
- Compact one-object silhouette with the base centered at the bottom.

Prompt:
```text
Use case: stylized-concept. Asset type: mobile tower-defense landmark sprite.
Create one frontier timber watch post with a stone footing, ladder, roofed lookout,
and one small blue pennant. Match the supplied citadel and gatehouse: polished
top-down 3/4 fantasy pixel art, dense masonry and timber detail, strong silhouette,
crisp pixel clusters. Perfectly flat solid #00FF00 chroma-key background. No green
on the object, no characters, no terrain, no UI, no text, no watermark.
```

Acceptance:
- Distinct from a combat tower and readable at 0.55× zoom.
- Base and roof use the same perspective as the reference gatehouse.

### 2. Bandit Checkpoint Tower

| Field | Value |
| --- | --- |
| File | `assets/sprites/campaign/environment/landmarks/checkpoint_tower.png` |
| Category | landmark |
| Size | 256×256 PNG, transparent |
| Role | Road-control landmark for Stages 6 and 9 |

Style rules:
- Fortified timber-and-stone checkpoint with ochre cloth and rough repairs.
- Top-down 3/4 perspective and pixel density must match the references.
- No playable-tower platform or unit silhouette.

Prompt:
```text
Use case: stylized-concept. Asset type: mobile tower-defense landmark sprite.
Create one fortified bandit checkpoint tower: squat stone lower wall, heavy timber
upper guard room, uneven barricade beams, ochre warning cloth, patched roof. Match
the supplied citadel and gatehouse in polished top-down 3/4 fantasy pixel art and
crisp dense pixel detail. Perfectly flat solid #00FF00 chroma-key background. No
green on the object, no characters, no terrain, no UI, no text, no watermark.
```

Acceptance:
- Reads as a map landmark rather than a buildable player tower.
- Stone and timber detail remain clear at gameplay scale.

### 3. Bandit Stockade

| Field | Value |
| --- | --- |
| File | `assets/sprites/campaign/environment/landmarks/bandit_stockade.png` |
| Category | landmark |
| Size | 256×256 PNG, transparent |
| Role | Crest landmark for Stage 10 |

Style rules:
- Wide palisade gate with layered timber, spikes, rope, and red-ochre banner.
- Symmetrical enough to read as the main bandit stronghold entrance.
- Top-down 3/4 perspective, no flat front-elevation drawing.

Prompt:
```text
Use case: stylized-concept. Asset type: mobile tower-defense landmark sprite.
Create one imposing bandit stockade gate, wide sharpened log palisade, reinforced
double timber doors, rope bindings, scrap-metal braces, small red-ochre banner.
Match the supplied citadel and gatehouse in polished top-down 3/4 fantasy pixel art,
crisp high-detail pixel clusters and readable depth. Perfectly flat solid #00FF00
chroma-key background. No green, no characters, no terrain, no UI, no text.
```

Acceptance:
- Strong crest-stage silhouette and visibly higher detail than the legacy sprite.
- Gate opening and palisade depth are readable on a phone.

### 4. Cemetery Statue

| Field | Value |
| --- | --- |
| File | `assets/sprites/campaign/environment/landmarks/cemetery_statue.png` |
| Category | landmark |
| Size | 256×256 PNG, transparent |
| Role | Grave-field focal landmark for Stage 11–14 variants |

Style rules:
- Weathered armored guardian statue on a layered grave pedestal.
- Moss-free gray stone with small blue-gray memorial accents.
- Top-down 3/4 perspective with a compact, non-unit silhouette.

Prompt:
```text
Use case: stylized-concept. Asset type: mobile tower-defense landmark sprite.
Create one weathered cemetery guardian statue: ancient armored knight carved from
gray stone, sword point resting downward, layered cracked memorial pedestal, small
blue-gray votive details. Match the supplied references in polished top-down 3/4
fantasy pixel art and crisp dense pixel shading. Perfectly flat solid #00FF00
chroma-key background. No green, no living character, no terrain, no UI, no text.
```

Acceptance:
- Clearly reads as an inert monument, not a hero or enemy.
- Pedestal footprint remains compact and bottom-centered.

### 5. Mausoleum Gate

| Field | Value |
| --- | --- |
| File | `assets/sprites/campaign/environment/landmarks/mausoleum_gate.png` |
| Category | landmark |
| Size | 256×256 PNG, transparent |
| Role | Grave-field crest landmark for Stage 15 |

Style rules:
- Stone mausoleum entrance with iron door, buttresses, skull relief, and cold blue accents.
- Heavy masonry depth matching the reference citadel.
- Dark interior must remain enclosed by a readable doorway frame.

Prompt:
```text
Use case: stylized-concept. Asset type: mobile tower-defense landmark sprite.
Create one grand mausoleum gate: weathered gray stone crypt facade, steep slate roof,
iron double door, side buttresses, carved skull crest, subtle cold blue memorial
lights. Match the supplied citadel and gatehouse in polished top-down 3/4 fantasy
pixel art, dense masonry texture and crisp pixels. Perfectly flat solid #00FF00
chroma-key background. No green, no characters, no terrain, no UI, no text.
```

Acceptance:
- Reads as the Stage 15 primary landmark at minimum zoom.
- Architecture shares the same viewing angle and material depth as the citadel.

### 6. Ritual Arch

| Field | Value |
| --- | --- |
| File | `assets/sprites/campaign/environment/landmarks/ritual_arch.png` |
| Category | landmark |
| Size | 256×256 PNG, transparent |
| Role | Cursed-chapel secondary landmark for Stages 16–20 |

Style rules:
- Broken black-stone arch with violet crystal and runic metal braces.
- Hollow center stays transparent and readable.
- Top-down 3/4 pixel-art architecture, not a flat icon.

Prompt:
```text
Use case: stylized-concept. Asset type: mobile tower-defense landmark sprite.
Create one cursed ritual arch: broken black and gray stone columns, pointed arch,
violet crystal keystone, dull silver runic braces, hollow open center. Match the
supplied references in polished top-down 3/4 fantasy pixel art with crisp dense
pixel texture. Perfectly flat solid #00FF00 chroma-key background, including through
the arch opening. No green, no characters, no terrain, no UI, no text.
```

Acceptance:
- Arch opening remains transparent after chroma removal.
- Violet details do not overpower enemy or tower readability.

### 7. Cursed Chapel

| Field | Value |
| --- | --- |
| File | `assets/sprites/campaign/environment/landmarks/cursed_chapel_front.png` |
| Category | landmark |
| Size | 256×256 PNG, transparent |
| Role | Cursed-chapel crest landmark for Stage 20 |

Style rules:
- Ruined stone chapel with steep roof, broken bell tower, violet stained glass.
- Same high-angle 3/4 architectural perspective as the reference gatehouse.
- Strong central silhouette with asymmetrical curse damage.

Prompt:
```text
Use case: stylized-concept. Asset type: mobile tower-defense landmark sprite.
Create one ruined cursed chapel: dark gray stone nave, steep damaged slate roof,
small broken bell tower, violet stained-glass window, cracked buttresses, faint
purple rune accents. Match the supplied citadel and gatehouse in polished top-down
3/4 fantasy pixel art, crisp dense masonry and roof pixels. Perfectly flat solid
#00FF00 chroma-key background. No green, no characters, no terrain, no UI, no text.
```

Acceptance:
- Clearly more substantial than the ritual arch and readable as the Stage 20 crest.
- No lighting haze or translucent glow outside the sprite silhouette.

### 8. Bastion Gate Ruin

| Field | Value |
| --- | --- |
| File | `assets/sprites/campaign/environment/landmarks/gate_ruin.png` |
| Category | landmark |
| Size | 256×256 PNG, transparent |
| Role | Damaged approach landmark for Stages 21–24 |

Style rules:
- Collapsed military gate with blue-banner remnants and rubble contained in the footprint.
- Cold gray blockwork and top-down 3/4 perspective.
- Must read as destroyed scenery, not a functioning player wall.

Prompt:
```text
Use case: stylized-concept. Asset type: mobile tower-defense landmark sprite.
Create one ruined bastion gate: cold gray stone arch, one partially collapsed tower,
cracked battlements, broken portcullis, small torn blue banner, compact rubble at the
base. Match the supplied citadel and gatehouse in polished top-down 3/4 fantasy pixel
art with crisp detailed masonry. Perfectly flat solid #00FF00 chroma-key background.
No green, no characters, no terrain, no UI, no text.
```

Acceptance:
- Destruction remains legible without exceeding the 2×2 landmark footprint.
- Blue accent connects it visually to the player-side fortress language.

### 9. Bastion Wall Chunk

| Field | Value |
| --- | --- |
| File | `assets/sprites/campaign/environment/landmarks/bastion_wall_chunk.png` |
| Category | landmark |
| Size | 256×256 PNG, transparent |
| Role | Siege crest landmark for Stage 25 |

Style rules:
- Wide breached fortress wall with towers, battlements, and a central impact gap.
- Cold stone, iron reinforcement, limited blue heraldry.
- High-angle 3/4 depth, not a rectangular front-facing slab.

Prompt:
```text
Use case: stylized-concept. Asset type: mobile tower-defense landmark sprite.
Create one wide breached bastion wall section: two squat stone guard towers,
battlements, iron reinforcement bands, large central impact breach, broken blocks,
small blue heraldic cloth. Match the supplied citadel in polished top-down 3/4
fantasy pixel art, crisp dense masonry detail. Perfectly flat solid #00FF00
chroma-key background. No green, no characters, no terrain, no UI, no text.
```

Acceptance:
- Reads as a major siege landmark at 0.55× zoom.
- Breach and wall depth remain clear against cold stone-green ground.

### 10. Infernal Gate

| Field | Value |
| --- | --- |
| File | `assets/sprites/campaign/environment/landmarks/infernal_gate.png` |
| Category | landmark |
| Size | 256×256 PNG, transparent |
| Role | Final crest landmark for Stage 30 |

Style rules:
- Obsidian fortress gate with ember-orange furnace light and blackened stone.
- Massive top-down 3/4 silhouette consistent with the reference architecture.
- Opaque pixel-art fire; no soft smoke or transparency-heavy glow.

Prompt:
```text
Use case: stylized-concept. Asset type: mobile tower-defense landmark sprite.
Create one massive infernal fortress gate: blackened obsidian stone, tall pointed
arch, iron doors, ember-orange furnace light inside, horn-like battlements, scorched
metal braces. Match the supplied citadel and gatehouse in polished top-down 3/4
fantasy pixel art with crisp dense material detail. Perfectly flat solid #00FF00
chroma-key background. No green, no characters, no terrain, no UI, no text, no haze.
```

Acceptance:
- Dominant Stage 30 silhouette without resembling the blue player citadel.
- Orange lighting is contained within hard pixel edges.

### 11. Throne Road Monument

| Field | Value |
| --- | --- |
| File | `assets/sprites/campaign/environment/landmarks/throne_road_monument.png` |
| Category | landmark |
| Size | 256×256 PNG, transparent |
| Role | Throne-march route monument for Stages 26–30 |

Style rules:
- Obsidian road shrine with ember crystal, chains, and stepped stone plinth.
- Smaller than the infernal gate but visually richer than a prop.
- Top-down 3/4 pixel-art architecture with a compact footprint.

Prompt:
```text
Use case: stylized-concept. Asset type: mobile tower-defense landmark sprite.
Create one throne-road monument: stepped black-stone plinth, central ember-orange
crystal crest, short iron pillars, hanging chains, scorched gold trim. Match the
supplied references in polished top-down 3/4 fantasy pixel art with crisp dense
pixel detail. Perfectly flat solid #00FF00 chroma-key background. No green, no
characters, no terrain, no UI, no text, no smoke.
```

Acceptance:
- Distinct from the infernal gate and readable at minimum zoom.
- Bottom-center anchor remains visually stable when scaled.

## Generation Record

- Generator: Codex built-in `imagegen` tool.
- Input role: `tutorial_citadel.png` and `village_gatehouse.png` were used only
  as style, pixel-density, palette, and top-down 3/4 perspective references.
- Generated sources: `docs/generated/campaign-landmarks/*-source.png`.
- Alpha intermediates: `docs/generated/campaign-landmarks/*-alpha.png`.
- Background removal: installed `remove_chroma_key.py`, border-sampled green
  key, soft matte, despill, transparent threshold 12, opaque threshold 220,
  edge contraction 1.
- Deterministic export: `tool/build_campaign_landmarks.py`; visible pixels are
  nearest-neighbor scaled into a 256×256 RGBA canvas with a shared bottom-center
  anchor and transparent-corner validation.
- Final assets: `assets/sprites/campaign/environment/landmarks/*.png`.
- Source/license statement: generated specifically for this project with the
  built-in OpenAI image generation tool; no third-party art was copied into the
  final landmark files.
