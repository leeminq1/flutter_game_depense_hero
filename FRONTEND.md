# Frontend

Flutter is responsible for the app shell around the game.

## Own In Flutter

- Title screen and onboarding flow
- Meta progression and upgrade menus
- Settings, audio, accessibility, and language controls
- Reward screens, pause modal, and out-of-run summaries
- Rewarded ad prompts, shop surfaces, and stage progression screens
- Debug toggles and developer instrumentation panels

## Audio Ownership

- Flutter app lifecycle should initialize ad privacy and app-wide services.
- The game runtime should emit semantic audio events such as `towerPlaced`, `enemyHitArmor`, and `stageCleared`.
- A dedicated audio service should translate those semantic events into concrete asset playback rules.
- UI widgets may trigger UI audio, but they should do it through the same central audio service.

## Own In Flame

- Battlefield camera and map
- Unit spawning and movement
- Targeting, attacks, collisions, and status effects
- Combat VFX that are tightly coupled to simulation timing

## UI Bridge Rules

- Use explicit commands from Flutter to the game layer.
- Surface read-only session snapshots back to Flutter overlays.
- Avoid two-way ad hoc mutation between widget trees and components.
- Keep HUD updates lightweight and resilient to rapid state changes.
- Route monetization through a single app-layer service so gameplay code stays ad-SDK agnostic.
