# Enemy Sprite Generation Notes

This project now treats the Universal LPC split animation ZIP as the canonical
source for every humanoid enemy sprite.

## Canonical LPC Frame Mapping

- Base runtime PNG: `standard/walk/down/5.png`
- `walk_02`: `standard/walk/down/3.png`
- `walk_03`: `standard/walk/down/7.png`
- Runtime convention:
  - `{enemy}.png` = planted neutral walk frame
  - `{enemy}_walk_02.png` = left-step companion
  - `{enemy}_walk_03.png` = right-step companion
- Export target: transparent `64x64` PNG
- Local polish pass: base PNG only

## Roster Prompts

### 1. raider

- Files: `raider.png`, `raider_walk_02.png`, `raider_walk_03.png`
- Role read: early bandit melee pressure
- Prompt anchor: rugged leather raider, hood, short blade, warm brown and red accents

### 2. scout

- Files: `scout.png`, `scout_walk_02.png`, `scout_walk_03.png`
- Role read: fast bandit skirmisher
- Prompt anchor: slim hooded scout, light bow silhouette, tan and forest accents

### 3. banner_captain

- Files: `banner_captain.png`, `banner_captain_walk_02.png`, `banner_captain_walk_03.png`
- Role read: bandit support leader
- Prompt anchor: leather captain, banner or spear read, red-marked plume, commanding posture

### 4. wolf_scout

- Files: `wolf_scout.png`, `wolf_scout_walk_02.png`, `wolf_scout_walk_03.png`
- Role read: beastfolk speed threat
- Prompt anchor: wolf head, light leather, runner silhouette, bow or knife read, gray-brown fur

### 5. shield_infantry

- Files: `shield_infantry.png`, `shield_infantry_walk_02.png`, `shield_infantry_walk_03.png`
- Role read: armored frontline check
- Prompt anchor: legion helm, broad shield-first silhouette, steel with green pattern

### 6. cult_adept

- Files: `cult_adept.png`, `cult_adept_walk_02.png`, `cult_adept_walk_03.png`
- Role read: ritual support caster
- Prompt anchor: robe-heavy silhouette, occult sash, ritual focus prop, purple accents

### 7. skeleton

- Files: `skeleton.png`, `skeleton_walk_02.png`, `skeleton_walk_03.png`
- Role read: reviving undead infantry
- Prompt anchor: clean skull read, simple sword, worn scrap detail, pale bone palette

### 8. bone_archer

- Files: `bone_archer.png`, `bone_archer_walk_02.png`, `bone_archer_walk_03.png`
- Role read: undead skirmisher
- Prompt anchor: skeleton bowman, worn scraps, thin ranged silhouette, pale bone with dark bow cue

### 9. grave_guard

- Files: `grave_guard.png`, `grave_guard_walk_02.png`, `grave_guard_walk_03.png`
- Role read: undead elite tank
- Prompt anchor: slab-like armored undead, shield or heavy torso mass, grave-green trim

### 10. plague_bearer

- Files: `plague_bearer.png`, `plague_bearer_walk_02.png`, `plague_bearer_walk_03.png`
- Role read: undead sustain support
- Prompt anchor: plague hood, censer or ritual staff, bone-green cloth accents, sickly support caster

### 11. corrupted_knight

- Files: `corrupted_knight.png`, `corrupted_knight_walk_02.png`, `corrupted_knight_walk_03.png`
- Role read: cursed armored elite
- Prompt anchor: dark plate, horned helm, red corruption trim, charger silhouette

### 12. hex_sniper

- Files: `hex_sniper.png`, `hex_sniper_walk_02.png`, `hex_sniper_walk_03.png`
- Role read: cursed ranged ward support
- Prompt anchor: narrow hood, crossbow silhouette, occult support cues, violet-green focal glow

### 13. warlock

- Files: `warlock.png`, `warlock_walk_02.png`, `warlock_walk_03.png`
- Role read: late summon-and-ward caster
- Prompt anchor: tall robe silhouette, stronger mantle, magical staff loop, purple focal glow

### 14. bastion_priest

- Files: `bastion_priest.png`, `bastion_priest_walk_02.png`, `bastion_priest_walk_03.png`
- Role read: plated elite healer
- Prompt anchor: plated cleric, ritual mace, white-gold bastion cloth, late-game support authority

### 15. bastion_overlord

- Files: `bastion_overlord.png`, `bastion_overlord_walk_02.png`, `bastion_overlord_walk_03.png`
- Role read: final fortress boss
- Prompt anchor: massive horned overlord, gold-red plate, fortress silhouette, infernal command presence
