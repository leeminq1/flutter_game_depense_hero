# Audio Architecture

## Goal

Make audio part of the core runtime architecture so combat stays smooth even when many enemies, projectiles, and UI events overlap.

## Core Rules

- Audio playback must be mediated by a central audio service.
- Game systems emit semantic audio events instead of directly choosing files.
- Short repeated sounds use `AudioPool`.
- Looping background music uses `FlameAudio.bgm`.
- Hot sounds are preloaded during scene load, not on first combat use.
- Missing or failed audio playback must never block gameplay.

## Flame-Oriented Structure

Recommended runtime layers:

```text
lib/
├── game/
│   ├── audio/
│   │   ├── game_audio_service.dart
│   │   ├── audio_bus.dart
│   │   ├── audio_catalog.dart
│   │   ├── audio_pools.dart
│   │   └── audio_settings_controller.dart
```

Responsibilities:
- `audio_bus`: semantic events like `towerPlaced`, `enemyHit`, `waveCleared`
- `audio_catalog`: maps events to files, variations, volume, cooldowns
- `audio_pools`: owns pooled players for high-frequency SFX
- `game_audio_service`: handles preload, play, pause, resume, and stage transitions
- `audio_settings_controller`: master/music/sfx/voice volume and mute state

## Performance Rules

- Pool high-frequency sounds: projectile hits, tower shots, coin gain, placement.
- Cap simultaneous plays per category, especially `enemyHit` and `death`.
- Queue repeated combat SFX through the game loop and drain only a small per-frame budget.
- Keep boundary jingles such as `waveClear` and `stageClear` as direct one-shot feedback.
- Add small random variation by file selection, not pitch-shifting every frame.
- Preload only the current stage's hot sounds plus global UI sounds.
- Clear stage-specific cache when leaving the stage if memory becomes an issue.
- Never use long-audio playback APIs for short combat sounds.

## Recommended Event Categories

- UI
  - click
  - select
  - confirm
  - error
- Build
  - tower_place
  - tower_upgrade
  - tower_sell
- Combat
  - projectile_launch
  - hit_flesh
  - hit_armor
  - hit_magic
  - enemy_death
  - base_damage
- Progression
  - wave_clear
  - stage_clear
  - reward_granted
  - unlock
- Music
  - menu_bgm
  - stage_bgm
  - boss_bgm

## Asset Guidance

- Keep combat SFX short and dry.
- Prefer OGG for compressed effects and music in this asset library.
- Maintain multiple variants for repetitive events to reduce ear fatigue.
- Keep one clear fallback file per category so missing variants do not break behavior.

## Current Project Decision

- The selected starting audio comes from Kenney interface, impact, RPG, music-jingles, and voiceover packs.
- The selected starting audio comes from Kenney interface, impact, RPG, and music-jingles packs.
- Those assets are enough for an early vertical slice of UI, placement, hits, rewards, and outcome cues.
- The current library does not include strong loopable fantasy stage BGM, so dedicated BGM generation is still needed.
