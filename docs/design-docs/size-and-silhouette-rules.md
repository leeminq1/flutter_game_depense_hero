# Size And Silhouette Rules

## Purpose

Lock visual scale rules before more combat and environment sprites are generated.

Pixel art quality is not only about drawing detail. It is also about relative size on the battlefield and whether a unit reads correctly at a glance.

## Core Rule

Towers and buildings should read larger and more rooted than enemies.

Enemies are mobile threats.
Towers are battlefield anchors.
Environment landmarks are scene anchors.

## Relative On-Screen Size

Use these target relationships for current combat rendering:

- light enemy: `1.0x`
- heavy enemy: `1.1x to 1.2x`
- boss enemy: `1.35x to 1.55x`
- standard tower: `1.45x to 1.7x`
- siege tower or landmark tower: `1.65x to 1.9x`
- environment landmark: `1.8x to 2.4x`
- map background structure: larger still, outside unit readability scale

Implication:

- A tower sprite can still live in a `64x64` source image.
- The game should scale it larger when drawing.

## Source Asset Rule

For current project assets:

- units can remain `64x64` source PNGs
- towers can remain `64x64` source PNGs
- props can begin as `64x64` or `96x96`
- landmark structures can use `96x96` or `128x128`

Source size does not equal world size.
Rendering scale determines battlefield dominance.

## Silhouette Rule By Content Type

### Enemy

Should prioritize:

- readable head or helm
- readable weapon or shield
- one dominant body read

Should avoid:

- too much tiny detail
- tower-like width
- confusing base silhouette

### Tower

Should prioritize:

- stable footprint
- visible top feature
- obvious combat role from shape alone

Examples:

- archer: raised platform or bow signifier
- barracks: hut or guard-post shape
- mage: crystal or obelisk profile
- frost: shrine or ice spire
- coin mill: mill arm or coin emblem
- ballista: siege frame and horizontal weapon arm
- emberkeep: brazier flame silhouette

### Environment Prop

Should prioritize:

- battlefield theme support
- no confusion with buildable towers
- fewer saturated colors than towers

### Landmark

Should prioritize:

- stage identity
- high readability from zoomed-out view
- lower combat ambiguity

## Color Hierarchy

Use saturation to separate gameplay layers:

- enemies: medium to high contrast for threat reading
- towers: medium-high contrast with faction clarity
- props: medium-low contrast
- background structures: lower contrast than interactive content

If an environment prop competes with a tower for attention, lower the prop contrast first.

## Rendering Rule For Current Prototype

Current code should render:

- towers visibly larger than enemies
- bosses larger than both

This means render multipliers belong in visual definitions, not as one shared magic number.

## Upgrade Sprite Rule

Tower upgrade tiers should usually change:

- top silhouette
- roof, crystal, frame, or flame size
- trim richness
- secondary color accents

Do not rely on recolor only.

Tier progression should feel like:

- T1: simple field deployable
- T2: reinforced version
- T3: elite magical or military structure

## Environment Integration Rule

Props must frame the path and placement pads rather than compete with them.

Good:

- torches near edges
- gravestones off path corners
- rubble clusters behind build pads

Bad:

- props blocking tower read
- props larger than towers in active placement zones
- path clutter that looks interactable when it is not
